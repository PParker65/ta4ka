import { blip } from "./audio";
import { assertEnergyTables } from "./data";
import {
  buyClothes,
  buySet,
  buyShop,
  buyTattoo,
  captureBiz,
  cashNychka,
  collectAll,
  createChar,
  doJob,
  eatFood,
  hitRaid,
  inviteFriend,
  joinBrigade,
  naezd,
  playCards,
  pumpBiceps,
  resolveRaid,
  rollHidden,
  sendFood,
  setScale,
  skipHour,
  spinSlot,
  spit,
  startRaid,
  stealTp,
  stealYard,
  takeTalent,
  upgradeBiz,
  wear,
  workshopJob,
  yeast,
} from "./engine";
import { go, loadState, saveState, tickEnergy, tickRaid, toast } from "./state";
import type { FightMode, GameState, Screen, TattooCat } from "./types";
import { render } from "./ui";
import { setStick, setWorldHandler } from "./world";
import "./styles.css";

assertEnergyTables();

let state: GameState = loadState();
const app = document.getElementById("app")!;

function scaleViewport(): void {
  const vp = app.querySelector(".viewport") as HTMLElement | null;
  if (!vp) return;
  if (vp.classList.contains("live")) {
    vp.style.transform = "";
    return;
  }
  const sx = (window.innerWidth - 16) / 780;
  const sy = (window.innerHeight - 16) / 640;
  const s = Math.min(sx, sy);
  vp.style.transform = `scale(${s})`;
  vp.style.transformOrigin = "center center";
}

function preserveFields(): void {
  const nickEl = app.querySelector("#nick") as HTMLInputElement | null;
  if (nickEl) state.nick = nickEl.value;
}

function paint(): void {
  preserveFields();
  tickEnergy(state);
  const raid = tickRaid(state);
  if (raid.killed) resolveRaid(state, "killed");
  if (raid.failed) resolveRaid(state, "failed");
  const focusNick = document.activeElement?.id === "nick";
  render(app, state, Date.now());
  scaleViewport();
  if (focusNick) {
    const el = app.querySelector("#nick") as HTMLInputElement | null;
    el?.focus();
    el?.setSelectionRange(el.value.length, el.value.length);
  }
}

function commit(sound?: "hit" | "ok" | "no" | "coin"): void {
  saveState(state);
  if (sound) blip(sound);
  paint();
}

function handleAct(el: HTMLElement): void {
  const act = el.dataset.act;
  if (!act) return;
  const id = el.dataset.id ?? "";
  switch (act) {
    case "age":
      state.screen = "gate";
      commit("ok");
      break;
    case "to-create":
      state.screen = "create";
      commit("ok");
      break;
    case "create": {
      const input = app.querySelector("#nick") as HTMLInputElement | null;
      createChar(state, input?.value ?? state.nick);
      commit(state.nick ? "ok" : "no");
      break;
    }
    case "nav":
      go(state, id as Screen);
      if (id === "jobs") go(state, "jobs");
      commit();
      break;
    case "flip":
      state.showBack = !state.showBack;
      commit();
      break;
    case "enter":
      state.zoneId = id;
      go(state, "jobs");
      commit("ok");
      break;
    case "shift":
      state.shift = id === "night" ? "night" : "day";
      commit();
      break;
    case "job":
      doJob(state, id);
      commit("ok");
      break;
    case "collect":
      collectAll(state);
      commit("coin");
      break;
    case "capture":
      captureBiz(state, id);
      commit("ok");
      break;
    case "upgrade":
      upgradeBiz(state, id);
      commit();
      break;
    case "shop-tab":
      state.shopTab = id;
      commit();
      break;
    case "buy":
      buyShop(state, id);
      commit("coin");
      break;
    case "ink-cat":
      state.inkCat = id as TattooCat;
      commit();
      break;
    case "tattoo":
      buyTattoo(state, id);
      commit("ok");
      break;
    case "tattoo-set":
      buySet(state, id as TattooCat);
      commit("ok");
      break;
    case "cloth":
      buyClothes(state, id);
      commit("ok");
      break;
    case "wear":
      wear(state, id);
      commit();
      break;
    case "raid-tab":
      state.raidTab = id === "guard" ? "guard" : "inmate";
      commit();
      break;
    case "raid":
      startRaid(state, id, (el.dataset.mode as FightMode) || "patsan");
      commit("ok");
      break;
    case "hit":
      hitRaid(state, id as "fist" | "poison" | "finka" | "samopal");
      if (state.raid && state.raid.hp <= 0) resolveRaid(state, "killed");
      commit("hit");
      break;
    case "steal":
      stealYard(state);
      commit("coin");
      break;
    case "tp":
      stealTp(state);
      commit("ok");
      break;
    case "cards":
      playCards(state);
      commit("coin");
      break;
    case "slot":
      spinSlot(state);
      commit("coin");
      break;
    case "friend":
      state.friendId = id;
      go(state, "friend");
      commit();
      break;
    case "pump":
      pumpBiceps(state, id);
      commit("ok");
      break;
    case "spit":
      spit(state, id);
      commit("ok");
      break;
    case "yeast":
      yeast(state, id);
      commit();
      break;
    case "naezd":
      naezd(state, id);
      commit("hit");
      break;
    case "food":
      sendFood(state, id, (el.dataset.kind as "bread") || "bread");
      commit("ok");
      break;
    case "eat":
      eatFood(state);
      commit("ok");
      break;
    case "cash":
      cashNychka(state, id);
      commit("coin");
      break;
    case "invite":
      inviteFriend(state);
      commit("ok");
      break;
    case "talent":
      takeTalent(state, id);
      commit("ok");
      break;
    case "craft":
      workshopJob(state, id);
      commit("ok");
      break;
    case "hidden":
      go(state, "hidden");
      commit();
      break;
    case "roll":
      rollHidden(state, el.dataset.red === "1");
      commit("coin");
      break;
    case "join":
      joinBrigade(state);
      commit("ok");
      break;
    case "skip":
      skipHour(state);
      commit();
      break;
    case "scale":
      setScale(state, Number(el.dataset.n || "60"));
      commit();
      break;
    case "sit":
      break;
    case "walk-hall":
    case "walk-cell":
    case "walk-yard":
    case "look-window":
      break;
    case "reset":
      if (window.confirm("Снести хату и начать с нуля?")) {
        localStorage.removeItem("srok-v1");
        state = loadState();
        commit("no");
      }
      break;
    default:
      break;
  }
}

app.addEventListener("click", (e) => {
  const t = (e.target as HTMLElement).closest("[data-act]") as HTMLElement | null;
  if (!t) return;
  handleAct(t);
});

app.addEventListener("input", (e) => {
  const t = e.target as HTMLInputElement;
  if (t.id === "nick") {
    state.nick = t.value;
    return;
  }
  if (t.dataset.act === "face" && t.dataset.k) {
    const k = t.dataset.k as keyof GameState["face"];
    state.face[k] = Number(t.value);
    paint();
  }
});

app.addEventListener("change", (e) => {
  const t = e.target as HTMLInputElement;
  if (t.dataset.act === "face") saveState(state);
});

window.addEventListener("resize", scaleViewport);

setInterval(() => {
  if (state.screen === "boot" || state.screen === "gate" || state.screen === "create") {
    return;
  }
  const before = state.energy;
  const hp = state.raid?.hp ?? 0;
  const toastN = state.toasts.length;
  tickEnergy(state);
  const raid = tickRaid(state);
  if (raid.killed) {
    resolveRaid(state, "killed");
    saveState(state);
    paint();
    return;
  }
  if (raid.failed) {
    resolveRaid(state, "failed");
    saveState(state);
    paint();
    return;
  }
  state.toasts = state.toasts.filter((t) => Date.now() - Math.floor(t.id) < 3200);
  const energyChanged = state.energy !== before;
  const raidTick = Boolean(state.raid && Math.abs((state.raid.hp ?? 0) - hp) > 0.4);
  const toastsChanged = state.toasts.length !== toastN;
  if (energyChanged || raidTick || toastsChanged) {
    saveState(state);
    paint();
  }
}, 500);

if (state.nick && (state.screen === "boot" || state.screen === "gate" || state.screen === "create")) {
  state.screen = "cell";
}

setWorldHandler((a) => {
  const el = document.createElement("button");
  el.dataset.act = a.act;
  if (a.id) el.dataset.id = a.id;
  if (a.mode) el.dataset.mode = a.mode;
  if (a.kind) el.dataset.kind = a.kind;
  handleAct(el);
});

let stickDown = false;
app.addEventListener("pointerdown", (e) => {
  const st = (e.target as HTMLElement).closest("#stick");
  if (!st) return;
  stickDown = true;
  (st as HTMLElement).setPointerCapture(e.pointerId);
  moveStick(st as HTMLElement, e);
});
app.addEventListener("pointermove", (e) => {
  if (!stickDown) return;
  const st = app.querySelector("#stick") as HTMLElement | null;
  if (st) moveStick(st, e);
});
app.addEventListener("pointerup", () => {
  stickDown = false;
  setStick(0, 0);
  const i = app.querySelector("#stick i") as HTMLElement | null;
  if (i) i.style.transform = "";
});

function moveStick(st: HTMLElement, e: PointerEvent): void {
  const r = st.getBoundingClientRect();
  const x = (e.clientX - r.left) / r.width * 2 - 1;
  const y = (e.clientY - r.top) / r.height * 2 - 1;
  const nx = Math.max(-1, Math.min(1, x));
  const ny = Math.max(-1, Math.min(1, y));
  setStick(nx, ny);
  const i = st.querySelector("i") as HTMLElement | null;
  if (i) i.style.transform = `translate(${nx * 22}px, ${ny * 22}px)`;
}

paint();

window.addEventListener("error", (ev) => {
  toast(state, String(ev.message));
  paint();
});
