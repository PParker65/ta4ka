import * as THREE from 'three';
import {
  plasterTex,
  occupiedBlueTex,
  corridorPlasterTex,
  blueTileTex,
  whiteTileTex,
  redFloorTex,
  brokenFloorTex,
  latticeTex,
  brickTex,
  ceilingTex,
  diamondCeilingTex,
  greenMetalTex,
  createFlickerMaterial,
} from '../shaders/environment.js';
import { buildArrival, openKppGate } from './Exterior.js';

export const LAYOUT = {
  corridorHalf: 1.42,
  corridorLen: 38,
  wallH: 2.55,
  vaultR: 1.7,
  cellW: 6.4,
  cellD: 7.2,
  doorW: 0.92,
  doorH: 2.08,
};

export class Prison {
  constructor(scene) {
    this.scene = scene;
    this.colliders = [];
    this.interactables = [];
    this.flickerMats = [];
    this.doors = [];
    this.cameras = [];
    this.group = new THREE.Group();
    this.group.name = 'SIZO';
    scene.add(this.group);
    this.tex = {};
  }

  build() {
    this.tex = {
      plaster: plasterTex(),
      occupied: occupiedBlueTex(),
      cPlaster: corridorPlasterTex(),
      blue: blueTileTex(),
      white: whiteTileTex(),
      red: redFloorTex(),
      broken: brokenFloorTex(),
      lattice: latticeTex(),
      brick: brickTex(),
      ceil: ceilingTex(),
      diamond: diamondCeilingTex(),
      green: greenMetalTex(),
    };

    this.addCorridor();
    this.addVault();
    this.addCellDoors();
    this.addPlayerCell();
    this.addOppositeCells();
    this.addDutyRoom();
    this.addYard();
    this.addPipesAndProps();
    this.addLamps();
    this.addCctvBodies();
    this.addIntake();
    this.addBoundaryColliders();
  }

  mat(map, opts = {}) {
    const tex = map.clone();
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.anisotropy = 8;
    tex.generateMipmaps = true;
    tex.minFilter = THREE.LinearMipmapLinearFilter;
    tex.magFilter = THREE.LinearFilter;
    tex.needsUpdate = true;
    if (opts.repeat) tex.repeat.set(opts.repeat[0], opts.repeat[1]);
    return new THREE.MeshStandardMaterial({
      map: tex,
      roughness: opts.roughness ?? 0.86,
      metalness: opts.metalness ?? 0.02,
      color: opts.color ?? 0xffffff,
      transparent: !!opts.transparent,
      opacity: opts.opacity ?? 1,
      envMapIntensity: opts.env ?? 0.4,
    });
  }

  box(w, h, d, material, x, y, z, parent = this.group) {
    const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
    m.position.set(x, y, z);
    m.castShadow = false;
    m.receiveShadow = true;
    parent.add(m);
    return m;
  }

  addCollider(minx, maxx, minz, maxz, id) {
    this.colliders.push({ minx, maxx, minz, maxz, id, active: true });
  }

  addCorridor() {
    const L = LAYOUT.corridorLen;
    const hw = LAYOUT.corridorHalf;
    const h = LAYOUT.wallH;
    const floor = this.box(
      hw * 2 + 0.08,
      0.06,
      L,
      this.mat(this.tex.red, { roughness: 0.78, metalness: 0, env: 0.12, repeat: [1.8, 6] }),
      0,
      0.03,
      L / 2,
    );
    floor.material.color.set(0xb24a32);

    this.box(0.55, 0.07, L, new THREE.MeshStandardMaterial({ color: 0x2a2c30, roughness: 0.55 }), 0, 0.035, L / 2);

    const tileH = 1.22;
    for (const side of [-1, 1]) {
      const x = side * (hw + 0.08);
      const tiles = this.box(0.16, tileH, L, this.mat(this.tex.blue, { repeat: [8, 2.2] }), x, tileH / 2, L / 2);
      tiles.userData.camCollide = true;
      const plaster = this.box(
        0.16,
        h - tileH,
        L,
        this.mat(this.tex.cPlaster, { repeat: [6, 1.2] }),
        x,
        tileH + (h - tileH) / 2,
        L / 2,
      );
      plaster.userData.camCollide = true;
    }

    this.box(hw * 2 + 0.4, 0.5, 0.2, this.mat(this.tex.cPlaster), 0, 1.4, 0.05);
    this.addCollider(-hw - 1, -0.55, -0.25, 0.22, 'start-l');
    this.addCollider(0.55, hw + 1, -0.25, 0.22, 'start-r');
    this.addBlockDoor();
  }

  addBlockDoor() {
    const steel = new THREE.MeshStandardMaterial({ color: 0x3a3e44, metalness: 0.65, roughness: 0.38 });
    const door = new THREE.Group();
    door.position.set(-0.52, 0, 0.02);
    this.group.add(door);
    const panel = new THREE.Mesh(new THREE.BoxGeometry(1.12, 2.15, 0.1), steel);
    panel.position.set(0.52, 1.08, 0);
    door.add(panel);
    const bar = new THREE.Mesh(
      new THREE.BoxGeometry(1.05, 0.08, 0.12),
      new THREE.MeshStandardMaterial({ color: 0x8a9096, metalness: 0.8, roughness: 0.3 }),
    );
    bar.position.set(0.52, 1.05, 0.04);
    door.add(bar);
    const sign = makeDoorNumber('СБ');
    sign.position.set(0.52, 1.72, 0.06);
    door.add(sign);
    this.addCollider(-0.55, 0.55, -0.16, 0.18, 'block-door');
    this.blockDoor = {
      id: 'block-door',
      type: 'block-door',
      position: new THREE.Vector3(0, 1, 0),
      radius: 1.8,
      door,
      hinge: door,
      open: false,
      side: 1,
      colliderId: 'block-door',
    };
    this.interactables.push(this.blockDoor);
  }

  openKpp() {
    openKppGate(this);
  }

  addVault() {
    const L = LAYOUT.corridorLen;
    const r = LAYOUT.vaultR;
    const geo = new THREE.CylinderGeometry(r, r, L, 14, 1, true, Math.PI * 0.04, Math.PI * 0.92);
    geo.rotateZ(Math.PI / 2);
    geo.rotateY(Math.PI / 2);
    const vault = new THREE.Mesh(geo, this.mat(this.tex.ceil, { roughness: 0.92, repeat: [L / 2.2, 2.4] }));
    vault.position.set(0, LAYOUT.wallH - 0.15, L / 2);
    vault.userData.camCollide = true;
    this.group.add(vault);

    const diamonds = this.box(LAYOUT.corridorHalf * 2 - 0.1, 0.02, L, this.mat(this.tex.diamond, { roughness: 0.7 }), 0, LAYOUT.wallH + 0.55, L / 2);
    diamonds.material.color.set(0xd8e4ee);
  }

  addCellDoors() {
    const numbers = [4, 5, 13, 14, 16, 17, 21, 22];
    const z0 = 3.4;
    const step = 3.55;
    let n = 0;
    for (const side of [1, -1]) {
      for (let i = 0; i < 4; i++) {
        const z = z0 + i * step;
        const num = numbers[n++];
        const isPlayer = num === 4;
        this.makeGreenDoor(side, z, num, isPlayer);
      }
    }
  }

  makeGreenDoor(side, z, num, isPlayer) {
    const hw = LAYOUT.corridorHalf;
    const hingeZ = z - LAYOUT.doorW / 2;
    const x = side * hw;
    const door = new THREE.Group();
    door.position.set(x, 0, hingeZ);
    this.group.add(door);

    const green = this.mat(this.tex.green, { roughness: 0.55, metalness: 0.25 });
    green.color.set(0x1f8c3c);
    const panel = new THREE.Mesh(new THREE.BoxGeometry(0.14, LAYOUT.doorH, LAYOUT.doorW), green);
    panel.position.set(0, LAYOUT.doorH / 2, LAYOUT.doorW / 2);
    panel.castShadow = true;
    panel.userData.camCollide = true;
    door.add(panel);

    const frame = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, LAYOUT.doorH + 0.1, LAYOUT.doorW + 0.12),
      new THREE.MeshStandardMaterial({ color: 0x146b2c, roughness: 0.6, metalness: 0.2 }),
    );
    frame.position.set(side * -0.04, LAYOUT.doorH / 2, LAYOUT.doorW / 2);
    door.add(frame);

    this.box(
      0.1,
      0.28,
      LAYOUT.doorW + 0.16,
      new THREE.MeshStandardMaterial({ color: 0x157a32, roughness: 0.55 }),
      0,
      0.14,
      LAYOUT.doorW / 2,
      door,
    );

    const hatch = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.16, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x0f5a24, metalness: 0.3, roughness: 0.45 }),
    );
    hatch.position.set(side * 0.05, 1.52, LAYOUT.doorW / 2);
    door.add(hatch);

    const lock = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.22, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x6a6e72, metalness: 0.7, roughness: 0.35 }),
    );
    lock.position.set(side * 0.06, 1.05, LAYOUT.doorW - 0.18);
    door.add(lock);

    const numPlane = makeDoorNumber(num);
    numPlane.position.set(side * -0.045, 1.72, LAYOUT.doorW * 0.62);
    numPlane.rotation.y = side > 0 ? -Math.PI / 2 : Math.PI / 2;
    door.add(numPlane);

    const cid = `door-${num}`;
    const thick = 0.2;
    const minx = side > 0 ? hw - 0.08 : -hw - thick;
    const maxx = side > 0 ? hw + thick : -hw + 0.08;
    this.addCollider(minx, maxx, z - LAYOUT.doorW / 2, z + LAYOUT.doorW / 2, cid);

    const interact = {
      id: cid,
      type: isPlayer ? 'cell-door' : 'locked-door',
      position: new THREE.Vector3(x - side * 0.15, 1, z),
      radius: 2.6,
      num,
      door,
      open: false,
      hinge: door,
      side,
      colliderId: cid,
    };
    this.interactables.push(interact);
    this.doors.push(interact);
  }

  openDoor(item) {
    if (!item || item.open) return;
    item.open = true;
    const col = this.colliders.find((c) => c.id === item.colliderId);
    if (col) col.active = false;
    if (item.type === 'block-door') {
      item.hinge.rotation.y -= Math.PI / 2;
      return;
    }
    item.hinge.rotation.y += item.side > 0 ? -Math.PI / 2 : Math.PI / 2;
    item.hinge.position.x += item.side * 0.85;
  }

  addPlayerCell() {
    const ox = LAYOUT.corridorHalf + LAYOUT.cellW / 2 + 0.08;
    const oz = 5.2;
    const w = LAYOUT.cellW;
    const d = LAYOUT.cellD;
    const h = 3.05;
    const cell = new THREE.Group();
    cell.position.set(ox, 0, oz);
    this.group.add(cell);

    this.box(w, 0.05, d, this.mat(this.tex.broken, { roughness: 0.9, repeat: [2.4, 2.8] }), 0, 0.025, 0, cell);

    const wallMat = this.mat(this.tex.plaster, { repeat: [w / 1.3, h / 1.1] });
    this.box(w, h, 0.16, wallMat, 0, h / 2, d / 2, cell).userData.camCollide = true;
    this.box(w, h, 0.16, wallMat, 0, h / 2, -d / 2, cell).userData.camCollide = true;
    this.box(0.16, h, d, wallMat, w / 2, h / 2, 0, cell).userData.camCollide = true;
    const doorRelZ = 3.4 - oz;
    const gap = LAYOUT.doorW / 2 + 0.08;
    const zA = -d / 2;
    const zB = doorRelZ - gap;
    const zC = doorRelZ + gap;
    const zD = d / 2;
    const len1 = zB - zA;
    const len2 = zD - zC;
    if (len1 > 0.2) this.box(0.16, h, len1, wallMat, -w / 2, h / 2, zA + len1 / 2, cell).userData.camCollide = true;
    if (len2 > 0.2) this.box(0.16, h, len2, wallMat, -w / 2, h / 2, zC + len2 / 2, cell).userData.camCollide = true;
    this.box(0.16, h - LAYOUT.doorH, LAYOUT.doorW + 0.2, wallMat, -w / 2, LAYOUT.doorH + (h - LAYOUT.doorH) / 2, doorRelZ, cell);
    const jamb = new THREE.MeshStandardMaterial({ color: 0x1f8c3c, roughness: 0.5, metalness: 0.2 });
    this.box(0.12, LAYOUT.doorH, 0.1, jamb, -w / 2 + 0.04, LAYOUT.doorH / 2, doorRelZ - LAYOUT.doorW / 2, cell);
    this.box(0.12, LAYOUT.doorH, 0.1, jamb, -w / 2 + 0.04, LAYOUT.doorH / 2, doorRelZ + LAYOUT.doorW / 2, cell);

    const teal = this.mat(this.tex.white, { repeat: [w / 0.16, 1] });
    teal.color.set(0x8ecfc4);
    this.box(w - 0.2, 0.16, 0.04, teal, 0, 1.22, d / 2 - 0.1, cell);
    this.box(w - 0.2, 0.16, 0.04, teal, 0, 1.22, -d / 2 + 0.1, cell);
    this.box(0.04, 0.16, d - 0.2, teal, w / 2 - 0.1, 1.22, 0, cell);

    const white = this.mat(this.tex.white, { roughness: 0.7, repeat: [w / 0.2, 1.12 / 0.2] });
    this.box(w - 0.25, 1.12, 0.05, white, 0, 0.58, d / 2 - 0.1, cell);
    this.box(0.05, 1.12, d - 0.25, white, w / 2 - 0.1, 0.58, 0, cell);

    const brick = this.mat(this.tex.brick);
    this.box(1.8, 1.4, 0.05, brick, -1.6, 2.15, d / 2 - 0.12, cell);

    const blue = this.mat(this.tex.occupied);
    this.box(2.6, 1.15, 0.04, blue, 1.4, 1.55, -d / 2 + 0.12, cell);

    this.box(w, 0.08, d, this.mat(this.tex.ceil), 0, h, 0, cell);

    this.addWindows(cell, w, d, h);
    this.addBunks(cell);
    this.addWashCorner(cell, w, d);
    this.addTable(cell);
    this.addCat(cell);
    this.addCellLamp(cell, 0, h - 0.12, 0);

    this.addCollider(ox + w / 2 - 0.18, ox + w / 2 + 0.3, oz - d / 2, oz + d / 2, 'cell-back');
    this.addCollider(ox - w / 2, ox + w / 2, oz + d / 2 - 0.18, oz + d / 2 + 0.25, 'cell-z+');
    this.addCollider(ox - w / 2, ox + w / 2, oz - d / 2 - 0.25, oz - d / 2 + 0.18, 'cell-z-');
    const doorGap = LAYOUT.doorW / 2 + 0.28;
    this.addCollider(ox - w / 2 - 0.12, ox - w / 2 + 0.16, oz - d / 2, 3.4 - doorGap, 'cell-inner-a');
    this.addCollider(ox - w / 2 - 0.12, ox - w / 2 + 0.16, 3.4 + doorGap, oz + d / 2, 'cell-inner-b');

    this.cellOrigin = new THREE.Vector3(ox, 0, oz);
    this.cellSpawn = new THREE.Vector3(ox - w / 2 + 1.15, 0, 3.55);
    this.doorThreshold = new THREE.Vector3(LAYOUT.corridorHalf + 0.35, 0, 3.4);
    this.playerSpawn = new THREE.Vector3(0, 0, -82.35);

    const rag = new THREE.Mesh(
      new THREE.BoxGeometry(0.55, 0.03, 0.38),
      new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.95 }),
    );
    rag.position.set(ox - w / 2 + 0.55, 0.04, 3.42);
    rag.name = 'Rag';
    this.group.add(rag);
    this.ragMesh = rag;
    this.interactables.push({
      id: 'rag',
      type: 'rag',
      position: rag.position.clone(),
      radius: 1.4,
    });
    this.interactables.push({
      id: 'starosta',
      type: 'starosta',
      position: new THREE.Vector3(ox + 0.3, 1, oz + 0.4),
      radius: 1.8,
    });
    this.interactables.push({
      id: 'bunk',
      type: 'bunk',
      own: true,
      position: new THREE.Vector3(ox + 1.85, 1, oz - 2.35),
      radius: 1.6,
    });
    this.interactables.push({
      id: 'bunk-other',
      type: 'bunk-other',
      position: new THREE.Vector3(ox + 1.85, 1, oz + 2.15),
      radius: 1.4,
    });
    this.interactables.push({
      id: 'wash',
      type: 'wash',
      position: new THREE.Vector3(ox + 2.2, 1, oz + 2.4),
      radius: 1.5,
    });
    this.interactables.push({
      id: 'cards',
      type: 'cards',
      position: new THREE.Vector3(ox + 0.2, 1, oz + 0.2),
      radius: 1.5,
    });
    this.interactables.push({
      id: 'malyava',
      type: 'malyava',
      position: new THREE.Vector3(ox - 1.8, 1, oz + 2.4),
      radius: 1.4,
    });
    this.interactables.push({
      id: 'obshak',
      type: 'obshak',
      position: new THREE.Vector3(ox + 1.4, 1, oz + 0.2),
      radius: 1.3,
    });
    this.interactables.push({
      id: 'food',
      type: 'food',
      position: new THREE.Vector3(ox - w / 2 + 0.8, 1, oz),
      radius: 1.5,
    });
  }

  addWindows(cell, w, d, h) {
    for (const x of [-1.35, 1.35]) {
      const frame = this.box(1.15, 1.35, 0.1, new THREE.MeshStandardMaterial({ color: 0x3a342c }), x, 2.15, d / 2 - 0.08, cell);
      const glass = this.box(0.95, 1.15, 0.02, new THREE.MeshStandardMaterial({ color: 0xb7c8d4, emissive: 0x8aa, emissiveIntensity: 0.35, roughness: 0.2 }), x, 2.15, d / 2 - 0.02, cell);
      const bars = new THREE.MeshStandardMaterial({ color: 0x2a2a2c, metalness: 0.7, roughness: 0.35 });
      for (let i = -3; i <= 3; i++) {
        this.box(0.03, 1.15, 0.03, bars, x + i * 0.13, 2.15, d / 2 - 0.01, cell);
      }
      for (let j = -2; j <= 2; j++) {
        this.box(0.95, 0.025, 0.025, bars, x, 2.15 + j * 0.22, d / 2 - 0.01, cell);
      }
    }
  }

  addBunks(cell) {
    const spots = [
      [1.85, -2.35, 0],
      [1.85, 2.15, 0],
      [-0.15, 2.35, Math.PI / 2],
    ];
    for (const [x, z, rot] of spots) {
      const bunk = this.makeBunk();
      bunk.position.set(x, 0, z);
      bunk.rotation.y = rot;
      cell.add(bunk);
    }
  }

  makeBunk() {
    const g = new THREE.Group();
    const rust = new THREE.MeshStandardMaterial({ color: 0x7a2c22, metalness: 0.45, roughness: 0.55 });
    const rustDark = new THREE.MeshStandardMaterial({ color: 0x4a241c, metalness: 0.4, roughness: 0.6 });
    const post = new THREE.CylinderGeometry(0.03, 0.03, 1.42, 6);
    for (const [x, z] of [
      [-0.95, -0.38],
      [0.95, -0.38],
      [-0.95, 0.38],
      [0.95, 0.38],
    ]) {
      const p = new THREE.Mesh(post, rust);
      p.position.set(x, 0.71, z);
      g.add(p);
    }
    for (const y of [0.42, 1.18]) {
      const frame = new THREE.Mesh(new THREE.BoxGeometry(1.96, 0.05, 0.82), rustDark);
      frame.position.y = y;
      g.add(frame);
      const deck = new THREE.Mesh(
        new THREE.PlaneGeometry(1.88, 0.74),
        new THREE.MeshStandardMaterial({ map: this.tex.lattice, roughness: 0.7, metalness: 0.35 }),
      );
      deck.rotation.x = -Math.PI / 2;
      deck.position.y = y + 0.03;
      g.add(deck);
    }
    const mattress = new THREE.Mesh(
      new THREE.BoxGeometry(1.7, 0.08, 0.7),
      new THREE.MeshStandardMaterial({ color: 0xc5c0b4, roughness: 0.95 }),
    );
    mattress.position.set(0.04, 1.26, 0);
    mattress.rotation.z = 0.04;
    g.add(mattress);
    return g;
  }

  addWashCorner(cell, w, d) {
    const g = new THREE.Group();
    g.position.set(2.35, 0, 2.55);
    cell.add(g);
    const tile = this.mat(this.tex.white, { roughness: 0.55 });
    this.box(1.5, 1.15, 0.08, tile, 0, 0.58, 0.55, g);
    this.box(0.08, 1.15, 1.2, tile, 0.72, 0.58, 0, g);
    this.box(1.15, 1.05, 0.08, tile, -0.1, 0.52, -0.15, g);

    const stallTop = this.box(1.15, 0.05, 0.7, tile, -0.1, 1.08, 0.15, g);

    const sink = new THREE.Mesh(
      new THREE.CylinderGeometry(0.18, 0.16, 0.08, 12),
      new THREE.MeshStandardMaterial({ color: 0xf2f0ea, roughness: 0.35 }),
    );
    sink.position.set(-0.35, 0.95, 0.42);
    g.add(sink);
    const tap = new THREE.Mesh(
      new THREE.CylinderGeometry(0.015, 0.015, 0.16, 6),
      new THREE.MeshStandardMaterial({ color: 0x9aa0a6, metalness: 0.8, roughness: 0.3 }),
    );
    tap.position.set(-0.35, 1.08, 0.5);
    g.add(tap);

    const platform = this.box(0.7, 0.08, 0.85, this.mat(this.tex.white), 0.15, 0.06, -0.15, g);
    const pan = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.1, 0.42),
      new THREE.MeshStandardMaterial({ color: 0xe8e4dc, roughness: 0.4 }),
    );
    pan.position.set(0.15, 0.12, -0.18);
    g.add(pan);
    const hole = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.1, 0.12, 10),
      new THREE.MeshStandardMaterial({ color: 0x1a1510 }),
    );
    hole.position.set(0.15, 0.12, -0.18);
    g.add(hole);

    const hose = new THREE.Mesh(
      new THREE.TubeGeometry(new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.2, 1.35, 0.45),
        new THREE.Vector3(-0.05, 1.1, 0.1),
        new THREE.Vector3(0.12, 0.55, -0.05),
      ]), 12, 0.018, 5, false),
      new THREE.MeshStandardMaterial({ color: 0x8a8f86, roughness: 0.5 }),
    );
    g.add(hose);
    const head = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.04, 0.08, 8),
      new THREE.MeshStandardMaterial({ color: 0xc0c4c8, metalness: 0.7, roughness: 0.3 }),
    );
    head.position.set(0.12, 0.52, -0.05);
    head.rotation.x = 0.6;
    g.add(head);

    const wire = new THREE.Mesh(
      new THREE.TubeGeometry(new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.6, 2.4, 0.2),
        new THREE.Vector3(-0.4, 1.7, 0.3),
        new THREE.Vector3(-0.5, 1.1, 0.45),
      ]), 8, 0.012, 4, false),
      new THREE.MeshStandardMaterial({ color: 0x1a1a1a }),
    );
    g.add(wire);
  }

  addTable(cell) {
    const wood = new THREE.MeshStandardMaterial({ color: 0xc8b48a, roughness: 0.8 });
    this.box(1.3, 0.05, 0.55, wood, 0.2, 0.72, 0.2, cell);
    this.box(1.1, 0.04, 0.28, wood, 0.2, 0.38, 0.85, cell);
    const kettle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.07, 0.09, 0.16, 12),
      new THREE.MeshStandardMaterial({ color: 0x7a7a72, metalness: 0.55, roughness: 0.35 }),
    );
    kettle.position.set(-0.15, 0.84, 0.15);
    cell.add(kettle);
    const lid = new THREE.Mesh(
      new THREE.SphereGeometry(0.055, 10, 6),
      new THREE.MeshStandardMaterial({ color: 0x5a5a54, metalness: 0.5 }),
    );
    lid.position.set(-0.15, 0.94, 0.15);
    const paper = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.01, 0.2),
      new THREE.MeshStandardMaterial({ color: 0xe8e0cc, roughness: 0.9 }),
    );
    paper.position.set(0.35, 0.76, 0.12);
    paper.rotation.y = 0.3;
    cell.add(paper);
    const pack = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.03, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x6a1020, roughness: 0.6 }),
    );
    pack.position.set(0.55, 0.76, 0.28);
    cell.add(pack);
    const cal = cellSign('ХАТА 4');
    cal.position.set(-2.2, 1.85, 0.2);
    cal.rotation.y = Math.PI / 2;
    cell.add(cal);
    cell.add(lid);
    const mug = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.035, 0.07, 10),
      new THREE.MeshStandardMaterial({ color: 0xc4b49a, roughness: 0.6 }),
    );
    mug.position.set(0.15, 0.78, 0.05);
    cell.add(mug);
    const photo = new THREE.Mesh(
      new THREE.PlaneGeometry(0.28, 0.36),
      new THREE.MeshStandardMaterial({ color: 0xd8c8a8, roughness: 0.7 }),
    );
    photo.position.set(1.2, 1.7, -LAYOUT.cellD / 2 + 0.1);
    cell.add(photo);
    const lamp = new THREE.PointLight(0xffd7a0, 0.55, 6, 2);
    lamp.position.set(0.2, 1.6, 0.2);
    cell.add(lamp);
  }

  addCat(cell) {
    const fur = new THREE.MeshStandardMaterial({ color: 0x6a675f, roughness: 0.9 });
    const body = new THREE.Mesh(new THREE.SphereGeometry(0.09, 8, 6), fur);
    body.scale.set(1.3, 0.7, 0.9);
    body.position.set(2.4, 0.1, -2.6);
    cell.add(body);
    const head = new THREE.Mesh(new THREE.SphereGeometry(0.055, 8, 6), fur);
    head.position.set(2.52, 0.16, -2.6);
    cell.add(head);
  }

  addCellLamp(parent, x, y, z) {
    const housing = new THREE.Mesh(
      new THREE.BoxGeometry(0.9, 0.06, 0.12),
      new THREE.MeshStandardMaterial({ color: 0x3a3a3c, metalness: 0.5, roughness: 0.4 }),
    );
    housing.position.set(x, y, z);
    parent.add(housing);
    const mat = createFlickerMaterial(this.flickerMats.length + 2);
    this.flickerMats.push(mat);
    const tube = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.82, 8), mat);
    tube.rotation.z = Math.PI / 2;
    tube.position.set(x, y - 0.04, z);
    parent.add(tube);
  }

  addOppositeCells() {
    const ozs = [8.8, 12.4, 16.0];
    for (const oz of ozs) {
      const ox = -LAYOUT.corridorHalf - 2.2;
      const g = new THREE.Group();
      g.position.set(ox, 0, oz);
      this.group.add(g);
      this.box(4.2, 0.05, 3.4, this.mat(this.tex.broken), 0, 0.02, 0, g);
      this.box(4.2, 2.8, 0.12, this.mat(this.tex.plaster), 0, 1.4, 1.7, g);
      this.box(0.12, 2.8, 3.4, this.mat(this.tex.plaster), -2.1, 1.4, 0, g);
      const bunk = this.makeBunk();
      bunk.scale.setScalar(0.85);
      bunk.position.set(0.2, 0, 0);
      g.add(bunk);
    }
  }

  addDutyRoom() {
    const z = 24.5;
    const x = LAYOUT.corridorHalf + 2.4;
    const g = new THREE.Group();
    g.position.set(x, 0, z);
    this.group.add(g);
    this.box(4.6, 0.05, 4.2, this.mat(this.tex.red, { roughness: 0.3 }), 0, 0.025, 0, g);
    this.box(4.6, 2.7, 0.14, this.mat(this.tex.cPlaster), 0, 1.35, 2.1, g);
    this.box(0.14, 2.7, 4.2, this.mat(this.tex.cPlaster), 2.3, 1.35, 0, g);

    const desk = this.box(1.6, 0.08, 0.7, new THREE.MeshStandardMaterial({ color: 0x5a4030 }), 0.4, 0.78, 0.2, g);
    this.dutyAnchor = new THREE.Vector3(x, 1.4, z);

    this.interactables.push({
      id: 'duty-door',
      type: 'locked-door',
      position: new THREE.Vector3(LAYOUT.corridorHalf + 0.4, 1, z),
      radius: 1.2,
      num: 'Д',
    });
    this.interactables.push({
      id: 'admin',
      type: 'admin',
      position: new THREE.Vector3(0.2, 1, z),
      radius: 1.8,
    });

    this.makeGreenDoor(1, z, 9, false);
  }

  addYard() {
    const z0 = LAYOUT.corridorLen;
    const g = new THREE.Group();
    g.position.set(0, 0, z0 + 4.5);
    this.group.add(g);

    const ground = this.box(9, 0.08, 9, new THREE.MeshStandardMaterial({ color: 0x6a6e66, roughness: 0.95 }), 0, -0.02, 0, g);
    for (const [x, z] of [
      [0, 4.4],
      [0, -4.4],
      [4.4, 0],
      [-4.4, 0],
    ]) {
      const wall = this.box(x === 0 ? 9 : 0.28, 3.4, z === 0 ? 9 : 0.28, new THREE.MeshStandardMaterial({ color: 0xcfc8b8, roughness: 0.9 }), x, 1.7, z, g);
    }

    const skyLight = new THREE.Mesh(
      new THREE.PlaneGeometry(8, 8),
      new THREE.MeshBasicMaterial({ color: 0x8aa6b8, side: THREE.DoubleSide }),
    );
    skyLight.rotation.x = Math.PI / 2;
    skyLight.position.y = 3.5;
    g.add(skyLight);

    const gate = new THREE.Mesh(
      new THREE.BoxGeometry(1.4, 2.2, 0.1),
      new THREE.MeshStandardMaterial({ color: 0x4a4e46, metalness: 0.5, roughness: 0.4 }),
    );
    gate.position.set(0, 1.1, -4.35);
    g.add(gate);

    this.interactables.push({
      id: 'exit-yard',
      type: 'exit',
      position: new THREE.Vector3(0, 1, z0 - 0.6),
      radius: 1.6,
    });

    const sign = makeDoorNumber('ДВОР');
    sign.position.set(0, 2.5, z0 - 0.2);
    this.group.add(sign);

    this.addCollider(-5, 5, z0 + 8.8, z0 + 10, 'yard-end');
    this.addCollider(-5.2, -4.1, z0, z0 + 9, 'yard-l');
    this.addCollider(4.1, 5.2, z0, z0 + 9, 'yard-r');
  }

  addPipesAndProps() {
    const pipeMat = new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.65, roughness: 0.35 });
    const pipe = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.045, LAYOUT.corridorLen - 2, 8), pipeMat);
    pipe.rotation.x = Math.PI / 2;
    pipe.position.set(-LAYOUT.corridorHalf + 0.22, 2.35, LAYOUT.corridorLen / 2);
    this.group.add(pipe);

    const pipe2 = pipe.clone();
    pipe2.position.y = 2.18;
    pipe2.position.x = -LAYOUT.corridorHalf + 0.32;
    this.group.add(pipe2);

    const extinguisher = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.09, 0.42, 8),
      new THREE.MeshStandardMaterial({ color: 0xc01818, roughness: 0.5 }),
    );
    extinguisher.position.set(LAYOUT.corridorHalf - 0.22, 1.15, 18.5);
    this.group.add(extinguisher);

    const box = this.box(0.18, 0.28, 0.08, new THREE.MeshStandardMaterial({ color: 0x4a5560, metalness: 0.4 }), LAYOUT.corridorHalf - 0.18, 1.55, 10.2);
  }

  addLamps() {
    for (let z = 2.5; z < LAYOUT.corridorLen; z += 4.2) {
      const housing = new THREE.Mesh(
        new THREE.BoxGeometry(0.22, 0.08, 0.7),
        new THREE.MeshStandardMaterial({ color: 0x3e4044, metalness: 0.4, roughness: 0.45 }),
      );
      housing.position.set(0, 2.72, z);
      this.group.add(housing);
      const mat = createFlickerMaterial(this.flickerMats.length);
      this.flickerMats.push(mat);
      const tube = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, 0.58, 8), mat);
      tube.rotation.x = Math.PI / 2;
      tube.position.set(0, 2.66, z);
      this.group.add(tube);
    }
  }

  addCctvBodies() {
    const spots = [
      { pos: [0, 2.55, 7.5], look: [0, 1.2, 14] },
      { pos: [0.4, 2.55, 19], look: [0, 1.2, 26] },
      { pos: [-0.2, 2.55, 31], look: [0, 1.2, 36] },
    ];
    spots.forEach((s, i) => {
      const cam = new THREE.Group();
      cam.position.set(...s.pos);
      this.group.add(cam);
      const body = new THREE.Mesh(
        new THREE.BoxGeometry(0.16, 0.1, 0.22),
        new THREE.MeshStandardMaterial({ color: 0x1c1c1e, metalness: 0.5, roughness: 0.4 }),
      );
      cam.add(body);
      const lens = new THREE.Mesh(
        new THREE.CylinderGeometry(0.04, 0.04, 0.06, 10),
        new THREE.MeshStandardMaterial({ color: 0x111, metalness: 0.8 }),
      );
      lens.rotation.x = Math.PI / 2;
      lens.position.z = 0.12;
      cam.add(lens);
      cam.lookAt(s.look[0], s.look[1], s.look[2]);
      this.cameras.push({
        id: `CAM-0${i + 1}`,
        position: new THREE.Vector3(...s.pos),
        lookAt: new THREE.Vector3(...s.look),
        range: 9.5,
        angle: 0.42,
      });
    });
  }

  addIntake() {
    buildArrival(this);
  }

  addBoundaryColliders() {
    const hw = LAYOUT.corridorHalf;
    const L = LAYOUT.corridorLen;
    const half = LAYOUT.doorW / 2 + 0.06;
    for (const [a, b] of wallSegments(0, L, [3.4, 6.95, 10.5, 14.05, 24.5], half)) {
      this.addCollider(hw - 0.06, hw + 0.16, a, b, `cwall+-${a}`);
    }
    for (const [a, b] of wallSegments(0, L, [3.4, 6.95, 10.5, 14.05], half)) {
      this.addCollider(-hw - 0.16, -hw + 0.06, a, b, `cwall--${a}`);
    }
    this.addCollider(hw + 0.14, 12, 9.1, L, 'posx-after-cell');
    this.addCollider(-12, -hw - 0.14, 0, 3.0, 'negx-start');
    this.addCollider(-12, -hw - 0.14, 18, L, 'negx-end');
  }

  resolve(pos, radius) {
    const p = pos.clone();
    for (const c of this.colliders) {
      if (!c.active) continue;
      const nearestX = Math.max(c.minx, Math.min(p.x, c.maxx));
      const nearestZ = Math.max(c.minz, Math.min(p.z, c.maxz));
      const dx = p.x - nearestX;
      const dz = p.z - nearestZ;
      const d2 = dx * dx + dz * dz;
      if (d2 < radius * radius) {
        const d = Math.sqrt(d2) || 0.0001;
        const push = (radius - d) / d;
        p.x += dx * push;
        p.z += dz * push;
      }
    }
    return p;
  }

  nearestInteractable(pos) {
    let best = null;
    let bestD = Infinity;
    for (const it of this.interactables) {
      const d = Math.hypot(pos.x - it.position.x, pos.z - it.position.z);
      if (d < it.radius && d < bestD) {
        best = it;
        bestD = d;
      }
    }
    return best;
  }
}

function cellSign(text) {
  const c = document.createElement('canvas');
  c.width = 256;
  c.height = 128;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#3a2a18';
  ctx.fillRect(0, 0, 256, 128);
  ctx.strokeStyle = '#d4b070';
  ctx.strokeRect(6, 6, 244, 116);
  ctx.fillStyle = '#f0e0c0';
  ctx.font = '700 42px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 128, 64);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return new THREE.Mesh(new THREE.PlaneGeometry(0.7, 0.35), new THREE.MeshBasicMaterial({ map: tex }));
}

function wallSegments(start, end, gaps, half) {
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

function makeDoorNumber(text) {
  const c = document.createElement('canvas');
  c.width = 128;
  c.height = 96;
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, 128, 96);
  ctx.fillStyle = '#f4f4f0';
  ctx.font = 'bold 64px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(String(text), 64, 50);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.MeshBasicMaterial({ map: tex, transparent: true });
  return new THREE.Mesh(new THREE.PlaneGeometry(0.28, 0.22), mat);
}
