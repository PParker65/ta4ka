import { siteConfig } from "./site.config.js";
import {
  availability,
  createBooking,
  createTow,
  customerDetail,
  dayWindow,
  garageNotes,
  getSettings,
  listBookings,
  listCustomers,
  listGarages,
  listPosts,
  listServices,
  listTows,
  rescheduleBooking,
  saveUpload,
  serviceById,
  serviceI18n,
  setSetting,
  upcomingExceptions,
  allHours,
} from "./db.js";
import { notifyClient, notifyOwner, runReminders } from "./notify.js";
import {
  adminAppPage,
  adminLoginPage,
  bookPage,
  contactPage,
  faqPage,
  homePage,
  legalPage,
  locationPage,
  notFoundPage,
  servicePage,
  servicesPage,
  towPage,
} from "./pages.js";
import { ensureSeed } from "./seed.js";
import { t } from "./i18n.js";
import {
  base64ToBytes,
  bytesToBase64,
  cleanPlate,
  clientIp,
  code,
  cookieValue,
  e164,
  html,
  isIsoDate,
  json,
  minLabel,
  parseLangPath,
  parseMinutes,
  randomHex,
  rateLimit,
  sessionCookie,
  sha256Hex,
  text,
  verifyPassword,
  hashPassword,
  amsterdamNow,
} from "./util.js";

const ASSET = /\.(css|js|mjs|map|svg|png|jpe?g|webp|gif|ico|woff2?|txt|xml|webmanifest)$/i;

function brandFrom(settings) {
  return {
    phoneDisplay: settings.phone_display || siteConfig.phoneDisplay,
    phoneTel: settings.phone_tel || siteConfig.phoneTel,
    whatsapp: settings.whatsapp_url || siteConfig.whatsapp,
    instagram: settings.instagram_url || siteConfig.instagram,
    telegram: settings.telegram_url || siteConfig.telegram,
    instagramHandle: settings.instagram_handle || siteConfig.instagramHandle,
    telegramHandle: settings.telegram_handle || siteConfig.telegramHandle,
  };
}

function originOf(request, env) {
  const configured = env.SITE_ORIGIN || siteConfig.origin;
  const url = new URL(request.url);
  if (url.hostname === "localhost" || url.hostname === "127.0.0.1") return url.origin;
  return String(configured).replace(/\/$/, "");
}

function secure(request) {
  return new URL(request.url).protocol === "https:";
}

async function session(db, request) {
  const token = cookieValue(request, "snelfix_sess");
  if (!token) return null;
  const tokenHash = await sha256Hex(token);
  const row = await db.prepare("SELECT * FROM sessions WHERE token_hash = ?").bind(tokenHash).first();
  if (!row || row.expires_at < new Date().toISOString()) return null;
  return row;
}

async function context(db, request, env, lang, path) {
  const settings = await getSettings(db);
  const url = new URL(request.url);
  return {
    lang,
    path,
    origin: originOf(request, env),
    copy: t(lang),
    brand: brandFrom(settings),
    settings,
    garages: await listGarages(db),
    notes: await garageNotes(db),
    hours: await allHours(db),
    services: await listServices(db, lang, { activeOnly: true }),
    posts: await listPosts(db, lang, { publishedOnly: true }),
    exceptions: await upcomingExceptions(db, amsterdamNow().date),
    analyticsId: env.ANALYTICS_ID || siteConfig.analyticsId || "",
    gsc: env.GSC_VERIFICATION || siteConfig.searchConsoleVerification || "",
    today: amsterdamNow().date,
    query: Object.fromEntries(url.searchParams.entries()),
  };
}

function headersFor(ctx) {
  const analytics = Boolean(ctx?.analyticsId);
  const script = analytics ? " https://www.googletagmanager.com" : "";
  const connect = analytics ? " https://www.google-analytics.com https://region1.google-analytics.com" : "";
  return {
    "content-security-policy": [
      "default-src 'self'",
      "img-src 'self' data: blob: https://*.basemaps.cartocdn.com https://*.tile.openstreetmap.org",
      `style-src 'self' 'unsafe-inline'`,
      `script-src 'self' 'unsafe-inline'${script}`,
      `connect-src 'self' https://*.basemaps.cartocdn.com https://*.tile.openstreetmap.org${connect}`,
      "font-src 'self'",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join("; "),
    "x-content-type-options": "nosniff",
    "referrer-policy": "strict-origin-when-cross-origin",
    "x-frame-options": "DENY",
  };
}

async function filesFrom(form, field) {
  const list = form.getAll(field).filter((file) => file && typeof file.arrayBuffer === "function" && file.size);
  if (list.length > 3) return { error: "invalid" };
  const allowed = new Set(["image/jpeg", "image/png", "image/webp"]);
  const files = [];
  for (const file of list) {
    if (!allowed.has(file.type) || file.size > 450000) return { error: "invalid" };
    files.push({
      name: String(file.name || "photo").slice(0, 80),
      mime: file.type,
      data: bytesToBase64(new Uint8Array(await file.arrayBuffer())),
    });
  }
  return { files };
}

function validEmail(value) {
  if (!value) return true;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) && value.length <= 120;
}

export async function handleRequest(request, { db, env = {}, assets }) {
  const url = new URL(request.url);
  try {
    if (url.pathname === "/robots.txt" || url.pathname === "/sitemap.xml") {
      await ensureSeed(db, env);
      return url.pathname === "/robots.txt" ? robots(request, env) : sitemap(db, request, env);
    }
    if (request.method === "GET" && (ASSET.test(url.pathname) || url.pathname.startsWith("/photos/") || url.pathname.startsWith("/brand/") || url.pathname.startsWith("/assets/"))) {
      if (!assets) return text("Not found", 404);
      return assets.fetch(request);
    }
    await ensureSeed(db, env);
    if (url.pathname.startsWith("/media/u/")) return media(db, request, url.pathname);
    if (url.pathname.startsWith("/api/")) return api(db, request, env, url);
    const rawPath = url.pathname.replace(/\/+$/, "") || "/";
    if (rawPath === "/ru" || rawPath.startsWith("/ru/")) {
      const dest = rawPath.slice(3) || "/";
      return new Response(null, { status: 301, headers: { location: dest } });
    }
    return page(db, request, env, url);
  } catch (error) {
    console.error(error && error.message ? error.message : "request failed");
    return text("Error", 500);
  }
}

export async function handleScheduled(db, env) {
  await ensureSeed(db, env);
  await runReminders(db, env);
}

function robots(request, env) {
  const origin = originOf(request, env);
  return text(`User-agent: *\nAllow: /\nDisallow: /admin\nDisallow: /api/\nSitemap: ${origin}/sitemap.xml\n`);
}

async function sitemap(db, request, env) {
  const origin = originOf(request, env);
  const services = await listServices(db, "nl", { activeOnly: true });
  const paths = ["/", "/diensten", "/evacuatie", "/boeken", "/contact", "/faq", "/voorwaarden", "/privacy", "/cookies", "/vestigingen/waddinxveen", "/vestigingen/de-bilt"];
  for (const service of services) paths.push(`/diensten/${service.id}`);
  const urls = [];
  for (const path of paths) {
    for (const lang of siteConfig.locales) {
      const localized = lang === siteConfig.defaultLocale ? path : (path === "/" ? `/${lang}/` : `/${lang}${path}`);
      urls.push(`<url><loc>${origin}${localized}</loc></url>`);
    }
  }
  const body = `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${urls.join("")}</urlset>`;
  return new Response(body, { headers: { "content-type": "application/xml; charset=utf-8" } });
}

async function media(db, request, pathname) {
  const id = Number(pathname.split("/").pop());
  const row = await db.prepare("SELECT mime, data, public FROM uploads WHERE id = ?").bind(id).first();
  if (!row) return text("Not found", 404);
  if (!row.public && !(await session(db, request))) return text("Unauthorized", 401);
  return new Response(base64ToBytes(row.data), {
    headers: { "content-type": row.mime, "cache-control": "private, max-age=3600", "x-content-type-options": "nosniff" },
  });
}

async function page(db, request, env, url) {
  const { lang, path } = parseLangPath(url.pathname.replace(/\/+$/, "") || "/");
  const normalized = path === "" ? "/" : path;
  const ctx = await context(db, request, env, lang, normalized);
  const head = headersFor(ctx);
  let body;
  let status = 200;
  if (normalized === "/admin") {
    const copy = t(lang);
    const signed = await session(db, request);
    body = signed ? adminAppPage(copy, lang) : adminLoginPage(copy, lang);
    head["x-robots-tag"] = "noindex";
  } else if (normalized === "/") body = homePage(ctx);
  else if (normalized === "/diensten") body = servicesPage(ctx);
  else if (normalized.startsWith("/diensten/")) {
    const service = await serviceById(db, normalized.slice("/diensten/".length), lang);
    if (!service || !service.active) {
      body = notFoundPage(ctx);
      status = 404;
    } else body = servicePage(ctx, service);
  } else if (normalized.startsWith("/vestigingen/")) {
    const id = normalized.slice("/vestigingen/".length);
    const garage = ctx.garages.find((item) => item.id === id);
    if (!garage) {
      body = notFoundPage(ctx);
      status = 404;
    } else body = locationPage(ctx, garage);
  }   else if (normalized === "/evacuatie") body = towPage(ctx);
  else if (normalized === "/boeken") body = bookPage(ctx);
  else if (normalized === "/contact") body = contactPage(ctx);
  else if (normalized === "/faq") body = faqPage(ctx);
  else if (normalized === "/voorwaarden") body = legalPage(ctx, "terms");
  else if (normalized === "/privacy") body = legalPage(ctx, "privacy");
  else if (normalized === "/cookies") body = legalPage(ctx, "cookies");
  else {
    body = notFoundPage(ctx);
    status = 404;
  }
  return html(body, status, head);
}

async function api(db, request, env, url) {
  const path = url.pathname;
  if (path === "/api/health") return json({ ok: true });
  if (path === "/api/availability" && request.method === "GET") return availabilityApi(db, request, url);
  if (path === "/api/bookings" && request.method === "POST") return bookingApi(db, request, env);
  if (path === "/api/tow" && request.method === "POST") return towApi(db, request, env);
  if (path === "/api/auth/login" && request.method === "POST") return login(db, request);
  if (path === "/api/auth/logout" && request.method === "POST") return logout(request);
  if (path === "/api/auth/me" && request.method === "GET") {
    return json({ ok: Boolean(await session(db, request)) });
  }
  if (path === "/api/cron/reminders" && request.method === "POST") {
    const secret = env.CRON_SECRET || "";
    if (!secret || request.headers.get("authorization") !== `Bearer ${secret}`) return json({ error: "unauthorized" }, 401);
    const count = await runReminders(db, env);
    return json({ ok: true, count });
  }
  const signed = await session(db, request);
  if (!signed) return json({ error: "unauthorized" }, 401);
  return adminApi(db, request, env, url, path);
}

async function availabilityApi(db, request, url) {
  const garageId = url.searchParams.get("garage") || "";
  const serviceId = url.searchParams.get("service") || "";
  const date = url.searchParams.get("date") || "";
  const ignore = url.searchParams.get("ignore");
  let ignoreId = null;
  if (ignore) {
    if (!(await session(db, request))) return json({ error: "unauthorized" }, 401);
    ignoreId = Number(ignore);
  }
  const result = await availability(db, { garageId, serviceId, date, ignoreId });
  if (result.error) return json(result, 400);
  return json({
    ...result,
    slots: (result.slots || []).map((slot) => ({ ...slot, label: minLabel(slot.start) })),
  });
}

async function bookingApi(db, request, env) {
  const form = await request.formData();
  const phone = e164(form.get("cc"), form.get("national"));
  const year = Number(form.get("year"));
  const startMin = Number(form.get("start"));
  const date = String(form.get("date") || "");
  const email = String(form.get("email") || "").trim();
  const plate = cleanPlate(form.get("plate"));
  const make = String(form.get("make") || "").trim();
  const model = String(form.get("model") || "").trim();
  const name = String(form.get("name") || "").trim();
  const problem = String(form.get("problem") || "").trim();
  if (!phone || !isIsoDate(date) || !make || !model || !name || !problem || !plate || year < 1970 || year > 2028) {
    return json({ error: "invalid" }, 400);
  }
  if (!validEmail(email)) return json({ error: "invalid" }, 400);
  const photos = await filesFrom(form, "photos");
  if (photos.error) return json({ error: "invalid" }, 400);
  const lang = ["nl", "en", "ru", "uk"].includes(form.get("lang")) ? form.get("lang") : "nl";
  const created = await createBooking(db, {
    code: code("SF"),
    garageId: String(form.get("garage") || ""),
    serviceId: String(form.get("service") || ""),
    date,
    startMin,
    problem,
    lang,
    customer: { name, phone, email },
    vehicle: { make, model, year, plate },
  });
  if (created.error) return json({ error: created.error }, created.error === "slot_taken" ? 409 : 400);
  for (const file of photos.files) {
    await saveUpload(db, { ...file, bookingId: created.booking.id });
  }
  const garage = await db.prepare("SELECT city, street FROM garages WHERE id = ?").bind(created.booking.garage_id).first();
  const service = await serviceById(db, created.booking.service_id, lang);
  const payload = {
    code: created.booking.code,
    date,
    time: minLabel(created.booking.start_min),
    garage: garage ? `${garage.city}, ${garage.street}` : created.booking.garage_id,
    service: service ? service.title : created.booking.service_id,
    name,
    phone,
    email,
    vehicle: `${make} ${model} ${year} ${plate}`,
    problem,
    lang,
    summary: `${created.booking.code} ${garage ? garage.city : ""} ${date} ${minLabel(created.booking.start_min)} ${name} ${phone} ${make} ${model} ${plate}`,
  };
  await notifyOwner(db, env, { kind: "booking", refType: "booking", refId: created.booking.id, payload });
  await notifyClient(db, env, { kind: "booking", refType: "booking", refId: created.booking.id, payload });
  return json({ ok: true, confirmation: payload });
}

async function towApi(db, request, env) {
  const form = await request.formData();
  const phone = e164(form.get("cc"), form.get("national"));
  const name = String(form.get("name") || "").trim();
  const pickup = String(form.get("pickup") || "").trim();
  const delivery = String(form.get("delivery") || "").trim();
  const make = String(form.get("make") || "").trim();
  const model = String(form.get("model") || "").trim();
  const email = String(form.get("email") || "").trim();
  if (!phone || !name || !pickup || !delivery || !make || !model || !validEmail(email)) return json({ error: "invalid" }, 400);
  const photos = await filesFrom(form, "photos");
  if (photos.error) return json({ error: "invalid" }, 400);
  const lang = ["nl", "en", "ru", "uk"].includes(form.get("lang")) ? form.get("lang") : "nl";
  const ref = code("EV");
  const created = await createTow(db, {
    code: ref,
    pickup,
    delivery,
    make,
    model,
    running: form.get("running") !== "0",
    date: String(form.get("date") || ""),
    time: String(form.get("time") || ""),
    name,
    phone,
    email,
    urgent: form.get("urgent") === "1",
    notes: [
      form.get("vclass") === "suv" ? "type: SUV" : form.get("vclass") === "car" ? "type: car" : "",
      String(form.get("problem") || "").trim().slice(0, 400),
      String(form.get("notes") || "").trim(),
    ].filter(Boolean).join("\n"),
    lang,
  });
  for (const file of photos.files) await saveUpload(db, { ...file, towId: created.id });
  const route = `https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(pickup)}&destination=${encodeURIComponent(delivery)}&travelmode=driving`;
  const payload = {
    code: ref,
    pickup,
    delivery,
    make,
    model,
    running: form.get("running") !== "0",
    urgent: form.get("urgent") === "1",
    name,
    phone,
    email,
    date: String(form.get("date") || ""),
    time: String(form.get("time") || ""),
    route,
    osmPickup: `https://www.openstreetmap.org/search?query=${encodeURIComponent(pickup)}`,
    osmDrop: `https://www.openstreetmap.org/search?query=${encodeURIComponent(delivery)}`,
    summary: `${ref} ${form.get("urgent") === "1" ? "SPOED " : ""}${pickup} → ${delivery} ${name} ${phone}`,
  };
  await notifyOwner(db, env, { kind: "tow", refType: "tow", refId: created.id, payload });
  await notifyClient(db, env, { kind: "tow", refType: "tow", refId: created.id, payload });
  return json({ ok: true, confirmation: payload });
}

async function login(db, request) {
  if (!rateLimit(`login:${clientIp(request)}`)) return json({ error: "limited" }, 429);
  let body = {};
  try { body = await request.json(); } catch { return json({ error: "invalid" }, 400); }
  const settings = await getSettings(db);
  const username = String(body.username || "");
  const password = String(body.password || "");
  const userOk = username === (settings.admin_username || "admin");
  const passOk = await verifyPassword(password, settings.admin_password || "");
  if (!userOk || !passOk) return json({ error: "bad" }, 401);
  const token = randomHex(32);
  const now = new Date().toISOString();
  const expires = new Date(Date.now() + 14 * 86400000).toISOString();
  await db.prepare(
    "INSERT INTO sessions (id, token_hash, expires_at, created_at) VALUES (?, ?, ?, ?)"
  ).bind(randomHex(16), await sha256Hex(token), expires, now).run();
  return json({ ok: true }, 200, { "set-cookie": sessionCookie(token, secure(request)) });
}

function logout(request) {
  return json({ ok: true }, 200, { "set-cookie": sessionCookie("", secure(request), 0) });
}

async function adminApi(db, request, env, url, path) {
  const lang = ["nl", "en", "ru", "uk"].includes(url.searchParams.get("lang")) ? url.searchParams.get("lang") : "nl";
  if (path === "/api/admin/bookings" && request.method === "GET") {
    return json({ bookings: await listBookings(db, { q: url.searchParams.get("q") || "", status: url.searchParams.get("status") || "", lang }) });
  }
  const bookingAction = path.match(/^\/api\/admin\/bookings\/(\d+)\/(confirm|cancel|done|reschedule|note)$/);
  if (bookingAction) return bookingActionApi(db, request, bookingAction);
  if (path === "/api/admin/tows" && request.method === "GET") return json({ tows: await listTows(db) });
  const towAction = path.match(/^\/api\/admin\/tows\/(\d+)\/(confirm|cancel|done)$/);
  if (towAction && request.method === "POST") {
    const status = { confirm: "confirmed", cancel: "cancelled", done: "done" }[towAction[2]];
    await db.prepare("UPDATE tow_requests SET status = ? WHERE id = ?").bind(status, Number(towAction[1])).run();
    return json({ ok: true });
  }
  if (path === "/api/admin/services" && request.method === "GET") {
    const services = await listServices(db, lang);
    const full = [];
    for (const service of services) full.push({ ...service, i18n: await serviceI18n(db, service.id) });
    return json({ services: full });
  }
  const servicePut = path.match(/^\/api\/admin\/services\/([a-z0-9-]+)$/);
  if (servicePut && request.method === "PUT") return updateService(db, request, servicePut[1]);
  if (path === "/api/admin/garages" && request.method === "GET") {
    return json({
      garages: await listGarages(db),
      notes: await garageNotes(db),
      hours: await allHours(db),
      exceptions: await upcomingExceptions(db, "2000-01-01"),
      settings: await publicSettings(db),
    });
  }
  const hoursPut = path.match(/^\/api\/admin\/garages\/([a-z0-9-]+)\/hours$/);
  if (hoursPut && request.method === "PUT") return updateHours(db, request, hoursPut[1]);
  const notePut = path.match(/^\/api\/admin\/garages\/([a-z0-9-]+)\/note$/);
  if (notePut && request.method === "PUT") return updateNote(db, request, notePut[1]);
  if (path === "/api/admin/exceptions" && request.method === "POST") return addException(db, request);
  const exceptionDelete = path.match(/^\/api\/admin\/exceptions\/(\d+)$/);
  if (exceptionDelete && request.method === "DELETE") {
    await db.prepare("DELETE FROM schedule_exceptions WHERE id = ?").bind(Number(exceptionDelete[1])).run();
    return json({ ok: true });
  }
  if (path === "/api/admin/customers" && request.method === "GET") {
    return json({ customers: await listCustomers(db, url.searchParams.get("q") || "") });
  }
  const customer = path.match(/^\/api\/admin\/customers\/(\d+)$/);
  if (customer && request.method === "GET") {
    const detail = await customerDetail(db, Number(customer[1]));
    if (!detail) return json({ error: "not_found" }, 404);
    return json(detail);
  }
  if (path === "/api/admin/posts" && request.method === "GET") {
    const posts = await listPosts(db, lang);
    const full = [];
    for (const post of posts) {
      const i18n = {};
      const rows = (await db.prepare("SELECT lang, title, body FROM post_i18n WHERE post_id = ?").bind(post.id).all()).results || [];
      for (const row of rows) i18n[row.lang] = row;
      full.push({ ...post, i18n });
    }
    return json({ posts: full });
  }
  if (path === "/api/admin/posts" && request.method === "POST") return createPost(db, request);
  const postDelete = path.match(/^\/api\/admin\/posts\/(\d+)$/);
  if (postDelete && request.method === "DELETE") {
    await db.prepare("DELETE FROM post_i18n WHERE post_id = ?").bind(Number(postDelete[1])).run();
    await db.prepare("DELETE FROM posts WHERE id = ?").bind(Number(postDelete[1])).run();
    return json({ ok: true });
  }
  if (path === "/api/admin/password" && request.method === "POST") return changePassword(db, request);
  if (path === "/api/admin/contact" && request.method === "PUT") return updateContact(db, request);
  return json({ error: "not_found" }, 404);
}

async function publicSettings(db) {
  const settings = await getSettings(db);
  return {
    phone_display: settings.phone_display || "",
    whatsapp_url: settings.whatsapp_url || "",
    instagram_url: settings.instagram_url || "",
    telegram_url: settings.telegram_url || "",
  };
}

async function bookingActionApi(db, request, match) {
  const id = Number(match[1]);
  const action = match[2];
  if (request.method !== "POST") return json({ error: "method" }, 405);
  if (action === "confirm" || action === "cancel" || action === "done") {
    const status = { confirm: "confirmed", cancel: "cancelled", done: "completed" }[action];
    await db.prepare("UPDATE bookings SET status = ?, updated_at = ? WHERE id = ?").bind(status, new Date().toISOString(), id).run();
    return json({ ok: true });
  }
  if (action === "reschedule") {
    const body = await request.json();
    const result = await rescheduleBooking(db, id, String(body.date || ""), Number(body.start));
    if (result.error) return json(result, result.error === "slot_taken" ? 409 : 400);
    return json({ ok: true });
  }
  const body = await request.json();
  await db.prepare(
    "UPDATE bookings SET next_service_on = ?, next_service_note = ?, updated_at = ? WHERE id = ?"
  ).bind(String(body.next_service_on || ""), String(body.next_service_note || "").slice(0, 300), new Date().toISOString(), id).run();
  return json({ ok: true });
}

async function updateService(db, request, id) {
  const body = await request.json();
  const current = await db.prepare("SELECT id FROM services WHERE id = ?").bind(id).first();
  if (!current) return json({ error: "not_found" }, 404);
  const price = body.price_cents === null || body.price_cents === "" ? null : Number(body.price_cents);
  await db.prepare(
    `UPDATE services SET duration_min = ?, price_cents = ?, active = ?, bookable = ?, image = ? WHERE id = ?`
  ).bind(Number(body.duration_min) || 60, Number.isFinite(price) ? price : null, body.active ? 1 : 0, body.bookable ? 1 : 0, String(body.image || ""), id).run();
  for (const lang of ["nl", "en", "ru", "uk"]) {
    const row = body.i18n?.[lang];
    if (!row) continue;
    await db.prepare(
      `INSERT INTO service_i18n (service_id, lang, title, summary, body) VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(service_id, lang) DO UPDATE SET title = excluded.title, summary = excluded.summary, body = excluded.body`
    ).bind(id, lang, String(row.title || ""), String(row.summary || ""), String(row.body || "")).run();
  }
  return json({ ok: true });
}

async function updateHours(db, request, garageId) {
  const body = await request.json();
  if (!Array.isArray(body.hours) || body.hours.length !== 7) return json({ error: "invalid" }, 400);
  for (const row of body.hours) {
    const weekday = Number(row.weekday);
    if (row.closed) {
      await db.prepare(
        `INSERT INTO garage_hours (garage_id, weekday, open_min, close_min) VALUES (?, ?, NULL, NULL)
         ON CONFLICT(garage_id, weekday) DO UPDATE SET open_min = NULL, close_min = NULL`
      ).bind(garageId, weekday).run();
    } else {
      const open = parseMinutes(row.open);
      const close = parseMinutes(row.close);
      if (open == null || close == null || close <= open) return json({ error: "invalid" }, 400);
      await db.prepare(
        `INSERT INTO garage_hours (garage_id, weekday, open_min, close_min) VALUES (?, ?, ?, ?)
         ON CONFLICT(garage_id, weekday) DO UPDATE SET open_min = excluded.open_min, close_min = excluded.close_min`
      ).bind(garageId, weekday, open, close).run();
    }
  }
  return json({ ok: true });
}

async function updateNote(db, request, garageId) {
  const body = await request.json();
  for (const lang of ["nl", "en", "ru", "uk"]) {
    if (body.notes?.[lang] == null) continue;
    await db.prepare(
      `INSERT INTO garage_i18n (garage_id, lang, note) VALUES (?, ?, ?)
       ON CONFLICT(garage_id, lang) DO UPDATE SET note = excluded.note`
    ).bind(garageId, lang, String(body.notes[lang]).slice(0, 500)).run();
  }
  return json({ ok: true });
}

async function addException(db, request) {
  const body = await request.json();
  const kind = body.kind;
  if (!["closed", "hours", "block"].includes(kind) || !isIsoDate(body.date)) return json({ error: "invalid" }, 400);
  let start = null;
  let end = null;
  if (kind !== "closed") {
    start = parseMinutes(body.start);
    end = parseMinutes(body.end);
    if (start == null || end == null || end <= start) return json({ error: "invalid" }, 400);
  }
  await db.prepare(
    `INSERT INTO schedule_exceptions (garage_id, date, kind, start_min, end_min, note) VALUES (?, ?, ?, ?, ?, ?)`
  ).bind(String(body.garage_id), body.date, kind, start, end, String(body.note || "").slice(0, 160)).run();
  const window = await dayWindow(db, body.garage_id, body.date);
  return json({ ok: true, window });
}

async function createPost(db, request) {
  const form = await request.formData();
  const kind = form.get("kind") === "news" ? "news" : "photo";
  let image = String(form.get("image") || "");
  const file = form.get("file");
  if (file && typeof file.arrayBuffer === "function" && file.size) {
    const saved = await filesFrom(form, "file");
    if (saved.error) return json({ error: "invalid" }, 400);
    if (saved.files[0]) {
      const id = await saveUpload(db, { ...saved.files[0], public: 1 });
      image = `/media/u/${id}`;
    }
  }
  if (!image) image = "/photos/workshop.jpg";
  const now = new Date().toISOString();
  const created = await db.prepare(
    "INSERT INTO posts (kind, image, published, sort, created_at) VALUES (?, ?, ?, ?, ?) RETURNING id"
  ).bind(kind, image, form.get("published") === "0" ? 0 : 1, Number(form.get("sort") || 0), now).first();
  for (const lang of ["nl", "en", "ru", "uk"]) {
    const title = String(form.get(`title_${lang}`) || "");
    const body = String(form.get(`body_${lang}`) || "");
    if (!title && lang !== "nl") continue;
    await db.prepare(
      "INSERT INTO post_i18n (post_id, lang, title, body) VALUES (?, ?, ?, ?)"
    ).bind(created.id, lang, title || String(form.get("title_nl") || "SnelFix"), body).run();
  }
  return json({ ok: true, id: created.id });
}

async function changePassword(db, request) {
  const body = await request.json();
  const current = String(body.current || "");
  const next = String(body.next || "");
  const confirm = String(body.confirm || "");
  if (next.length < 4) return json({ error: "short" }, 400);
  if (next !== confirm) return json({ error: "mismatch" }, 400);
  const settings = await getSettings(db);
  if (!(await verifyPassword(current, settings.admin_password || ""))) return json({ error: "bad" }, 400);
  await setSetting(db, "admin_password", await hashPassword(next));
  await db.prepare("DELETE FROM sessions").run();
  return json({ ok: true }, 200, { "set-cookie": sessionCookie("", secure(request), 0) });
}

async function updateContact(db, request) {
  const body = await request.json();
  const phone = String(body.phone_display || "").trim();
  const tel = `+${phone.replace(/\D/g, "")}`;
  if (!/^\+[1-9]\d{7,14}$/.test(tel)) return json({ error: "invalid" }, 400);
  await setSetting(db, "phone_display", phone);
  await setSetting(db, "phone_tel", tel);
  await setSetting(db, "whatsapp_url", String(body.whatsapp_url || "").slice(0, 200));
  await setSetting(db, "instagram_url", String(body.instagram_url || "").slice(0, 200));
  await setSetting(db, "telegram_url", String(body.telegram_url || "").slice(0, 200));
  return json({ ok: true });
}
