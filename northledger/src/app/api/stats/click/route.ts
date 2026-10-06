import { NextResponse } from "next/server";
import { isAuthed } from "@/lib/auth";
import { incrementStat } from "@/lib/stats";

export const runtime = "nodejs";

export async function POST() {
  if (!(await isAuthed())) {
    await incrementStat("clicks");
  }
  return NextResponse.json(
    { ok: true },
    { headers: { "Cache-Control": "no-store" } },
  );
}
