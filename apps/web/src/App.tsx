import { Link, Route, Routes } from "react-router-dom";
import { useCart } from "./cart";
import ProductList from "./pages/ProductList";
import ProductDetail from "./pages/ProductDetail";
import Checkout from "./pages/Checkout";
import Orders from "./pages/Orders";
import OrderConfirmation from "./pages/OrderConfirmation";

export default function App() {
  const { itemCount } = useCart();

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-cocoa text-cream shadow-md">
        <div className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between">
          <Link to="/" className="font-display text-3xl tracking-wide">
            🥐 Carissa Bakery
          </Link>
          <nav className="flex gap-6 text-sm font-medium">
            <Link to="/" className="hover:text-butter">Shop</Link>
            <Link to="/orders" className="hover:text-butter">My Orders</Link>
            <Link to="/checkout" className="relative hover:text-butter">
              Cart
              {itemCount > 0 && (
                <span className="ml-2 inline-flex items-center justify-center bg-butter text-cocoa rounded-full text-xs w-6 h-6 font-bold">
                  {itemCount}
                </span>
              )}
            </Link>
          </nav>
        </div>
      </header>

      <main className="flex-1 max-w-6xl w-full mx-auto px-6 py-10">
        <Routes>
          <Route path="/" element={<ProductList />} />
          <Route path="/products/:id" element={<ProductDetail />} />
          <Route path="/checkout" element={<Checkout />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/orders/confirmation/:id" element={<OrderConfirmation />} />
        </Routes>
      </main>

      <footer className="bg-cocoa text-cream/70 text-sm">
        <div className="max-w-6xl mx-auto px-6 py-6 text-center">
          Baked fresh daily · DevOps final demo
        </div>
      </footer>
    </div>
  );
}
