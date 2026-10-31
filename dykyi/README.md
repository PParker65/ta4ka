# Dykyi

Static landing for dykyiboss.com. Russian UI, boot splash, then a glass card with two links.

## Links

Edit only `public/js/site.js`, the `siteConfig` object at the top:

```js
const siteConfig = {
  gameUrl: "https://rmr.global",
  telegramUrl: "https://t.me/dykyiboss1",
};
```

**Игра** opens `gameUrl`. **Телеграм канал** opens `telegramUrl`. Both open in a new tab. A value of `#` keeps that button on this page. Bump `?v=` on the script tag in `public/index.html` when the addresses change.

## Publish

Cloudflare Pages project name: `dykyiboss`.  
Root directory: `dykyi`. Build command: none. Output: `public`.

```sh
cd dykyi
npx wrangler@4 pages deploy public --project-name dykyiboss
```

Or `./scripts/publish.sh` once `CLOUDFLARE_API_TOKEN` is set. The script deploys Pages, attaches `dykyiboss.com` and `www.dykyiboss.com`, creates proxied CNAMEs to `dykyiboss.pages.dev`, and turns on Always Use HTTPS. It does not add a country block. If one is already on the zone, the script prints it and exits without calling the site live.

This environment had no `CLOUDFLARE_API_TOKEN` and no Wrangler login, so nothing was deployed. `dykyiboss.com` is on `hope.ns.cloudflare.com` and `drake.ns.cloudflare.com` with no A or CNAME yet.

### Token scopes

- Account — Cloudflare Pages — Edit
- Account — Account Settings — Read
- User — User Details — Read
- Zone — Zone — Read
- Zone — DNS — Edit
- Zone — Zone Settings — Edit
- Zone — Firewall Services — Read (confirm there is no country block; Edit only to remove one)
