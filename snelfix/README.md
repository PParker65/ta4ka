# SnelFix Auto

Website for SnelFix Auto: a workshop in Waddinxveen and De Bilt, plus vehicle recovery and transport across the Netherlands and Europe. The public site is Russian by default, with Dutch, English and Ukrainian on the language switch at the top. On a phone it is one screen: a bottom bar swaps panels, and the page itself does not scroll. Bookings, tow requests, services, hours and customers live in a database the owner can edit from `/admin` on a phone.

The site is isolated in this `snelfix/` directory. It does not share routes or storage with any other project in the repository.

## Run locally

Requires Node.js 22 or newer. No Cloudflare login is required.

```bash
cd snelfix
npm install
npm run dev
```

Open http://127.0.0.1:8787

`npm run dev` builds the CSS and JavaScript, creates `data/snelfix.sqlite` if needed, applies `migrations/0001_init.sql`, and seeds the garages, services, hours and sample news. The database file stays on this machine and is not committed.

The first admin login is username `admin` and password `admin`. It is stored as a salted SHA-256 hash, not as reversible text. Change it immediately under Beheer → Wachtwoord. After a change, the previous password stops working and every session is signed out. The hash is not printed in logs.

## What the owner edits

In `/admin`:

- bookings: confirm, cancel, reschedule, next-service note
- tow requests, with urgent ones marked
- services, durations and from-prices
- both garages: weekly hours, closed days, blocked hours, address text in four languages
- phone, WhatsApp, Instagram and Telegram links
- customers and their vehicles
- photos and news
- the admin password

Public prices are from-prices. An empty price means the job is quoted after the car is seen. Recovery does not use the lift diary and does not calculate a paid distance. The tow form opens a Google Maps route and OpenStreetMap searches; the price is confirmed afterwards.

## Deploy on Cloudflare

HTTPS is terminated at the Cloudflare edge. The worker assumes that. Apex `snelfixauto.com` and `www.snelfixauto.com` are both custom domains in `wrangler.toml`. Do not add any other zone to that file.

```bash
cd snelfix
npm install
npm run build
npx wrangler login
npx wrangler d1 create snelfix-auto
```

Paste the database id into `wrangler.toml` (`database_id`). Then:

```bash
npx wrangler d1 migrations apply snelfix-auto --remote
npx wrangler deploy
```

The first request seeds services, both addresses, hours and the admin user. Set secrets before relying on notifications:

```bash
npx wrangler secret put TELEGRAM_BOT_TOKEN
npx wrangler secret put TELEGRAM_CHAT_ID
npx wrangler secret put EMAIL_WEBHOOK_URL
npx wrangler secret put SMS_WEBHOOK_URL
npx wrangler secret put EMAIL_TO
npx wrangler secret put CRON_SECRET
npx wrangler secret put ANALYTICS_ID
npx wrangler secret put GSC_VERIFICATION
```

Optional `ADMIN_PASSWORD` is read only while the database is empty. It does not reset a password that was already changed in the panel.

A cron trigger at 06:15 UTC writes reminder rows for visits whose reminder time has passed. `POST /api/cron/reminders` with `Authorization: Bearer $CRON_SECRET` does the same and is the documented stub for a manual run. Client email and SMS are not sent by a paid SDK. If `EMAIL_WEBHOOK_URL` or `SMS_WEBHOOK_URL` is empty, the booking is still saved, shown in admin, and confirmed on screen. The payload is stored in the `notifications` table.

Copy `.dev.vars.example` to `.dev.vars` for local hooks. `.dev.vars` is gitignored. Do not commit tokens.

## Replace the placeholders

- Logo: replace `public/brand/wordmark.svg`. Every page loads that one file.
- Photographs: replace the files in `public/photos/`. They are stand-ins (Unsplash, and a Wikimedia Commons recovery scene, geograph.org.uk 8237923, with the operator name blurred). Use the garage's own truck, bays and cars.
- Analytics and Search Console stay empty in `src/site.config.js` until an id is set there or via the environment. The cookie note does not load Google Analytics before that, and only after the visitor accepts.

## Checks

```bash
npm run smoke
```
