CREATE TABLE stock (
    product_id BIGINT PRIMARY KEY,
    quantity   INTEGER NOT NULL CHECK (quantity >= 0)
);
