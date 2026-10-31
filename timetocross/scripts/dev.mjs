import { readFile, mkdir, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { resolve, sep } from "node:path";
import worker from "../src/worker.js";

const root = resolve(import.meta.dirname, "..");
const publicDir = resolve(root, "public");
const dataFile = resolve(root, ".data/kv.json");

class FileKV {
  constructor(file) {
    this.file = file;
    this.map = new Map();
  }
  async load() {
    try {
      const raw = JSON.parse(await readFile(this.file, "utf8"));
      this.map = new Map(Object.entries(raw));
    } catch {
      this.map = new Map();
    }
  }
  async flush() {
    await mkdir(resolve(this.file, ".."), { recursive: true });
    await writeFile(this.file, JSON.stringify(Object.fromEntries(this.map)));
  }
  async get(key) {
    return this.map.has(key) ? this.map.get(key) : null;
  }
  async put(key, value) {
    this.map.set(key, String(value));
    await this.flush();
  }
  async delete(key) {
    this.map.delete(key);
    await this.flush();
  }
  async list({ prefix = "" } = {}) {
    const keys = [...this.map.keys()].filter((name) => name.startsWith(prefix)).map((name) => ({ name }));
    return { keys, list_complete: true };
  }
}

class DiskAssets {
  async fetch(request) {
    const url = new URL(request.url);
    const pathname = decodeURIComponent(url.pathname);
    const full = resolve(publicDir, `.${pathname}`);
    if (full !== publicDir && !full.startsWith(publicDir + sep)) return new Response("no", { status: 404 });
    try {
      const body = await readFile(full);
      return new Response(body);
    } catch {
      return new Response("no", { status: 404 });
    }
  }
}

function loadDevVars() {
  const out = { ADMIN_USER: "admin", ADMIN_PASSWORD: "ttc-wroclaw-dev" };
  return readFile(resolve(root, ".dev.vars"), "utf8")
    .then((text) => {
      for (const line of text.split("\n")) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("#")) continue;
        const idx = trimmed.indexOf("=");
        if (idx === -1) continue;
        out[trimmed.slice(0, idx).trim()] = trimmed.slice(idx + 1).trim();
      }
      return out;
    })
    .catch(() => out);
}

const vars = await loadDevVars();
const kv = new FileKV(dataFile);
await kv.load();
const binding = {
  LEADS: kv,
  ASSETS: new DiskAssets(),
  ADMIN_USER: vars.ADMIN_USER,
  ADMIN_PASSWORD: vars.ADMIN_PASSWORD,
};

const server = createServer(async (req, res) => {
  try {
    const host = req.headers.host || "127.0.0.1:8787";
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    const body = Buffer.concat(chunks);
    const headers = new Headers();
    for (const [key, value] of Object.entries(req.headers)) {
      if (value == null) continue;
      headers.set(key, Array.isArray(value) ? value.join(", ") : value);
    }
    const request = new Request(`http://${host}${req.url}`, {
      method: req.method,
      headers,
      body: req.method === "GET" || req.method === "HEAD" ? undefined : body,
    });
    const response = await worker.fetch(request, binding);
    const head = {};
    const cookies = [];
    for (const [key, value] of response.headers) {
      if (key === "set-cookie") cookies.push(value);
      else head[key] = value;
    }
    if (cookies.length) head["set-cookie"] = cookies;
    res.writeHead(response.status, head);
    if (req.method === "HEAD") {
      res.end();
      return;
    }
    res.end(Buffer.from(await response.arrayBuffer()));
  } catch (error) {
    res.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
    res.end(error instanceof Error ? error.message : "error");
  }
});

server.listen(8787, "127.0.0.1", () => {
  console.log("Time to Cross http://127.0.0.1:8787");
});
