"use client";

import { useEffect } from "react";

export function VisitBeacon() {
  useEffect(() => {
    const now = Date.now();
    const last = Number(window.sessionStorage.getItem("fb-visit-at") || "0");
    if (Number.isFinite(last) && now - last < 1500) return;
    window.sessionStorage.setItem("fb-visit-at", String(now));
    fetch("/api/stats/visit", { method: "POST", keepalive: true }).catch(() => undefined);
  }, []);

  return null;
}

export function PortalButton({ href }: { href: string }) {
  async function handleRedirect() {
    try {
      await fetch("/api/stats/click", { method: "POST", keepalive: true });
    } catch {
      // Navigation still happens if the counter request fails.
    }
    window.location.assign(href);
  }

  return (
    <button
      type="button"
      onClick={handleRedirect}
      data-testid="portal-signin"
      className="flex w-full items-center justify-center space-x-2 rounded-lg bg-[#0077C5] px-4 py-3.5 text-base font-semibold text-white shadow-md transition-all duration-200 hover:bg-[#005FA3] hover:shadow-lg motion-reduce:transform-none motion-reduce:transition-none active:scale-[0.99]"
    >
      <span>Continue to Portal Sign-In</span>
      <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
      </svg>
    </button>
  );
}
