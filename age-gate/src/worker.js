import { copyFor, languageFor } from "./i18n.js";
import { canonicalTarget, clip, geoFrom, parseUa, publicScheme, validDestUrl } from "./parse.js";

// SHA-256 of the admin password. The plaintext is not stored in this repo.
const PASSWORD_SHA256 = "5c01d38059428bda59e5a9bd56c915f80f39000c32c85f2ea48c9441c866c999";
const ADMIN_USER = "admin";
const SESSION_TTL = 60 * 60 * 24 * 7;
const VID_TTL = 60 * 60 * 24 * 365;
const DEST_KEY = "cfg:dest";
const MAX_EVENTS = 2000;
const EVENT_ID = /^\d{13}_[0-9a-f]{8}$/;
const CSP = "default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests";

const FALLBACK_HTML = `<!DOCTYPE html>
<html lang="__LANG__" dir="__DIR__">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>__AGE_LINE__</title>
</head>
<body class="gate" data-visit="__VISIT__">
  <main class="gate-main">
    <p class="age-line">__AGE_LINE__</p>
    <button class="age-btn" id="age-btn" type="button">__AGE_BTN__</button>
  </main>
  <footer class="credit">Coding Teams</footer>
  <script src="/js/gate.js?v=20261014a"></script>
</body>
</html>`;

export default {
  async fetch(request, env) {
    try {
      return withSecurity(request, await dispatch(request, env));
    } catch {
      return withSecurity(request, json({ ok: false, error: "Server error" }, 500));
    }
  },
};

async function dispatch(request, env) {
  // Real edge requests carry CF-Ray. Local wrangler serves the custom-domain
  // hostname without it, so dev traffic must not be redirected off localhost.
  if (request.headers.get("cf-ray")) {
    const dest = canonicalTarget(request.url, request.headers.get("x-forwarded-proto"), request.headers.get("cf-visitor"));
    if (dest) {
      return new Response(null, {
        status: 301,
        headers: { location: dest, "cache-control": "no-store" },
      });
    }
  }
  const url = new URL(request.url);
  const path = url.pathname;
  if (path.startsWith("/panel/")) return handlePanel(request, env, path);
  if (path === "/admin" || path === "/admin/") return serveAdmin(request, env);
  if (path === "/" || path === "/index.html") return serveGate(request, env);
  if (request.method !== "GET" && request.method !== "HEAD") return json({ ok: false, error: "Not found" }, 404);
  return serveStatic(request, env);
}

async function handlePanel(request, env, path) {
  if (path === "/panel/login" && request.method === "POST") return login(request, env);
  if (path === "/panel/logout" && request.method === "POST") return logout(request, env);
  if (path === "/panel/session" && request.method === "GET") return sessionInfo(request, env);
  if (path === "/panel/settings" && request.method === "GET") return getSettings(request, env);
  if (path === "/panel/settings" && request.method === "POST") return setSettings(request, env);
  if (path === "/panel/hit" && request.method === "POST") return hit(request, env);
  if (path === "/panel/click" && request.method === "POST") return click(request, env);
  if (path === "/panel/time" && request.method === "POST") return timeOnSite(request, env);
  if (path === "/panel/stats" && request.method === "GET") return stats(request, env);
  if (path === "/panel/events/clear" && request.method === "POST") return clearEvents(request, env);
  if (path.startsWith("/panel/events/") && request.method === "DELETE") {
    return deleteEvent(request, env, decodeURIComponent(path.slice("/panel/events/".length)));
  }
  return json({ ok: false, error: "Not found" }, 404);
}

async function serveGate(request, env) {
  if (request.method !== "GET" && request.method !== "HEAD") return json({ ok: false, error: "Method not allowed" }, 405);
  const geo = geoFrom(request);
  const lang = languageFor(geo.country, request.headers.get("Accept-Language"));
  const pack = copyFor(lang);
  const identity = await visitorIdentity(request);
  let visitId = "";
  if (request.method === "GET") {
    const ua = clip(request.headers.get("User-Agent") || "", 400);
    const parsed = parseUa(ua);
    const ts = Date.now();
    try {
      visitId = await putEvent(env, {
        type: "visit",
        ts,
        day: utcDay(ts),
        visitor: identity.visitor,
        country: geo.country,
        city: geo.city,
        region: geo.region,
        device: parsed.device,
        os: parsed.os,
        browser: parsed.browser,
        ua,
        lang,
        locale: "",
        accept: clip(request.headers.get("Accept-Language") || "", 180),
        viewport: "",
        referrer: clip(request.headers.get("Referer") || "", 500),
        path: "/",
        duration: 0,
      });
    } catch {
      visitId = "";
    }
  }
  let html = (await loadAsset(env, request, "/index.html")) || FALLBACK_HTML;
  html = html
    .replaceAll("__LANG__", escapeHtml(lang))
    .replaceAll("__DIR__", lang === "ar" ? "rtl" : "ltr")
    .replaceAll("__AGE_LINE__", escapeHtml(pack.line))
    .replaceAll("__AGE_BTN__", escapeHtml(pack.button))
    .replaceAll("__VISIT__", escapeHtml(visitId));
  const headers = htmlHeaders();
  if (identity.cookie) headers.append("Set-Cookie", identity.cookie);
  return new Response(request.method === "HEAD" ? null : html, { status: 200, headers });
}

async function serveAdmin(request, env) {
  if (request.method !== "GET" && request.method !== "HEAD") return json({ ok: false, error: "Method not allowed" }, 405);
  const html = await loadAsset(env, request, "/admin.html");
  if (!html) return json({ ok: false, error: "Admin page missing" }, 500);
  return new Response(request.method === "HEAD" ? null : html, { status: 200, headers: htmlHeaders() });
}

async function serveStatic(request, env) {
  if (!env.ASSETS) return json({ ok: false, error: "Not found" }, 404);
  const url = new URL(request.url);
  url.search = "";
  return env.ASSETS.fetch(new Request(url, request));
}

async function login(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  const body = await readJson(request);
  const username = body && typeof body.username === "string" ? body.username.slice(0, 80) : "";
  const password = body && typeof body.password === "string" ? body.password.slice(0, 200) : "";
  const hash = await sha256Hex(password);
  const ok = timingSafeEqual(username, ADMIN_USER) && timingSafeEqual(hash, PASSWORD_SHA256);
  if (!ok) {
    await sleep(400);
    return json({ ok: false, error: "Invalid login" }, 401);
  }
  const token = randomHex(32);
  const exp = Date.now() + SESSION_TTL * 1000;
  await env.LEADS.put(`sess:${token}`, JSON.stringify({ u: ADMIN_USER, exp }), { expirationTtl: SESSION_TTL });
  return json({ ok: true }, 200, [sessionCookie(token, request, SESSION_TTL)]);
}

async function logout(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  const token = readCookie(request, "card_sess");
  if (token && env.LEADS) await env.LEADS.delete(`sess:${token}`);
  return json({ ok: true }, 200, [`card_sess=; HttpOnly; Path=/; SameSite=Lax; Max-Age=0${secureAttr(request)}`]);
}

async function sessionInfo(request, env) {
  const user = await sessionUser(request, env);
  if (!user) return json({ ok: false }, 401);
  return json({ ok: true, username: ADMIN_USER });
}

async function getSettings(request, env) {
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  const url = (await env.LEADS.get(DEST_KEY)) || "";
  return json({ ok: true, url });
}

async function setSettings(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  const body = await readJson(request);
  if (!body) return json({ ok: false, error: "Bad request" }, 400);
  if (body.url === "" || body.url === null) {
    await env.LEADS.delete(DEST_KEY);
    return json({ ok: true, url: "" });
  }
  const dest = validDestUrl(typeof body.url === "string" ? body.url : "");
  if (!dest) return json({ ok: false, error: "URL must start with http:// or https://" }, 400);
  await env.LEADS.put(DEST_KEY, dest);
  return json({ ok: true, url: dest });
}

async function hit(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  const body = await readJson(request);
  if (!body) return json({ ok: false, error: "Bad request" }, 400);
  const patch = {
    viewport: clip(body.viewport || "", 32),
    locale: clip(body.locale || "", 40),
    referrer: clip(body.referrer || "", 500),
    path: clip(body.path || "", 200),
  };
  const updated = await patchVisit(env, String(body.visitId || ""), patch);
  if (updated) return json({ ok: true });
  const identity = await visitorIdentity(request);
  const geo = geoFrom(request);
  const ua = clip(request.headers.get("User-Agent") || "", 400);
  const parsed = parseUa(ua);
  const ts = Date.now();
  const id = await putEvent(env, {
    type: "visit",
    ts,
    day: utcDay(ts),
    visitor: identity.visitor,
    country: geo.country,
    city: geo.city,
    region: geo.region,
    device: parsed.device,
    os: parsed.os,
    browser: parsed.browser,
    ua,
    lang: clip(body.lang || languageFor(geo.country, request.headers.get("Accept-Language")), 12),
    locale: patch.locale,
    accept: clip(request.headers.get("Accept-Language") || "", 180),
    viewport: patch.viewport,
    referrer: patch.referrer || clip(request.headers.get("Referer") || "", 500),
    path: patch.path || "/",
    duration: 0,
  });
  return json({ ok: true, visitId: id }, 200, identity.cookie ? [identity.cookie] : []);
}

async function click(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  const body = await readJson(request);
  if (!body) return json({ ok: false, error: "Bad request" }, 400);
  const identity = await visitorIdentity(request);
  const geo = geoFrom(request);
  const ua = clip(request.headers.get("User-Agent") || "", 400);
  const parsed = parseUa(ua);
  const ts = Date.now();
  await putEvent(env, {
    type: "click",
    ts,
    day: utcDay(ts),
    visitor: identity.visitor,
    control: "age18",
    x: finiteCoord(body.x),
    y: finiteCoord(body.y),
    country: geo.country,
    city: geo.city,
    region: geo.region,
    device: parsed.device,
    os: parsed.os,
    browser: parsed.browser,
    ua,
    lang: clip(body.lang || "", 12),
    viewport: clip(body.viewport || "", 32),
    referrer: clip(body.referrer || request.headers.get("Referer") || "", 500),
    path: clip(body.path || "/", 200),
  });
  const dest = (await env.LEADS.get(DEST_KEY)) || "";
  return json({ ok: true, url: dest || null }, 200, identity.cookie ? [identity.cookie] : []);
}

async function timeOnSite(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  const body = await readJson(request);
  if (!body) return json({ ok: false, error: "Bad request" }, 400);
  const duration = Number(body.duration);
  if (!Number.isFinite(duration)) return json({ ok: false, error: "Bad request" }, 400);
  const updated = await patchVisit(env, String(body.visitId || ""), { duration });
  if (!updated) return json({ ok: false, error: "Unknown visit" }, 404);
  return json({ ok: true });
}

async function stats(request, env) {
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  const events = await loadEvents(env);
  const today = utcDay(Date.now());
  const visits = events.filter((event) => event.type === "visit");
  const clicks = events.filter((event) => event.type === "click");
  const todayVisits = visits.filter((event) => event.day === today);
  const timed = visits.filter((event) => Number(event.duration) > 0);
  const avgTimeSec = timed.length
    ? Math.round(timed.reduce((sum, event) => sum + Number(event.duration), 0) / timed.length)
    : 0;
  const recent = events
    .slice()
    .sort((a, b) => b.ts - a.ts)
    .slice(0, 100);
  return json({
    ok: true,
    today,
    totals: {
      visits: visits.length,
      uniques: uniqueCount(visits),
      clicks: clicks.length,
      avgTimeSec,
      timedVisits: timed.length,
      todayVisits: todayVisits.length,
      todayUniques: uniqueCount(todayVisits),
      todayClicks: clicks.filter((event) => event.day === today).length,
    },
    byCountry: breakdown(visits, clicks, "country"),
    byDevice: breakdown(visits, clicks, "device"),
    byBrowser: breakdown(visits, clicks, "browser"),
    byOs: breakdown(visits, clicks, "os"),
    events: recent,
  });
}

async function deleteEvent(request, env, id) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  if (!EVENT_ID.test(id)) return json({ ok: false, error: "Bad id" }, 400);
  await env.LEADS.delete(`evt:${id}`);
  return json({ ok: true });
}

async function clearEvents(request, env) {
  if (!isSameOrigin(request)) return json({ ok: false }, 403);
  if (!(await sessionUser(request, env))) return json({ ok: false }, 401);
  const keys = await listKeys(env, "evt:");
  for (let i = 0; i < keys.length; i += 40) {
    await Promise.all(keys.slice(i, i + 40).map((name) => env.LEADS.delete(name)));
  }
  return json({ ok: true, deleted: keys.length });
}

async function putEvent(env, event) {
  const id = `${String(event.ts).padStart(13, "0")}_${randomHex(4)}`;
  await env.LEADS.put(`evt:${id}`, JSON.stringify(event));
  try {
    await pruneEvents(env);
  } catch {
    // Keeping the new event matters more than trimming history.
  }
  return id;
}

async function pruneEvents(env) {
  const keys = await listKeys(env, "evt:");
  if (keys.length <= MAX_EVENTS) return;
  keys.sort();
  const stale = keys.slice(0, keys.length - MAX_EVENTS);
  for (let i = 0; i < stale.length; i += 40) {
    await Promise.all(stale.slice(i, i + 40).map((name) => env.LEADS.delete(name)));
  }
}

async function patchVisit(env, id, patch) {
  if (!EVENT_ID.test(id)) return null;
  const key = `evt:${id}`;
  const raw = await env.LEADS.get(key);
  if (!raw) return null;
  let event;
  try {
    event = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!event || event.type !== "visit") return null;
  if (patch.viewport) event.viewport = patch.viewport;
  if (patch.locale) event.locale = patch.locale;
  if (patch.referrer) event.referrer = patch.referrer;
  if (patch.path) event.path = patch.path;
  if (Number.isFinite(patch.duration)) {
    const duration = Math.max(0, Math.min(86400, Math.round(patch.duration)));
    event.duration = Math.max(Number(event.duration) || 0, duration);
  }
  await env.LEADS.put(key, JSON.stringify(event));
  return event;
}

async function loadEvents(env) {
  const names = await listKeys(env, "evt:");
  names.sort();
  const newest = names.slice(-MAX_EVENTS);
  const events = [];
  for (let i = 0; i < newest.length; i += 25) {
    const chunk = newest.slice(i, i + 25);
    const rows = await Promise.all(
      chunk.map(async (name) => {
        const raw = await env.LEADS.get(name);
        if (!raw) return null;
        try {
          const event = JSON.parse(raw);
          event.id = name.slice(4);
          return event;
        } catch {
          return null;
        }
      }),
    );
    for (const row of rows) if (row) events.push(row);
  }
  return events;
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
  const token = readCookie(request, "card_sess");
  if (!/^[0-9a-f]{64}$/.test(token)) return null;
  const raw = await env.LEADS.get(`sess:${token}`);
  if (!raw) return null;
  try {
    const data = JSON.parse(raw);
    if (!data || data.u !== ADMIN_USER || !data.exp || data.exp < Date.now()) return null;
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
  const visitor = (await sha256Hex(`age-gate-vid:${vid}`)).slice(0, 20);
  return { visitor, cookie };
}

function sessionCookie(token, request, maxAge) {
  return `card_sess=${token}; HttpOnly; Path=/; SameSite=Lax; Max-Age=${maxAge}${secureAttr(request)}`;
}

function secureAttr(request) {
  const scheme = publicScheme(request.url, request.headers.get("x-forwarded-proto"), request.headers.get("cf-visitor"));
  return scheme === "https" ? "; Secure" : "";
}

function readCookie(request, name) {
  const header = request.headers.get("Cookie") || "";
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
  const origin = request.headers.get("Origin");
  if (origin) {
    try {
      return new URL(origin).origin === new URL(request.url).origin;
    } catch {
      return false;
    }
  }
  const site = request.headers.get("Sec-Fetch-Site");
  if (site && site !== "same-origin" && site !== "none") return false;
  return true;
}

async function readJson(request) {
  const text = await request.text();
  if (text.length > 16000) return null;
  if (!text) return {};
  try {
    const data = JSON.parse(text);
    return data && typeof data === "object" ? data : null;
  } catch {
    return null;
  }
}

async function loadAsset(env, request, pathname) {
  if (!env.ASSETS) return "";
  const assetUrl = new URL(pathname, request.url);
  const res = await env.ASSETS.fetch(new Request(assetUrl, { method: "GET" }));
  if (!res.ok) return "";
  return res.text();
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
  for (const cookie of cookies) headers.append("Set-Cookie", cookie);
  return new Response(JSON.stringify(data), { status, headers });
}

function withSecurity(request, response) {
  const headers = new Headers(response.headers);
  headers.set("x-content-type-options", "nosniff");
  headers.set("referrer-policy", "strict-origin-when-cross-origin");
  headers.set("x-frame-options", "DENY");
  headers.set("content-security-policy", CSP);
  if (publicScheme(request.url, request.headers.get("x-forwarded-proto"), request.headers.get("cf-visitor")) === "https") {
    headers.set("strict-transport-security", "max-age=31536000; includeSubDomains; preload");
  }
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function breakdown(visits, clicks, field) {
  const map = new Map();
  const bump = (event, kind) => {
    const key = event[field] || "Unknown";
    if (!map.has(key)) map.set(key, { key, visits: 0, clicks: 0 });
    map.get(key)[kind] += 1;
  };
  for (const event of visits) bump(event, "visits");
  for (const event of clicks) bump(event, "clicks");
  return [...map.values()].sort((a, b) => b.visits - a.visits || b.clicks - a.clicks || a.key.localeCompare(b.key));
}

function uniqueCount(rows) {
  return new Set(rows.map((event) => event.visitor).filter(Boolean)).size;
}

function finiteCoord(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  return Math.max(-100000, Math.min(100000, Math.round(n)));
}

function utcDay(ts) {
  return new Date(ts).toISOString().slice(0, 10);
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

function timingSafeEqual(a, b) {
  const left = String(a);
  const right = String(b);
  if (left.length !== right.length) return false;
  let out = 0;
  for (let i = 0; i < left.length; i++) out |= left.charCodeAt(i) ^ right.charCodeAt(i);
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
