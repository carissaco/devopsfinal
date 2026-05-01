import { createContext, useContext, useEffect, useMemo, useState, ReactNode } from "react";
import type { CartItem, Product } from "./types";

interface CartCtx {
  items: CartItem[];
  add: (p: Product, qty?: number) => void;
  setQty: (productId: number, qty: number) => void;
  remove: (productId: number) => void;
  clear: () => void;
  totalCents: number;
  itemCount: number;
}

const Ctx = createContext<CartCtx | null>(null);
const STORAGE_KEY = "bakery.cart";

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartItem[]>(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? (JSON.parse(raw) as CartItem[]) : [];
    } catch {
      return [];
    }
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
  }, [items]);

  const value = useMemo<CartCtx>(() => {
    const totalCents = items.reduce((s, i) => s + i.priceCents * i.quantity, 0);
    const itemCount = items.reduce((s, i) => s + i.quantity, 0);
    return {
      items,
      totalCents,
      itemCount,
      add: (p, qty = 1) =>
        setItems(prev => {
          const existing = prev.find(i => i.productId === p.id);
          if (existing) {
            return prev.map(i =>
              i.productId === p.id ? { ...i, quantity: i.quantity + qty } : i,
            );
          }
          return [
            ...prev,
            {
              productId: p.id,
              name: p.name,
              priceCents: p.priceCents,
              quantity: qty,
              imageUrl: p.imageUrl,
            },
          ];
        }),
      setQty: (productId, qty) =>
        setItems(prev =>
          qty <= 0
            ? prev.filter(i => i.productId !== productId)
            : prev.map(i => (i.productId === productId ? { ...i, quantity: qty } : i)),
        ),
      remove: productId => setItems(prev => prev.filter(i => i.productId !== productId)),
      clear: () => setItems([]),
    };
  }, [items]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useCart(): CartCtx {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useCart must be used inside CartProvider");
  return ctx;
}
