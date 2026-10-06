import { NextResponse } from "next/server";
import { clearSessionCookie } from "@/lib/auth";

export const runtime = "nodejs";

export async function POST(req: Request) {
  const res = NextResponse.json({ ok: true });
  res.headers.set("Cache-Control", "no-store");
  clearSessionCookie(res, req);
  return res;
}
