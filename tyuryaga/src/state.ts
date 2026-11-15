import {
  ENERGY_CAP_BASE,
  ENERGY_TICK_MS,
  FRIEND_NAMES,
  RAID_MS,
  TALENTS,
  ZONES,
} from "./data";
import type { Face, Friend, GameState, MailItem, Screen, ZoneSave } from "./types";

export const SAVE_KEY = "srok-v1";

const defaultFace = (): Face => ({ jaw: 50, lips: 40, eyes: 55, brow: 45, skin: 40 });

function emptyZone(): ZoneSave {
  return {
    day: {},
    night: {},
    hodkas: 0,
    riots: 0,
    bizLevel: 0,
    bizAt: 0,
    captured: false,
  };
}

function hashHue(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return h % 360;
}

export function makeFriend(name: string, i: number): Friend {
  return {
    id: `f-${name}-${i}`,
    name,
    hue: hashHue(name + i),
    biceps: 8 + (i % 20),
    authority: 200 + i * 37,
    raidPower: 0.35 + (i % 7) * 0.12,
    lastPump: 0,
  };
}

export function starterFriends(): Friend[] {
  return FRIEND_NAMES.slice(0, 12).map((n, i) => makeFriend(n, i));
}

export function emptyZones(): Record<string, ZoneSave> {
  const o: Record<string, ZoneSave> = {};
  for (const z of ZONES) o[z.id] = emptyZone();
  return o;
}

export function todayStamp(now = Date.now()): string {
  const d = new Date(now);
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

export function blankState(): GameState {
  const now = Date.now();
  return {
    v: 1,
    nick: "",
    face: defaultFace(),
    createdAt: now,
    tutorial: 0,
    screen: "boot",
    prev: "cell",
    zoneId: "butyrka",
    shift: "day",
    friendId: null,
    inkCat: "patsan",
    shopTab: "pap",
    raidTab: "inmate",
    // Local solo: ×60 so 1 energy / 5s and 8h timers fit a session. ×1 is classic.
    timeScale: 60,
    levelXp: 0,
    authority: 0,
    energy: ENERGY_CAP_BASE,
    energyAt: now,
    biceps: 5,
    respect: 0,
    hate: 0,
    mastery: 0,
    cardSkill: 0,
    cardGames: 0,
    hiddenScore: 0,
    pap: 160,
    rub: 2,
    sugar: 0,
    tp: 1,
    soap: 0,
    condensed: 0,
    votes: 12,
    poison: 2,
    finka: 1,
    samopal: 0,
    tattoos: [],
    clothes: ["cap-black", "shorts", "sneakers"],
    worn: { head: "cap-black", legs: "shorts", feet: "sneakers" },
    keys: {},
    medals: [],
    nychki: {},
    phone: {},
    escape: {},
    talents: [],
    hiddenSlots: [],
    zones: emptyZones(),
    raid: null,
    kirpichToday: 0,
    dayStamp: todayStamp(now),
    stolenToday: 0,
    cardsToday: 0,
    slotToday: 0,
    tpToday: false,
    energyGiftToday: 0,
    nychkaSentToday: 0,
    dailies: {},
    dailyRub: false,
    friends: starterFriends(),
    mail: [
      {
        id: "m0",
        at: now,
        text: "Шило: здорова. Движухи на проходной, папиросы — на стол. Корешей не забывай.",
      },
    ],
    achievements: [],
    brigade: { name: "", joined: false, xp: 0 },
    zaruba: 0,
    cellTheme: "empty",
    showBack: false,
    toasts: [],
    lastSkip: 0,
  };
}

export function energyMax(s: GameState): number {
  let cap = ENERGY_CAP_BASE;
  if (s.talents.includes("adrenalin")) cap += 25;
  if (s.talents.includes("howl")) cap += 15;
  if (s.talents.includes("beast")) cap += 10;
  cap += s.hiddenSlots.filter((x) => x.startsWith("red")).length * 3;
  return cap;
}

export function levelOf(s: GameState): number {
  return Math.min(99, 1 + Math.floor(s.levelXp / 40));
}

export function talentDmg(s: GameState): number {
  let n = 0;
  for (const t of TALENTS) if (s.talents.includes(t.id)) n += 1;
  return n;
}

function rollover(s: GameState, now: number): void {
  const stamp = todayStamp(now);
  if (s.dayStamp === stamp) return;
  s.dayStamp = stamp;
  s.stolenToday = 0;
  s.cardsToday = 0;
  s.slotToday = 0;
  s.tpToday = false;
  s.energyGiftToday = 0;
  s.nychkaSentToday = 0;
  s.dailies = {};
  s.dailyRub = false;
  s.kirpichToday = 0;
}

export function tickEnergy(s: GameState, now = Date.now()): void {
  rollover(s, now);
  const cap = energyMax(s);
  const tick = ENERGY_TICK_MS / Math.max(1, s.timeScale);
  if (s.energy >= cap) {
    s.energyAt = now;
    return;
  }
  const gained = Math.floor((now - s.energyAt) / tick);
  if (gained <= 0) return;
  s.energy = Math.min(cap, s.energy + gained);
  s.energyAt += gained * tick;
  if (s.energy >= cap) s.energyAt = now;
}

export function nextEnergyIn(s: GameState, now = Date.now()): number {
  const cap = energyMax(s);
  if (s.energy >= cap) return 0;
  const tick = ENERGY_TICK_MS / Math.max(1, s.timeScale);
  return Math.max(0, tick - ((now - s.energyAt) % tick));
}

export function tickRaid(s: GameState, now = Date.now()): { killed?: string; failed?: string } {
  const r = s.raid;
  if (!r) return {};
  const dt = Math.max(0, now - r.lastTick) / 1000;
  r.lastTick = now;
  let dps = s.friends.reduce((sum, f) => sum + f.raidPower, 0);
  if (s.talents.includes("eternal")) dps *= 1.2;
  // Local compression: friends were an 8h sponge. Scale DPS with timeScale so a
  // 24-friend starter roster can finish the sparring boss in a sitting.
  dps *= Math.max(1, Math.sqrt(s.timeScale / 8));
  r.hp = Math.max(0, r.hp - dps * dt);
  if (r.hp <= 0) return { killed: r.bossId };
  if (now >= r.endsAt) return { failed: r.bossId };
  return {};
}

export function raidWindowMs(s: GameState): number {
  return RAID_MS / Math.max(1, s.timeScale);
}

export function loadState(): GameState {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return blankState();
    const parsed = JSON.parse(raw) as GameState;
    if (parsed.v !== 1 || typeof parsed.nick !== "string") return blankState();
    parsed.toasts = [];
    const fresh = blankState();
    return { ...fresh, ...parsed, v: 1, toasts: [], face: { ...fresh.face, ...parsed.face } };
  } catch {
    return blankState();
  }
}

export function saveState(s: GameState): void {
  const copy = { ...s, toasts: [] as GameState["toasts"] };
  localStorage.setItem(SAVE_KEY, JSON.stringify(copy));
}

export function pushMail(s: GameState, text: string): void {
  const item: MailItem = { id: `m-${Date.now()}-${Math.random()}`, at: Date.now(), text };
  s.mail = [item, ...s.mail].slice(0, 40);
}

export function toast(s: GameState, text: string): void {
  const id = Date.now() + Math.random();
  s.toasts = [...s.toasts, { id, text }].slice(-5);
}

export function go(s: GameState, screen: Screen): void {
  if (s.screen !== screen) s.prev = s.screen;
  s.screen = screen;
}
