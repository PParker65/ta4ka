export type Screen =
  | "boot"
  | "gate"
  | "create"
  | "cell"
  | "yard"
  | "map"
  | "jobs"
  | "shop"
  | "ink"
  | "wardrobe"
  | "raids"
  | "inventory"
  | "stats"
  | "rank"
  | "dailies"
  | "mail"
  | "gifts"
  | "friend"
  | "workshop"
  | "talents"
  | "hidden"
  | "cards"
  | "slot"
  | "brigade";

export type Shift = "day" | "night";
export type FightMode = "patsan" | "blatnoy" | "avtoritet";
export type TattooCat = "patsan" | "fraer" | "blat" | "zhigan" | "avtor" | "ponto";
export type Currency = "pap" | "rub" | "sugar" | "tp" | "soap" | "votes";

export interface Job {
  id: string;
  title: string;
  blurb: string;
  energy: number;
  repeats: number;
  authority: number;
  pap: number;
  respect: number;
  hate: number;
  sugar: number;
  loot: number;
}

export interface Zone {
  id: string;
  name: string;
  city: string;
  blurb: string;
  tattoosNeeded: number;
  dayEnergy: number;
  nightEnergy: number;
  phoneParts: number;
  escapeParts: number;
  businessName: string;
  businessKind: "pap" | "respect";
  day: Job[];
  night: Job[];
}

export interface Boss {
  id: string;
  name: string;
  title: string;
  kind: "inmate" | "guard" | "sparring";
  hp: number;
  authGate: number;
  keyFrom: string | null;
  keysNeeded: number;
  riotsZone?: string;
  riotsNeeded?: number;
  rewardAuth: number;
  rewardPap: number;
  rewardKey: string | null;
  cellTheme?: string;
  dailyCap?: number;
}

export interface Tattoo {
  id: string;
  name: string;
  cat: TattooCat;
  slot: string;
  cost: number;
  currency: Currency;
  auth: number;
  dmg: number;
}

export interface Clothes {
  id: string;
  name: string;
  slot: "head" | "torso" | "legs" | "feet" | "extra";
  cost: number;
  currency: Currency;
  auth: number;
}

export interface ShopOffer {
  id: string;
  tab: string;
  name: string;
  blurb: string;
  give: Partial<Record<Currency | "poison" | "finka" | "samopal" | "energy", number>>;
  cost: number;
  currency: Currency;
}

export interface Talent {
  id: string;
  name: string;
  blurb: string;
  cost: number;
}

export interface Daily {
  id: string;
  title: string;
  hint: string;
  auth: number;
  pap: number;
}

export interface Friend {
  id: string;
  name: string;
  hue: number;
  biceps: number;
  authority: number;
  raidPower: number;
  lastPump: number;
}

export interface Raid {
  bossId: string;
  mode: FightMode;
  hp: number;
  maxHp: number;
  startedAt: number;
  endsAt: number;
  lastTick: number;
  keysSpent: number;
  playerHits: number;
}

export interface MailItem {
  id: string;
  at: number;
  text: string;
}

export interface Face {
  jaw: number;
  lips: number;
  eyes: number;
  brow: number;
  skin: number;
}

export interface ZoneSave {
  day: Record<string, number>;
  night: Record<string, number>;
  hodkas: number;
  riots: number;
  bizLevel: number;
  bizAt: number;
  captured: boolean;
}

export interface GameState {
  v: 1;
  nick: string;
  face: Face;
  createdAt: number;
  tutorial: number;
  screen: Screen;
  prev: Screen;
  zoneId: string;
  shift: Shift;
  friendId: string | null;
  inkCat: TattooCat;
  shopTab: string;
  raidTab: "inmate" | "guard";
  timeScale: number;
  levelXp: number;
  authority: number;
  energy: number;
  energyAt: number;
  biceps: number;
  respect: number;
  hate: number;
  mastery: number;
  cardSkill: number;
  cardGames: number;
  hiddenScore: number;
  pap: number;
  rub: number;
  sugar: number;
  tp: number;
  soap: number;
  condensed: number;
  votes: number;
  poison: number;
  finka: number;
  samopal: number;
  tattoos: string[];
  clothes: string[];
  worn: Partial<Record<Clothes["slot"], string>>;
  keys: Record<string, number>;
  medals: string[];
  nychki: Record<string, number>;
  phone: Record<string, number>;
  escape: Record<string, number>;
  talents: string[];
  hiddenSlots: string[];
  zones: Record<string, ZoneSave>;
  raid: Raid | null;
  kirpichToday: number;
  dayStamp: string;
  stolenToday: number;
  cardsToday: number;
  slotToday: number;
  tpToday: boolean;
  energyGiftToday: number;
  nychkaSentToday: number;
  dailies: Record<string, boolean>;
  dailyRub: boolean;
  friends: Friend[];
  mail: MailItem[];
  achievements: string[];
  brigade: { name: string; joined: boolean; xp: number };
  zaruba: number;
  cellTheme: string;
  showBack: boolean;
  toasts: { id: number; text: string }[];
  lastSkip: number;
}
