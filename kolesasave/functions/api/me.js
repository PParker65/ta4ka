import { json, requireUser } from "../lib/auth.js";

export async function onRequestGet(context) {
  const gate = await requireUser(context);
  if (gate.error) return gate.error;
  return json(
    { email: gate.user.email, shopName: gate.user.shop_name || "" },
    200,
    context.request,
  );
}
