export const siteConfig = {
  origin: "https://snelfixauto.com",
  name: "SnelFix Auto",
  assetVersion: "20261021l",
  phoneDisplay: "+31 6 13044422",
  phoneTel: "+31613044422",
  whatsapp: "https://wa.me/31613044422",
  instagram: "https://instagram.com/SnelFix_Auto",
  instagramHandle: "@SnelFix_Auto",
  telegram: "https://t.me/SnelFix_Auto",
  telegramHandle: "@SnelFix_Auto",
  analyticsId: "",
  searchConsoleVerification: "",
  defaultLocale: "ru",
  locales: ["nl", "en", "ru", "uk"],
};

export const asset = {
  css: `/assets/site.css?v=${siteConfig.assetVersion}`,
  main: `/assets/main.js?v=${siteConfig.assetVersion}`,
  admin: `/assets/admin.js?v=${siteConfig.assetVersion}`,
  wordmark: "/brand/wordmark.svg",
};
