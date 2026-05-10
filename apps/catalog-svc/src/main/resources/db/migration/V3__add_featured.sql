ALTER TABLE products ADD COLUMN is_featured BOOLEAN NOT NULL DEFAULT false;

UPDATE products SET is_featured = true WHERE id IN (1, 5);
