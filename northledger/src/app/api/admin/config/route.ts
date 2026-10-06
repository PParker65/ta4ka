import { NextResponse } from "next/server";
import { isAuthed } from "@/lib/auth";
import { readConfig, writeConfig } from "@/lib/config";
import { validateConfig } from "@/lib/validate";

export const runtime = "nodejs";

export async function GET() {
  if (!(await isAuthed())) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }
  const config = await readConfig();
  return NextResponse.json(
    { config },
    { headers: { "Cache-Control": "no-store" } },
  );
}

export async function PUT(req: Request) {
  if (!(await isAuthed())) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request." }, { status: 400 });
  }

  const result = validateConfig(body);
  if (!result.ok) {
    return NextResponse.json({ error: result.error }, { status: 400 });
  }

  await writeConfig(result.config);
  return NextResponse.json(
    { ok: true, config: result.config },
    { headers: { "Cache-Control": "no-store" } },
  );
}
