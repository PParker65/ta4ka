const HASH_NS = "kolesasave.v1";
const ALLOWED = new Set([
  "https://kolesasave.com",
  "https://www.kolesasave.com",
  "https://kolesasave.pages.dev",
]);

export function corsHeaders(request) {
  const origin = String(request?.headers?.get("origin") || "");
  let allow = "https://kolesasave.com";
  if (ALLOWED.has(origin) || /\.kolesasave\.pages\.dev$/i.test(origin)) {
    allow = origin;
  }
  return {
    "access-control-allow-origin": allow,
    "access-control-allow-methods": "GET, POST, PUT, OPTIONS",
    "access-control-allow-headers": "Content-Type, Authorization",
    "access-control-max-age": "86400",
    vary: "Origin",
  };
}

export function json(data, status, request) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...corsHeaders(request),
    },
  });
}

export async function readJson(request) {
  const text = await request.text();
  if (!text || !String(text).trim()) return {};
  try {
    return JSON.parse(text);
  } catch {
    const err = new Error("bad_json");
    err.code = "bad_json";
    throw err;
  }
}

export function normalizeEmail(raw) {
  return String(raw || "")
    .trim()
    .toLowerCase();
}

export function isEmail(raw) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizeEmail(raw));
}

export function newSalt() {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

export function newToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
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

export function hashPassword(password, salt) {
  return sha256Hex(`${salt}\u001f${HASH_NS}\u001f${password}`);
}

export async function verifyPassword(password, salt, expected) {
  if (!salt || !expected) return false;
  const got = await hashPassword(password, salt);
  return got === expected;
}

export async function createSession(db, email) {
  const token = newToken();
  await db
    .prepare(
      "INSERT INTO sessions (token, user_email, created_at) VALUES (?, ?, ?)",
    )
    .bind(token, email, Date.now())
    .run();
  return token;
}

export function bearerToken(request) {
  const raw = String(request.headers.get("authorization") || "");
  const m = raw.match(/^Bearer\s+(\S+)/i);
  return m ? m[1].trim() : "";
}

export async function userFromToken(db, token) {
  if (!token) return null;
  const row = await db
    .prepare(
      `SELECT u.email, u.shop_name, u.password_hash, u.salt
       FROM sessions s
       JOIN users u ON u.email = s.user_email
       WHERE s.token = ?`,
    )
    .bind(token)
    .first();
  return row || null;
}

export async function requireUser(context) {
  const db = context.env && context.env.DB;
  if (!db) return { error: json({ error: "d1" }, 503, context.request) };
  const token = bearerToken(context.request);
  const user = await userFromToken(db, token);
  if (!user) {
    return { error: json({ error: "unauthorized" }, 401, context.request) };
  }
  return { db, user, token };
}
