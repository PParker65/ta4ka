import { createHash, timingSafeEqual } from "crypto";
import { cookies } from "next/headers";
import { NextResponse } from "next/server";

export const SESSION_COOKIE = "nl_sess";

const DEV_ONLY_USER = "admin";
const DEV_ONLY_PASSWORD = "admin1";

export function getAdminUser(): string {
  const fromEnv = process.env.ADMIN_USER?.trim();
  return fromEnv ? fromEnv : DEV_ONLY_USER;
}

export function getAdminPassword(): string {
  const fromEnv = process.env.ADMIN_PASSWORD?.trim();
  return fromEnv ? fromEnv : DEV_ONLY_PASSWORD;
}

export function sha256Hex(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

export function expectedSessionToken(): string {
  const passwordHash = sha256Hex(getAdminPassword());
  return sha256Hex(`${getAdminUser()}:${passwordHash}`);
}

export function credentialsMatch(username: string, password: string): boolean {
  const userOk = safeEqualHex(sha256Hex(username), sha256Hex(getAdminUser()));
  const passwordHash = sha256Hex(password);
  const passOk = safeEqualHex(passwordHash, sha256Hex(getAdminPassword()));
  return userOk && passOk;
}

export function safeEqualHex(left: string, right: string): boolean {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

export function requestIsSecure(req: Request): boolean {
  const forwarded = req.headers.get("x-forwarded-proto");
  if (forwarded) {
    return forwarded.split(",")[0]?.trim() === "https";
  }
  return new URL(req.url).protocol === "https:";
}

function cookieOptions(req: Request, maxAge: number) {
  return {
    httpOnly: true,
    sameSite: "lax" as const,
    secure: requestIsSecure(req),
    path: "/",
    maxAge,
  };
}

export function applySessionCookie(res: NextResponse, req: Request, token: string) {
  res.cookies.set(SESSION_COOKIE, token, cookieOptions(req, 60 * 60 * 24 * 14));
}

export function clearSessionCookie(res: NextResponse, req: Request) {
  res.cookies.set(SESSION_COOKIE, "", cookieOptions(req, 0));
}

export async function isAuthed(): Promise<boolean> {
  const jar = await cookies();
  const session = jar.get(SESSION_COOKIE)?.value;
  if (!session) return false;
  return safeEqualHex(session, expectedSessionToken());
}
