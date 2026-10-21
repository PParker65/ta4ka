import { handleRequest, handleScheduled } from "./app.js";

export default {
  async fetch(request, env) {
    if (!env.DB) return new Response("Database is not bound", { status: 500 });
    return handleRequest(request, { db: env.DB, env, assets: env.ASSETS });
  },
  async scheduled(_event, env, ctx) {
    if (!env.DB) return;
    ctx.waitUntil(handleScheduled(env.DB, env));
  },
};
