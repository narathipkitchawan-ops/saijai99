-- Saijai 99 order foundation. No commercial values are seeded.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  sku TEXT UNIQUE,
  category TEXT NOT NULL CHECK (category IN ('chicken','pork')),
  name TEXT NOT NULL,
  unit TEXT,
  description TEXT,
  price_satang INTEGER CHECK (price_satang IS NULL OR price_satang >= 0),
  stock_quantity REAL CHECK (stock_quantity IS NULL OR stock_quantity >= 0),
  availability TEXT NOT NULL DEFAULT 'unconfigured' CHECK (availability IN ('unconfigured','available','unavailable','out_of_stock')),
  is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1)),
  source_note TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS delivery_zones (
  id TEXT PRIMARY KEY,
  zone_code TEXT UNIQUE,
  province TEXT NOT NULL,
  district TEXT,
  subdistrict TEXT,
  delivery_fee_satang INTEGER CHECK (delivery_fee_satang IS NULL OR delivery_fee_satang >= 0),
  minimum_order_satang INTEGER CHECK (minimum_order_satang IS NULL OR minimum_order_satang >= 0),
  delivery_schedule TEXT,
  is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1)),
  source_note TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY,
  line_user_id TEXT UNIQUE,
  display_name TEXT,
  phone TEXT,
  address TEXT,
  province TEXT,
  district TEXT,
  subdistrict TEXT,
  postal_code TEXT,
  consent_status TEXT NOT NULL DEFAULT 'unknown' CHECK (consent_status IN ('unknown','granted','withdrawn')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  order_no TEXT NOT NULL UNIQUE,
  customer_id TEXT REFERENCES customers(id),
  line_user_id TEXT,
  customer_name TEXT,
  phone TEXT,
  delivery_address TEXT,
  province TEXT,
  district TEXT,
  subdistrict TEXT,
  postal_code TEXT,
  delivery_zone_id TEXT REFERENCES delivery_zones(id),
  subtotal_satang INTEGER CHECK (subtotal_satang IS NULL OR subtotal_satang >= 0),
  delivery_fee_satang INTEGER CHECK (delivery_fee_satang IS NULL OR delivery_fee_satang >= 0),
  total_satang INTEGER CHECK (total_satang IS NULL OR total_satang >= 0),
  pricing_status TEXT NOT NULL DEFAULT 'unquoted' CHECK (pricing_status IN ('unquoted','quoted','expired','verified')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','pending_review','quoted','awaiting_customer_confirmation','confirmed','processing','dispatched','completed','cancelled')),
  customer_note TEXT,
  staff_note TEXT,
  confirmed_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id TEXT REFERENCES products(id),
  product_name_snapshot TEXT NOT NULL,
  sku_snapshot TEXT,
  quantity REAL NOT NULL CHECK (quantity > 0),
  unit_snapshot TEXT,
  unit_price_satang INTEGER CHECK (unit_price_satang IS NULL OR unit_price_satang >= 0),
  line_total_satang INTEGER CHECK (line_total_satang IS NULL OR line_total_satang >= 0),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS webhook_events (
  webhook_event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  line_user_id TEXT,
  received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  processed_at TEXT,
  processing_status TEXT NOT NULL DEFAULT 'received' CHECK (processing_status IN ('received','processed','ignored','failed'))
);

CREATE TABLE IF NOT EXISTS order_events (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  from_status TEXT,
  to_status TEXT,
  actor_type TEXT NOT NULL CHECK (actor_type IN ('customer','staff','system')),
  actor_id TEXT,
  detail_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_category_active ON products(category,is_active);
CREATE INDEX IF NOT EXISTS idx_delivery_zone_lookup ON delivery_zones(province,district,subdistrict,is_active);
CREATE INDEX IF NOT EXISTS idx_orders_status_created ON orders(status,created_at);
CREATE INDEX IF NOT EXISTS idx_orders_line_user ON orders(line_user_id,created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_events_order ON order_events(order_id,created_at);
