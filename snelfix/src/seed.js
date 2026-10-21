import { GARAGES, POSTS, SERVICES, WEEKLY_HOURS } from "./catalog.js";
import { hashPassword } from "./util.js";

let ready;

export function ensureSeed(db, env) {
  if (!ready) {
    ready = seedIfNeeded(db, env).catch((error) => {
      ready = null;
      throw error;
    });
  }
  return ready;
}

const CATALOG_VERSION = "prices-20261021c";

async function seedIfNeeded(db, env) {
  const flag = await db.prepare("SELECT value FROM settings WHERE key = 'seeded'").first();
  if (!flag) await seedBase(db, env);
  await syncCatalog(db);
}

async function seedBase(db, env) {
  const password = await hashPassword(env.ADMIN_PASSWORD || "admin");
  await db.prepare(
    "INSERT INTO settings (key, value) VALUES ('admin_username', 'admin') ON CONFLICT(key) DO NOTHING"
  ).run();
  await db.prepare(
    "INSERT INTO settings (key, value) VALUES ('admin_password', ?) ON CONFLICT(key) DO NOTHING"
  ).bind(password).run();
  const defaults = {
    phone_display: "+31 6 13044422",
    phone_tel: "+31613044422",
    whatsapp_url: "https://wa.me/31613044422",
    instagram_url: "https://instagram.com/SnelFix_Auto",
    telegram_url: "https://t.me/SnelFix_Auto",
    instagram_handle: "@SnelFix_Auto",
    telegram_handle: "@SnelFix_Auto",
  };
  for (const [key, value] of Object.entries(defaults)) {
    await db.prepare(
      "INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO NOTHING"
    ).bind(key, value).run();
  }
  for (const garage of GARAGES) {
    await db.prepare(
      `INSERT INTO garages (id, name, street, postal, city, lat, lng, phone)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO NOTHING`
    ).bind(garage.id, garage.name, garage.street, garage.postal, garage.city, garage.lat, garage.lng, garage.phone).run();
    for (const [lang, note] of Object.entries(garage.note)) {
      await db.prepare(
        `INSERT INTO garage_i18n (garage_id, lang, note) VALUES (?, ?, ?)
         ON CONFLICT(garage_id, lang) DO NOTHING`
      ).bind(garage.id, lang, note).run();
    }
    for (const [weekday, open, close] of WEEKLY_HOURS) {
      await db.prepare(
        `INSERT INTO garage_hours (garage_id, weekday, open_min, close_min)
         VALUES (?, ?, ?, ?)
         ON CONFLICT(garage_id, weekday) DO NOTHING`
      ).bind(garage.id, weekday, open, close).run();
    }
  }
  const existingPosts = await db.prepare("SELECT COUNT(*) AS n FROM posts").first();
  if (!existingPosts || !existingPosts.n) {
    const now = new Date().toISOString();
    for (const post of POSTS) {
      const created = await db.prepare(
        `INSERT INTO posts (kind, image, published, sort, created_at)
         VALUES (?, ?, 1, ?, ?) RETURNING id`
      ).bind(post.kind, post.image, post.sort, now).first();
      for (const lang of ["nl", "en", "ru", "uk"]) {
        await db.prepare(
          "INSERT INTO post_i18n (post_id, lang, title, body) VALUES (?, ?, ?, ?)"
        ).bind(created.id, lang, post.title[lang], post.body[lang]).run();
      }
    }
  }
  await db.prepare(
    "INSERT INTO settings (key, value) VALUES ('seeded', '1') ON CONFLICT(key) DO NOTHING"
  ).run();
}

async function syncCatalog(db) {
  const current = await db.prepare("SELECT value FROM settings WHERE key = 'catalog_version'").first();
  if (current && current.value === CATALOG_VERSION) return;
  const ids = new Set(SERVICES.map((service) => service.id));
  const existing = await db.prepare("SELECT id FROM services").all();
  for (const row of existing.results || []) {
    if (!ids.has(row.id)) {
      await db.prepare("UPDATE services SET active = 0, bookable = 0 WHERE id = ?").bind(row.id).run();
    }
  }
  for (const service of SERVICES) {
    await db.prepare(
      `INSERT INTO services (id, duration_min, price_cents, sort, active, bookable, kind, image)
       VALUES (?, ?, ?, ?, 1, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         duration_min = excluded.duration_min,
         price_cents = excluded.price_cents,
         sort = excluded.sort,
         active = 1,
         bookable = excluded.bookable,
         kind = excluded.kind,
         image = excluded.image`
    ).bind(service.id, service.duration, service.price, service.sort, service.bookable, service.kind, service.image).run();
    for (const lang of ["nl", "en", "ru", "uk"]) {
      await db.prepare(
        `INSERT INTO service_i18n (service_id, lang, title, summary, body)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(service_id, lang) DO UPDATE SET
           title = excluded.title,
           summary = excluded.summary,
           body = excluded.body`
      ).bind(service.id, lang, service.title[lang], service.summary[lang], service.body[lang]).run();
    }
  }
  await db.prepare(
    "INSERT INTO settings (key, value) VALUES ('catalog_version', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value"
  ).bind(CATALOG_VERSION).run();
}
