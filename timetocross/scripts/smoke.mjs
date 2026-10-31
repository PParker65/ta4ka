import { readFile } from "node:fs/promises";
import { resolve, sep } from "node:path";
import worker from "../src/worker.js";

const root = resolve(import.meta.dirname, "../public");
const password = "ttc-wroclaw-dev";

class MemoryKV {
  constructor() {
    this.map = new Map();
  }
  async get(key) {
    return this.map.has(key) ? this.map.get(key) : null;
  }
  async put(key, value) {
    this.map.set(key, String(value));
  }
  async delete(key) {
    this.map.delete(key);
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
    const full = resolve(root, `.${pathname}`);
    if (full !== root && !full.startsWith(root + sep)) return new Response("no", { status: 404 });
    try {
      const body = await readFile(full);
      return new Response(body);
    } catch {
      return new Response("no", { status: 404 });
    }
  }
}

function env() {
  return {
    LEADS: new MemoryKV(),
    ASSETS: new DiskAssets(),
    ADMIN_USER: "admin",
    ADMIN_PASSWORD: password,
  };
}

async function call(box, path, { method = "GET", body, headers = {}, cookie = "" } = {}) {
  const head = new Headers(headers);
  if (cookie) head.set("cookie", cookie);
  if (body && !head.has("content-type")) head.set("content-type", "application/json");
  if (method !== "GET" && method !== "HEAD" && !head.has("origin")) head.set("origin", "http://127.0.0.1");
  const request = new Request(`http://127.0.0.1${path}`, {
    method,
    headers: head,
    body: body == null ? undefined : typeof body === "string" ? body : JSON.stringify(body),
  });
  const response = await worker.fetch(request, box);
  const type = response.headers.get("content-type") || "";
  const payload = type.includes("json") ? await response.json() : await response.text();
  return { response, payload };
}

function cookieFrom(response) {
  return (response.headers.get("set-cookie") || "").split(";")[0];
}

const today = new Intl.DateTimeFormat("en-CA", {
  timeZone: "Europe/Warsaw",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
}).format(new Date());

function lead(extra = {}) {
  return {
    name: "Олег",
    dial: "+48",
    phone: "793709974",
    machine: "moto250",
    date: today,
    hour: 11,
    note: "двоє",
    lang: "uk",
    ...extra,
  };
}

let failed = 0;
function check(name, cond) {
  if (!cond) {
    failed += 1;
    console.error("FAIL", name);
  } else {
    console.log("ok", name);
  }
}

const box = env();

const home = await call(box, "/");
check("home injects phone", typeof home.payload === "string" && home.payload.includes("+48793709974") && home.payload.includes("150"));
check("home has no raw tokens", !home.payload.includes("__PHONE__") && !home.payload.includes("__RANGE__"));

const pub = await call(box, "/panel/public");
check("public defaults", pub.payload.phone === "+48793709974" && pub.payload.prices.quad500 === 250 && pub.payload.telegram === "");

const badOrigin = await call(box, "/panel/leads", {
  method: "POST",
  body: lead(),
  headers: { origin: "https://evil.example" },
});
check("cross origin blocked", badOrigin.response.status === 403);

const badPhone = await call(box, "/panel/leads", { method: "POST", body: lead({ phone: "12" }) });
check("bad phone", badPhone.response.status === 400 && badPhone.payload.error === "phone");

const honeypot = await call(box, "/panel/leads", { method: "POST", body: lead({ hp_field: "1" }) });
check("honeypot pretends ok", honeypot.payload.ok === true && !honeypot.payload.id);

const created = await call(box, "/panel/leads", { method: "POST", body: lead() });
check("lead stored", created.response.status === 200 && created.payload.ok && created.payload.id);

const guestList = await call(box, "/panel/leads");
check("leads need auth", guestList.response.status === 401);

const badLogin = await call(box, "/panel/login", { method: "POST", body: { user: "admin", password: "wrong-password" } });
check("bad login", badLogin.response.status === 401);

const login = await call(box, "/panel/login", { method: "POST", body: { user: "admin", password } });
const session = cookieFrom(login.response);
check("login cookie", login.payload.ok && session.startsWith("card_sess="));

const list = await call(box, "/panel/leads", { cookie: session });
check("inbox has the lead", list.payload.leads?.length === 1 && list.payload.leads[0].phone === "+48793709974");

const patched = await call(box, `/panel/leads/${created.payload.id}`, {
  method: "PATCH",
  cookie: session,
  body: { status: "done" },
});
check("mark done", patched.payload.lead?.status === "done");

const removed = await call(box, `/panel/leads/${created.payload.id}`, { method: "DELETE", cookie: session });
check("delete lead", removed.payload.ok === true);
const after = await call(box, "/panel/leads", { cookie: session });
check("inbox empty", after.payload.leads?.length === 0);

const hit1 = await call(box, "/panel/hit", { method: "POST", body: {} });
const vid = cookieFrom(hit1.response);
const hit2 = await call(box, "/panel/hit", { method: "POST", body: {}, cookie: vid });
check("second hit keeps cookie", hit2.response.status === 200);
const stats = await call(box, "/panel/stats", { cookie: session });
check("unique and total", stats.payload.totals.total === 2 && stats.payload.totals.unique === 1);

await call(box, "/panel/click", { method: "POST", body: { kind: "call" } });
const stats2 = await call(box, "/panel/stats", { cookie: session });
check("call click", stats2.payload.totals.call === 1);

const saved = await call(box, "/panel/settings", {
  method: "POST",
  cookie: session,
  body: {
    phone: "+48 793 709 974",
    instagram: "@time_to_cross",
    telegram: "https://t.me/timetocross",
    prices: { moto250: 160, moto300: 210, quad250: 210, quad500: 260 },
  },
});
check("settings save", saved.payload.telegram === "https://t.me/timetocross" && saved.payload.prices.moto250 === 160);
const again = await call(box, "/");
check("home uses saved price", again.payload.includes(">160<") && again.payload.includes("https://t.me/timetocross") && !again.payload.includes("data-telegram hidden"));

const www = await worker.fetch(new Request("https://www.timetocrosswroclaw.com/fleet"), box);
check("www redirects home", www.status === 301 && www.headers.get("location") === "https://timetocrosswroclaw.com/fleet");

const htmlLead = await call(box, "/panel/leads", {
  method: "POST",
  headers: { "content-type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams(lead({ name: "Anna", hour: "12", machine: "quad500" })).toString(),
});
check("html form confirms", htmlLead.response.status === 200 && htmlLead.payload.includes("Заявку прийнято"));

if (failed) {
  console.error(`${failed} failed`);
  process.exit(1);
}
console.log("smoke passed");
