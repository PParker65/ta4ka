# FastBookkeeper sign-in gateway

Public page at `/` is a single sign-in card for FastBookkeeper. The one button is a normal same-tab link to the saved `targetUrl` (`#` when that value is blank). Edit the destination at `/admin`.

The site is meant to be served at [https://fastbookkeeper.com/](https://fastbookkeeper.com/). That host is this gateway, not the default button destination.

This folder is separate from the Flutter app at the repository root.

## Run

```bash
cd northledger
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

Admin: [http://localhost:3000/admin](http://localhost:3000/admin).

Production check on Node:

```bash
npm run build
npm start
```

`npm run dev` and `npm start` read and write `data/site-config.json`.

## Environment

Copy `.env.example` to `.env.local` to override the admin credentials.

| Variable | Dev default | Purpose |
| --- | --- | --- |
| `ADMIN_USER` | `admin` | Username for `/admin`. One account only. |
| `ADMIN_PASSWORD` | `admin1` | Password for `/admin`. |

If a variable is unset, the server uses that dev-only default. Do not use those defaults on a public deployment. Never commit a real secret. `.env` and `.env.local` are gitignored. The password is hashed with SHA-256 for the session cookie and is not written to logs.

On Cloudflare, set the same names as Worker secrets if you want to override the defaults:

```bash
npx wrangler secret put ADMIN_USER
npx wrangler secret put ADMIN_PASSWORD
```

## Admin config

Sign in at `/admin` with both the username and the password (`admin` / `admin1` in development). The session is an HTTP-only cookie. Its value is a SHA-256 digest, not the password.

After login, editors can change:

- `targetUrl` — blank, `#`, or an `http`/`https` URL. The shipped default is `#`. Paste the real destination in this field; it is not prefilled.
- banner text, brand name, and product badge
- hero headline, subheadline, and badge
- primary CTA, secondary CTA (`Open Web App`), sign-in, and workspace labels
- comparison, feature, pricing, and security copy
- footer disclaimer

Every public button is a normal same-tab link to the saved `targetUrl`. Blank and `#` stay on this page. Saving any other scheme is rejected. A live preview appears only after a real http(s) URL is entered.

Local Node saves go to `data/site-config.json`. The Cloudflare Worker saves the same JSON in the `SITE_CONFIG` KV namespace so edits persist at the edge.

Anonymous counters are stored separately, so a config save or a new deploy does not reset them. Locally they are written to `data/site-stats.json` (gitignored). On Cloudflare they are the `site-stats` key in the same `SITE_CONFIG` KV namespace. Each public page load sends a visit beacon, and the sign-in button records a click before it follows `targetUrl`. Signed-in admin sessions are not counted. No personal data is stored.

## Deploy to Cloudflare

The Worker is prepared with [OpenNext for Cloudflare](https://opennext.js.org/cloudflare) (`@opennextjs/cloudflare`) and Wrangler. `@cloudflare/next-on-pages` is not used; it does not support this Next.js 15 app.

Config files:

- `wrangler.jsonc` — Worker name `fastbookkeeper`, asset binding, `SITE_CONFIG` KV, and custom domains `fastbookkeeper.com` and `www.fastbookkeeper.com`
- `open-next.config.ts`
- `public/_headers` — long cache for `/_next/static/*`

Preview the Worker runtime locally (uses a local KV, not the JSON file):

```bash
npm run preview
```

### What you need before a real deploy

These were not available in this environment, so nothing has been deployed:

1. `CLOUDFLARE_API_TOKEN` with permission to edit Workers scripts, create KV namespaces, and edit DNS on the `fastbookkeeper.com` zone.
2. `CLOUDFLARE_ACCOUNT_ID` for that account.
3. The `fastbookkeeper.com` zone already on that Cloudflare account. Wrangler attaches the custom domains in `wrangler.jsonc` only when the zone is there.
4. A real KV namespace id. The id in `wrangler.jsonc` is a placeholder of zeros and must be replaced:

```bash
export CLOUDFLARE_API_TOKEN=...
export CLOUDFLARE_ACCOUNT_ID=...
npx wrangler kv namespace create SITE_CONFIG
```

Paste the printed id into `wrangler.jsonc` under `kv_namespaces` → `SITE_CONFIG` → `id`, then:

```bash
npm run deploy
```

That builds the app and deploys the Worker. After the zone is attached, the sign-in page is served at [https://fastbookkeeper.com/](https://fastbookkeeper.com/). Open `/admin` there and paste the call-to-action URL.

## Constraints

- Every call to action is a normal same-tab link to the saved `targetUrl`.
- There is no user-agent split, cloaking, delayed redirect, or clipboard rewrite.
- There is no desktop download and no automatic redirect. The public button is a normal link. The card footer is text only.
- The only form is the admin username and password gate. The page does not collect leads, end-user passwords, or payment details.
- The public page does not render stored marketing copy.
