import { ArrowRight, Check, Star } from "lucide-react";
import { LogoMark } from "@/components/logo-mark";
import { SiteHeader } from "@/components/site-header";
import { featureIconMap, securityIconMap } from "@/lib/icons";
import { primaryCtaClass, secondaryCtaClass } from "@/lib/styles";
import { ctaHref } from "@/lib/url";
import type { SiteConfig } from "@/lib/types";

const sampleRows = [
  { name: "Harbor Studio", meta: "Invoice 1842", amount: "$2,400", state: "Paid" },
  { name: "City Fleet", meta: "Expense batch", amount: "$860", state: "Review" },
  { name: "Tax packet", meta: "Q1 close", amount: "Ready", state: "Filed" },
];

const bars = ["42%", "58%", "50%", "74%", "66%", "90%"];

export function LandingPage({ config }: { config: SiteConfig }) {
  const year = new Date().getFullYear();

  return (
    <div id="top" className="min-h-screen bg-slate-50 text-slate-900">
      <div className="sticky top-0 z-40">
        <a
          href={ctaHref(config.targetUrl)}
          data-testid="banner-link"
          className="relative block bg-indigo-50 text-center text-indigo-950 shadow-[0_10px_40px_-18px_rgba(79,70,229,0.65)] ring-1 ring-inset ring-indigo-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-indigo-600"
        >
          <span className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(99,102,241,0.22),transparent_68%)]" />
          <span className="relative block px-4 py-2.5 text-sm font-medium sm:text-[0.95rem]">
            {config.bannerText}
          </span>
        </a>
        <SiteHeader config={config} />
      </div>

      <main>
        <section className="relative overflow-hidden">
          <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(199,210,254,0.7),transparent_46%),radial-gradient(ellipse_at_bottom_right,rgba(167,243,208,0.55),transparent_42%)]" />
          <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-5 py-16 lg:grid-cols-[1.08fr_0.92fr] lg:py-24">
            <div>
              <p className="inline-flex max-w-xl rounded-2xl bg-white/90 px-3 py-1.5 text-sm font-medium leading-snug text-indigo-950 shadow-sm ring-1 ring-indigo-100">
                {config.heroBadge}
              </p>
              <h1 className="mt-6 max-w-xl font-display text-4xl leading-[1.08] tracking-tight text-slate-950 sm:text-5xl lg:text-[3.35rem]">
                {config.heroHeadline}
              </h1>
              <p className="mt-5 max-w-xl text-lg leading-relaxed text-slate-600">
                {config.heroSubheadline}
              </p>
              <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
                <a
                  href={ctaHref(config.targetUrl)}
                  className={primaryCtaClass}
                  data-testid="hero-primary-cta"
                >
                  {config.primaryCtaLabel}
                  <ArrowRight className="h-4 w-4 transition motion-safe:group-hover:translate-x-0.5" />
                </a>
                <a
                  href={ctaHref(config.targetUrl)}
                  className={secondaryCtaClass}
                  data-testid="hero-secondary-cta"
                >
                  {config.secondaryCtaLabel}
                </a>
              </div>
              <div className="mt-8 space-y-2">
                <p className="flex flex-wrap items-center gap-x-2 gap-y-1 text-sm text-slate-700">
                  <span className="flex text-amber-400" aria-hidden="true">
                    {Array.from({ length: 5 }, (_, index) => (
                      <Star key={index} className="h-4 w-4 fill-current" />
                    ))}
                  </span>
                  <span className="font-semibold text-slate-900">
                    {config.trustRating}
                  </span>
                  <span className="text-slate-300" aria-hidden="true">
                    ·
                  </span>
                  <span>{config.trustCount}</span>
                </p>
                <p className="text-sm text-slate-500">{config.trustMicro}</p>
              </div>
            </div>

            <aside className="relative" aria-hidden="true">
              <div className="absolute -inset-8 -z-10 rounded-[2.5rem] bg-gradient-to-br from-indigo-200/80 via-white to-emerald-200/70 blur-2xl" />
              <div className="rounded-[1.75rem] border border-white/80 bg-white/90 p-4 shadow-[0_30px_80px_-36px_rgba(49,46,129,0.55)] ring-1 ring-slate-200/80 sm:p-5">
                <div className="flex items-center justify-between gap-3 px-1">
                  <p className="text-sm font-semibold text-slate-800">Sample workspace</p>
                  <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-800 ring-1 ring-emerald-100">
                    Browser ledger
                  </span>
                </div>
                <div className="mt-4 space-y-2">
                  {sampleRows.map((row) => (
                    <div
                      key={row.name}
                      className="flex items-center justify-between gap-3 rounded-2xl bg-slate-50 px-3 py-3 ring-1 ring-slate-100"
                    >
                      <div>
                        <p className="text-sm font-semibold text-slate-900">{row.name}</p>
                        <p className="text-xs text-slate-500">{row.meta}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-semibold text-slate-900">{row.amount}</p>
                        <p className="text-xs font-medium text-emerald-700">{row.state}</p>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-4 flex h-24 items-end gap-2 rounded-2xl bg-slate-950 px-4 py-3">
                  {bars.map((height, index) => (
                    <span
                      key={height}
                      className={
                        index === bars.length - 1
                          ? "flex-1 rounded-t-md bg-emerald-400"
                          : "flex-1 rounded-t-md bg-indigo-400/80"
                      }
                      style={{ height }}
                    />
                  ))}
                </div>
              </div>
            </aside>
          </div>
        </section>

        <section id="comparison" className="mx-auto max-w-6xl px-5 py-16 sm:py-20">
          <div className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-[0.16em] text-indigo-600">
              {config.nav.comparison}
            </p>
            <h2 className="mt-3 font-display text-3xl tracking-tight text-slate-950 sm:text-4xl">
              {config.comparisonTitle}
            </h2>
            <p className="mt-4 text-lg leading-relaxed text-slate-600">
              {config.comparisonSubtitle}
            </p>
          </div>

          <div className="mt-8 max-h-[70vh] overflow-auto rounded-3xl border border-slate-200 bg-white shadow-[0_20px_50px_-32px_rgba(15,23,42,0.45)]">
            <table className="w-full min-w-[720px] border-collapse text-left">
              <caption className="sr-only">
                Comparison of {config.brandName} and {config.comparisonLegacyLabel}
              </caption>
              <thead className="sticky top-0 z-10">
                <tr>
                  <th
                    scope="col"
                    className="sticky left-0 z-20 bg-slate-900 px-4 py-4 text-sm font-semibold text-white"
                  >
                    {config.comparisonCapabilityLabel}
                  </th>
                  <th
                    scope="col"
                    className="bg-indigo-700 px-4 py-4 text-sm font-semibold text-white"
                  >
                    {config.brandName}
                  </th>
                  <th
                    scope="col"
                    className="bg-slate-100 px-4 py-4 text-sm font-semibold text-slate-600"
                  >
                    {config.comparisonLegacyLabel}
                  </th>
                </tr>
              </thead>
              <tbody>
                {config.comparisonRows.map((row) => (
                  <tr key={row.capability} className="border-t border-slate-100">
                    <th
                      scope="row"
                      className="sticky left-0 bg-white px-4 py-4 text-sm font-semibold text-slate-900"
                    >
                      {row.capability}
                    </th>
                    <td className="bg-indigo-50/70 px-4 py-4 text-sm font-medium text-slate-900">
                      <span className="flex items-start gap-2">
                        <Check
                          className="mt-0.5 h-4 w-4 shrink-0 text-emerald-600"
                          aria-hidden="true"
                        />
                        {row.product}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-sm text-slate-500">{row.legacy}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="mt-4 text-sm text-slate-500">{config.comparisonNote}</p>
        </section>

        <section id="features" className="bg-white py-16 sm:py-20">
          <div className="mx-auto max-w-6xl px-5">
            <div className="max-w-2xl">
              <p className="text-sm font-semibold uppercase tracking-[0.16em] text-indigo-600">
                {config.nav.features}
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight text-slate-950 sm:text-4xl">
                {config.featuresTitle}
              </h2>
              <p className="mt-4 text-lg leading-relaxed text-slate-600">
                {config.featuresSubtitle}
              </p>
            </div>
            <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {config.features.map((feature) => {
                const Icon = featureIconMap[feature.icon];
                return (
                  <article
                    key={feature.title}
                    className="rounded-3xl border border-slate-200 bg-slate-50/60 p-5 shadow-sm transition motion-safe:hover:-translate-y-1 hover:bg-white hover:shadow-md"
                  >
                    <span className="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-indigo-50 text-indigo-700 ring-1 ring-indigo-100">
                      <Icon className="h-5 w-5" aria-hidden="true" />
                    </span>
                    <h3 className="mt-4 text-lg font-semibold text-slate-950">
                      {feature.title}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed text-slate-600">
                      {feature.description}
                    </p>
                  </article>
                );
              })}
            </div>
          </div>
        </section>

        <section id="pricing" className="mx-auto max-w-6xl px-5 py-16 sm:py-20">
          <div className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-[0.16em] text-indigo-600">
              {config.nav.pricing}
            </p>
            <h2 className="mt-3 font-display text-3xl tracking-tight text-slate-950 sm:text-4xl">
              {config.pricingTitle}
            </h2>
            <p className="mt-4 text-lg leading-relaxed text-slate-600">
              {config.pricingSubtitle}
            </p>
          </div>
          <div className="mt-10 grid items-stretch gap-5 lg:grid-cols-3">
            {config.pricingTiers.map((tier, index) => (
              <article
                key={tier.name}
                className={
                  tier.highlighted
                    ? "relative flex flex-col rounded-3xl border border-indigo-200 bg-white p-6 shadow-[0_24px_60px_-28px_rgba(79,70,229,0.55)] ring-2 ring-indigo-500"
                    : "relative flex flex-col rounded-3xl border border-slate-200 bg-white p-6 shadow-sm"
                }
              >
                {tier.badge ? (
                  <span className="absolute -top-3 left-6 rounded-full bg-indigo-600 px-3 py-1 text-xs font-semibold text-white">
                    {tier.badge}
                  </span>
                ) : null}
                <h3 className="text-lg font-semibold text-slate-950">{tier.name}</h3>
                <p className="mt-4 flex items-end gap-2">
                  <span className="font-display text-5xl tracking-tight text-slate-950">
                    {tier.price}
                  </span>
                  <span className="mb-1 text-sm text-slate-500">{tier.period}</span>
                </p>
                <p className="mt-3 text-sm leading-relaxed text-slate-600">
                  {tier.description}
                </p>
                <ul className="mt-5 flex-1 space-y-2 text-sm text-slate-700">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2">
                      <Check
                        className="mt-0.5 h-4 w-4 shrink-0 text-emerald-600"
                        aria-hidden="true"
                      />
                      {feature}
                    </li>
                  ))}
                </ul>
                <a
                  href={ctaHref(config.targetUrl)}
                  data-testid={`pricing-cta-${index}`}
                  className={
                    tier.highlighted
                      ? `${primaryCtaClass} mt-6 w-full`
                      : `${secondaryCtaClass} mt-6 w-full`
                  }
                >
                  {tier.ctaLabel}
                </a>
              </article>
            ))}
          </div>
          <p className="mt-6 text-sm text-slate-500">{config.pricingNote}</p>
        </section>

        <section id="security" className="bg-slate-950 py-16 text-white sm:py-20">
          <div className="mx-auto max-w-6xl px-5">
            <div className="max-w-2xl">
              <p className="text-sm font-semibold uppercase tracking-[0.16em] text-emerald-300">
                {config.nav.security}
              </p>
              <h2 className="mt-3 font-display text-3xl tracking-tight sm:text-4xl">
                {config.securityTitle}
              </h2>
              <p className="mt-4 text-lg leading-relaxed text-slate-300">
                {config.securitySubtitle}
              </p>
            </div>
            <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {config.securityItems.map((item) => {
                const Icon = securityIconMap[item.icon];
                return (
                  <article
                    key={item.title}
                    className="rounded-3xl border border-white/10 bg-white/5 p-5"
                  >
                    <span className="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-emerald-400/10 text-emerald-300 ring-1 ring-emerald-300/20">
                      <Icon className="h-5 w-5" aria-hidden="true" />
                    </span>
                    <h3 className="mt-4 text-lg font-semibold">{item.title}</h3>
                    <p className="mt-2 text-sm leading-relaxed text-slate-300">
                      {item.description}
                    </p>
                  </article>
                );
              })}
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-slate-800 bg-slate-950 text-slate-300">
        <div className="mx-auto max-w-6xl px-5 py-12">
          <div className="flex flex-col gap-8 sm:flex-row sm:items-start sm:justify-between">
            <div className="flex items-center gap-3">
              <LogoMark className="h-9 w-9" />
              <div>
                <p className="text-lg font-semibold text-white">{config.brandName}</p>
                <p className="text-sm text-slate-400">{config.productBadge}</p>
              </div>
            </div>
            <nav aria-label="Footer" className="flex flex-wrap gap-x-5 gap-y-2 text-sm">
              <a className="hover:text-white" href="#features">
                {config.nav.features}
              </a>
              <a className="hover:text-white" href="#comparison">
                {config.nav.comparison}
              </a>
              <a className="hover:text-white" href="#pricing">
                {config.nav.pricing}
              </a>
              <a className="hover:text-white" href="#security">
                {config.nav.security}
              </a>
            </nav>
          </div>
          <p className="mt-10 max-w-3xl text-sm leading-relaxed text-slate-400">
            {config.footerDisclaimer}
          </p>
          <p className="mt-6 text-xs text-slate-500">
            © {year} {config.brandName}
          </p>
        </div>
      </footer>
    </div>
  );
}
