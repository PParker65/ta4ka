function clip(value, max = 500) {
  const text = String(value ?? "");
  return text.length > max ? `${text.slice(0, max)}…` : text;
}

export async function storeNotification(db, item) {
  const now = new Date().toISOString();
  await db.prepare(
    `INSERT INTO notifications (channel, kind, ref_type, ref_id, payload, status, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`
  ).bind(
    item.channel,
    item.kind,
    item.refType,
    item.refId,
    JSON.stringify(item.payload),
    item.status || "stored",
    now
  ).run();
}

async function postJson(url, payload) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!response.ok) throw new Error(`hook ${response.status}`);
}

export async function notifyOwner(db, env, item) {
  const payload = item.payload;
  let status = "stored";
  const token = env.TELEGRAM_BOT_TOKEN || "";
  const chat = env.TELEGRAM_CHAT_ID || "";
  if (token && chat) {
    try {
      const text = [
        `SnelFix — ${item.kind}`,
        payload.code ? `Code: ${payload.code}` : "",
        payload.summary ? clip(payload.summary, 800) : "",
      ].filter(Boolean).join("\n");
      const response = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ chat_id: chat, text }),
      });
      status = response.ok ? "sent" : "failed";
    } catch {
      status = "failed";
    }
  }
  if (env.EMAIL_WEBHOOK_URL) {
    try {
      await postJson(env.EMAIL_WEBHOOK_URL, {
        to: env.EMAIL_TO || "",
        kind: item.kind,
        payload,
      });
      if (status === "stored") status = "sent";
    } catch {
      status = "failed";
    }
  }
  await storeNotification(db, { ...item, channel: "owner", status });
}

export async function notifyClient(db, env, item) {
  let status = "stored";
  if (env.EMAIL_WEBHOOK_URL) {
    try {
      await postJson(env.EMAIL_WEBHOOK_URL, { kind: `client_${item.kind}`, payload: item.payload });
      status = "sent";
    } catch {
      status = "failed";
    }
  }
  if (env.SMS_WEBHOOK_URL) {
    try {
      await postJson(env.SMS_WEBHOOK_URL, { kind: `client_${item.kind}`, payload: item.payload });
      status = "sent";
    } catch {
      status = status === "sent" ? "sent" : "failed";
    }
  }
  await storeNotification(db, { ...item, channel: "client", status });
}

export async function runReminders(db, env) {
  const now = new Date().toISOString();
  const { results } = await db.prepare(
    `SELECT b.id, b.code, b.date, b.start_min, b.garage_id, b.service_id, b.lang,
            c.name, c.phone, c.email
     FROM bookings b
     JOIN customers c ON c.id = b.customer_id
     WHERE b.reminder_sent = 0
       AND b.status IN ('requested', 'confirmed')
       AND b.reminder_at IS NOT NULL
       AND b.reminder_at <= ?`
  ).bind(now).all();
  for (const row of results || []) {
    const payload = {
      code: row.code,
      date: row.date,
      start_min: row.start_min,
      garage_id: row.garage_id,
      service_id: row.service_id,
      name: row.name,
      phone: row.phone,
      email: row.email,
      lang: row.lang,
      summary: `${row.code} ${row.date} ${row.name} ${row.phone}`,
    };
    await notifyOwner(db, env, { kind: "reminder", refType: "booking", refId: row.id, payload });
    await notifyClient(db, env, { kind: "reminder", refType: "booking", refId: row.id, payload });
    await db.prepare(
      "UPDATE bookings SET reminder_sent = 1, updated_at = ? WHERE id = ?"
    ).bind(now, row.id).run();
  }
  return (results || []).length;
}
