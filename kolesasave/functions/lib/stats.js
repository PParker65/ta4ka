import { d1, ensureSchema } from "./db.js";

const ZONE = "Europe/Warsaw";

export function requestCountry(request) {
  let raw = "";
  if (request && request.cf && request.cf.country) {
    raw = String(request.cf.country);
  }
  if (!raw && request && request.headers) {
    raw = String(request.headers.get("cf-ipcountry") || "");
  }
  raw = raw.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(raw) || raw === "XX" || raw === "T1") return "unknown";
  return raw;
}

export function isPublicDocument(pathname, request) {
  if (!request || request.method !== "GET") return false;
  const path = pathname || "/";
  if (path === "/api" || path.startsWith("/api/")) return false;
  if (path === "/admin" || path.startsWith("/admin/")) return false;
  if (path.startsWith("/cdn-cgi/")) return false;
  const last = path.split("/").filter(Boolean).pop() || "";
  const dot = last.lastIndexOf(".");
  if (dot > 0) {
    const ext = last.slice(dot + 1).toLowerCase();
    if (ext !== "html") return false;
  }
  const dest = String(request.headers.get("sec-fetch-dest") || "").toLowerCase();
  if (dest && dest !== "document") return false;
  const purpose = String(
    request.headers.get("sec-purpose") || request.headers.get("purpose") || "",
  ).toLowerCase();
  if (purpose.includes("prefetch") || purpose.includes("preview")) return false;
  return true;
}

export function warsawDayKey(ts) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date(ts));
}

export function addDays(dayKey, delta) {
  const [y, m, d] = String(dayKey).split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + delta));
  const y2 = dt.getUTCFullYear();
  const m2 = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const d2 = String(dt.getUTCDate()).padStart(2, "0");
  return `${y2}-${m2}-${d2}`;
}

export function warsawStartMs(dayKey) {
  const [y, m, d] = String(dayKey).split("-").map(Number);
  let utc = Date.UTC(y, m - 1, d, 0, 0, 0);
  const dtf = new Intl.DateTimeFormat("en-US", {
    timeZone: ZONE,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
  for (let i = 0; i < 4; i++) {
    const map = {};
    for (const part of dtf.formatToParts(new Date(utc))) {
      if (part.type !== "literal") map[part.type] = part.value;
    }
    let hour = Number(map.hour);
    if (hour === 24) hour = 0;
    const asUtc = Date.UTC(
      Number(map.year),
      Number(map.month) - 1,
      Number(map.day),
      hour,
      Number(map.minute),
      Number(map.second),
    );
    const diff = Date.UTC(y, m - 1, d, 0, 0, 0) - asUtc;
    if (diff === 0) break;
    utc += diff;
  }
  return utc;
}

export function formatWarsaw(ts) {
  const n = Number(ts);
  if (!Number.isFinite(n) || n <= 0) return "—";
  const ms = n < 1e12 ? n * 1000 : n;
  const dtf = new Intl.DateTimeFormat("en-CA", {
    timeZone: ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
  const map = {};
  for (const part of dtf.formatToParts(new Date(ms))) {
    if (part.type !== "literal") map[part.type] = part.value;
  }
  const hour = map.hour === "24" ? "00" : map.hour;
  return `${map.year}-${map.month}-${map.day} ${hour}:${map.minute}`;
}

async function sha256Hex(text) {
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(buf)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export async function recordPageHit(context) {
  const request = context.request;
  const url = new URL(request.url);
  if (!isPublicDocument(url.pathname, request)) return;
  try {
    await ensureSchema(context.env);
    const db = d1(context.env);
    if (!db) return;
    const day = warsawDayKey(Date.now());
    const ip = request.headers.get("cf-connecting-ip") || "";
    const visitor = await sha256Hex(
      `kolesasave.hit.v1\u001f${day}\u001f${ip}`,
    );
    const country = requestCountry(request);
    await db
      .prepare(
        "INSERT INTO hits (created_at, day, visitor_hash, country) VALUES (?, ?, ?, ?)",
      )
      .bind(Date.now(), day, visitor, country)
      .run();
  } catch {
    // A failed hit write must not affect the page.
  }
}

function num(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function rowsOf(result) {
  if (!result) return [];
  if (Array.isArray(result.results)) return result.results;
  if (Array.isArray(result)) return result;
  return [];
}

export async function loadAdminStats(db) {
  const now = Date.now();
  const today = warsawDayKey(now);
  const yesterday = addDays(today, -1);
  const d7 = addDays(today, -6);
  const d30 = addDays(today, -29);
  const todayStart = warsawStartMs(today);
  const yStart = warsawStartMs(yesterday);
  const d7Start = warsawStartMs(d7);
  const d30Start = warsawStartMs(d30);

  const hits = await db
    .prepare(
      `SELECT
         COUNT(*) AS total,
         COUNT(DISTINCT visitor_hash) AS uniq,
         SUM(CASE WHEN day = ?1 THEN 1 ELSE 0 END) AS today,
         COUNT(DISTINCT CASE WHEN day = ?1 THEN visitor_hash END) AS uniq_today,
         SUM(CASE WHEN day = ?2 THEN 1 ELSE 0 END) AS yesterday,
         COUNT(DISTINCT CASE WHEN day = ?2 THEN visitor_hash END) AS uniq_yesterday,
         SUM(CASE WHEN day >= ?2 THEN 1 ELSE 0 END) AS since_y,
         COUNT(DISTINCT CASE WHEN day >= ?2 THEN visitor_hash END) AS uniq_since_y,
         SUM(CASE WHEN day >= ?3 THEN 1 ELSE 0 END) AS d7,
         COUNT(DISTINCT CASE WHEN day >= ?3 THEN visitor_hash END) AS uniq_d7,
         SUM(CASE WHEN day >= ?4 THEN 1 ELSE 0 END) AS d30,
         COUNT(DISTINCT CASE WHEN day >= ?4 THEN visitor_hash END) AS uniq_d30
       FROM hits`,
    )
    .bind(today, yesterday, d7, d30)
    .first();

  const countryRes = await db
    .prepare(
      `SELECT country, COUNT(*) AS hits, COUNT(DISTINCT visitor_hash) AS uniq
       FROM hits
       GROUP BY country
       ORDER BY hits DESC, country ASC`,
    )
    .all();

  const dailyRes = await db
    .prepare(
      `SELECT day, COUNT(*) AS hits, COUNT(DISTINCT visitor_hash) AS uniq
       FROM hits
       WHERE day >= ?1
       GROUP BY day`,
    )
    .bind(d30)
    .all();

  const users = await db
    .prepare(
      `SELECT
         COUNT(*) AS total,
         SUM(CASE WHEN created_at >= ?1 THEN 1 ELSE 0 END) AS today,
         SUM(CASE WHEN created_at >= ?2 AND created_at < ?1 THEN 1 ELSE 0 END) AS yesterday,
         SUM(CASE WHEN created_at >= ?2 THEN 1 ELSE 0 END) AS since_y,
         SUM(CASE WHEN created_at >= ?3 THEN 1 ELSE 0 END) AS d7,
         SUM(CASE WHEN created_at >= ?4 THEN 1 ELSE 0 END) AS d30,
         MAX(created_at) AS last_at
       FROM users`,
    )
    .bind(todayStart, yStart, d7Start, d30Start)
    .first();

  const recentRes = await db
    .prepare(
      "SELECT email, created_at FROM users ORDER BY created_at DESC LIMIT 20",
    )
    .all();

  let regCountries = [];
  try {
    const regRes = await db
      .prepare(
        `SELECT COALESCE(NULLIF(TRIM(country), ''), 'unknown') AS country, COUNT(*) AS n
         FROM users
         GROUP BY 1
         ORDER BY n DESC, country ASC`,
      )
      .all();
    regCountries = rowsOf(regRes);
  } catch {
    regCountries = [];
  }

  let lots = null;
  try {
    lots = await db
      .prepare(
        `SELECT
           SUM(CASE WHEN COALESCE(json_array_length(json_extract(payload, '$.lots')), 0) > 0 THEN 1 ELSE 0 END) AS active_users,
           SUM(COALESCE(json_array_length(json_extract(payload, '$.lots')), 0)) AS lot_count,
           COUNT(*) AS lot_rows
         FROM lots`,
      )
      .first();
  } catch {
    lots = null;
  }

  const hitTotal = num(hits && hits.total);
  const countries = rowsOf(countryRes).map((row) => ({
    country: row.country || "unknown",
    hits: num(row.hits),
    uniq: num(row.uniq),
    share: hitTotal ? num(row.hits) / hitTotal : 0,
  }));

  const byDay = new Map();
  for (const row of rowsOf(dailyRes)) {
    byDay.set(String(row.day), { hits: num(row.hits), uniq: num(row.uniq) });
  }
  const daily = [];
  for (let i = 0; i < 30; i++) {
    const day = addDays(today, -i);
    const found = byDay.get(day) || { hits: 0, uniq: 0 };
    daily.push({ day, hits: found.hits, uniq: found.uniq });
  }

  const userTotal = num(users && users.total);
  return {
    now,
    today,
    yesterday,
    d7,
    d30,
    hits: {
      total: hitTotal,
      uniq: num(hits && hits.uniq),
      today: num(hits && hits.today),
      uniqToday: num(hits && hits.uniq_today),
      yesterday: num(hits && hits.yesterday),
      uniqYesterday: num(hits && hits.uniq_yesterday),
      sinceY: num(hits && hits.since_y),
      uniqSinceY: num(hits && hits.uniq_since_y),
      d7: num(hits && hits.d7),
      uniqD7: num(hits && hits.uniq_d7),
      d30: num(hits && hits.d30),
      uniqD30: num(hits && hits.uniq_d30),
    },
    countries,
    daily,
    users: {
      total: userTotal,
      today: num(users && users.today),
      yesterday: num(users && users.yesterday),
      sinceY: num(users && users.since_y),
      d7: num(users && users.d7),
      d30: num(users && users.d30),
      lastAt: users && users.last_at ? Number(users.last_at) : 0,
    },
    recent: rowsOf(recentRes).map((row) => ({
      email: String(row.email || ""),
      createdAt: Number(row.created_at) || 0,
    })),
    regCountries: regCountries.map((row) => ({
      country: row.country || "unknown",
      n: num(row.n),
      share: userTotal ? num(row.n) / userTotal : 0,
    })),
    lots: lots
      ? {
          active: num(lots.active_users),
          count: num(lots.lot_count),
          rows: num(lots.lot_rows),
        }
      : null,
  };
}
