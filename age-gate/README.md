# Age gate

A one-page age gate and a first-party admin panel. The public page shows a short age line and a single “I am 18” button. The label follows the visitor’s country (`CF-IPCountry` / `request.cf.country`). `Accept-Language` is used only when the country is unknown.

## Run locally

```bash
cd age-gate
npm install
npx wrangler dev
```

Open the site at the URL Wrangler prints (usually `http://127.0.0.1:8787`). Sign in at `/admin` and set the button destination there. Until a link is saved, clicks are counted and the visitor stays on the page.

To preview a country locally:

```bash
curl -H 'CF-IPCountry: UA' http://127.0.0.1:8787/
curl -H 'CF-IPCountry: ES' http://127.0.0.1:8787/
```

Production is https://ilovdady.com. `www.ilovdady.com` and plain HTTP redirect to that HTTPS apex. The worker runs on Cloudflare’s global edge (no region pin). `wrangler.toml` routes are only this domain, and a Workers custom domain is proxied rather than DNS-only.

The `LEADS` KV id in `wrangler.toml` is a local placeholder. Before the first deploy, create a new namespace for this site only and replace that id:

```bash
npx wrangler kv namespace create LEADS
npx wrangler deploy
```

In the zone, also turn on Always Use HTTPS, Automatic HTTPS Rewrites, and minimum TLS 1.2. The worker sends HSTS, `X-Content-Type-Options: nosniff`, a Referrer-Policy, `X-Frame-Options: DENY`, and a CSP that allows only this site’s own CSS and JS.

## Admin

`/admin` stores the http(s) destination in KV and shows visits, uniques, clicks, time on site, and breakdowns. Stats stay on this site. Visitor ids are hashed before they are stored. Raw IP addresses are not stored.
