import type { Order, Product, Stock } from "./types";

const CATALOG_URL = import.meta.env.VITE_CATALOG_URL ?? "http://localhost:8081";
const ORDERS_URL = import.meta.env.VITE_ORDERS_URL ?? "http://localhost:8083";
const INVENTORY_URL = import.meta.env.VITE_INVENTORY_URL ?? "http://localhost:8082";

async function jsonOrThrow<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let detail = res.statusText;
    try {
      const body = await res.json();
      if (body?.detail) detail = body.detail;
    } catch {
      // ignore
    }
    throw new Error(detail);
  }
  return res.json() as Promise<T>;
}

export const api = {
  listProducts: () => fetch(`${CATALOG_URL}/products`).then(jsonOrThrow<Product[]>),
  getProduct: (id: number) => fetch(`${CATALOG_URL}/products/${id}`).then(jsonOrThrow<Product>),
  listStock: () => fetch(`${INVENTORY_URL}/stock`).then(jsonOrThrow<Stock[]>),
  placeOrder: (body: {
    customer_name: string;
    customer_email: string;
    items: { product_id: number; quantity: number }[];
  }) =>
    fetch(`${ORDERS_URL}/orders`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }).then(jsonOrThrow<Order>),
  listOrders: (email: string) =>
    fetch(`${ORDERS_URL}/orders?email=${encodeURIComponent(email)}`).then(jsonOrThrow<Order[]>),
};

export const formatPrice = (cents: number) =>
  `$${(cents / 100).toFixed(2)}`;
