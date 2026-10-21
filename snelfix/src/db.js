import { amsterdamNow, amsterdamToUtcIso, isIsoDate, overlaps, weekdayFromDate } from "./util.js";

export async function getSettings(db) {
  const { results } = await db.prepare("SELECT key, value FROM settings").all();
  const out = {};
  for (const row of results || []) out[row.key] = row.value;
  return out;
}

export async function setSetting(db, key, value) {
  await db.prepare(
    "INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value"
  ).bind(key, value).run();
}

export async function listGarages(db) {
  const { results } = await db.prepare(
    "SELECT * FROM garages ORDER BY CASE id WHEN 'waddinxveen' THEN 0 ELSE 1 END, city"
  ).all();
  return results || [];
}

export async function garageNotes(db) {
  const { results } = await db.prepare("SELECT garage_id, lang, note FROM garage_i18n").all();
  const map = {};
  for (const row of results || []) {
    if (!map[row.garage_id]) map[row.garage_id] = {};
    map[row.garage_id][row.lang] = row.note;
  }
  return map;
}

export async function allHours(db) {
  const { results } = await db.prepare(
    "SELECT garage_id, weekday, open_min, close_min FROM garage_hours ORDER BY weekday"
  ).all();
  const map = {};
  for (const row of results || []) {
    if (!map[row.garage_id]) map[row.garage_id] = [];
    map[row.garage_id].push(row);
  }
  return map;
}

export async function upcomingExceptions(db, fromDate) {
  const { results } = await db.prepare(
    "SELECT * FROM schedule_exceptions WHERE date >= ? ORDER BY date, id"
  ).bind(fromDate).all();
  return results || [];
}

export async function listServices(db, lang, { activeOnly = false } = {}) {
  const where = activeOnly ? "WHERE s.active = 1" : "";
  const { results } = await db.prepare(
    `SELECT s.*, i.title, i.summary, i.body
     FROM services s
     LEFT JOIN service_i18n i ON i.service_id = s.id AND i.lang = ?
     ${where}
     ORDER BY s.sort, s.id`
  ).bind(lang).all();
  return results || [];
}

export async function serviceById(db, id, lang) {
  return db.prepare(
    `SELECT s.*, i.title, i.summary, i.body
     FROM services s
     LEFT JOIN service_i18n i ON i.service_id = s.id AND i.lang = ?
     WHERE s.id = ?`
  ).bind(lang, id).first();
}

export async function serviceI18n(db, id) {
  const { results } = await db.prepare(
    "SELECT lang, title, summary, body FROM service_i18n WHERE service_id = ?"
  ).bind(id).all();
  const map = {};
  for (const row of results || []) map[row.lang] = row;
  return map;
}

export async function listPosts(db, lang, { publishedOnly = false } = {}) {
  const where = publishedOnly ? "WHERE p.published = 1" : "";
  const { results } = await db.prepare(
    `SELECT p.*, i.title, i.body
     FROM posts p
     LEFT JOIN post_i18n i ON i.post_id = p.id AND i.lang = ?
     ${where}
     ORDER BY p.sort, p.id`
  ).bind(lang).all();
  return results || [];
}

export async function dayWindow(db, garageId, date) {
  const exceptions = (await db.prepare(
    "SELECT * FROM schedule_exceptions WHERE garage_id = ? AND date = ?"
  ).bind(garageId, date).all()).results || [];
  if (exceptions.some((row) => row.kind === "closed")) {
    return { closed: true, blocks: [] };
  }
  const special = exceptions.find((row) => row.kind === "hours");
  let open = null;
  let close = null;
  if (special) {
    open = special.start_min;
    close = special.end_min;
  } else {
    const weekday = weekdayFromDate(date);
    const row = await db.prepare(
      "SELECT open_min, close_min FROM garage_hours WHERE garage_id = ? AND weekday = ?"
    ).bind(garageId, weekday).first();
    if (!row || row.open_min == null || row.close_min == null) return { closed: true, blocks: [] };
    open = row.open_min;
    close = row.close_min;
  }
  const blocks = exceptions
    .filter((row) => row.kind === "block" && row.start_min != null && row.end_min != null)
    .map((row) => ({ start: row.start_min, end: row.end_min }));
  return { closed: false, open, close, blocks };
}

export async function takenRanges(db, garageId, date, ignoreId = null) {
  const { results } = await db.prepare(
    `SELECT id, start_min, end_min FROM bookings
     WHERE garage_id = ? AND date = ? AND status != 'cancelled'`
  ).bind(garageId, date).all();
  return (results || []).filter((row) => String(row.id) !== String(ignoreId || ""));
}

export async function availability(db, { garageId, serviceId, date, ignoreId = null }) {
  if (!isIsoDate(date)) return { error: "invalid" };
  const service = await db.prepare(
    "SELECT duration_min, bookable, active, kind FROM services WHERE id = ?"
  ).bind(serviceId).first();
  if (!service || !service.active || !service.bookable || service.kind === "tow") return { error: "invalid" };
  const now = amsterdamNow();
  if (date < now.date) return { slots: [], closed: false, past: true };
  const max = new Date(`${now.date}T00:00:00Z`);
  max.setUTCDate(max.getUTCDate() + 90);
  if (date > max.toISOString().slice(0, 10)) return { error: "invalid" };
  const window = await dayWindow(db, garageId, date);
  if (window.closed) return { slots: [], closed: true };
  const taken = await takenRanges(db, garageId, date, ignoreId);
  const duration = Number(service.duration_min);
  const slots = [];
  for (let start = window.open; start + duration <= window.close; start += 30) {
    const end = start + duration;
    if (date === now.date && start <= now.minutes) continue;
    if (window.blocks.some((block) => overlaps(start, end, block.start, block.end))) continue;
    if (taken.some((row) => overlaps(start, end, row.start_min, row.end_min))) continue;
    slots.push({ start, end });
  }
  return { slots, closed: false, open: window.open, close: window.close, duration };
}

async function upsertCustomer(db, { name, phone, email }) {
  const now = new Date().toISOString();
  const row = await db.prepare(
    `INSERT INTO customers (name, phone, email, created_at)
     VALUES (?, ?, ?, ?)
     ON CONFLICT(phone) DO UPDATE SET
       name = excluded.name,
       email = CASE WHEN excluded.email != '' THEN excluded.email ELSE customers.email END
     RETURNING id`
  ).bind(name, phone, email || "", now).first();
  return row.id;
}

async function upsertVehicle(db, customerId, vehicle) {
  const plate = vehicle.plate || "";
  const now = new Date().toISOString();
  if (plate) {
    const existing = await db.prepare(
      "SELECT id FROM vehicles WHERE customer_id = ? AND plate = ?"
    ).bind(customerId, plate).first();
    if (existing) {
      await db.prepare(
        "UPDATE vehicles SET make = ?, model = ?, year = ? WHERE id = ?"
      ).bind(vehicle.make, vehicle.model, vehicle.year, existing.id).run();
      return existing.id;
    }
  }
  const created = await db.prepare(
    `INSERT INTO vehicles (customer_id, make, model, year, plate, created_at)
     VALUES (?, ?, ?, ?, ?, ?) RETURNING id`
  ).bind(customerId, vehicle.make, vehicle.model, vehicle.year, plate, now).first();
  return created.id;
}

export async function createBooking(db, input) {
  const slot = await availability(db, {
    garageId: input.garageId,
    serviceId: input.serviceId,
    date: input.date,
  });
  if (slot.error) return { error: slot.error };
  if (slot.past) return { error: "past" };
  if (slot.closed) return { error: "closed" };
  const match = (slot.slots || []).find((item) => item.start === input.startMin);
  if (!match) return { error: "slot_taken" };
  const customerId = await upsertCustomer(db, input.customer);
  const vehicleId = await upsertVehicle(db, customerId, input.vehicle);
  const now = new Date().toISOString();
  const reminderAt = amsterdamToUtcIso(input.date, "07:00");
  const inserted = await db.prepare(
    `INSERT INTO bookings (
      code, garage_id, service_id, customer_id, vehicle_id, date, start_min, end_min,
      problem, status, lang, reminder_at, reminder_sent, created_at, updated_at
    )
    SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, 'requested', ?, ?, 0, ?, ?
    WHERE NOT EXISTS (
      SELECT 1 FROM bookings
      WHERE garage_id = ? AND date = ? AND status != 'cancelled'
        AND start_min < ? AND end_min > ?
    )`
  ).bind(
    input.code,
    input.garageId,
    input.serviceId,
    customerId,
    vehicleId,
    input.date,
    match.start,
    match.end,
    input.problem || "",
    input.lang || "nl",
    reminderAt,
    now,
    now,
    input.garageId,
    input.date,
    match.end,
    match.start
  ).run();
  if (!inserted.meta || !inserted.meta.changes) return { error: "slot_taken" };
  const booking = await db.prepare("SELECT * FROM bookings WHERE code = ?").bind(input.code).first();
  return { booking, customerId, vehicleId };
}

export async function createTow(db, input) {
  const customerId = await upsertCustomer(db, {
    name: input.name,
    phone: input.phone,
    email: input.email,
  });
  const now = new Date().toISOString();
  const inserted = await db.prepare(
    `INSERT INTO tow_requests (
      code, pickup, delivery, make, model, running, desired_date, desired_time,
      contact_name, contact_phone, contact_email, urgent, notes, status, lang, customer_id, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'new', ?, ?, ?)
    RETURNING id`
  ).bind(
    input.code,
    input.pickup,
    input.delivery,
    input.make || "",
    input.model || "",
    input.running ? 1 : 0,
    input.date || "",
    input.time || "",
    input.name,
    input.phone,
    input.email || "",
    input.urgent ? 1 : 0,
    input.notes || "",
    input.lang || "nl",
    customerId,
    now
  ).first();
  return { id: inserted.id, customerId };
}

export async function saveUpload(db, file) {
  const now = new Date().toISOString();
  const row = await db.prepare(
    `INSERT INTO uploads (booking_id, tow_id, post_id, public, name, mime, data, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id`
  ).bind(
    file.bookingId || null,
    file.towId || null,
    file.postId || null,
    file.public ? 1 : 0,
    file.name || "",
    file.mime,
    file.data,
    now
  ).first();
  return row.id;
}

export async function bookingByCode(db, code, lang = "ru") {
  return db.prepare(
    `SELECT b.code, b.status, b.date, b.start_min, b.end_min, b.problem, b.next_service_note,
            c.name AS name, c.phone AS phone,
            v.make, v.model, v.year, v.plate,
            g.city, g.street, g.postal, g.phone AS garage_phone,
            i.title AS service
     FROM bookings b
     JOIN customers c ON c.id = b.customer_id
     JOIN vehicles v ON v.id = b.vehicle_id
     JOIN garages g ON g.id = b.garage_id
     LEFT JOIN service_i18n i ON i.service_id = b.service_id AND i.lang = ?
     WHERE b.code = ?`
  ).bind(lang, code).first();
}

export async function listBookings(db, { q = "", status = "", lang = "nl" } = {}) {
  const like = `%${q.replace(/[%_]/g, "")}%`;
  const { results } = await db.prepare(
    `SELECT b.*, c.name AS customer_name, c.phone, c.email,
            v.make, v.model, v.year, v.plate,
            g.name AS garage_name, g.city AS garage_city,
            i.title AS service_title,
            (SELECT group_concat(u.id) FROM uploads u WHERE u.booking_id = b.id) AS photo_ids
     FROM bookings b
     JOIN customers c ON c.id = b.customer_id
     JOIN vehicles v ON v.id = b.vehicle_id
     JOIN garages g ON g.id = b.garage_id
     LEFT JOIN service_i18n i ON i.service_id = b.service_id AND i.lang = ?
     WHERE (? = '' OR c.name LIKE ? OR c.phone LIKE ? OR v.plate LIKE ? OR b.code LIKE ?)
       AND (? = '' OR b.status = ?)
     ORDER BY b.date DESC, b.start_min DESC
     LIMIT 200`
  ).bind(lang, q, like, like, like, like, status, status).all();
  return results || [];
}

export async function listTows(db) {
  const { results } = await db.prepare(
    `SELECT t.*,
            (SELECT group_concat(u.id) FROM uploads u WHERE u.tow_id = t.id) AS photo_ids
     FROM tow_requests t
     ORDER BY t.urgent DESC, t.created_at DESC
     LIMIT 200`
  ).all();
  return results || [];
}

export async function listCustomers(db, q = "") {
  const like = `%${q.replace(/[%_]/g, "")}%`;
  const { results } = await db.prepare(
    `SELECT c.*,
            (SELECT COUNT(*) FROM bookings b WHERE b.customer_id = c.id) AS bookings,
            (SELECT COUNT(*) FROM vehicles v WHERE v.customer_id = c.id) AS vehicles
     FROM customers c
     WHERE ? = '' OR c.name LIKE ? OR c.phone LIKE ? OR c.email LIKE ?
     ORDER BY c.created_at DESC
     LIMIT 200`
  ).bind(q, like, like, like).all();
  return results || [];
}

export async function customerDetail(db, id) {
  const customer = await db.prepare("SELECT * FROM customers WHERE id = ?").bind(id).first();
  if (!customer) return null;
  const vehicles = (await db.prepare(
    "SELECT * FROM vehicles WHERE customer_id = ? ORDER BY id DESC"
  ).bind(id).all()).results || [];
  const bookings = (await db.prepare(
    `SELECT b.*, g.city AS garage_city, i.title AS service_title
     FROM bookings b
     JOIN garages g ON g.id = b.garage_id
     LEFT JOIN service_i18n i ON i.service_id = b.service_id AND i.lang = 'nl'
     WHERE b.customer_id = ?
     ORDER BY b.date DESC`
  ).bind(id).all()).results || [];
  const tows = (await db.prepare(
    "SELECT * FROM tow_requests WHERE customer_id = ? ORDER BY created_at DESC"
  ).bind(id).all()).results || [];
  return { customer, vehicles, bookings, tows };
}

export async function rescheduleBooking(db, id, date, startMin) {
  const booking = await db.prepare("SELECT * FROM bookings WHERE id = ?").bind(id).first();
  if (!booking || booking.status === "cancelled") return { error: "invalid" };
  const slot = await availability(db, {
    garageId: booking.garage_id,
    serviceId: booking.service_id,
    date,
    ignoreId: id,
  });
  if (slot.error) return { error: slot.error };
  if (slot.closed) return { error: "closed" };
  const match = (slot.slots || []).find((item) => item.start === startMin);
  if (!match) return { error: "slot_taken" };
  const now = new Date().toISOString();
  const reminderAt = amsterdamToUtcIso(date, "07:00");
  const updated = await db.prepare(
    `UPDATE bookings
     SET date = ?, start_min = ?, end_min = ?, reminder_at = ?, reminder_sent = 0, updated_at = ?, status = CASE WHEN status = 'completed' THEN 'confirmed' ELSE status END
     WHERE id = ?
       AND NOT EXISTS (
         SELECT 1 FROM bookings
         WHERE garage_id = ? AND date = ? AND status != 'cancelled' AND id != ?
           AND start_min < ? AND end_min > ?
       )`
  ).bind(
    date, match.start, match.end, reminderAt, now, id,
    booking.garage_id, date, id, match.end, match.start
  ).run();
  if (!updated.meta || !updated.meta.changes) return { error: "slot_taken" };
  return { ok: true };
}
