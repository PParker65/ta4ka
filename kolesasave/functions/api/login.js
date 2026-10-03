import {
  createSession,
  isEmail,
  json,
  normalizeEmail,
  readJson,
  verifyPassword,
} from "../lib/auth.js";
import { d1 } from "../lib/db.js";

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
  if (!isEmail(email) || !password) {
    return json({ error: "unauthorized" }, 401, context.request);
  }
  const user = await db
    .prepare(
      "SELECT email, password_hash, salt, shop_name FROM users WHERE email = ?",
    )
    .bind(email)
    .first();
  if (!user) return json({ error: "unauthorized" }, 401, context.request);
  const ok = await verifyPassword(password, user.salt, user.password_hash);
  if (!ok) return json({ error: "unauthorized" }, 401, context.request);
  const token = await createSession(db, user.email);
  return json(
    { token, email: user.email, shopName: user.shop_name || "" },
    200,
    context.request,
  );
}
