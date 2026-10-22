const pack = readJson("sf-admin");
const copy = pack.admin || pack;
const hours = pack.hours || [];
const closedLabel = pack.hoursClosed || "closed";

const login = document.getElementById("login-form");
if (login) {
  login.addEventListener("submit", async (event) => {
    event.preventDefault();
    const error = document.getElementById("login-error");
    error.textContent = "";
    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ username: login.username.value, password: login.password.value }),
    });
    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      error.textContent = body.error === "limited" ? copy.limited : copy.bad;
      return;
    }
    location.reload();
  });
}

const root = document.getElementById("admin-root");
if (root) {
  const section = document.getElementById("section");
  document.getElementById("logout").addEventListener("click", async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    location.reload();
  });
  section.addEventListener("change", () => show(section.value));
  show(section.value || "leads");
}

async function show(name) {
  const error = document.getElementById("admin-error");
  error.textContent = "";
  root.innerHTML = "";
  try {
    if (name === "leads") await renderLeads();
    else if (name === "stats") await renderStats();
    else if (name === "bookings") await renderBookings();
    else if (name === "tows") await renderTows();
    else if (name === "services") await renderServices();
    else if (name === "garages") await renderGarages();
    else if (name === "customers") await renderCustomers();
    else if (name === "news") await renderNews();
    else await renderPassword();
  } catch (err) {
    error.textContent = err.message || "Error";
  }
}

async function api(url, options) {
  const response = await fetch(url, options);
  const body = await response.json().catch(() => ({}));
  if (response.status === 401) location.reload();
  if (!response.ok) throw new Error(body.error || response.statusText);
  return body;
}

async function renderBookings() {
  const search = el("input", { placeholder: copy.search });
  root.append(search);
  const list = el("div");
  root.append(list);
  const load = async () => {
    const data = await api(`/api/admin/bookings?q=${encodeURIComponent(search.value)}`);
    list.innerHTML = "";
    if (!data.bookings.length) list.append(el("p", { text: copy.empty }));
    for (const booking of data.bookings) list.append(bookingCard(booking, load));
  };
  search.addEventListener("input", load);
  await load();
}

function bookingCard(booking, reload) {
  const card = el("article", { className: "card" });
  card.innerHTML = `<div class="badge">${esc(copy.status[booking.status] || booking.status)}</div>
    <h3>${esc(booking.code)}</h3>
    <p>${esc(booking.service_title || booking.service_id)} · ${esc(booking.garage_city)}<br>
    ${esc(booking.date)} ${esc(label(booking.start_min))}–${esc(label(booking.end_min))}</p>
    <p>${esc(booking.customer_name)} · ${esc(booking.phone)}<br>${esc(booking.email || "")}</p>
    <p>${esc(booking.make)} ${esc(booking.model)} ${esc(booking.year || "")} · ${esc(booking.plate)}</p>
    <p>${esc(copy.booking.problem)}: ${esc(booking.problem || "")}</p>`;
  if (booking.photo_ids) {
    const photos = el("div", { className: "actions" });
    for (const id of String(booking.photo_ids).split(",")) {
      const img = el("img", { src: `/media/u/${id}`, alt: "" });
      img.style.width = "96px";
      img.style.height = "72px";
      img.style.objectFit = "cover";
      photos.append(img);
    }
    card.append(photos);
  }
  const actions = el("div", { className: "actions" });
  if (booking.status === "requested") actions.append(button(copy.confirm, () => post(`/api/admin/bookings/${booking.id}/confirm`).then(reload)));
  if (booking.status === "requested" || booking.status === "confirmed") {
    actions.append(button(copy.progress, () => post(`/api/admin/bookings/${booking.id}/progress`).then(reload)));
  }
  if (booking.status !== "cancelled") actions.append(button(copy.cancel, () => post(`/api/admin/bookings/${booking.id}/cancel`).then(reload)));
  if (booking.status !== "completed" && booking.status !== "cancelled") actions.append(button(copy.done, () => post(`/api/admin/bookings/${booking.id}/done`).then(reload)));
  const move = button(copy.reschedule, () => openMove(card, booking, reload));
  actions.append(move);
  card.append(actions);
  const fix = el("textarea", { rows: "2" });
  fix.value = booking.problem || "";
  card.append(field(copy.booking.problem, fix), button(copy.correct, async () => {
    await post(`/api/admin/bookings/${booking.id}/correct`, { problem: fix.value });
    reload();
  }));
  const note = el("div", { className: "two" });
  const next = el("input", { type: "date", value: booking.next_service_on || "" });
  const text = el("input", { value: booking.next_service_note || "", placeholder: copy.booking.note });
  note.append(field(copy.booking.next, next), field(copy.booking.note, text));
  const saveNote = button(copy.save, async () => {
    await post(`/api/admin/bookings/${booking.id}/note`, { next_service_on: next.value, next_service_note: text.value });
    reload();
  });
  card.append(note, saveNote);
  return card;
}

function openMove(card, booking, reload) {
  const box = el("div");
  const date = el("input", { type: "date", value: booking.date });
  const slots = el("div", { className: "slots" });
  let start = null;
  const load = async () => {
    slots.innerHTML = "";
    start = null;
    const data = await api(`/api/availability?garage=${booking.garage_id}&service=${booking.service_id}&date=${date.value}&ignore=${booking.id}`);
    for (const slot of data.slots || []) {
      const b = button(slot.label, () => {
        start = slot.start;
        for (const node of slots.querySelectorAll("button")) node.setAttribute("aria-pressed", "false");
        b.setAttribute("aria-pressed", "true");
      });
      slots.append(b);
    }
  };
  date.addEventListener("change", load);
  box.append(date, slots, button(copy.save, async () => {
    if (start == null) return;
    await post(`/api/admin/bookings/${booking.id}/reschedule`, { date: date.value, start });
    reload();
  }));
  card.append(box);
  load();
}

async function renderLeads() {
  const data = await api("/api/admin/leads");
  if (!data.leads.length) {
    root.append(el("p", { text: copy.empty }));
    return;
  }
  for (const lead of data.leads) {
    const card = el("article", { className: "card" });
    card.innerHTML = `<span class="badge">${esc(copy.status[lead.status] || lead.status)}</span>
      <h3>${esc(lead.code)}</h3>
      <p><strong>${esc(lead.service_title || lead.service_id)}</strong></p>
      <p>${esc(lead.contact_name)} · ${esc(lead.contact_phone)}</p>
      <p>${esc(lead.note || "")}</p>
      <p class="hint">${esc(String(lead.created_at || "").replace("T", " ").slice(0, 16))}</p>`;
    const actions = el("div", { className: "actions" });
    actions.append(
      button(copy.status.new, () => post(`/api/admin/leads/${lead.id}/new`).then(() => show("leads"))),
      button(copy.done, () => post(`/api/admin/leads/${lead.id}/done`).then(() => show("leads"))),
      button(copy.status.closed, () => post(`/api/admin/leads/${lead.id}/closed`).then(() => show("leads")))
    );
    card.append(actions);
    root.append(card);
  }
}

async function renderStats() {
  const data = await api("/api/admin/stats");
  const grid = el("div", { className: "stat-grid" });
  grid.append(statNum(copy.stats.uniques, data.uniques), statNum(copy.stats.views, data.views));
  root.append(grid);
  root.append(el("h3", { text: copy.stats.days }));
  const maxDay = Math.max(1, ...(data.days || []).map((day) => Number(day.uniques) || 0));
  for (const day of data.days || []) {
    root.append(statRow(String(day.day).slice(5), Number(day.uniques) || 0, maxDay));
  }
  root.append(el("h3", { text: copy.stats.country }));
  if (!(data.countries || []).length) root.append(el("p", { text: copy.stats.none }));
  const maxCountry = Math.max(1, ...(data.countries || []).map((row) => Number(row.uniques) || 0));
  for (const row of data.countries || []) {
    const label = [row.country || "—", row.city].filter(Boolean).join(" · ");
    root.append(statRow(label, Number(row.uniques) || 0, maxCountry));
  }
  root.append(el("h3", { text: copy.stats.panels }));
  const maxPanel = Math.max(1, ...(data.panels || []).map((row) => Number(row.views) || 0));
  for (const row of data.panels || []) {
    const label = (copy.panel && copy.panel[row.panel]) || row.panel || "—";
    root.append(statRow(label, Number(row.views) || 0, maxPanel));
  }
}

function statNum(label, value) {
  const node = el("div", { className: "stat-num" });
  node.innerHTML = `<b>${esc(value ?? 0)}</b><span>${esc(label)}</span>`;
  return node;
}

function statRow(label, value, max) {
  const node = el("div", { className: "stat-row" });
  const width = Math.max(0, Math.round((Number(value) / max) * 100));
  node.innerHTML = `<b>${esc(label)}</b><i style="width:${width}%"></i><span>${esc(value)}</span>`;
  return node;
}

async function renderTows() {
  const data = await api("/api/admin/tows");
  if (!data.tows.length) root.append(el("p", { text: copy.empty }));
  for (const tow of data.tows) {
    const card = el("article", { className: `card${tow.urgent ? " urgent" : ""}` });
    card.innerHTML = `${tow.urgent ? `<span class="badge hot">${esc(copy.tow.urgent)}</span>` : ""} <span class="badge">${esc(copy.status[tow.status] || tow.status)}</span>
      <h3>${esc(tow.code)}</h3>
      <p><strong>${esc(tow.pickup)}</strong><br>→ ${esc(tow.delivery)}</p>
      <p>${esc(tow.make)} ${esc(tow.model)} · ${tow.running ? esc(copy.tow.running) : esc(copy.tow.notRunning)}</p>
      <p>${esc(tow.contact_name)} · ${esc(tow.contact_phone)}<br>${esc(tow.desired_date || "")} ${esc(tow.desired_time || "")}</p>
      <p>${esc(tow.notes || "")}</p>`;
    const actions = el("div", { className: "actions" });
    actions.append(
      button(copy.confirm, () => post(`/api/admin/tows/${tow.id}/confirm`).then(() => show("tows"))),
      button(copy.done, () => post(`/api/admin/tows/${tow.id}/done`).then(() => show("tows"))),
      button(copy.cancel, () => post(`/api/admin/tows/${tow.id}/cancel`).then(() => show("tows")))
    );
    card.append(actions);
    if (tow.photo_ids) {
      for (const id of String(tow.photo_ids).split(",")) {
        const img = el("img", { src: `/media/u/${id}`, alt: "" });
        img.style.width = "120px";
        card.append(img);
      }
    }
    root.append(card);
  }
}

async function renderServices() {
  const data = await api("/api/admin/services?lang=nl");
  for (const service of data.services) root.append(serviceEditor(service));
}

function serviceEditor(service) {
  const card = el("article", { className: "card" });
  const price = service.price_cents == null ? "" : String(service.price_cents / 100);
  const euros = el("input", { value: price, inputMode: "decimal" });
  const duration = el("input", { type: "number", value: service.duration_min, min: "15" });
  const image = el("input", { value: service.image || "" });
  const active = el("input", { type: "checkbox" });
  active.checked = !!service.active;
  const bookable = el("input", { type: "checkbox" });
  bookable.checked = !!service.bookable;
  const lang = el("select");
  for (const code of ["nl", "en", "ru", "uk"]) lang.append(new Option(code.toUpperCase(), code));
  const title = el("input");
  const summary = el("textarea", { rows: "2" });
  const body = el("textarea", { rows: "6" });
  const fill = () => {
    const row = service.i18n?.[lang.value] || {};
    title.value = row.title || "";
    summary.value = row.summary || "";
    body.value = row.body || "";
  };
  lang.addEventListener("change", () => {
    service.i18n[lang.value] = service.i18n[lang.value] || {};
    fill();
  });
  const remember = () => {
    service.i18n[lang.value] = { title: title.value, summary: summary.value, body: body.value };
  };
  title.addEventListener("change", remember);
  summary.addEventListener("change", remember);
  body.addEventListener("change", remember);
  fill();
  card.append(
    el("h3", { text: service.id }),
    field(copy.service.price, euros),
    field(copy.service.duration, duration),
    field(copy.service.image, image),
    check(copy.service.active, active),
    check(copy.service.bookable, bookable),
    field(copy.lang, lang),
    field(copy.service.title, title),
    field(copy.service.summary, summary),
    field(copy.service.body, body),
    button(copy.save, async () => {
      remember();
      const cents = euros.value.trim() === "" ? null : Math.round(Number(euros.value.replace(",", ".")) * 100);
      await post(`/api/admin/services/${service.id}`, {
        duration_min: Number(duration.value),
        price_cents: cents,
        active: active.checked,
        bookable: bookable.checked,
        image: image.value,
        i18n: service.i18n,
      });
      card.append(el("p", { text: copy.saved }));
    })
  );
  return card;
}

async function renderGarages() {
  const data = await api("/api/admin/garages");
  const contact = el("article", { className: "card" });
  const phone = el("input", { value: data.settings.phone_display || "" });
  const wa = el("input", { value: data.settings.whatsapp_url || "" });
  const ig = el("input", { value: data.settings.instagram_url || "" });
  const tg = el("input", { value: data.settings.telegram_url || "" });
  contact.append(
    el("h3", { text: copy.brand.title }),
    field(copy.brand.phone, phone),
    field(copy.brand.whatsapp, wa),
    field(copy.brand.instagram, ig),
    field(copy.brand.telegram, tg),
    button(copy.save, async () => {
      await post("/api/admin/contact", {
        phone_display: phone.value,
        whatsapp_url: wa.value,
        instagram_url: ig.value,
        telegram_url: tg.value,
      }, "PUT");
      contact.append(el("p", { text: copy.saved }));
    })
  );
  root.append(contact);
  for (const garage of data.garages) root.append(garageEditor(garage, data));
}

function garageEditor(garage, data) {
  const card = el("article", { className: "card" });
  card.append(el("h3", { text: garage.city }));
  const rows = [];
  for (let day = 0; day < 7; day++) {
    const current = (data.hours[garage.id] || []).find((row) => row.weekday === day) || {};
    const closed = el("input", { type: "checkbox" });
    closed.checked = current.open_min == null;
    const open = el("select");
    const close = el("select");
    for (let m = 0; m < 24 * 60; m += 30) {
      const text = label(m);
      open.append(new Option(text, text));
      close.append(new Option(text, text));
    }
    if (current.open_min != null) open.value = label(current.open_min);
    if (current.close_min != null) close.value = label(current.close_min);
    const line = el("div", { className: "two" });
    line.append(el("strong", { text: hours[day] || String(day) }), check(copy.garage.closed, closed), open, close);
    card.append(line);
    rows.push({ day, closed, open, close });
  }
  card.append(button(copy.save, async () => {
    await post(`/api/admin/garages/${garage.id}/hours`, {
      hours: rows.map((row) => ({ weekday: row.day, closed: row.closed.checked, open: row.open.value, close: row.close.value })),
    }, "PUT");
    card.append(el("p", { text: copy.saved }));
  }));
  const lang = el("select");
  for (const code of ["nl", "en", "ru", "uk"]) lang.append(new Option(code.toUpperCase(), code));
  const note = el("textarea", { rows: "3" });
  const notes = { ...(data.notes[garage.id] || {}) };
  const fill = () => { note.value = notes[lang.value] || ""; };
  lang.addEventListener("change", () => { notes[lang.value] = note.value; fill(); });
  note.addEventListener("change", () => { notes[lang.value] = note.value; });
  fill();
  card.append(field(copy.lang, lang), field(copy.garage.note, note), button(copy.save, async () => {
    notes[lang.value] = note.value;
    await post(`/api/admin/garages/${garage.id}/note`, { notes }, "PUT");
    card.append(el("p", { text: copy.saved }));
  }));
  const kind = el("select");
  kind.append(new Option(copy.garage.full, "closed"), new Option(copy.garage.special, "hours"), new Option(copy.garage.block, "block"));
  const date = el("input", { type: "date" });
  const start = el("input", { type: "time", value: "12:00" });
  const end = el("input", { type: "time", value: "14:00" });
  card.append(el("h3", { text: copy.garage.addException }), field(copy.garage.kind, kind), field(copy.garage.date, date), field(copy.garage.open, start), field(copy.garage.close, end));
  card.append(button(copy.garage.addException, async () => {
    await post("/api/admin/exceptions", { garage_id: garage.id, kind: kind.value, date: date.value, start: start.value, end: end.value });
    show("garages");
  }));
  for (const item of data.exceptions.filter((row) => row.garage_id === garage.id)) {
    const line = el("p", { text: `${item.date} · ${item.kind} ${item.start_min != null ? label(item.start_min) + "–" + label(item.end_min) : ""}` });
    const del = button(copy.delete, async () => {
      await fetch(`/api/admin/exceptions/${item.id}`, { method: "DELETE" });
      show("garages");
    });
    card.append(line, del);
  }
  return card;
}

async function renderCustomers() {
  const search = el("input", { placeholder: copy.search });
  const list = el("div");
  root.append(search, list);
  const load = async () => {
    const data = await api(`/api/admin/customers?q=${encodeURIComponent(search.value)}`);
    list.innerHTML = "";
    if (!data.customers.length) list.append(el("p", { text: copy.empty }));
    for (const customer of data.customers) {
      const card = el("article", { className: "card" });
      card.innerHTML = `<h3>${esc(customer.name)}</h3><p>${esc(customer.phone)} · ${esc(customer.email || "")}</p><p>${esc(copy.customer.vehicles)}: ${customer.vehicles} · ${esc(copy.customer.history)}: ${customer.bookings}</p>`;
      card.append(button(copy.customer.history, async () => {
        const detail = await api(`/api/admin/customers/${customer.id}`);
        const box = el("div");
        box.innerHTML = detail.vehicles.map((v) => `<p>${esc(v.make)} ${esc(v.model)} ${esc(v.year || "")} ${esc(v.plate)}</p>`).join("")
          + detail.bookings.map((b) => `<p>${esc(b.date)} ${esc(b.service_title || "")} · ${esc(b.status)} · ${esc(b.code)}</p>`).join("")
          + detail.tows.map((t) => `<p>${esc(t.code)} ${t.urgent ? "SPOED" : ""} ${esc(t.pickup)} → ${esc(t.delivery)}</p>`).join("");
        card.append(box);
      }));
      list.append(card);
    }
  };
  search.addEventListener("input", load);
  await load();
}

async function renderNews() {
  const data = await api("/api/admin/posts?lang=nl");
  for (const post of data.posts) {
    const card = el("article", { className: "card" });
    card.innerHTML = `<span class="badge">${esc(post.kind)}</span><h3>${esc(post.title || post.image)}</h3><p>${esc(post.body || "")}</p>`;
    if (post.image) {
      const img = el("img", { src: post.image, alt: "" });
      img.style.maxWidth = "220px";
      card.append(img);
    }
    card.append(button(copy.delete, async () => {
      await fetch(`/api/admin/posts/${post.id}`, { method: "DELETE" });
      show("news");
    }));
    root.append(card);
  }
  const form = el("form", { className: "card form" });
  form.innerHTML = `<h3>${esc(copy.news.add)}</h3>`;
  const kind = el("select");
  kind.append(new Option(copy.news.photo, "photo"), new Option(copy.news.news, "news"));
  const image = el("input", { placeholder: "/photos/workshop.jpg" });
  const file = el("input", { type: "file", accept: "image/jpeg,image/png,image/webp" });
  form.append(field(copy.garage.kind, kind), field(copy.news.image, image), file);
  for (const code of ["nl", "en", "ru", "uk"]) {
    form.append(field(`${code} ${copy.service.title}`, el("input", { name: `title_${code}` })));
    form.append(field(`${code} ${copy.service.body}`, el("textarea", { name: `body_${code}`, rows: "3" })));
  }
  form.append(button(copy.news.add, async () => {
    const body = new FormData(form);
    body.set("kind", kind.value);
    body.set("image", image.value);
    if (file.files[0]) body.set("file", file.files[0]);
    await fetch("/api/admin/posts", { method: "POST", body });
    show("news");
  }));
  root.append(form);
}

function renderPassword() {
  const form = el("form", { className: "card form" });
  const current = el("input", { type: "password", autocomplete: "current-password" });
  const next = el("input", { type: "password", autocomplete: "new-password" });
  const confirm = el("input", { type: "password", autocomplete: "new-password" });
  const error = el("p", { className: "form-error" });
  form.append(
    field(copy.pass.current, current),
    field(copy.pass.next, next),
    field(copy.pass.confirm, confirm),
    error,
    button(copy.pass.save, async () => {
      error.textContent = "";
      const response = await fetch("/api/admin/password", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ current: current.value, next: next.value, confirm: confirm.value }),
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        error.textContent = { bad: copy.pass.bad, short: copy.pass.short, mismatch: copy.pass.mismatch }[body.error] || body.error;
        return;
      }
      form.innerHTML = `<p>${esc(copy.pass.ok)}</p>`;
      setTimeout(() => location.reload(), 900);
    })
  );
  root.append(form);
}

function field(label, input) {
  const wrap = el("label");
  wrap.append(document.createTextNode(label), input);
  return wrap;
}
function check(label, input) {
  const wrap = el("label", { className: "check" });
  wrap.append(input, document.createTextNode(label));
  return wrap;
}
function button(text, onClick) {
  const node = el("button", { className: "btn btn-amber", type: "button", text });
  node.addEventListener("click", onClick);
  return node;
}
function post(url, body, method = "POST") {
  return api(url, {
    method,
    headers: body ? { "content-type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });
}
function label(mins) {
  const m = Number(mins) || 0;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}
function el(tag, attrs = {}) {
  const node = document.createElement(tag);
  if (attrs.className) node.className = attrs.className;
  if (attrs.text) node.textContent = attrs.text;
  if (attrs.type) node.type = attrs.type;
  if (attrs.placeholder) node.placeholder = attrs.placeholder;
  if (attrs.value != null) node.value = attrs.value;
  if (attrs.name) node.name = attrs.name;
  if (attrs.rows) node.rows = attrs.rows;
  if (attrs.min) node.min = attrs.min;
  if (attrs.accept) node.accept = attrs.accept;
  if (attrs.autocomplete) node.autocomplete = attrs.autocomplete;
  if (attrs.inputMode) node.inputMode = attrs.inputMode;
  if (attrs.src) node.src = attrs.src;
  if (attrs.alt != null) node.alt = attrs.alt;
  return node;
}
function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
function readJson(id) {
  try { return JSON.parse(document.getElementById(id)?.textContent || "{}"); } catch { return {}; }
}
