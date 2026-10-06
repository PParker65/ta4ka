"use client";

import Link from "next/link";
import { useEffect, useId, useState, type FormEvent, type ReactNode } from "react";
import { LogoMark } from "@/components/logo-mark";
import { featureIconLabels, securityIconLabels } from "@/lib/icons";
import { inputClass, primaryCtaClass } from "@/lib/styles";
import {
  FEATURE_ICON_NAMES,
  SECURITY_ICON_NAMES,
  type ComparisonRow,
  type FeatureItem,
  type PricingTier,
  type SecurityItem,
  type SiteConfig,
} from "@/lib/types";
import { ctaHref, isHttpUrl } from "@/lib/url";
import type { SiteStats } from "@/lib/stats";

export function AdminApp({
  initialAuthed,
  initialConfig,
  initialStats,
}: {
  initialAuthed: boolean;
  initialConfig: SiteConfig | null;
  initialStats: SiteStats | null;
}) {
  const [authed, setAuthed] = useState(initialAuthed);
  const [config, setConfig] = useState<SiteConfig | null>(initialConfig);

  if (!authed || !config) {
    return (
      <LoginScreen
        onSuccess={(next) => {
          setConfig(next);
          setAuthed(true);
        }}
      />
    );
  }

  return (
    <Editor
      initial={config}
      initialStats={initialStats}
      onLogout={() => {
        setAuthed(false);
        setConfig(null);
      }}
    />
  );
}

function LoginScreen({ onSuccess }: { onSuccess: (config: SiteConfig) => void }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const usernameId = useId();
  const passwordId = useId();

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setPending(true);
    try {
      const login = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
      if (!login.ok) {
        const data: unknown = await login.json().catch(() => null);
        setError(readError(data) ?? "Incorrect username or password.");
        return;
      }
      const configRes = await fetch("/api/admin/config");
      const data: unknown = await configRes.json().catch(() => null);
      if (!configRes.ok || !isConfigPayload(data)) {
        setError("Signed in, but the config could not be loaded.");
        return;
      }
      onSuccess(data.config);
    } catch {
      setError("Could not reach the server.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-5 py-16">
      <form
        onSubmit={onSubmit}
        className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-[0_24px_60px_-32px_rgba(15,23,42,0.4)] sm:p-8"
      >
        <div className="flex items-center gap-3">
          <LogoMark className="h-10 w-10" />
          <div>
            <p className="text-lg font-semibold text-slate-950">Site admin</p>
            <p className="text-sm text-slate-500">Editors only</p>
          </div>
        </div>
        <label htmlFor={usernameId} className="mt-6 block text-sm font-medium text-slate-700">
          Username
          <input
            id={usernameId}
            data-testid="admin-username"
            type="text"
            autoComplete="username"
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            className={inputClass}
            required
          />
        </label>
        <label htmlFor={passwordId} className="mt-4 block text-sm font-medium text-slate-700">
          Password
          <input
            id={passwordId}
            data-testid="admin-password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className={inputClass}
            required
          />
        </label>
        <p className="mt-3 text-sm text-slate-500">
          Development credentials are documented in .env.example. Replace ADMIN_USER and ADMIN_PASSWORD before a real deployment.
        </p>
        {error ? (
          <p role="alert" className="mt-3 text-sm text-rose-700">
            {error}
          </p>
        ) : null}
        <button
          type="submit"
          data-testid="admin-login"
          disabled={pending}
          className={`${primaryCtaClass} mt-6 w-full disabled:opacity-60`}
        >
          {pending ? "Checking…" : "Continue"}
        </button>
      </form>
    </div>
  );
}

function Editor({
  initial,
  initialStats,
  onLogout,
}: {
  initial: SiteConfig;
  initialStats: SiteStats | null;
  onLogout: () => void;
}) {
  const [draft, setDraft] = useState(initial);
  const [previewUrl, setPreviewUrl] = useState(initial.targetUrl);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    const handle = window.setTimeout(() => setPreviewUrl(draft.targetUrl), 350);
    return () => window.clearTimeout(handle);
  }, [draft.targetUrl]);

  function patch(partial: Partial<SiteConfig>) {
    setDraft((current) => ({ ...current, ...partial }));
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setMessage(null);
    const trimmedTarget = draft.targetUrl.trim();
    if (trimmedTarget !== "" && trimmedTarget !== "#" && !isHttpUrl(trimmedTarget)) {
      setError("Target URL must be blank, #, or an http or https URL.");
      return;
    }
    setSaving(true);
    try {
      const res = await fetch("/api/admin/config", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(draft),
      });
      const data: unknown = await res.json().catch(() => null);
      if (!res.ok || !isConfigPayload(data)) {
        setError(readError(data) ?? "Could not save.");
        return;
      }
      setDraft(data.config);
      setMessage("Saved. The public page is using these values.");
    } catch {
      setError("Could not reach the server.");
    } finally {
      setSaving(false);
    }
  }

  async function logout() {
    await fetch("/api/admin/logout", { method: "POST" });
    onLogout();
  }

  const previewReady = isHttpUrl(previewUrl);

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-5 py-4">
          <div className="flex items-center gap-3">
            <LogoMark className="h-9 w-9" />
            <div>
              <p className="text-lg font-semibold text-slate-950">Site settings</p>
              <p className="text-sm text-slate-500">{draft.brandName}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Link
              href="/"
              className="inline-flex min-h-11 items-center rounded-full px-4 text-sm font-semibold text-slate-700 hover:bg-slate-100"
            >
              View public page
            </Link>
            <button
              type="button"
              onClick={() => void logout()}
              className="inline-flex min-h-11 items-center rounded-full border border-slate-200 px-4 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              Log out
            </button>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-6xl px-5 pt-8">
        <StatsPanel initialStats={initialStats} />
      </div>

      <div className="mx-auto grid max-w-6xl gap-6 px-5 py-8 lg:grid-cols-[minmax(0,1fr)_320px]">
        <form onSubmit={onSubmit} className="space-y-5">
          <Section title="Destination and calls to action">
            <Field
              label="Target URL"
              value={draft.targetUrl}
              onChange={(targetUrl) => patch({ targetUrl })}
              testId="target-url"
              optional
              hint="Paste the destination when you have it. Blank and # keep every button on this page. An http(s) URL opens in the same tab."
            />
            <Field
              label="Banner text"
              value={draft.bannerText}
              onChange={(bannerText) => patch({ bannerText })}
              multiline
            />
            <div className="grid gap-4 sm:grid-cols-2">
              <Field
                label="Brand name"
                value={draft.brandName}
                onChange={(brandName) => patch({ brandName })}
                testId="brand-name"
              />
              <Field
                label="Product badge"
                value={draft.productBadge}
                onChange={(productBadge) => patch({ productBadge })}
              />
              <Field
                label="Primary CTA"
                value={draft.primaryCtaLabel}
                onChange={(primaryCtaLabel) => patch({ primaryCtaLabel })}
                testId="primary-cta-label"
              />
              <Field
                label="Secondary CTA"
                value={draft.secondaryCtaLabel}
                onChange={(secondaryCtaLabel) => patch({ secondaryCtaLabel })}
                testId="secondary-cta-label"
                hint="Web app label. This is not a file download."
              />
              <Field
                label="Sign-in button"
                value={draft.signInLabel}
                onChange={(signInLabel) => patch({ signInLabel })}
              />
              <Field
                label="Workspace button"
                value={draft.workspaceLabel}
                onChange={(workspaceLabel) => patch({ workspaceLabel })}
              />
            </div>
          </Section>

          <Section title="Hero">
            <Field
              label="Hero badge"
              value={draft.heroBadge}
              onChange={(heroBadge) => patch({ heroBadge })}
              multiline
            />
            <Field
              label="Headline"
              value={draft.heroHeadline}
              onChange={(heroHeadline) => patch({ heroHeadline })}
              testId="hero-headline"
            />
            <Field
              label="Subheadline"
              value={draft.heroSubheadline}
              onChange={(heroSubheadline) => patch({ heroSubheadline })}
              multiline
            />
            <div className="grid gap-4 sm:grid-cols-2">
              <Field
                label="Trust rating"
                value={draft.trustRating}
                onChange={(trustRating) => patch({ trustRating })}
              />
              <Field
                label="Trust count"
                value={draft.trustCount}
                onChange={(trustCount) => patch({ trustCount })}
              />
            </div>
            <Field
              label="Trust micro copy"
              value={draft.trustMicro}
              onChange={(trustMicro) => patch({ trustMicro })}
            />
            <div className="grid gap-4 sm:grid-cols-2">
              {(
                [
                  ["features", "Features nav"],
                  ["comparison", "Comparison nav"],
                  ["pricing", "Pricing nav"],
                  ["security", "Security nav"],
                ] as const
              ).map(([key, label]) => (
                <Field
                  key={key}
                  label={label}
                  value={draft.nav[key]}
                  onChange={(value) =>
                    patch({ nav: { ...draft.nav, [key]: value } })
                  }
                />
              ))}
            </div>
          </Section>

          <Section title="Comparison">
            <Field
              label="Title"
              value={draft.comparisonTitle}
              onChange={(comparisonTitle) => patch({ comparisonTitle })}
            />
            <Field
              label="Subtitle"
              value={draft.comparisonSubtitle}
              onChange={(comparisonSubtitle) => patch({ comparisonSubtitle })}
              multiline
            />
            <div className="grid gap-4 sm:grid-cols-2">
              <Field
                label="Capability column"
                value={draft.comparisonCapabilityLabel}
                onChange={(comparisonCapabilityLabel) =>
                  patch({ comparisonCapabilityLabel })
                }
              />
              <Field
                label="Legacy column"
                value={draft.comparisonLegacyLabel}
                onChange={(comparisonLegacyLabel) =>
                  patch({ comparisonLegacyLabel })
                }
              />
            </div>
            <div className="space-y-3">
              {draft.comparisonRows.map((row, index) => (
                <div
                  key={index}
                  className="grid gap-3 rounded-2xl bg-slate-50 p-3 sm:grid-cols-3"
                >
                  <Field
                    label={`Row ${index + 1} capability`}
                    value={row.capability}
                    onChange={(capability) =>
                      updateRow(setDraft, index, { capability })
                    }
                  />
                  <Field
                    label="Product"
                    value={row.product}
                    onChange={(product) => updateRow(setDraft, index, { product })}
                  />
                  <Field
                    label="Legacy"
                    value={row.legacy}
                    onChange={(legacy) => updateRow(setDraft, index, { legacy })}
                  />
                </div>
              ))}
            </div>
            <Field
              label="Note under the table"
              value={draft.comparisonNote}
              onChange={(comparisonNote) => patch({ comparisonNote })}
              multiline
            />
          </Section>

          <Section title="Features">
            <Field
              label="Title"
              value={draft.featuresTitle}
              onChange={(featuresTitle) => patch({ featuresTitle })}
            />
            <Field
              label="Subtitle"
              value={draft.featuresSubtitle}
              onChange={(featuresSubtitle) => patch({ featuresSubtitle })}
              multiline
            />
            {draft.features.map((feature, index) => (
              <div key={index} className="grid gap-3 rounded-2xl bg-slate-50 p-3">
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field
                    label={`Feature ${index + 1} title`}
                    value={feature.title}
                    onChange={(title) => updateFeature(setDraft, index, { title })}
                  />
                  <label className="block text-sm font-medium text-slate-700">
                    Icon
                    <select
                      value={feature.icon}
                      onChange={(event) =>
                        updateFeature(setDraft, index, {
                          icon: event.target.value as FeatureItem["icon"],
                        })
                      }
                      className={inputClass}
                    >
                      {FEATURE_ICON_NAMES.map((name) => (
                        <option key={name} value={name}>
                          {featureIconLabels[name]}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>
                <Field
                  label="Description"
                  value={feature.description}
                  onChange={(description) =>
                    updateFeature(setDraft, index, { description })
                  }
                />
              </div>
            ))}
          </Section>

          <Section title="Pricing">
            <Field
              label="Title"
              value={draft.pricingTitle}
              onChange={(pricingTitle) => patch({ pricingTitle })}
            />
            <Field
              label="Subtitle"
              value={draft.pricingSubtitle}
              onChange={(pricingSubtitle) => patch({ pricingSubtitle })}
              multiline
            />
            <Field
              label="Note"
              value={draft.pricingNote}
              onChange={(pricingNote) => patch({ pricingNote })}
            />
            {draft.pricingTiers.map((tier, index) => (
              <div key={index} className="grid gap-3 rounded-2xl bg-slate-50 p-3">
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field
                    label="Plan name"
                    value={tier.name}
                    onChange={(name) => updateTier(setDraft, index, { name })}
                  />
                  <Field
                    label="Price"
                    value={tier.price}
                    onChange={(price) => updateTier(setDraft, index, { price })}
                  />
                  <Field
                    label="Period"
                    value={tier.period}
                    onChange={(period) => updateTier(setDraft, index, { period })}
                  />
                  <Field
                    label="Button label"
                    value={tier.ctaLabel}
                    onChange={(ctaLabel) => updateTier(setDraft, index, { ctaLabel })}
                  />
                </div>
                <Field
                  label="Description"
                  value={tier.description}
                  onChange={(description) =>
                    updateTier(setDraft, index, { description })
                  }
                />
                <Field
                  label="Badge"
                  value={tier.badge}
                  onChange={(badge) => updateTier(setDraft, index, { badge })}
                  hint="Leave blank to hide the badge."
                />
                <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                  <input
                    type="radio"
                    name="highlighted-tier"
                    className="h-4 w-4"
                    checked={tier.highlighted}
                    onChange={() => highlightTier(setDraft, index)}
                  />
                  Highlight this plan
                </label>
                <label className="block text-sm font-medium text-slate-700">
                  Feature lines
                  <textarea
                    value={tier.features.join("\n")}
                    onChange={(event) =>
                      updateTier(setDraft, index, {
                        features: event.target.value.split("\n"),
                      })
                    }
                    rows={4}
                    className={inputClass}
                  />
                </label>
              </div>
            ))}
          </Section>

          <Section title="Security and footer">
            <Field
              label="Title"
              value={draft.securityTitle}
              onChange={(securityTitle) => patch({ securityTitle })}
            />
            <Field
              label="Subtitle"
              value={draft.securitySubtitle}
              onChange={(securitySubtitle) => patch({ securitySubtitle })}
              multiline
            />
            {draft.securityItems.map((item, index) => (
              <div key={index} className="grid gap-3 rounded-2xl bg-slate-50 p-3">
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field
                    label={`Security ${index + 1} title`}
                    value={item.title}
                    onChange={(title) => updateSecurity(setDraft, index, { title })}
                  />
                  <label className="block text-sm font-medium text-slate-700">
                    Icon
                    <select
                      value={item.icon}
                      onChange={(event) =>
                        updateSecurity(setDraft, index, {
                          icon: event.target.value as SecurityItem["icon"],
                        })
                      }
                      className={inputClass}
                    >
                      {SECURITY_ICON_NAMES.map((name) => (
                        <option key={name} value={name}>
                          {securityIconLabels[name]}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>
                <Field
                  label="Description"
                  value={item.description}
                  onChange={(description) =>
                    updateSecurity(setDraft, index, { description })
                  }
                />
              </div>
            ))}
            <Field
              label="Footer disclaimer"
              value={draft.footerDisclaimer}
              onChange={(footerDisclaimer) => patch({ footerDisclaimer })}
              multiline
              hint="Keep the non-affiliation statement if the brand name changes."
            />
          </Section>

          <div className="sticky bottom-3 z-30 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-200 bg-white/95 px-4 py-3 shadow-lg backdrop-blur">
            <div className="min-h-5 text-sm">
              {error ? (
                <p role="alert" className="text-rose-700">
                  {error}
                </p>
              ) : null}
              {message ? (
                <p role="status" className="text-emerald-700">
                  {message}
                </p>
              ) : null}
              {!error && !message ? (
                <p className="text-slate-500">
                  Save to publish these values on the public page.
                </p>
              ) : null}
            </div>
            <button
              type="submit"
              data-testid="save-config"
              disabled={saving}
              className="inline-flex min-h-11 items-center rounded-full bg-indigo-600 px-5 text-base font-semibold text-white hover:bg-indigo-700 disabled:opacity-60"
            >
              {saving ? "Saving…" : "Save changes"}
            </button>
          </div>
        </form>

        <aside className="h-fit rounded-3xl border border-slate-200 bg-white p-4 shadow-sm lg:sticky lg:top-6">
          <h2 className="text-sm font-semibold text-slate-900">Target preview</h2>
          <p className="mt-2 break-all text-sm text-indigo-700">
            {previewReady ? (
              <a href={ctaHref(previewUrl)} data-testid="preview-link">
                {previewUrl}
              </a>
            ) : (
              "No destination yet. Public buttons stay on this page until you save an http(s) URL."
            )}
          </p>
          {previewReady ? (
            <iframe
              title="Live preview of the target URL"
              src={previewUrl}
              className="mt-3 h-64 w-full rounded-2xl border border-slate-200 bg-white"
              data-testid="target-preview"
            />
          ) : (
            <div className="mt-3 flex h-64 items-center justify-center rounded-2xl border border-dashed border-slate-200 px-4 text-center text-sm text-slate-500">
              Paste an http(s) URL to preview a destination. Until then, public buttons stay on this page.
            </div>
          )}
          <p className="mt-3 text-xs leading-relaxed text-slate-500">
            {previewReady
              ? "If a site blocks embedding, use the address link. Public calls to action use that same URL."
              : "Public buttons use the saved target. A blank value or # stays on this page."}
          </p>
          {previewReady ? (
            <a href={ctaHref(previewUrl)} className={`${primaryCtaClass} mt-4 w-full text-center`}>
              {draft.primaryCtaLabel}
            </a>
          ) : null}
        </aside>
      </div>
    </div>
  );
}

function StatsPanel({ initialStats }: { initialStats: SiteStats | null }) {
  const [stats, setStats] = useState<SiteStats | null>(initialStats);

  useEffect(() => {
    let cancelled = false;
    fetch("/api/stats")
      .then(async (res) => {
        if (!res.ok) return null;
        return res.json() as Promise<unknown>;
      })
      .then((data) => {
        if (!cancelled && isStatsPayload(data)) setStats(data.stats);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  const updated = stats?.updatedAt ? new Date(stats.updatedAt) : null;
  const updatedLabel =
    updated && !Number.isNaN(updated.getTime()) ? updated.toLocaleString() : null;

  return (
    <section className="grid gap-4 sm:grid-cols-2" data-testid="stats-panel">
      <article className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <p className="text-sm font-medium text-slate-500">Visits</p>
        <p className="text-sm text-slate-400">посещения</p>
        <p className="mt-2 font-display text-4xl text-slate-950" data-testid="stat-visits">
          {stats?.visits ?? 0}
        </p>
      </article>
      <article className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <p className="text-sm font-medium text-slate-500">Link clicks</p>
        <p className="text-sm text-slate-400">клики по ссылке</p>
        <p className="mt-2 font-display text-4xl text-slate-950" data-testid="stat-clicks">
          {stats?.clicks ?? 0}
        </p>
      </article>
      {updatedLabel ? (
        <p className="text-sm text-slate-500 sm:col-span-2">Updated {updatedLabel}</p>
      ) : null}
    </section>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="font-display text-2xl text-slate-950">{title}</h2>
      <div className="mt-4 grid gap-4">{children}</div>
    </section>
  );
}

function Field({
  label,
  value,
  onChange,
  multiline = false,
  testId,
  hint,
  optional = false,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  multiline?: boolean;
  testId?: string;
  hint?: string;
  optional?: boolean;
}) {
  const id = useId();
  return (
    <label htmlFor={id} className="block text-sm font-medium text-slate-700">
      {label}
      {multiline ? (
        <textarea
          id={id}
          data-testid={testId}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          rows={3}
          className={inputClass}
          required
        />
      ) : (
        <input
          id={id}
          data-testid={testId}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          className={inputClass}
          required={!optional && label !== "Badge"}
        />
      )}
      {hint ? <span className="mt-1 block text-sm font-normal text-slate-500">{hint}</span> : null}
    </label>
  );
}

function updateRow(
  setDraft: (updater: (current: SiteConfig) => SiteConfig) => void,
  index: number,
  partial: Partial<ComparisonRow>,
) {
  setDraft((current) => ({
    ...current,
    comparisonRows: current.comparisonRows.map((row, rowIndex) =>
      rowIndex === index ? { ...row, ...partial } : row,
    ),
  }));
}

function updateFeature(
  setDraft: (updater: (current: SiteConfig) => SiteConfig) => void,
  index: number,
  partial: Partial<FeatureItem>,
) {
  setDraft((current) => ({
    ...current,
    features: current.features.map((item, itemIndex) =>
      itemIndex === index ? { ...item, ...partial } : item,
    ),
  }));
}

function updateTier(
  setDraft: (updater: (current: SiteConfig) => SiteConfig) => void,
  index: number,
  partial: Partial<PricingTier>,
) {
  setDraft((current) => ({
    ...current,
    pricingTiers: current.pricingTiers.map((tier, tierIndex) =>
      tierIndex === index ? { ...tier, ...partial } : tier,
    ),
  }));
}

function highlightTier(
  setDraft: (updater: (current: SiteConfig) => SiteConfig) => void,
  index: number,
) {
  setDraft((current) => ({
    ...current,
    pricingTiers: current.pricingTiers.map((tier, tierIndex) => ({
      ...tier,
      highlighted: tierIndex === index,
    })),
  }));
}

function updateSecurity(
  setDraft: (updater: (current: SiteConfig) => SiteConfig) => void,
  index: number,
  partial: Partial<SecurityItem>,
) {
  setDraft((current) => ({
    ...current,
    securityItems: current.securityItems.map((item, itemIndex) =>
      itemIndex === index ? { ...item, ...partial } : item,
    ),
  }));
}

function isStatsPayload(value: unknown): value is { stats: SiteStats } {
  if (typeof value !== "object" || value === null || !("stats" in value)) return false;
  const stats = value.stats;
  if (typeof stats !== "object" || stats === null) return false;
  const record = stats as Record<string, unknown>;
  return (
    typeof record.visits === "number" &&
    typeof record.clicks === "number" &&
    (record.updatedAt === null || typeof record.updatedAt === "string")
  );
}

function isConfigPayload(value: unknown): value is { config: SiteConfig } {
  return (
    typeof value === "object" &&
    value !== null &&
    "config" in value &&
    typeof value.config === "object" &&
    value.config !== null
  );
}

function readError(value: unknown): string | null {
  if (
    typeof value === "object" &&
    value !== null &&
    "error" in value &&
    typeof value.error === "string"
  ) {
    return value.error;
  }
  return null;
}
