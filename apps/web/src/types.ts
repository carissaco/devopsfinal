export interface Product {
  id: number;
  name: string;
  category: string;
  priceCents: number;
  imageUrl: string;
  description: string;
}

export interface Stock {
  product_id: number;
  quantity: number;
}

export interface CartItem {
  productId: number;
  name: string;
  priceCents: number;
  quantity: number;
  imageUrl: string;
}

export interface OrderItem {
  product_id: number;
  name: string;
  quantity: number;
  unit_price_cents: number;
}

export interface Order {
  id: number;
  customer_name: string;
  customer_email: string;
  placed_at: string;
  total_cents: number;
  items: OrderItem[];
}
