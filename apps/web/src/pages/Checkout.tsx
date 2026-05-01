import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api, formatPrice } from "../api";
import { useCart } from "../cart";

export default function Checkout() {
  const { items, totalCents, setQty, remove, clear } = useCart();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const order = await api.placeOrder({
        customer_name: name,
        customer_email: email,
        items: items.map(i => ({ product_id: i.productId, quantity: i.quantity })),
      });
      clear();
      navigate(`/orders/confirmation/${order.id}`, { state: { order } });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSubmitting(false);
    }
  };

  if (items.length === 0) {
    return (
      <div className="text-center py-20">
        <h1 className="font-display text-3xl mb-3">Your cart is empty</h1>
        <p className="mb-6 text-cocoa/70">Browse our fresh-baked goods and add something delicious.</p>
        <Link to="/" className="bg-crust text-cream px-6 py-3 rounded-full font-semibold hover:bg-cocoa transition">
          Shop now
        </Link>
      </div>
    );
  }

  return (
    <div className="grid md:grid-cols-3 gap-8">
      <section className="md:col-span-2 bg-white rounded-2xl p-6 shadow-sm">
        <h1 className="font-display text-3xl mb-5">Your cart</h1>
        <ul className="divide-y divide-cocoa/10">
          {items.map(i => (
            <li key={i.productId} className="flex items-center gap-4 py-4">
              <img src={i.imageUrl} alt={i.name} className="w-20 h-20 object-cover rounded-lg" />
              <div className="flex-1">
                <p className="font-semibold">{i.name}</p>
                <p className="text-sm text-cocoa/70">{formatPrice(i.priceCents)} each</p>
              </div>
              <input
                type="number"
                min={0}
                value={i.quantity}
                onChange={e => setQty(i.productId, Number(e.target.value))}
                className="w-16 px-2 py-1 border border-cocoa/20 rounded-lg"
              />
              <p className="w-20 text-right font-semibold">{formatPrice(i.priceCents * i.quantity)}</p>
              <button
                onClick={() => remove(i.productId)}
                className="text-cocoa/50 hover:text-red-700"
                aria-label={`Remove ${i.name}`}
              >
                ✕
              </button>
            </li>
          ))}
        </ul>
      </section>

      <aside className="bg-white rounded-2xl p-6 shadow-sm">
        <h2 className="font-display text-2xl mb-4">Checkout</h2>
        <form onSubmit={submit} className="space-y-3">
          <label className="block">
            <span className="text-sm text-cocoa/70">Name</span>
            <input
              required
              value={name}
              onChange={e => setName(e.target.value)}
              className="mt-1 w-full px-3 py-2 border border-cocoa/20 rounded-lg"
            />
          </label>
          <label className="block">
            <span className="text-sm text-cocoa/70">Email</span>
            <input
              type="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="mt-1 w-full px-3 py-2 border border-cocoa/20 rounded-lg"
            />
          </label>

          <div className="border-t border-cocoa/10 pt-4 flex justify-between text-lg font-semibold">
            <span>Total</span>
            <span>{formatPrice(totalCents)}</span>
          </div>

          {error && <p className="text-red-700 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={submitting}
            className="w-full bg-crust text-cream py-3 rounded-full font-semibold hover:bg-cocoa disabled:opacity-50 transition"
          >
            {submitting ? "Placing order…" : "Place order"}
          </button>
        </form>
      </aside>
    </div>
  );
}
