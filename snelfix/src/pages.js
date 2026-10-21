import { asset, siteConfig } from "./site.config.js";
import { esc, localizePath, minLabel } from "./util.js";

const LOCALE = { nl: "nl_NL", en: "en_GB", ru: "ru_RU", uk: "uk_UA" };
const LANG_ORDER = ["ru", "nl", "en", "uk"];
const LANG_LABEL = { ru: "RU", nl: "NL", en: "EN", uk: "UA" };
const LANG_NAME = { ru: "Русский", nl: "Nederlands", en: "English", uk: "Українська" };

function safeJson(data) {
  return JSON.stringify(data).replace(/</g, "\\u003c");
}

function href(lang, path) {
  return localizePath(lang, path);
}

function wordmark() {
  return `<span class="mark" aria-label="SnelFix Auto"><span class="mark-name">SNELFIX</span><span class="mark-auto">AUTO</span></span>`;
}

function criticalCss() {
  return `<style>html,body{margin:0;background:#07080a;color:#f7f7f5;height:100svh;height:100dvh;max-height:100svh;overflow:hidden}</style>`;
}

function ico(name) {
  const paths = {
    book: '<rect x="5" y="3.5" width="14" height="17" rx="1.2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M9 3.5v17M5 9h14" stroke="currentColor" stroke-width="1.6"/>',
    tow: '<path d="M3 15.5V9h5.2l2 3H19l2 3.5H3z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><circle cx="8" cy="17.6" r="1.5" fill="currentColor"/><circle cx="16.2" cy="17.6" r="1.5" fill="currentColor"/>',
    phone: '<path d="M8 3.5h2.4l1.1 3.1-1.7 1.1a10 10 0 0 0 4.4 4.4l1.1-1.7 3.1 1.1V14A1.6 1.6 0 0 1 16.8 15.6 12.6 12.6 0 0 1 6.4 5.2 1.6 1.6 0 0 1 8 3.5z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>',
    wa: '<path d="M12 4.2a7.2 7.2 0 0 0-6.2 10.8L4.8 19.6l4.7-1.2A7.2 7.2 0 1 0 12 4.2z" fill="none" stroke="currentColor" stroke-width="1.6"/>',
    chev: '<path d="M9 6.5 15 12l-6 5.5" fill="none" stroke="currentColor" stroke-width="1.6"/>',
  };
  return `<svg class="ico" viewBox="0 0 24 24" aria-hidden="true">${paths[name] || ""}</svg>`;
}

function seq(node) {
  if (Array.isArray(node)) return node;
  return Object.keys(node || {})
    .filter((key) => /^\d+$/.test(key))
    .sort((a, b) => Number(a) - Number(b))
    .map((key) => node[key]);
}

function euro(cents) {
  if (cents == null || cents === "") return "";
  return `€ ${Math.round(Number(cents) / 100)}`;
}

function priceLabel(copy, service) {
  if (service.kind === "ask") return copy.price.ask;
  const amount = euro(service.price_cents);
  if (!amount) return copy.price.ask;
  if (service.kind === "hour") return `${amount} / ${copy.price.hour}`;
  if (service.kind === "from") return `${copy.price.from} ${amount}`;
  return amount;
}

function weekdayFromIso(iso) {
  const [y, m, d] = String(iso || "").split("-").map(Number);
  if (!y || !m || !d) return 0;
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

function hourRow(rows, day) {
  return (rows || []).find((row) => Number(row.weekday) === day) || null;
}

function span(copy, row) {
  if (!row || row.open_min == null) return copy.hours.closed;
  return `${minLabel(row.open_min)}–${minLabel(row.close_min)}`;
}

function weekLine(copy, rows) {
  const mon = hourRow(rows, 1);
  const same = [2, 3, 4, 5].every((day) => {
    const row = hourRow(rows, day);
    return !!row && !!mon && row.open_min === mon.open_min && row.close_min === mon.close_min;
  });
  const weekday = same ? span(copy, mon) : span(copy, mon);
  return `${copy.home.wd} ${weekday} · ${copy.home.sat} ${span(copy, hourRow(rows, 6))} · ${copy.home.sun} ${span(copy, hourRow(rows, 0))}`;
}

function todayLine(copy, rows, today) {
  const day = weekdayFromIso(today);
  return `${copy.hours[day]} ${span(copy, hourRow(rows, day))}`;
}

function gDestination(garage) {
  const q = encodeURIComponent(`${garage.street}, ${garage.postal} ${garage.city}, Netherlands`);
  return `https://www.google.com/maps/dir/?api=1&destination=${q}`;
}

function appleDestination(garage) {
  return `https://maps.apple.com/?daddr=${garage.lat},${garage.lng}&dirflg=d`;
}

function langs(ctx, path) {
  return `<nav class="langs" aria-label="${esc(ctx.copy.nav.lang)}">${LANG_ORDER.map((code) => {
    const current = code === ctx.lang ? ` aria-current="true"` : "";
    return `<a href="${esc(href(code, path))}" hreflang="${code}" lang="${code}"${current} title="${esc(LANG_NAME[code])}">${LANG_LABEL[code]}</a>`;
  }).join("")}</nav>`;
}

function baySvg(kind) {
  return `<svg class="bay bay-${kind}" viewBox="0 0 140 180" aria-hidden="true">
    <path d="M34 6v166M106 6v166" fill="none" stroke="currentColor" stroke-width="5"/>
    <path d="M26 8h88M18 172h104" fill="none" stroke="currentColor" stroke-width="3"/>
    <g class="carriage">
      <path d="M34 98h72" fill="none" stroke="currentColor" stroke-width="6"/>
      <path d="M42 98v7h10v-7M88 98v7h10v-7" fill="currentColor"/>
      <path d="M40 86h16l6-18h20l8 18h14v12H40z" fill="currentColor"/>
      <path d="M62 70h20l4 12H58z" fill="none" stroke="currentColor" stroke-width="1.6" opacity=".55"/>
      <circle cx="54" cy="100" r="7" fill="none" stroke="currentColor" stroke-width="2.4"/>
      <circle cx="90" cy="100" r="7" fill="none" stroke="currentColor" stroke-width="2.4"/>
    </g>
  </svg>`;
}

function haulScene() {
  const wheel = (x, y) => `<g transform="translate(${x} ${y})"><g class="haul-wheel"><circle r="11" fill="#07080a" stroke="currentColor" stroke-width="2.6"/><path d="M0-7v14M-7 0h14" stroke="currentColor" stroke-width="1.6"/></g></g>`;
  return `<svg class="haul-svg" viewBox="0 0 400 168" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
    <rect width="400" height="168" fill="#07080a"/>
    <rect y="100" width="400" height="68" fill="#10140c"/>
    <g class="haul-poles" fill="none" stroke="currentColor" stroke-width="1.6" opacity=".28">
      <path d="M8 100V58M62 100V48M116 100V58M170 100V48M224 100V58M278 100V48"/>
    </g>
    <path d="M0 102h400M0 156h400" fill="none" stroke="currentColor" stroke-width="1.4" opacity=".4"/>
    <g class="haul-dashes"><path d="M-60 128h520" fill="none" stroke="currentColor" stroke-width="2.4" stroke-dasharray="18 16"/></g>
    <g class="haul-bay">
      <path d="M308 168V36h86v132" fill="#07080a" stroke="currentColor" stroke-width="2.4"/>
      <rect class="haul-glow" x="320" y="48" width="62" height="120" fill="currentColor"/>
      <path class="haul-door" d="M322 168V50h58v118" fill="#0c1204" stroke="currentColor" stroke-width="1.6"/>
      <path d="M338 168V62M364 168V62" fill="none" stroke="currentColor" stroke-width="2.4" opacity=".7"/>
      <path class="haul-beam" d="M332 100h40" fill="none" stroke="currentColor" stroke-width="4"/>
    </g>
    <g class="haul-truck" transform="translate(118 0)">
      <path d="M0 98h102v14H0z" fill="currentColor"/>
      <path d="M98 112V64h26l22 24v24z" fill="currentColor"/>
      <path d="M108 86h14V68h-10z" fill="#07080a"/>
      <rect class="haul-beacon" x="116" y="54" width="16" height="8" fill="currentColor"/>
      <g class="haul-cable" fill="none" stroke="currentColor" stroke-width="2.2">
        <path d="M6 98H-18V112"/>
        <circle cx="-18" cy="112" r="3.4"/>
      </g>
      ${wheel(22, 112)}
      ${wheel(116, 112)}
    </g>
    <g class="haul-car" transform="translate(4 10)">
      <path d="M4 100h90v-16H74L58 66H30L16 84H4z" fill="#07080a" stroke="currentColor" stroke-width="2.6" stroke-linejoin="round"/>
      <path d="M32 84l8-14h18l8 14z" fill="currentColor"/>
      <circle class="haul-hazard" cx="14" cy="88" r="3" fill="currentColor"/>
      ${wheel(22, 100)}
      ${wheel(72, 100)}
    </g>
  </svg>`;
}

function splashHtml(copy) {
  return `<div id="splash" class="splash">
    <div class="splash-bg" aria-hidden="true">
      <i class="splash-glow"></i>
      <i class="splash-sheen"></i>
    </div>
    <div class="splash-stage">
      ${wordmark()}
      <span class="flag" aria-hidden="true"><i></i><i></i><i></i></span>
    </div>
    <button type="button" id="splash-skip" class="splash-skip">${esc(copy.splash.skip)}</button>
  </div>
  <script>
  (function(){
    var el=document.getElementById("splash");
    if(!el)return;
    if(document.documentElement.classList.contains("no-splash")){el.remove();return;}
    var reduce=false;
    try{reduce=matchMedia("(prefers-reduced-motion: reduce)").matches;}catch(e){}
    var ms=reduce?320:1500;
    var done=false;
    function finish(){
      if(done)return; done=true;
      try{sessionStorage.setItem("snelfix_splash","1");}catch(e){}
      el.classList.add("is-out");
      setTimeout(function(){ if(el.parentNode) el.remove(); }, 280);
    }
    var skip=document.getElementById("splash-skip");
    if(skip) skip.addEventListener("click", finish);
    setTimeout(finish, ms);
  })();
  </script>`;
}

function jsonLd(ctx) {
  const { origin, brand, garages, hours } = ctx;
  return {
    "@context": "https://schema.org",
    "@graph": (garages || []).map((garage) => ({
      "@type": ["AutoRepair", "LocalBusiness"],
      "@id": `${origin}/vestigingen/${garage.id}#business`,
      name: garage.name,
      url: `${origin}${href(ctx.lang, `/vestigingen/${garage.id}`)}`,
      telephone: brand.phoneTel,
      image: `${origin}/photos/workshop.jpg`,
      address: {
        "@type": "PostalAddress",
        streetAddress: garage.street,
        postalCode: garage.postal,
        addressLocality: garage.city,
        addressCountry: "NL",
      },
      geo: { "@type": "GeoCoordinates", latitude: garage.lat, longitude: garage.lng },
      openingHoursSpecification: (hours[garage.id] || [])
        .filter((row) => row.open_min != null)
        .map((row) => ({
          "@type": "OpeningHoursSpecification",
          dayOfWeek: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][row.weekday],
          opens: minLabel(row.open_min),
          closes: minLabel(row.close_min),
        })),
    })),
  };
}

function phoneFields(copy) {
  const countries = [
    ["31", "NL"], ["32", "BE"], ["49", "DE"], ["33", "FR"], ["352", "LU"], ["44", "GB"],
    ["48", "PL"], ["380", "UA"], ["40", "RO"], ["359", "BG"], ["90", "TR"], ["34", "ES"],
    ["39", "IT"], ["351", "PT"], ["43", "AT"], ["41", "CH"], ["46", "SE"], ["47", "NO"],
    ["45", "DK"], ["358", "FI"], ["420", "CZ"], ["421", "SK"], ["36", "HU"],
  ];
  return `<label class="phone-label">${esc(copy.book.phone)}
    <span class="phone-inputs">
      <select name="cc" aria-label="country">${countries.map(([cc, iso]) => `<option value="${cc}"${cc === "31" ? " selected" : ""}>${iso} +${cc}</option>`).join("")}</select>
      <input name="national" inputmode="tel" autocomplete="tel-national" required placeholder="6 13044422">
    </span>
  </label>`;
}

function tabs(ctx, panel) {
  const { copy, lang } = ctx;
  const items = [
    ["home", "/", copy.tab.home],
    ["services", "/diensten", copy.tab.services],
    ["tow", "/evacuatie", copy.tab.tow],
    ["contacts", "/contact", copy.tab.contacts],
  ];
  return `<nav class="tabs" aria-label="${esc(copy.nav.menu)}">${items.map(([id, path, label]) => {
    const on = id === panel ? ` aria-current="page"` : "";
    return `<a href="${esc(href(lang, path))}" data-panel="${id}"${on}><span>${esc(label)}</span></a>`;
  }).join("")}</nav>`;
}

function homePanel(ctx) {
  const { copy, lang, garages, hours, today } = ctx;
  const byId = Object.fromEntries((garages || []).map((garage) => [garage.id, garage]));
  const door = (garage, kind) => {
    if (!garage) return "";
    return `<a class="door door-${kind}" href="${esc(href(lang, `/vestigingen/${garage.id}`))}" data-panel="contacts" data-garage="${esc(garage.id)}">
      <span class="door-name">SnelFix Auto<br>${esc(garage.city)}</span>
      ${baySvg(kind)}
      <span class="door-copy">
        <small>${esc(garage.street)}</small>
        <small class="door-hours">${esc(todayLine(copy, hours[garage.id], today))}</small>
      </span>
    </a>`;
  };
  return `<section id="panel-home" class="panel panel-home" data-panel="home">
    <p class="home-line">${esc(copy.home.line)}</p>
    <div class="doors">
      ${door(byId.waddinxveen, "a")}
      ${door(byId["de-bilt"], "b")}
    </div>
  </section>`;
}

function servicesPanel(ctx, serviceId) {
  const { copy, lang, services, brand } = ctx;
  const workshop = services.filter((service) => service.kind !== "tow");
  const tiles = workshop.map((service, index) => `<a class="tile" href="${esc(href(lang, `/diensten/${service.id}`))}" data-service="${esc(service.id)}">
    <img class="tile-photo" src="/photos/jobs/${esc(service.id)}.jpg" alt="">
    <span class="idx">${String(index + 1).padStart(2, "0")}</span>
    <b>${esc(service.title)}</b>
    <span class="mono tile-price">${esc(String(service.duration_min))} ${esc(copy.svc.minutes)} · ${esc(priceLabel(copy, service))}</span>
  </a>`).join("");
  const details = workshop.map((service) => {
    const wa = `${String(brand.whatsapp || "https://wa.me/31613044422").split("?")[0]}?text=${encodeURIComponent(service.title)}`;
    return `<article class="detail" id="svc-${esc(service.id)}" data-service-detail="${esc(service.id)}"${service.id === serviceId ? "" : " hidden"}>
    <button type="button" class="text-btn" data-service-back>${esc(copy.svc.back)}</button>
    <h2>${esc(service.title)}</h2>
    <p class="mono">${esc(String(service.duration_min))} ${esc(copy.svc.minutes)} · ${esc(priceLabel(copy, service))}</p>
    <p class="summary">${esc(service.summary || "")}</p>
    <p class="body-copy">${esc(service.body || "")}</p>
    <div class="step-nav">
      <a class="btn btn-primary" href="${esc(wa)}" target="_blank" rel="noopener">${esc(copy.dock.wa)}</a>
      <a class="btn btn-ghost" href="tel:${esc(brand.phoneTel)}">${esc(copy.dock.call)}</a>
    </div>
  </article>`;
  }).join("");
  return `<section id="panel-services" class="panel" data-panel="services">
    <div class="svc-grid"${serviceId ? " hidden" : ""}>${tiles}</div>
    ${details}
  </section>`;
}

function towSquare(copy, name, label, tone) {
  const auto = name === "pickup" ? ` autocomplete="street-address"` : "";
  return `<div class="sq sq-${tone}" data-point="${name}">
    <span class="sq-k">${esc(label)}</span>
    <textarea class="sq-field" data-value name="${name}" required maxlength="180" rows="3" placeholder="${esc(copy.tow.byAddress)}"${auto}></textarea>
    <button type="button" class="sq-mode" data-mode>${esc(copy.tow.byMap)}</button>
    <div class="sq-map" hidden>
      <div class="pinmap" data-lat="52.0900" data-lng="4.9200" data-set="0">
        <div class="pinmap-world"></div>
        <i class="pinmap-pin" aria-hidden="true"><i></i></i>
      </div>
      <button type="button" class="sq-here" data-geo>${esc(copy.tow.here)}</button>
    </div>
    <p class="point-error" hidden>${esc(copy.tow.pointNeed)}</p>
  </div>`;
}

function towPanel(ctx) {
  const { copy } = ctx;
  return `<section id="panel-tow" class="panel panel-tow" data-panel="tow">
    <div class="haul">
      ${haulScene()}
      <p class="haul-kicker">${esc(copy.tow.kicker)}</p>
    </div>
    <p class="tow-cap">${esc(copy.tow.capacity)}</p>
    <form id="tow-form" class="tow-sheet" novalidate>
      <div class="tow-squares">
        ${towSquare(copy, "pickup", copy.tow.pickup, "pick")}
        ${towSquare(copy, "delivery", copy.tow.delivery, "drop")}
      </div>
      <div class="tow-rest" hidden>
        <label class="tow-problem">${esc(copy.tow.problem)}<textarea name="problem" rows="2" maxlength="400"></textarea></label>
        <label>${esc(copy.tow.name)}<input name="name" required maxlength="80" autocomplete="name"></label>
        ${phoneFields(copy)}
        <div class="two">
          <label>${esc(copy.tow.make)}<input name="make" required maxlength="40"></label>
          <label>${esc(copy.tow.model)}<input name="model" required maxlength="40"></label>
        </div>
        <p class="form-error" id="tow-error" role="alert"></p>
        <button class="btn btn-primary" type="submit">${esc(copy.tow.submit)}</button>
      </div>
    </form>
    <div id="tow-done" hidden></div>
  </section>`;
}

function contactsPanel(ctx, garageId, sheet) {
  const { copy, lang, brand, garages, hours, notes, today } = ctx;
  const plates = garages.map((garage, index) => {
    const note = (notes[garage.id] && notes[garage.id][lang]) || "";
    const on = garage.id === garageId ? " is-on" : "";
    return `<article class="loc-row loc-static${on}" id="garage-${esc(garage.id)}">
      <span class="idx">${String(index + 1).padStart(2, "0")}</span>
      <span class="loc-copy"><b>${esc(garage.city)}</b><small>${esc(garage.street)}, ${esc(garage.postal)}</small><small class="hint">${esc(note)}</small></span>
      <span class="routes">
        <a class="route route-google" href="${esc(gDestination(garage))}">Google Maps</a>
        <a class="route route-apple" href="${esc(appleDestination(garage))}">Apple Maps</a>
      </span>
    </article>`;
  }).join("");
  const sheets = [
    ["faq", copy.faq.title, seq(copy.faq).map((item) => `<h3>${esc(item.q)}</h3><p>${esc(item.a)}</p>`).join("")],
    ["terms", copy.meta.termsTitle.replace(" — SnelFix Auto", ""), seq(copy.terms).map((block) => `<h3>${esc(block.h)}</h3>${seq(block.p).map((p) => `<p>${esc(p)}</p>`).join("")}`).join("")],
    ["privacy", copy.meta.privacyTitle.replace(" — SnelFix Auto", ""), seq(copy.privacy).map((block) => `<h3>${esc(block.h)}</h3>${seq(block.p).map((p) => `<p>${esc(p)}</p>`).join("")}`).join("")],
  ];
  return `<section id="panel-contacts" class="panel" data-panel="contacts">
    <div class="contact-fit"${sheet ? " hidden" : ""}>
      <div class="loc-list">${plates}</div>
      <figure class="map-plate">
        <img src="/maps/garages.jpg" alt="${esc(copy.contact.map)}" width="1280" height="853">
      </figure>
      <div class="qa qa-tight">
        <a class="qa-btn qa-primary" href="tel:${esc(brand.phoneTel)}">${ico("phone")}<span>${esc(brand.phoneDisplay)}</span></a>
        <a class="qa-btn" href="${esc(brand.whatsapp)}">${ico("wa")}<span>${esc(copy.dock.wa)}</span></a>
        <a class="qa-btn" href="${esc(brand.telegram)}"><span>Telegram</span></a>
        <a class="qa-btn" href="${esc(brand.instagram)}"><span>Instagram</span></a>
      </div>
    </div>
    ${sheets.map(([id, title, body]) => `<article class="sheet" id="sheet-${id}" data-sheet-panel="${id}"${sheet === id ? "" : " hidden"}>
      <a class="text-btn" href="${esc(href(lang, "/contact"))}" data-sheet-close>${esc(copy.step.back)}</a>
      <h2>${esc(title)}</h2>
      <div class="sheet-body">${body}</div>
    </article>`).join("")}
  </section>`;
}

function shell(ctx, { panel, title, description, path, serviceId = "", garageId = "", sheet = "", banner = "" }) {
  const { lang, origin, copy, brand, analyticsId, gsc } = ctx;
  const canonical = origin + href(lang, path);
  const alternates = siteConfig.locales.map((code) => {
    const url = origin + href(code, path);
    return `<link rel="alternate" hreflang="${code}" href="${esc(url)}">`;
  }).join("");
  const boot = {
    lang,
    panel,
    analyticsId: analyticsId || "",
    points: (ctx.garages || []).map((garage) => ({
      id: garage.id,
      name: garage.name,
      lat: garage.lat,
      lng: garage.lng,
      address: `${garage.street}, ${garage.postal} ${garage.city}`,
    })),
  };
  const strings = {
    book: copy.book,
    tow: copy.tow,
  };
  const show = (id) => (id === panel ? "" : " hidden");
  return `<!doctype html>
<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<link rel="canonical" href="${esc(canonical)}">
${alternates}
<link rel="alternate" hreflang="x-default" href="${esc(origin + href("ru", path))}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:type" content="website">
<meta property="og:url" content="${esc(canonical)}">
<meta property="og:locale" content="${LOCALE[lang] || "ru_RU"}">
<meta name="theme-color" content="#07080a">
${criticalCss()}
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
${gsc ? `<meta name="google-site-verification" content="${esc(gsc)}">` : ""}
<link rel="stylesheet" href="${asset.css}">
<script>try{if(sessionStorage.getItem("snelfix_splash")==="1")document.documentElement.classList.add("no-splash")}catch(e){}</script>
<script type="application/ld+json">${safeJson(jsonLd(ctx))}</script>
</head>
<body class="app-body">
${splashHtml(copy)}
<div class="app">
  <header class="bar">
    <a class="brand" href="${esc(href(lang, "/"))}" data-panel="home">${wordmark()}</a>
    ${langs(ctx, path)}
  </header>
  <main id="content" class="stage">
    ${banner ? `<p class="banner">${esc(banner)}</p>` : ""}
    <div class="panel-slot"${show("home")}>${homePanel(ctx)}</div>
    <div class="panel-slot"${show("services")}>${servicesPanel(ctx, serviceId)}</div>
    <div class="panel-slot"${show("tow")}>${towPanel(ctx)}</div>
    <div class="panel-slot"${show("contacts")}>${contactsPanel(ctx, garageId, sheet)}</div>
  </main>
  ${tabs(ctx, panel)}
</div>
<script type="application/json" id="sf-extra">${safeJson({ strings })}</script>
<script type="application/json" id="sf-boot">${safeJson(boot)}</script>
<script type="module" src="${asset.main}"></script>
</body>
</html>`;
}

function meta(ctx, keyTitle, keyDesc, path, panel, extra = {}) {
  return shell(ctx, {
    panel,
    title: ctx.copy.meta[keyTitle],
    description: ctx.copy.meta[keyDesc],
    path,
    ...extra,
  });
}

export function homePage(ctx) {
  return meta(ctx, "homeTitle", "homeDesc", "/", "home");
}

export function servicesPage(ctx) {
  return meta(ctx, "servicesTitle", "servicesDesc", "/diensten", "services");
}

export function servicePage(ctx, service) {
  return shell(ctx, {
    panel: "services",
    title: `${service.title} — SnelFix Auto`,
    description: service.summary || ctx.copy.meta.servicesDesc,
    path: `/diensten/${service.id}`,
    serviceId: service.id,
  });
}

export function locationPage(ctx, garage) {
  return shell(ctx, {
    panel: "contacts",
    title: `${garage.city} — SnelFix Auto`,
    description: `${garage.street}, ${garage.postal} ${garage.city}`,
    path: `/vestigingen/${garage.id}`,
    garageId: garage.id,
  });
}

export function towPage(ctx) {
  return meta(ctx, "towTitle", "towDesc", "/evacuatie", "tow");
}

export function contactPage(ctx) {
  return shell(ctx, {
    panel: "contacts",
    title: ctx.copy.meta.homeTitle,
    description: ctx.copy.meta.homeDesc,
    path: "/contact",
  });
}

export function faqPage(ctx) {
  return shell(ctx, {
    panel: "contacts",
    title: ctx.copy.meta.faqTitle,
    description: ctx.copy.meta.faqDesc,
    path: "/faq",
    sheet: "faq",
  });
}

export function legalPage(ctx, kind) {
  const map = {
    terms: { path: "/voorwaarden", title: "termsTitle", desc: "termsDesc", sheet: "terms" },
    privacy: { path: "/privacy", title: "privacyTitle", desc: "privacyDesc", sheet: "privacy" },
  };
  const page = map[kind];
  return shell(ctx, {
    panel: "contacts",
    title: ctx.copy.meta[page.title],
    description: ctx.copy.meta[page.desc],
    path: page.path,
    sheet: page.sheet,
  });
}

export function notFoundPage(ctx) {
  return shell(ctx, {
    panel: "home",
    title: ctx.copy.meta.notFound,
    description: ctx.copy.notfound.body,
    path: "/404",
    banner: ctx.copy.notfound.title,
  });
}

function adminLangs(lang) {
  return `<nav class="langs">${LANG_ORDER.map((code) => {
    const current = code === lang ? ` aria-current="true"` : "";
    return `<a href="${esc(href(code, "/admin"))}"${current}>${LANG_LABEL[code]}</a>`;
  }).join("")}</nav>`;
}

export function adminLoginPage(copy, lang = "ru") {
  return `<!doctype html>
<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(copy.admin.loginTitle)} — SnelFix</title>
<meta name="theme-color" content="#07080a">
${criticalCss()}
<link rel="stylesheet" href="${asset.css}">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
</head>
<body class="page-admin">
<main class="admin-login">
  ${adminLangs(lang)}
  <a class="brand" href="${esc(href(lang, "/"))}">${wordmark()}</a>
  <h1>${esc(copy.admin.loginTitle)}</h1>
  <form id="login-form" class="form">
    <label>${esc(copy.admin.username)}<input name="username" autocomplete="username" required></label>
    <label>${esc(copy.admin.password)}<input name="password" type="password" autocomplete="current-password" required></label>
    <p class="form-error" id="login-error" role="alert"></p>
    <button class="btn btn-amber" type="submit">${esc(copy.admin.signIn)}</button>
  </form>
</main>
<script type="application/json" id="sf-admin">${safeJson(copy.admin)}</script>
<script type="module" src="${asset.admin}"></script>
</body></html>`;
}

export function adminAppPage(copy, lang = "ru") {
  const tabsAdmin = ["bookings", "tows", "services", "garages", "customers", "news", "password"];
  return `<!doctype html>
<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(copy.admin.loginTitle)} — SnelFix</title>
<meta name="theme-color" content="#07080a">
${criticalCss()}
<link rel="stylesheet" href="${asset.css}">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
</head>
<body class="page-admin" data-mode="app">
<header class="admin-bar">
  <a class="brand" href="${esc(href(lang, "/"))}">${wordmark()}</a>
  ${adminLangs(lang)}
  <strong>${esc(copy.admin.loginTitle)}</strong>
  <button type="button" id="logout" class="btn btn-ghost">${esc(copy.admin.logout)}</button>
</header>
<label class="admin-jump">${esc(copy.nav.menu)}
  <select id="section">
    ${tabsAdmin.map((tab) => `<option value="${tab}">${esc(copy.admin.tab[tab])}</option>`).join("")}
  </select>
</label>
<main id="admin-root" class="admin-root"></main>
<p class="form-error" id="admin-error" role="alert"></p>
<script type="application/json" id="sf-admin">${safeJson({ admin: copy.admin, hours: copy.hours, hoursClosed: copy.hours.closed })}</script>
<script type="module" src="${asset.admin}"></script>
</body></html>`;
}
