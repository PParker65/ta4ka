// Country decides the language. Accept-Language is used only when the
// country is missing or Cloudflare reports it as unknown.

const SUPPORTED = ["ru", "uk", "en", "es", "de", "fr", "it", "pt", "pl", "tr", "nl", "ar"];

const COUNTRY = {
  RU: "ru",
  BY: "ru",
  KZ: "ru",
  KG: "ru",
  UZ: "ru",
  TJ: "ru",
  AM: "ru",
  AZ: "ru",
  MD: "ru",
  UA: "uk",
  US: "en",
  GB: "en",
  AU: "en",
  CA: "en",
  IE: "en",
  NZ: "en",
  ES: "es",
  MX: "es",
  AR: "es",
  CO: "es",
  CL: "es",
  PE: "es",
  VE: "es",
  UY: "es",
  DE: "de",
  AT: "de",
  FR: "fr",
  IT: "it",
  PT: "pt",
  BR: "pt",
  PL: "pl",
  TR: "tr",
  NL: "nl",
  SA: "ar",
  AE: "ar",
  EG: "ar",
};

const UNKNOWN_COUNTRY = new Set(["", "XX", "T1", "A1", "A2", "O1", "UNKNOWN"]);

export const COPY = {
  en: { line: "Adults only.", button: "I am 18 or older" },
  ru: { line: "Только для взрослых.", button: "Мне есть 18 лет" },
  uk: { line: "Лише для дорослих.", button: "Мені є 18 років" },
  es: { line: "Solo para adultos.", button: "Tengo 18 años" },
  de: { line: "Nur für Erwachsene.", button: "Ich bin 18 oder älter" },
  fr: { line: "Réservé aux adultes.", button: "J'ai 18 ans ou plus" },
  it: { line: "Solo per adulti.", button: "Ho 18 anni o più" },
  pt: { line: "Apenas para adultos.", button: "Tenho 18 anos ou mais" },
  pl: { line: "Tylko dla dorosłych.", button: "Mam ukończone 18 lat" },
  tr: { line: "Yalnızca yetişkinler için.", button: "18 yaşındayım veya daha büyüğüm" },
  nl: { line: "Alleen voor volwassenen.", button: "Ik ben 18 jaar of ouder" },
  ar: { line: "للبالغين فقط.", button: "عمري 18 عامًا أو أكثر" },
};

export function languageFor(country, acceptLanguage) {
  const code = String(country || "").trim().toUpperCase();
  if (!UNKNOWN_COUNTRY.has(code)) return COUNTRY[code] || "en";
  return matchAccept(acceptLanguage) || "en";
}

export function copyFor(lang) {
  return COPY[lang] || COPY.en;
}

function matchAccept(header) {
  if (!header) return "";
  const parts = [];
  for (const piece of String(header).split(",")) {
    const [tag, ...params] = piece.trim().split(";");
    let q = 1;
    for (const param of params) {
      const [key, value] = param.trim().split("=");
      if (key === "q") q = Number(value);
    }
    let primary = (tag || "").toLowerCase().split("-")[0];
    if (primary === "ua") primary = "uk";
    if (!primary || primary === "*") continue;
    parts.push({ primary, q: Number.isFinite(q) ? q : 0 });
  }
  parts.sort((a, b) => b.q - a.q);
  for (const part of parts) {
    if (SUPPORTED.includes(part.primary)) return part.primary;
  }
  return "";
}
