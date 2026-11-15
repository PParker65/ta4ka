import {
  BIZ_UPGRADE_PAP,
  BOSSES,
  BUSINESS_MS,
  CAT_LABEL,
  CLOTHES,
  DAILIES,
  ENERGY_CAP_BASE,
  FRIEND_NAMES,
  HIDDEN_AUTH,
  HODKA_AUTH,
  MODE_HP,
  NAEZD_AUTH,
  NAEZD_COST,
  NIGHT_TATTOOS,
  NYCHKA_NAMES,
  PODGREV_CAP,
  SHOP,
  TALENTS,
  TATTOOS,
  WORKSHOP,
  WORKSHOP_LEVEL,
  YARD_STEAL_CAP,
  ZONES,
  zoneById,
} from "./data";
import {
  energyMax,
  go,
  levelOf,
  makeFriend,
  pushMail,
  raidWindowMs,
  toast,
} from "./state";
import type { Currency, FightMode, GameState, Job } from "./types";

export function pay(s: GameState, n: number, cur: Currency): boolean {
  if (cur === "pap" && s.pap >= n) {
    s.pap -= n;
    return true;
  }
  if (cur === "rub" && s.rub >= n) {
    s.rub -= n;
    return true;
  }
  if (cur === "sugar" && s.sugar >= n) {
    s.sugar -= n;
    return true;
  }
  if (cur === "tp" && s.tp >= n) {
    s.tp -= n;
    return true;
  }
  if (cur === "soap" && s.soap >= n) {
    s.soap -= n;
    return true;
  }
  if (cur === "votes" && s.votes >= n) {
    s.votes -= n;
    return true;
  }
  return false;
}

export function inkBonus(s: GameState): number {
  return TATTOOS.filter((t) => s.tattoos.includes(t.id)).reduce((n, t) => n + t.dmg, 0);
}

export function unarmedDmg(s: GameState): number {
  let d = 8 + Math.floor(s.biceps / 4) + inkBonus(s);
  if (s.talents.includes("unarmed")) d *= 2;
  return d;
}

export function poisonDmg(s: GameState): number {
  let d = 55 + inkBonus(s) * 2;
  if (s.talents.includes("chemist")) d *= 1.25;
  if (s.talents.includes("science")) d *= 1.2;
  return Math.round(d);
}

export function zoneUnlocked(s: GameState, zoneId: string): boolean {
  const z = zoneById(zoneId);
  return s.tattoos.length >= z.tattoosNeeded;
}

export function nightOpen(s: GameState): boolean {
  return s.tattoos.length >= NIGHT_TATTOOS;
}

function grantLoot(s: GameState, job: Job, night: boolean): string[] {
  const notes: string[] = [];
  if (Math.random() < job.loot) {
    const name = NYCHKA_NAMES[Math.floor(Math.random() * NYCHKA_NAMES.length)];
    s.nychki[name] = (s.nychki[name] ?? 0) + 1;
    notes.push(`нычка: ${name}`);
  }
  if (night && Math.random() < 0.08) {
    s.finka += 1;
    notes.push("финка");
  }
  if (night && Math.random() < 0.03) {
    s.samopal += 1;
    notes.push("самопал");
  }
  if (night && Math.random() < 0.12) {
    s.sugar += 1;
    notes.push("сахар");
  }
  return notes;
}

function checkHodka(s: GameState, shift: "day" | "night"): void {
  const z = zoneById(s.zoneId);
  const jobs = shift === "day" ? z.day : z.night;
  const prog = s.zones[z.id][shift];
  const done = jobs.every((j) => (prog[j.id] ?? 0) >= j.repeats);
  if (!done) return;
  s.authority += HODKA_AUTH;
  s.levelXp += 25;
  if (shift === "day") {
    s.zones[z.id].hodkas += 1;
    if ((s.phone[z.id] ?? 0) < z.phoneParts) {
      s.phone[z.id] = (s.phone[z.id] ?? 0) + 1;
      toast(s, `Деталь мобилы (${s.phone[z.id]}/${z.phoneParts})`);
    }
    markDaily(s, "respect");
    toast(s, `Ходка закрыта. +${HODKA_AUTH} авторитета.`);
  } else {
    s.zones[z.id].riots += 1;
    if ((s.escape[z.id] ?? 0) < z.escapeParts) {
      s.escape[z.id] = (s.escape[z.id] ?? 0) + 1;
      toast(s, `Деталь побега (${s.escape[z.id]}/${z.escapeParts})`);
    }
    toast(s, "Бунт! Ночная ходка закрыта.");
  }
  for (const j of jobs) prog[j.id] = 0;
}

export function doJob(s: GameState, jobId: string): void {
  const z = zoneById(s.zoneId);
  const shift = s.shift;
  if (shift === "night" && !nightOpen(s)) {
    toast(s, `Ночь с ${NIGHT_TATTOOS} наколок.`);
    return;
  }
  const job = (shift === "day" ? z.day : z.night).find((j) => j.id === jobId);
  if (!job) return;
  const prog = s.zones[z.id][shift];
  if ((prog[job.id] ?? 0) >= job.repeats) {
    toast(s, "Эта уже закрыта.");
    return;
  }
  if (s.energy < job.energy) {
    toast(s, "Энергии нет. Подожди или чифирни.");
    return;
  }
  s.energy -= job.energy;
  s.levelXp += job.energy;
  s.authority += job.authority;
  s.pap += job.pap;
  s.respect += job.respect;
  s.hate += job.hate;
  s.sugar += job.sugar;
  prog[job.id] = (prog[job.id] ?? 0) + 1;
  const loot = grantLoot(s, job, shift === "night");
  markDaily(s, "rise");
  toast(
    s,
    `${job.title}: +${job.pap} пап. +${job.authority} авт.${loot.length ? " · " + loot.join(", ") : ""}`,
  );
  checkHodka(s, shift);
}

export function captureBiz(s: GameState, zoneId: string): void {
  if (!zoneUnlocked(s, zoneId)) return;
  const z = s.zones[zoneId];
  if (z.captured) return;
  if (!pay(s, 50, "pap")) {
    toast(s, "50 папирос на крышу.");
    return;
  }
  z.captured = true;
  z.bizLevel = 1;
  z.bizAt = Date.now();
  toast(s, `${zoneById(zoneId).businessName} под крышей.`);
}

export function upgradeBiz(s: GameState, zoneId: string): void {
  const z = s.zones[zoneId];
  if (!z.captured) return;
  if (!pay(s, BIZ_UPGRADE_PAP, "pap")) {
    toast(s, `${BIZ_UPGRADE_PAP} папирос за уровень.`);
    return;
  }
  z.bizLevel += 1;
  toast(s, `Крыша ${zoneById(zoneId).businessName}: ур. ${z.bizLevel}`);
}

export function collectAll(s: GameState): void {
  const wait = BUSINESS_MS / Math.max(1, s.timeScale);
  let pap = 0;
  let auth = 0;
  let respect = 0;
  let n = 0;
  const now = Date.now();
  for (const zone of ZONES) {
    const z = s.zones[zone.id];
    if (!z.captured || z.bizLevel < 1) continue;
    if (now - z.bizAt < wait) continue;
    const hours = Math.min(3, Math.floor((now - z.bizAt) / wait) || 1);
    if (zone.businessKind === "respect") {
      respect += (4 + z.bizLevel * 2) * hours;
    } else {
      pap += (18 + z.bizLevel * 8) * hours;
      auth += (2 + z.bizLevel) * hours;
    }
    z.bizAt = now;
    n += 1;
  }
  if (!n) {
    toast(s, "Пока пусто. Крыша отдаёт раз в 8 часов.");
    return;
  }
  s.pap += pap;
  s.authority += auth;
  s.respect += respect;
  markDaily(s, "profit");
  toast(s, `Собрали с ${n} точек: +${pap} пап. +${auth} авт.`);
}

export function bizReady(s: GameState, zoneId: string, now = Date.now()): boolean {
  const z = s.zones[zoneId];
  if (!z.captured) return false;
  return now - z.bizAt >= BUSINESS_MS / Math.max(1, s.timeScale);
}

export function buyTattoo(s: GameState, id: string): void {
  const t = TATTOOS.find((x) => x.id === id);
  if (!t || s.tattoos.includes(id)) return;
  if (!pay(s, t.cost, t.currency)) {
    toast(s, "Не хватает на наколку.");
    return;
  }
  s.tattoos = [...s.tattoos, id];
  s.authority += t.auth;
  toast(s, `${t.name}. +${t.auth} авторитета.`);
}

export function buySet(s: GameState, cat: (typeof TATTOOS)[0]["cat"]): void {
  const list = TATTOOS.filter((t) => t.cat === cat && !s.tattoos.includes(t.id));
  if (!list.length) {
    toast(s, "Сет уже набит.");
    return;
  }
  for (const t of list) buyTattoo(s, t.id);
  toast(s, `Набить сет: ${CAT_LABEL[cat]}`);
}

export function buyClothes(s: GameState, id: string): void {
  const c = CLOTHES.find((x) => x.id === id);
  if (!c || s.clothes.includes(id)) return;
  if (!pay(s, c.cost, c.currency)) {
    toast(s, "Мало на шмот.");
    return;
  }
  s.clothes = [...s.clothes, id];
  s.worn[c.slot] = id;
  s.authority += c.auth;
  toast(s, `${c.name} сел как влитой.`);
}

export function wear(s: GameState, id: string): void {
  const c = CLOTHES.find((x) => x.id === id);
  if (!c || !s.clothes.includes(id)) return;
  s.worn[c.slot] = id;
}

export function buyShop(s: GameState, id: string): void {
  const o = SHOP.find((x) => x.id === id);
  if (!o) return;
  if (!pay(s, o.cost, o.currency)) {
    toast(s, "Толян не в кредит.");
    return;
  }
  if (o.give.pap) s.pap += o.give.pap;
  if (o.give.rub) s.rub += o.give.rub;
  if (o.give.sugar) s.sugar += o.give.sugar;
  if (o.give.tp) s.tp += o.give.tp;
  if (o.give.soap) s.soap += o.give.soap;
  if (o.give.votes) s.votes += o.give.votes;
  if (o.give.poison) s.poison += o.give.poison;
  if (o.give.finka) s.finka += o.give.finka;
  if (o.give.samopal) s.samopal += o.give.samopal;
  if (o.give.energy) {
    s.energy = Math.min(energyMax(s) + 20, s.energy + o.give.energy);
  }
  toast(s, `${o.name} — зачётно.`);
}

export function bossById(id: string) {
  const b = BOSSES.find((x) => x.id === id);
  if (!b) throw new Error(id);
  return b;
}

export function bossLocked(s: GameState, id: string): string | null {
  const b = bossById(id);
  if (s.authority < b.authGate) return `Нужно ${b.authGate} авторитета.`;
  if (b.id === "zoya" && s.hiddenScore < 70) return "Нужна крутизна заныканного шмота 70.";
  if (b.id === "twins" && s.hiddenScore < 50) return "Нужна крутизна 50.";
  if (b.id === "kolya" && s.zaruba < 50) return "Нужен 50-й уровень заруба.";
  if (b.riotsZone && (s.zones[b.riotsZone]?.riots ?? 0) < (b.riotsNeeded ?? 0)) {
    return `Нужно ${b.riotsNeeded} бунта в «${zoneById(b.riotsZone).name}».`;
  }
  if (b.keysNeeded > 0 && b.keyFrom) {
    const have = s.keys[b.keyFrom] ?? 0;
    if (have < b.keysNeeded) return `Ключи: ${have}/${b.keysNeeded}.`;
  }
  if (b.id === "plita" && s.kirpichToday >= 6) return "Плита сегодня уже сыт (6/6).";
  return null;
}

export function startRaid(s: GameState, bossId: string, mode: FightMode): void {
  if (s.raid) {
    toast(s, "Сначала добей текущую разборку.");
    return;
  }
  const lock = bossLocked(s, bossId);
  if (lock) {
    toast(s, lock);
    return;
  }
  const b = bossById(bossId);
  let spent = 0;
  if (b.keysNeeded > 0 && b.keyFrom) {
    s.keys[b.keyFrom] -= b.keysNeeded;
    spent = b.keysNeeded;
  }
  const hp = Math.round(b.hp * (MODE_HP[mode] ?? 1));
  const now = Date.now();
  s.raid = {
    bossId,
    mode,
    hp,
    maxHp: hp,
    startedAt: now,
    endsAt: now + raidWindowMs(s),
    lastTick: now,
    keysSpent: spent,
    playerHits: 0,
  };
  go(s, "raids");
  toast(s, `${b.name}: окно 8 часов. Кореши бьют сами.`);
}

export function hitRaid(s: GameState, weapon: "fist" | "poison" | "finka" | "samopal"): void {
  if (!s.raid) return;
  let dmg = 0;
  if (weapon === "fist") dmg = unarmedDmg(s);
  if (weapon === "poison") {
    if (s.poison < 1) {
      toast(s, "Яд кончился.");
      return;
    }
    s.poison -= 1;
    dmg = poisonDmg(s);
  }
  if (weapon === "finka") {
    if (s.finka < 1) {
      toast(s, "Финки нет.");
      return;
    }
    s.finka -= 1;
    dmg = 28 + inkBonus(s);
  }
  if (weapon === "samopal") {
    if (s.samopal < 1) {
      toast(s, "Самопал молчит.");
      return;
    }
    s.samopal -= 1;
    dmg = 90 + inkBonus(s) * 2;
  }
  if (Math.random() < 0.12 + inkBonus(s) * 0.01) dmg *= 2;
  s.raid.hp = Math.max(0, s.raid.hp - dmg);
  s.raid.playerHits += 1;
  s.zaruba += 1;
  toast(s, `−${dmg}`);
}

export function resolveRaid(s: GameState, kind: "killed" | "failed"): void {
  const r = s.raid;
  if (!r) return;
  const b = bossById(r.bossId);
  s.raid = null;
  if (kind === "failed") {
    toast(s, `${b.name} устоял. Ключи сгорели.`);
    pushMail(s, `${b.name} не лёг за 8 часов. Ключи потеряны.`);
    return;
  }
  s.authority += b.rewardAuth;
  s.pap += b.rewardPap;
  if (b.rewardKey) s.keys[b.rewardKey] = (s.keys[b.rewardKey] ?? 0) + 1;
  if (b.cellTheme) s.cellTheme = b.cellTheme;
  if (b.id === "plita") s.kirpichToday += 1;
  s.medals = [...new Set([...s.medals, b.id])];
  if (b.id === "sparring") markDaily(s, "naezd");
  toast(s, `${b.name} лёг. +${b.rewardAuth} авт. +${b.rewardPap} пап.`);
  pushMail(s, `Разборка: ${b.name} закрыт.`);
}

export function stealYard(s: GameState): void {
  if (s.stolenToday >= YARD_STEAL_CAP) {
    toast(s, "Лохи пустые до завтра (300/день).");
    return;
  }
  const n = 8 + Math.floor(Math.random() * 18);
  const got = Math.min(n, YARD_STEAL_CAP - s.stolenToday);
  s.stolenToday += got;
  s.pap += got;
  toast(s, `С лоха +${got} папирос.`);
}

export function stealTp(s: GameState): void {
  if (s.tpToday) {
    toast(s, "Толян уже не зевает.");
    return;
  }
  s.tpToday = true;
  s.tp += 1;
  toast(s, "Рулон. Он отвернулся.");
}

export function playCards(s: GameState): void {
  if (s.cardsToday >= 1 && !pay(s, 1, "rub")) {
    toast(s, "Бесплатная одна. Дальше — деревянный.");
    return;
  }
  s.cardsToday += 1;
  s.cardGames += 1;
  s.pap += 30;
  const ranks = [7, 8, 9, 10, 11, 12, 13, 14];
  const a = ranks[Math.floor(Math.random() * ranks.length)];
  const b = ranks[Math.floor(Math.random() * ranks.length)];
  let extra = 0;
  let auth = 0;
  if (a === b) {
    extra = 100 + (a - 7) * 120;
    auth = a === 7 ? 30 : a === 9 ? 100 : 40 + a * 4;
    s.pap += extra;
    s.authority += auth;
  }
  s.cardSkill += 1;
  if (s.cardGames % 10 === 0) {
    s.pap += 50;
    s.authority += 50;
    toast(s, "Мастерство каталы: +50 пап. +50 авт.");
  }
  markDaily(s, "naezd");
  toast(s, a === b ? `Пара ${a}: +${30 + extra} пап. +${auth} авт.` : `Карты ${a} и ${b}. +30 пап.`);
}

export function spinSlot(s: GameState): void {
  if (s.slotToday >= 1 && !pay(s, 15, "pap")) {
    toast(s, "Бесплатный один круг.");
    return;
  }
  s.slotToday += 1;
  const roll = Math.random();
  if (roll < 0.08) {
    s.pap += 200;
    toast(s, "Барабан: 200 папирос!");
  } else if (roll < 0.2) {
    s.sugar += 2;
    toast(s, "Барабан: сахар.");
  } else if (roll < 0.45) {
    s.pap += 40;
    toast(s, "Барабан: 40 папирос.");
  } else {
    toast(s, "Барабан пустой. Бывает.");
  }
}

export function pumpBiceps(s: GameState, friendId: string): void {
  const f = s.friends.find((x) => x.id === friendId);
  if (!f) return;
  const now = Date.now();
  if (now - f.lastPump < 20 * 60 * 1000 / Math.max(1, s.timeScale / 10)) {
    toast(s, "Гиря остывает.");
    return;
  }
  f.lastPump = now;
  f.biceps += 1;
  s.biceps += 1;
  toast(s, `${f.name}: бицуха +1. Он качнёт и тебя.`);
}

export function spit(s: GameState, friendId: string): void {
  const f = s.friends.find((x) => x.id === friendId);
  if (!f) return;
  markDaily(s, "spit");
  pushMail(s, `Ты харкнул в баланду ${f.name}.`);
  toast(s, "П-тю. Дневное закрыто.");
}

export function yeast(s: GameState, friendId: string): void {
  const f = s.friends.find((x) => x.id === friendId);
  if (!f) return;
  pushMail(s, `Дрожжи в парашу: ${f.name}.`);
  toast(s, "Пусть бродит.");
}

export function naezd(s: GameState, friendId: string): void {
  const f = s.friends.find((x) => x.id === friendId);
  if (!f) return;
  if (s.authority < NAEZD_AUTH) {
    toast(s, `Наезд с ${NAEZD_AUTH} авторитета.`);
    return;
  }
  if (!pay(s, NAEZD_COST, "pap")) {
    toast(s, "50 папирос на наезд.");
    return;
  }
  const mine = s.authority + s.biceps * 10;
  const his = f.authority + f.biceps * 10;
  if (mine >= his) {
    s.authority += 7;
    toast(s, `Наезд зашёл. +7 авторитета.`);
  } else {
    toast(s, `${f.name} оказался борзее.`);
  }
}

export function sendFood(s: GameState, friendId: string, kind: "bread" | "choco" | "kolbasa"): void {
  const f = s.friends.find((x) => x.id === friendId);
  if (!f) return;
  const cost = kind === "bread" ? 8 : kind === "choco" ? 14 : 22;
  const energy = kind === "bread" ? 3 : kind === "choco" ? 5 : 7;
  if (s.energyGiftToday + energy > PODGREV_CAP) {
    toast(s, "Подогрев на сегодня закрыт (50).");
    return;
  }
  if (!pay(s, cost, "pap")) {
    toast(s, "Папирос на передачку мало.");
    return;
  }
  s.energyGiftToday += energy;
  markDaily(s, "gift");
  toast(s, `${f.name} получил ${energy} энергии.`);
}

export function eatFood(s: GameState): void {
  if (s.energyGiftToday >= PODGREV_CAP) {
    toast(s, "Сыт.");
    return;
  }
  const add = Math.min(7, PODGREV_CAP - s.energyGiftToday);
  s.energyGiftToday += add;
  s.energy = Math.min(energyMax(s) + 9, s.energy + add);
  toast(s, `Подогрев от корешей: +${add}`);
}

export function cashNychka(s: GameState, name: string): void {
  const n = s.nychki[name] ?? 0;
  if (n < 7) {
    toast(s, "Собери 7 штук.");
    return;
  }
  s.nychki[name] = n - 7;
  s.pap += 80;
  s.authority += 50 + Math.min(110, zoneById(s.zoneId).dayEnergy / 8);
  toast(s, `${name}: семёрка сдана.`);
}

export function sendNychka(s: GameState, friendId: string, name: string): void {
  if ((s.nychki[name] ?? 0) < 1) return;
  if (s.nychkaSentToday >= 50) {
    toast(s, "Лимит маляв.");
    return;
  }
  s.nychki[name] -= 1;
  s.nychkaSentToday += 1;
  const f = s.friends.find((x) => x.id === friendId);
  toast(s, `${name} ушёл к ${f?.name ?? "корешу"}.`);
}

export function inviteFriend(s: GameState): void {
  const used = new Set(s.friends.map((f) => f.name));
  const pool = FRIEND_NAMES.filter((n) => !used.has(n));
  const extra = ["Рыжий", "Карп", "Шуруп", "Мотя", "Ганс", "Валет", "Крот", "Бугор"];
  const name = pool[0] ?? extra[s.friends.length % extra.length] + " " + (s.friends.length + 1);
  s.friends.push(makeFriend(name, s.friends.length));
  toast(s, `${name} зашёл в хату. Теперь бьёт твоих боссов.`);
}

export function takeTalent(s: GameState, id: string): void {
  const t = TALENTS.find((x) => x.id === id);
  if (!t || s.talents.includes(id)) return;
  const pts = 1 + Math.floor(levelOf(s) / 8) - s.talents.length;
  if (pts < t.cost) {
    toast(s, "Очков таланта мало.");
    return;
  }
  s.talents = [...s.talents, id];
  if (id === "adrenalin" || id === "howl" || id === "beast") {
    s.energy = Math.min(energyMax(s), s.energy + 10);
  }
  toast(s, t.name);
}

export function workshopJob(s: GameState, id: string): void {
  if (levelOf(s) < WORKSHOP_LEVEL) {
    toast(s, `Мастерская с ${WORKSHOP_LEVEL} уровня.`);
    return;
  }
  const m = WORKSHOP.find((x) => x.id === id);
  if (!m) return;
  if (s.energy < m.energy) {
    toast(s, "Энергии на смену не хватит.");
    return;
  }
  if (s.pap < m.pap || s.rub < m.rub) {
    toast(s, "Инструмент не бесплатный.");
    return;
  }
  s.energy -= m.energy;
  s.pap -= m.pap;
  s.rub -= m.rub;
  s.mastery += 8;
  s.authority += 12;
  if (Math.random() < 0.4) {
    const name = NYCHKA_NAMES[Math.floor(Math.random() * NYCHKA_NAMES.length)];
    s.nychki[name] = (s.nychki[name] ?? 0) + 1;
  }
  toast(s, `${m.name}: мастерство +8.`);
}

export function markDaily(s: GameState, id: string): void {
  if (s.dailies[id]) return;
  const d = DAILIES.find((x) => x.id === id);
  if (!d) return;
  s.dailies[id] = true;
  s.authority += d.auth;
  s.pap += d.pap;
  if (DAILIES.every((x) => s.dailies[x.id]) && !s.dailyRub) {
    s.dailyRub = true;
    s.rub += 1;
    toast(s, "Срочняки закрыты. +1 деревянный.");
  }
}

export function skipHour(s: GameState): void {
  const now = Date.now();
  if (now - s.lastSkip < 400) return;
  s.lastSkip = now;
  const ms = 60 * 60 * 1000;
  s.energyAt -= ms;
  for (const z of Object.values(s.zones)) {
    if (z.captured) z.bizAt -= ms;
  }
  if (s.raid) {
    s.raid.startedAt -= ms;
    s.raid.lastTick -= ms;
    // keep endsAt so the window still closes on schedule; damage is ticked by engine
  }
  toast(s, "Срок прыгнул на час (локально).");
}

export function setScale(s: GameState, n: number): void {
  s.timeScale = n;
  toast(s, n === 1 ? "Классика: 1 энергия / 5 мин." : `Темп ×${n} (локальная версия).`);
}

export function openHidden(s: GameState): void {
  if (s.authority < HIDDEN_AUTH) {
    toast(s, `Заныканный шмот с ${HIDDEN_AUTH} авторитета.`);
    return;
  }
  go(s, "hidden");
}

export function rollHidden(s: GameState, red: boolean): void {
  if (s.authority < HIDDEN_AUTH) return;
  const cost = red ? 4 : 2;
  if (!pay(s, cost, "votes")) {
    toast(s, "Толян крутит за голоса.");
    return;
  }
  const id = `${red ? "red" : "n"}-${s.hiddenSlots.length}`;
  s.hiddenSlots = [...s.hiddenSlots, id].slice(0, 24);
  s.hiddenScore += red ? 8 : 3;
  s.biceps += red ? 2 : 1;
  toast(s, red ? "Красный слот." : "Заныкали.");
}

export function joinBrigade(s: GameState): void {
  if (s.brigade.joined) return;
  s.brigade = { name: "Двор-12", joined: true, xp: 0 };
  toast(s, "Приняли в «Двор-12». Лагеря в v1 — заглушка.");
}

export function createChar(s: GameState, nick: string): void {
  const n = nick.trim().slice(0, 18);
  if (n.length < 2) {
    toast(s, "Кликуха короче двух букв не живёт.");
    return;
  }
  s.nick = n;
  s.tutorial = 2;
  s.screen = "cell";
  s.energy = ENERGY_CAP_BASE;
  pushMail(s, `Шило: ну здарова, ${n}. Камера пустая — сам забьёшь.`);
  toast(s, "Камера твоя. Дверь — во двор.");
}

export function phoneProgress(s: GameState): { have: number; need: number } {
  let have = 0;
  let need = 0;
  for (const z of ZONES) {
    have += s.phone[z.id] ?? 0;
    need += z.phoneParts;
  }
  return { have, need };
}

export function escapeProgress(s: GameState): { have: number; need: number } {
  let have = 0;
  let need = 0;
  for (const z of ZONES) {
    have += s.escape[z.id] ?? 0;
    need += z.escapeParts;
  }
  return { have, need };
}

export function holderOf(s: GameState, zoneId: string): string {
  const z = s.zones[zoneId];
  if ((z?.captured && s.respect > 40) || s.nick) {
    if (s.respect >= 80) return s.nick || "ты";
  }
  const fake = ["Хмурый", "Бугор", "Карп", "Седой"];
  return fake[zoneId.length % fake.length];
}
