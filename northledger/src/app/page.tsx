import type { Metadata } from "next";
import { PortalButton, VisitBeacon } from "@/components/gateway-client";
import { readConfig } from "@/lib/config";
import { ctaHref } from "@/lib/url";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Sign In to Accounting Portal",
  description:
    "Click below to authenticate and enter your unified business workspace.",
};

export default async function HomePage() {
  const config = await readConfig();
  const href = ctaHref(config.targetUrl);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-slate-100 px-4 py-10">
      <header className="mb-6 flex items-center gap-2.5">
        <p className="text-xl font-semibold tracking-tight text-slate-900">
          FastBookkeeper
        </p>
        <span className="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-800 ring-1 ring-indigo-200">
          SSL Secured
        </span>
      </header>

      <main className="w-full max-w-md rounded-2xl border border-slate-200 bg-white px-6 py-8 shadow-[0_20px_50px_-28px_rgba(15,23,42,0.45)] sm:px-8">
        <p className="inline-flex rounded-full bg-indigo-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.12em] text-indigo-800">
          Secure Session Gateway
        </p>
        <h1 className="mt-4 text-2xl font-semibold tracking-tight text-slate-950">
          Sign In to Accounting Portal
        </h1>
        <p className="mt-2 text-base leading-relaxed text-slate-600">
          Click below to authenticate and enter your unified business workspace.
        </p>
        <VisitBeacon />
        <PortalButton href={href} />
        <p className="mt-6 text-center text-xs leading-relaxed text-slate-500">
          Protected by Enterprise Security • Fast Auto-Redirect
        </p>
      </main>
    </div>
  );
}
