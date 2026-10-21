import "./styles.css";

const boot = readJson("sf-boot");
const extra = readJson("sf-extra");
const lang = boot.lang || "ru";

loadAnalytics();

function loadAnalytics() {
  const id = boot.analyticsId;
  if (!id || document.getElementById("ga-src")) return;
  const script = document.createElement("script");
  script.id = "ga-src";
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(id)}`;
  document.head.appendChild(script);
  window.dataLayer = window.dataLayer || [];
  window.gtag = function gtag() { window.dataLayer.push(arguments); };
  window.gtag("js", new Date());
  window.gtag("config", id);
}

function panelFromPath(pathname) {
  const bare = pathname.replace(/^\/(nl|en|uk)(?=\/|$)/, "") || "/";
  if (bare === "/" || bare === "") return "home";
  if (bare === "/diensten" || bare.startsWith("/diensten/")) return "services";
  if (bare === "/evacuatie") return "tow";
  if (bare === "/contact" || bare.startsWith("/vestigingen/") || bare === "/faq" || bare === "/voorwaarden" || bare === "/privacy") return "contacts";
  return "home";
}

function serviceFromPath(pathname) {
  const bare = pathname.replace(/^\/(nl|en|uk)(?=\/|$)/, "") || "/";
  const match = bare.match(/^\/diensten\/([^/]+)$/);
  return match ? decodeURIComponent(match[1]) : "";
}

function sheetFromPath(pathname) {
  const bare = pathname.replace(/^\/(nl|en|uk)(?=\/|$)/, "") || "/";
  if (bare === "/faq") return "faq";
  if (bare === "/voorwaarden") return "terms";
  if (bare === "/privacy") return "privacy";
  return "";
}

function garageFromPath(pathname) {
  const bare = pathname.replace(/^\/(nl|en|uk)(?=\/|$)/, "") || "/";
  const match = bare.match(/^\/vestigingen\/([^/]+)$/);
  return match ? decodeURIComponent(match[1]) : "";
}

function focusGarage(id) {
  for (const row of document.querySelectorAll("#panel-contacts .loc-row")) {
    row.classList.toggle("is-on", Boolean(id) && row.id === `garage-${id}`);
  }
}

function showPanel(id) {
  for (const slot of document.querySelectorAll(".panel-slot")) {
    const panel = slot.querySelector(".panel");
    const on = panel && panel.dataset.panel === id;
    slot.hidden = !on;
  }
  for (const link of document.querySelectorAll(".tabs a")) {
    if (link.dataset.panel === id) link.setAttribute("aria-current", "page");
    else link.removeAttribute("aria-current");
  }
}

function showService(id) {
  const grid = document.querySelector(".svc-grid");
  const details = document.querySelectorAll("[data-service-detail]");
  if (!id) {
    if (grid) grid.hidden = false;
    for (const node of details) node.hidden = true;
    return;
  }
  if (grid) grid.hidden = true;
  for (const node of details) node.hidden = node.dataset.serviceDetail !== id;
}

function showSheet(id) {
  const fit = document.querySelector(".contact-fit");
  const sheets = document.querySelectorAll("[data-sheet-panel]");
  if (fit) fit.hidden = Boolean(id);
  for (const node of sheets) node.hidden = node.dataset.sheetPanel !== id;
}

document.addEventListener("click", (event) => {
  const link = event.target.closest("a[data-panel], a[data-service], a[data-sheet], button[data-service-back], a[data-sheet-close]");
  if (!link) return;
  if (link.dataset.serviceBack != null || link.hasAttribute("data-service-back")) {
    event.preventDefault();
    showService("");
    const base = document.querySelector('.tabs a[data-panel="services"]');
    if (base) history.pushState({}, "", base.href);
    return;
  }
  if (link.dataset.sheetClose != null) {
    event.preventDefault();
    showSheet("");
    const base = document.querySelector('.tabs a[data-panel="contacts"]');
    if (base) history.pushState({}, "", base.href);
    return;
  }
  if (link.dataset.service) {
    event.preventDefault();
    showPanel("services");
    showService(link.dataset.service);
    history.pushState({}, "", link.href);
    return;
  }
  if (link.dataset.sheet) {
    event.preventDefault();
    showPanel("contacts");
    showSheet(link.dataset.sheet);
    history.pushState({}, "", link.href);
    return;
  }
  if (link.dataset.panel && document.querySelector(`[data-panel="${link.dataset.panel}"].panel`)) {
    event.preventDefault();
    showPanel(link.dataset.panel);
    if (link.dataset.panel === "services") showService("");
    if (link.dataset.panel === "contacts") {
      showSheet("");
      focusGarage(link.dataset.garage || garageFromPath(link.getAttribute("href") || ""));
    }
    history.pushState({}, "", link.href);
  }
});

window.addEventListener("popstate", () => {
  const panel = panelFromPath(location.pathname);
  showPanel(panel);
  showService(panel === "services" ? serviceFromPath(location.pathname) : "");
  showSheet(panel === "contacts" ? sheetFromPath(location.pathname) : "");
  if (panel === "contacts") focusGarage(garageFromPath(location.pathname));
});
focusGarage(garageFromPath(location.pathname));

const towForm = document.getElementById("tow-form");
if (towForm) initTow(towForm);

function wireSteps(form, onEnter) {
  const steps = [...form.querySelectorAll(".step")];
  let index = steps.findIndex((step) => !step.hidden);
  if (index < 0) index = 0;
  function show(next) {
    index = next;
    form.dataset.step = String(index + 1);
    steps.forEach((step, i) => { step.hidden = i !== index; });
    if (onEnter) onEnter(index);
  }
  form.dataset.step = String(index + 1);
  form.addEventListener("click", (event) => {
    if (event.target.closest("[data-next]")) {
      event.preventDefault();
      if (!validStep(steps[index])) return;
      show(Math.min(index + 1, steps.length - 1));
    } else if (event.target.closest("[data-back]")) {
      event.preventDefault();
      show(Math.max(index - 1, 0));
    }
  });
  return { show };
}

function validStep(step) {
  const fields = [...step.querySelectorAll("input, select, textarea")].filter((field) => {
    if (field.disabled || field.type === "radio" || field.type === "checkbox" || field.type === "file") return false;
    return true;
  });
  for (const field of fields) {
    if (!field.checkValidity()) {
      field.reportValidity();
      return false;
    }
  }
  return true;
}

function project(lat, lng, z) {
  const n = 256 * 2 ** z;
  const x = ((lng + 180) / 360) * n;
  const s = Math.sin((lat * Math.PI) / 180);
  const y = (0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)) * n;
  return { x, y };
}

function unproject(x, y, z) {
  const n = 256 * 2 ** z;
  const lng = (x / n) * 360 - 180;
  const lat = (180 / Math.PI) * Math.atan(Math.sinh(Math.PI * (1 - (2 * y) / n)));
  return { lat, lng };
}

function paintMap(el) {
  if (!el) return;
  const z = 14;
  const lat = Number(el.dataset.lat);
  const lng = Number(el.dataset.lng);
  const w = el.clientWidth;
  const h = el.clientHeight;
  if (!w || !h) return;
  const { x: cx, y: cy } = project(lat, lng, z);
  const world = el.querySelector(".pinmap-world");
  const max = 2 ** z;
  const x0 = Math.floor((cx - w / 2) / 256);
  const x1 = Math.floor((cx + w / 2) / 256);
  const y0 = Math.floor((cy - h / 2) / 256);
  const y1 = Math.floor((cy + h / 2) / 256);
  world.replaceChildren();
  world.style.transform = "";
  for (let tx = x0; tx <= x1; tx += 1) {
    for (let ty = y0; ty <= y1; ty += 1) {
      if (ty < 0 || ty >= max) continue;
      const img = document.createElement("img");
      img.alt = "";
      img.draggable = false;
      const wrap = ((tx % max) + max) % max;
      img.src = `https://tile.openstreetmap.org/${z}/${wrap}/${ty}.png`;
      img.style.left = `${tx * 256 - (cx - w / 2)}px`;
      img.style.top = `${ty * 256 - (cy - h / 2)}px`;
      img.addEventListener("error", () => img.remove());
      world.appendChild(img);
    }
  }
}

function wirePinMap(el) {
  if (!el || el.dataset.wired) return;
  el.dataset.wired = "1";
  const world = el.querySelector(".pinmap-world");
  const z = 14;
  let drag = null;
  el.addEventListener("pointerdown", (event) => {
    if (event.target.closest("a, button")) return;
    el.setPointerCapture(event.pointerId);
    drag = { x: event.clientX, y: event.clientY, lat: Number(el.dataset.lat), lng: Number(el.dataset.lng) };
  });
  el.addEventListener("pointermove", (event) => {
    if (!drag) return;
    world.style.transform = `translate(${event.clientX - drag.x}px, ${event.clientY - drag.y}px)`;
  });
  function end(event) {
    if (!drag) return;
    const dx = event.clientX - drag.x;
    const dy = event.clientY - drag.y;
    const start = project(drag.lat, drag.lng, z);
    let point;
    if (Math.hypot(dx, dy) < 6) {
      const rect = el.getBoundingClientRect();
      point = unproject(start.x + (event.clientX - rect.left - rect.width / 2), start.y + (event.clientY - rect.top - rect.height / 2), z);
    } else {
      point = unproject(start.x - dx, start.y - dy, z);
    }
    el.dataset.lat = String(point.lat);
    el.dataset.lng = String(point.lng);
    el.dataset.set = "1";
    drag = null;
    paintMap(el);
    const err = el.closest(".point")?.querySelector(".point-error");
    if (err) err.hidden = true;
  }
  el.addEventListener("pointerup", end);
  el.addEventListener("pointercancel", () => { drag = null; world.style.transform = ""; });
}

function commitPoint(point) {
  const field = point.querySelector("[data-value]");
  const map = point.querySelector(".pinmap");
  const err = point.querySelector(".point-error");
  if (!field) return true;
  field.setCustomValidity("");
  if (!point.classList.contains("is-map")) {
    if (err) err.hidden = true;
    return true;
  }
  if (!map || map.dataset.set !== "1") {
    field.value = "";
    if (err) err.hidden = false;
    return false;
  }
  field.value = `${Number(map.dataset.lat).toFixed(5)}, ${Number(map.dataset.lng).toFixed(5)}`;
  if (err) err.hidden = true;
  return true;
}

function openTowStep(form, point) {
  point.classList.add("is-go");
  if (form.classList.contains("is-open")) return;
  form.classList.add("is-open");
  const rest = form.querySelector(".tow-rest");
  if (rest) rest.hidden = false;
}

function initTow(form) {
  const strings = extra.strings?.tow || {};
  const book = extra.strings?.book || {};
  const error = document.getElementById("tow-error");
  for (const point of form.querySelectorAll("[data-point]")) {
    point.addEventListener("pointerdown", () => openTowStep(form, point));
    point.addEventListener("focusin", () => openTowStep(form, point));
    const modeBtn = point.querySelector("[data-mode]");
    modeBtn?.addEventListener("click", () => {
      const mapMode = !point.classList.contains("is-map");
      point.classList.toggle("is-map", mapMode);
      const mapWrap = point.querySelector(".sq-map");
      if (mapWrap) mapWrap.hidden = !mapMode;
      const field = point.querySelector("[data-value]");
      modeBtn.textContent = mapMode ? (strings.byAddress || "Address") : (strings.byMap || "Map");
      if (mapMode) {
        field.dataset.draft = field.value;
        const map = point.querySelector(".pinmap");
        wirePinMap(map);
        requestAnimationFrame(() => paintMap(map));
      } else if (field.dataset.draft != null) {
        field.value = field.dataset.draft;
      }
    });
    const geo = point.querySelector("[data-geo]");
    geo?.addEventListener("click", () => {
      const map = point.querySelector(".pinmap");
      const err = point.querySelector(".point-error");
      if (!navigator.geolocation) {
        if (err) { err.hidden = false; err.textContent = strings.geoNo || ""; }
        return;
      }
      navigator.geolocation.getCurrentPosition((pos) => {
        map.dataset.lat = String(pos.coords.latitude);
        map.dataset.lng = String(pos.coords.longitude);
        map.dataset.set = "1";
        paintMap(map);
        if (err) err.hidden = true;
      }, () => {
        if (err) { err.hidden = false; err.textContent = strings.geoNo || ""; }
      });
    });
  }
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    error.textContent = "";
    let pointsOk = true;
    for (const point of form.querySelectorAll("[data-point]")) {
      if (!commitPoint(point)) pointsOk = false;
    }
    for (const field of form.querySelectorAll("input, textarea, select")) {
      if (field.closest(".sq.is-map")) continue;
      if (field.type === "radio" || field.type === "checkbox" || field.type === "file" || field.type === "date" || field.type === "time") continue;
      if (field.required && !String(field.value || "").trim()) {
        pointsOk = false;
        field.focus();
        break;
      }
    }
    if (!pointsOk) {
      error.textContent = book.invalid || "";
      return;
    }
    const data = new FormData(form);
    data.set("lang", lang);
    const button = form.querySelector("[type=submit]");
    button.disabled = true;
    try {
      const response = await fetch("/api/tow", { method: "POST", body: data });
      const body = await response.json();
      if (!response.ok) {
        error.textContent = book.invalid || body.error;
        button.disabled = false;
        return;
      }
      form.hidden = true;
      const done = document.getElementById("tow-done");
      const c = body.confirmation;
      done.hidden = false;
      done.innerHTML = `<div class="confirm-card"><h2>${escapeHtml(strings.sentTitle || "")}</h2><p>${escapeHtml(strings.sentBody || "")}</p><code>${escapeHtml(c.code)}</code><p><strong>${escapeHtml(c.pickup)}</strong><br>→ ${escapeHtml(c.delivery)}</p><p><a href="${escapeAttr(c.route)}">${escapeHtml(strings.route || "Route")}</a></p><p>${escapeHtml(strings.quote || "")}</p></div>`;
    } catch {
      error.textContent = book.invalid || "Error";
      button.disabled = false;
    }
  });
}


function readJson(id) {
  const node = document.getElementById(id);
  if (!node) return {};
  try { return JSON.parse(node.textContent || "{}"); } catch { return {}; }
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
function escapeAttr(value) {
  return escapeHtml(value);
}
