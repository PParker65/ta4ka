import { hashPassword, json, newSalt, readJson, requireUser, verifyPassword } from "../lib/auth.js";

export async function onRequestPost(context) {
  const gate = await requireUser(context);
  if (gate.error) return gate.error;
  let body;
  try {
    body = await readJson(context.request);
  } catch {
    return json({ error: "bad_json" }, 400, context.request);
  }
  const oldPassword = String(body.old || body.oldPassword || "");
  const nextPassword = String(body.new || body.newPassword || "");
  if (nextPassword.length < 8) {
    return json({ error: "weak" }, 400, context.request);
  }
  const ok = await verifyPassword(
    oldPassword,
    gate.user.salt,
    gate.user.password_hash,
  );
  if (!ok) return json({ error: "unauthorized" }, 401, context.request);
  const salt = newSalt();
  const passwordHash = await hashPassword(nextPassword, salt);
  await gate.db
    .prepare("UPDATE users SET password_hash = ?, salt = ? WHERE email = ?")
    .bind(passwordHash, salt, gate.user.email)
    .run();
  return json({ ok: true, email: gate.user.email }, 200, context.request);
}
