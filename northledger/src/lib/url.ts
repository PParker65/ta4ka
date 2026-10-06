/** Href for a saved target. Blank values stay on this page. Only http(s) leaves the site. */
export function ctaHref(targetUrl: string): string {
  const trimmed = targetUrl.trim();
  if (trimmed === "#") return "#";
  if (isHttpUrl(trimmed)) return trimmed;
  return "#";
}

export function isHttpUrl(value: string): boolean {
  try {
    const url = new URL(value.trim());
    return (
      (url.protocol === "http:" || url.protocol === "https:") &&
      url.hostname.length > 0
    );
  } catch {
    return false;
  }
}
