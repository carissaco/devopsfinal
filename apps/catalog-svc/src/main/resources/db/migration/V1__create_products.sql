CREATE TABLE products (
    id          BIGINT PRIMARY KEY,
    name        TEXT NOT NULL,
    category    TEXT NOT NULL,
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    image_url   TEXT,
    description TEXT
);
