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
  block(prison, { x: -22, z: 44, w: 14, d: 12, h: 9.5, mat: mass, mass, roof, label: 'ЮЛЬКА' });

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
  prison.box(0.36, 0.07, 2.35, rust, -0.62, 0.52, 0.05, van);
  prison.box(0.36, 0.07, 2.35, rust, 0.62, 0.52, 0.05, van);
  prison.box(1.85, 1.05, 0.05, dark, 0, 1.15, 1.72, van);
  const chain = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.55, 5), steel);
  chain.position.set(-0.55, 1.15, -0.4);
  van.add(chain);
  const cuff = new THREE.Mesh(new THREE.TorusGeometry(0.045, 0.01, 6, 10), steel);
  cuff.position.set(-0.55, 0.86, -0.4);
  cuff.rotation.x = Math.PI / 2;
  van.add(cuff);
  const cabin = new THREE.PointLight(0xffc27a, 0.42, 4.2, 1.8);
  cabin.position.set(0, 1.62, 0.2);
  van.add(cabin);

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
  const n = 1100;
  const pos = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) {
    pos[i * 3] = (Math.random() - 0.5) * 56;
    pos[i * 3 + 1] = Math.random() * 14;
    pos[i * 3 + 2] = -92 + Math.random() * 42;
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  const rain = new THREE.Points(
    g,
    new THREE.PointsMaterial({
      color: 0xd0d8e0,
      size: 0.11,
      transparent: true,
      opacity: 0.72,
      depthWrite: false,
      sizeAttenuation: true,
    }),
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
  const paper = new THREE.MeshStandardMaterial({ color: 0xe8e0cc, roughness: 0.9 });
  prison.box(0.22, 0.01, 0.16, paper, 2.85, 1.1, -56.55);
  prison.box(0.18, 0.01, 0.14, paper, 3.05, 1.11, -56.48);
  const mug = new THREE.Mesh(
    new THREE.CylinderGeometry(0.04, 0.035, 0.07, 8),
    new THREE.MeshStandardMaterial({ color: 0x6a2020, roughness: 0.55 }),
  );
  mug.position.set(3.35, 1.14, -56.45);
  prison.group.add(mug);
  const lamp = new THREE.PointLight(0xffd7a0, 0.55, 5, 1.8);
  lamp.position.set(3.5, 1.7, -56.6);
  prison.group.add(lamp);
  const stamp = new THREE.Mesh(
    new THREE.BoxGeometry(0.08, 0.04, 0.08),
    new THREE.MeshStandardMaterial({ color: 0x1a3a6a, roughness: 0.5 }),
  );
  stamp.position.set(2.7, 1.12, -56.35);
  prison.group.add(stamp);

  const steel = new THREE.MeshStandardMaterial({ color: 0x6a727c, metalness: 0.22, roughness: 0.62 });
  const left = new THREE.Mesh(new THREE.BoxGeometry(3.4, 3.4, 0.16), steel);
  left.position.set(-3.2, 1.7, -54.2);
  prison.group.add(left);
  const right = left.clone();
  right.position.x = 0.15;
  prison.group.add(right);
  const barMat = new THREE.MeshStandardMaterial({ color: 0xb8bec4, metalness: 0.3, roughness: 0.42 });
  const stripeMat = new THREE.MeshStandardMaterial({ color: 0xc9a227, roughness: 0.55 });
  for (const g of [left, right]) {
    for (const faceZ of [-0.1, 0.1]) {
      for (let y = 0.28; y < 3.2; y += 0.36) {
        const bar = new THREE.Mesh(new THREE.BoxGeometry(3.15, 0.06, 0.05), barMat);
        bar.position.set(0, y - 1.7, faceZ);
        g.add(bar);
      }
      const stripe = new THREE.Mesh(new THREE.BoxGeometry(3.15, 0.2, 0.05), stripeMat);
      stripe.position.set(0, 0.32, faceZ);
      g.add(stripe);
    }
  }

  prison.addCollider(-6.4, 2.0, -54.5, -53.9, 'kpp-gate');
  prison.kppGate = { left, right, open: false, colliderId: 'kpp-gate' };

  prison.interactables.push({
    id: 'kpp',
    type: 'kpp',
    position: new THREE.Vector3(2.4, 1, -58.6),
    radius: 2.5,
  });
  prison.addCollider(2.65, 6.15, -58.05, -54.95, 'kpp-booth');
}

export function openKppGate(prison) {
  const g = prison.kppGate;
  if (!g || g.open) return;
  g.open = true;
  g.k = 0;
  g.leftFrom = g.left.position.x;
  g.rightFrom = g.right.position.x;
  g.leftTo = g.left.position.x - 3.1;
  g.rightTo = g.right.position.x + 3.1;
}

export function tickKppGate(prison, dt) {
  const g = prison.kppGate;
  if (!g || !g.open || g.k >= 1) return;
  g.k = Math.min(1, (g.k || 0) + dt * 0.85);
  const e = g.k * g.k * (3 - 2 * g.k);
  g.left.position.x = g.leftFrom + (g.leftTo - g.leftFrom) * e;
  g.right.position.x = g.rightFrom + (g.rightTo - g.rightFrom) * e;
  if (g.k > 0.55) {
    const col = prison.colliders.find((c) => c.id === g.colliderId);
    if (col) col.active = false;
  }
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
  const zA = z0 - L / 2;
  const zB = z0 + L / 2;
  const leftGaps = [-36.2, -22.2];
  const rightGaps = [-28.2, -15.4];
  const alcoveHalf = 1.55;
  for (const [side, gaps] of [
    [-1, leftGaps],
    [1, rightGaps],
  ]) {
    const x = side * (hw + 0.1);
    for (const [a, b] of procSegments(zA, zB, gaps, alcoveHalf)) {
      const len = b - a;
      if (len < 0.12) continue;
      const z = (a + b) / 2;
      prison.box(0.18, 1.15, len, dado, x, 0.57, z).userData.camCollide = true;
      prison.box(0.18, h - 1.15, len, wall, x, 1.15 + (h - 1.15) / 2, z).userData.camCollide = true;
    }
    for (const [a, b] of procSegments(zA, zB, gaps, alcoveHalf)) {
      prison.addCollider(
        side > 0 ? hw - 0.08 : -hw - 0.2,
        side > 0 ? hw + 0.2 : -hw + 0.08,
        a,
        b,
        `proc-${side}-${a}`,
      );
    }
  }
  prison.box(hw * 2 + 0.4, 0.12, L, new THREE.MeshStandardMaterial({ color: 0xcfc8bc }), 0, h, z0);

  const endW = hw * 2 + 0.2;
  const doorGap = 1.2;
  const endWing = (endW - doorGap) / 2;
  const endX = (endW + doorGap) / 4;
  prison.box(endWing, h, 0.18, wall, -endX, h / 2, zB - 0.04).userData.camCollide = true;
  prison.box(endWing, h, 0.18, wall, endX, h / 2, zB - 0.04).userData.camCollide = true;
  prison.box(doorGap, 0.7, 0.18, wall, 0, h - 0.35, zB - 0.04);
  prison.addCollider(-hw - 0.1, -doorGap / 2, zB - 0.16, zB + 0.1, 'proc-end-l');
  prison.addCollider(doorGap / 2, hw + 0.1, zB - 0.16, zB + 0.1, 'proc-end-r');
  addVestibule(prison);

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
  const photoBottle = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.056, 0.22, 8),
    new THREE.MeshStandardMaterial({ color: 0xc4a050, roughness: 0.24, metalness: 0.28, transparent: true, opacity: 0.9 }),
  );
  photoBottle.position.set(1.15, 0.08, -27.85);
  photoBottle.rotation.z = 1.18;
  photoBottle.rotation.y = 0.35;
  photoBottle.name = 'photoBottle';
  prison.group.add(photoBottle);
  const photoTin = new THREE.Mesh(
    new THREE.CylinderGeometry(0.045, 0.05, 0.07, 8),
    new THREE.MeshStandardMaterial({ color: 0x8a8680, metalness: 0.45, roughness: 0.4 }),
  );
  photoTin.position.set(0.82, 0.06, -27.52);
  photoTin.name = 'photoTin';
  prison.group.add(photoTin);
  const photoCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  photoCig.position.set(0.55, 0.055, -27.72);
  photoCig.rotation.z = Math.PI / 2;
  photoCig.rotation.y = 0.4;
  photoCig.name = 'photoCig';
  prison.group.add(photoCig);

  prison.interactables.push({
    id: 'med',
    type: 'med',
    position: new THREE.Vector3(-1.0, 1, -22.2),
    radius: 1.8,
  });
  prison.box(1.6, 0.45, 0.55, new THREE.MeshStandardMaterial({ color: 0xe8e4dc }), -1.4, 0.55, -22.2);
  const jar = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.05, 0.12, 8),
    new THREE.MeshStandardMaterial({ color: 0xc8d8c8, roughness: 0.25, metalness: 0.1, transparent: true, opacity: 0.7 }),
  );
  jar.position.set(-1.15, 0.84, -22.05);
  prison.group.add(jar);
  const tray = new THREE.MeshStandardMaterial({ color: 0xb0b4b0, metalness: 0.4, roughness: 0.45 });
  prison.box(0.28, 0.03, 0.18, tray, -0.95, 0.8, -22.15);
  const medBottle = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.056, 0.22, 8),
    new THREE.MeshStandardMaterial({ color: 0xc4a050, roughness: 0.24, metalness: 0.28, transparent: true, opacity: 0.9 }),
  );
  medBottle.position.set(-0.92, 0.09, -21.48);
  medBottle.rotation.z = 1.18;
  medBottle.rotation.y = 0.4;
  medBottle.name = 'medBottle';
  prison.group.add(medBottle);
  const medTin = new THREE.Mesh(
    new THREE.CylinderGeometry(0.045, 0.05, 0.07, 8),
    new THREE.MeshStandardMaterial({ color: 0x8a8680, metalness: 0.45, roughness: 0.4 }),
  );
  medTin.position.set(-1.08, 0.06, -22.78);
  medTin.name = 'medTin';
  prison.group.add(medTin);
  const medCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  medCig.position.set(-0.78, 0.80, -22.32);
  medCig.rotation.z = Math.PI / 2;
  medCig.rotation.y = 0.35;
  medCig.name = 'medCig';
  prison.group.add(medCig);

  prison.interactables.push({
    id: 'bath',
    type: 'bath',
    position: new THREE.Vector3(1.2, 1, -15.4),
    radius: 1.35,
  });
  const tile = new THREE.MeshStandardMaterial({ color: 0x4a5a54, roughness: 0.62 });
  prison.box(0.08, 1.15, 1.35, tile, 2.38, 0.72, -16.2);
  const chair = new THREE.MeshStandardMaterial({ color: 0x2a2a28 });
  prison.box(0.42, 0.08, 0.42, chair, 1.2, 0.48, -15.2);
  prison.box(0.08, 0.7, 0.08, chair, 1.2, 0.7, -15.38);
  const clip = new THREE.MeshStandardMaterial({ color: 0x3a3e42, metalness: 0.55, roughness: 0.35 });
  prison.box(0.16, 0.06, 0.05, clip, 1.35, 0.55, -15.05);
  prison.box(0.04, 0.04, 0.12, clip, 1.42, 0.55, -14.98);
  const hair = new THREE.Mesh(
    new THREE.CircleGeometry(0.18, 8),
    new THREE.MeshStandardMaterial({ color: 0x2a221c, roughness: 0.95 }),
  );
  hair.rotation.x = -Math.PI / 2;
  hair.position.set(1.15, 0.04, -15.15);
  prison.group.add(hair);
  const drain = new THREE.Mesh(
    new THREE.CylinderGeometry(0.08, 0.09, 0.03, 10),
    new THREE.MeshStandardMaterial({ color: 0x2a2a28, metalness: 0.6, roughness: 0.4 }),
  );
  drain.position.set(1.6, 0.04, -15.7);
  prison.group.add(drain);
  const bathWet = new THREE.Mesh(
    new THREE.CircleGeometry(0.7, 10),
    new THREE.MeshStandardMaterial({ color: 0x6a7a78, roughness: 0.18, metalness: 0.15 }),
  );
  bathWet.rotation.x = -Math.PI / 2;
  bathWet.position.set(1.3, 0.035, -15.4);
  prison.group.add(bathWet);
  const bathBottle = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.056, 0.22, 8),
    new THREE.MeshStandardMaterial({ color: 0xc4a050, roughness: 0.24, metalness: 0.28, transparent: true, opacity: 0.9 }),
  );
  bathBottle.position.set(1.48, 0.08, -15.72);
  bathBottle.rotation.z = 1.18;
  bathBottle.rotation.y = 0.35;
  bathBottle.name = 'bathBottle';
  prison.group.add(bathBottle);
  const bathRag = new THREE.Mesh(
    new THREE.BoxGeometry(0.22, 0.025, 0.14),
    new THREE.MeshStandardMaterial({ color: 0x5a4434, roughness: 0.96 }),
  );
  bathRag.position.set(1.32, 0.05, -15.68);
  bathRag.rotation.y = 0.55;
  bathRag.name = 'bathRag';
  prison.group.add(bathRag);
  const bathCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  bathCig.position.set(1.05, 0.055, -15.48);
  bathCig.rotation.z = Math.PI / 2;
  bathCig.rotation.y = 0.4;
  bathCig.name = 'bathCig';
  prison.group.add(bathCig);

  prison.interactables.push({
    id: 'robe',
    type: 'robe',
    position: new THREE.Vector3(2.35, 1, -15.32),
    radius: 1.7,
  });
  kazenkaPile(prison, 2.35, -15.32);
  const mist = new THREE.MeshStandardMaterial({
    color: 0x6a7a76,
    transparent: true,
    opacity: 0.08,
    depthWrite: false,
    roughness: 1,
  });
  for (const [x, y, z, w, h] of [
    [1.05, 1.15, -15.35, 1.3, 1.0],
    [0.4, 0.85, -14.6, 0.9, 0.7],
  ]) {
    const p = new THREE.Mesh(new THREE.PlaneGeometry(w, h), mist);
    p.position.set(x, y, z);
    p.rotation.y = 0.4;
    prison.group.add(p);
  }

  const tubeGlass = new THREE.MeshStandardMaterial({
    color: 0xb8b490,
    emissive: 0x8a8658,
    emissiveIntensity: 0.32,
    roughness: 0.5,
  });
  const tubeHouse = new THREE.MeshStandardMaterial({ color: 0x3a3a36, metalness: 0.42, roughness: 0.55 });
  const tubeWire = new THREE.MeshStandardMaterial({ color: 0x1c1c18, roughness: 0.92 });
  let tubeI = 0;
  for (let z = -50; z < -2; z += 6) {
    const x = tubeI % 2 === 0 ? 0.68 : -0.68;
    tubeI += 1;
    const house = new THREE.Mesh(new THREE.BoxGeometry(0.2, 0.07, 0.82), tubeHouse);
    house.position.set(x, 2.94, z);
    prison.group.add(house);
    const tube = new THREE.Mesh(new THREE.CylinderGeometry(0.026, 0.026, 0.64, 8), tubeGlass);
    tube.rotation.x = Math.PI / 2;
    tube.position.set(x, 2.88, z);
    prison.group.add(tube);
    const drop = new THREE.Mesh(new THREE.CylinderGeometry(0.008, 0.008, 0.16, 5), tubeWire);
    drop.position.set(x, 3.02, z);
    prison.group.add(drop);
  }
  for (const z of [-46, -34, -22, -12, -4]) {
    const lamp = new THREE.PointLight(0xf2ead0, 0.7, 9, 1.6);
    lamp.position.set(0, 2.7, z);
    prison.group.add(lamp);
  }

  const benchMat = new THREE.MeshStandardMaterial({ color: 0x4a4034, roughness: 0.85 });
  for (const z of [-42, -32, -18]) {
    prison.box(0.38, 0.08, 1.35, benchMat, -1.85, 0.42, z);
    prison.box(0.06, 0.42, 0.06, benchMat, -1.85, 0.21, z - 0.55);
    prison.box(0.06, 0.42, 0.06, benchMat, -1.85, 0.21, z + 0.55);
  }
  for (const z of [-38.4, -25.6, -11.2]) {
    prison.box(0.38, 0.08, 1.2, benchMat, 1.85, 0.42, z);
    prison.box(0.06, 0.42, 0.06, benchMat, 1.85, 0.21, z - 0.48);
    prison.box(0.06, 0.42, 0.06, benchMat, 1.85, 0.21, z + 0.48);
  }
  const hallPipe = new THREE.MeshStandardMaterial({ color: 0x6a7068, metalness: 0.35, roughness: 0.55 });
  const hallConduit = new THREE.Mesh(
    new THREE.CylinderGeometry(0.04, 0.04, 40, 6),
    hallPipe,
  );
  hallConduit.rotation.x = Math.PI / 2;
  hallConduit.position.set(-2.15, 2.72, -28);
  prison.group.add(hallConduit);
  const hallConduit2 = hallConduit.clone();
  hallConduit2.position.set(2.15, 2.68, -28);
  prison.group.add(hallConduit2);
  const hallDamp = new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.62, transparent: true, opacity: 0.42 });
  const hallPeel = new THREE.MeshStandardMaterial({ color: 0xa89f8c, roughness: 0.92 });
  for (const [x, z, w, hh] of [
    [-2.52, -38.4, 0.38, 1.1],
    [2.52, -34.2, 0.32, 1.05],
    [-2.52, -30.5, 0.34, 1.2],
    [2.52, -40.1, 0.28, 0.7],
    [-2.52, -26.2, 0.4, 0.85],
    [2.52, -21.4, 0.3, 1.05],
    [-2.52, -17.8, 0.26, 0.7],
    [2.52, -12.6, 0.36, 0.9],
  ]) {
    prison.box(0.03, hh, w, hallDamp, x, 2.05, z);
  }
  prison.box(0.03, 0.35, 0.28, hallPeel, 2.5, 2.35, -36.4);
  prison.box(0.03, 0.4, 0.32, hallPeel, -2.5, 2.4, -33.2);
  prison.box(0.03, 0.28, 0.26, hallPeel, 2.5, 2.2, -27.5);
  prison.box(0.03, 0.32, 0.24, hallPeel, -2.5, 2.15, -19.8);
  const fuse = new THREE.MeshStandardMaterial({ color: 0x3a4238, metalness: 0.38, roughness: 0.52 });
  prison.box(0.1, 0.38, 0.28, fuse, 2.46, 1.5, -34.15);
  prison.box(0.04, 0.05, 0.07, fuse, 2.4, 1.58, -34.15);
  const quiet2 = plaque('ТИХО', 0.55, 0.2);
  quiet2.position.set(2.48, 1.88, -34.15);
  quiet2.rotation.y = -Math.PI / 2;
  prison.group.add(quiet2);
  const stainEye = new THREE.MeshStandardMaterial({
    color: 0x5a6054,
    roughness: 0.7,
    transparent: true,
    opacity: 0.48,
  });
  for (const [x, z, w, hh, y] of [
    [-2.52, -34.6, 0.22, 1.2, 1.72],
    [2.52, -32.1, 0.18, 1.35, 1.78],
    [-2.52, -25.4, 0.26, 1.05, 1.62],
    [2.52, -23.0, 0.2, 1.18, 1.7],
    [-2.52, -14.8, 0.16, 0.95, 1.58],
    [2.52, -10.4, 0.24, 1.1, 1.64],
  ]) {
    prison.box(0.03, hh, w, stainEye, x, y, z);
  }
  const rustDrip = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.85, transparent: true, opacity: 0.55 });
  prison.box(0.03, 0.85, 0.08, rustDrip, 2.52, 2.15, -32.05);
  prison.box(0.03, 0.7, 0.07, rustDrip, -2.52, 2.05, -34.55);
  prison.box(0.03, 0.95, 0.09, rustDrip, 2.52, 2.22, -22.9);
  prison.box(0.1, 0.42, 0.32, fuse, 2.46, 1.52, -32.05);
  prison.box(0.04, 0.06, 0.08, fuse, 2.4, 1.62, -32.05);
  prison.box(0.1, 0.36, 0.26, fuse, -2.46, 1.48, -25.35);
  prison.box(0.04, 0.05, 0.07, fuse, -2.4, 1.56, -25.35);
  const notice = new THREE.MeshStandardMaterial({ color: 0xe4d8b8, roughness: 0.92 });
  prison.box(0.02, 0.28, 0.2, notice, 2.49, 1.78, -31.82);
  prison.box(0.02, 0.22, 0.16, notice, 2.49, 1.68, -32.22);
  prison.box(0.02, 0.24, 0.18, notice, -2.49, 1.72, -34.4);
  const acct = plaque('УЧЁТ', 0.7, 0.22);
  acct.position.set(2.48, 1.92, -32.05);
  acct.rotation.y = -Math.PI / 2;
  prison.group.add(acct);
  const row = plaque('РЯД 1', 0.65, 0.2);
  row.position.set(-2.48, 1.88, -34.55);
  row.rotation.y = Math.PI / 2;
  prison.group.add(row);
  const ceilDampHall = new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.92, transparent: true, opacity: 0.42 });
  prison.box(1.6, 0.02, 0.7, ceilDampHall, -0.4, h - 0.04, -33.2);
  prison.box(0.9, 0.02, 1.4, ceilDampHall, 0.6, h - 0.04, -27.5);
  prison.box(1.2, 0.02, 0.55, ceilDampHall, -0.2, h - 0.04, -20.4);
  prison.box(0.7, 0.02, 1.1, ceilDampHall, 0.35, h - 0.04, -14.2);
  const dropCable = new THREE.MeshStandardMaterial({ color: 0x1a1a18, roughness: 0.9 });
  for (const z of [-34.8, -28.4, -21.6, -13.5]) {
    const c = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.95, 5), dropCable);
    c.position.set(1.85, 2.35, z);
    c.rotation.z = 0.42;
    prison.group.add(c);
  }
  for (const [x, z, len, rz] of [
    [0.28, -34.1, 0.72, 0.48],
    [-0.38, -30.6, 0.88, -0.36],
    [0.42, -25.4, 0.62, 0.28],
    [-0.18, -18.2, 0.98, 0.2],
    [0.22, -12.4, 0.55, -0.44],
  ]) {
    const c = new THREE.Mesh(new THREE.CylinderGeometry(0.01, 0.01, len, 5), dropCable);
    c.position.set(x, 3.05 - len / 2, z);
    c.rotation.z = rz;
    prison.group.add(c);
  }
  const hangRag = new THREE.Mesh(
    new THREE.BoxGeometry(0.14, 0.42, 0.02),
    new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.95 }),
  );
  hangRag.position.set(-0.55, 2.55, -33.6);
  hangRag.rotation.z = 0.18;
  prison.group.add(hangRag);
  const rad = new THREE.MeshStandardMaterial({ color: 0x6a3a28, roughness: 0.7, metalness: 0.22 });
  for (const z of [-33.5, -24.8, -16.6, -8.4]) {
    prison.box(0.1, 0.48, 0.85, rad, -2.42, 0.42, z);
    for (let i = -3; i <= 3; i++) {
      prison.box(0.04, 0.44, 0.04, rad, -2.46, 0.42, z + i * 0.11);
    }
  }
  const hallPaper = new THREE.MeshStandardMaterial({ color: 0xe8e0cc, roughness: 0.9 });
  prison.box(0.16, 0.01, 0.22, hallPaper, 0.35, 0.055, -35.4);
  prison.box(0.12, 0.01, 0.18, hallPaper, -0.2, 0.055, -37.1);
  prison.box(0.18, 0.01, 0.14, hallPaper, 0.55, 0.055, -31.2);
  prison.box(0.14, 0.01, 0.2, hallPaper, -0.45, 0.055, -26.6);
  prison.box(0.2, 0.01, 0.16, hallPaper, 0.25, 0.055, -19.4);
  prison.box(0.12, 0.01, 0.18, hallPaper, -0.3, 0.055, -12.8);
  prison.box(0.15, 0.01, 0.2, hallPaper, 0.12, 0.055, -33.8);
  prison.box(0.1, 0.01, 0.14, hallPaper, -0.55, 0.055, -29.6);
  const hallRag = new THREE.Mesh(
    new THREE.BoxGeometry(0.32, 0.02, 0.18),
    new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.95 }),
  );
  hallRag.position.set(0.4, 0.05, -34.2);
  hallRag.rotation.y = 0.35;
  prison.group.add(hallRag);
  const shallBottle = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.056, 0.22, 8),
    new THREE.MeshStandardMaterial({ color: 0xc4a050, roughness: 0.24, metalness: 0.28, transparent: true, opacity: 0.9 }),
  );
  shallBottle.position.set(0.52, 0.08, -34.85);
  shallBottle.rotation.z = 1.18;
  shallBottle.rotation.y = 0.4;
  shallBottle.name = 'shallBottle';
  prison.group.add(shallBottle);
  const shallTin = new THREE.Mesh(
    new THREE.CylinderGeometry(0.045, 0.05, 0.07, 8),
    new THREE.MeshStandardMaterial({ color: 0x8a8680, metalness: 0.45, roughness: 0.4 }),
  );
  shallTin.position.set(0.18, 0.055, -35.12);
  shallTin.name = 'shallTin';
  prison.group.add(shallTin);
  const shallCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  shallCig.position.set(-0.08, 0.055, -35.38);
  shallCig.rotation.z = Math.PI / 2;
  shallCig.rotation.y = 0.45;
  shallCig.name = 'shallCig';
  prison.group.add(shallCig);
  const belt = new THREE.Mesh(
    new THREE.BoxGeometry(0.42, 0.015, 0.05),
    new THREE.MeshStandardMaterial({ color: 0x2a2420, roughness: 0.8 }),
  );
  belt.position.set(-0.25, 0.05, -30.4);
  belt.rotation.y = -0.4;
  prison.group.add(belt);
  const hallBag = new THREE.Mesh(
    new THREE.BoxGeometry(0.28, 0.16, 0.22),
    new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.88 }),
  );
  hallBag.position.set(-1.55, 0.12, -31.6);
  hallBag.rotation.y = 0.4;
  prison.group.add(hallBag);
  const hallCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallCig.position.set(-1.32, 0.055, -31.42);
  hallCig.rotation.z = Math.PI / 2;
  hallCig.rotation.y = 0.4;
  hallCig.name = 'hallCig';
  prison.group.add(hallCig);
  const hallBag2 = hallBag.clone();
  hallBag2.position.set(1.55, 0.12, -25.2);
  hallBag2.rotation.y = -0.55;
  prison.group.add(hallBag2);
  const hallXCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallXCig.position.set(1.42, 0.055, -24.95);
  hallXCig.rotation.z = Math.PI / 2;
  hallXCig.rotation.y = 0.4;
  hallXCig.name = 'hallXCig';
  prison.group.add(hallXCig);
  const hallBag3 = hallBag.clone();
  hallBag3.position.set(-1.4, 0.12, -17.4);
  hallBag3.rotation.y = 0.2;
  prison.group.add(hallBag3);
  const hallYCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallYCig.position.set(-1.22, 0.055, -17.15);
  hallYCig.rotation.z = Math.PI / 2;
  hallYCig.rotation.y = 0.35;
  hallYCig.name = 'hallYCig';
  prison.group.add(hallYCig);
  const hallShoe = new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.9 });
  for (const [sx, sz] of [
    [-1.7, -41.6],
    [-1.52, -41.45],
  ]) {
    const galosh = new THREE.Mesh(new THREE.BoxGeometry(0.2, 0.07, 0.1), hallShoe);
    galosh.position.set(sx, 0.08, sz);
    galosh.rotation.y = 0.5;
    prison.group.add(galosh);
  }
  const hallSCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallSCig.position.set(-1.38, 0.055, -41.32);
  hallSCig.rotation.z = Math.PI / 2;
  hallSCig.rotation.y = 0.35;
  hallSCig.name = 'hallSCig';
  prison.group.add(hallSCig);
  const rules = plaque('СДАТЬ ВСЁ', 0.9, 0.28);
  rules.position.set(2.48, 1.7, -36.4);
  rules.rotation.y = -Math.PI / 2;
  prison.group.add(rules);
  const hallRCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallRCig.position.set(2.18, 0.055, -36.25);
  hallRCig.rotation.z = Math.PI / 2;
  hallRCig.rotation.y = -0.35;
  hallRCig.name = 'hallRCig';
  prison.group.add(hallRCig);
  const line = new THREE.Mesh(
    new THREE.BoxGeometry(0.08, 0.01, 40),
    new THREE.MeshStandardMaterial({ color: 0xc9a227, roughness: 0.55 }),
  );
  line.position.set(-0.85, 0.045, -28);
  prison.group.add(line);
  const hallLCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallLCig.position.set(-0.78, 0.055, -22.4);
  hallLCig.rotation.z = Math.PI / 2;
  hallLCig.rotation.y = 0.4;
  hallLCig.name = 'hallLCig';
  prison.group.add(hallLCig);
  const quiet = plaque('НЕ КУРИТЬ', 1.4, 0.28);
  quiet.position.set(-2.48, 1.85, -40);
  quiet.rotation.y = Math.PI / 2;
  prison.group.add(quiet);
  const hallQCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallQCig.position.set(-2.18, 0.055, -39.82);
  hallQCig.rotation.z = Math.PI / 2;
  hallQCig.rotation.y = 0.4;
  hallQCig.name = 'hallQCig';
  prison.group.add(hallQCig);
  const arrow = plaque('→ ШМОН', 0.85, 0.22);
  arrow.position.set(2.48, 1.55, -33.8);
  arrow.rotation.y = -Math.PI / 2;
  prison.group.add(arrow);
  const hallACig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallACig.position.set(2.18, 0.055, -33.65);
  hallACig.rotation.z = Math.PI / 2;
  hallACig.rotation.y = -0.35;
  hallACig.name = 'hallACig';
  prison.group.add(hallACig);
  const halt = plaque('СТОЙ', 0.55, 0.22);
  halt.position.set(-2.48, 1.58, -27.2);
  halt.rotation.y = Math.PI / 2;
  prison.group.add(halt);
  const hallTCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallTCig.position.set(-2.18, 0.055, -27.05);
  hallTCig.rotation.z = Math.PI / 2;
  hallTCig.rotation.y = 0.35;
  hallTCig.name = 'hallTCig';
  prison.group.add(hallTCig);
  const noTalk = plaque('НЕ ОРАТЬ', 0.95, 0.22);
  noTalk.position.set(2.48, 1.62, -20.6);
  noTalk.rotation.y = -Math.PI / 2;
  prison.group.add(noTalk);
  const hallNCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallNCig.position.set(2.18, 0.055, -20.45);
  hallNCig.rotation.z = Math.PI / 2;
  hallNCig.rotation.y = -0.35;
  hallNCig.name = 'hallNCig';
  prison.group.add(hallNCig);
  const wet = new THREE.MeshStandardMaterial({ color: 0x3a4038, roughness: 0.2, metalness: 0.28 });
  for (const [x, z, s] of [
    [0.4, -24, 0.45],
    [-0.6, -16.2, 0.55],
    [0.2, -38, 0.35],
    [0.15, -32.4, 0.4],
    [-0.35, -21.8, 0.32],
    [0.5, -13.6, 0.38],
  ]) {
    const p = new THREE.Mesh(new THREE.CircleGeometry(s, 8), wet);
    p.rotation.x = -Math.PI / 2;
    p.position.set(x, 0.045, z);
    prison.group.add(p);
  }
  const hallWCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallWCig.position.set(0.42, 0.055, -24.0);
  hallWCig.rotation.z = Math.PI / 2;
  hallWCig.rotation.y = 0.35;
  hallWCig.name = 'hallWCig';
  prison.group.add(hallWCig);
  const hallPCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallPCig.position.set(0.22, 0.055, -38.0);
  hallPCig.rotation.z = Math.PI / 2;
  hallPCig.rotation.y = -0.3;
  hallPCig.name = 'hallPCig';
  prison.group.add(hallPCig);
  const hallVCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallVCig.position.set(-0.58, 0.055, -16.2);
  hallVCig.rotation.z = Math.PI / 2;
  hallVCig.rotation.y = 0.4;
  hallVCig.name = 'hallVCig';
  prison.group.add(hallVCig);
  const hallKCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallKCig.position.set(0.17, 0.055, -32.4);
  hallKCig.rotation.z = Math.PI / 2;
  hallKCig.rotation.y = -0.25;
  hallKCig.name = 'hallKCig';
  prison.group.add(hallKCig);
  const hallJCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallJCig.position.set(-0.33, 0.055, -21.8);
  hallJCig.rotation.z = Math.PI / 2;
  hallJCig.rotation.y = 0.28;
  hallJCig.name = 'hallJCig';
  prison.group.add(hallJCig);
  const hallICig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallICig.position.set(0.52, 0.055, -13.6);
  hallICig.rotation.z = Math.PI / 2;
  hallICig.rotation.y = -0.22;
  hallICig.name = 'hallICig';
  prison.group.add(hallICig);
  const hallBCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallBCig.position.set(1.85, 0.50, -11.2);
  hallBCig.rotation.z = Math.PI / 2;
  hallBCig.rotation.y = 0.18;
  hallBCig.name = 'hallBCig';
  prison.group.add(hallBCig);
  const hallCCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallCCig.position.set(-1.85, 0.50, -18.0);
  hallCCig.rotation.z = Math.PI / 2;
  hallCCig.rotation.y = -0.2;
  hallCCig.name = 'hallCCig';
  prison.group.add(hallCCig);
  const hallDCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallDCig.position.set(-1.85, 0.50, -32.0);
  hallDCig.rotation.z = Math.PI / 2;
  hallDCig.rotation.y = 0.22;
  hallDCig.name = 'hallDCig';
  prison.group.add(hallDCig);
  const hallECig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallECig.position.set(1.85, 0.50, -25.6);
  hallECig.rotation.z = Math.PI / 2;
  hallECig.rotation.y = 0.14;
  hallECig.name = 'hallECig';
  prison.group.add(hallECig);
  const hallFCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallFCig.position.set(1.85, 0.50, -38.4);
  hallFCig.rotation.z = Math.PI / 2;
  hallFCig.rotation.y = -0.18;
  hallFCig.name = 'hallFCig';
  prison.group.add(hallFCig);
  const hallGCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallGCig.position.set(2.18, 0.055, -28.05);
  hallGCig.rotation.z = Math.PI / 2;
  hallGCig.rotation.y = -0.32;
  hallGCig.name = 'hallGCig';
  prison.group.add(hallGCig);
  const hallHCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallHCig.position.set(-2.18, 0.055, -33.2);
  hallHCig.rotation.z = Math.PI / 2;
  hallHCig.rotation.y = 0.28;
  hallHCig.name = 'hallHCig';
  prison.group.add(hallHCig);
  const hallMCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallMCig.position.set(2.18, 0.055, -15.8);
  hallMCig.rotation.z = Math.PI / 2;
  hallMCig.rotation.y = -0.24;
  hallMCig.name = 'hallMCig';
  prison.group.add(hallMCig);
  const hallOCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallOCig.position.set(-2.18, 0.055, -30.15);
  hallOCig.rotation.z = Math.PI / 2;
  hallOCig.rotation.y = 0.26;
  hallOCig.name = 'hallOCig';
  prison.group.add(hallOCig);
  const hallUCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallUCig.position.set(2.18, 0.055, -40.5);
  hallUCig.rotation.z = Math.PI / 2;
  hallUCig.rotation.y = -0.28;
  hallUCig.name = 'hallUCig';
  prison.group.add(hallUCig);
  const hallZCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallZCig.position.set(-2.18, 0.055, -12.4);
  hallZCig.rotation.z = Math.PI / 2;
  hallZCig.rotation.y = 0.22;
  hallZCig.name = 'hallZCig';
  prison.group.add(hallZCig);
  const hallTXCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallTXCig.position.set(-2.18, 0.055, -22.6);
  hallTXCig.rotation.z = Math.PI / 2;
  hallTXCig.rotation.y = -0.2;
  hallTXCig.name = 'hallTXCig';
  prison.group.add(hallTXCig);
  const hallAACig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallAACig.position.set(2.18, 0.055, -30.85);
  hallAACig.rotation.z = Math.PI / 2;
  hallAACig.rotation.y = 0.18;
  hallAACig.name = 'hallAACig';
  prison.group.add(hallAACig);
  const hallBBCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallBBCig.position.set(2.18, 0.055, -18.1);
  hallBBCig.rotation.z = Math.PI / 2;
  hallBBCig.rotation.y = -0.16;
  hallBBCig.name = 'hallBBCig';
  prison.group.add(hallBBCig);
  const hallCCCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallCCCig.position.set(-2.18, 0.055, -24.8);
  hallCCCig.rotation.z = Math.PI / 2;
  hallCCCig.rotation.y = 0.2;
  hallCCCig.name = 'hallCCCig';
  prison.group.add(hallCCCig);
  const hallDDCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallDDCig.position.set(2.18, 0.055, -32.25);
  hallDDCig.rotation.z = Math.PI / 2;
  hallDDCig.rotation.y = -0.22;
  hallDDCig.name = 'hallDDCig';
  prison.group.add(hallDDCig);
  const hallEECig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallEECig.position.set(-2.18, 0.055, -28.6);
  hallEECig.rotation.z = Math.PI / 2;
  hallEECig.rotation.y = -0.18;
  hallEECig.name = 'hallEECig';
  prison.group.add(hallEECig);
  const hallFFCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallFFCig.position.set(2.18, 0.055, -23.2);
  hallFFCig.rotation.z = Math.PI / 2;
  hallFFCig.rotation.y = 0.24;
  hallFFCig.name = 'hallFFCig';
  prison.group.add(hallFFCig);
  const hallGGCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallGGCig.position.set(-2.18, 0.055, -15.2);
  hallGGCig.rotation.z = Math.PI / 2;
  hallGGCig.rotation.y = -0.2;
  hallGGCig.name = 'hallGGCig';
  prison.group.add(hallGGCig);
  const hallHHCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallHHCig.position.set(-2.18, 0.055, -20.5);
  hallHHCig.rotation.z = Math.PI / 2;
  hallHHCig.rotation.y = 0.16;
  hallHHCig.name = 'hallHHCig';
  prison.group.add(hallHHCig);
  const hallIICig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallIICig.position.set(2.18, 0.055, -29.45);
  hallIICig.rotation.z = Math.PI / 2;
  hallIICig.rotation.y = -0.14;
  hallIICig.name = 'hallIICig';
  prison.group.add(hallIICig);
  const hallJJCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallJJCig.position.set(-2.18, 0.055, -13.8);
  hallJJCig.rotation.z = Math.PI / 2;
  hallJJCig.rotation.y = 0.12;
  hallJJCig.name = 'hallJJCig';
  prison.group.add(hallJJCig);
  const hallKKCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallKKCig.position.set(2.18, 0.055, -21.85);
  hallKKCig.rotation.z = Math.PI / 2;
  hallKKCig.rotation.y = -0.11;
  hallKKCig.name = 'hallKKCig';
  prison.group.add(hallKKCig);
  const hallLLCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallLLCig.position.set(2.18, 0.055, -16.95);
  hallLLCig.rotation.z = Math.PI / 2;
  hallLLCig.rotation.y = 0.13;
  hallLLCig.name = 'hallLLCig';
  prison.group.add(hallLLCig);
  const hallMMCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallMMCig.position.set(-2.18, 0.055, -16.55);
  hallMMCig.rotation.z = Math.PI / 2;
  hallMMCig.rotation.y = -0.15;
  hallMMCig.name = 'hallMMCig';
  prison.group.add(hallMMCig);
  const hallNNCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallNNCig.position.set(-2.18, 0.055, -21.55);
  hallNNCig.rotation.z = Math.PI / 2;
  hallNNCig.rotation.y = 0.14;
  hallNNCig.name = 'hallNNCig';
  prison.group.add(hallNNCig);
  const hallOOCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallOOCig.position.set(-2.18, 0.055, -25.9);
  hallOOCig.rotation.z = Math.PI / 2;
  hallOOCig.rotation.y = -0.12;
  hallOOCig.name = 'hallOOCig';
  prison.group.add(hallOOCig);
  const hallPPCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallPPCig.position.set(2.18, 0.055, -34.95);
  hallPPCig.rotation.z = Math.PI / 2;
  hallPPCig.rotation.y = 0.11;
  hallPPCig.name = 'hallPPCig';
  prison.group.add(hallPPCig);
  const hallQQCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallQQCig.position.set(-2.18, 0.055, -34.7);
  hallQQCig.rotation.z = Math.PI / 2;
  hallQQCig.rotation.y = -0.16;
  hallQQCig.name = 'hallQQCig';
  prison.group.add(hallQQCig);
  const hallRRCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallRRCig.position.set(2.18, 0.055, -32.95);
  hallRRCig.rotation.z = Math.PI / 2;
  hallRRCig.rotation.y = 0.15;
  hallRRCig.name = 'hallRRCig';
  prison.group.add(hallRRCig);
  const hallSSCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallSSCig.position.set(-2.18, 0.055, -38.16);
  hallSSCig.rotation.z = Math.PI / 2;
  hallSSCig.rotation.y = 0.13;
  hallSSCig.name = 'hallSSCig';
  prison.group.add(hallSSCig);
  const hallTTCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallTTCig.position.set(2.18, 0.055, -39.45);
  hallTTCig.rotation.z = Math.PI / 2;
  hallTTCig.rotation.y = -0.14;
  hallTTCig.name = 'hallTTCig';
  prison.group.add(hallTTCig);
  const hallUUCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallUUCig.position.set(2.18, 0.055, -35.6);
  hallUUCig.rotation.z = Math.PI / 2;
  hallUUCig.rotation.y = 0.12;
  hallUUCig.name = 'hallUUCig';
  prison.group.add(hallUUCig);
  const hallVVCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallVVCig.position.set(-2.18, 0.055, -29.38);
  hallVVCig.rotation.z = Math.PI / 2;
  hallVVCig.rotation.y = -0.13;
  hallVVCig.name = 'hallVVCig';
  prison.group.add(hallVVCig);
  const hallWWCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallWWCig.position.set(2.18, 0.055, -26.85);
  hallWWCig.rotation.z = Math.PI / 2;
  hallWWCig.rotation.y = 0.15;
  hallWWCig.name = 'hallWWCig';
  prison.group.add(hallWWCig);
  const hallXXCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallXXCig.position.set(-2.18, 0.055, -15.88);
  hallXXCig.rotation.z = Math.PI / 2;
  hallXXCig.rotation.y = 0.11;
  hallXXCig.name = 'hallXXCig';
  prison.group.add(hallXXCig);
  const hallYYCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallYYCig.position.set(-2.18, 0.055, -14.5);
  hallYYCig.rotation.z = Math.PI / 2;
  hallYYCig.rotation.y = -0.14;
  hallYYCig.name = 'hallYYCig';
  prison.group.add(hallYYCig);
  const hallZZCig = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
  );
  hallZZCig.position.set(-2.18, 0.055, -13.1);
  hallZZCig.rotation.z = Math.PI / 2;
  hallZZCig.rotation.y = 0.16;
  hallZZCig.name = 'hallZZCig';
  prison.group.add(hallZZCig);
}

/** Fill the black 2m hole between сборник (ends ~z=-2) and коряк (starts z=0). */
function addVestibule(prison) {
  const z = -1.05;
  const len = 2.5;
  const W = 5.35;
  const h = 3.1;
  const floor = prison.mat(prison.tex.plaster, { roughness: 0.85, metalness: 0, env: 0.08, repeat: [2, 1] });
  floor.color.set(0x7a7872);
  prison.box(W, 0.08, len, floor, 0, 0.03, z);
  prison.box(W, 0.16, len, new THREE.MeshStandardMaterial({ color: 0xc4beb2, roughness: 0.88 }), 0, h, z);
  const wall = new THREE.MeshStandardMaterial({ color: 0xd2ccbe, roughness: 0.9, side: THREE.DoubleSide });
  const dado = new THREE.MeshStandardMaterial({ color: 0x3a6a62, roughness: 0.75, side: THREE.DoubleSide });
  const steel = new THREE.MeshStandardMaterial({
    color: 0x4a5058,
    metalness: 0.45,
    roughness: 0.45,
    side: THREE.DoubleSide,
  });
  for (const side of [-1, 1]) {
    const x = side * (W / 2);
    prison.box(0.22, 1.15, len, dado, x, 0.57, z).userData.camCollide = true;
    prison.box(0.22, h - 1.15, len, wall, x, 1.15 + (h - 1.15) / 2, z).userData.camCollide = true;
    prison.addCollider(
      side > 0 ? W / 2 - 0.2 : -W / 2 - 0.12,
      side > 0 ? W / 2 + 0.12 : -W / 2 + 0.2,
      z - len / 2,
      z + len / 2,
      `vest-${side}`,
    );
  }
  const hw = 1.42;
  for (const side of [-1, 1]) {
    const inner = side * hw;
    const outer = side * (W / 2);
    const mid = (inner + outer) / 2;
    const thick = Math.abs(outer - inner);
    prison.box(thick, h, 0.28, steel, mid, h / 2, 0.08).userData.camCollide = true;
    prison.addCollider(
      Math.min(inner, outer),
      Math.max(inner, outer),
      -0.12,
      0.22,
      `vest-bulk-${side}`,
    );
  }
  prison.box(hw * 2 + 0.2, 0.35, 0.28, steel, 0, 2.75, 0.08);
  prison.box(0.12, 2.2, 0.28, steel, -hw, 1.1, 0.08);
  prison.box(0.12, 2.2, 0.28, steel, hw, 1.1, 0.08);
  const lamp = new THREE.PointLight(0xf0ead0, 1.05, 11, 1.5);
  lamp.position.set(0, 2.65, -1.05);
  prison.group.add(lamp);
  const tube = new THREE.Mesh(
    new THREE.CylinderGeometry(0.035, 0.035, 0.7, 8),
    new THREE.MeshStandardMaterial({ color: 0xf0eed8, emissive: 0xd8d4b8, emissiveIntensity: 0.55 }),
  );
  tube.rotation.x = Math.PI / 2;
  tube.position.set(0, 2.88, -1.05);
  prison.group.add(tube);
}

function kazenkaPile(prison, x, z) {
  const cloth = new THREE.MeshStandardMaterial({ color: 0x9a9a52, roughness: 0.82 });
  const band = new THREE.MeshStandardMaterial({ color: 0x1a1a18, roughness: 0.8 });
  const slip = new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.9 });
  const layers = [
    [0.62, 0.16, 0.44, 0.08],
    [0.58, 0.14, 0.4, 0.23],
    [0.54, 0.14, 0.38, 0.37],
    [0.5, 0.12, 0.34, 0.5],
  ];
  for (const [w, h, d, y] of layers) {
    prison.box(w, h, d, cloth, x, y, z);
    prison.box(w + 0.02, 0.035, d + 0.02, band, x, y + h * 0.15, z);
    prison.box(w + 0.02, 0.035, d + 0.02, band, x, y - h * 0.2, z);
  }
  prison.box(0.22, 0.08, 0.22, slip, x - 0.38, 0.06, z + 0.18);
  prison.box(0.22, 0.08, 0.22, slip, x - 0.28, 0.06, z + 0.32);
}

function alcove(prison, x, z, title) {
  const g = new THREE.Group();
  g.position.set(x, 0, z);
  prison.group.add(g);
  const wall = new THREE.MeshStandardMaterial({ color: 0x6a665c, roughness: 0.9 });
  const floor = new THREE.MeshStandardMaterial({ color: 0x8a8882, roughness: 0.86 });
  const ceil = new THREE.MeshStandardMaterial({ color: 0x8a8478, roughness: 0.88 });
  prison.box(3.6, 0.06, 3.5, floor, 0, 0.03, 0, g);
  prison.box(3.6, 0.22, 3.5, ceil, 0, 3.08, 0, g);
  prison.box(3.6, 3.1, 0.14, wall, 0, 1.55, 1.7, g);
  prison.box(3.6, 3.1, 0.14, wall, 0, 1.55, -1.7, g);
  prison.box(0.14, 3.1, 3.4, wall, (x < 0 ? -1 : 1) * 1.75, 1.55, 0, g);
  const dadoHall = new THREE.MeshStandardMaterial({ color: 0x3a6a62, roughness: 0.75 });
  prison.box(3.4, 1.12, 0.05, dadoHall, 0, 0.56, 1.61, g);
  prison.box(3.4, 1.12, 0.05, dadoHall, 0, 0.56, -1.61, g);
  const faceCover = new THREE.MeshStandardMaterial({ color: 0x3e3c38, roughness: 0.9 });
  prison.box(3.4, 1.65, 0.04, faceCover, 0, 2.02, 1.61, g);
  prison.box(3.4, 1.65, 0.04, faceCover, 0, 2.02, -1.61, g);
  const darkBoard = new THREE.MeshStandardMaterial({ color: 0x3e423c, roughness: 0.72 });
  prison.box(2.4, 1.35, 0.05, darkBoard, 0.1, 1.95, -1.58, g);
  prison.box(2.4, 1.35, 0.05, darkBoard, 0.1, 1.95, 1.58, g);
  const farFace = (x < 0 ? -1 : 1) * 1.68;
  prison.box(0.08, 2.6, 2.8, darkBoard, farFace, 1.4, 0, g);
  const lamp = new THREE.PointLight(0xf2ead0, 0.22, 4.6, 2.0);
  lamp.position.set(0, 2.45, 0);
  g.add(lamp);
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
    const bag = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.12, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x3a3530, roughness: 0.9 }),
    );
    bag.position.set(-0.2, 1.02, 0.15);
    g.add(bag);
    const bin = new THREE.Mesh(
      new THREE.BoxGeometry(0.42, 0.22, 0.32),
      new THREE.MeshStandardMaterial({ color: 0x6a6e50, roughness: 0.7 }),
    );
    bin.position.set(0.55, 0.22, -0.5);
    g.add(bin);
    prison.box(0.08, 1.85, 0.08, metal, -0.7, 0.92, -1.0, g);
    prison.box(0.08, 1.85, 0.08, metal, 0.7, 0.92, -1.0, g);
    prison.box(1.5, 0.08, 0.08, metal, 0, 1.82, -1.0, g);
    const tags = plaque('№ 4417', 0.55, 0.16);
    tags.position.set(0.2, 1.22, 0.55);
    g.add(tags);
    const peel = new THREE.MeshStandardMaterial({ color: 0x6a5240, roughness: 0.92 });
    prison.box(0.03, 0.7, 1.1, peel, -1.68, 2.15, 0.2, g);
    prison.box(0.03, 0.45, 0.6, peel, -1.68, 1.55, -0.8, g);
    const damp = new THREE.MeshStandardMaterial({ color: 0x6a6860, roughness: 0.55, transparent: true, opacity: 0.45 });
    prison.box(0.03, 0.9, 0.8, damp, -1.68, 2.0, 0.9, g);
    const papers = new THREE.MeshStandardMaterial({ color: 0xe8e0cc, roughness: 0.9 });
    prison.box(0.22, 0.012, 0.16, papers, -0.15, 0.97, 0.05, g);
    prison.box(0.18, 0.01, 0.14, papers, 0.22, 0.97, 0.18, g);
    const stamp = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 0.05, 8), metal);
    stamp.position.set(0.35, 0.99, 0.28);
    g.add(stamp);
    const ledger = new THREE.Mesh(
      new THREE.BoxGeometry(0.2, 0.03, 0.28),
      new THREE.MeshStandardMaterial({ color: 0x3a2020, roughness: 0.85 }),
    );
    ledger.position.set(-0.45, 0.98, 0.08);
    g.add(ledger);
    const cab = new THREE.MeshStandardMaterial({ color: 0x4a4e46, metalness: 0.3, roughness: 0.55 });
    prison.box(0.45, 1.15, 0.4, cab, -1.2, 0.58, -1.15, g);
    prison.box(0.42, 0.02, 0.38, metal, -1.2, 0.85, -1.15, g);
    prison.box(0.42, 0.02, 0.38, metal, -1.2, 0.45, -1.15, g);
    const coat = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.85, 0.08),
      new THREE.MeshStandardMaterial({ color: 0x1a1c20, roughness: 0.9 }),
    );
    coat.position.set(1.2, 1.35, -0.4);
    g.add(coat);
    prison.box(0.04, 0.04, 0.08, metal, 1.2, 1.8, -0.4, g);
    const ceilPipe = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 2.4, 6), metal);
    ceilPipe.rotation.z = Math.PI / 2;
    ceilPipe.position.set(0, 2.85, 0.4);
    g.add(ceilPipe);
    const ceilDamp = new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.92, transparent: true, opacity: 0.4 });
    prison.box(1.2, 0.02, 0.5, ceilDamp, 0.2, 2.96, -0.3, g);
    prison.box(0.16, 0.01, 0.12, papers, 0.4, 0.05, -0.6, g);
    prison.box(0.35, 0.08, 0.28, metal, 1.1, 0.12, 0.5, g);
    const cuffs = new THREE.Mesh(new THREE.TorusGeometry(0.04, 0.008, 6, 10), metal);
    cuffs.position.set(0.5, 0.98, -0.05);
    cuffs.rotation.x = Math.PI / 2;
    g.add(cuffs);
    const list = plaque('ВЕЩИ', 0.55, 0.18);
    list.position.set(0, 2.15, -1.55);
    g.add(list);
    const wet = new THREE.Mesh(
      new THREE.CircleGeometry(0.28, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a4038, roughness: 0.2, metalness: 0.15 }),
    );
    wet.rotation.x = -Math.PI / 2;
    wet.position.set(-0.3, 0.05, -0.4);
    g.add(wet);
  }
  if (title === 'ФОТО') {
    prison.box(2.2, 2.4, 0.05, new THREE.MeshStandardMaterial({ color: 0x8a8478, roughness: 0.82 }), 0.2, 1.3, -1.55, g);
    const grid = new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.7 });
    for (let i = 0; i < 8; i++) {
      prison.box(2.05, 0.012, 0.02, grid, 0.2, 0.38 + i * 0.28, -1.52, g);
    }
    prison.box(0.012, 2.2, 0.02, grid, -0.75, 1.3, -1.52, g);
    prison.box(0.012, 2.2, 0.02, grid, 1.15, 1.3, -1.52, g);
    const frame = new THREE.MeshStandardMaterial({ color: 0x3a3a36, roughness: 0.6 });
    prison.box(2.28, 0.05, 0.06, frame, 0.2, 2.48, -1.55, g);
    prison.box(2.28, 0.05, 0.06, frame, 0.2, 0.12, -1.55, g);
    const marks = plaque('180\n170\n160', 0.42, 1.05);
    marks.position.set(-1.15, 1.45, -1.48);
    g.add(marks);
    prison.box(0.12, 1.1, 0.12, metal, -0.4, 0.7, 0.3, g);
    prison.box(0.22, 0.16, 0.18, darkCam(), -0.4, 1.28, 0.4, g);
    const stool = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.2, 0.08, 10), wood);
    stool.position.set(0.45, 0.45, 0);
    g.add(stool);
    prison.box(0.06, 0.42, 0.06, wood, 0.45, 0.22, 0, g);
    const flash = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.18, 0.12),
      new THREE.MeshStandardMaterial({ color: 0xf2ead0, emissive: 0xfff2c4, emissiveIntensity: 0.35 }),
    );
    flash.position.set(-0.4, 1.48, 0.5);
    g.add(flash);
    const pad = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.04, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x1a1a18, roughness: 0.9 }),
    );
    pad.position.set(0.15, 0.96, 0.35);
    g.add(pad);
    prison.box(0.55, 0.08, 0.32, wood, 0.2, 0.92, 0.35, g);
    prison.box(0.06, 0.88, 0.06, wood, 0.0, 0.44, 0.22, g);
    prison.box(0.06, 0.88, 0.06, wood, 0.4, 0.44, 0.48, g);
    const peel = new THREE.MeshStandardMaterial({ color: 0xb8b0a0, roughness: 0.92 });
    const damp = new THREE.MeshStandardMaterial({ color: 0x6a6860, roughness: 0.55, transparent: true, opacity: 0.45 });
    prison.box(0.03, 0.7, 1.0, peel, 1.68, 2.15, 0.15, g);
    prison.box(0.03, 0.5, 0.7, damp, 1.68, 1.85, -0.7, g);
    prison.box(1.1, 0.02, 0.45, damp, 0.2, 2.96, 0.4, g);
    const ceilPipe = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 2.2, 6), metal);
    ceilPipe.rotation.z = Math.PI / 2;
    ceilPipe.position.set(0, 2.85, -0.35);
    g.add(ceilPipe);
    const cards = new THREE.MeshStandardMaterial({ color: 0xe8e0cc, roughness: 0.9 });
    prison.box(0.16, 0.008, 0.22, cards, 0.05, 0.97, 0.28, g);
    prison.box(0.14, 0.008, 0.18, cards, 0.28, 0.97, 0.4, g);
    const ink = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.04, 0.04, 8),
      new THREE.MeshStandardMaterial({ color: 0x1a1a18, roughness: 0.7 }),
    );
    ink.position.set(0.42, 0.98, 0.22);
    g.add(ink);
    const cab = new THREE.MeshStandardMaterial({ color: 0x4a4e46, metalness: 0.3, roughness: 0.55 });
    prison.box(0.4, 1.05, 0.38, cab, 1.2, 0.54, -1.15, g);
    const coat = new THREE.Mesh(
      new THREE.BoxGeometry(0.26, 0.8, 0.07),
      new THREE.MeshStandardMaterial({ color: 0x1a1c20, roughness: 0.9 }),
    );
    coat.position.set(-1.15, 1.3, 0.55);
    g.add(coat);
    const anfas = plaque('АНФАС', 0.7, 0.2);
    anfas.position.set(0, 2.2, 1.55);
    g.add(anfas);
    const wet = new THREE.Mesh(
      new THREE.CircleGeometry(0.25, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a4038, roughness: 0.22, metalness: 0.12 }),
    );
    wet.rotation.x = -Math.PI / 2;
    wet.position.set(-0.35, 0.05, -0.5);
    g.add(wet);
    const numCard = plaque('№ 4418', 0.5, 0.16);
    numCard.position.set(0.2, 1.18, 0.5);
    g.add(numCard);
  }
  if (title === 'МЕД') {
    prison.box(1.6, 0.12, 0.55, new THREE.MeshStandardMaterial({ color: 0xe8e4dc }), 0, 0.72, 0, g);
    prison.box(0.08, 0.7, 0.08, metal, -0.7, 0.35, 0.2, g);
    prison.box(0.08, 0.7, 0.08, metal, 0.7, 0.35, -0.2, g);
    const bottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.035, 0.12, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a2020, roughness: 0.4 }),
    );
    bottle.position.set(-0.35, 0.86, 0.05);
    g.add(bottle);
    const scale = new THREE.Mesh(
      new THREE.BoxGeometry(0.35, 0.06, 0.28),
      new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.45, roughness: 0.4 }),
    );
    scale.position.set(0.7, 0.08, -0.4);
    g.add(scale);
    const lamp = new THREE.Mesh(new THREE.SphereGeometry(0.08, 8, 6), new THREE.MeshStandardMaterial({
      color: 0xf2ead0,
      emissive: 0xffe8b0,
      emissiveIntensity: 0.5,
    }));
    lamp.position.set(0.2, 1.55, 0.2);
    g.add(lamp);
    const hiv = plaque('АНАЛИЗ', 0.7, 0.2);
    hiv.position.set(0, 2.15, 1.62);
    g.add(hiv);
    const peel = new THREE.MeshStandardMaterial({ color: 0xb8b0a0, roughness: 0.92 });
    const damp = new THREE.MeshStandardMaterial({ color: 0x6a6860, roughness: 0.55, transparent: true, opacity: 0.45 });
    prison.box(0.03, 0.65, 0.9, peel, -1.68, 2.15, 0.2, g);
    prison.box(0.03, 0.5, 0.7, damp, -1.68, 1.9, -0.7, g);
    prison.box(1.0, 0.02, 0.45, damp, 0.1, 2.96, 0.3, g);
    const ceilPipe = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 2.1, 6), metal);
    ceilPipe.rotation.z = Math.PI / 2;
    ceilPipe.position.set(0, 2.84, -0.3);
    g.add(ceilPipe);
    const papers = new THREE.MeshStandardMaterial({ color: 0xe8e0cc, roughness: 0.9 });
    prison.box(0.18, 0.01, 0.14, papers, 0.25, 0.79, 0.05, g);
    prison.box(0.14, 0.01, 0.12, papers, -0.15, 0.79, 0.12, g);
    const cotton = new THREE.Mesh(
      new THREE.SphereGeometry(0.04, 6, 6),
      new THREE.MeshStandardMaterial({ color: 0xe8e4dc, roughness: 0.95 }),
    );
    cotton.position.set(0.45, 0.82, -0.08);
    g.add(cotton);
    const tray = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.02, 0.14),
      new THREE.MeshStandardMaterial({ color: 0xb0b4b0, metalness: 0.4, roughness: 0.45 }),
    );
    tray.position.set(0.55, 0.79, 0.15);
    g.add(tray);
    const cab = new THREE.MeshStandardMaterial({ color: 0x4a4e46, metalness: 0.3, roughness: 0.55 });
    prison.box(0.42, 1.1, 0.38, cab, -1.15, 0.56, -1.1, g);
    const coat = new THREE.Mesh(
      new THREE.BoxGeometry(0.26, 0.8, 0.07),
      new THREE.MeshStandardMaterial({ color: 0x1a1c20, roughness: 0.9 }),
    );
    coat.position.set(1.15, 1.3, 0.4);
    g.add(coat);
    const exam = plaque('ОСМОТР', 0.75, 0.2);
    exam.position.set(0, 2.2, -1.55);
    g.add(exam);
    const wet = new THREE.Mesh(
      new THREE.CircleGeometry(0.28, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a4038, roughness: 0.22, metalness: 0.12 }),
    );
    wet.rotation.x = -Math.PI / 2;
    wet.position.set(-0.2, 0.05, 0.4);
    g.add(wet);
    const jar2 = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.03, 0.1, 8),
      new THREE.MeshStandardMaterial({ color: 0xc8d8c8, roughness: 0.3, metalness: 0.1, transparent: true, opacity: 0.7 }),
    );
    jar2.position.set(0.15, 0.86, -0.12);
    g.add(jar2);
  }
  if (title === 'БАНЯ') {
    const dado = new THREE.MeshStandardMaterial({ color: 0x3a5a54, roughness: 0.72 });
    const tile = new THREE.MeshStandardMaterial({ color: 0x5e6c66, roughness: 0.62 });
    const wallX = (x < 0 ? -1 : 1) * 1.68;
    prison.box(3.4, 1.12, 0.05, dado, 0, 0.56, 1.62, g);
    prison.box(3.4, 1.12, 0.05, dado, 0, 0.56, -1.62, g);
    prison.box(0.05, 1.12, 3.2, dado, wallX, 0.56, 0, g);
    prison.box(3.4, 1.55, 0.04, tile, 0, 1.92, 1.62, g);
    prison.box(3.4, 1.55, 0.04, tile, 0, 1.92, -1.62, g);
    const chrome = new THREE.MeshStandardMaterial({ color: 0xb0b4b8, metalness: 0.7, roughness: 0.3 });
    const head = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.08, 0.1, 8), chrome);
    head.position.set(0.5, 1.55, 0.8);
    g.add(head);
    prison.box(0.06, 2.1, 0.06, chrome, 0.85, 1.15, 1.55, g);
    prison.box(0.7, 0.08, 0.36, wood, 0.55, 0.42, -1.15, g);
    prison.box(0.08, 0.4, 0.08, wood, 0.1, 0.2, -1.05, g);
    prison.box(0.08, 0.4, 0.08, wood, 1.0, 0.2, -1.05, g);
    prison.box(0.45, 0.9, 0.45, wood, -0.4, 0.5, 0, g);
    const cloth = new THREE.MeshStandardMaterial({ color: 0x8a8a4a, roughness: 0.85 });
    const band = new THREE.MeshStandardMaterial({ color: 0x1e1e1c, roughness: 0.8 });
    for (const [lx, ly, lz, rot] of [
      [-0.55, 1.15, 0.15, 0.12],
      [-0.75, 1.12, -0.25, -0.18],
    ]) {
      const robe = new THREE.Mesh(new THREE.BoxGeometry(0.36, 0.85, 0.07), cloth);
      robe.position.set(lx, ly, lz);
      robe.rotation.y = rot;
      g.add(robe);
      const s1 = new THREE.Mesh(new THREE.BoxGeometry(0.38, 0.07, 0.08), band);
      s1.position.set(lx, ly + 0.12, lz);
      s1.rotation.y = rot;
      g.add(s1);
      const s2 = s1.clone();
      s2.position.y = ly - 0.18;
      g.add(s2);
    }
    const clip = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.06, 0.05), chrome);
    clip.position.set(-0.2, 0.98, 0.05);
    g.add(clip);
    const grate = new THREE.Mesh(
      new THREE.CircleGeometry(0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a2c30, metalness: 0.5, roughness: 0.4 }),
    );
    grate.rotation.x = -Math.PI / 2;
    grate.position.set(0.5, 0.04, 0.3);
    g.add(grate);
    const peel = new THREE.MeshStandardMaterial({ color: 0xb8b0a0, roughness: 0.92 });
    const damp = new THREE.MeshStandardMaterial({ color: 0x6a6860, roughness: 0.55, transparent: true, opacity: 0.45 });
    prison.box(0.03, 0.65, 0.9, peel, wallX, 2.15, 0.2, g);
    prison.box(0.03, 0.5, 0.7, damp, wallX, 1.9, -0.6, g);
    prison.box(1.0, 0.02, 0.4, damp, 0.15, 2.96, 0.3, g);
    const ceilPipe = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 2.0, 6), chrome);
    ceilPipe.rotation.z = Math.PI / 2;
    ceilPipe.position.set(0, 2.82, -0.4);
    g.add(ceilPipe);
    const hair = new THREE.Mesh(
      new THREE.CircleGeometry(0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a221c, roughness: 0.95 }),
    );
    hair.rotation.x = -Math.PI / 2;
    hair.position.set(0.15, 0.045, -0.35);
    g.add(hair);
    const wet = new THREE.Mesh(
      new THREE.CircleGeometry(0.45, 10),
      new THREE.MeshStandardMaterial({ color: 0x6a7a78, roughness: 0.18, metalness: 0.12 }),
    );
    wet.rotation.x = -Math.PI / 2;
    wet.position.set(0.2, 0.04, 0.15);
    g.add(wet);
    const bucket = new THREE.Mesh(
      new THREE.CylinderGeometry(0.12, 0.1, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, metalness: 0.3, roughness: 0.55 }),
    );
    bucket.position.set(0.85, 0.14, -0.55);
    g.add(bucket);
    const soap = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.03, 0.05),
      new THREE.MeshStandardMaterial({ color: 0xd8d0c0, roughness: 0.6 }),
    );
    soap.position.set(0.5, 0.48, -1.1);
    g.add(soap);
    const cut = plaque('СТРИЧКА', 0.85, 0.2);
    cut.position.set(0, 2.2, 1.55);
    g.add(cut);
    const towel = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.55, 0.05),
      new THREE.MeshStandardMaterial({ color: 0xc8c0b0, roughness: 0.9 }),
    );
    towel.position.set(-0.9, 1.25, 0.7);
    towel.rotation.z = 0.1;
    g.add(towel);
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

function procSegments(start, end, gaps, half) {
  const cuts = gaps.map((z) => [z - half, z + half]).sort((a, b) => a[0] - b[0]);
  const segs = [];
  let cursor = start;
  for (const [a, b] of cuts) {
    if (a > cursor + 0.05) segs.push([cursor, a]);
    cursor = Math.max(cursor, b);
  }
  if (cursor < end) segs.push([cursor, end]);
  return segs;
}
