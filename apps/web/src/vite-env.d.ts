/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_CATALOG_URL?: string;
  readonly VITE_ORDERS_URL?: string;
  readonly VITE_INVENTORY_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
