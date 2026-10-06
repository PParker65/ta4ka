"use client";

import { useEffect, type MouseEvent } from "react";

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
  async function onClick(event: MouseEvent<HTMLAnchorElement>) {
    if (
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey
    ) {
      return;
    }
    event.preventDefault();
    try {
      await fetch("/api/stats/click", { method: "POST", keepalive: true });
    } catch {
      // The link still opens if the counter request fails.
    }
    window.location.assign(href);
  }

  return (
    <a
      href={href}
      onClick={onClick}
      data-testid="portal-signin"
      className="mt-6 flex w-full items-center justify-center rounded-xl bg-blue-700 px-4 py-3.5 text-base font-semibold text-white shadow-sm transition hover:bg-blue-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-700"
    >
      Continue to Portal Sign-In →
    </a>
  );
}
