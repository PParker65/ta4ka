import { CLOTHES, TATTOOS } from "./data";
import type { Face, GameState } from "./types";

function clamp(n: number, a: number, b: number): number {
  return Math.max(a, Math.min(b, n));
}

const SKIN = ["#c99570", "#d4a574", "#e0b080", "#c4845c", "#a86b48", "#8d5638"];

export function skinTone(face: Face): string {
  return SKIN[clamp(Math.floor((face.skin / 100) * SKIN.length), 0, SKIN.length - 1)];
}

function inkOn(s: GameState, slot: string): boolean {
  return TATTOOS.some((t) => t.slot === slot && s.tattoos.includes(t.id));
}

function anyCat(s: GameState, cat: string): boolean {
  return TATTOOS.some((t) => t.cat === cat && s.tattoos.includes(t.id));
}

export function miniFace(hue: number, name: string): string {
  const skin = `hsl(${(hue * 0.15 + 24).toFixed(0)} 48% 62%)`;
  const hair = `hsl(${hue} 18% 16%)`;
  const shirt = `hsl(${hue} 28% 32%)`;
  const initial = name.slice(0, 1);
  return `<svg viewBox="0 0 64 80" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
    <rect width="64" height="80" fill="#3a2a18"/>
    <rect x="16" y="46" width="32" height="32" rx="6" fill="${shirt}"/>
    <circle cx="32" cy="32" r="16" fill="${skin}"/>
    <path d="M16 30 Q32 8 48 30" fill="${hair}"/>
    <circle cx="26" cy="34" r="2.2" fill="#1a120c"/>
    <circle cx="38" cy="34" r="2.2" fill="#1a120c"/>
    <text x="32" y="72" text-anchor="middle" font-size="9" fill="#e6c36a" font-family="serif">${initial}</text>
  </svg>`;
}

export function inmateSvg(s: GameState, opts?: { back?: boolean }): string {
  const back = opts?.back ?? s.showBack;
  const skin = skinTone(s.face);
  const jaw = 18 + (s.face.jaw / 100) * 10;
  const lip = 1.5 + (s.face.lips / 100) * 3;
  const eye = 2.2 + (s.face.eyes / 100) * 2.2;
  const brow = s.face.brow / 100;
  const cap = s.worn.head;
  const legs = s.worn.legs;
  const feet = s.worn.feet;
  const torso = s.worn.torso;
  const extra = s.worn.extra;
  const capFill = cap === "ushanka" ? "#5a4330" : cap === "cap-knit" ? "#222" : "#111";
  const shorts = legs === "sweats" ? "#2c2c2c" : "#111";
  const neon = "#c8ff3a";
  const shoe = feet === "red-slippers" ? "#b42a2a" : feet === "slippers" ? "#d9c29a" : "#111";
  const shirt = torso === "robe" ? "#6e5a3a" : torso === "wifebeater" ? "#eee8d8" : "none";

  const tattoosFront = `
    ${inkOn(s, "chest") || anyCat(s, "avtor") ? `<g fill="none" stroke="#1a120c" stroke-width="1.3">
      <path d="M70 118 Q80 108 90 118 Q80 128 70 118"/>
      <circle cx="80" cy="118" r="7"/>
    </g>` : ""}
    ${inkOn(s, "shoulder-l") ? `<path d="M52 108 q8 -10 16 0 q-8 8 -16 0" fill="#1a120c"/>` : ""}
    ${inkOn(s, "shoulder-r") ? `<path d="M92 108 q8 -10 16 0 q-8 8 -16 0" fill="#1a120c"/>` : ""}
    ${inkOn(s, "forearm-l") ? `<g stroke="#1a120c" fill="none" stroke-width="1.2">
      <circle cx="46" cy="150" r="7"/><path d="M46 143 v14 M39 150 h14"/>
    </g>` : ""}
    ${inkOn(s, "forearm-r") ? `<path d="M110 142 l6 12 -8 2 z" fill="#1a120c"/>` : ""}
    ${inkOn(s, "neck") ? `<path d="M72 96 q8 8 16 0" fill="none" stroke="#1a120c" stroke-width="1.4"/>` : ""}
    ${inkOn(s, "elbow") ? `<path d="M48 132 l6 6 -6 6 -6 -6z" fill="#1a120c"/>` : ""}
    ${inkOn(s, "calf-l") ? `<path d="M64 210 q6 -10 12 0" fill="none" stroke="#1a120c"/>` : ""}
    ${inkOn(s, "calf-r") ? `<path d="M84 210 q6 -10 12 0" fill="none" stroke="#1a120c"/>` : ""}
    ${inkOn(s, "hand-l") ? `<circle cx="42" cy="176" r="2.2" fill="#1a120c"/>` : ""}
    ${inkOn(s, "hand-r") ? `<circle cx="118" cy="176" r="2.2" fill="#1a120c"/>` : ""}
    ${inkOn(s, "torso") ? `<path d="M68 130 h24" stroke="#1a120c" stroke-width="2"/>` : ""}
    ${inkOn(s, "ribs") ? `<path d="M64 138 q16 8 32 0" fill="none" stroke="#1a120c"/>` : ""}
    ${inkOn(s, "arm-l") ? `<path d="M50 120 q-8 20 0 40" fill="none" stroke="#1a120c" stroke-width="1.4"/>` : ""}
    ${inkOn(s, "arm-r") ? `<path d="M110 120 q8 20 0 40" fill="none" stroke="#1a120c" stroke-width="1.4"/>` : ""}
  `;

  const tattoosBack = `
    ${inkOn(s, "back") || anyCat(s, "blat") ? `<g fill="none" stroke="#1a120c" stroke-width="1.3">
      <path d="M80 112 q-14 18 0 36 q14 -18 0 -36"/>
      <path d="M70 124 h20"/>
      <circle cx="80" cy="120" r="5"/>
    </g>` : ""}
    ${inkOn(s, "shoulder-l") ? `<rect x="52" y="108" width="10" height="8" rx="2" fill="#1a120c"/>` : ""}
    ${inkOn(s, "shoulder-r") ? `<rect x="98" y="108" width="10" height="8" rx="2" fill="#1a120c"/>` : ""}
    ${s.tattoos.length > 8 ? `<path d="M62 150 q18 12 36 0" fill="none" stroke="#1a120c"/>` : ""}
  `;

  const head = back
    ? `<ellipse cx="80" cy="62" rx="${jaw - 2}" ry="22" fill="${skin}"/>
       <path d="M62 52 Q80 38 98 52 Q96 44 80 42 Q64 44 62 52" fill="#1a1a1a"/>`
    : `<ellipse cx="80" cy="62" rx="${jaw}" ry="22" fill="${skin}"/>
       <path d="M${80 - jaw + 2} 54 Q80 ${38 - brow * 6} ${80 + jaw - 2} 54" fill="#1a1a1a"/>
       <ellipse cx="${80 - 7}" cy="64" rx="${eye}" ry="${eye * 0.85}" fill="#1d120a"/>
       <ellipse cx="${80 + 7}" cy="64" rx="${eye}" ry="${eye * 0.85}" fill="#1d120a"/>
       <ellipse cx="${80 - 7.4}" cy="63.4" rx="0.8" ry="0.8" fill="#f3e2c8"/>
       <ellipse cx="${80 + 6.6}" cy="63.4" rx="0.8" ry="0.8" fill="#f3e2c8"/>
       <path d="M76 70 q4 3 8 0" fill="none" stroke="#6a3e28" stroke-width="1.2"/>
       <path d="M74 ${76} q6 ${lip} 12 0" fill="#8a3a3a" stroke="#5a2424" stroke-width="0.6"/>
       <path d="M68 58 q4 -${2 + brow * 3} 8 0" fill="none" stroke="#2a1a10" stroke-width="1.4"/>
       <path d="M84 58 q4 -${2 + brow * 3} 8 0" fill="none" stroke="#2a1a10" stroke-width="1.4"/>`;

  const capSvg =
    cap === "ushanka"
      ? `<ellipse cx="80" cy="46" rx="24" ry="12" fill="${capFill}"/><ellipse cx="56" cy="58" rx="8" ry="10" fill="${capFill}"/><ellipse cx="104" cy="58" rx="8" ry="10" fill="${capFill}"/>`
      : `<path d="M58 50 Q80 32 102 50 L100 56 Q80 48 60 56 Z" fill="${capFill}"/><rect x="54" y="50" width="36" height="6" rx="2" fill="${capFill}"/>`;

  const shirtSvg =
    shirt === "none"
      ? ""
      : torso === "robe"
        ? `<path d="M54 102 q26 10 52 0 v70 q-26 8 -52 0 z" fill="${shirt}" stroke="#3a2a18"/>`
        : `<path d="M62 102 h36 v40 h-36 z" fill="${shirt}"/><path d="M70 102 l10 40 l10 -40" fill="none" stroke="#ccc"/>`;

  const beads = extra === "beads" ? `<circle cx="80" cy="98" r="3" fill="#c9a227"/><circle cx="72" cy="100" r="2.4" fill="#7a1c1c"/><circle cx="88" cy="100" r="2.4" fill="#7a1c1c"/>` : "";
  const chain = extra === "chain-gold" ? `<path d="M68 96 q12 10 24 0" fill="none" stroke="#e6c36a" stroke-width="2"/>` : "";

  return `<svg class="inmate" viewBox="0 0 160 280" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="${s.nick || "зек"}">
    <ellipse cx="80" cy="270" rx="48" ry="8" fill="rgba(0,0,0,.35)"/>
    <g class="stool">
      <rect x="44" y="196" width="72" height="14" rx="3" fill="#9a6230" stroke="#5a3616"/>
      <rect x="50" y="210" width="9" height="52" fill="#6d441c"/>
      <rect x="101" y="210" width="9" height="52" fill="#6d441c"/>
      <rect x="48" y="258" width="14" height="6" fill="#5a3616"/>
      <rect x="98" y="258" width="14" height="6" fill="#5a3616"/>
    </g>
    <path d="M54 176 l-6 28 22 8 8 -30z" fill="${skin}"/>
    <path d="M106 176 l6 28 -22 8 -8 -30z" fill="${skin}"/>
    <path d="M46 202 v52" stroke="${skin}" stroke-width="16" stroke-linecap="round"/>
    <path d="M114 202 v52" stroke="${skin}" stroke-width="16" stroke-linecap="round"/>
    <path d="M52 168 h56 v36 q-28 16 -56 0 z" fill="${shorts}"/>
    <rect x="52" y="166" width="56" height="6" fill="${neon}"/>
    <ellipse cx="48" cy="262" rx="13" ry="8" fill="${shoe}"/>
    <ellipse cx="112" cy="262" rx="13" ry="8" fill="${shoe}"/>
    <path d="M80 96 l-30 12 10 70 h40 l10 -70 z" fill="${skin}"/>
    ${shirtSvg}
    ${back ? tattoosBack : tattoosFront}
    <path d="M52 106 l-16 64 12 8 12 -60" fill="${skin}"/>
    <path d="M108 106 l16 64 -12 8 -12 -60" fill="${skin}"/>
    <circle cx="38" cy="176" r="7" fill="${skin}"/>
    <circle cx="122" cy="176" r="7" fill="${skin}"/>
    ${head}
    ${capSvg}
    ${beads}${chain}
    ${s.medals.length ? `<g transform="translate(118,92)">${s.medals.slice(0, 3).map((_, i) => `<circle cx="0" cy="${i * 10}" r="4" fill="#c9a227" stroke="#7a5a12"/>`).join("")}</g>` : ""}
  </svg>`;
}

export function dealerSvg(): string {
  return `<svg viewBox="0 0 180 220" xmlns="http://www.w3.org/2000/svg" class="npc-art" aria-hidden="true">
    <ellipse cx="90" cy="210" rx="50" ry="10" fill="rgba(0,0,0,.3)"/>
    <path d="M40 210 q10 -90 50 -90 q40 0 50 90" fill="#2d6b5a"/>
    <path d="M55 130 h70 v80 h-70z" fill="#245a4c"/>
    <circle cx="90" cy="78" r="32" fill="#e0b080"/>
    <ellipse cx="90" cy="58" rx="28" ry="12" fill="#d8c9a0"/>
    <circle cx="78" cy="76" r="4" fill="#2a1a10"/>
    <circle cx="102" cy="76" r="4" fill="#2a1a10"/>
    <path d="M78 92 q12 8 24 0" fill="none" stroke="#8a3a3a" stroke-width="2"/>
    <path d="M70 200 h40 v10 h-40z" fill="#1c1c1c"/>
    <rect x="48" y="138" width="22" height="28" rx="4" fill="#c9a227"/>
    <rect x="110" y="150" width="18" height="22" rx="3" fill="#eee"/>
  </svg>`;
}

export function shiloSvg(): string {
  return `<svg viewBox="0 0 160 210" xmlns="http://www.w3.org/2000/svg" class="npc-art" aria-hidden="true">
    <ellipse cx="80" cy="200" rx="40" ry="8" fill="rgba(0,0,0,.3)"/>
    <path d="M80 90 l-30 12 10 80 h40 l10 -80z" fill="#d4a574"/>
    <path d="M50 102 l-14 58 12 6 12 -54" fill="#d4a574"/>
    <rect x="34" y="158" width="18" height="6" fill="#222"/>
    <path d="M38 164 l-6 22 8 2 6 -20" fill="#c9a227"/>
    <circle cx="80" cy="62" r="24" fill="#d4a574"/>
    <path d="M58 58 Q80 36 102 58" fill="#3a2a1a"/>
    <path d="M70 70 q10 0 12 8" fill="none" stroke="#2a1a10" stroke-width="1.4"/>
    <path d="M90 70 q-4 6 8 6" fill="none" stroke="#2a1a10" stroke-width="1.4"/>
    <rect x="58" y="170" width="44" height="22" fill="#1a1a1a"/>
    <rect x="56" y="168" width="48" height="5" fill="#c8ff3a"/>
  </svg>`;
}

export function bossSvg(name: string, hue: number): string {
  const skin = `hsl(${22 + (hue % 20)} 40% 58%)`;
  return `<svg viewBox="0 0 160 210" xmlns="http://www.w3.org/2000/svg" class="npc-art" aria-hidden="true">
    <ellipse cx="80" cy="200" rx="44" ry="8" fill="rgba(0,0,0,.35)"/>
    <path d="M80 86 l-36 16 12 90 h48 l12 -90z" fill="${skin}"/>
    <circle cx="80" cy="58" r="26" fill="${skin}"/>
    <path d="M56 50 Q80 28 104 50" fill="#1a1a1a"/>
    <circle cx="70" cy="60" r="3.2" fill="#1a120c"/>
    <circle cx="92" cy="60" r="3.2" fill="#1a120c"/>
    <path d="M70 76 q10 8 20 0" fill="#7a3030"/>
    <rect x="54" y="168" width="52" height="24" fill="#111"/>
    <rect x="52" y="166" width="56" height="5" fill="hsl(${hue} 70% 48%)"/>
    <text x="80" y="128" text-anchor="middle" fill="#1a120c" font-size="9" font-family="Georgia,serif">${name.slice(0, 8)}</text>
  </svg>`;
}

export function clothesLabel(s: GameState, slot: (typeof CLOTHES)[0]["slot"]): string {
  const id = s.worn[slot];
  return CLOTHES.find((c) => c.id === id)?.name ?? "—";
}
