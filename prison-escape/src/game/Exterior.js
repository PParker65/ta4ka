import * as THREE from 'three';
import { asphaltTex, facadeTex, brickTex, plasterTex } from '../shaders/environment.js';

/**
 * Arrival compound modelled on Лукʼянівське СІЗО №13:
 * outer yard, автозак, dogs, КПП, then сборник — not the cell corridor.
 */
export function buildArrival(prison) {
  prison.tex.asphalt = prison.tex.asphalt || asphaltTex();
  prison.tex.facade = prison.tex.facade || facadeTex();
  prison.tex.brick = prison.tex.brick || brickTex();
  prison.tex.plaster = prison.tex.plaster || plasterTex();

  addSky(prison);
  addGround(prison);
  addPerimeter(prison);
  addBlocks(prison);
  addWatchtowers(prison);
  addVan(prison);
  addKpp(prison);
  addProcessing(prison);
  addWaymarks(prison);

  prison.playerSpawn = new THREE.Vector3(0, 0, -82.35);
}

function addSky(prison) {
  // Flat overcast — a low-poly dome reads as a pyramid and swims.
  prison.scene.background = new THREE.Color(0x9aadb8);
}

function addGround(prison) {
  const asphalt = prison.mat(prison.tex.asphalt, { roughness: 0.95, metalness: 0, env: 0.05, repeat: [5, 6] });
  prison.box(80, 0.08, 90, asphalt, 0, -0.03, -48);
  const curb = new THREE.MeshStandardMaterial({ color: 0x6a6e66, roughness: 0.92 });
  prison.box(80, 0.12, 1.2, curb, 0, 0.04, -90);
  const grass = new THREE.MeshStandardMaterial({ color: 0x4a5a3a, roughness: 1 });
  prison.box(6, 0.06, 70, grass, -28, 0.02, -48);
  prison.box(6, 0.06, 70, grass, 28, 0.02, -48);
}

function addPerimeter(prison) {
  const concrete = new THREE.MeshStandardMaterial({ color: 0xc8c2b4, roughness: 0.9 });
  const cap = new THREE.MeshStandardMaterial({ color: 0x8a9096, metalness: 0.4, roughness: 0.45 });
  const H = 5.4;
  prison.box(76, H, 0.45, concrete, 0, H / 2, -92).userData.camCollide = true;
  prison.box(0.45, H, 78, concrete, -38, H / 2, -54).userData.camCollide = true;
  prison.box(0.45, H, 78, concrete, 38, H / 2, -54).userData.camCollide = true;
  prison.addCollider(-40, 40, -92.4, -91.6, 'outer-back');
  prison.addCollider(-38.4, -37.6, -92, -16, 'outer-l');
  prison.addCollider(37.6, 38.4, -92, -16, 'outer-r');

  for (let x = -36; x <= 36; x += 4) {
    prison.box(0.08, 0.5, 0.08, cap, x, H + 0.2, -92);
    coil(prison, x, H + 0.35, -92);
  }
  const sign = plaque('СІЗО №13  ·  КИЇВ  ·  ДЕГТЯРІВСЬКА', 4.6, 0.55);
  sign.position.set(0, 4.4, -91.7);
  prison.group.add(sign);
  tree(prison, -22, -84);
  tree(prison, 24, -82);
  tree(prison, -26, -62);
  tree(prison, 27, -64);
}

function tree(prison, x, z) {
  const trunk = new THREE.MeshStandardMaterial({ color: 0x4a3428, roughness: 0.95 });
  const leaf = new THREE.MeshStandardMaterial({ color: 0x3a5a32, roughness: 1 });
  prison.box(0.28, 2.2, 0.28, trunk, x, 1.1, z);
  const crown = new THREE.Mesh(new THREE.SphereGeometry(1.6, 8, 6), leaf);
  crown.position.set(x, 3.1, z);
  prison.group.add(crown);
}

function coil(prison, x, y, z) {
  const m = new THREE.Mesh(
    new THREE.TorusGeometry(0.22, 0.018, 5, 10),
    new THREE.MeshStandardMaterial({ color: 0x6a7076, metalness: 0.7, roughness: 0.35 }),
  );
  m.position.set(x, y, z);
  m.rotation.y = Math.PI / 2;
  prison.group.add(m);
}

function addBlocks(prison) {
  const facade = prison.mat(prison.tex.facade, { roughness: 0.88, metalness: 0, env: 0.2, repeat: [2.4, 1] });
  const mass = new THREE.MeshStandardMaterial({ color: 0xccc6b8, roughness: 0.9 });
  const roof = new THREE.MeshStandardMaterial({ color: 0x8a9094, roughness: 0.7, metalness: 0.15 });
  const brick = prison.mat(prison.tex.brick, { roughness: 0.9, repeat: [4, 3] });

  // Facades only — a solid box over the коряк would hide the corridor.
  prison.box(15, 14.2, 3.2, facade, -14, 7.1, -17);
  prison.box(15, 14.2, 3.2, facade, 14, 7.1, -17);
  prison.box(14, 6.2, 3.0, facade, 0, 11.2, -17);
  const katLabel = plaque('КАТЕНЬКА', 5.2, 0.7);
  katLabel.position.set(0, 12.4, -18.7);
  prison.group.add(katLabel);
  prison.addCollider(-22, -6.2, -19, -15.2, 'wing-l');
  prison.addCollider(6.2, 22, -19, -15.2, 'wing-r');
  block(prison, { x: -22, z: 18, w: 14, d: 26, h: 14.2, mat: facade, mass, roof, label: 'КАТЕНЬКА' });
  block(prison, { x: 22, z: 20, w: 14, d: 24, h: 13.5, mat: facade, mass, roof, label: '' });
  // Wings
  block(prison, { x: -28, z: 8, w: 16, d: 22, h: 12.2, mat: brick, mass, roof, label: 'СТОЛИПИНКА' });
  block(prison, { x: 26, z: 6, w: 18, d: 18, h: 11.5, mat: mass, mass, roof, label: 'БРЕЖНЕВКА' });
  block(prison, { x: 24, z: 28, w: 14, d: 16, h: 10.5, mat: facade, mass, roof, label: 'МАЛОЛЕТКА' });
  block(prison, { x: -8, z: 42, w: 18, d: 12, h: 9.5, mat: mass, mass, roof, label: 'ЮЛЬКА' });

  const chimney = prison.box(1.4, 8, 1.4, brick, -6, 18, 22);
  chimney.userData.camCollide = false;
}

function block(prison, spec) {
  const { x, z, w, d, h, mat, mass, roof, label } = spec;
  const body = prison.box(w, h, d, mat, x, h / 2, z);
  body.userData.camCollide = true;
  prison.box(w + 0.6, 0.35, d + 0.6, roof, x, h + 0.1, z);
  if (label) {
    const pl = plaque(label, Math.min(6, w * 0.35), 0.7);
    pl.position.set(x, h * 0.72, z - d / 2 - 0.04);
    prison.group.add(pl);
  }
  // Keep playable corridor / yard clear: only collide if the mass is far from the walk path.
  if (Math.abs(x) > 10 || z > 30) {
    prison.addCollider(x - w / 2, x + w / 2, z - d / 2, z + d / 2, `block-${label}`);
  }
}

function addWatchtowers(prison) {
  prison.searchlights = [];
  for (const [x, z, phase] of [
    [-34, -88, 0],
    [34, -88, 1.7],
    [-34, -20, 3.1],
    [34, -18, 4.4],
  ]) {
    tower(prison, x, z, phase);
  }
}

function tower(prison, x, z, phase) {
  const conc = new THREE.MeshStandardMaterial({ color: 0xb8b2a6, roughness: 0.88 });
  const dark = new THREE.MeshStandardMaterial({ color: 0x2a2c30, roughness: 0.5, metalness: 0.2 });
  prison.box(1.6, 9.2, 1.6, conc, x, 4.6, z);
  prison.box(2.6, 1.6, 2.6, dark, x, 10.1, z);
  const glass = new THREE.MeshStandardMaterial({
    color: 0x8899aa,
    emissive: 0x334455,
    emissiveIntensity: 0.4,
    roughness: 0.25,
  });
  prison.box(2.2, 0.9, 2.2, glass, x, 10.15, z);

  const pivot = new THREE.Group();
  pivot.position.set(x, 10.6, z);
  pivot.userData.phase = phase;
  prison.group.add(pivot);
  const spot = new THREE.SpotLight(0xf2e6c4, 18, 70, 0.28, 0.55, 1.2);
  spot.position.set(0, 0, 0);
  const tgt = new THREE.Object3D();
  tgt.position.set(0, -8, 18);
  pivot.add(tgt);
  spot.target = tgt;
  pivot.add(spot);
  const cone = new THREE.Mesh(
    new THREE.ConeGeometry(3.4, 14, 16, 1, true),
    new THREE.MeshBasicMaterial({
      color: 0xf2e6c4,
      transparent: true,
      opacity: 0.055,
      side: THREE.DoubleSide,
      depthWrite: false,
    }),
  );
  cone.position.copy(tgt.position).multiplyScalar(0.45);
  cone.lookAt(tgt.position);
  cone.rotateX(-Math.PI / 2);
  pivot.add(cone);
  prison.searchlights.push(pivot);
}

function addVan(prison) {
  const van = new THREE.Group();
  van.name = 'Autozak';
  // Rear (local -Z) faces the prison after 180° yaw — first shot is the doorway.
  van.position.set(0, 0, -83.2);
  van.rotation.y = Math.PI;
  prison.group.add(van);

  const body = new THREE.MeshStandardMaterial({ color: 0x3d4538, roughness: 0.72 });
  const dark = new THREE.MeshStandardMaterial({ color: 0x141614, roughness: 0.82 });
  const steel = new THREE.MeshStandardMaterial({ color: 0x6a7074, metalness: 0.55, roughness: 0.4 });
  const rust = new THREE.MeshStandardMaterial({ color: 0x4a3024, roughness: 0.9 });
  prison.box(2.05, 0.1, 5.3, rust, 0, 0.32, 0, van);
  prison.box(2.05, 0.08, 5.3, dark, 0, 1.88, 0, van);
  prison.box(0.1, 1.55, 5.3, body, -1.02, 1.08, 0, van);
  prison.box(0.1, 1.55, 5.3, body, 1.02, 1.08, 0, van);
  prison.box(2.15, 1.55, 0.12, body, 0, 1.08, 2.62, van);
  prison.box(2.2, 0.55, 1.5, dark, 0, 1.55, 2.15, van);
  prison.box(0.55, 0.12, 4.6, rust, -0.55, 0.55, 0.2, van);
  prison.box(0.55, 0.12, 4.6, rust, 0.55, 0.55, 0.2, van);

  for (const [x, z] of [
    [-1.05, -1.6],
    [1.05, -1.6],
    [-1.05, 1.7],
    [1.05, 1.7],
  ]) {
    const w = new THREE.Mesh(new THREE.CylinderGeometry(0.38, 0.38, 0.28, 12), dark);
    w.rotation.z = Math.PI / 2;
    w.position.set(x, 0.38, z);
    van.add(w);
  }

  const bars = new THREE.MeshStandardMaterial({ color: 0x1a1a1c, metalness: 0.55, roughness: 0.35 });
  for (const side of [-1, 1]) {
    for (let i = 0; i < 6; i++) {
      const b = new THREE.Mesh(new THREE.BoxGeometry(0.03, 0.5, 0.03), bars);
      b.position.set(side * 1.08, 1.25, -1.4 + i * 0.5);
      van.add(b);
    }
  }

  const doorL = new THREE.Mesh(new THREE.BoxGeometry(0.07, 1.42, 1.02), body);
  doorL.position.set(-0.5, 1.05, -2.62);
  doorL.rotation.y = 0;
  van.add(doorL);
  const doorR = doorL.clone();
  doorR.position.set(0.5, 1.05, -2.62);
  van.add(doorR);
  prison.vanDoors = { left: doorL, right: doorR };

  addRain(prison);

  const plate = plaque('АА 1313 КІ', 0.7, 0.18);
  plate.position.set(0, 0.7, 2.75);
  van.add(plate);

  const flood = new THREE.SpotLight(0xe8dcc0, 10, 32, 0.5, 0.45, 1.3);
  flood.position.set(3.2, 5.2, -78);
  flood.target.position.set(0, 0.4, -70);
  prison.group.add(flood);
  prison.group.add(flood.target);
  prison.box(0.14, 5.0, 0.14, steel, 3.2, 2.5, -86);

  prison.playerSpawn = new THREE.Vector3(0, 0, -82.35);
}

function addRain(prison) {
  const n = 700;
  const pos = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) {
    pos[i * 3] = (Math.random() - 0.5) * 70;
    pos[i * 3 + 1] = Math.random() * 16;
    pos[i * 3 + 2] = -90 + Math.random() * 70;
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  const rain = new THREE.Points(
    g,
    new THREE.PointsMaterial({ color: 0xb8c4ce, size: 0.045, transparent: true, opacity: 0.45, depthWrite: false }),
  );
  rain.name = 'Rain';
  prison.group.add(rain);
  prison.rain = rain;
}

function addKpp(prison) {
  const brick = prison.mat(prison.tex.brick, { roughness: 0.88, repeat: [2, 1.4] });
  const booth = new THREE.Group();
  booth.position.set(4.4, 0, -56.5);
  prison.group.add(booth);
  prison.box(3.6, 2.6, 3.2, brick, 0, 1.3, 0, booth);
  prison.box(3.8, 0.16, 3.4, new THREE.MeshStandardMaterial({ color: 0x5a4030 }), 0, 2.68, 0, booth);
  const glass = new THREE.MeshStandardMaterial({
    color: 0x9aa8b4,
    roughness: 0.15,
    metalness: 0.2,
    transparent: true,
    opacity: 0.55,
  });
  prison.box(1.4, 0.7, 0.06, glass, -0.4, 1.45, -1.62, booth);
  const kppSign = plaque('КПП', 1.1, 0.32);
  kppSign.position.set(0, 2.35, -1.64);
  booth.add(kppSign);

  prison.box(1.5, 0.08, 0.55, new THREE.MeshStandardMaterial({ color: 0x3a3530 }), 3.2, 1.05, -56.4);

  const steel = new THREE.MeshStandardMaterial({ color: 0x3a3e44, metalness: 0.62, roughness: 0.38 });
  const left = new THREE.Mesh(new THREE.BoxGeometry(3.2, 3.4, 0.16), steel);
  left.position.set(-3.3, 1.7, -54.2);
  prison.group.add(left);
  const right = left.clone();
  right.position.x = 0.2;
  prison.group.add(right);
  for (const g of [left, right]) {
    for (let y = 0.3; y < 3.2; y += 0.38) {
      const bar = new THREE.Mesh(
        new THREE.BoxGeometry(3.0, 0.04, 0.04),
        new THREE.MeshStandardMaterial({ color: 0x8a9096, metalness: 0.8, roughness: 0.3 }),
      );
      bar.position.set(0, y - 1.7, 0.1);
      g.add(bar);
    }
  }

  prison.addCollider(-6.4, 2.0, -54.5, -53.9, 'kpp-gate');
  prison.kppGate = { left, right, open: false, colliderId: 'kpp-gate' };

  prison.interactables.push({
    id: 'kpp',
    type: 'kpp',
    position: new THREE.Vector3(3.4, 1, -56.2),
    radius: 2.6,
  });
}

export function openKppGate(prison) {
  const g = prison.kppGate;
  if (!g || g.open) return;
  g.open = true;
  g.left.position.x -= 3.1;
  g.right.position.x += 3.1;
  const col = prison.colliders.find((c) => c.id === g.colliderId);
  if (col) col.active = false;
}

function addProcessing(prison) {
  const hw = 2.55;
  const z0 = -28;
  const L = 52;
  const h = 3.1;
  const floor = prison.mat(prison.tex.plaster, { roughness: 0.82, metalness: 0, env: 0.1, repeat: [3, 6] });
  floor.color.set(0x8a8882);
  prison.box(hw * 2 + 0.2, 0.06, L, floor, 0, 0.03, z0);

  const wall = new THREE.MeshStandardMaterial({ color: 0xd8d2c4, roughness: 0.9 });
  const dado = new THREE.MeshStandardMaterial({ color: 0x3a6a62, roughness: 0.75 });
  for (const side of [-1, 1]) {
    const x = side * (hw + 0.1);
    prison.box(0.18, 1.15, L, dado, x, 0.57, z0).userData.camCollide = true;
    prison.box(0.18, h - 1.15, L, wall, x, 1.15 + (h - 1.15) / 2, z0).userData.camCollide = true;
    prison.addCollider(
      side > 0 ? hw - 0.08 : -hw - 0.2,
      side > 0 ? hw + 0.2 : -hw + 0.08,
      -54.2,
      -1.15,
      `proc-${side}`,
    );
  }
  prison.box(hw * 2 + 0.4, 0.12, L, new THREE.MeshStandardMaterial({ color: 0xcfc8bc }), 0, h, z0);

  // Rooms as alcoves so it is not the cell corridor.
  alcove(prison, -hw - 2.1, -36.2, 'ШМОН');
  alcove(prison, hw + 2.1, -28.2, 'ФОТО');
  alcove(prison, -hw - 2.1, -22.2, 'МЕД');
  alcove(prison, hw + 2.1, -15.4, 'БАНЯ');

  prison.interactables.push({
    id: 'shmon',
    type: 'shmon',
    position: new THREE.Vector3(-1.2, 1, -36.2),
    radius: 2.0,
  });
  prison.box(1.4, 0.08, 0.6, new THREE.MeshStandardMaterial({ color: 0x4a4030 }), -1.1, 0.92, -36.2);

  prison.interactables.push({
    id: 'photo',
    type: 'photo',
    position: new THREE.Vector3(1.1, 1, -28.2),
    radius: 1.8,
  });
  const chart = plaque('180\n170\n160', 0.5, 1.1);
  chart.position.set(2.3, 1.4, -28.2);
  prison.group.add(chart);
  prison.box(0.35, 0.45, 0.18, new THREE.MeshStandardMaterial({ color: 0x1a1a1c }), 0.7, 1.35, -28.0);

  prison.interactables.push({
    id: 'med',
    type: 'med',
    position: new THREE.Vector3(-1.0, 1, -22.2),
    radius: 1.8,
  });
  prison.box(1.6, 0.45, 0.55, new THREE.MeshStandardMaterial({ color: 0xe8e4dc }), -1.4, 0.55, -22.2);

  prison.interactables.push({
    id: 'bath',
    type: 'bath',
    position: new THREE.Vector3(1.2, 1, -15.4),
    radius: 2.2,
  });
  const tile = new THREE.MeshStandardMaterial({ color: 0xd8e0dc, roughness: 0.55 });
  prison.box(2.2, 1.3, 0.08, tile, 1.4, 0.65, -16.2);
  const chair = new THREE.MeshStandardMaterial({ color: 0x2a2a28 });
  prison.box(0.42, 0.08, 0.42, chair, 1.2, 0.48, -15.2);
  prison.box(0.08, 0.7, 0.08, chair, 1.2, 0.7, -15.38);

  prison.interactables.push({
    id: 'robe',
    type: 'robe',
    position: new THREE.Vector3(-0.9, 1, -13.6),
    radius: 2.0,
  });
  prison.box(0.55, 0.22, 0.4, new THREE.MeshStandardMaterial({ color: 0x5a5a58 }), -0.9, 0.2, -13.6);

  for (let z = -50; z < -2; z += 6) {
    const tube = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.035, 0.7, 8),
      new THREE.MeshStandardMaterial({
        color: 0xf0eed8,
        emissive: 0xd8d4b8,
        emissiveIntensity: 0.55,
      }),
    );
    tube.rotation.x = Math.PI / 2;
    tube.position.set(0, 2.85, z);
    prison.group.add(tube);
  }
  for (const z of [-46, -34, -22, -12]) {
    const lamp = new THREE.PointLight(0xf2ead0, 0.7, 9, 1.6);
    lamp.position.set(0, 2.7, z);
    prison.group.add(lamp);
  }
}

function alcove(prison, x, z, title) {
  const g = new THREE.Group();
  g.position.set(x, 0, z);
  prison.group.add(g);
  const wall = new THREE.MeshStandardMaterial({ color: 0xd2ccbe, roughness: 0.9 });
  prison.box(3.6, 2.9, 0.14, wall, 0, 1.45, 1.7, g);
  prison.box(0.14, 2.9, 3.4, wall, (x < 0 ? -1 : 1) * 1.75, 1.45, 0, g);
  const t = plaque(title, 1.2, 0.28);
  t.position.set(0, 2.55, 1.62);
  g.add(t);
  const wood = new THREE.MeshStandardMaterial({ color: 0x5a4030, roughness: 0.8 });
  const metal = new THREE.MeshStandardMaterial({ color: 0x6a7074, metalness: 0.45, roughness: 0.4 });
  if (title === 'ШМОН') {
    prison.box(1.5, 0.08, 0.7, wood, 0, 0.92, 0.2, g);
    prison.box(0.08, 0.88, 0.08, wood, -0.6, 0.44, 0.4, g);
    prison.box(0.08, 0.88, 0.08, wood, 0.6, 0.44, 0.0, g);
    const lamp = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.07, 0.12, 8), metal);
    lamp.position.set(0.4, 1.02, 0.1);
    g.add(lamp);
  }
  if (title === 'ФОТО') {
    prison.box(0.12, 1.1, 0.12, metal, -0.4, 0.7, 0.3, g);
    prison.box(0.22, 0.16, 0.18, darkCam(), -0.4, 1.28, 0.4, g);
    const stool = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.2, 0.08, 10), wood);
    stool.position.set(0.45, 0.45, 0);
    g.add(stool);
    prison.box(0.06, 0.42, 0.06, wood, 0.45, 0.22, 0, g);
  }
  if (title === 'МЕД') {
    prison.box(1.6, 0.12, 0.55, new THREE.MeshStandardMaterial({ color: 0xe8e4dc }), 0, 0.72, 0, g);
    prison.box(0.08, 0.7, 0.08, metal, -0.7, 0.35, 0.2, g);
    prison.box(0.08, 0.7, 0.08, metal, 0.7, 0.35, -0.2, g);
  }
  if (title === 'БАНЯ') {
    const chrome = new THREE.MeshStandardMaterial({ color: 0xb0b4b8, metalness: 0.7, roughness: 0.3 });
    const head = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.08, 0.1, 8), chrome);
    head.position.set(0.5, 1.55, 0.8);
    g.add(head);
    prison.box(0.45, 0.9, 0.45, wood, -0.4, 0.5, 0, g);
  }
}

function darkCam() {
  return new THREE.MeshStandardMaterial({ color: 0x1a1a1c, roughness: 0.45, metalness: 0.3 });
}

function addWaymarks(prison) {
  const paint = new THREE.MeshBasicMaterial({ color: 0xc9a227, transparent: true, opacity: 0.7, depthWrite: false });
  for (let z = -78; z <= -58; z += 3.6) {
    const chev = new THREE.Mesh(new THREE.ConeGeometry(0.22, 0.7, 3), paint);
    chev.rotation.x = -Math.PI / 2;
    chev.position.set(0.95, 0.03, z);
    prison.group.add(chev);
  }
  const kpp = plaque('КПП →', 1.6, 0.38);
  kpp.position.set(2.35, 1.55, -58.4);
  kpp.rotation.y = -0.4;
  prison.group.add(kpp);
  const puddle = new THREE.Mesh(
    new THREE.CircleGeometry(1.4, 10),
    new THREE.MeshStandardMaterial({ color: 0x2a3034, roughness: 0.22, metalness: 0.35 }),
  );
  puddle.rotation.x = -Math.PI / 2;
  puddle.position.set(-1.6, 0.02, -72);
  prison.group.add(puddle);
}

function plaque(text, w, h) {
  const c = document.createElement('canvas');
  c.width = 512;
  c.height = 128;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#1a2a1c';
  ctx.fillRect(0, 0, 512, 128);
  ctx.fillStyle = '#e8e0c8';
  ctx.font = '600 42px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  const lines = String(text).split('\n');
  lines.forEach((line, i) => ctx.fillText(line, 256, 64 + (i - (lines.length - 1) / 2) * 40));
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.MeshBasicMaterial({ map: tex });
  return new THREE.Mesh(new THREE.PlaneGeometry(w, h), mat);
}
