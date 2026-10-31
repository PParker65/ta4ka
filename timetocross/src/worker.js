import { DEFAULTS, DIALS, HOURS, MACHINE_IDS } from "./catalog.js";

const ASSET_V = "20261031b";
const SESSION_TTL = 60 * 60 * 24 * 14;
const VID_TTL = 60 * 60 * 24 * 400;
const MAX_LEADS = 400;
const LEAD_ID = /^[a-z0-9]{6,16}_[0-9a-f]{8}$/;
const DAY_KEY = /^\d{4}-\d{2}-\d{2}$/;

const CSP = [
  "default-src 'self'",
  "style-src 'self'",
  "script-src 'self'",
  "font-src 'self'",
  "img-src 'self' data:",
  "connect-src 'self'",
  "base-uri 'none'",
  "form-action 'self'",
  "frame-ancestors 'none'",
  "object-src 'none'",
].join("; ");

const TYPES = {
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
  ".txt": "text/plain; charset=utf-8",
  ".html": "text/html; charset=utf-8",
};

const HTML_ERR = {
  name: "Напиши ім’я.",
  phone: "Перевір номер телефону.",
  machine: "Обери техніку на сторінці.",
  date: "Обери день — сьогодні або пізніше.",
  hour: "Обери годину.",
  note: "Коментар занадто довгий.",
  rate: "Забагато заявок. Подзвони нам.",
  origin: "Не вийшло надіслати форму.",
  server: "Не вийшло зберегти заявку. Подзвони нам.",
};

export default {
  async fetch(request, env) {
    try {
      return withSecurity(request, await dispatch(request, env));
    } catch {
      return withSecurity(request, json({ ok: false, error: "server" }, 500));
    }
  },
};

async function dispatch(request, env) {
  const redirected = canonicalRedirect(request);
  if (redirected) return redirected;

  const url = new URL(request.url);
  const path = url.pathname;

  if (path.startsWith("/panel/")) return handlePanel(request, env, path);
  if (path === "/admin" || path === "/admin/") return serveAsset(request, env, "/admin.html");
  if (path === "/" || path === "/index.html") return serveHome(request, env);
  if (request.method !== "GET" && request.method !== "HEAD") return json({ ok: false, error: "Not found" }, 404);

  const asset = staticPath(path);
  if (!asset) return text("Not found", 404);
  return serveAsset(request, env, asset);
}

function canonicalRedirect(request) {
  const url = new URL(request.url);
  const host = (request.headers.get("host") || url.host).split(":")[0].toLowerCase();
  if (host !== "www.timetocrosswroclaw.com") return null;
  url.hostname = "timetocrosswroclaw.com";
  url.protocol = "https:";
  return new Response(null, {
    status: 301,
    headers: { location: url.toString(), "cache-control": "no-store" },
  });
}

async function handlePanel(request, env, path) {
  if (path === "/panel/public" && request.method === "GET") return json({ ok: true, ...await getConfig(env) });
  if (path === "/panel/hit" && request.method === "POST") return hit(request, env);
  if (path === "/panel/click" && request.method === "POST") return click(request, env);
  if (path === "/panel/leads" && request.method === "POST") return createLead(request, env);
  if (path === "/panel/login" && request.method === "POST") return login(request, env);
  if (path === "/panel/logout" && request.method === "POST") return logout(request, env);
  if (path === "/panel/session" && request.method === "GET") return sessionInfo(request, env);
  if (path === "/panel/settings" && request.method === "GET") return getSettings(request, env);
  if (path === "/panel/settings" && request.method === "POST") return saveSettings(request, env);
  if (path === "/panel/stats" && request.method === "GET") return stats(request, env);
  if (path === "/panel/leads" && request.method === "GET") return listLeads(request, env);
  if (path.startsWith("/panel/leads/") && request.method === "DELETE") {
    return deleteLead(request, env, path.slice("/panel/leads/".length));
  }
  if (path.startsWith("/panel/leads/") && request.method === "PATCH") {
    return patchLead(request, env, path.slice("/panel/leads/".length));
  }
  return json({ ok: false, error: "Not found" }, 404);
}

async function serveHome(request, env) {
  if (request.method !== "GET" && request.method !== "HEAD") return json({ ok: false, error: "Method not allowed" }, 405);
  const raw = await readAsset(env, request, "/index.html");
  if (!raw) return text("Not found", 404);
  const html = renderHome(raw, await getConfig(env));
  return htmlResponse(request, html);
}

function renderHome(html, cfg) {
  const map = {
    __PHONE__: cfg.phone,
    __PHONE_PRETTY__: prettyPhone(cfg.phone),
    __INSTAGRAM__: cfg.instagram,
    __IG_LABEL__: igLabel(cfg.instagram),
    __TELEGRAM__: cfg.telegram || "",
    __TG_LABEL__: cfg.telegram ? tgLabel(cfg.telegram) : "Telegram",
    __TG_ATTR__: cfg.telegram ? "" : "hidden",
    __RANGE__: priceRange(cfg.prices),
  };
  for (const id of MACHINE_IDS) map[`__P_${id}__`] = String(cfg.prices[id]);
  let out = html;
  for (const [token, value] of Object.entries(map)) out = out.replaceAll(token, escapeHtml(value));
  return out;
}

async function hit(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  const identity = await visitorIdentity(request);
  if (env.LEADS) await bumpVisit(env, identity.visitor);
  return json({ ok: true }, 200, identity.cookie ? [identity.cookie] : []);
}

async function click(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  const body = await readBody(request);
  const kind = body && body.kind;
  if (kind !== "call" && kind !== "instagram" && kind !== "telegram") return json({ ok: false, error: "kind" }, 400);
  if (env.LEADS) {
    await addStat(env, { [kind]: 1 });
  }
  return json({ ok: true });
}

async function createLead(request, env) {
  if (!isSameOrigin(request)) return failLead(request, "origin", 403);
  if (!env.LEADS) return failLead(request, "server", 503);
  const body = await readBody(request);
  if (!body) return failLead(request, "server", 400);

  const html = wantsHtml(request);
  if (body.hp_field) return html ? resultPage(request, { ok: true }) : json({ ok: true });

  const identity = await visitorIdentity(request);
  if (await rateLimited(env, identity.visitor)) return failLead(request, "rate", 429, identity);

  const lead = normalizeLead(body);
  if (lead.error) return failLead(request, lead.error, 400, identity);

  const id = `${Date.now().toString(36)}_${randomHex(4)}`;
  const stored = { id, ...lead.value, status: "new", created: new Date().toISOString() };
  await env.LEADS.put(`lead:${id}`, JSON.stringify(stored));
  await addStat(env, { leads: 1 });
  await pruneLeads(env);

  if (html) return resultPage(request, { ok: true, phone: (await getConfig(env)).phone }, identity);
  return json({ ok: true, id }, 200, identity.cookie ? [identity.cookie] : []);
}

function failLead(request, error, status, identity) {
  const cookies = identity && identity.cookie ? [identity.cookie] : [];
  if (wantsHtml(request)) return resultPage(request, { ok: false, error }, identity);
  return json({ ok: false, error }, status, cookies);
}

function normalizeLead(body) {
  const name = cleanText(body.name, 60);
  if (!/^[\p{L}][\p{L}\s'’-]{1,59}$/u.test(name)) return { error: "name" };

  const phone = normalizePhone(body.dial, body.phone);
  if (!phone) return { error: "phone" };

  const machine = String(body.machine || "");
  if (!MACHINE_IDS.includes(machine)) return { error: "machine" };

  const date = String(body.date || "");
  if (!DAY_KEY.test(date) || date < warsawToday() || date > warsawShift(120)) return { error: "date" };

  const hour = Number(body.hour);
  if (!HOURS.includes(hour)) return { error: "hour" };

  const note = cleanText(body.note, 400);
  if (String(body.note || "").trim().length > 400) return { error: "note" };

  const lang = body.lang === "pl" || body.lang === "ru" ? body.lang : "uk";
  return { value: { name, phone, machine, date, hour, note, lang } };
}

async function login(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  const body = await readBody(request);
  const user = String(body?.user || "").slice(0, 64);
  const password = String(body?.password || "").slice(0, 200);
  const expectedUser = String(env.ADMIN_USER || "admin").trim();
  const expectedPass = String(env.ADMIN_PASSWORD || "");

  const failKey = env.LEADS ? `fail:${(await sha256Hex(clientKey(request))).slice(0, 20)}` : "";
  if (failKey) {
    const fails = Number(await env.LEADS.get(failKey) || "0");
    if (fails >= 8) return json({ ok: false, error: "rate" }, 429);
  }

  const userOk = await hashesEqual(user, expectedUser);
  const passOk = expectedPass.length >= 10 && (await hashesEqual(password, expectedPass));
  if (!userOk || !passOk || !env.LEADS) {
    if (failKey) {
      const fails = Number(await env.LEADS.get(failKey) || "0");
      await env.LEADS.put(failKey, String(fails + 1), { expirationTtl: 900 });
    }
    await sleep(200);
    return json({ ok: false, error: "auth" }, 401);
  }

  if (failKey) await env.LEADS.delete(failKey);
  const token = randomHex(32);
  const exp = Date.now() + SESSION_TTL * 1000;
  await env.LEADS.put(`sess:${token}`, JSON.stringify({ u: expectedUser, exp }), { expirationTtl: SESSION_TTL });
  return json({ ok: true }, 200, [sessionCookie(token, request, SESSION_TTL)]);
}

async function logout(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  const token = readCookie(request, "card_sess");
  if (env.LEADS && /^[0-9a-f]{64}$/.test(token)) await env.LEADS.delete(`sess:${token}`);
  return json({ ok: true }, 200, [sessionCookie("", request, 0)]);
}

async function sessionInfo(request, env) {
  const user = await sessionUser(request, env);
  if (!user) return json({ ok: false }, 401);
  return json({ ok: true, user: user.u });
}

async function getSettings(request, env) {
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  return json({ ok: true, ...(await getConfig(env)) });
}

async function saveSettings(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  if (!env.LEADS) return json({ ok: false, error: "server" }, 503);
  const body = await readBody(request);
  if (!body) return json({ ok: false, error: "config" }, 400);

  const phone = normalizePhone("+48", body.phone);
  if (!phone) return json({ ok: false, error: "phone" }, 400);
  const instagram = normalizeInstagram(body.instagram);
  if (!instagram) return json({ ok: false, error: "instagram" }, 400);
  const telegram = normalizeTelegram(body.telegram);
  if (telegram == null) return json({ ok: false, error: "telegram" }, 400);

  const prices = {};
  const source = body.prices && typeof body.prices === "object" ? body.prices : {};
  for (const id of MACHINE_IDS) {
    const value = Number(source[id]);
    if (!Number.isInteger(value) || value < 50 || value > 2000) return json({ ok: false, error: "price" }, 400);
    prices[id] = value;
  }

  const cfg = { phone, instagram, telegram, prices };
  await env.LEADS.put("cfg:public", JSON.stringify(cfg));
  return json({ ok: true, ...cfg });
}

async function stats(request, env) {
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  const totals = await readStats(env);
  const days = [];
  for (let i = 13; i >= 0; i--) {
    const day = warsawShift(-i);
    const row = env.LEADS ? await readDay(env, day) : emptyStats();
    days.push({ day, ...row });
  }
  const leads = await loadLeads(env);
  return json({
    ok: true,
    totals,
    days,
    leads: leads.length,
    fresh: leads.filter((lead) => lead.status !== "done").length,
  });
}

async function listLeads(request, env) {
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  const leads = await loadLeads(env);
  leads.sort((a, b) => String(b.created).localeCompare(String(a.created)));
  return json({ ok: true, leads });
}

async function deleteLead(request, env, id) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  if (!LEAD_ID.test(id) || !env.LEADS) return json({ ok: false, error: "Not found" }, 404);
  await env.LEADS.delete(`lead:${id}`);
  return json({ ok: true });
}

async function patchLead(request, env, id) {
  if (!isSameOrigin(request)) return json({ ok: false, error: "origin" }, 403);
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  if (!LEAD_ID.test(id) || !env.LEADS) return json({ ok: false, error: "Not found" }, 404);
  const raw = await env.LEADS.get(`lead:${id}`);
  if (!raw) return json({ ok: false, error: "Not found" }, 404);
  const body = await readBody(request);
  const status = body && body.status;
  if (status !== "new" && status !== "done") return json({ ok: false, error: "status" }, 400);
  const lead = JSON.parse(raw);
  lead.status = status;
  await env.LEADS.put(`lead:${id}`, JSON.stringify(lead));
  return json({ ok: true, lead });
}

async function getConfig(env) {
  if (!env.LEADS) return structuredClone(DEFAULTS);
  const raw = await env.LEADS.get("cfg:public");
  if (!raw) return structuredClone(DEFAULTS);
  try {
    return mergeConfig(JSON.parse(raw));
  } catch {
    return structuredClone(DEFAULTS);
  }
}

function mergeConfig(value) {
  const prices = { ...DEFAULTS.prices };
  if (value && value.prices && typeof value.prices === "object") {
    for (const id of MACHINE_IDS) {
      const price = Number(value.prices[id]);
      if (Number.isInteger(price)) prices[id] = price;
    }
  }
  return {
    phone: typeof value?.phone === "string" && /^\+[1-9]\d{7,14}$/.test(value.phone) ? value.phone : DEFAULTS.phone,
    instagram: typeof value?.instagram === "string" && value.instagram ? value.instagram : DEFAULTS.instagram,
    telegram: typeof value?.telegram === "string" ? value.telegram : "",
    prices,
  };
}

async function bumpVisit(env, visitor) {
  const seenKey = `seen:${visitor}`;
  const seen = await env.LEADS.get(seenKey);
  if (seen) {
    await addStat(env, { total: 1 });
    return;
  }
  await env.LEADS.put(seenKey, "1", { expirationTtl: VID_TTL });
  await addStat(env, { total: 1, unique: 1 });
}

async function addStat(env, delta) {
  const totals = await readStats(env);
  const day = warsawToday();
  const row = await readDay(env, day);
  for (const [key, amount] of Object.entries(delta)) {
    totals[key] = (totals[key] || 0) + amount;
    row[key] = (row[key] || 0) + amount;
  }
  await env.LEADS.put("stats", JSON.stringify(totals));
  await env.LEADS.put(`day:${day}`, JSON.stringify(row));
}

async function readStats(env) {
  if (!env.LEADS) return emptyStats();
  return parseStats(await env.LEADS.get("stats"));
}

async function readDay(env, day) {
  return parseStats(await env.LEADS.get(`day:${day}`));
}

function parseStats(raw) {
  const base = emptyStats();
  if (!raw) return base;
  try {
    const data = JSON.parse(raw);
    for (const key of Object.keys(base)) base[key] = Number(data[key]) || 0;
    return base;
  } catch {
    return base;
  }
}

function emptyStats() {
  return { total: 0, unique: 0, leads: 0, call: 0, instagram: 0, telegram: 0 };
}

async function loadLeads(env) {
  if (!env.LEADS) return [];
  const names = await listKeys(env, "lead:");
  const leads = [];
  for (const name of names) {
    const raw = await env.LEADS.get(name);
    if (!raw) continue;
    try {
      leads.push(JSON.parse(raw));
    } catch {
      /* skip broken rows */
    }
  }
  return leads;
}

async function pruneLeads(env) {
  const names = await listKeys(env, "lead:");
  if (names.length <= MAX_LEADS) return;
  const rows = [];
  for (const name of names) {
    const raw = await env.LEADS.get(name);
    let created = 0;
    try {
      created = Date.parse(JSON.parse(raw).created) || 0;
    } catch {
      created = 0;
    }
    rows.push({ name, created });
  }
  rows.sort((a, b) => a.created - b.created);
  for (const row of rows.slice(0, rows.length - MAX_LEADS)) await env.LEADS.delete(row.name);
}

async function rateLimited(env, visitor) {
  const key = `rate:${visitor}`;
  const current = Number(await env.LEADS.get(key) || "0");
  if (current >= 8) return true;
  await env.LEADS.put(key, String(current + 1), { expirationTtl: 3600 });
  return false;
}

async function listKeys(env, prefix) {
  const names = [];
  let cursor;
  do {
    const page = await env.LEADS.list({ prefix, cursor, limit: 500 });
    for (const key of page.keys) names.push(key.name);
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor);
  return names;
}

async function sessionUser(request, env) {
  if (!env.LEADS) return null;
  const token = readCookie(request, "card_sess");
  if (!/^[0-9a-f]{64}$/.test(token)) return null;
  const raw = await env.LEADS.get(`sess:${token}`);
  if (!raw) return null;
  try {
    const data = JSON.parse(raw);
    const expected = String(env.ADMIN_USER || "admin").trim();
    if (!data || data.u !== expected || !data.exp || data.exp < Date.now()) return null;
    return data;
  } catch {
    return null;
  }
}

async function visitorIdentity(request) {
  let vid = readCookie(request, "vid");
  let cookie = "";
  if (!/^[0-9a-f]{32}$/.test(vid)) {
    vid = randomHex(16);
    cookie = `vid=${vid}; HttpOnly; Path=/; SameSite=Lax; Max-Age=${VID_TTL}${secureAttr(request)}`;
  }
  const visitor = (await sha256Hex(`ttc:${vid}`)).slice(0, 24);
  return { visitor, cookie };
}

function sessionCookie(token, request, maxAge) {
  const value = token ? token : "";
  return `card_sess=${value}; HttpOnly; Path=/; SameSite=Lax; Max-Age=${maxAge}${secureAttr(request)}`;
}

function secureAttr(request) {
  return publicScheme(request) === "https" ? "; Secure" : "";
}

function publicScheme(request) {
  const forwarded = request.headers.get("x-forwarded-proto");
  if (forwarded) return forwarded.split(",")[0].trim();
  return new URL(request.url).protocol === "https:" ? "https" : "http";
}

function readCookie(request, name) {
  const header = request.headers.get("cookie") || "";
  for (const part of header.split(";")) {
    const idx = part.indexOf("=");
    if (idx === -1) continue;
    if (part.slice(0, idx).trim() !== name) continue;
    try {
      return decodeURIComponent(part.slice(idx + 1).trim());
    } catch {
      return "";
    }
  }
  return "";
}

function isSameOrigin(request) {
  const origin = request.headers.get("origin");
  if (origin) {
    try {
      return new URL(origin).origin === new URL(request.url).origin;
    } catch {
      return false;
    }
  }
  const site = request.headers.get("sec-fetch-site");
  if (site && site !== "same-origin" && site !== "none") return false;
  return true;
}

function wantsHtml(request) {
  return (request.headers.get("content-type") || "").includes("application/x-www-form-urlencoded");
}

async function readBody(request) {
  const type = request.headers.get("content-type") || "";
  if (type.includes("application/json")) {
    const text = await request.text();
    if (text.length > 20000) return null;
    try {
      const data = JSON.parse(text);
      if (!data || typeof data !== "object" || Array.isArray(data)) return null;
      return data;
    } catch {
      return null;
    }
  }
  if (type.includes("application/x-www-form-urlencoded") || type.includes("multipart/form-data")) {
    const form = await request.formData();
    const data = {};
    for (const [key, value] of form.entries()) {
      if (typeof value === "string") data[key] = value.slice(0, 2000);
    }
    return data;
  }
  return {};
}

function normalizePhone(dial, raw) {
  const source = String(raw || "").trim();
  let full = "";
  if (source.startsWith("+") || source.startsWith("00")) {
    full = "+" + source.replace(/^00/, "").replace(/\D/g, "");
  } else {
    const prefix = DIALS.includes(dial) ? dial : "+48";
    let local = source.replace(/\D/g, "");
    if (local.startsWith("0")) local = local.slice(1);
    full = prefix + local;
  }
  if (!/^\+[1-9]\d{7,14}$/.test(full)) return "";
  return full;
}

function normalizeInstagram(raw) {
  let value = String(raw || "").trim();
  if (!value) return "";
  if (value.startsWith("@")) value = value.slice(1);
  if (!/^https?:\/\//i.test(value)) value = `https://instagram.com/${value}`;
  let url;
  try {
    url = new URL(value);
  } catch {
    return "";
  }
  const host = url.hostname.replace(/^www\./, "");
  if (host !== "instagram.com") return "";
  const handle = url.pathname.split("/").filter(Boolean)[0] || "";
  if (!/^[A-Za-z0-9._]{1,30}$/.test(handle)) return "";
  return `https://instagram.com/${handle}`;
}

function normalizeTelegram(raw) {
  const text = String(raw || "").trim();
  if (!text) return "";
  let value = text;
  if (value.startsWith("@")) value = `https://t.me/${value.slice(1)}`;
  else if (!/^https?:\/\//i.test(value)) value = `https://t.me/${value.replace(/^t\.me\//i, "")}`;
  let url;
  try {
    url = new URL(value);
  } catch {
    return null;
  }
  const host = url.hostname.replace(/^www\./, "");
  if (host !== "t.me" && host !== "telegram.me") return null;
  const user = url.pathname.match(/^\/([A-Za-z][A-Za-z0-9_]{3,31})\/?$/);
  const invite = url.pathname.match(/^\/\+([A-Za-z0-9_-]{8,80})\/?$/);
  if (user) return `https://t.me/${user[1]}`;
  if (invite) return `https://t.me/+${invite[1]}`;
  return null;
}

function cleanText(value, max) {
  return String(value || "")
    .replace(/[\u0000-\u001f\u007f]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, max);
}

function warsawToday() {
  return warsawShift(0);
}

function warsawShift(days) {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Warsaw",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return fmt.format(new Date(Date.now() + days * 86400000));
}

function prettyPhone(phone) {
  if (phone.startsWith("+48") && phone.length === 12) {
    return `+48 ${phone.slice(3, 6)} ${phone.slice(6, 9)} ${phone.slice(9)}`;
  }
  if (phone.startsWith("+380") && phone.length === 13) {
    return `+380 ${phone.slice(4, 6)} ${phone.slice(6, 9)} ${phone.slice(9, 11)} ${phone.slice(11)}`;
  }
  return phone;
}

function igLabel(url) {
  const handle = String(url || "").split("/").filter(Boolean).pop();
  return handle ? `Instagram · @${handle}` : "Instagram";
}

function tgLabel(url) {
  const path = String(url || "").split("t.me/")[1] || "";
  if (path.startsWith("+")) return "Telegram";
  return path ? `Telegram · @${path.replace(/\/$/, "")}` : "Telegram";
}

function priceRange(prices) {
  const values = MACHINE_IDS.map((id) => prices[id]);
  const min = Math.min(...values);
  const max = Math.max(...values);
  return min === max ? `${min} zł` : `${min}–${max} zł`;
}

function resultPage(request, { ok, error, phone }, identity) {
  const cfgPhone = phone || DEFAULTS.phone;
  const title = ok ? "Заявку прийнято" : "Не вийшло";
  const text = ok
    ? "Передзвонимо і підтвердимо годину."
    : HTML_ERR[error] || HTML_ERR.server;
  const html = `<!DOCTYPE html>
<html lang="uk">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex">
  <title>${title} — Time to Cross</title>
  <link rel="icon" href="/favicon.svg">
  <link rel="stylesheet" href="/css/site.css?v=${ASSET_V}">
</head>
<body>
  <main class="wrap result">
    <p class="eyebrow"><span>TIME TO CROSS</span> · <span>Вроцлав</span></p>
    <h1>${escapeHtml(title)}</h1>
    <p class="lead">${escapeHtml(text)}</p>
    <div class="hero-actions">
      <a class="btn btn-hot" href="tel:${escapeHtml(cfgPhone)}">Зателефонувати</a>
      <a class="btn btn-ghost" href="/#lead-form">На сайт</a>
    </div>
  </main>
</body>
</html>`;
  const headers = htmlHeaders();
  if (identity && identity.cookie) headers.append("set-cookie", identity.cookie);
  return new Response(html, { status: ok ? 200 : 400, headers });
}

function clientKey(request) {
  return request.headers.get("cf-connecting-ip") || request.headers.get("x-forwarded-for") || "local";
}

async function serveAsset(request, env, pathname) {
  const raw = await readAsset(env, request, pathname);
  if (!raw && raw !== "") return text("Not found", 404);
  const found = await fetchAsset(env, request, pathname);
  if (!found) return text("Not found", 404);
  const headers = new Headers();
  const ext = pathname.slice(pathname.lastIndexOf("."));
  headers.set("content-type", TYPES[ext] || found.type || "application/octet-stream");
  headers.set("x-content-type-options", "nosniff");
  if (ext === ".html") {
    headers.set("cache-control", "no-store");
    headers.set("x-robots-tag", "noindex");
  } else if (ext === ".woff2") headers.set("cache-control", "public, max-age=604800");
  else headers.set("cache-control", "public, max-age=86400");
  if (request.method === "HEAD") return new Response(null, { status: 200, headers });
  return new Response(found.body, { status: 200, headers });
}

async function fetchAsset(env, request, pathname) {
  if (!env.ASSETS) return null;
  const url = new URL(request.url);
  url.pathname = pathname;
  const res = await env.ASSETS.fetch(new Request(url.toString(), { method: "GET" }));
  if (!res.ok) return null;
  const body = await res.arrayBuffer();
  return { body, type: res.headers.get("content-type") };
}

async function readAsset(env, request, pathname) {
  const found = await fetchAsset(env, request, pathname);
  if (!found) return "";
  return new TextDecoder().decode(found.body);
}

function htmlResponse(request, html) {
  if (request.method === "HEAD") return new Response(null, { status: 200, headers: htmlHeaders() });
  return new Response(html, { status: 200, headers: htmlHeaders() });
}

function htmlHeaders() {
  return new Headers({
    "content-type": "text/html; charset=utf-8",
    "cache-control": "no-store",
  });
}

function json(data, status = 200, cookies = []) {
  const headers = new Headers({
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  for (const cookie of cookies) headers.append("set-cookie", cookie);
  return new Response(JSON.stringify(data), { status, headers });
}

function text(body, status) {
  return new Response(body, {
    status,
    headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" },
  });
}

function withSecurity(request, response) {
  const headers = new Headers(response.headers);
  headers.set("x-content-type-options", "nosniff");
  headers.set("referrer-policy", "strict-origin-when-cross-origin");
  headers.set("x-frame-options", "DENY");
  headers.set("content-security-policy", CSP);
  const path = new URL(request.url).pathname;
  if (path.startsWith("/admin") || path.startsWith("/panel")) headers.set("x-robots-tag", "noindex");
  if (publicScheme(request) === "https") {
    headers.set("strict-transport-security", "max-age=31536000; includeSubDomains");
  }
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function staticPath(path) {
  if (path.includes("..")) return "";
  if (!/^\/[a-zA-Z0-9./_-]+$/.test(path)) return "";
  if (!/\.(css|js|svg|woff2|txt)$/.test(path)) return "";
  return path;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function sha256Hex(text) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function hashesEqual(a, b) {
  const [left, right] = await Promise.all([sha256Hex(String(a)), sha256Hex(String(b))]);
  return timingSafeEqual(left, right);
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let out = 0;
  for (let i = 0; i < a.length; i++) out |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return out === 0;
}

function randomHex(bytes) {
  const buf = new Uint8Array(bytes);
  crypto.getRandomValues(buf);
  return [...buf].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
