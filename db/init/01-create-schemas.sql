-- Bootstraps per-service schemas in the shared bakery database.
-- Each microservice owns its own schema; cross-service queries are forbidden by convention.
CREATE SCHEMA IF NOT EXISTS catalog;
CREATE SCHEMA IF NOT EXISTS orders;
CREATE SCHEMA IF NOT EXISTS inventory;
