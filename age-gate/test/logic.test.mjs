import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import test from "node:test";
import { copyFor, languageFor } from "../src/i18n.js";
import { canonicalTarget, geoFrom, parseUa, validDestUrl } from "../src/parse.js";

const root = new URL("../", import.meta.url);

test("country map and default English", () => {
  assert.equal(languageFor("UA"), "uk");
  assert.equal(languageFor("ru"), "ru");
  assert.equal(languageFor("KZ"), "ru");
  assert.equal(languageFor("ES"), "es");
  assert.equal(languageFor("MX"), "es");
  assert.equal(languageFor("US"), "en");
  assert.equal(languageFor("DE"), "de");
  assert.equal(languageFor("AT"), "de");
  assert.equal(languageFor("FR"), "fr");
  assert.equal(languageFor("IT"), "it");
  assert.equal(languageFor("BR"), "pt");
  assert.equal(languageFor("PL"), "pl");
  assert.equal(languageFor("TR"), "tr");
  assert.equal(languageFor("NL"), "nl");
  assert.equal(languageFor("SA"), "ar");
  assert.equal(languageFor("AE"), "ar");
  assert.equal(languageFor("EG"), "ar");
  assert.equal(languageFor("JP", "fr-FR,fr;q=0.9"), "en");
  assert.equal(copyFor("en").button, "I am 18 or older");
  assert.equal(copyFor("ru").button, "Мне есть 18 лет");
  assert.equal(copyFor("uk").button, "Мені є 18 років");
  assert.equal(copyFor("es").button, "Tengo 18 años");
});

test("Accept-Language only when the country is unknown", () => {
  assert.equal(languageFor("", "uk-UA,uk;q=0.9,en;q=0.8"), "uk");
  assert.equal(languageFor("XX", "es-MX,es;q=0.8,en;q=0.2"), "es");
  assert.equal(languageFor("T1", "de-DE,de;q=0.7"), "de");
  assert.equal(languageFor("", "zh-CN,zh;q=0.9,en;q=0.8"), "en");
  assert.equal(languageFor("US", "ru-RU,ru;q=0.9"), "en");
});

test("user agent and destination URL", () => {
  const phone = parseUa("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1");
  assert.deepEqual(phone, { device: "mobile", os: "iOS", browser: "Safari" });
  const desktop = parseUa("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36");
  assert.deepEqual(desktop, { device: "desktop", os: "Windows", browser: "Chrome" });
  const tablet = parseUa("Mozilla/5.0 (Linux; Android 13; SM-X200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
  assert.equal(tablet.device, "tablet");
  assert.equal(validDestUrl("https://example.com/go"), "https://example.com/go");
  assert.equal(validDestUrl("javascript:alert(1)"), "");
  assert.equal(validDestUrl("ftp://example.com"), "");
});

test("geo uses CF-IPCountry when present and request.cf otherwise", () => {
  const fromHeaders = geoFrom({
    cf: { country: "US", city: "Austin", region: "Texas" },
    headers: new Headers({ "CF-IPCountry": "UA", "CF-IPCity": "Kyiv", "CF-Region": "Kyiv" }),
  });
  assert.deepEqual(fromHeaders, { country: "UA", city: "Kyiv", region: "Kyiv" });
  const fromCf = geoFrom({
    cf: { country: "ES", city: "Madrid", region: "Madrid" },
    headers: new Headers(),
  });
  assert.deepEqual(fromCf, { country: "ES", city: "Madrid", region: "Madrid" });
});

test("www and http redirect to the https apex", () => {
  assert.equal(canonicalTarget("https://ilovdady.com/", "", ""), "");
  assert.equal(canonicalTarget("https://ilovdady.com/admin?x=1", "", ""), "");
  assert.equal(canonicalTarget("http://ilovdady.com/", "", ""), "https://ilovdady.com/");
  assert.equal(canonicalTarget("https://www.ilovdady.com/admin", "", ""), "https://ilovdady.com/admin");
  assert.equal(canonicalTarget("http://www.ilovdady.com/foo?a=1", "", ""), "https://ilovdady.com/foo?a=1");
  assert.equal(canonicalTarget("https://www.ilovdady.com/", "", '{"scheme":"http"}'), "https://ilovdady.com/");
  assert.equal(canonicalTarget("http://127.0.0.1:8787/", "", ""), "");
  const toml = fs.readFileSync(new URL("wrangler.toml", root), "utf8");
  assert.match(toml, /pattern = "ilovdady\.com"/);
  assert.match(toml, /pattern = "www\.ilovdady\.com"/);
  assert.match(toml, /custom_domain = true/);
  assert.match(toml, /workers_dev = false/);
  assert.equal(toml.includes("account_id"), false);
  assert.equal(toml.includes("zone_id"), false);
  assert.equal(toml.includes("ta4ka"), false);
});

test("the plaintext admin password is not in the project", () => {
  const secret = String.fromCharCode(109, 101, 120, 105, 99, 111, 54, 49, 53, 54, 64);
  const hash = createHash("sha256").update(secret).digest("hex");
  const files = [
    "src/worker.js",
    "src/i18n.js",
    "src/parse.js",
    "README.md",
    "wrangler.toml",
    "public/index.html",
    "public/admin.html",
    "public/js/gate.js",
    "public/js/admin.js",
  ];
  for (const file of files) {
    const src = fs.readFileSync(new URL(file, root), "utf8");
    assert.equal(src.includes(secret), false, file);
  }
  const worker = fs.readFileSync(new URL("src/worker.js", root), "utf8");
  assert.equal(worker.includes(hash), true);
  const gate = fs.readFileSync(new URL("public/js/gate.js", root), "utf8");
  assert.equal(gate.includes("location.assign"), true);
  assert.equal(gate.includes("window.open"), false);
  assert.equal(gate.includes("_blank"), false);
});
