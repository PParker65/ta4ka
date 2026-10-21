import "./styles.css";

const boot = readJson("sf-boot");
const extra = readJson("sf-extra");
const lang = boot.lang || "ru";

const cookie = document.getElementById("cookie");
if (cookie) {
  const choice = localStorage.getItem("snelfix_cookie");
  if (!choice) cookie.hidden = false;
  cookie.addEventListener("click", (event) => {
    const value = event.target?.dataset?.cookie;
    if (!value) return;
    localStorage.setItem("snelfix_cookie", value);
    cookie.hidden = true;
    if (value === "yes") loadAnalytics();
  });
  if (choice === "yes") loadAnalytics();
}

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
  if (bare === "/boeken") return "book";
  if (bare === "/evacuatie") return "tow";
  if (bare === "/contact" || bare.startsWith("/vestigingen/") || bare === "/faq" || bare === "/voorwaarden" || bare === "/privacy" || bare === "/cookies") return "contacts";
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
  if (bare === "/cookies") return "cookies";
  return "";
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
    if (link.dataset.panel === "contacts") showSheet("");
    if (link.dataset.serviceBook) {
      const select = document.querySelector("#book-form select[name=service]");
      if (select) {
        select.value = link.dataset.serviceBook;
        select.dispatchEvent(new Event("change"));
      }
    }
    history.pushState({}, "", link.href);
  }
});

window.addEventListener("popstate", () => {
  const panel = panelFromPath(location.pathname);
  showPanel(panel);
  showService(panel === "services" ? serviceFromPath(location.pathname) : "");
  showSheet(panel === "contacts" ? sheetFromPath(location.pathname) : "");
});

const bookForm = document.getElementById("book-form");
if (bookForm) initBooking(bookForm);
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

function initBooking(form) {
  const strings = extra.strings?.book || {};
  const slots = document.getElementById("slots");
  const empty = document.getElementById("slots-empty");
  const error = document.getElementById("book-error");
  const date = form.querySelector("[name=date]");
  let selected = null;
  date.min = form.dataset.today || "";
  const max = new Date(`${form.dataset.today}T00:00:00`);
  max.setDate(max.getDate() + 90);
  date.max = max.toISOString().slice(0, 10);

  async function load() {
    selected = null;
    slots.innerHTML = "";
    const params = new URLSearchParams({
      garage: form.garage.value,
      service: form.service.value,
      date: form.date.value,
    });
    const response = await fetch(`/api/availability?${params}`);
    const data = await response.json();
    const list = data.slots || [];
    empty.hidden = list.length > 0;
    for (const slot of list) {
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = slot.label;
      button.setAttribute("aria-pressed", "false");
      button.addEventListener("click", () => {
        selected = slot.start;
        for (const node of slots.querySelectorAll("button")) node.setAttribute("aria-pressed", "false");
        button.setAttribute("aria-pressed", "true");
      });
      slots.appendChild(button);
    }
  }
  form.garage.forEach?.((node) => node.addEventListener("change", () => { if (!form.querySelector('[data-step="3"]').hidden) load(); }));
  form.querySelectorAll("[name=garage]").forEach((node) => node.addEventListener("change", () => {
    if (!form.querySelector('[data-step="3"]').hidden) load().catch(() => {});
  }));
  form.service.addEventListener("change", () => {
    if (!form.querySelector('[data-step="3"]').hidden) load().catch(() => {});
  });
  form.date.addEventListener("change", () => load().catch(() => {}));

  const live = document.getElementById("book-live");
  function paintLive() {
    if (!live) return;
    const opt = form.service.selectedOptions[0];
    const garage = form.querySelector("[name=garage]:checked");
    const where = garage ? garage.parentElement.textContent.trim() : "";
    live.innerHTML = `<span class="k">${escapeHtml(where)}</span><strong>${escapeHtml(opt ? opt.textContent : "")}</strong><span class="mono">${escapeHtml(opt?.dataset?.min || "")} · ${escapeHtml(opt?.dataset?.price || "")}</span>`;
  }
  form.service.addEventListener("change", paintLive);
  form.querySelectorAll("[name=garage]").forEach((node) => node.addEventListener("change", paintLive));
  paintLive();

  wireSteps(form, (index) => {
    if (index === 2) load().catch(() => { error.textContent = strings.invalid || "Error"; });
  });

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    error.textContent = "";
    if (selected == null) {
      error.textContent = strings.pickSlot || strings.required || "";
      form.querySelector('[data-step="4"]').hidden = true;
      form.querySelector('[data-step="3"]').hidden = false;
      return;
    }
    const data = new FormData(form);
    data.set("start", String(selected));
    data.set("lang", lang);
    const button = form.querySelector("[type=submit]");
    button.disabled = true;
    button.textContent = strings.sending || "…";
    try {
      const response = await fetch("/api/bookings", { method: "POST", body: data });
      const body = await response.json();
      if (!response.ok) {
        error.textContent = strings[camel(body.error)] || strings.invalid || body.error;
        button.disabled = false;
        button.textContent = form.dataset.label || strings.submit || "OK";
        return;
      }
      form.hidden = true;
      const done = document.getElementById("book-done");
      done.hidden = false;
      const c = body.confirmation;
      done.innerHTML = `<div class="confirm-card"><h2>${escapeHtml(strings.confirmTitle || "")}</h2><p>${escapeHtml(strings.confirmBody || "")}</p><p class="k">${escapeHtml(strings.code || "Code")}</p><code>${escapeHtml(c.code)}</code><p>${escapeHtml(c.service)} · ${escapeHtml(c.garage)}<br>${escapeHtml(c.date)} ${escapeHtml(c.time)}<br>${escapeHtml(c.vehicle)}</p></div>`;
    } catch {
      error.textContent = strings.invalid || "Error";
      button.disabled = false;
    }
  });
}

function initTow(form) {
  const strings = extra.strings?.tow || {};
  const book = extra.strings?.book || {};
  const error = document.getElementById("tow-error");
  wireSteps(form);
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    error.textContent = "";
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

function camel(error) {
  return ({ slot_taken: "slotTaken", closed: "closed", invalid: "invalid", past: "past" })[error] || "invalid";
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
