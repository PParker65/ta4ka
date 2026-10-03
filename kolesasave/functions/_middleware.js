import { corsHeaders, json } from "./lib/auth.js";
import { ensureSchema } from "./lib/db.js";
import { isPublicDocument, recordPageHit } from "./lib/stats.js";

export async function onRequest(context) {
  const url = new URL(context.request.url);
  if (isPublicDocument(url.pathname, context.request)) {
    const job = recordPageHit(context).catch(() => {});
    if (typeof context.waitUntil === "function") context.waitUntil(job);
  }
  if (!url.pathname.startsWith("/api/")) {
    return context.next();
  }
  if (context.request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(context.request) });
  }
  try {
    await ensureSchema(context.env);
  } catch (err) {
    if (err && err.code === "d1") {
      return json({ error: "d1" }, 503, context.request);
    }
    throw err;
  }
  const res = await context.next();
  const headers = new Headers(res.headers);
  for (const [key, value] of Object.entries(corsHeaders(context.request))) {
    headers.set(key, value);
  }
  return new Response(res.body, { status: res.status, headers });
}
