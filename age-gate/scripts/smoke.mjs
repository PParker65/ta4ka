const base = (process.argv[2] || "http://127.0.0.1:8787").replace(/\/$/, "");
const password = process.env.AGE_GATE_ADMIN_PASSWORD || "";
const chromeUa = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36";

function fail(message) {
  console.error("FAIL", message);
  process.exit(1);
}

async function req(path, options = {}) {
  const headers = new Headers(options.headers || {});
  if (options.jar) {
    const cookie = options.jar.join("; ");
    if (cookie) headers.set("cookie", cookie);
  }
  const res = await fetch(base + path, {
    method: options.method || "GET",
    headers,
    body: options.body,
    redirect: "manual",
  });
  const setCookie = typeof res.headers.getSetCookie === "function" ? res.headers.getSetCookie() : [];
  if (options.jar) {
    for (const line of setCookie) {
      const pair = line.split(";")[0];
      const name = pair.split("=")[0];
      const idx = options.jar.findIndex((item) => item.startsWith(name + "="));
      if (idx >= 0) options.jar.splice(idx, 1);
      if (!/Max-Age=0/i.test(line)) options.jar.push(pair);
    }
  }
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch { json = null; }
  return { status: res.status, text, json, setCookie };
}

function assertIncludes(text, needle, label) {
  if (!text.includes(needle)) fail(label + " missing " + JSON.stringify(needle));
}

const ua = await req("/", { headers: { "CF-IPCountry": "UA", "CF-IPCity": "Kyiv", "CF-Region": "Kyiv", "User-Agent": chromeUa } });
assertIncludes(ua.text, "Мені є 18 років", "UA button");
assertIncludes(ua.text, "Лише для дорослих.", "UA line");
assertIncludes(ua.text, 'lang="uk"', "UA lang");
if (!ua.text.includes("Coding Teams")) fail("credit missing");

const es = await req("/", { headers: { "CF-IPCountry": "ES", "User-Agent": chromeUa } });
assertIncludes(es.text, "Tengo 18 años", "ES button");
assertIncludes(es.text, 'lang="es"', "ES lang");

const unknown = await req("/", { headers: { "CF-IPCountry": "XX", "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.4", "User-Agent": chromeUa } });
assertIncludes(unknown.text, "J'ai 18 ans ou plus", "Accept-Language fr");

const knownDefault = await req("/", { headers: { "CF-IPCountry": "JP", "Accept-Language": "fr-FR,fr;q=0.9", "User-Agent": chromeUa } });
assertIncludes(knownDefault.text, "I am 18 or older", "JP stays English");

const jar = [];
const visit = await req("/", {
  jar,
  headers: { "CF-IPCountry": "UA", "CF-IPCity": "Kyiv", "CF-Region": "Kyiv", "User-Agent": chromeUa, Referer: "https://example.test/in" },
});
const idMatch = visit.text.match(/data-visit="(\d{13}_[0-9a-f]{8})"/);
if (!idMatch) fail("visit id missing");
const visitId = idMatch[1];

const hit = await req("/panel/hit", {
  jar,
  method: "POST",
  headers: { "content-type": "application/json", "CF-IPCountry": "UA", "User-Agent": chromeUa },
  body: JSON.stringify({ visitId, viewport: "1280x800", locale: "uk-UA", lang: "uk", referrer: "https://example.test/in", path: "/" }),
});
if (!hit.json || !hit.json.ok) fail("hit failed");

const timed = await req("/panel/time", {
  jar,
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ visitId, duration: 18 }),
});
if (!timed.json || !timed.json.ok) fail("time failed");

const locked = await req("/panel/stats");
if (locked.status !== 401) fail("stats should require a session");

if (!password) fail("AGE_GATE_ADMIN_PASSWORD is not set");
const bad = await req("/panel/login", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "nope" }),
});
if (bad.status !== 401) fail("bad login should be rejected");

const admin = [];
const logged = await req("/panel/login", {
  jar: admin,
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ username: "admin", password }),
});
if (!logged.json || !logged.json.ok) fail("login failed");
const sess = logged.setCookie.find((line) => line.startsWith("card_sess="));
if (!sess || !/HttpOnly/i.test(sess) || !/SameSite=Lax/i.test(sess)) fail("session cookie flags");

const secureLogin = await req("/panel/login", {
  method: "POST",
  headers: { "content-type": "application/json", "x-forwarded-proto": "https" },
  body: JSON.stringify({ username: "admin", password }),
});
const secureSess = (secureLogin.setCookie || []).find((line) => line.startsWith("card_sess="));
if (!secureSess || !/;\s*Secure/i.test(secureSess) || !/HttpOnly/i.test(secureSess) || !/SameSite=Lax/i.test(secureSess)) {
  fail("https session cookie should be HttpOnly, Secure, and SameSite=Lax");
}

const cleared = await req("/panel/settings", {
  jar: admin,
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ url: "" }),
});
if (!cleared.json || cleared.json.url) fail("clear url failed");

const early = await req("/panel/click", {
  jar,
  method: "POST",
  headers: { "content-type": "application/json", "CF-IPCountry": "UA", "CF-IPCity": "Kyiv", "User-Agent": chromeUa },
  body: JSON.stringify({ visitId, x: 180, y: 420, viewport: "1280x800", lang: "uk", path: "/" }),
});
if (!early.json || early.json.url) fail("click without a saved URL should not navigate");

const saved = await req("/panel/settings", {
  jar: admin,
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ url: base + "/admin" }),
});
if (!saved.json || saved.json.url !== base + "/admin") fail("save url failed");

const clicked = await req("/panel/click", {
  jar,
  method: "POST",
  headers: { "content-type": "application/json", "CF-IPCountry": "UA", "CF-IPCity": "Kyiv", "User-Agent": chromeUa },
  body: JSON.stringify({ x: 200, y: 440, viewport: "1280x800", lang: "uk", path: "/" }),
});
if (!clicked.json || clicked.json.url !== base + "/admin") fail("click did not return the saved URL");

const dash = await req("/panel/stats", { jar: admin });
if (!dash.json || !dash.json.ok) fail("stats failed");
const totals = dash.json.totals;
if (totals.clicks < 2) fail("clicks not recorded: " + totals.clicks);
if (totals.visits < 1) fail("visits not recorded");
const row = (dash.json.events || []).find((event) => event.type === "visit" && event.country === "UA" && event.device === "desktop");
if (!row) fail("visit row with country and device missing");
if (row.browser !== "Chrome" || row.os !== "Windows") fail("browser/os parse missed");
if (!row.city) fail("city missing");
const clickRow = (dash.json.events || []).find((event) => event.type === "click" && event.x === 200);
if (!clickRow || clickRow.control !== "age18") fail("click row missing position");
const timedRow = (dash.json.events || []).find((event) => event.id === visitId);
if (!timedRow || timedRow.duration < 18 || timedRow.viewport !== "1280x800") fail("time or viewport not stored");

const removed = await req("/panel/events/" + clickRow.id, { jar: admin, method: "DELETE" });
if (!removed.json || !removed.json.ok) fail("delete event failed");

console.log("ok", JSON.stringify({
  visits: totals.visits,
  uniques: totals.uniques,
  clicks: totals.clicks,
  avgTimeSec: totals.avgTimeSec,
  country: row.country,
  city: row.city,
  device: row.device,
}));
