ALTER TABLE products ADD COLUMN is_new BOOLEAN NOT NULL DEFAULT false;

UPDATE products SET is_new = true WHERE id IN (7, 8);
