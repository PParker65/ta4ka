import { newToken, verifyPassword } from "./lib/auth.js";
import { renderDashboard, renderLogin, renderProblem } from "./lib/admin_page.js";
import { d1, ensureSchema } from "./lib/db.js";
import { loadAdminStats } from "./lib/stats.js";

const COOKIE = "ks_admin";
const MAX_AGE = 60 * 60 * 24 * 14;
const ADMIN_USER = "admin";
const ADMIN_SALT = "oYaIfFRO1hYK6reO72SYtA==";
const ADMIN_HASH =
  "288be11f281c5a9befa78c9f661cb914e778db5953f885a2baecb76eb4ebbcd9";

function html(body, status, extra) {
  const headers = {
    "content-type": "text/html; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "referrer-policy": "no-referrer",
    "x-robots-tag": "noindex, nofollow",
    ...extra,
  };
  return new Response(body, { status: status || 200, headers });
}

function sessionCookie(token, clear) {
  const parts = [
    `${COOKIE}=${clear ? "" : token}`,
    "HttpOnly",
    "Secure",
    "SameSite=Lax",
    "Path=/",
    `Max-Age=${clear ? 0 : MAX_AGE}`,
  ];
  return parts.join("; ");
}

function readCookie(request, name) {
  const raw = String(request.headers.get("cookie") || "");
  for (const part of raw.split(";")) {
    const i = part.indexOf("=");
    if (i < 0) continue;
    const key = part.slice(0, i).trim();
    if (key !== name) continue;
    try {
      return decodeURIComponent(part.slice(i + 1).trim());
    } catch {
      return part.slice(i + 1).trim();
    }
  }
  return "";
}

async function sessionToken(db, request) {
  const token = readCookie(request, COOKIE);
  if (!/^[a-f0-9]{64}$/.test(token)) return "";
  const row = await db
    .prepare("SELECT token, expires_at FROM admin_sessions WHERE token = ?")
    .bind(token)
    .first();
  if (!row) return "";
  if (Number(row.expires_at) < Date.now()) {
    await db.prepare("DELETE FROM admin_sessions WHERE token = ?").bind(token).run();
    return "";
  }
  return token;
}

async function doLogout(db, request) {
  const token = readCookie(request, COOKIE);
  if (/^[a-f0-9]{64}$/.test(token)) {
    await db.prepare("DELETE FROM admin_sessions WHERE token = ?").bind(token).run();
  }
  return new Response(null, {
    status: 303,
    headers: {
      Location: "/admin",
      "Set-Cookie": sessionCookie("", true),
      "Cache-Control": "no-store",
    },
  });
}

async function doLogin(db, request, form) {
  const username = String(form.get("username") || "").trim();
  const password = String(form.get("password") || "");
  const passOk =
    password.length > 0 && password.length <= 200
      ? await verifyPassword(password, ADMIN_SALT, ADMIN_HASH)
      : false;
  if (username !== ADMIN_USER || !passOk) {
    return html(renderLogin(true), 401);
  }
  const token = newToken();
  const now = Date.now();
  await db
    .prepare("DELETE FROM admin_sessions WHERE expires_at < ?")
    .bind(now)
    .run();
  await db
    .prepare(
      "INSERT INTO admin_sessions (token, created_at, expires_at) VALUES (?, ?, ?)",
    )
    .bind(token, now, now + MAX_AGE * 1000)
    .run();
  return new Response(null, {
    status: 303,
    headers: {
      Location: "/admin",
      "Set-Cookie": sessionCookie(token, false),
      "Cache-Control": "no-store",
    },
  });
}

export async function onRequest(context) {
  let db;
  try {
    await ensureSchema(context.env);
    db = d1(context.env);
  } catch {
    db = null;
  }
  if (!db) return html(renderProblem("Statistics database is unavailable."), 503);

  const method = context.request.method;
  if (method === "POST") {
    const len = Number(context.request.headers.get("content-length") || 0);
    if (len > 4000) return html(renderLogin(true), 401);
    const form = new URLSearchParams(await context.request.text());
    if (form.get("action") === "logout") return doLogout(db, context.request);
    return doLogin(db, context.request, form);
  }
  if (method !== "GET" && method !== "HEAD") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { "cache-control": "no-store" },
    });
  }

  const token = await sessionToken(db, context.request);
  if (!token) return html(renderLogin(false), 200);
  try {
    const stats = await loadAdminStats(db);
    return html(renderDashboard(stats), 200);
  } catch {
    return html(renderProblem("Could not load statistics."), 500);
  }
}
