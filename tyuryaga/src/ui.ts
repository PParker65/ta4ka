import { bossSvg, dealerSvg, inmateSvg, miniFace, shiloSvg } from "./avatar";
import {
  BIZ_UPGRADE_PAP,
  BOSSES,
  BUSINESS_MS,
  CAT_LABEL,
  CLOTHES,
  DAILIES,
  ENERGY_TICK_MS,
  MODE_LABEL,
  NIGHT_TATTOOS,
  NYCHKA_NAMES,
  RANK_NPC,
  SHOP,
  TALENTS,
  TATTOOS,
  TITLE,
  WORKSHOP,
  WORKSHOP_LEVEL,
  YARD_STEAL_CAP,
  ZONES,
  zoneById,
} from "./data";
import { bizReady, bossLocked, escapeProgress, holderOf, nightOpen, phoneProgress, unarmedDmg, zoneUnlocked } from "./engine";
import { energyMax, levelOf, nextEnergyIn } from "./state";
import type { GameState, Screen, TattooCat } from "./types";

export function esc(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
}

function fmtMs(ms: number): string {
  const s = Math.max(0, Math.ceil(ms / 1000));
  const m = Math.floor(s / 60);
  const h = Math.floor(m / 60);
  if (h) return `${h}:${String(m % 60).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
  return `${String(m % 60).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
}

function money(n: number): string {
  return Math.floor(n).toLocaleString("ru-RU");
}

const NAV: { id: Screen; glyph: string; label: string }[] = [
  { id: "cell", glyph: "▣", label: "Камера" },
  { id: "ink", glyph: "👔", label: "Шмот" },
  { id: "stats", glyph: "◎", label: "Анкетка" },
  { id: "raids", glyph: "🗡", label: "Разборки" },
  { id: "mail", glyph: "✉", label: "Малява" },
  { id: "brigade", glyph: "🪓", label: "Бригада" },
  { id: "inventory", glyph: "📦", label: "Нычки" },
  { id: "gifts", glyph: "❤", label: "Передачи" },
];

export function render(app: HTMLElement, s: GameState, now: number): void {
  if (s.screen === "boot" || s.screen === "gate" || s.screen === "create") {
    app.innerHTML = `<div class="viewport wood-dark">${renderBoot(s)}</div>`;
    return;
  }
  const cap = energyMax(s);
  const eta = nextEnergyIn(s, now);
  const mailN = s.mail.length > 12 ? s.mail.length - 12 : 0;
  app.innerHTML = `
    <div class="viewport">
      <div class="hud wood">
        <div class="hud-side">
          <div class="pill" title="папиросы"><span class="ico">🚬</span><b>${money(s.pap)}</b></div>
          <div class="pill" title="деревянные"><span class="ico">🪙</span><b>${money(s.rub)}</b></div>
          <div class="pill" title="сахар"><span class="ico">🍬</span><b>${money(s.sugar)}</b></div>
          <div class="pill" title="голоса (локальные)"><span class="ico">★</span><b>${money(s.votes)}</b></div>
        </div>
        <div class="energy" data-act="skip" title="клик: +1 час локально">
          <div class="num">⚡ ${s.energy} / ${cap}</div>
          <div class="eta">${s.energy >= cap ? "полный бак" : "до +1  " + fmtMs(eta)} · темп ×${s.timeScale}</div>
          <div class="bar"><i style="width:${(s.energy / cap) * 100}%"></i></div>
        </div>
        <div class="hud-side" style="justify-content:flex-end">
          <div class="pill" title="авторитет"><span class="ico">✊</span><b>${money(s.authority)}</b></div>
          <div class="pill" title="уровень"><span class="ico">Lv</span><b>${levelOf(s)}</b></div>
          <div class="pill" title="мыло"><span class="ico">🧼</span><b>${money(s.soap)}</b></div>
        </div>
      </div>
      <div class="stage" id="stage">${renderStage(s, now)}</div>
      <div class="nav wood">
        <div class="icons">
          ${NAV.map(
            (n) => `<button class="ico-btn ${s.screen === n.id ? "on" : ""}" data-act="nav" data-id="${n.id}">
              <div class="glyph">${n.glyph}</div>${n.label}
              ${n.id === "mail" && s.mail.length ? `<i class="badge">${Math.min(9, s.mail.length)}</i>` : ""}
              ${n.id === "brigade" && mailN ? `<i class="badge">1</i>` : ""}
            </button>`,
          ).join("")}
        </div>
        <div class="wanted" data-act="invite">
          <b>РОЗЫСК</b>
          <span>Позови корешей — вместе срок короче</span>
          <span class="btn btn-gold" style="margin-top:4px;padding:2px 8px">Позвать</span>
        </div>
      </div>
      <div class="dock wood-dark">
        ${s.friends
          .slice(0, 12)
          .map(
            (f, i) => `<div class="barred" data-act="friend" data-id="${esc(f.id)}" title="${esc(f.name)}">
              <span class="n">${i + 1}</span>${miniFace(f.hue, f.name)}
            </div>`,
          )
          .join("")}
        <div class="pager">
          <button class="btn btn-wood" data-act="nav" data-id="rank">ТОП</button>
          <button class="btn btn-wood" data-act="nav" data-id="map">Проходная</button>
          <button class="btn btn-wood" data-act="nav" data-id="yard">Двор</button>
        </div>
      </div>
      <div class="toast-stack">${s.toasts.map((t) => `<div class="toast">${esc(t.text)}</div>`).join("")}</div>
    </div>`;
}

function renderBoot(s: GameState): string {
  if (s.screen === "boot") {
    return `<div class="boot">
      <h1>${TITLE}</h1>
      <p>Фан-реконструкция дворовой социалки 2012–13. Свой арт, свои кликухи, без студии Кефир, без чужих SWF и без звёзд на плечах.</p>
      <p class="muted">18+. Мультяшная зона, дворовый сленг, не учебник.</p>
      <button class="btn btn-gold" data-act="age">Мне есть 18</button>
    </div>`;
  }
  if (s.screen === "gate") {
    return `<div class="boot">
      ${shiloSvg()}
      <h2>Здорова, сокамерник.</h2>
      <p>Я местный кольщик. Кликуха — Шило. Движухи на проходной, папиросы на стол, корешей зови — они бьют сами.</p>
      <button class="btn btn-lime" data-act="to-create">Ну давай</button>
    </div>`;
  }
  return `<div class="boot" style="grid-template-columns: 1fr 1fr; text-align:left; padding: 28px;">
    <div>
      ${inmateSvg(s)}
    </div>
    <div>
      <h2>Как кличут?</h2>
      <input id="nick" type="text" maxlength="18" placeholder="кликуха" value="${esc(s.nick)}" />
      <div class="face-sliders" style="margin-top:12px;display:grid;gap:8px">
        ${slider("jaw", "Челюсть", s.face.jaw)}
        ${slider("lips", "Губы", s.face.lips)}
        ${slider("eyes", "Глаза", s.face.eyes)}
        ${slider("brow", "Брови", s.face.brow)}
        ${slider("skin", "Тон", s.face.skin)}
      </div>
      <button class="btn btn-lime" style="margin-top:14px" data-act="create">В хату</button>
      <p class="muted">Мужик, как в классике. Шмот и наколки — потом.</p>
    </div>
  </div>`;
}

function slider(k: string, label: string, v: number): string {
  return `<label>${label}<input data-act="face" data-k="${k}" type="range" min="0" max="100" value="${v}" /></label>`;
}

function renderStage(s: GameState, now: number): string {
  switch (s.screen) {
    case "cell":
      return cell(s);
    case "yard":
      return yard(s);
    case "map":
      return map(s, now);
    case "jobs":
      return jobs(s);
    case "shop":
      return shop(s);
    case "ink":
      return ink(s);
    case "wardrobe":
      return wardrobe(s);
    case "raids":
      return raids(s, now);
    case "inventory":
      return inventory(s);
    case "stats":
      return stats(s);
    case "rank":
      return rank(s);
    case "dailies":
      return dailies(s);
    case "mail":
      return mail(s);
    case "gifts":
      return gifts(s);
    case "friend":
      return friend(s);
    case "workshop":
      return workshop(s);
    case "talents":
      return talents(s);
    case "hidden":
      return hidden(s);
    case "cards":
      return cards(s);
    case "slot":
      return slot(s);
    case "brigade":
      return brigade(s);
    default:
      return cell(s);
  }
}

function cell(s: GameState): string {
  const theme = s.cellTheme === "empty" ? "Пустая хата" : `Хата: ${s.cellTheme}`;
  return `
    <div class="cell-bg"></div>
    <div class="bars-win" title="окно"></div>
    <div class="hanger" title="вешалка"></div>
    <div class="slippers-floor"></div>
    <div class="hotspot" data-act="nav" data-id="yard" style="right:8px;top:80px;width:70px;height:160px"><span>Двор</span></div>
    <div class="hotspot" data-act="nav" data-id="map" style="left:8px;bottom:40px;width:80px;height:90px"><span>Проходная</span></div>
    <div class="hotspot" data-act="nav" data-id="dailies" style="left:140px;top:20px;width:70px;height:50px"><span>Срочняки</span></div>
    <div class="avatar-wrap" data-act="flip">${inmateSvg(s)}</div>
    <div style="position:absolute;left:12px;top:12px" class="pill">${esc(s.nick)} · ${theme}</div>
    <div style="position:absolute;right:12px;bottom:12px" class="row">
      <button class="btn btn-wood" data-act="nav" data-id="ink">Наколки</button>
      <button class="btn btn-wood" data-act="flip">${s.showBack ? "Лицо" : "Спина"}</button>
    </div>
  `;
}

function yard(s: GameState): string {
  return `
    <div class="yard-bg"></div>
    ${[0, 1, 2, 3, 4].map((i) => `<div class="loh" data-act="steal" style="left:${80 + i * 90}px;bottom:70px">${miniFace(40 + i * 40, "Л")}</div>`).join("")}
    <div class="panel wood" style="inset:auto 12px 12px 12px;height:120px;position:absolute">
      <div class="row">
        <button class="btn btn-lime" data-act="steal">Экспроприация (${s.stolenToday}/${YARD_STEAL_CAP})</button>
        <button class="btn btn-gold" data-act="nav" data-id="cards">Карты с терпилой</button>
        <button class="btn btn-gold" data-act="nav" data-id="slot">Барабан</button>
        <button class="btn btn-wood" data-act="tp">Стырить туалетку</button>
        <button class="btn btn-wood" data-act="nav" data-id="shop">Толян</button>
        <button class="btn btn-wood" data-act="nav" data-id="map">На проходную</button>
      </div>
      <div class="tiny" style="margin-top:6px">Кликай лохов во дворе. С пар — 300 папирос в сутки. Толян зевает раз в день.</div>
    </div>
  `;
}

function map(s: GameState, now: number): string {
  const wait = BUSINESS_MS / Math.max(1, s.timeScale);
  return `<div class="panel wood" style="inset:8px">
    <div class="row" style="justify-content:space-between">
      <h2>Проходная</h2>
      <div>
        <button class="btn btn-lime" data-act="collect">Собрать всё</button>
        <button class="btn btn-wood" data-act="nav" data-id="workshop">Мастерская</button>
      </div>
    </div>
    <div class="tiny">Крыша отдаёт раз в 8 ч (у тебя ×${s.timeScale}). Бутырка — лучшие папиросы с энергии.</div>
    <div class="map-grid" style="margin-top:8px">
      ${ZONES.map((z) => {
        const open = zoneUnlocked(s, z.id);
        const zs = s.zones[z.id];
        const left = zs.captured ? Math.max(0, wait - (now - zs.bizAt)) : 0;
        return `<div class="card zone-card ${open ? "" : "lock"}" ${open ? `data-act="enter" data-id="${z.id}"` : ""}>
          <b>${z.name}</b>
          <div class="tiny">${z.city} · наколок ${z.tattoosNeeded}</div>
          <div class="tiny">${zs.captured ? `крыша ур.${zs.bizLevel} · ${bizReady(s, z.id, now) ? "ГОТОВО" : fmtMs(left)}` : "без крыши"}</div>
          <div class="tiny">держатель: ${esc(holderOf(s, z.id))}</div>
          ${open && !zs.captured ? `<button class="btn btn-gold" data-act="capture" data-id="${z.id}">Крышевать · 50 пап.</button>` : ""}
          ${zs.captured ? `<button class="btn btn-wood" data-act="upgrade" data-id="${z.id}">+ур. · ${BIZ_UPGRADE_PAP}</button>` : ""}
        </div>`;
      }).join("")}
    </div>
  </div>`;
}

function jobs(s: GameState): string {
  const z = zoneById(s.zoneId);
  const list = s.shift === "day" ? z.day : z.night;
  const nightOk = nightOpen(s);
  const prog = s.zones[z.id][s.shift];
  return `<div class="panel wood" style="inset:8px">
    <div class="row" style="justify-content:space-between">
      <h2>${z.name} · ${s.shift === "day" ? "день" : "ночь"}</h2>
      <div>
        <button class="tab ${s.shift === "day" ? "on" : ""}" data-act="shift" data-id="day">День ${z.dayEnergy}</button>
        <button class="tab ${s.shift === "night" ? "on" : ""}" data-act="shift" data-id="night">Ночь ${z.nightEnergy}</button>
        <button class="btn btn-wood" data-act="nav" data-id="map">Назад</button>
      </div>
    </div>
    <div class="tiny">${z.blurb} · ходок ${s.zones[z.id].hodkas} · бунтов ${s.zones[z.id].riots}
      ${s.shift === "night" && !nightOk ? ` · ночь с ${NIGHT_TATTOOS} наколок (у тебя ${s.tattoos.length})` : ""}</div>
    <div class="grid" style="margin-top:8px;max-height:320px;overflow:auto">
      ${list
        .map((j) => {
          const p = prog[j.id] ?? 0;
          const left = Math.max(0, j.repeats - p);
          return `<div class="card row" style="justify-content:space-between">
            <div>
              <b>${j.title}</b>
              <div class="tiny">${j.blurb}</div>
              <div class="tiny">⚡${j.energy} · ✊${j.authority} · 🚬${j.pap}${j.hate ? " · ненависть " + j.hate : ""}${j.respect ? " · уважение " + j.respect : ""} · ${p}/${j.repeats}</div>
            </div>
            <button class="btn btn-lime" data-act="job" data-id="${j.id}" ${left === 0 || s.energy < j.energy ? "disabled" : ""}>Идти</button>
          </div>`;
        })
        .join("")}
    </div>
  </div>`;
}

function shop(s: GameState): string {
  const tabs = [...new Set(SHOP.map((o) => o.tab))];
  const list = SHOP.filter((o) => o.tab === s.shopTab);
  const labels: Record<string, string> = {
    pap: "🚬",
    rub: "🪙",
    sugar: "🍬",
    tp: "🧻",
    soap: "🧼",
    energy: "⚡",
    weapon: "🗡",
  };
  return `<div class="panel wood" style="inset:8px">
    <h2>Толян · лавка</h2>
    <div class="shop-layout">
      <div class="vtabs">${tabs.map((t) => `<button class="tab ${s.shopTab === t ? "on" : ""}" data-act="shop-tab" data-id="${t}">${labels[t] ?? t}</button>`).join("")}</div>
      <div class="grid">${list
        .map(
          (o) => `<div class="card row" style="justify-content:space-between">
            <div><b>${o.name}</b><div class="tiny">${o.blurb}</div></div>
            <button class="btn btn-gold" data-act="buy" data-id="${o.id}">${o.cost} ${o.currency === "votes" ? "★" : o.currency}</button>
          </div>`,
        )
        .join("")}</div>
      <div>
        ${dealerSvg()}
        <div class="tiny">Свои треники, без чужих полосок. Послать — из хаты кореша.</div>
        <button class="btn btn-wood" data-act="tp">Стырить рулон</button>
      </div>
    </div>
  </div>`;
}

function ink(s: GameState): string {
  const cats = Object.keys(CAT_LABEL) as TattooCat[];
  const list = TATTOOS.filter((t) => t.cat === s.inkCat);
  const counts = cats.map((c) => `${CAT_LABEL[c].slice(0, 3)} ${TATTOOS.filter((t) => t.cat === c && s.tattoos.includes(t.id)).length}`).join(" · ");
  return `<div class="panel wood" style="inset:8px;display:grid;grid-template-columns:200px 1fr;gap:8px">
    <div>
      ${inmateSvg(s)}
      <button class="btn btn-wood" data-act="flip">Перевернуть</button>
      <button class="btn btn-wood" data-act="nav" data-id="wardrobe">Шмот</button>
    </div>
    <div>
      <div class="tabs">${cats.map((c) => `<button class="tab ${s.inkCat === c ? "on" : ""}" data-act="ink-cat" data-id="${c}">${CAT_LABEL[c]}</button>`).join("")}</div>
      <div class="tiny">${counts} · всего ${s.tattoos.length}</div>
      <div class="grid grid-3" style="margin-top:8px;max-height:280px;overflow:auto">
        ${list
          .map((t) => {
            const have = s.tattoos.includes(t.id);
            return `<div class="card">
              <b>${t.name}</b>
              <div class="tiny">${t.cost} ${t.currency} · +${t.auth} авт.</div>
              <button class="btn btn-lime" data-act="tattoo" data-id="${t.id}" ${have ? "disabled" : ""}>${have ? "набито" : "Набить"}</button>
            </div>`;
          })
          .join("")}
      </div>
      <button class="btn btn-gold" data-act="tattoo-set" data-id="${s.inkCat}">Набить сет</button>
    </div>
  </div>`;
}

function wardrobe(s: GameState): string {
  return `<div class="panel wood" style="inset:8px">
    <div class="row" style="justify-content:space-between"><h2>Шмот</h2><button class="btn btn-wood" data-act="nav" data-id="ink">К наколкам</button></div>
    <div class="grid grid-3">${CLOTHES.map((c) => {
      const have = s.clothes.includes(c.id);
      const on = s.worn[c.slot] === c.id;
      return `<div class="card">
        <b>${c.name}</b>
        <div class="tiny">${c.slot} · ${c.cost} ${c.currency} · +${c.auth}</div>
        ${have ? `<button class="btn btn-wood" data-act="wear" data-id="${c.id}">${on ? "на тебе" : "Надеть"}</button>` : `<button class="btn btn-gold" data-act="cloth" data-id="${c.id}">Купить</button>`}
      </div>`;
    }).join("")}</div>
  </div>`;
}

function raids(s: GameState, now: number): string {
  const r = s.raid;
  const list = BOSSES.filter((b) => (s.raidTab === "guard" ? b.kind === "guard" : b.kind !== "guard"));
  return `<div class="panel wood" style="inset:8px">
    <div class="row" style="justify-content:space-between">
      <h2>Разборки</h2>
      <div>
        <button class="tab ${s.raidTab === "inmate" ? "on" : ""}" data-act="raid-tab" data-id="inmate">Беспредел</button>
        <button class="tab ${s.raidTab === "guard" ? "on" : ""}" data-act="raid-tab" data-id="guard">Вертухаи</button>
      </div>
    </div>
    ${
      r
        ? (() => {
            const b = BOSSES.find((x) => x.id === r.bossId)!;
            const pct = (r.hp / r.maxHp) * 100;
            return `<div class="card" style="margin:8px 0;display:grid;grid-template-columns:140px 1fr;gap:8px">
              ${bossSvg(b.name, 20)}
              <div>
                <b>${b.name}</b> · ${MODE_LABEL[r.mode]} · ${fmtMs(r.endsAt - now)}
                <div class="hp" style="margin:8px 0"><i style="width:${pct}%"></i></div>
                <div class="tiny">${money(Math.ceil(r.hp))} / ${money(r.maxHp)} · ударов ${r.playerHits} · корешей ${s.friends.length}</div>
                <div class="row" style="margin-top:8px">
                  <button class="btn btn-lime" data-act="hit" data-id="fist">Пыром (${unarmedDmg(s)})</button>
                  <button class="btn btn-gold" data-act="hit" data-id="poison">Яд ×${s.poison}</button>
                  <button class="btn btn-wood" data-act="hit" data-id="finka">Финка ×${s.finka}</button>
                  <button class="btn btn-red" data-act="hit" data-id="samopal">Самопал ×${s.samopal}</button>
                </div>
                <div class="tiny">Кнопка «позвать» ничего не делает — кореши бьют сами, как в классике.</div>
              </div>
            </div>`;
          })()
        : `<div class="tiny">Окно боя — 8 часов. Проигрыш жжёт ключи. Спарринг с Борзым — без порога.</div>`
    }
    <div class="grid grid-2" style="max-height:220px;overflow:auto;margin-top:8px">
      ${list
        .map((b) => {
          const lock = bossLocked(s, b.id);
          return `<div class="card">
            <b>${b.name}</b> <span class="tiny">${b.title}</span>
            <div class="tiny">HP ${money(b.hp)} · авт. ${b.authGate}${b.keysNeeded ? ` · ключи ${b.keysNeeded}` : ""}</div>
            ${lock ? `<div class="warn tiny">${lock}</div>` : ""}
            <div class="row">
              <button class="btn btn-lime" data-act="raid" data-id="${b.id}" data-mode="patsan" ${lock ? "disabled" : ""}>Пацанский</button>
              <button class="btn btn-wood" data-act="raid" data-id="${b.id}" data-mode="blatnoy" ${lock ? "disabled" : ""}>×3</button>
              <button class="btn btn-gold" data-act="raid" data-id="${b.id}" data-mode="avtoritet" ${lock ? "disabled" : ""}>×6</button>
            </div>
          </div>`;
        })
        .join("")}
    </div>
  </div>`;
}

function inventory(s: GameState): string {
  const ph = phoneProgress(s);
  const es = escapeProgress(s);
  return `<div class="panel wood" style="inset:8px">
    <h2>Нычки и заначки</h2>
    <div class="tiny">Оружие: яд ${s.poison} · финка ${s.finka} · самопал ${s.samopal} · туалетка ${s.tp} · сгущёнка ${s.condensed}</div>
    <div class="tiny">Мобила ${ph.have}/${ph.need} · побег ${es.have}/${es.need} (долгий сбор, не финал кампании)</div>
    <div class="grid grid-3" style="margin-top:8px">
      ${NYCHKA_NAMES.map((n) => {
        const c = s.nychki[n] ?? 0;
        return `<div class="card">
          <b>${n}</b>
          <div class="progress"><i style="width:${Math.min(100, (c / 7) * 100)}%"></i></div>
          <div class="tiny">${c}/7</div>
          <button class="btn btn-lime" data-act="cash" data-id="${n}" ${c < 7 ? "disabled" : ""}>Сдать семёрку</button>
        </div>`;
      }).join("")}
    </div>
    <div class="row" style="margin-top:8px">
      <button class="btn btn-wood" data-act="hidden">Заныканный шмот</button>
      <div class="tiny">Ключи: ${Object.entries(s.keys).map(([k, v]) => `${k}×${v}`).join(", ") || "нет"}</div>
    </div>
  </div>`;
}

function stats(s: GameState): string {
  return `<div class="panel wood" style="inset:8px">
    <h2>Анкетка · ${esc(s.nick)}</h2>
    <div class="grid grid-2">
      <div class="card">
        <div>Уровень ${levelOf(s)} · XP ${s.levelXp}</div>
        <div>Авторитет ${money(s.authority)}</div>
        <div>Бицуха ${s.biceps}</div>
        <div>Уважение зеков ${s.respect}</div>
        <div>Ненависть охраны ${s.hate}</div>
        <div>Мастерство ${s.mastery} · катала ${s.cardSkill}</div>
        <div>Крутизна шмота ${s.hiddenScore} · зарубы ${s.zaruba}</div>
        <div>Наколок ${s.tattoos.length} · медалей ${s.medals.length}</div>
      </div>
      <div class="card">
        <div class="tiny">Энергия: 1 / 5 мин, база 50. Адреналин и сеты поднимают потолок.</div>
        <div class="tiny">Локальный темп ×${s.timeScale} (классика — ×1).</div>
        <div class="row" style="margin-top:8px">
          <button class="btn btn-wood" data-act="scale" data-n="1">×1</button>
          <button class="btn btn-wood" data-act="scale" data-n="12">×12</button>
          <button class="btn btn-gold" data-act="scale" data-n="60">×60</button>
          <button class="btn btn-lime" data-act="skip">+1 час</button>
        </div>
        <div class="row" style="margin-top:8px">
          <button class="btn btn-wood" data-act="nav" data-id="talents">Таланты</button>
          <button class="btn btn-wood" data-act="nav" data-id="rank">ТОП</button>
          <button class="btn btn-red" data-act="reset">Сбросить хату</button>
        </div>
        <div class="tiny" style="margin-top:8px">Тик энергии классики ${ENERGY_TICK_MS / 60000} мин. Чифир — 3 ★ за +50.</div>
      </div>
    </div>
  </div>`;
}

function rank(s: GameState): string {
  const rows = [...RANK_NPC.map(([n, a]) => ({ name: n, auth: a, me: false })), { name: s.nick || "ты", auth: s.authority, me: true }];
  rows.sort((a, b) => b.auth - a.auth);
  return `<div class="panel wood" style="inset:8px">
    <h2>ТОП двора · авторитет</h2>
    <div class="tiny">Публичный рейтинг — это авторитет, не уровень.</div>
    ${rows
      .map(
        (r, i) => `<div class="rank-row ${r.me ? "me" : ""}"><div>${i + 1}</div><div>${esc(r.name)}</div><div>${money(r.auth)}</div></div>`,
      )
      .join("")}
  </div>`;
}

function dailies(s: GameState): string {
  const n = DAILIES.filter((d) => s.dailies[d.id]).length;
  return `<div class="panel leather" style="inset:8px">
    <div class="note">
      <h3>Срочняки · ${n}/${DAILIES.length}</h3>
      ${DAILIES.map((d) => `<div class="task"><b>${d.title}</b> · ${d.hint} ${s.dailies[d.id] ? '<span class="ok">✓</span>' : ""} <span class="tiny">✊${d.auth} 🚬${d.pap}</span></div>`).join("")}
      <div class="tiny">Закрой все — +1 деревянный на слепого кольщика. С ~5 уровня в оригинале; тут открыто сразу.</div>
    </div>
  </div>`;
}

function mail(s: GameState): string {
  return `<div class="panel wood" style="inset:8px">
    <h2>Малява</h2>
    <div class="tiny">Чата комнаты в классике не было — только журнал и стены.</div>
    ${s.mail.map((m) => `<div class="card" style="margin-top:6px"><div class="tiny">${new Date(m.at).toLocaleString("ru")}</div>${esc(m.text)}</div>`).join("") || "<div>Пусто.</div>"}
  </div>`;
}

function gifts(s: GameState): string {
  return `<div class="panel wood" style="inset:8px">
    <h2>Подогревы</h2>
    <div>Сегодня съедено/отослано: ${s.energyGiftToday}/50</div>
    <button class="btn btn-lime" data-act="eat">Съесть передачку корешей</button>
    <div class="tiny" style="margin-top:8px">Батон +3, шоколадка +5 (с 10 ур. в оригинале), колбаса +7. Чифир за ★.</div>
    <button class="btn btn-gold" data-act="buy" data-id="chifir">Чифирнуть · 3★</button>
  </div>`;
}

function friend(s: GameState): string {
  const f = s.friends.find((x) => x.id === s.friendId) ?? s.friends[0];
  if (!f) return `<div class="panel wood">Нет корешей.</div>`;
  return `<div class="cell-bg"></div>
    <div class="panel wood" style="inset:auto 12px 12px 12px;height:150px;position:absolute">
      <h3>Хата ${esc(f.name)}</h3>
      <div class="tiny">бицуха ${f.biceps} · авт. ${f.authority} · вклад в рейд ${f.raidPower.toFixed(2)}</div>
      <div class="row">
        <button class="btn btn-lime" data-act="pump" data-id="${esc(f.id)}">Качнуть бицуху</button>
        <button class="btn btn-wood" data-act="food" data-id="${esc(f.id)}" data-kind="bread">Батон</button>
        <button class="btn btn-wood" data-act="spit" data-id="${esc(f.id)}">Харкнуть</button>
        <button class="btn btn-wood" data-act="yeast" data-id="${esc(f.id)}">Дрожжи</button>
        <button class="btn btn-red" data-act="naezd" data-id="${esc(f.id)}">Наехать · 50</button>
      </div>
    </div>
    <div class="avatar-wrap">${miniFace(f.hue, f.name)}</div>
  `;
}

function workshop(s: GameState): string {
  const ok = levelOf(s) >= WORKSHOP_LEVEL;
  return `<div class="panel wood" style="inset:8px">
    <h2>Мастерская</h2>
    ${ok ? "" : `<div class="warn">Сарай с ${WORKSHOP_LEVEL} уровня (сейчас ${levelOf(s)}).</div>`}
    <div class="grid grid-2" style="margin-top:8px;max-height:340px;overflow:auto">
      ${WORKSHOP.map(
        (m) => `<div class="card">
          <b>${m.name}</b> · ${m.bench}
          <div class="tiny">⚡${m.energy} · 🚬${m.pap} · 🪙${m.rub}</div>
          <button class="btn btn-lime" data-act="craft" data-id="${m.id}" ${ok ? "" : "disabled"}>Смена</button>
        </div>`,
      ).join("")}
    </div>
  </div>`;
}

function talents(s: GameState): string {
  const pts = Math.max(0, 1 + Math.floor(levelOf(s) / 8) - s.talents.length);
  return `<div class="panel wood" style="inset:8px">
    <h2>Таланты · очков ${pts}</h2>
    <div class="tiny">Полное дерево в оригинале стоило тысячи голосов. Тут — ранние узлы 2012-го.</div>
    <div class="grid grid-2">${TALENTS.map((t) => {
      const have = s.talents.includes(t.id);
      return `<div class="card"><b>${t.name}</b><div class="tiny">${t.blurb} · ${t.cost} очк.</div>
        <button class="btn btn-gold" data-act="talent" data-id="${t.id}" ${have ? "disabled" : ""}>${have ? "взято" : "Взять"}</button></div>`;
    }).join("")}</div>
  </div>`;
}

function hidden(s: GameState): string {
  return `<div class="panel wood" style="inset:8px">
    <h2>Заныканный шмот · ${s.hiddenScore}</h2>
    <div class="tiny">12 в хате + 12 у Толяна. Красные слоты: +3 к потолку энергии.</div>
    <div class="grid grid-3">${Array.from({ length: 24 }, (_, i) => {
      const it = s.hiddenSlots[i];
      const red = i >= 12;
      return `<div class="card" style="${red ? "background:#c96a4a" : ""}">${it ?? (red ? "красный" : "пусто")}</div>`;
    }).join("")}</div>
    <div class="row" style="margin-top:8px">
      <button class="btn btn-gold" data-act="roll" data-red="0">Крутить · 2★</button>
      <button class="btn btn-red" data-act="roll" data-red="1">Красный · 4★</button>
    </div>
  </div>`;
}

function cards(s: GameState): string {
  return `<div class="panel wood" style="inset:8px;text-align:center">
    <h2>Терпила</h2>
    <p>Пара 7–туз. За игру всегда +30 папирос. Пара кормит.</p>
    <p class="tiny">Сегодня игр: ${s.cardsToday}. Первая халява, дальше деревянный.</p>
    <button class="btn btn-lime" data-act="cards">Сдать</button>
    <button class="btn btn-wood" data-act="nav" data-id="yard">Во двор</button>
  </div>`;
}

function slot(s: GameState): string {
  return `<div class="panel wood" style="inset:8px;text-align:center">
    <h2>Барабан Толяна</h2>
    <p class="tiny">Кругов сегодня: ${s.slotToday}. Первый бесплатный.</p>
    <button class="btn btn-gold" data-act="slot">Крутить</button>
    <button class="btn btn-wood" data-act="nav" data-id="yard">Во двор</button>
  </div>`;
}

function brigade(s: GameState): string {
  return `<div class="panel wood" style="inset:8px">
    <h2>Бригада</h2>
    ${
      s.brigade.joined
        ? `<p>Ты в «${esc(s.brigade.name)}». Польза считается с рейдов.</p>
           <p class="tiny">Лагеря, повязки и меняла — поздний контент. В v1: состав из корешей, без захвата КПП.</p>
           <div class="grid">${s.friends
             .slice(0, 8)
             .map((f) => `<div class="card">${esc(f.name)} · польза ${Math.min(99, 20 + f.biceps)}%</div>`)
             .join("")}</div>`
        : `<p>Создать бригаду в классике: 2500 деревянных и голова охраны. Тут можно вступить в дворовую.</p>
           <button class="btn btn-lime" data-act="join">Вступить в «Двор-12»</button>`
    }
  </div>`;
}
