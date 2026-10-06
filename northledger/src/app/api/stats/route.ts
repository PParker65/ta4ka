import { NextResponse } from "next/server";
import { isAuthed } from "@/lib/auth";
import { readStats } from "@/lib/stats";

export const runtime = "nodejs";

export async function GET() {
  if (!(await isAuthed())) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }
  const stats = await readStats();
  return NextResponse.json(
    { stats },
    { headers: { "Cache-Control": "no-store" } },
  );
}
