import { Link, useLocation, useParams } from "react-router-dom";
import { formatPrice } from "../api";
import type { Order } from "../types";

export default function OrderConfirmation() {
  const { id } = useParams<{ id: string }>();
  const { state } = useLocation() as { state: { order?: Order } };
  const order = state?.order;

  return (
    <div className="bg-white rounded-2xl p-8 shadow-sm max-w-2xl mx-auto text-center">
      <div className="text-5xl mb-3">🎉</div>
      <h1 className="font-display text-3xl mb-2">Thanks for your order!</h1>
      <p className="text-cocoa/70 mb-6">Order #{id} is confirmed. We'll have it ready soon.</p>

      {order && (
        <div className="text-left border-t border-cocoa/10 pt-4 mb-6">
          <ul className="divide-y divide-cocoa/10">
            {order.items.map(i => (
              <li key={i.product_id} className="flex justify-between py-2 text-sm">
                <span>{i.name} × {i.quantity}</span>
                <span>{formatPrice(i.unit_price_cents * i.quantity)}</span>
              </li>
            ))}
          </ul>
          <div className="flex justify-between pt-3 mt-3 border-t border-cocoa/10 font-semibold">
            <span>Total</span>
            <span>{formatPrice(order.total_cents)}</span>
          </div>
        </div>
      )}

      <Link to="/" className="bg-crust text-cream px-6 py-3 rounded-full font-semibold hover:bg-cocoa transition">
        Keep shopping
      </Link>
    </div>
  );
}
