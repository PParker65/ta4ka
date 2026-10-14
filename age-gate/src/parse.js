export function parseUa(ua) {
  const s = String(ua || "");
  const isAndroid = /Android/i.test(s);
  const isIos = /iPhone|iPad|iPod/i.test(s);
  let device = "desktop";
  if (/iPad|Tablet|PlayBook|Silk/i.test(s) || (isAndroid && !/Mobile/i.test(s))) {
    device = "tablet";
  } else if (/Mobi|iPhone|iPod|Windows Phone|webOS/i.test(s) || (isAndroid && /Mobile/i.test(s))) {
    device = "mobile";
  }

  let os = "Other";
  if (/Windows NT/i.test(s)) os = "Windows";
  else if (isAndroid) os = "Android";
  else if (isIos) os = "iOS";
  else if (/Mac OS X|Macintosh/i.test(s)) os = "macOS";
  else if (/CrOS/i.test(s)) os = "ChromeOS";
  else if (/Linux/i.test(s)) os = "Linux";

  let browser = "Other";
  if (/Edg\//i.test(s)) browser = "Edge";
  else if (/OPR\/|Opera/i.test(s)) browser = "Opera";
  else if (/SamsungBrowser/i.test(s)) browser = "Samsung Internet";
  else if (/Firefox\//i.test(s)) browser = "Firefox";
  else if (/Chrome|CriOS/i.test(s)) browser = "Chrome";
  else if (/Safari\//i.test(s)) browser = "Safari";

  return { device, os, browser };
}

export function geoFrom(request) {
  const cf = (request && request.cf) || {};
  const headers = request && request.headers;
  const read = (name) => (headers && typeof headers.get === "function" ? headers.get(name) : "") || "";
  // Cloudflare sets both `request.cf` and `CF-IPCountry`. Local wrangler fills
  // `request.cf` with a US default, so an explicit country header must win.
  return {
    country: clip(read("CF-IPCountry") || cf.country, 8).toUpperCase(),
    city: clip(read("CF-IPCity") || cf.city, 80),
    region: clip(read("CF-Region") || read("CF-IPRegion") || cf.region || cf.regionCode, 80),
  };
}

export function validDestUrl(input) {
  if (typeof input !== "string") return "";
  const trimmed = input.trim();
  if (!trimmed || trimmed.length > 2000) return "";
  let url;
  try {
    url = new URL(trimmed);
  } catch {
    return "";
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return "";
  if (!url.hostname) return "";
  return url.toString();
}

const APEX = "ilovdady.com";

export function publicScheme(urlString, forwardedProto, cfVisitor) {
  if (cfVisitor) {
    try {
      const parsed = JSON.parse(cfVisitor);
      if (parsed && parsed.scheme) return String(parsed.scheme).toLowerCase() === "https" ? "https" : "http";
    } catch {
      // Ignore a malformed CF-Visitor header and use the other signals.
    }
  }
  if (forwardedProto) {
    const value = forwardedProto.split(",")[0].trim().toLowerCase();
    if (value === "https" || value === "http") return value;
  }
  return new URL(urlString).protocol === "https:" ? "https" : "http";
}

export function canonicalTarget(urlString, forwardedProto, cfVisitor) {
  const url = new URL(urlString);
  const host = url.hostname.toLowerCase();
  if (host !== APEX && host !== `www.${APEX}`) return "";
  const scheme = publicScheme(urlString, forwardedProto, cfVisitor);
  if (host === APEX && scheme === "https") return "";
  return `https://${APEX}${url.pathname}${url.search}`;
}

export function clip(value, max) {
  return String(value || "")
    .replace(/[\u0000-\u001F]/g, "")
    .trim()
    .slice(0, max);
}
