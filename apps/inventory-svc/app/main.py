import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from pydantic import BaseModel, Field

from . import db, migrations

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s - %(message)s")
log = logging.getLogger("inventory-svc")

DECREMENT_FAIL = Counter("inventory_decrement_failures_total", "Stock decrement failures", ["reason"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = await db.init_pool()
    async with pool.acquire() as conn:
        await migrations.run(conn, db.DB_SCHEMA)
    log.info("inventory-svc ready, schema=%s", db.DB_SCHEMA)
    yield
    await db.close_pool()


app = FastAPI(title="inventory-svc", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


class StockRow(BaseModel):
    product_id: int
    quantity: int


class DecrementRequest(BaseModel):
    quantity: int = Field(gt=0)


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


@app.get("/stock", response_model=list[StockRow])
async def list_stock():
    rows = await db.pool().fetch("SELECT product_id, quantity FROM stock ORDER BY product_id")
    return [StockRow(product_id=r["product_id"], quantity=r["quantity"]) for r in rows]


@app.get("/stock/{product_id}", response_model=StockRow)
async def get_stock(product_id: int):
    row = await db.pool().fetchrow("SELECT product_id, quantity FROM stock WHERE product_id = $1", product_id)
    if row is None:
        raise HTTPException(404, "product not found in inventory")
    return StockRow(product_id=row["product_id"], quantity=row["quantity"])


@app.post("/stock/{product_id}/decrement", response_model=StockRow)
async def decrement_stock(product_id: int, body: DecrementRequest):
    """Atomic decrement: fails if not enough stock. Used by orders-svc at checkout."""
    async with db.pool().acquire() as conn:
        async with conn.transaction():
            row = await conn.fetchrow(
                """
                UPDATE stock
                   SET quantity = quantity - $2
                 WHERE product_id = $1 AND quantity >= $2
                 RETURNING product_id, quantity
                """,
                product_id,
                body.quantity,
            )
            if row is None:
                exists = await conn.fetchval("SELECT 1 FROM stock WHERE product_id = $1", product_id)
                if exists is None:
                    DECREMENT_FAIL.labels(reason="not_found").inc()
                    raise HTTPException(404, "product not found in inventory")
                DECREMENT_FAIL.labels(reason="insufficient").inc()
                raise HTTPException(409, "insufficient stock")
            return StockRow(product_id=row["product_id"], quantity=row["quantity"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
