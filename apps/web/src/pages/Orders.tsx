import { useState } from "react";
import { api, formatPrice } from "../api";
import type { Order } from "../types";

export default function Orders() {
  const [email, setEmail] = useState("");
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const lookup = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    setOrders(null);
    try {
      setOrders(await api.listOrders(email));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="font-display text-3xl mb-2">Your orders</h1>
      <p className="text-cocoa/70 mb-6">Look up past orders by the email you used at checkout.</p>

      <form onSubmit={lookup} className="flex gap-2 mb-8">
        <input
          type="email"
          required
          placeholder="you@example.com"
          value={email}
          onChange={e => setEmail(e.target.value)}
          className="flex-1 px-4 py-2 border border-cocoa/20 rounded-full bg-white"
        />
        <button
          type="submit"
          className="bg-crust text-cream px-5 py-2 rounded-full font-semibold hover:bg-cocoa transition"
        >
          Look up
        </button>
      </form>

      {loading && <p>Loading…</p>}
      {error && <p className="text-red-700">{error}</p>}
      {orders && orders.length === 0 && (
        <p className="text-cocoa/70">No orders found for that email.</p>
      )}
      {orders && orders.length > 0 && (
        <ul className="space-y-4">
          {orders.map(o => (
            <li key={o.id} className="bg-white rounded-2xl p-5 shadow-sm">
              <div className="flex justify-between mb-2">
                <p className="font-semibold">Order #{o.id}</p>
                <p className="text-sm text-cocoa/70">{new Date(o.placed_at).toLocaleString()}</p>
              </div>
              <ul className="text-sm divide-y divide-cocoa/10">
                {o.items.map(i => (
                  <li key={i.product_id} className="flex justify-between py-1.5">
                    <span>{i.name} × {i.quantity}</span>
                    <span>{formatPrice(i.unit_price_cents * i.quantity)}</span>
                  </li>
                ))}
              </ul>
              <div className="flex justify-between pt-3 mt-2 border-t border-cocoa/10 font-semibold">
                <span>Total</span>
                <span>{formatPrice(o.total_cents)}</span>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
