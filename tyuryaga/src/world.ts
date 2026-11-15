import * as THREE from "three";
import { skinTone } from "./avatar";
import { ZONES } from "./data";
import type { GameState } from "./types";

export type WorldAct = { act: string; id?: string; mode?: string; kind?: string };
export const WORLD_REV = "5d-4";

type Spot = {
  id: string;
  pos: THREE.Vector3;
  r: number;
  label: string;
  payload: WorldAct;
  area: string;
};

type Aabb = { min: THREE.Vector3; max: THREE.Vector3; area: string };

const EYE = 1.62;
const SIT = 1.08;
const RADIUS = 0.22;
const SPEED = 3.1;

let renderer: THREE.WebGLRenderer | null = null;
let scene: THREE.Scene | null = null;
let camera: THREE.PerspectiveCamera | null = null;
let host: HTMLElement | null = null;
let promptEl: HTMLElement | null = null;
let raf = 0;
let yaw = 0;
let pitch = -0.12;
let sitting = false;
let area = "home";
const pos = new THREE.Vector3(0, EYE, 1.4);
const keys = new Set<string>();
const spots: Spot[] = [];
const walls: Aabb[] = [];
let locked = false;
let dragging = false;
let lastMx = 0;
let lastMy = 0;
let bob = 0;
let onAct: ((a: WorldAct) => void) | null = null;
let hover: Spot | null = null;
let bulb: THREE.PointLight | null = null;
let built = false;
let arms: THREE.Group | null = null;
let stateRef: GameState | null = null;
let stickX = 0;
let stickZ = 0;
let lastScreen = "";
let listenersBound = false;

function tex(paint: (g: CanvasRenderingContext2D, n: number) => void, n = 256): THREE.CanvasTexture {
  const c = document.createElement("canvas");
  c.width = c.height = n;
  paint(c.getContext("2d")!, n);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = 8;
  return t;
}

function plaster(): THREE.CanvasTexture {
  return tex((g, n) => {
    g.fillStyle = "#6e7158";
    g.fillRect(0, 0, n, n);
    for (let i = 0; i < 2800; i++) {
      g.fillStyle = `rgba(${40 + Math.random() * 40},${40 + Math.random() * 30},20,${0.04 + Math.random() * 0.1})`;
      g.fillRect(Math.random() * n, Math.random() * n, 1 + Math.random() * 3, 1 + Math.random() * 2);
    }
    g.fillStyle = "rgba(30,40,20,0.18)";
    g.beginPath();
    g.ellipse(n * 0.3, n * 0.7, 40, 18, 0.4, 0, 6.3);
    g.fill();
  });
}

function concrete(): THREE.CanvasTexture {
  return tex((g, n) => {
    g.fillStyle = "#6a655c";
    g.fillRect(0, 0, n, n);
    for (let i = 0; i < 1200; i++) {
      g.fillStyle = `rgba(0,0,0,${Math.random() * 0.12})`;
      g.fillRect(Math.random() * n, Math.random() * n, 2, 2);
    }
    g.strokeStyle = "rgba(0,0,0,0.15)";
    g.beginPath();
    g.moveTo(0, n * 0.5);
    g.lineTo(n, n * 0.52);
    g.stroke();
  });
}

function wood(): THREE.CanvasTexture {
  return tex((g, n) => {
    for (let x = 0; x < n; x++) {
      g.fillStyle = `rgb(${140 + (x % 7) * 4},${90 + (x % 5) * 3},${40})`;
      g.fillRect(x, 0, 1, n);
    }
    g.globalAlpha = 0.15;
    g.fillStyle = "#3a2208";
    for (let i = 0; i < 20; i++) g.fillRect(i * 13, 0, 1, n);
    g.globalAlpha = 1;
  });
}

function metal(): THREE.CanvasTexture {
  return tex((g, n) => {
    const grd = g.createLinearGradient(0, 0, n, n);
    grd.addColorStop(0, "#8a9094");
    grd.addColorStop(1, "#4a5054");
    g.fillStyle = grd;
    g.fillRect(0, 0, n, n);
  });
}

function rust(): THREE.MeshLambertMaterial {
  return new THREE.MeshLambertMaterial({ map: metal(), color: 0x9a8a70 });
}

function mat(map: THREE.Texture, color = 0xffffff): THREE.MeshLambertMaterial {
  return new THREE.MeshLambertMaterial({ map, color });
}

function box(
  parent: THREE.Object3D,
  w: number,
  h: number,
  d: number,
  material: THREE.Material,
  x: number,
  y: number,
  z: number,
  collide = true,
  areaName = area,
): THREE.Mesh {
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
  m.position.set(x, y, z);
  m.castShadow = true;
  m.receiveShadow = true;
  parent.add(m);
  if (collide) {
    walls.push({
      min: new THREE.Vector3(x - w / 2, y - h / 2, z - d / 2),
      max: new THREE.Vector3(x + w / 2, y + h / 2, z + d / 2),
      area: areaName,
    });
  }
  return m;
}

function cyl(
  parent: THREE.Object3D,
  r: number,
  h: number,
  material: THREE.Material,
  x: number,
  y: number,
  z: number,
  rx = 0,
): THREE.Mesh {
  const m = new THREE.Mesh(new THREE.CylinderGeometry(r, r, h, 10), material);
  m.position.set(x, y, z);
  m.rotation.x = rx;
  m.castShadow = true;
  parent.add(m);
  return m;
}

function spot(id: string, x: number, y: number, z: number, r: number, label: string, payload: WorldAct, areaName = "home"): void {
  spots.push({ id, pos: new THREE.Vector3(x, y, z), r, label, payload, area: areaName });
}

function man(hue: number, cap = true): THREE.Group {
  const g = new THREE.Group();
  const skin = new THREE.MeshLambertMaterial({ color: new THREE.Color().setHSL(0.08, 0.42, 0.62) });
  const cloth = new THREE.MeshLambertMaterial({ color: new THREE.Color().setHSL(hue / 360, 0.45, 0.38) });
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.13, 12, 10), skin);
  head.position.y = 1.52;
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.16, 0.55, 4, 8), cloth);
  body.position.y = 1.05;
  const legL = new THREE.Mesh(new THREE.CapsuleGeometry(0.07, 0.45, 3, 6), cloth);
  const legR = legL.clone();
  legL.position.set(-0.08, 0.4, 0);
  legR.position.set(0.08, 0.4, 0);
  g.add(head, body, legL, legR);
  if (cap) {
    const c = new THREE.Mesh(new THREE.SphereGeometry(0.14, 10, 8, 0, Math.PI * 2, 0, 1.1), new THREE.MeshLambertMaterial({ color: 0x111111 }));
    c.position.set(0, 1.58, 0);
    g.add(c);
  }
  g.traverse((o) => {
    const mesh = o as THREE.Mesh;
    if (mesh.isMesh) mesh.castShadow = true;
  });
  return g;
}

function bars(parent: THREE.Object3D, x: number, y: number, z: number, w: number, h: number, along: "x" | "z"): void {
  const m = rust();
  const n = 7;
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    if (along === "x") cyl(parent, 0.018, h, m, x - w / 2 + t * w, y, z);
    else cyl(parent, 0.018, h, m, x, y, z - w / 2 + t * w);
  }
  box(parent, along === "x" ? w : 0.05, 0.04, along === "x" ? 0.05 : w, m, x, y + h / 2, z, false);
  box(parent, along === "x" ? w : 0.05, 0.04, along === "x" ? 0.05 : w, m, x, y - h / 2, z, false);
}

function buildCell(root: THREE.Group): void {
  const pl = mat(plaster());
  const fl = mat(concrete(), 0xc2b8a4);
  const cl = mat(plaster(), 0x5a5c4a);
  const wd = mat(wood());
  const mt = rust();
  // room: x -1.25..1.25, z -2.05..2.05
  box(root, 2.6, 0.08, 4.2, fl, 0, -0.04, 0, true, "home");
  box(root, 2.6, 0.06, 4.2, cl, 0, 2.52, 0, false, "home");
  box(root, 0.12, 2.55, 4.2, pl, -1.31, 1.25, 0, true, "home");
  box(root, 0.12, 2.55, 4.2, pl, 1.31, 1.25, 0, true, "home");
  // back wall with window hole
  box(root, 0.9, 2.55, 0.12, pl, -0.85, 1.25, -2.11, true, "home");
  box(root, 0.9, 2.55, 0.12, pl, 0.85, 1.25, -2.11, true, "home");
  box(root, 0.9, 0.85, 0.12, pl, 0, 0.42, -2.11, true, "home");
  box(root, 0.9, 0.7, 0.12, pl, 0, 2.2, -2.11, true, "home");
  bars(root, 0, 1.25, -2.08, 0.82, 1.05, "x");
  // night sky behind window
  const sky = new THREE.Mesh(
    new THREE.PlaneGeometry(8, 5),
    new THREE.MeshBasicMaterial({ color: 0x6a8aaa }),
  );
  sky.position.set(0, 1.4, -2.4);
  root.add(sky);

  // front wall with door gap |x|<0.42
  box(root, 0.7, 2.55, 0.12, pl, -1.05, 1.25, 2.11, true, "home");
  box(root, 0.7, 2.55, 0.12, pl, 1.05, 1.25, 2.11, true, "home");
  box(root, 1.4, 0.4, 0.12, pl, 0, 2.35, 2.11, true, "home");
  const door = box(root, 0.85, 2.05, 0.05, wd, 0.9, 1.05, 1.95, false, "home");
  door.rotation.y = -1.85;
  box(root, 0.08, 2.05, 0.08, mt, -0.68, 1.05, 2.08, false, "home");

  // bunk
  box(root, 0.95, 0.08, 2.0, mt, -0.72, 0.48, -0.55, true, "home");
  box(root, 0.95, 0.12, 2.0, new THREE.MeshLambertMaterial({ color: 0x6a5040 }), -0.72, 0.58, -0.55, false, "home");
  box(root, 0.06, 0.5, 0.06, mt, -1.12, 0.25, -1.45, false, "home");
  box(root, 0.06, 0.5, 0.06, mt, -0.32, 0.25, -1.45, false, "home");
  box(root, 0.06, 0.5, 0.06, mt, -1.12, 0.25, 0.35, false, "home");
  box(root, 0.06, 0.5, 0.06, mt, -0.32, 0.25, 0.35, false, "home");
  const pillow = new THREE.Mesh(new THREE.BoxGeometry(0.35, 0.1, 0.45), new THREE.MeshLambertMaterial({ color: 0xd9cbb0 }));
  pillow.position.set(-0.72, 0.68, -1.35);
  root.add(pillow);

  // stool
  box(root, 0.34, 0.05, 0.34, wd, 0.55, 0.46, 0.15, true, "home");
  cyl(root, 0.03, 0.46, wd, 0.42, 0.23, 0.02);
  cyl(root, 0.03, 0.46, wd, 0.68, 0.23, 0.02);
  cyl(root, 0.03, 0.46, wd, 0.42, 0.23, 0.28);
  cyl(root, 0.03, 0.46, wd, 0.68, 0.23, 0.28);

  // parasha
  cyl(root, 0.16, 0.32, mt, 1.0, 0.16, -1.7);
  // hanger
  box(root, 0.04, 0.7, 0.04, wd, 1.15, 1.55, 0.9, false, "home");
  box(root, 0.5, 0.04, 0.04, wd, 0.95, 1.85, 0.9, false, "home");
  const jacket = new THREE.Mesh(new THREE.BoxGeometry(0.38, 0.55, 0.08), new THREE.MeshLambertMaterial({ color: 0x2a241c }));
  jacket.position.set(0.95, 1.45, 0.9);
  root.add(jacket);
  // slippers
  box(root, 0.12, 0.04, 0.26, new THREE.MeshLambertMaterial({ color: 0x111111 }), 0.35, 0.03, 0.7, false, "home");
  box(root, 0.12, 0.04, 0.26, new THREE.MeshLambertMaterial({ color: 0x111111 }), 0.52, 0.03, 0.7, false, "home");
  // notebook
  box(root, 0.22, 0.03, 0.3, new THREE.MeshLambertMaterial({ color: 0x5c3310 }), -0.35, 0.66, -0.2, false, "home");
  // bulb
  const cord = cyl(root, 0.01, 0.55, mt, 0, 2.2, 0);
  cord.castShadow = false;
  const bulbMesh = new THREE.Mesh(new THREE.SphereGeometry(0.07, 10, 8), new THREE.MeshBasicMaterial({ color: 0xffe6a0 }));
  bulbMesh.position.set(0, 1.9, 0);
  root.add(bulbMesh);
  bulb = new THREE.PointLight(0xffd090, 90, 14, 1.1);
  bulb.position.set(0, 1.88, 0);
  bulb.castShadow = true;
  bulb.shadow.mapSize.set(512, 512);
  root.add(bulb);

  spot("bunk", -0.7, 0.6, -0.5, 1.7, "Нары · сесть", { act: "sit" });
  spot("stool", 0.55, 0.5, 0.15, 1.2, "Табурет · сесть", { act: "sit" });
  spot("note", -0.35, 0.7, -0.2, 1.1, "Срочняки", { act: "nav", id: "dailies" });
  spot("hanger", 0.95, 1.4, 0.9, 1.2, "Шмот и наколки", { act: "nav", id: "ink" });
  spot("door-hall", 0, 1, 2.05, 1.4, "Коридор", { act: "walk-hall" });
  spot("window", 0, 1.3, -2.05, 1.3, "Глянуть в окно", { act: "look-window" });
}

function buildHall(root: THREE.Group): void {
  const pl = mat(plaster(), 0x7a7d68);
  const fl = mat(concrete(), 0x9a9488);
  // hall z 2.15 .. 8.2, x -1.15 .. 1.15
  box(root, 2.3, 0.08, 6.1, fl, 0, -0.04, 5.2, true, "home");
  box(root, 0.12, 2.5, 6.1, pl, -1.2, 1.25, 5.2, true, "home");
  box(root, 0.12, 2.5, 6.1, pl, 1.2, 1.25, 5.2, true, "home");
  box(root, 2.3, 0.08, 6.1, mat(plaster(), 0x55564a), 0, 2.5, 5.2, false, "home");
  // other cell doors along hall
  for (const z of [3.4, 5.0, 6.6]) {
    box(root, 0.06, 1.9, 0.7, mat(wood()), -1.12, 1.0, z, false, "home");
    bars(root, 1.14, 1.2, z, 0.6, 0.9, "z");
  }
  for (const z of [3.3, 5.5, 7.6]) {
    const lamp = new THREE.PointLight(0xffd0a0, 70, 11, 1.05);
    lamp.position.set(0, 2.25, z);
    root.add(lamp);
    const glow = new THREE.Mesh(new THREE.SphereGeometry(0.06, 8, 8), new THREE.MeshBasicMaterial({ color: 0xffe6a8 }));
    glow.position.set(0, 2.25, z);
    root.add(glow);
  }
  spot("to-cell", 0, 1, 2.2, 1.3, "В хату", { act: "walk-cell" });
  spot("to-yard", 0, 1, 8.0, 1.4, "Во двор", { act: "walk-yard" });
}

function buildYard(root: THREE.Group): void {
  const ground = mat(concrete(), 0x8a8470);
  ground.map!.repeat.set(8, 8);
  box(root, 22, 0.1, 18, ground, 0, -0.05, 16.5, true, "home");
  const wall = mat(plaster(), 0x6a6c58);
  box(root, 22, 4.2, 0.3, wall, 0, 2.1, 7.6, true, "home");
  // opening in wall at x=0
  walls.pop();
  box(root, 9.5, 4.2, 0.3, wall, -6.2, 2.1, 7.6, true, "home");
  box(root, 9.5, 4.2, 0.3, wall, 6.2, 2.1, 7.6, true, "home");
  box(root, 3.2, 1.2, 0.3, wall, 0, 3.6, 7.6, true, "home");
  box(root, 0.3, 4.2, 18, wall, -11, 2.1, 16.5, true, "home");
  box(root, 0.3, 4.2, 18, wall, 11, 2.1, 16.5, true, "home");
  box(root, 22, 4.2, 0.3, wall, 0, 2.1, 25.4, true, "home");
  bars(root, 0, 3.4, 7.72, 2.6, 1.6, "x");

  const sun = new THREE.DirectionalLight(0xfff0d0, 3.2);
  sun.position.set(8, 18, 28);
  sun.target.position.set(0, 0, 16);
  root.add(sun);
  root.add(sun.target);
  root.add(new THREE.HemisphereLight(0xb8d0e8, 0x6a6048, 1.1));
  const fill = new THREE.PointLight(0xffe6c0, 80, 28, 1);
  fill.position.set(0, 6, 16);
  root.add(fill);
  const sky = new THREE.Mesh(
    new THREE.SphereGeometry(40, 16, 12),
    new THREE.MeshBasicMaterial({ color: 0x9eb8cc, side: THREE.BackSide }),
  );
  sky.position.set(0, 0, 16);
  root.add(sky);

  // lohs
  const lohPos = [
    [-1.6, 10.4],
    [1.4, 10.8],
    [0.2, 12.6],
    [-3.2, 13.2],
    [3.4, 14.5],
  ];
  lohPos.forEach(([x, z], i) => {
    const m = man(20 + i * 40);
    m.position.set(x, 0, z);
    m.rotation.y = (i * 1.2) % 6;
    root.add(m);
    spot(`loh-${i}`, x, 1, z, 0.8, "Лох · экспроприация", { act: "steal" });
  });

  // cards table
  box(root, 0.9, 0.08, 0.9, mat(wood()), -6, 0.78, 13, true, "home");
  cyl(root, 0.06, 0.78, mat(wood()), -6, 0.39, 13);
  const terpila = man(200, false);
  terpila.position.set(-6.5, 0, 13.6);
  root.add(terpila);
  spot("cards", -6, 0.9, 13, 1.0, "Карты с терпилой", { act: "nav", id: "cards" });

  // slot crate
  box(root, 0.7, 1.1, 0.5, rust(), 7.5, 0.55, 12, true, "home");
  spot("slot", 7.5, 1, 12, 0.9, "Барабан Толяна", { act: "nav", id: "slot" });

  // dealer shack
  box(root, 3.2, 2.4, 2.6, mat(wood(), 0x8a5a28), 7.2, 1.2, 19.2, true, "home");
  walls.pop();
  box(root, 3.2, 2.4, 0.12, mat(wood(), 0x8a5a28), 7.2, 1.2, 20.45, true, "home");
  box(root, 0.12, 2.4, 2.6, mat(wood(), 0x8a5a28), 5.66, 1.2, 19.2, true, "home");
  box(root, 0.12, 2.4, 2.6, mat(wood(), 0x8a5a28), 8.74, 1.2, 19.2, true, "home");
  box(root, 3.2, 0.12, 2.6, mat(wood(), 0x6a4418), 7.2, 2.42, 19.2, false, "home");
  const dealer = man(140, false);
  dealer.position.set(7.2, 0, 18.6);
  root.add(dealer);
  box(root, 1.4, 0.7, 0.6, mat(wood()), 7.2, 0.4, 18.3, true, "home");
  spot("shop", 7.2, 1, 18.5, 1.2, "Лавка Толяна", { act: "nav", id: "shop" });
  spot("tp", 7.4, 0.5, 18.1, 0.7, "Стырить рулон", { act: "tp" });

  // gate to проходная
  box(root, 2.2, 2.6, 0.16, rust(), 0, 1.3, 25.2, false, "home");
  bars(root, 0, 1.3, 25.2, 1.8, 2.2, "x");
  spot("map", 0, 1.2, 24.6, 1.2, "Проходная", { act: "nav", id: "map" });
  box(root, 1.6, 0.12, 0.45, mat(wood()), 0, 0.42, 10.2, true, "home");
  cyl(root, 0.05, 0.42, mat(wood()), -0.6, 0.21, 10.2);
  cyl(root, 0.05, 0.42, mat(wood()), 0.6, 0.21, 10.2);
  spot("to-hall", 0, 1, 8.0, 1.3, "В корпус", { act: "walk-hall" });
}

function buildCorridor(root: THREE.Group): void {
  const pl = mat(plaster(), 0x6a6e5a);
  const fl = mat(concrete());
  box(root, 4.4, 0.1, 28, fl, 100, -0.05, 0, true, "corridor");
  box(root, 0.2, 3.2, 28, pl, 97.9, 1.6, 0, true, "corridor");
  box(root, 0.2, 3.2, 28, pl, 102.1, 1.6, 0, true, "corridor");
  box(root, 4.4, 0.12, 28, mat(plaster(), 0x4a4c40), 100, 3.2, 0, false, "corridor");
  box(root, 4.4, 3.2, 0.2, pl, 100, 1.6, -14, true, "corridor");
  box(root, 4.4, 3.2, 0.2, pl, 100, 1.6, 14, true, "corridor");
  const lit = new THREE.PointLight(0xffcc88, 110, 22, 1.05);
  lit.position.set(100, 2.6, 0);
  root.add(lit);
  root.add(new THREE.HemisphereLight(0x8899aa, 0x333, 0.4));
  ZONES.forEach((z, i) => {
    const zz = -11 + i * 2.2;
    box(root, 0.08, 2.1, 1.1, mat(wood()), 102.0, 1.1, zz, false, "corridor");
    const plate = tex((g, n) => {
      g.fillStyle = "#c9a05a";
      g.fillRect(0, 0, n, n);
      g.fillStyle = "#3a2208";
      g.font = "bold 28px serif";
      g.textAlign = "center";
      g.fillText(z.name, n / 2, n / 2);
    }, 128);
    const sign = new THREE.Mesh(new THREE.PlaneGeometry(0.9, 0.28), new THREE.MeshLambertMaterial({ map: plate }));
    sign.position.set(101.9, 2.15, zz);
    sign.rotation.y = -Math.PI / 2;
    root.add(sign);
    spot(`z-${z.id}`, 101.4, 1.2, zz, 0.95, z.name, { act: "enter", id: z.id }, "corridor");
  });
  spot("back-yard", 100, 1, -13, 1.1, "Обратно во двор", { act: "nav", id: "yard" }, "corridor");
}

function buildFriend(root: THREE.Group): void {
  const pl = mat(plaster(), 0x5e6250);
  const fl = mat(concrete(), 0xb0a898);
  box(root, 3.0, 0.08, 4.0, fl, 200, -0.04, 0, true, "friend");
  box(root, 0.12, 2.5, 4.0, pl, 198.5, 1.25, 0, true, "friend");
  box(root, 0.12, 2.5, 4.0, pl, 201.5, 1.25, 0, true, "friend");
  box(root, 3.0, 2.5, 0.12, pl, 200, 1.25, -2.05, true, "friend");
  box(root, 3.0, 2.5, 0.12, pl, 200, 1.25, 2.05, true, "friend");
  box(root, 3.0, 0.08, 4.0, mat(plaster(), 0x4a4c40), 200, 2.5, 0, false, "friend");
  const l = new THREE.PointLight(0xffd0a0, 80, 10, 1.1);
  l.position.set(200, 2.0, 0);
  root.add(l);
  const npc = man(30);
  npc.name = "friend-body";
  npc.position.set(200.4, 0, -0.3);
  root.add(npc);
  box(root, 0.9, 0.5, 1.8, rust(), 199.2, 0.35, -0.6, true, "friend");
  spot("pump", 200.4, 1.1, -0.3, 0.9, "Качнуть бицуху", { act: "pump" }, "friend");
  spot("spit", 200.6, 1.0, 0.2, 0.7, "Харкнуть в баланду", { act: "spit" }, "friend");
  spot("yeast", 200.2, 0.6, 0.5, 0.7, "Дрожжи в парашу", { act: "yeast" }, "friend");
  spot("naezd", 200.4, 1.2, -0.6, 0.8, "Наехать", { act: "naezd" }, "friend");
  spot("food", 199.6, 1.0, 0.4, 0.7, "Батон", { act: "food", kind: "bread" }, "friend");
  spot("leave-f", 200, 1, 1.8, 0.8, "Выйти", { act: "nav", id: "cell" }, "friend");
}

function buildBoss(root: THREE.Group): void {
  const pl = mat(plaster(), 0x4a4038);
  const fl = mat(concrete(), 0x6a6058);
  box(root, 3.4, 0.1, 8.0, fl, 300, -0.05, 0, true, "boss");
  box(root, 0.16, 2.8, 8.0, pl, 298.3, 1.4, 0, true, "boss");
  box(root, 0.16, 2.8, 8.0, pl, 301.7, 1.4, 0, true, "boss");
  box(root, 3.4, 2.8, 0.16, pl, 300, 1.4, -4.05, true, "boss");
  box(root, 3.4, 2.8, 0.16, pl, 300, 1.4, 4.05, true, "boss");
  const l = new THREE.PointLight(0xffaa77, 90, 14, 1.1);
  l.position.set(300, 2.3, 0);
  root.add(l);
  const boss = man(10);
  boss.scale.set(1.25, 1.2, 1.25);
  boss.position.set(300, 0, -2.4);
  boss.name = "boss-body";
  root.add(boss);
  spot("hit", 300, 1.3, -2.2, 1.4, "Пыром в солнышко", { act: "hit", id: "fist" }, "boss");
  spot("poison", 300.5, 1.2, -1.8, 0.8, "Яд", { act: "hit", id: "poison" }, "boss");
  spot("leave-b", 300, 1, 3.6, 0.9, "Выйти", { act: "nav", id: "cell" }, "boss");
}

function buildWorkshop(root: THREE.Group): void {
  const wd = mat(wood(), 0x8a6230);
  box(root, 8, 0.1, 8, mat(concrete()), 400, -0.05, 0, true, "workshop");
  box(root, 0.2, 3.4, 8, wd, 396, 1.7, 0, true, "workshop");
  box(root, 0.2, 3.4, 8, wd, 404, 1.7, 0, true, "workshop");
  box(root, 8, 3.4, 0.2, wd, 400, 1.7, -4, true, "workshop");
  box(root, 8, 3.4, 0.2, wd, 400, 1.7, 4, true, "workshop");
  const l = new THREE.PointLight(0xffd0a0, 100, 16, 1.1);
  l.position.set(400, 3, 0);
  root.add(l);
  box(root, 2.2, 0.9, 0.8, rust(), 398.5, 0.45, -1.2, true, "workshop");
  spot("craft", 398.5, 1, -1.2, 1.1, "Верстак", { act: "nav", id: "workshop" }, "workshop");
  spot("leave-w", 400, 1, 3.5, 1, "Выйти", { act: "nav", id: "map" }, "workshop");
}

function makeArms(): THREE.Group {
  const g = new THREE.Group();
  const skin = new THREE.MeshLambertMaterial({ color: 0xd4a574 });
  const cloth = new THREE.MeshLambertMaterial({ color: 0x222 });
  const l = new THREE.Mesh(new THREE.CapsuleGeometry(0.05, 0.28, 3, 6), skin);
  const r = l.clone();
  l.position.set(-0.22, -0.28, -0.35);
  r.position.set(0.22, -0.28, -0.35);
  l.rotation.x = 0.9;
  r.rotation.x = 0.9;
  const sleeveL = new THREE.Mesh(new THREE.CapsuleGeometry(0.06, 0.12, 3, 6), cloth);
  const sleeveR = sleeveL.clone();
  sleeveL.position.set(-0.22, -0.18, -0.22);
  sleeveR.position.set(0.22, -0.18, -0.22);
  g.add(l, r, sleeveL, sleeveR);
  return g;
}

function hits(x: number, z: number): boolean {
  const r = RADIUS;
  for (const w of walls) {
    if (w.area !== area) continue;
    if (w.max.y < 0.35) continue;
    if (x + r > w.min.x && x - r < w.max.x && z + r > w.min.z && z - r < w.max.z) return true;
  }
  return false;
}

function spawn(kind: string): void {
  sitting = false;
  if (kind === "enter") {
    area = "home";
    pos.set(0, EYE, 3.55);
    yaw = Math.PI;
    pitch = -0.04;
  } else if (kind === "cell") {
    area = "home";
    pos.set(0, EYE, 1.35);
    yaw = Math.PI;
    pitch = -0.05;
  } else if (kind === "hall") {
    area = "home";
    pos.set(0, EYE, 5.0);
    yaw = 0;
    pitch = 0;
  } else if (kind === "yard") {
    area = "home";
    pos.set(0, EYE, 9.5);
    yaw = 0;
    pitch = 0.05;
  } else if (kind === "corridor") {
    area = "corridor";
    pos.set(100, EYE, -12);
    yaw = 0;
    pitch = 0;
  } else if (kind === "friend") {
    area = "friend";
    pos.set(200, EYE, 1.4);
    yaw = Math.PI;
    pitch = 0;
  } else if (kind === "boss") {
    area = "boss";
    pos.set(300, EYE, 3.2);
    yaw = Math.PI;
    pitch = 0;
  } else if (kind === "workshop") {
    area = "workshop";
    pos.set(400, EYE, 3);
    yaw = Math.PI;
    pitch = 0;
  }
}

function nearestSpot(): Spot | null {
  let best: Spot | null = null;
  let bestD = 99;
  const dir = new THREE.Vector3(0, 0, -1).applyQuaternion(camera!.quaternion);
  const feet = new THREE.Vector3(pos.x, 0, pos.z);
  for (const s of spots) {
    if (s.area !== area) continue;
    const d = Math.hypot(s.pos.x - feet.x, s.pos.z - feet.z);
    if (d > s.r) continue;
    const to = d > 0.02 ? new THREE.Vector3(s.pos.x - pos.x, 0, s.pos.z - pos.z).normalize() : dir.clone();
    const flat = new THREE.Vector3(dir.x, 0, dir.z);
    if (flat.lengthSq() > 0.0001) flat.normalize();
    const dot = to.dot(flat);
    const score = d - Math.max(0, dot) * 0.8;
    if (score < bestD) {
      bestD = score;
      best = s;
    }
  }
  return best;
}

function applyLook(): void {
  if (!camera) return;
  camera.rotation.order = "YXZ";
  camera.rotation.y = yaw;
  camera.rotation.x = pitch;
  const h = sitting ? SIT : EYE;
  camera.position.set(pos.x, h + Math.sin(bob) * (sitting ? 0 : 0.03), pos.z);
  if (arms) {
    arms.position.copy(camera.position);
    arms.rotation.copy(camera.rotation);
    const swing = Math.sin(bob) * 0.12;
    arms.children[0].rotation.x = 0.9 + swing;
    arms.children[1].rotation.x = 0.9 - swing;
  }
}

function step(dt: number): void {
  if (!camera || !renderer || !scene) return;
  let fx = 0;
  let fz = 0;
  if (keys.has("KeyW") || keys.has("ArrowUp")) fz -= 1;
  if (keys.has("KeyS") || keys.has("ArrowDown")) fz += 1;
  if (keys.has("KeyA") || keys.has("ArrowLeft")) fx -= 1;
  if (keys.has("KeyD") || keys.has("ArrowRight")) fx += 1;
  fx += stickX;
  fz += stickZ;
  if (sitting && (fx || fz)) sitting = false;
  const len = Math.hypot(fx, fz);
  if (len > 1) {
    fx /= len;
    fz /= len;
  }
  const sprint = keys.has("ShiftLeft") || keys.has("ShiftRight") ? 1.45 : 1;
  if (!sitting && len > 0.05) {
    const cy = Math.cos(yaw);
    const sy = Math.sin(yaw);
    const dx = (fx * cy + fz * sy) * SPEED * sprint * dt;
    const dz = (fz * cy - fx * sy) * SPEED * sprint * dt;
    if (!hits(pos.x + dx, pos.z)) pos.x += dx;
    if (!hits(pos.x, pos.z + dz)) pos.z += dz;
    bob += dt * 10 * sprint;
  } else {
    bob *= 0.9;
  }
  applyLook();
  hover = nearestSpot();
  if (promptEl) {
    promptEl.textContent = hover
      ? `[E] ${hover.label}`
      : locked
        ? "WASD ходить · мышь смотреть · E взять"
        : "Клик по хате — смотреть · WASD — ходить · E — взять";
  }
  if (bulb) bulb.intensity = 16 + Math.sin(performance.now() / 400) * 0.8;
  renderer.render(scene, camera);
}

let last = performance.now();
function frame(now: number): void {
  raf = requestAnimationFrame(frame);
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;
  step(dt);
}

function onKey(e: KeyboardEvent, down: boolean): void {
  if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
  if (e.repeat && down) return;
  if (down) keys.add(e.code);
  else keys.delete(e.code);
  const blocked = Boolean(document.querySelector("#overlay.open")?.childElementCount);
  if (down && (e.code === "KeyE" || e.code === "Space")) {
    if (blocked) return;
    e.preventDefault();
    useSpot();
  }
  if (down && e.code === "KeyC") sitting = !sitting;
}

function useSpot(): void {
  const s = hover ?? nearestSpot();
  if (!s) return;
  if (s.payload.act === "sit") {
    sitting = !sitting;
    return;
  }
  if (s.payload.act === "walk-hall") {
    spawn("hall");
    return;
  }
  if (s.payload.act === "walk-cell") {
    spawn("cell");
    return;
  }
  if (s.payload.act === "walk-yard") {
    spawn("yard");
    return;
  }
  if (s.payload.act === "look-window") {
    yaw = Math.PI;
    pitch = -0.12;
    pos.set(0, EYE, -1.3);
    return;
  }
  if (s.payload.act === "pump" || s.payload.act === "spit" || s.payload.act === "yeast" || s.payload.act === "naezd" || s.payload.act === "food") {
    const id = stateRef?.friendId ?? stateRef?.friends[0]?.id;
    onAct?.({ ...s.payload, id });
    return;
  }
  onAct?.(s.payload);
}

function resize(): void {
  if (!renderer || !camera || !host) return;
  const w = host.clientWidth || 800;
  const h = host.clientHeight || 480;
  camera.aspect = w / Math.max(1, h);
  camera.updateProjectionMatrix();
  renderer.setSize(w, h, false);
}

function onMouseMove(e: MouseEvent): void {
  if (!locked && !dragging) return;
  const dx = locked ? e.movementX : e.clientX - lastMx;
  const dy = locked ? e.movementY : e.clientY - lastMy;
  lastMx = e.clientX;
  lastMy = e.clientY;
  yaw -= dx * 0.0022;
  pitch -= dy * 0.0022;
  pitch = Math.max(-1.2, Math.min(1.2, pitch));
}

export function worldLocked(): boolean {
  return locked;
}

export function mountWorld(el: HTMLElement, prompt: HTMLElement): void {
  if (built && host === el && renderer?.domElement.isConnected && el.dataset.rev === WORLD_REV) {
    resize();
    return;
  }
  spots.length = 0;
  walls.length = 0;
  cancelAnimationFrame(raf);
  renderer?.dispose();
  renderer = null;
  host = el;
  el.dataset.rev = WORLD_REV;
  promptEl = prompt;
  console.info("[srok] 5D world", WORLD_REV);
  scene = new THREE.Scene();
  scene.fog = new THREE.Fog(0x6a6860, 18, 42);
  scene.background = new THREE.Color(0x6a7a88);
  scene.add(new THREE.AmbientLight(0x8a806c, 0.7));
  scene.add(new THREE.HemisphereLight(0xc5d4e0, 0x4a4030, 0.55));
  camera = new THREE.PerspectiveCamera(72, 1, 0.05, 80);
  renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: "high-performance" });
  renderer.setPixelRatio(Math.min(2, window.devicePixelRatio || 1));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFShadowMap;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.35;
  el.innerHTML = "";
  el.appendChild(renderer.domElement);
  renderer.domElement.style.width = "100%";
  renderer.domElement.style.height = "100%";
  renderer.domElement.style.display = "block";
  renderer.domElement.style.cursor = "crosshair";

  const worldRoot = new THREE.Group();
  scene.add(worldRoot);
  buildCell(worldRoot);
  buildHall(worldRoot);
  buildYard(worldRoot);
  buildCorridor(worldRoot);
  buildFriend(worldRoot);
  buildBoss(worldRoot);
  buildWorkshop(worldRoot);
  arms = makeArms();
  scene.add(arms);

  built = true;
  spawn("cell");
  resize();
  applyLook();
  cancelAnimationFrame(raf);
  last = performance.now();
  raf = requestAnimationFrame(frame);

  renderer.domElement.addEventListener("click", () => {
    renderer?.domElement.requestPointerLock();
  });
  renderer.domElement.addEventListener("mousedown", (e) => {
    if (locked) return;
    dragging = true;
    lastMx = e.clientX;
    lastMy = e.clientY;
  });
  if (!listenersBound) {
    listenersBound = true;
    document.addEventListener("pointerlockchange", () => {
      locked = document.pointerLockElement === renderer?.domElement;
    });
    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", () => {
      dragging = false;
    });
    window.addEventListener("keydown", (e) => onKey(e, true));
    window.addEventListener("keyup", (e) => onKey(e, false));
    window.addEventListener("resize", resize);
  }
}

export function setWorldHandler(fn: (a: WorldAct) => void): void {
  onAct = fn;
}

export function syncWorld(s: GameState): void {
  stateRef = s;
  if (s.screen !== lastScreen) {
    lastScreen = s.screen;
    const want =
      s.screen === "yard" || s.screen === "cards" || s.screen === "slot" || s.screen === "shop"
        ? "yard"
        : s.screen === "map" || s.screen === "jobs"
          ? "corridor"
          : s.screen === "friend"
            ? "friend"
            : s.screen === "raids"
              ? "boss"
              : s.screen === "workshop"
                ? "workshop"
                : s.screen === "cell"
                  ? "cell"
                  : null;
    if (want === "yard") spawn("yard");
    if (want === "cell") spawn(s.tutorial <= 2 ? "enter" : "cell");
    if (want === "corridor") spawn("corridor");
    if (want === "friend") spawn("friend");
    if (want === "boss") spawn("boss");
    if (want === "workshop") spawn("workshop");
  }

  const skin = skinTone(s.face);
  if (arms) {
    arms.children.forEach((ch, i) => {
      if (i < 2 && ch instanceof THREE.Mesh) {
        const m = ch.material as THREE.MeshLambertMaterial;
        m.color.set(skin);
      }
    });
  }
}

export function worldUse(): void {
  useSpot();
}

export function setStick(x: number, z: number): void {
  stickX = x;
  stickZ = z;
}

export function releaseLook(): void {
  if (document.pointerLockElement) document.exitPointerLock();
}

export function worldReady(): boolean {
  return built;
}
