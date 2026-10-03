CREATE TABLE IF NOT EXISTS users (
  email TEXT PRIMARY KEY,
  password_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  shop_name TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  user_email TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_email ON sessions(user_email);

CREATE TABLE IF NOT EXISTS lots (
  user_email TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
