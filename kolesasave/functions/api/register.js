import {
  createSession,
  hashPassword,
  isEmail,
  json,
  newSalt,
  normalizeEmail,
  readJson,
} from "../lib/auth.js";
import { d1, emptyLotsPayload } from "../lib/db.js";
import { requestCountry } from "../lib/stats.js";

export async function onRequestPost(context) {
  const db = d1(context.env);
  if (!db) return json({ error: "d1" }, 503, context.request);
  let body;
  try {
    body = await readJson(context.request);
  } catch {
    return json({ error: "bad_json" }, 400, context.request);
  }
  const email = normalizeEmail(body.email);
  const password = String(body.password || "");
  const shopName = String(body.shopName || body.shop_name || "").trim();
  if (!isEmail(email)) return json({ error: "email" }, 400, context.request);
  if (password.length < 8) return json({ error: "weak" }, 400, context.request);
  if (!shopName) return json({ error: "shop" }, 400, context.request);

  const existing = await db
    .prepare("SELECT email FROM users WHERE email = ?")
    .bind(email)
    .first();
  if (existing) {
    return json({ error: "exists" }, 409, context.request);
  }

  const salt = newSalt();
  const passwordHash = await hashPassword(password, salt);
  const country = requestCountry(context.request);
  try {
    try {
      await db
        .prepare(
          "INSERT INTO users (email, password_hash, salt, shop_name, created_at, country) VALUES (?, ?, ?, ?, ?, ?)",
        )
        .bind(email, passwordHash, salt, shopName, Date.now(), country)
        .run();
    } catch (err) {
      const msg = String((err && err.message) || err);
      if (!/no such column|no column named/i.test(msg)) throw err;
      await db
        .prepare(
          "INSERT INTO users (email, password_hash, salt, shop_name, created_at) VALUES (?, ?, ?, ?, ?)",
        )
        .bind(email, passwordHash, salt, shopName, Date.now())
        .run();
    }
  } catch (err) {
    const msg = String(err && err.message ? err.message : err);
    if (/unique|constraint/i.test(msg)) {
      return json({ error: "exists" }, 409, context.request);
    }
    throw err;
  }

  await db
    .prepare("INSERT OR IGNORE INTO lots (user_email, payload, updated_at) VALUES (?, ?, ?)")
    .bind(email, JSON.stringify(emptyLotsPayload()), Date.now())
    .run();

  const token = await createSession(db, email);
  return json({ token, email, shopName }, 200, context.request);
}
