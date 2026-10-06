import type { Metadata } from "next";
import { LandingPage } from "@/components/landing-page";
import { readConfig } from "@/lib/config";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const config = await readConfig();
  return {
    title: `${config.brandName} — Accounting and invoicing`,
    description: config.heroSubheadline,
  };
}

export default async function HomePage() {
  const config = await readConfig();
  return <LandingPage config={config} />;
}
