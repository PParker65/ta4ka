CREATE TABLE IF NOT EXISTS hits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at INTEGER NOT NULL,
  day TEXT NOT NULL,
  visitor_hash TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'unknown'
);

CREATE INDEX IF NOT EXISTS idx_hits_day ON hits(day);
CREATE INDEX IF NOT EXISTS idx_hits_created ON hits(created_at);

CREATE TABLE IF NOT EXISTS admin_sessions (
  token TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

ALTER TABLE users ADD COLUMN country TEXT;
