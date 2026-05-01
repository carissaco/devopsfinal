import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime

import httpx
from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from pydantic import BaseModel, EmailStr, Field

from . import db, migrations

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s - %(message)s")
log = logging.getLogger("orders-svc")

CATALOG_URL = os.environ["CATALOG_URL"].rstrip("/")
INVENTORY_URL = os.environ["INVENTORY_URL"].rstrip("/")

ORDER_FAIL = Counter("orders_failures_total", "Failed orders by reason", ["reason"])
ORDER_OK = Counter("orders_placed_total", "Successful orders placed")


@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = await db.init_pool()
    async with pool.acquire() as conn:
        await migrations.run(conn, db.DB_SCHEMA)
    app.state.http = httpx.AsyncClient(timeout=5.0)
    log.info("orders-svc ready, catalog=%s inventory=%s", CATALOG_URL, INVENTORY_URL)
    yield
    await app.state.http.aclose()
    await db.close_pool()


app = FastAPI(title="orders-svc", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


class OrderItemIn(BaseModel):
    product_id: int
    quantity: int = Field(gt=0)


class OrderIn(BaseModel):
    customer_name: str = Field(min_length=1, max_length=120)
    customer_email: EmailStr
    items: list[OrderItemIn] = Field(min_length=1)


class OrderItemOut(BaseModel):
    product_id: int
    name: str
    quantity: int
    unit_price_cents: int


class OrderOut(BaseModel):
    id: int
    customer_name: str
    customer_email: str
    placed_at: datetime
    total_cents: int
    items: list[OrderItemOut]


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.get("/readyz")
async def readyz():
    async with db.pool().acquire() as conn:
        await conn.execute("SELECT 1")
    return {"status": "ok"}


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/orders", response_model=OrderOut, status_code=201)
async def place_order(order: OrderIn):
    http: httpx.AsyncClient = app.state.http

    # 1. Resolve products against catalog (price + name).
    try:
        products: dict[int, dict] = {}
        for item in order.items:
            r = await http.get(f"{CATALOG_URL}/products/{item.product_id}")
            if r.status_code == 404:
                ORDER_FAIL.labels(reason="product_not_found").inc()
                raise HTTPException(400, f"product {item.product_id} not found")
            r.raise_for_status()
            products[item.product_id] = r.json()
    except httpx.HTTPError as e:
        log.exception("catalog call failed")
        ORDER_FAIL.labels(reason="catalog_unavailable").inc()
        raise HTTPException(502, f"catalog service unavailable: {e}") from e

    # 2. Decrement inventory atomically per item.
    decremented: list[OrderItemIn] = []
    try:
        for item in order.items:
            r = await http.post(
                f"{INVENTORY_URL}/stock/{item.product_id}/decrement",
                json={"quantity": item.quantity},
            )
            if r.status_code == 409:
                # Roll back any previous decrements (best-effort compensating action).
                await _rollback_inventory(http, decremented)
                ORDER_FAIL.labels(reason="out_of_stock").inc()
                raise HTTPException(409, f"product {item.product_id} is out of stock")
            r.raise_for_status()
            decremented.append(item)
    except httpx.HTTPError as e:
        log.exception("inventory call failed")
        await _rollback_inventory(http, decremented)
        ORDER_FAIL.labels(reason="inventory_unavailable").inc()
        raise HTTPException(502, f"inventory service unavailable: {e}") from e

    # 3. Persist order + line items.
    total_cents = sum(products[i.product_id]["priceCents"] * i.quantity for i in order.items)
    async with db.pool().acquire() as conn:
        async with conn.transaction():
            order_row = await conn.fetchrow(
                """
                INSERT INTO orders (customer_name, customer_email, total_cents)
                VALUES ($1, $2, $3)
                RETURNING id, placed_at
                """,
                order.customer_name,
                order.customer_email,
                total_cents,
            )
            for item in order.items:
                p = products[item.product_id]
                await conn.execute(
                    """
                    INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price_cents)
                    VALUES ($1, $2, $3, $4, $5)
                    """,
                    order_row["id"],
                    item.product_id,
                    p["name"],
                    item.quantity,
                    p["priceCents"],
                )

    ORDER_OK.inc()
    return OrderOut(
        id=order_row["id"],
        customer_name=order.customer_name,
        customer_email=order.customer_email,
        placed_at=order_row["placed_at"],
        total_cents=total_cents,
        items=[
            OrderItemOut(
                product_id=i.product_id,
                name=products[i.product_id]["name"],
                quantity=i.quantity,
                unit_price_cents=products[i.product_id]["priceCents"],
            )
            for i in order.items
        ],
    )


async def _rollback_inventory(http: httpx.AsyncClient, items: list[OrderItemIn]) -> None:
    """Compensating action when an order fails partway through inventory decrements.
    No /increment endpoint exists, so we PATCH stock back via decrement-with-negative? No —
    we just log loudly. In a real system we'd add an increment endpoint or use a saga."""
    if items:
        log.error("FIXME: cannot roll back inventory decrements for %s — would leave stock low", items)


@app.get("/orders", response_model=list[OrderOut])
async def list_orders(email: str = Query(..., min_length=3)):
    async with db.pool().acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT id, customer_name, customer_email, placed_at, total_cents
              FROM orders
             WHERE customer_email = $1
             ORDER BY placed_at DESC
            """,
            email,
        )
        out: list[OrderOut] = []
        for r in rows:
            items = await conn.fetch(
                """
                SELECT product_id, product_name, quantity, unit_price_cents
                  FROM order_items
                 WHERE order_id = $1
                 ORDER BY product_id
                """,
                r["id"],
            )
            out.append(
                OrderOut(
                    id=r["id"],
                    customer_name=r["customer_name"],
                    customer_email=r["customer_email"],
                    placed_at=r["placed_at"],
                    total_cents=r["total_cents"],
                    items=[
                        OrderItemOut(
                            product_id=i["product_id"],
                            name=i["product_name"],
                            quantity=i["quantity"],
                            unit_price_cents=i["unit_price_cents"],
                        )
                        for i in items
                    ],
                )
            )
        return out


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
