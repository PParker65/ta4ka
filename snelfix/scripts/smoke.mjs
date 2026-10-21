import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { handleRequest } from "../src/app.js";
import { translationGaps } from "../src/i18n.js";
import { openSqlite } from "../server/sqlite.js";

const gaps = translationGaps();
if (gaps.length) {
  console.error(gaps.slice(0, 20).join("\n"));
  throw new Error(`missing translations: ${gaps.length}`);
}

const dir = mkdtempSync(join(tmpdir(), "snelfix-"));
const db = openSqlite(join(dir, "test.sqlite"));
db.exec(readFileSync(new URL("../migrations/0001_init.sql", import.meta.url), "utf8"));
const env = {};
const assets = { async fetch() { return new Response("ok", { status: 200, headers: { "content-type": "text/plain" } }); } };

async function call(path, init = {}) {
  const response = await handleRequest(new Request(`http://127.0.0.1:8787${path}`, init), { db, env, assets });
  const text = await response.text();
  return { status: response.status, text, headers: response.headers };
}

function assert(cond, message) {
  if (!cond) throw new Error(message);
}

const home = await call("/");
assert(home.status === 200, "home status");
assert(home.text.includes('lang="ru"'), "russian default");
assert(home.text.includes("Главная"), "russian tab");
assert(!home.text.includes("Afspraak maken"), "not dutch first");
assert(home.text.includes("Kromme Esse"), "waddinxveen");
assert(home.text.includes("Groenekanseweg"), "de bilt");
assert(home.text.includes('id="splash"'), "splash");
assert(home.text.includes("splash-bg"), "splash background");
assert(home.text.includes("snelfix_splash"), "splash session key");
assert(!home.text.includes('id="cookie"'), "no cookie bar");
assert(!home.text.includes("Begrepen"), "no cookie consent");
assert(home.text.includes("Шиномонтаж + балансировка"), "ru tyre title");
assert(home.text.includes("€ 30"), "tyre price");
assert(home.text.includes("€ 100"), "brakes price");
assert(home.text.includes("€ 50"), "oil price");
assert(home.text.includes("€ 80"), "major service price");
assert(home.text.includes("от € 500"), "chain from price");
assert(home.text.includes("от € 300"), "belt from price");
assert(home.text.includes("от € 400"), "gearbox from price");
assert(home.text.includes("€ 35 / час"), "welding hourly");
assert(home.text.includes("по запросу"), "coding on request");
assert(home.text.includes("зависит от авто"), "depends note");
assert(home.text.includes('class="carriage"'), "lift carriage");
assert(home.text.includes('class="tile"'), "service cards");
assert(!home.text.includes('class="price-row"'), "no spreadsheet rows");
assert(home.text.includes('class="rocker"'), "booking rocker");
assert(home.text.includes("work-square"), "booking square");
assert(home.text.includes('id="work-curtain"'), "booking curtain");
assert(home.text.includes("overflow:hidden"), "no page scroll lock");

const nl = await call("/nl/");
assert(nl.text.includes('lang="nl"'), "dutch lang");
assert(nl.text.includes("Afspraak"), "dutch tab");
const en = await call("/en/");
assert(en.text.includes('lang="en"'), "english lang");
assert(en.text.includes(">Book<") || en.text.includes(">BOOK<") || en.text.includes("Book"), "english");

assert((await call("/vestigingen/waddinxveen")).status === 200, "location w");
assert((await call("/vestigingen/de-bilt")).status === 200, "location b");
assert((await call("/evacuatie")).text.includes("Эвакуатор"), "tow page");
assert((await call("/contact")).text.includes("Kromme Esse"), "contacts");
assert((await call("/diensten/tyre-fit")).status === 200, "service");
assert((await call("/diensten/tyre-fit")).text.includes("€ 30"), "service price");
assert((await call("/faq")).status === 200, "faq");
assert((await call("/privacy")).text.includes("13044422"), "privacy");
assert((await call("/nl/privacy")).text.includes("verwerkingsverantwoordelijke"), "privacy nl");
assert((await call("/voorwaarden")).status === 200, "terms");
const cookies = await call("/cookies");
assert(cookies.status === 301 && cookies.headers.get("location") === "/", "cookies redirect");
const uk = await call("/uk/");
assert(uk.text.includes("Головна"), "ukrainian");
assert(uk.text.includes('lang="uk"'), "uk lang attr");
assert(uk.text.includes('hreflang="ru"'), "hreflang");
assert(uk.text.includes("ШИНОМОНТАЖ + БАЛАНСУВАННЯ"), "ua tyre title");
assert(uk.text.includes("від € 500"), "ua from price");
assert(uk.text.includes("€ 35 / год"), "ua hourly");
assert(uk.text.includes("за запитом"), "ua on request");
assert(uk.text.includes("залежить від авто"), "ua depends");
assert(uk.text.includes("ВЕЛИКЕ ТО: ОЛИВА + МАСЛЯНИЙ, ПОВІТРЯНИЙ, САЛОННИЙ І ПАЛИВНИЙ ФІЛЬТР"), "ua major title");
assert((await call("/nope")).status === 404, "404");
assert((await call("/sitemap.xml")).text.includes("/vestigingen/de-bilt"), "sitemap");
assert((await call("/robots.txt")).text.includes("Sitemap:"), "robots");

const today = new Date();
let date = "";
for (let i = 1; i < 14; i++) {
  const d = new Date(today.getTime() + i * 86400000);
  const iso = d.toISOString().slice(0, 10);
  const weekday = new Date(`${iso}T00:00:00Z`).getUTCDay();
  if (weekday >= 1 && weekday <= 5) { date = iso; break; }
}
const slots = await call(`/api/availability?garage=waddinxveen&service=oil-filter&date=${date}`);
const slotJson = JSON.parse(slots.text);
assert(slots.status === 200 && slotJson.slots.length > 0, "slots");
const start = slotJson.slots[0].start;

function booking(startMin) {
  const data = new FormData();
  data.set("service", "oil-filter");
  data.set("garage", "waddinxveen");
  data.set("make", "Volkswagen");
  data.set("model", "Golf");
  data.set("year", "2018");
  data.set("plate", "SF-001-K");
  data.set("date", date);
  data.set("start", String(startMin));
  data.set("problem", "Olie verversen voor de winter");
  data.set("name", "Test Klant");
  data.set("cc", "31");
  data.set("national", "612345678");
  data.set("email", "klant@example.com");
  data.set("lang", "nl");
  return data;
}

const first = await call("/api/bookings", { method: "POST", body: booking(start) });
assert(first.status === 200, `book ${first.status} ${first.text}`);
const confirmation = JSON.parse(first.text).confirmation;
assert(confirmation.code.startsWith("SF-"), "code");

const second = await call("/api/bookings", { method: "POST", body: booking(start) });
assert(second.status === 409, `double book should fail, got ${second.status} ${second.text}`);

const tow = new FormData();
tow.set("pickup", "Damrak 1, Amsterdam");
tow.set("delivery", "Kromme Esse 4e, Waddinxveen");
tow.set("make", "Mercedes");
tow.set("model", "A-Klasse");
tow.set("running", "0");
tow.set("urgent", "1");
tow.set("name", "Test Sleep");
tow.set("cc", "31");
tow.set("national", "612345679");
tow.set("lang", "nl");
const towRes = await call("/api/tow", { method: "POST", body: tow });
assert(towRes.status === 200, `tow ${towRes.status} ${towRes.text}`);
assert(JSON.parse(towRes.text).confirmation.route.includes("google.com/maps"), "route");

const bad = await call("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "wrong-pass" }),
});
assert(bad.status === 401, "bad login");

const good = await call("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "admin" }),
});
assert(good.status === 200, "admin login");
const cookie = good.headers.get("set-cookie") || "";
assert(cookie.includes("snelfix_sess="), "cookie");
const token = cookie.split(";")[0];

const bookings = await call("/api/admin/bookings", { headers: { cookie: token } });
assert(bookings.status === 200, "admin bookings");
const id = JSON.parse(bookings.text).bookings[0].id;
const confirmed = await call(`/api/admin/bookings/${id}/confirm`, { method: "POST", headers: { cookie: token } });
assert(confirmed.status === 200, "confirm");
const cancelled = await call(`/api/admin/bookings/${id}/cancel`, { method: "POST", headers: { cookie: token } });
assert(cancelled.status === 200, "cancel");

const changed = await call("/api/admin/password", {
  method: "POST",
  headers: { "content-type": "application/json", cookie: token },
  body: JSON.stringify({ current: "admin", next: "workshop-pass", confirm: "workshop-pass" }),
});
assert(changed.status === 200, `password change ${changed.status} ${changed.text}`);
const old = await call("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "admin" }),
});
assert(old.status === 401, "old password must fail");
const fresh = await call("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "workshop-pass" }),
});
assert(fresh.status === 200, "new password works");

const sunday = await call(`/api/availability?garage=de-bilt&service=oil-filter&date=${nextWeekday(0)}`);
assert(JSON.parse(sunday.text).closed === true || (JSON.parse(sunday.text).slots || []).length === 0, "sunday closed");

console.log("smoke ok");

function nextWeekday(target) {
  for (let i = 1; i < 14; i++) {
    const d = new Date(Date.now() + i * 86400000);
    const iso = d.toISOString().slice(0, 10);
    if (new Date(`${iso}T00:00:00Z`).getUTCDay() === target) return iso;
  }
  return "2026-11-01";
}
