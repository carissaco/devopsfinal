import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api, formatPrice } from "../api";
import type { Product } from "../types";
import { useCart } from "../cart";

export default function ProductList() {
  const [products, setProducts] = useState<Product[] | null>(null);
  const [stock, setStock] = useState<Record<number, number>>({});
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<string>("All");
  const { add } = useCart();

  useEffect(() => {
    Promise.all([api.listProducts(), api.listStock()])
      .then(([ps, ss]) => {
        setProducts(ps);
        setStock(Object.fromEntries(ss.map(s => [s.product_id, s.quantity])));
      })
      .catch(e => setError(e.message));
  }, []);

  const categories = useMemo(() => {
    if (!products) return [];
    return ["All", ...Array.from(new Set(products.map(p => p.category)))];
  }, [products]);

  const visible = useMemo(
    () => (products ?? []).filter(p => filter === "All" || p.category === filter),
    [products, filter],
  );

  if (error) return <p className="text-red-700">Couldn't load products: {error}</p>;
  if (!products) return <p>Loading the bakery…</p>;

  return (
    <div>
      <section className="mb-10 text-center">
        <h1 className="font-display text-5xl mb-3">Fresh from the oven.</h1>
        <p className="text-cocoa/80 max-w-xl mx-auto">
          Small-batch cookies, cakes, and pastries baked every morning. Order online; we'll have it ready.
        </p>
      </section>

      <div className="flex gap-2 flex-wrap mb-6">
        {categories.map(c => (
          <button
            key={c}
            onClick={() => setFilter(c)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition ${
              filter === c
                ? "bg-cocoa text-cream"
                : "bg-white text-cocoa hover:bg-butter"
            }`}
          >
            {c}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {visible.map(p => {
          const qty = stock[p.id] ?? 0;
          const lowStock = qty > 0 && qty < 5;
          const out = qty === 0;
          return (
            <article
              key={p.id}
              className="bg-white rounded-2xl overflow-hidden shadow-sm hover:shadow-lg transition"
            >
              <Link to={`/products/${p.id}`}>
                <img src={p.imageUrl} alt={p.name} className="w-full h-48 object-cover" />
              </Link>
              <div className="p-5">
                <div className="flex items-start justify-between mb-1">
                  <h2 className="font-display text-xl">{p.name}</h2>
                  <span className="font-semibold">{formatPrice(p.priceCents)}</span>
                </div>
                <p className="text-sm text-cocoa/70 mb-4">{p.description}</p>
                <div className="flex items-center justify-between">
                  <span className={`text-xs ${out ? "text-red-700" : lowStock ? "text-crust" : "text-cocoa/60"}`}>
                    {out ? "Sold out" : lowStock ? `Only ${qty} left` : `${qty} in stock`}
                  </span>
                  <button
                    onClick={() => add(p)}
                    disabled={out}
                    className="bg-crust text-cream px-4 py-2 rounded-full text-sm font-semibold hover:bg-cocoa disabled:opacity-50 disabled:cursor-not-allowed transition"
                  >
                    Add to cart
                  </button>
                </div>
              </div>
            </article>
          );
        })}
      </div>
    </div>
  );
}
