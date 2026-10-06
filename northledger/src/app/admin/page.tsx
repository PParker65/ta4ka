import type { Metadata } from "next";
import { AdminApp } from "@/components/admin-app";
import { isAuthed } from "@/lib/auth";
import { readConfig } from "@/lib/config";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Admin",
  robots: { index: false, follow: false },
};

export default async function AdminPage() {
  const authed = await isAuthed();
  const config = authed ? await readConfig() : null;
  return <AdminApp initialAuthed={authed} initialConfig={config} />;
}
