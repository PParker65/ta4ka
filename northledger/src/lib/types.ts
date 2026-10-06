export const FEATURE_ICON_NAMES = [
  "file-text",
  "receipt",
  "scroll-text",
  "landmark",
  "users",
  "layout-dashboard",
] as const;

export type FeatureIconName = (typeof FEATURE_ICON_NAMES)[number];

export const SECURITY_ICON_NAMES = [
  "lock",
  "key-round",
  "users",
  "clipboard-list",
  "file-output",
] as const;

export type SecurityIconName = (typeof SECURITY_ICON_NAMES)[number];

export type ComparisonRow = {
  capability: string;
  product: string;
  legacy: string;
};

export type FeatureItem = {
  title: string;
  description: string;
  icon: FeatureIconName;
};

export type PricingTier = {
  name: string;
  price: string;
  period: string;
  description: string;
  features: string[];
  ctaLabel: string;
  badge: string;
  highlighted: boolean;
};

export type SecurityItem = {
  title: string;
  description: string;
  icon: SecurityIconName;
};

export type SiteConfig = {
  targetUrl: string;
  bannerText: string;
  brandName: string;
  productBadge: string;
  signInLabel: string;
  workspaceLabel: string;
  nav: {
    features: string;
    comparison: string;
    pricing: string;
    security: string;
  };
  heroBadge: string;
  heroHeadline: string;
  heroSubheadline: string;
  primaryCtaLabel: string;
  secondaryCtaLabel: string;
  trustRating: string;
  trustCount: string;
  trustMicro: string;
  comparisonTitle: string;
  comparisonSubtitle: string;
  comparisonCapabilityLabel: string;
  comparisonLegacyLabel: string;
  comparisonNote: string;
  comparisonRows: ComparisonRow[];
  featuresTitle: string;
  featuresSubtitle: string;
  features: FeatureItem[];
  pricingTitle: string;
  pricingSubtitle: string;
  pricingNote: string;
  pricingTiers: PricingTier[];
  securityTitle: string;
  securitySubtitle: string;
  securityItems: SecurityItem[];
  footerDisclaimer: string;
};
