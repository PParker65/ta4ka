import { json, readJson, requireUser } from "../lib/auth.js";
import { emptyLotsPayload, parsePayload } from "../lib/db.js";
import { IRINA_SEED } from "../lib/irina-seed.js";

const IRINA = "irinaogiyko@gmail.com";

function seedIrina() {
  return {
    lots: Array.isArray(IRINA_SEED.lots) ? IRINA_SEED.lots : [],
    pricePerDayGrosze: IRINA_SEED.pricePerDayGrosze || 500,
    sectorCount: IRINA_SEED.sectorCount || 5,
    shopJournalHydrated: "irina-v1",
  };
}

async function loadPayload(db, email) {
  const row = await db
    .prepare("SELECT payload FROM lots WHERE user_email = ?")
    .bind(email)
    .first();
  let payload = parsePayload(row && row.payload);
  const empty = !payload.lots.length;
  if (email === IRINA && empty) {
    payload = seedIrina();
    await db
      .prepare(
        "INSERT OR REPLACE INTO lots (user_email, payload, updated_at) VALUES (?, ?, ?)",
      )
      .bind(email, JSON.stringify(payload), Date.now())
      .run();
    return payload;
  }
  let persist = !row;
  if (row && row.payload) {
    try {
      const raw = typeof row.payload === "string" ? JSON.parse(row.payload) : row.payload;
      const n = Number(raw && raw.sectorCount);
      if (!Number.isFinite(n) || n < 3) persist = true;
    } catch {
      persist = true;
    }
  }
  if (persist) {
    payload = { ...payload, sectorCount: payload.sectorCount < 3 ? 3 : payload.sectorCount };
    await db
      .prepare(
        "INSERT OR REPLACE INTO lots (user_email, payload, updated_at) VALUES (?, ?, ?)",
      )
      .bind(email, JSON.stringify(payload), Date.now())
      .run();
  }
  return payload;
}

export async function onRequestGet(context) {
  const gate = await requireUser(context);
  if (gate.error) return gate.error;
  const payload = await loadPayload(gate.db, gate.user.email);
  return json(
    {
      email: gate.user.email,
      shopName: gate.user.shop_name || "",
      ...payload,
    },
    200,
    context.request,
  );
}

export async function onRequestPut(context) {
  const gate = await requireUser(context);
  if (gate.error) return gate.error;
  let body;
  try {
    body = await readJson(context.request);
  } catch {
    return json({ error: "bad_json" }, 400, context.request);
  }
  const incoming = parsePayload(body);
  if (gate.user.email === IRINA && !incoming.lots.length) {
    const current = await loadPayload(gate.db, gate.user.email);
    if (current.lots.length) {
      return json(
        { ok: true, email: gate.user.email, ...current },
        200,
        context.request,
      );
    }
  }
  const payload = {
    ...emptyLotsPayload(),
    ...incoming,
  };
  await gate.db
    .prepare(
      "INSERT OR REPLACE INTO lots (user_email, payload, updated_at) VALUES (?, ?, ?)",
    )
    .bind(gate.user.email, JSON.stringify(payload), Date.now())
    .run();
  return json({ ok: true, email: gate.user.email }, 200, context.request);
}
