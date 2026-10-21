export function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[c]));
}

export function json(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...headers,
    },
  });
}

export function html(body, status = 200, headers = {}) {
  return new Response(body, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      ...headers,
    },
  });
}

export function text(body, status = 200, headers = {}) {
  return new Response(body, {
    status,
    headers: { "content-type": "text/plain; charset=utf-8", ...headers },
  });
}

export async function sha256Hex(value) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function randomHex(bytes = 32) {
  const a = new Uint8Array(bytes);
  crypto.getRandomValues(a);
  return [...a].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function safeEqual(a, b) {
  const left = String(a);
  const right = String(b);
  const len = Math.max(left.length, right.length);
  let out = left.length ^ right.length;
  for (let i = 0; i < len; i++) out |= left.charCodeAt(i) ^ right.charCodeAt(i);
  return out === 0;
}

export async function hashPassword(password, salt = randomHex(16)) {
  const hash = await sha256Hex(`${salt}:${password}`);
  return `${salt}:${hash}`;
}

export async function verifyPassword(password, stored) {
  const parts = String(stored || "").split(":");
  if (parts.length !== 2 || !parts[0] || !parts[1]) return false;
  const got = await sha256Hex(`${parts[0]}:${password}`);
  return safeEqual(got, parts[1]);
}

export function cookieValue(request, name) {
  const raw = request.headers.get("cookie") || "";
  for (const part of raw.split(";")) {
    const [k, ...rest] = part.trim().split("=");
    if (k === name) return decodeURIComponent(rest.join("="));
  }
  return "";
}

export function sessionCookie(token, secure, maxAge = 1209600) {
  const bits = [`snelfix_sess=${token}`, "HttpOnly", "Path=/", "SameSite=Lax", `Max-Age=${maxAge}`];
  if (secure) bits.push("Secure");
  return bits.join("; ");
}

export function clientIp(request) {
  return request.headers.get("cf-connecting-ip")
    || (request.headers.get("x-forwarded-for") || "").split(",")[0].trim()
    || "local";
}

const hits = new Map();
export function rateLimit(key, limit = 8, windowMs = 10 * 60 * 1000) {
  const now = Date.now();
  let row = hits.get(key);
  if (!row || now > row.reset) row = { n: 0, reset: now + windowMs };
  row.n += 1;
  hits.set(key, row);
  return row.n <= limit;
}

export function minLabel(mins) {
  const m = Number(mins) || 0;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

export function parseMinutes(value) {
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(value || "").trim());
  if (!m) return null;
  const h = Number(m[1]);
  const min = Number(m[2]);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

export function weekdayFromDate(iso) {
  const [y, m, d] = String(iso).split("-").map(Number);
  if (!y || !m || !d) return null;
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

export function amsterdamNow(date = new Date()) {
  const fmt = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Amsterdam",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
  const parts = Object.fromEntries(fmt.formatToParts(date).map((p) => [p.type, p.value]));
  let hour = Number(parts.hour);
  if (hour === 24) hour = 0;
  return {
    date: `${parts.year}-${parts.month}-${parts.day}`,
    minutes: hour * 60 + Number(parts.minute),
  };
}

export function addDays(iso, days) {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + days));
  return dt.toISOString().slice(0, 10);
}

export function amsterdamToUtcIso(dateStr, hhmm) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const [hh, mm] = hhmm.split(":").map(Number);
  let guess = Date.UTC(y, m - 1, d, hh, mm);
  for (let i = 0; i < 4; i++) {
    const got = amsterdamNow(new Date(guess));
    const [gy, gm, gd] = got.date.split("-").map(Number);
    const gotUtc = Date.UTC(gy, gm - 1, gd, Math.floor(got.minutes / 60), got.minutes % 60);
    const want = Date.UTC(y, m - 1, d, hh, mm);
    const delta = want - gotUtc;
    if (delta === 0) break;
    guess += delta;
  }
  return new Date(guess).toISOString();
}

export function isIsoDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || "")) return false;
  const [y, m, d] = value.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}

export function code(prefix) {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  let out = "";
  for (const b of bytes) out += alphabet[b % alphabet.length];
  return `${prefix}-${out}`;
}

export function money(cents, lang) {
  if (cents == null || cents === "") return null;
  const value = Number(cents) / 100;
  const locale = lang === "en" ? "en-GB" : lang === "uk" ? "uk-UA" : lang === "ru" ? "ru-RU" : "nl-NL";
  return new Intl.NumberFormat(locale, { style: "currency", currency: "EUR", maximumFractionDigits: 0 }).format(value);
}

export function bytesToBase64(bytes) {
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(bin);
}

export function base64ToBytes(b64) {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

export function e164(country, national) {
  const cc = String(country || "").replace(/\D/g, "");
  let n = String(national || "").replace(/\D/g, "");
  if (n.startsWith("0")) n = n.slice(1);
  const full = `+${cc}${n}`;
  return /^\+[1-9]\d{7,14}$/.test(full) ? full : null;
}

export function cleanPlate(value) {
  return String(value || "").toUpperCase().replace(/[^A-Z0-9-]/g, "").slice(0, 12);
}

export function localizePath(lang, path) {
  const clean = path.startsWith("/") ? path : `/${path}`;
  if (!lang || lang === "ru") return clean === "" ? "/" : clean;
  if (clean === "/") return `/${lang}/`;
  return `/${lang}${clean}`;
}

export function parseLangPath(pathname) {
  const match = pathname.match(/^\/(nl|en|uk)(\/.*)?$/);
  if (!match) return { lang: "ru", path: pathname || "/" };
  const rest = match[2] || "/";
  return { lang: match[1], path: rest.startsWith("/") ? rest : `/${rest}` };
}

export function overlaps(a0, a1, b0, b1) {
  return a0 < b1 && a1 > b0;
}

export async function readJson(request) {
  const textBody = await request.text();
  if (!textBody) return {};
  return JSON.parse(textBody);
}
