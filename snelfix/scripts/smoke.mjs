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
db.exec(readFileSync(new URL("../migrations/0002_leads_stats.sql", import.meta.url), "utf8"));
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
for (const job of ["tyre-fit", "discs-pads", "chassis-diag", "oil-filter", "major-service", "e-diag", "timing-chain", "timing-belt", "gearbox", "clutch", "alternator", "starter", "welding", "coding"]) {
  assert(home.text.includes(`/photos/jobs/${job}.jpg`), `job photo ${job}`);
}
assert(!home.text.includes('class="price-row"'), "no spreadsheet rows");
assert(!home.text.includes('data-panel="book"'), "no book tab");
assert(!home.text.includes('id="panel-book"'), "no book panel");
assert(!home.text.includes('class="rocker"'), "no booking rocker");
assert(!home.text.includes("work-square"), "no booking square");
assert(!home.text.includes('id="visit"'), "no visit card");
assert(!home.text.includes("/boeken"), "no book links");
assert(!home.text.includes("splash-copy"), "splash has no pitch");
assert(home.text.includes('class="flag"'), "splash flag");
assert(home.text.includes("SNELFIX"), "splash wordmark");
assert(home.text.includes("Сеть автосервисов в Нидерландах"), "home network line");
assert(home.text.includes('class="home-line"'), "home line can take the sheen");
assert(home.text.includes('class="door-name">SnelFix Auto<br>Waddinxveen'), "waddinxveen name above lift");
assert(home.text.includes('class="door-name">SnelFix Auto<br>De Bilt'), "de bilt name above lift");
assert(home.text.includes('class="door-name"'), "door name label");
assert(home.text.includes(">Главная<"), "home tab");
assert(home.text.includes(">Услуги<"), "services tab");
assert(home.text.includes(">Эвакуатор<"), "tow tab");
assert(home.text.includes(">Контакты<"), "contacts tab");
assert(!home.text.includes("<span>Запись</span>"), "no book label");
assert(home.text.includes("overflow:hidden"), "no page scroll lock");

const nl = await call("/nl/");
assert(nl.text.includes('lang="nl"'), "dutch lang");
assert(nl.text.includes("Netwerk van autoservices in Nederland"), "dutch home line");
assert(nl.text.includes(">Diensten<"), "dutch services tab");
assert(!nl.text.includes('data-panel="book"'), "dutch has no book tab");
const en = await call("/en/");
assert(en.text.includes('lang="en"'), "english lang");
assert(en.text.includes("A network of auto services in the Netherlands"), "english home line");
assert(en.text.includes(">Services<"), "english services tab");
assert(!en.text.includes(">Book<"), "english has no book tab");

assert((await call("/vestigingen/waddinxveen")).status === 200, "location w");
assert((await call("/vestigingen/de-bilt")).status === 200, "location b");
const towPage = await call("/evacuatie");
assert(towPage.text.includes("Эвакуатор"), "tow page");
assert(towPage.text.includes('class="haul"'), "tow scene");
assert(towPage.text.includes("haul-truck"), "tow truck");
assert(towPage.text.includes("haul-car"), "towed car");
assert(!towPage.text.includes("haul-bay"), "no garage in the tow scene");
assert(!towPage.text.includes("haul-door"), "no garage door in the tow scene");
assert((towPage.text.match(/class="sq /g) || []).length === 2, "two tow squares");
assert(towPage.text.includes("до 4 тонн"), "tow capacity");
assert(towPage.text.includes('class="tow-rest" hidden'), "tow fields wait for location");
assert(towPage.text.includes("Что случилось?"), "tow problem still in the step");
assert(towPage.text.includes("Мы уже готовы выехать."), "tow ready line");
assert(towPage.text.includes("Перезвоним в течение 15 минут."), "tow callback line");
assert(!towPage.text.includes('name="date"'), "short tow form");
assert((await call("/nl/evacuatie")).text.includes("We staan al klaar om te rijden."), "nl ready");
assert((await call("/en/evacuatie")).text.includes("We are already ready to go."), "en ready");
assert((await call("/uk/evacuatie")).text.includes("Ми вже готові виїхати."), "uk ready");
assert(!towPage.text.includes("tab-mark"), "tabs are squares");
assert(!towPage.text.includes('data-panel="book"'), "tow has no book tab");
assert((await call("/nl/evacuatie")).text.includes("Tot 4 ton"), "nl capacity");
assert((await call("/en/evacuatie")).text.includes("Up to 4 tons"), "en capacity");
assert((await call("/uk/evacuatie")).text.includes("до 4 тонн"), "uk capacity");
const contact = await call("/contact");
assert(contact.text.includes("Kromme Esse"), "contacts");
assert(contact.text.includes("https://www.google.com/maps/dir/"), "google maps route");
assert(!contact.text.includes('class="legal-links"'), "no legal links on contacts");
assert(!contact.text.includes('data-sheet="faq"'), "no faq link on contacts");
assert(contact.text.includes("https://maps.apple.com/"), "apple maps route");
assert(!contact.text.includes("openstreetmap.org"), "no osm route button");
assert(!contact.text.includes(">OSM<"), "no osm label");
assert((contact.text.match(/class="route /g) || []).length === 4, "two route buttons per garage");
assert((await call("/diensten/tyre-fit")).status === 200, "service");
assert((await call("/diensten/tyre-fit")).text.includes("€ 30"), "service price");
const tyre = await call("/diensten/tyre-fit");
assert(tyre.text.includes("wa.me/31613044422"), "service whatsapp");
assert(tyre.text.includes("Оставить заявку"), "service lead action");
assert(tyre.text.includes("Связаться"), "service contact action");
assert(tyre.text.includes("data-lead-form"), "service lead form");
assert(!tyre.text.includes('data-panel="book"'), "service has no book panel");
assert(!(await call("/diensten/tyre-fit")).text.includes("/boeken"), "service has no book link");
assert((await call("/faq")).status === 200, "faq");
assert((await call("/privacy")).text.includes("13044422"), "privacy");
assert((await call("/nl/privacy")).text.includes("verwerkingsverantwoordelijke"), "privacy nl");
assert((await call("/voorwaarden")).status === 200, "terms");
const cookies = await call("/cookies");
assert(cookies.status === 301 && cookies.headers.get("location") === "/", "cookies redirect");
const booked = await call("/boeken");
assert(booked.status === 301 && booked.headers.get("location") === "/contact", "book redirect");
const bookedNl = await call("/nl/boeken");
assert(bookedNl.status === 301 && bookedNl.headers.get("location") === "/nl/contact", "book redirect nl");
const uk = await call("/uk/");
assert(uk.text.includes("Головна"), "ukrainian");
assert(uk.text.includes("Мережа автосервісів у Нідерландах"), "ukrainian home line");
assert(uk.text.includes('lang="uk"'), "uk lang attr");
assert(uk.text.includes('hreflang="ru"'), "hreflang");
assert(uk.text.includes("ШИНОМОНТАЖ + БАЛАНСУВАННЯ"), "ua tyre title");
assert(uk.text.includes("від € 500"), "ua from price");
assert(uk.text.includes("€ 35 / год"), "ua hourly");
assert(uk.text.includes("за запитом"), "ua on request");
assert(uk.text.includes("залежить від авто"), "ua depends");
assert(uk.text.includes("ВЕЛИКЕ ТО: ОЛИВА + МАСЛЯНИЙ, ПОВІТРЯНИЙ, САЛОННИЙ І ПАЛИВНИЙ ФІЛЬТР"), "ua major title");
assert((await call("/nope")).status === 404, "404");
const sitemap = await call("/sitemap.xml");
assert(sitemap.text.includes("/vestigingen/de-bilt"), "sitemap");
assert(!sitemap.text.includes("/boeken"), "sitemap has no booking");
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

async function lookup(national) {
  return call("/api/bookings/status", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ code: confirmation.code, cc: "31", national, lang: "ru" }),
  });
}
const looked = await lookup("612345678");
assert(looked.status === 200, `status ${looked.status} ${looked.text}`);
const visit0 = JSON.parse(looked.text).visit;
assert(visit0.status === "requested", `requested ${visit0.status}`);
assert(String(visit0.address).includes("Kromme Esse"), `address ${visit0.address}`);
assert(visit0.phone === "+31612345678", `phone ${visit0.phone}`);
assert(String(visit0.vehicle).includes("Golf"), "vehicle");
const wrong = await lookup("600000000");
assert(wrong.status === 404, `wrong phone ${wrong.status}`);

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
const afterConfirm = await lookup("612345678");
assert(JSON.parse(afterConfirm.text).visit.status === "confirmed", "client confirmed");
const progressed = await call(`/api/admin/bookings/${id}/progress`, { method: "POST", headers: { cookie: token } });
assert(progressed.status === 200, "progress");
const afterProgress = await lookup("612345678");
assert(JSON.parse(afterProgress.text).visit.status === "in_progress", "client in progress");
const corrected = await call(`/api/admin/bookings/${id}/correct`, {
  method: "POST",
  headers: { "content-type": "application/json", cookie: token },
  body: JSON.stringify({ problem: "Фильтр и масло" }),
});
assert(corrected.status === 200, `correct ${corrected.status} ${corrected.text}`);
const afterCorrect = await lookup("612345678");
assert(JSON.parse(afterCorrect.text).visit.problem.includes("Фильтр"), "client problem");
const cancelled = await call(`/api/admin/bookings/${id}/cancel`, { method: "POST", headers: { cookie: token } });
assert(cancelled.status === 200, "cancel");
const afterCancel = await lookup("612345678");
assert(JSON.parse(afterCancel.text).visit.status === "cancelled", "client cancelled");

const lead = new FormData();
lead.set("service", "tyre-fit");
lead.set("name", "Олег");
lead.set("cc", "31");
lead.set("national", "612345670");
lead.set("note", "Зимняя резина");
lead.set("lang", "ru");
const leadRes = await call("/api/leads", { method: "POST", body: lead });
assert(leadRes.status === 200, `lead ${leadRes.status} ${leadRes.text}`);
const leadCode = JSON.parse(leadRes.text).code;
assert(String(leadCode).startsWith("LD-"), "lead code");
const leads = await call("/api/admin/leads", { headers: { cookie: token } });
assert(leads.status === 200, "admin leads");
const leadRow = JSON.parse(leads.text).leads.find((row) => row.code === leadCode);
assert(leadRow && leadRow.contact_name === "Олег", "lead stored");
assert(leadRow.service_id === "tyre-fit", "lead service");
assert(leadRow.status === "new", "lead is new");
const leadDone = await call(`/api/admin/leads/${leadRow.id}/done`, { method: "POST", headers: { cookie: token } });
assert(leadDone.status === 200, "lead done");
const leadsAfter = await call("/api/admin/leads", { headers: { cookie: token } });
assert(JSON.parse(leadsAfter.text).leads.find((row) => row.id === leadRow.id).status === "done", "lead status done");

const visit = await call("/api/visit", {
  method: "POST",
  headers: { "content-type": "application/json", "cf-ipcountry": "NL", "cf-ipcity": "Rotterdam" },
  body: JSON.stringify({ vid: "session-visit-1", path: "/diensten/tyre-fit", panel: "services" }),
});
assert(visit.status === 200, `visit ${visit.status}`);
await call("/api/visit", {
  method: "POST",
  headers: { "content-type": "application/json", "cf-ipcountry": "NL", "cf-ipcity": "Rotterdam" },
  body: JSON.stringify({ vid: "session-visit-1", path: "/", panel: "home" }),
});
const stats = await call("/api/admin/stats", { headers: { cookie: token } });
assert(stats.status === 200, "admin stats");
const statsBody = JSON.parse(stats.text);
assert(statsBody.uniques >= 1, "unique visits");
assert(statsBody.views >= 2, "page views");
assert(statsBody.countries.some((row) => row.country === "NL" && String(row.city).includes("Rotterdam")), "country from CF header");
const adminPage = await call("/admin", { headers: { cookie: token } });
assert(adminPage.text.includes("Статистика"), "stats section label");
assert(adminPage.text.includes("Заявки"), "leads section label");
assert(!adminPage.text.includes('data-panel="book"'), "admin has no public book panel");

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
