CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS garages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  street TEXT NOT NULL,
  postal TEXT NOT NULL,
  city TEXT NOT NULL,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  phone TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS garage_i18n (
  garage_id TEXT NOT NULL,
  lang TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (garage_id, lang)
);

CREATE TABLE IF NOT EXISTS garage_hours (
  garage_id TEXT NOT NULL,
  weekday INTEGER NOT NULL,
  open_min INTEGER,
  close_min INTEGER,
  PRIMARY KEY (garage_id, weekday)
);

CREATE TABLE IF NOT EXISTS schedule_exceptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  garage_id TEXT NOT NULL,
  date TEXT NOT NULL,
  kind TEXT NOT NULL,
  start_min INTEGER,
  end_min INTEGER,
  note TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS services (
  id TEXT PRIMARY KEY,
  duration_min INTEGER NOT NULL,
  price_cents INTEGER,
  sort INTEGER NOT NULL,
  active INTEGER NOT NULL DEFAULT 1,
  bookable INTEGER NOT NULL DEFAULT 1,
  kind TEXT NOT NULL DEFAULT 'workshop',
  image TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS service_i18n (
  service_id TEXT NOT NULL,
  lang TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  body TEXT NOT NULL,
  PRIMARY KEY (service_id, lang)
);

CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vehicles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER,
  plate TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  garage_id TEXT NOT NULL,
  service_id TEXT NOT NULL,
  customer_id INTEGER NOT NULL,
  vehicle_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  start_min INTEGER NOT NULL,
  end_min INTEGER NOT NULL,
  problem TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'requested',
  lang TEXT NOT NULL DEFAULT 'nl',
  reminder_at TEXT,
  reminder_sent INTEGER NOT NULL DEFAULT 0,
  next_service_on TEXT,
  next_service_note TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS tow_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  pickup TEXT NOT NULL,
  delivery TEXT NOT NULL,
  make TEXT NOT NULL DEFAULT '',
  model TEXT NOT NULL DEFAULT '',
  running INTEGER NOT NULL DEFAULT 1,
  desired_date TEXT NOT NULL DEFAULT '',
  desired_time TEXT NOT NULL DEFAULT '',
  contact_name TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  contact_email TEXT NOT NULL DEFAULT '',
  urgent INTEGER NOT NULL DEFAULT 0,
  notes TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'new',
  lang TEXT NOT NULL DEFAULT 'nl',
  customer_id INTEGER,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS uploads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id INTEGER,
  tow_id INTEGER,
  post_id INTEGER,
  public INTEGER NOT NULL DEFAULT 0,
  name TEXT NOT NULL DEFAULT '',
  mime TEXT NOT NULL,
  data TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,
  image TEXT NOT NULL DEFAULT '',
  published INTEGER NOT NULL DEFAULT 1,
  sort INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS post_i18n (
  post_id INTEGER NOT NULL,
  lang TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (post_id, lang)
);

CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel TEXT NOT NULL,
  kind TEXT NOT NULL,
  ref_type TEXT NOT NULL,
  ref_id INTEGER NOT NULL,
  payload TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'stored',
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_bookings_slot ON bookings (garage_id, date, status);
CREATE INDEX IF NOT EXISTS idx_vehicles_customer ON vehicles (customer_id);
CREATE INDEX IF NOT EXISTS idx_exceptions_day ON schedule_exceptions (garage_id, date);
CREATE INDEX IF NOT EXISTS idx_tows_created ON tow_requests (created_at);
CREATE INDEX IF NOT EXISTS idx_uploads_booking ON uploads (booking_id);
CREATE INDEX IF NOT EXISTS idx_uploads_tow ON uploads (tow_id);
