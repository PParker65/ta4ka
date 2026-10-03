import { formatWarsaw } from "./stats.js";

function esc(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function nfmt(value) {
  return Number(value || 0).toLocaleString("en-US");
}

function pct(share) {
  const v = Number(share) * 100;
  if (!Number.isFinite(v) || v <= 0) return "0%";
  if (v >= 10 || v >= 99.5) return `${Math.round(v)}%`;
  return `${v.toFixed(1)}%`;
}

const CSS = `
:root { color-scheme: dark; --bg:#0B0D11; --card:#14161A; --line:#2A2E36; --text:#F4EFE6; --muted:#A39E93; --gold:#E8A23A; --danger:#E15B64; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: var(--bg); color: var(--text); font: 16px/1.45 ui-sans-serif, system-ui, sans-serif; }
body { min-height: 100vh; }
a { color: var(--gold); }
button, input { font: inherit; }
.wrap { width: min(1080px, calc(100% - 32px)); margin: 0 auto; padding: 28px 0 64px; }
.top { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 22px; }
.brand { display: flex; flex-direction: column; gap: 2px; }
.brand b { letter-spacing: .14em; font-size: 13px; }
.brand b span { color: var(--gold); }
.brand small, .note, .card span, th { color: var(--muted); }
h1 { font-size: 28px; line-height: 1.15; margin: 18px 0 8px; }
h2 { font-size: 13px; letter-spacing: .08em; text-transform: uppercase; color: var(--muted); margin: 28px 0 12px; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(168px, 1fr)); gap: 12px; }
.card { background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 14px 16px; }
.card span { display: block; font-size: 11px; letter-spacing: .06em; text-transform: uppercase; margin-bottom: 6px; }
.card strong { display: block; font-size: 28px; letter-spacing: -0.03em; font-variant-numeric: tabular-nums; }
.card em { display: block; margin-top: 4px; color: var(--muted); font-style: normal; font-size: 13px; }
.panel { background: var(--card); border: 1px solid var(--line); border-radius: 14px; overflow: auto; }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid var(--line); vertical-align: middle; }
th { font-size: 11px; letter-spacing: .06em; text-transform: uppercase; font-weight: 650; }
tr:last-child td { border-bottom: 0; }
.num { text-align: right; font-variant-numeric: tabular-nums; }
.share { display: inline-block; width: 72px; height: 8px; border-radius: 99px; background: #23262C; vertical-align: middle; margin-right: 8px; overflow: hidden; }
.share i { display: block; height: 100%; background: var(--gold); }
.bars { display: grid; gap: 8px; }
.bar { display: grid; grid-template-columns: 108px 1fr auto; gap: 10px; align-items: center; font-variant-numeric: tabular-nums; font-size: 14px; }
.bar i { display: block; height: 8px; border-radius: 99px; background: var(--gold); }
.note { margin: 8px 0 0; font-size: 13px; }
.ghost, .primary { border-radius: 10px; cursor: pointer; }
.ghost { background: transparent; color: var(--text); border: 1px solid var(--line); padding: 8px 12px; }
.primary { width: 100%; height: 48px; border: 0; background: var(--gold); color: #1A1206; font-weight: 750; }
.login { min-height: 100vh; display: grid; place-items: center; padding: 24px; }
.sheet { width: min(420px, 100%); background: var(--card); border: 1px solid var(--line); border-radius: 18px; padding: 28px 24px; }
label { display: block; margin: 14px 0; }
label span { display: block; margin-bottom: 6px; color: var(--muted); font-size: 13px; }
input { width: 100%; height: 48px; border-radius: 10px; border: 1px solid var(--line); background: var(--bg); color: var(--text); padding: 0 12px; }
input:focus { outline: 2px solid var(--gold); border-color: transparent; }
.err { color: var(--danger); margin: 0 0 8px; }
.scroll { max-height: 420px; overflow: auto; }
`;

function shell(title, body, extraClass) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex, nofollow">
  <title>${esc(title)}</title>
  <style>${CSS}</style>
</head>
<body class="${extraClass || ""}">
${body}
</body>
</html>`;
}

export function renderLogin(failed) {
  const err = failed
    ? `<p class="err">Invalid username or password.</p>`
    : "";
  return shell(
    "KOLESA SAVE Admin",
    `<main class="login">
      <form class="sheet" method="post" action="/admin">
        <div class="brand"><b>KOLESA <span>SAVE</span></b><small>Admin</small></div>
        <h1>Sign in</h1>
        ${err}
        <label><span>Username</span><input name="username" autocomplete="username" autocapitalize="off" spellcheck="false" required></label>
        <label><span>Password</span><input name="password" type="password" autocomplete="current-password" maxlength="200" required></label>
        <button class="primary" type="submit">Sign in</button>
      </form>
    </main>`,
    "login",
  );
}

export function renderProblem(message) {
  return shell(
    "KOLESA SAVE Admin",
    `<main class="wrap">
      <div class="top">
        <div class="brand"><b>KOLESA <span>SAVE</span></b><small>Admin</small></div>
        <form method="post" action="/admin"><input type="hidden" name="action" value="logout"><button class="ghost" type="submit">Log out</button></form>
      </div>
      <p class="err">${esc(message)}</p>
    </main>`,
  );
}

function card(label, value, sub) {
  const extra = sub ? `<em>${esc(sub)}</em>` : "";
  return `<article class="card"><span>${esc(label)}</span><strong>${esc(value)}</strong>${extra}</article>`;
}

function countryTable(rows, countKey) {
  if (!rows.length) {
    return `<div class="panel"><p class="note" style="padding:14px">No data yet.</p></div>`;
  }
  const body = rows
    .map((row) => {
      const width = Math.max(0, Math.min(100, Math.round(Number(row.share) * 100)));
      const mid =
        countKey === "hits"
          ? `<td class="num">${nfmt(row.uniq)}</td>`
          : "";
      return `<tr>
        <td>${esc(row.country || "unknown")}</td>
        <td class="num">${nfmt(row[countKey])}</td>
        ${mid}
        <td class="num"><span class="share"><i style="width:${width}%"></i></span>${pct(row.share)}</td>
      </tr>`;
    })
    .join("");
  const midHead = countKey === "hits" ? `<th class="num">Unique</th>` : "";
  const countHead = countKey === "hits" ? "Hits" : "Accounts";
  return `<div class="panel"><table>
    <thead><tr><th>Country</th><th class="num">${countHead}</th>${midHead}<th class="num">Share</th></tr></thead>
    <tbody>${body}</tbody>
  </table></div>`;
}

export function renderDashboard(stats) {
  const h = stats.hits;
  const u = stats.users;
  const maxBar = stats.daily.slice(0, 7).reduce((m, row) => Math.max(m, row.hits), 0);
  const bars = stats.daily
    .slice(0, 7)
    .map((row) => {
      const width = maxBar ? Math.max(4, Math.round((row.hits / maxBar) * 100)) : 0;
      const shown = row.hits ? width : 0;
      return `<div class="bar"><span>${esc(row.day)}</span><i style="width:${shown}%"></i><b>${nfmt(row.hits)}</b></div>`;
    })
    .join("");
  const dailyRows = stats.daily
    .map(
      (row) =>
        `<tr><td>${esc(row.day)}</td><td class="num">${nfmt(row.hits)}</td><td class="num">${nfmt(row.uniq)}</td></tr>`,
    )
    .join("");
  const recent = stats.recent.length
    ? stats.recent
        .map(
          (row) =>
            `<tr><td>${esc(row.email)}</td><td>${esc(formatWarsaw(row.createdAt))}</td></tr>`,
        )
        .join("")
    : `<tr><td colspan="2">No registrations yet.</td></tr>`;
  const lots = stats.lots
    ? `<div class="grid">
        ${card("Active storage users", nfmt(stats.lots.active), "Journal has at least one lot")}
        ${card("Lots", nfmt(stats.lots.count), "Tires and wheels in journals")}
        ${card("Storage rows", nfmt(stats.lots.rows), "Accounts with a saved journal")}
      </div>`
    : `<p class="note">Lot totals are unavailable.</p>`;

  return shell(
    "KOLESA SAVE Admin",
    `<main class="wrap">
      <div class="top">
        <div class="brand"><b>KOLESA <span>SAVE</span></b><small>Admin · ${esc(formatWarsaw(stats.now))} Europe/Warsaw</small></div>
        <form method="post" action="/admin"><input type="hidden" name="action" value="logout"><button class="ghost" type="submit">Log out</button></form>
      </div>
      <h1>Statistics</h1>
      <p class="note">A hit is a full page load of the public site. Unique visitors are a hash of IP and the Warsaw calendar day. Raw IP addresses are not stored.</p>

      <h2>Visits</h2>
      <div class="grid">
        ${card("Total hits", nfmt(h.total), `${nfmt(h.uniq)} unique`)}
        ${card("Today", nfmt(h.today), `${nfmt(h.uniqToday)} unique · ${stats.today}`)}
        ${card("Yesterday", nfmt(h.yesterday), `${nfmt(h.uniqYesterday)} unique · ${stats.yesterday}`)}
        ${card("Since yesterday", nfmt(h.sinceY), `${nfmt(h.uniqSinceY)} unique · from ${stats.yesterday} 00:00`)}
        ${card("Last 7 days", nfmt(h.d7), `${nfmt(h.uniqD7)} unique · from ${stats.d7}`)}
        ${card("Last 30 days", nfmt(h.d30), `${nfmt(h.uniqD30)} unique · from ${stats.d30}`)}
      </div>
      <h2>Last 7 days</h2>
      <div class="panel" style="padding:14px 16px"><div class="bars">${bars}</div></div>

      <h2>Registrations</h2>
      <div class="grid">
        ${card("Total accounts", nfmt(u.total))}
        ${card("Today", nfmt(u.today), stats.today)}
        ${card("Yesterday", nfmt(u.yesterday), stats.yesterday)}
        ${card("Since yesterday", nfmt(u.sinceY), `from ${stats.yesterday} 00:00`)}
        ${card("Last 7 days", nfmt(u.d7), `from ${stats.d7}`)}
        ${card("Last 30 days", nfmt(u.d30), `from ${stats.d30}`)}
        ${card("Last registration", u.lastAt ? formatWarsaw(u.lastAt) : "—", "Europe/Warsaw")}
      </div>

      <h2>Storage</h2>
      ${lots}

      <h2>Visits by country</h2>
      ${countryTable(stats.countries, "hits")}

      <h2>Registrations by country</h2>
      ${countryTable(stats.regCountries, "n")}
      <p class="note">Country comes from Cloudflare on the request. Missing country is unknown. Older accounts stay unknown.</p>

      <h2>Last 30 days</h2>
      <div class="panel scroll"><table>
        <thead><tr><th>Day</th><th class="num">Hits</th><th class="num">Unique</th></tr></thead>
        <tbody>${dailyRows}</tbody>
      </table></div>

      <h2>Last 20 registrations</h2>
      <div class="panel"><table>
        <thead><tr><th>Email</th><th>Time (Europe/Warsaw)</th></tr></thead>
        <tbody>${recent}</tbody>
      </table></div>
    </main>`,
  );
}
