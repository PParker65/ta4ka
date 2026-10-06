import {
  FEATURE_ICON_NAMES,
  SECURITY_ICON_NAMES,
  type ComparisonRow,
  type FeatureIconName,
  type FeatureItem,
  type PricingTier,
  type SecurityIconName,
  type SecurityItem,
  type SiteConfig,
} from "./types";
import { isHttpUrl } from "./url";

export type ValidateResult =
  | { ok: true; config: SiteConfig }
  | { ok: false; error: string };

class ConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConfigError";
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function mustString(
  value: unknown,
  label: string,
  max: number,
  allowEmpty = false,
): string {
  if (typeof value !== "string") {
    throw new ConfigError(`${label} is required.`);
  }
  const trimmed = value.trim();
  if (!allowEmpty && trimmed.length === 0) {
    throw new ConfigError(`${label} is required.`);
  }
  if (trimmed.length > max) {
    throw new ConfigError(`${label} must be ${max} characters or fewer.`);
  }
  return trimmed;
}

function mustIcon<T extends string>(
  value: unknown,
  allowed: readonly T[],
  label: string,
): T {
  if (typeof value === "string" && (allowed as readonly string[]).includes(value)) {
    return value as T;
  }
  throw new ConfigError(`${label} icon is not recognized.`);
}

function mustArray(value: unknown, label: string, exact: number): unknown[] {
  if (!Array.isArray(value) || value.length !== exact) {
    throw new ConfigError(`${label} must include ${exact} items.`);
  }
  return value;
}

function mustFeatureLines(value: unknown, label: string): string[] {
  if (!Array.isArray(value)) {
    throw new ConfigError(`${label} needs a feature list.`);
  }
  const lines = value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter(Boolean);
  if (lines.length < 1 || lines.length > 8) {
    throw new ConfigError(`${label} needs 1 to 8 feature lines.`);
  }
  for (const line of lines) {
    if (line.length > 80) {
      throw new ConfigError(
        `${label} feature lines must be 80 characters or fewer.`,
      );
    }
  }
  return lines;
}

function parseConfig(input: unknown): SiteConfig {
  if (!isRecord(input)) {
    throw new ConfigError("Config must be an object.");
  }

  const targetUrl = mustString(input.targetUrl, "Target URL", 500);
  if (!isHttpUrl(targetUrl)) {
    throw new ConfigError("Target URL must be an http or https URL.");
  }

  if (!isRecord(input.nav)) {
    throw new ConfigError("Navigation labels are required.");
  }

  const comparisonRows = mustArray(
    input.comparisonRows,
    "Comparison rows",
    9,
  ).map((row, index): ComparisonRow => {
    if (!isRecord(row)) {
      throw new ConfigError(`Comparison row ${index + 1} is incomplete.`);
    }
    return {
      capability: mustString(row.capability, `Comparison row ${index + 1} capability`, 80),
      product: mustString(row.product, `Comparison row ${index + 1} product cell`, 160),
      legacy: mustString(row.legacy, `Comparison row ${index + 1} legacy cell`, 160),
    };
  });

  const features = mustArray(input.features, "Features", 6).map(
    (item, index): FeatureItem => {
      if (!isRecord(item)) {
        throw new ConfigError(`Feature ${index + 1} is incomplete.`);
      }
      return {
        title: mustString(item.title, `Feature ${index + 1} title`, 60),
        description: mustString(
          item.description,
          `Feature ${index + 1} description`,
          200,
        ),
        icon: mustIcon<FeatureIconName>(
          item.icon,
          FEATURE_ICON_NAMES,
          `Feature ${index + 1}`,
        ),
      };
    },
  );

  const pricingTiers = mustArray(input.pricingTiers, "Pricing tiers", 3).map(
    (item, index): PricingTier => {
      if (!isRecord(item)) {
        throw new ConfigError(`Pricing tier ${index + 1} is incomplete.`);
      }
      if (typeof item.highlighted !== "boolean") {
        throw new ConfigError(`Pricing tier ${index + 1} needs a highlighted flag.`);
      }
      return {
        name: mustString(item.name, `Pricing tier ${index + 1} name`, 40),
        price: mustString(item.price, `Pricing tier ${index + 1} price`, 24),
        period: mustString(item.period, `Pricing tier ${index + 1} period`, 40),
        description: mustString(
          item.description,
          `Pricing tier ${index + 1} description`,
          160,
        ),
        features: mustFeatureLines(item.features, `Pricing tier ${index + 1}`),
        ctaLabel: mustString(item.ctaLabel, `Pricing tier ${index + 1} button`, 60),
        badge: mustString(item.badge, `Pricing tier ${index + 1} badge`, 40, true),
        highlighted: item.highlighted,
      };
    },
  );

  const highlighted = pricingTiers.filter((tier) => tier.highlighted).length;
  if (highlighted !== 1) {
    throw new ConfigError("Choose one highlighted pricing tier.");
  }

  const securityItems = mustArray(input.securityItems, "Security items", 5).map(
    (item, index): SecurityItem => {
      if (!isRecord(item)) {
        throw new ConfigError(`Security item ${index + 1} is incomplete.`);
      }
      return {
        title: mustString(item.title, `Security item ${index + 1} title`, 60),
        description: mustString(
          item.description,
          `Security item ${index + 1} description`,
          200,
        ),
        icon: mustIcon<SecurityIconName>(
          item.icon,
          SECURITY_ICON_NAMES,
          `Security item ${index + 1}`,
        ),
      };
    },
  );

  return {
    targetUrl,
    bannerText: mustString(input.bannerText, "Banner text", 240),
    brandName: mustString(input.brandName, "Brand name", 40),
    productBadge: mustString(input.productBadge, "Product badge", 24),
    signInLabel: mustString(input.signInLabel, "Sign-in label", 60),
    workspaceLabel: mustString(input.workspaceLabel, "Workspace label", 60),
    nav: {
      features: mustString(input.nav.features, "Features nav label", 40),
      comparison: mustString(input.nav.comparison, "Comparison nav label", 40),
      pricing: mustString(input.nav.pricing, "Pricing nav label", 40),
      security: mustString(input.nav.security, "Security nav label", 40),
    },
    heroBadge: mustString(input.heroBadge, "Hero badge", 160),
    heroHeadline: mustString(input.heroHeadline, "Hero headline", 160),
    heroSubheadline: mustString(input.heroSubheadline, "Hero subheadline", 400),
    primaryCtaLabel: mustString(input.primaryCtaLabel, "Primary CTA label", 60),
    secondaryCtaLabel: mustString(input.secondaryCtaLabel, "Secondary CTA label", 60),
    trustRating: mustString(input.trustRating, "Trust rating", 60),
    trustCount: mustString(input.trustCount, "Trust count", 80),
    trustMicro: mustString(input.trustMicro, "Trust micro copy", 160),
    comparisonTitle: mustString(input.comparisonTitle, "Comparison title", 120),
    comparisonSubtitle: mustString(
      input.comparisonSubtitle,
      "Comparison subtitle",
      240,
    ),
    comparisonCapabilityLabel: mustString(
      input.comparisonCapabilityLabel,
      "Comparison capability label",
      40,
    ),
    comparisonLegacyLabel: mustString(
      input.comparisonLegacyLabel,
      "Comparison legacy label",
      60,
    ),
    comparisonNote: mustString(input.comparisonNote, "Comparison note", 240),
    comparisonRows,
    featuresTitle: mustString(input.featuresTitle, "Features title", 120),
    featuresSubtitle: mustString(input.featuresSubtitle, "Features subtitle", 240),
    features,
    pricingTitle: mustString(input.pricingTitle, "Pricing title", 120),
    pricingSubtitle: mustString(input.pricingSubtitle, "Pricing subtitle", 240),
    pricingNote: mustString(input.pricingNote, "Pricing note", 160),
    pricingTiers,
    securityTitle: mustString(input.securityTitle, "Security title", 120),
    securitySubtitle: mustString(input.securitySubtitle, "Security subtitle", 240),
    securityItems,
    footerDisclaimer: mustString(input.footerDisclaimer, "Footer disclaimer", 400),
  };
}

export function validateConfig(input: unknown): ValidateResult {
  try {
    return { ok: true, config: parseConfig(input) };
  } catch (error) {
    if (error instanceof ConfigError) {
      return { ok: false, error: error.message };
    }
    return { ok: false, error: "Config could not be read." };
  }
}
