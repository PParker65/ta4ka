# Northledger landing page

Single-page marketing site for Northledger, an independent accounting and invoicing web app. The public page is one screen of anchor sections. Marketing copy and the destination URL live in `data/site-config.json` and can be edited at `/admin` without a code change.

This folder is separate from the Flutter app at the repository root.

## Run

```bash
cd northledger
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

Admin: [http://localhost:3000/admin](http://localhost:3000/admin).

Production check:

```bash
npm run build
npm start
```

## Environment

Copy `.env.example` to `.env.local` to override the admin credentials.

| Variable | Dev default | Purpose |
| --- | --- | --- |
| `ADMIN_USER` | `admin` | Username for `/admin`. One account only. |
| `ADMIN_PASSWORD` | `admin1` | Password for `/admin`. |

If a variable is unset, the server uses the matching dev-only default from `.env.example`. Do not use those defaults in production. Never commit a real secret. `.env` and `.env.local` are gitignored. The password is hashed with SHA-256 for the session and is not written to logs.

## Admin config

After login, editors can change:

- `targetUrl` (must be an `http` or `https` URL)
- banner text, brand name, and product badge
- hero headline, subheadline, and badge
- primary CTA, secondary CTA, sign-in, and workspace labels
- comparison, feature, pricing, and security copy
- footer disclaimer

The public page reads `data/site-config.json` on each request. A live preview of the current target URL sits beside the form. Saving an invalid URL is rejected.

Sign in at `/admin` with both the username and the password. The session is an HTTP-only cookie. Its value is a SHA-256 digest, not the password.

## Constraints

- Every call to action is a normal same-tab link to `targetUrl`.
- There is no user-agent split, cloaking, delayed redirect, or clipboard rewrite.
- There is no desktop download. The secondary CTA defaults to “Open Web App”.
- The only form is the admin username and password gate. The page does not collect leads, end-user passwords, or payment details.
- Public calls to action default to `https://fastbookkeper.com`.
- QuickBooks and Intuit are named only as a comparison category. The footer states that Northledger is independent and not affiliated with them. No trademark logos are used.
