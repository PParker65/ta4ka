const NAMES = {
  moto250: "Мото 250",
  moto300: "Мото 300",
  quad250: "Квадро 250",
  quad500: "Квадро 500",
};

const state = { leads: [], filter: "all", settings: null };

const loginForm = document.querySelector("#login-form");
const app = document.querySelector("#app");
const logoutBtn = document.querySelector("#logout");

boot();

async function boot() {
  bindTabs();
  bindLogin();
  bindLeads();
  bindSettings();
  logoutBtn.addEventListener("click", logout);
  const session = await api("/panel/session");
  if (session.ok) enter();
}

function bindLogin() {
  loginForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(loginForm).entries());
    const result = await api("/panel/login", { method: "POST", body: data });
    const error = document.querySelector("#login-error");
    if (!result.ok) {
      error.textContent = result.status === 429 ? "Слишком много попыток. Подожди." : "Неверный логин или пароль.";
      return;
    }
    error.textContent = "";
    loginForm.reset();
    enter();
  });
}

async function enter() {
  loginForm.hidden = true;
  app.hidden = false;
  logoutBtn.hidden = false;
  await Promise.all([refreshLeads(), refreshStats(), refreshSettings()]);
}

async function logout() {
  await api("/panel/logout", { method: "POST", body: {} });
  app.hidden = true;
  logoutBtn.hidden = true;
  loginForm.hidden = false;
}

function bindTabs() {
  const tabs = [
    ["tab-leads", "panel-leads"],
    ["tab-stats", "panel-stats"],
    ["tab-contacts", "panel-contacts"],
  ];
  for (const [tabId, panelId] of tabs) {
    document.querySelector(`#${tabId}`).addEventListener("click", () => {
      for (const [id, pid] of tabs) {
        document.querySelector(`#${id}`).setAttribute("aria-selected", id === tabId ? "true" : "false");
        document.querySelector(`#${pid}`).hidden = id !== tabId;
      }
      if (tabId === "tab-stats") refreshStats();
      if (tabId === "tab-leads") refreshLeads();
    });
  }
  document.querySelectorAll("[data-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      state.filter = button.dataset.filter;
      document.querySelectorAll("[data-filter]").forEach((el) => {
        el.setAttribute("aria-pressed", el === button ? "true" : "false");
      });
      paintLeads();
    });
  });
}

function bindLeads() {
  document.querySelector("#leads").addEventListener("click", async (event) => {
    const button = event.target.closest("button");
    if (!button) return;
    const card = button.closest(".inbox-card");
    const id = card?.dataset.id;
    if (!id) return;
    if (button.dataset.action === "copy") {
      const phone = card.dataset.phone || "";
      try {
        await navigator.clipboard.writeText(phone);
      } catch {
        const input = document.createElement("input");
        input.value = phone;
        document.body.append(input);
        input.select();
        document.execCommand("copy");
        input.remove();
      }
      button.textContent = "Скопировано";
      setTimeout(() => {
        button.textContent = "Копировать";
      }, 1200);
      return;
    }
    if (button.dataset.action === "done" || button.dataset.action === "new") {
      const status = button.dataset.action === "done" ? "done" : "new";
      const result = await api(`/panel/leads/${id}`, { method: "PATCH", body: { status } });
      if (result.ok) await refreshLeads();
      return;
    }
    if (button.dataset.action === "delete") {
      if (!confirm("Удалить заявку?")) return;
      const result = await api(`/panel/leads/${id}`, { method: "DELETE" });
      if (result.ok) await refreshLeads();
    }
  });
}

function bindSettings() {
  document.querySelector("#panel-contacts").addEventListener("submit", async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const raw = Object.fromEntries(new FormData(form).entries());
    const body = {
      phone: raw.phone,
      instagram: raw.instagram,
      telegram: raw.telegram,
      prices: {
        moto250: Number(raw.moto250),
        moto300: Number(raw.moto300),
        quad250: Number(raw.quad250),
        quad500: Number(raw.quad500),
      },
    };
    const result = await api("/panel/settings", { method: "POST", body });
    const error = document.querySelector("#save-error");
    if (!result.ok) {
      error.textContent = "Проверь телефон, ссылки и цены (целое число от 50 до 2000).";
      return;
    }
    error.textContent = "Сохранено.";
    state.settings = result.data;
  });
}

async function refreshLeads() {
  const result = await api("/panel/leads");
  if (!result.ok) return;
  state.leads = result.data.leads || [];
  const fresh = state.leads.filter((lead) => lead.status !== "done").length;
  document.querySelector("#tab-leads").textContent = fresh ? `Заявки ${fresh}` : "Заявки";
  paintLeads();
}

function paintLeads() {
  const box = document.querySelector("#leads");
  const rows = state.leads.filter((lead) => state.filter === "all" || lead.status === state.filter);
  box.replaceChildren();
  if (!rows.length) {
    const empty = document.createElement("p");
    empty.className = "empty";
    empty.textContent = "Пока заявок нет.";
    box.append(empty);
    return;
  }
  for (const lead of rows) box.append(leadCard(lead));
}

function leadCard(lead) {
  const card = document.createElement("article");
  card.className = lead.status === "done" ? "inbox-card is-done" : "inbox-card";
  card.dataset.id = lead.id;
  card.dataset.phone = lead.phone;

  const top = document.createElement("div");
  top.className = "lead-top";
  const name = document.createElement("div");
  name.className = "lead-name";
  name.textContent = lead.name;
  const badge = document.createElement("div");
  badge.textContent = lead.status === "done" ? "Готово" : "Новая";
  top.append(name, badge);

  const phone = document.createElement("div");
  phone.className = "lead-phone";
  phone.textContent = lead.phone;

  const meta = document.createElement("div");
  meta.className = "lead-meta";
  meta.textContent = `${NAMES[lead.machine] || lead.machine} · ${showDate(lead.date)} · ${String(lead.hour).padStart(2, "0")}:00 · ${showWhen(lead.created)} · ${lead.lang || "uk"}`;

  card.append(top, phone, meta);
  if (lead.note) {
    const note = document.createElement("div");
    note.className = "lead-note";
    note.textContent = lead.note;
    card.append(note);
  }

  const actions = document.createElement("div");
  actions.className = "lead-actions";
  actions.append(
    actionButton("copy", "Копировать"),
    actionButton(lead.status === "done" ? "new" : "done", lead.status === "done" ? "Вернуть" : "Готово"),
    actionButton("delete", "Удалить"),
  );
  card.append(actions);
  return card;
}

function actionButton(action, label) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = action === "delete" ? "btn btn-ghost" : "btn btn-hot";
  button.dataset.action = action;
  button.textContent = label;
  return button;
}

async function refreshStats() {
  const result = await api("/panel/stats");
  if (!result.ok) return;
  const totals = result.data.totals || {};
  const cards = [
    ["Визиты", totals.total || 0],
    ["Уникальные", totals.unique || 0],
    ["Заявки", totals.leads || 0],
    ["Звонки", totals.call || 0],
    ["Instagram", totals.instagram || 0],
    ["Telegram", totals.telegram || 0],
  ];
  const box = document.querySelector("#stat-cards");
  box.replaceChildren();
  for (const [label, value] of cards) {
    const card = document.createElement("div");
    card.className = "stat";
    const strong = document.createElement("b");
    strong.textContent = String(value);
    const span = document.createElement("span");
    span.textContent = label;
    card.append(strong, span);
    box.append(card);
  }
  const chart = document.querySelector("#chart");
  chart.replaceChildren();
  const days = result.data.days || [];
  const max = Math.max(1, ...days.map((day) => day.total || 0));
  for (const day of days) {
    const col = document.createElement("div");
    col.className = "bar-col";
    const fill = document.createElement("div");
    fill.className = "bar-fill";
    const hits = day.total || 0;
    fill.style.height = hits ? `${Math.max(8, Math.round((hits / max) * 100))}%` : "0";
    const label = document.createElement("span");
    label.textContent = day.day.slice(8);
    col.append(fill, label);
    chart.append(col);
  }
}

async function refreshSettings() {
  const result = await api("/panel/settings");
  if (!result.ok) return;
  state.settings = result.data;
  const form = document.querySelector("#panel-contacts");
  form.phone.value = result.data.phone || "";
  form.instagram.value = result.data.instagram || "";
  form.telegram.value = result.data.telegram || "";
  for (const id of Object.keys(NAMES)) form[id].value = result.data.prices?.[id] ?? "";
}

async function api(path, { method = "GET", body } = {}) {
  const opts = { method };
  if (body !== undefined) {
    opts.headers = { "content-type": "application/json" };
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(path, opts);
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && path !== "/panel/login" && path !== "/panel/session") {
    app.hidden = true;
    logoutBtn.hidden = true;
    loginForm.hidden = false;
  }
  return { ok: res.ok && data.ok !== false, status: res.status, data };
}

function showDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || "")) return value || "";
  return `${value.slice(8)}.${value.slice(5, 7)}.${value.slice(0, 4)}`;
}

function showWhen(iso) {
  const time = Date.parse(iso);
  if (!time) return "";
  return new Intl.DateTimeFormat("ru-RU", {
    timeZone: "Europe/Warsaw",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(time);
}
