"use client";

import { Menu, X } from "lucide-react";
import { useState } from "react";
import { LogoMark } from "@/components/logo-mark";
import { ghostCtaClass, solidNavCtaClass } from "@/lib/styles";
import { ctaHref } from "@/lib/url";
import type { SiteConfig } from "@/lib/types";

const links = [
  { key: "features", href: "#features" },
  { key: "comparison", href: "#comparison" },
  { key: "pricing", href: "#pricing" },
  { key: "security", href: "#security" },
] as const;

export function SiteHeader({ config }: { config: SiteConfig }) {
  const [open, setOpen] = useState(false);

  return (
    <header className="border-b border-slate-200/80 bg-white/85 backdrop-blur-md">
      <div className="mx-auto max-w-6xl px-5 py-3">
        <div className="flex items-center justify-between gap-3 lg:grid lg:grid-cols-[1fr_auto_1fr] lg:items-center">
          <a href="#top" className="flex min-w-0 items-center gap-2.5">
            <LogoMark className="h-9 w-9 shrink-0" />
            <span className="truncate text-lg font-semibold tracking-tight text-slate-900">
              {config.brandName}
            </span>
            <span className="shrink-0 rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-800 ring-1 ring-emerald-200">
              {config.productBadge}
            </span>
          </a>

          <nav
            aria-label="Page"
            className="hidden items-center justify-center gap-6 lg:flex"
          >
            {links.map((link) => (
              <a
                key={link.key}
                href={link.href}
                className="text-sm font-medium text-slate-600 transition hover:text-indigo-700"
              >
                {config.nav[link.key]}
              </a>
            ))}
          </nav>

          <div className="flex items-center justify-end gap-1 sm:gap-2">
            <a
              href={ctaHref(config.targetUrl)}
              className={ghostCtaClass}
              data-testid="sign-in"
            >
              {config.signInLabel}
            </a>
            <a
              href={ctaHref(config.targetUrl)}
              className={solidNavCtaClass}
              data-testid="workspace"
            >
              {config.workspaceLabel}
            </a>
            <button
              type="button"
              className="inline-flex h-11 w-11 items-center justify-center rounded-full text-slate-700 hover:bg-slate-100 lg:hidden"
              aria-expanded={open}
              aria-controls="mobile-nav"
              onClick={() => setOpen((value) => !value)}
            >
              {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              <span className="sr-only">{open ? "Close menu" : "Open menu"}</span>
            </button>
          </div>
        </div>

        {open ? (
          <nav
            id="mobile-nav"
            aria-label="Page"
            className="mt-3 flex flex-col border-t border-slate-100 pt-2 lg:hidden"
          >
            {links.map((link) => (
              <a
                key={link.key}
                href={link.href}
                className="rounded-xl px-2 py-3 text-base font-medium text-slate-800 hover:bg-indigo-50"
                onClick={() => setOpen(false)}
              >
                {config.nav[link.key]}
              </a>
            ))}
          </nav>
        ) : null}
      </div>
    </header>
  );
}
