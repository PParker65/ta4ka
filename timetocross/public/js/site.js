import { STR } from "./i18n.js?v=20261031b";

const LANGS = ["uk", "pl", "ru"];
const ERR = {
  name: "errName",
  phone: "errPhone",
  machine: "errMachine",
  date: "errDate",
  hour: "errHour",
  note: "errNet",
  rate: "errRate",
  origin: "errNet",
  server: "errNet",
};

const state = {
  lang: "uk",
  error: "",
  config: readDomConfig(),
};

const form = document.querySelector("#lead-form");
const fields = document.querySelector("#fields");
const success = document.querySelector("#success");
const errorBox = document.querySelector("#form-error");
const sendBtn = document.querySelector("#send");

boot();

function boot() {
  const saved = localStorage.getItem("ttc_lang");
  state.lang = LANGS.includes(saved) ? saved : "uk";
  applyI18n();
  bindLang();
  bindMachines();
  bindForm();
  bindTyping();
  tick();
  setInterval(tick, 30000);
  setDateBounds();
  const params = new URLSearchParams(location.search);
  if (params.get("sent") === "1") showSuccess();
  loadPublic();
  fetch("/panel/hit", { method: "POST" }).catch(() => {});
}

function readDomConfig() {
  const prices = {};
  document.querySelectorAll("[data-price]").forEach((el) => {
    prices[el.dataset.price] = Number(el.textContent) || 0;
  });
  const telegram = document.querySelector("[data-telegram]");
  return {
    phone: (document.querySelector("[data-phone]")?.getAttribute("href") || "").replace(/^tel:/, ""),
    instagram: document.querySelector("[data-instagram]")?.getAttribute("href") || "",
    telegram: telegram && !telegram.hidden ? telegram.getAttribute("href") || "" : "",
    prices,
  };
}

async function loadPublic() {
  try {
    const res = await fetch("/panel/public");
    const data = await res.json();
    if (!data.ok) return;
    state.config = {
      phone: data.phone,
      instagram: data.instagram,
      telegram: data.telegram || "",
      prices: data.prices,
    };
    paintConfig();
  } catch {
    paintConfig();
  }
}

function paintConfig() {
  const phone = state.config.phone;
  document.querySelectorAll("[data-phone]").forEach((el) => {
    el.href = `tel:${phone}`;
    if (el.classList.contains("show-phone")) el.textContent = prettyPhone(phone);
  });
  const ig = document.querySelector("[data-instagram]");
  if (ig && state.config.instagram) {
    ig.href = state.config.instagram;
    const handle = state.config.instagram.split("/").filter(Boolean).pop();
    ig.textContent = handle ? `Instagram · @${handle}` : "Instagram";
  }
  const tg = document.querySelector("[data-telegram]");
  if (tg) {
    if (state.config.telegram) {
      tg.hidden = false;
      tg.href = state.config.telegram;
      const path = state.config.telegram.split("t.me/")[1] || "";
      tg.textContent = path.startsWith("+") || !path ? "Telegram" : `Telegram · @${path.replace(/\/$/, "")}`;
    } else {
      tg.hidden = true;
    }
  }
  for (const [id, price] of Object.entries(state.config.prices || {})) {
    const node = document.querySelector(`[data-price="${id}"]`);
    if (node) node.textContent = String(price);
  }
  const values = Object.values(state.config.prices || {}).filter((n) => n > 0);
  if (values.length) {
    const min = Math.min(...values);
    const max = Math.max(...values);
    document.querySelector("#price-range").textContent = min === max ? `${min} zł` : `${min}–${max} zł`;
  }
  paintPicked();
}

function bindLang() {
  document.querySelectorAll("[data-lang]").forEach((button) => {
    button.addEventListener("click", () => {
      state.lang = button.dataset.lang;
      localStorage.setItem("ttc_lang", state.lang);
      applyI18n();
    });
  });
}

function applyI18n() {
  const pack = STR[state.lang] || STR.uk;
  document.documentElement.lang = state.lang;
  document.title = pack.pageTitle;
  const desc = document.querySelector("#meta-desc");
  if (desc) desc.setAttribute("content", pack.metaDescription);
  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const value = pack[el.dataset.i18n];
    if (value != null) el.textContent = value;
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
    const value = pack[el.dataset.i18nPlaceholder];
    if (value != null) el.setAttribute("placeholder", value);
  });
  document.querySelectorAll("[data-lang]").forEach((button) => {
    button.setAttribute("aria-pressed", button.dataset.lang === state.lang ? "true" : "false");
  });
  const dial = document.querySelector("#dial");
  if (dial) dial.setAttribute("aria-label", pack.dialLabel);
  const clock = document.querySelector("#clock");
  if (clock) clock.setAttribute("aria-label", pack.clockLabel);
  const langField = document.querySelector("#lang-field");
  if (langField) langField.value = state.lang;
  paintPicked();
  if (state.error) showError(state.error);
}

function t(key) {
  return (STR[state.lang] || STR.uk)[key] || "";
}

function bindMachines() {
  document.querySelectorAll('input[name="machine"]').forEach((input) => {
    input.addEventListener("change", () => {
      paintPicked();
      if (window.matchMedia("(max-width: 899px)").matches) {
        document.querySelector("#lead-form")?.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  });
}

function paintPicked() {
  const picked = document.querySelector("#picked");
  if (!picked) return;
  const input = document.querySelector('input[name="machine"]:checked');
  if (!input) {
    picked.textContent = t("pickFirst");
    return;
  }
  const plate = input.closest(".plate");
  const kind = plate?.dataset.kind === "quad" ? t("kindQuad") : t("kindMoto");
  const price = state.config.prices[plate.dataset.id];
  picked.textContent = `${kind} ${plate.dataset.cc} · ${price} zł`;
}

function bindForm() {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(form).entries());
    const machine = document.querySelector('input[name="machine"]:checked');
    if (machine) data.machine = machine.value;
    data.lang = state.lang;
    const problem = clientProblem(data);
    if (problem) {
      showError(problem);
      if (problem === "machine") document.querySelector("#fleet")?.scrollIntoView({ behavior: "smooth", block: "start" });
      return;
    }
    sendBtn.disabled = true;
    sendBtn.textContent = t("sending");
    try {
      const res = await fetch("/panel/leads", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(data),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok || !body.ok) {
        showError(body.error || "server");
        return;
      }
      showSuccess();
    } catch {
      showError("server");
    } finally {
      sendBtn.disabled = false;
      sendBtn.textContent = t("send");
    }
  });

  document.querySelector("#again")?.addEventListener("click", () => {
    form.reset();
    document.querySelector("#lang-field").value = state.lang;
    setDateBounds();
    success.hidden = true;
    fields.hidden = false;
    state.error = "";
    errorBox.textContent = "";
    paintPicked();
    document.querySelector("#fleet")?.scrollIntoView({ behavior: "smooth", block: "start" });
  });

  document.querySelectorAll("[data-track]").forEach((el) => {
    el.addEventListener("click", () => {
      const kind = el.dataset.track;
      fetch("/panel/click", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ kind }),
        keepalive: true,
      }).catch(() => {});
    });
  });
}

function clientProblem(data) {
  if (!data.machine) return "machine";
  if (!data.name || data.name.trim().length < 2) return "name";
  if (!data.phone || data.phone.replace(/\D/g, "").length < 8) return "phone";
  if (!data.date) return "date";
  if (!data.hour) return "hour";
  return "";
}

function showError(code) {
  state.error = code;
  const key = ERR[code] || "errNet";
  errorBox.textContent = t(key);
  if (fields.hidden) return;
  errorBox.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function showSuccess() {
  state.error = "";
  errorBox.textContent = "";
  fields.hidden = true;
  success.hidden = false;
  document.querySelector("#lead-form")?.scrollIntoView({ behavior: "smooth", block: "start" });
}

function setDateBounds() {
  const input = form.querySelector('input[name="date"]');
  if (!input) return;
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Warsaw",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  input.min = fmt.format(new Date());
  input.max = fmt.format(new Date(Date.now() + 120 * 86400000));
}

function bindTyping() {
  document.querySelectorAll("input, select, textarea").forEach((el) => {
    el.addEventListener("focus", () => document.body.classList.add("is-typing"));
    el.addEventListener("blur", () => document.body.classList.remove("is-typing"));
  });
}

function tick() {
  const clock = document.querySelector("#clock");
  if (!clock) return;
  const text = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Warsaw",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(new Date());
  clock.textContent = text;
  clock.dateTime = text;
}

function prettyPhone(phone) {
  if (phone.startsWith("+48") && phone.length === 12) {
    return `+48 ${phone.slice(3, 6)} ${phone.slice(6, 9)} ${phone.slice(9)}`;
  }
  if (phone.startsWith("+380") && phone.length === 13) {
    return `+380 ${phone.slice(4, 6)} ${phone.slice(6, 9)} ${phone.slice(9, 11)} ${phone.slice(11)}`;
  }
  return phone;
}
