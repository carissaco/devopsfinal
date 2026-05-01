import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, formatPrice } from "../api";
import type { Product } from "../types";
import { useCart } from "../cart";

export default function ProductDetail() {
  const { id } = useParams<{ id: string }>();
  const [product, setProduct] = useState<Product | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [qty, setQty] = useState(1);
  const { add } = useCart();

  useEffect(() => {
    if (!id) return;
    api.getProduct(Number(id))
      .then(setProduct)
      .catch(e => setError(e.message));
  }, [id]);

  if (error) return <p className="text-red-700">Couldn't load product: {error}</p>;
  if (!product) return <p>Loading…</p>;

  return (
    <article className="grid md:grid-cols-2 gap-10 bg-white rounded-2xl overflow-hidden shadow-sm p-6">
      <img src={product.imageUrl} alt={product.name} className="w-full h-80 object-cover rounded-xl" />
      <div className="flex flex-col justify-between">
        <div>
          <p className="uppercase text-xs tracking-wider text-cocoa/60 mb-2">{product.category}</p>
          <h1 className="font-display text-4xl mb-3">{product.name}</h1>
          <p className="text-cocoa/80 mb-6">{product.description}</p>
          <p className="text-3xl font-semibold mb-6">{formatPrice(product.priceCents)}</p>
        </div>
        <div className="flex items-center gap-3">
          <input
            type="number"
            min={1}
            value={qty}
            onChange={e => setQty(Math.max(1, Number(e.target.value)))}
            className="w-20 px-3 py-2 border border-cocoa/20 rounded-lg"
          />
          <button
            onClick={() => add(product, qty)}
            className="flex-1 bg-crust text-cream px-5 py-3 rounded-full font-semibold hover:bg-cocoa transition"
          >
            Add to cart
          </button>
          <Link to="/" className="text-sm text-cocoa/70 underline">Back</Link>
        </div>
      </div>
    </article>
  );
}
