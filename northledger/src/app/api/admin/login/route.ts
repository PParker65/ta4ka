import { NextResponse } from "next/server";
import {
  applySessionCookie,
  credentialsMatch,
  expectedSessionToken,
} from "@/lib/auth";

export const runtime = "nodejs";

export async function POST(req: Request) {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request." }, { status: 400 });
  }

  const username =
    typeof body === "object" &&
    body !== null &&
    "username" in body &&
    typeof body.username === "string"
      ? body.username
      : "";
  const password =
    typeof body === "object" &&
    body !== null &&
    "password" in body &&
    typeof body.password === "string"
      ? body.password
      : "";

  if (!credentialsMatch(username, password)) {
    return NextResponse.json(
      { error: "Incorrect username or password." },
      { status: 401 },
    );
  }

  const expected = expectedSessionToken();

  const res = NextResponse.json({ ok: true });
  res.headers.set("Cache-Control", "no-store");
  applySessionCookie(res, req, expected);
  return res;
}
