let schemaReady = false;

export function d1(env) {
  const db = env && env.DB;
  if (!db || typeof db.prepare !== "function") return null;
  return db;
}

export async function ensureSchema(env) {
  if (schemaReady) return;
  const db = d1(env);
  if (!db) {
    const err = new Error("no_d1");
    err.code = "d1";
    throw err;
  }
  await db.batch([
    db.prepare(`CREATE TABLE IF NOT EXISTS users (
      email TEXT PRIMARY KEY,
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      shop_name TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_email TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )`),
    db.prepare(
      `CREATE INDEX IF NOT EXISTS idx_sessions_email ON sessions(user_email)`,
    ),
    db.prepare(`CREATE TABLE IF NOT EXISTS lots (
      user_email TEXT PRIMARY KEY,
      payload TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS hits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at INTEGER NOT NULL,
      day TEXT NOT NULL,
      visitor_hash TEXT NOT NULL,
      country TEXT NOT NULL DEFAULT 'unknown'
    )`),
    db.prepare(`CREATE INDEX IF NOT EXISTS idx_hits_day ON hits(day)`),
    db.prepare(
      `CREATE INDEX IF NOT EXISTS idx_hits_created ON hits(created_at)`,
    ),
    db.prepare(`CREATE TABLE IF NOT EXISTS admin_sessions (
      token TEXT PRIMARY KEY,
      created_at INTEGER NOT NULL,
      expires_at INTEGER NOT NULL
    )`),
  ]);
  await ensureUserCountryColumn(db);
  schemaReady = true;
}

async function ensureUserCountryColumn(db) {
  const info = await db.prepare("PRAGMA table_info(users)").all();
  const rows = (info && info.results) || [];
  const hasCountry = rows.some((col) => col && col.name === "country");
  if (hasCountry) return;
  try {
    await db.prepare("ALTER TABLE users ADD COLUMN country TEXT").run();
  } catch (err) {
    const msg = String((err && err.message) || err);
    if (!/duplicate column/i.test(msg)) throw err;
  }
}

export function emptyLotsPayload() {
  return {
    lots: [],
    pricePerDayGrosze: 0,
    sectorCount: 3,
    shopJournalHydrated: "",
  };
}

export function parsePayload(raw) {
  if (!raw) return emptyLotsPayload();
  try {
    const map = typeof raw === "string" ? JSON.parse(raw) : raw;
    if (!map || typeof map !== "object") return emptyLotsPayload();
    const lots = Array.isArray(map.lots) ? map.lots : [];
    const price = Number(map.pricePerDayGrosze) || 0;
    let sectors = Number(map.sectorCount);
    if (!Number.isFinite(sectors) || sectors < 1) sectors = 3;
    if (sectors > 12) sectors = 12;
    return {
      lots,
      pricePerDayGrosze: price < 0 ? 0 : price,
      sectorCount: sectors,
      shopJournalHydrated: String(map.shopJournalHydrated || ""),
    };
  } catch {
    return emptyLotsPayload();
  }
}
