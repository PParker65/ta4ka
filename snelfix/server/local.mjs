import { createServer } from "node:http";
import { readFileSync, existsSync, mkdirSync, statSync } from "node:fs";
import { extname, join, normalize } from "node:path";
import { Readable } from "node:stream";
import { handleRequest } from "../src/app.js";
import { openSqlite } from "./sqlite.js";

const root = new URL("..", import.meta.url).pathname;
const dist = join(root, "dist");
const dataDir = join(root, "data");
mkdirSync(dataDir, { recursive: true });
loadDevVars(join(root, ".dev.vars"));

const dbFile = process.env.DB_PATH || join(dataDir, "snelfix.sqlite");
const db = openSqlite(dbFile);
for (const file of ["migrations/0001_init.sql", "migrations/0002_leads_stats.sql"]) {
  db.exec(readFileSync(join(root, file), "utf8"));
}

const mime = {
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".woff2": "font/woff2",
  ".ico": "image/x-icon",
};

const assets = {
  async fetch(request) {
    const url = new URL(request.url);
    const decoded = decodeURIComponent(url.pathname);
    const file = normalize(join(dist, decoded));
    if (!file.startsWith(dist)) return new Response("no", { status: 403 });
    if (!existsSync(file) || !statSync(file).isFile()) return new Response("Not found", { status: 404 });
    const data = readFileSync(file);
    return new Response(data, {
      headers: { "content-type": mime[extname(file)] || "application/octet-stream", "cache-control": "public, max-age=3600" },
    });
  },
};

const env = {
  SITE_ORIGIN: process.env.SITE_ORIGIN || "",
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD || "",
  TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN || "",
  TELEGRAM_CHAT_ID: process.env.TELEGRAM_CHAT_ID || "",
  EMAIL_WEBHOOK_URL: process.env.EMAIL_WEBHOOK_URL || "",
  SMS_WEBHOOK_URL: process.env.SMS_WEBHOOK_URL || "",
  EMAIL_TO: process.env.EMAIL_TO || "",
  CRON_SECRET: process.env.CRON_SECRET || "",
  ANALYTICS_ID: process.env.ANALYTICS_ID || "",
  GSC_VERIFICATION: process.env.GSC_VERIFICATION || "",
};

const port = Number(process.env.PORT || 8787);
const server = createServer(async (req, res) => {
  try {
    const host = req.headers.host || `127.0.0.1:${port}`;
    const request = new Request(`http://${host}${req.url}`, {
      method: req.method,
      headers: req.headers,
      body: req.method === "GET" || req.method === "HEAD" ? undefined : Readable.toWeb(req),
      duplex: "half",
    });
    const response = await handleRequest(request, { db, env, assets });
    res.statusCode = response.status;
    response.headers.forEach((value, key) => res.setHeader(key, value));
    const buf = Buffer.from(await response.arrayBuffer());
    res.end(buf);
  } catch (error) {
    console.error(error && error.message ? error.message : "server error");
    res.statusCode = 500;
    res.end("Error");
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`SnelFix Auto http://127.0.0.1:${port}`);
});

function loadDevVars(file) {
  if (!existsSync(file)) return;
  for (const line of readFileSync(file, "utf8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const idx = trimmed.indexOf("=");
    if (idx < 1) continue;
    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim();
    if (!process.env[key]) process.env[key] = value;
  }
}
