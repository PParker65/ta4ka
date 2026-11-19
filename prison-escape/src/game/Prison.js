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
  windowViewTex,
  createFlickerMaterial,
} from '../shaders/environment.js';
import { buildArrival, openKppGate, tickKppGate } from './Exterior.js';

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
      windowView: windowViewTex(),
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
    let bump = null;
    if (map.userData?.bump) {
      bump = map.userData.bump.clone();
      bump.wrapS = bump.wrapT = THREE.RepeatWrapping;
      if (opts.repeat) bump.repeat.set(opts.repeat[0], opts.repeat[1]);
    }
    return new THREE.MeshStandardMaterial({
      map: tex,
      bumpMap: bump,
      bumpScale: bump ? (opts.bump ?? 0.035) : 0,
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
    floor.material.roughness = 0.42;
    floor.material.metalness = 0.12;

    this.box(0.55, 0.07, L, new THREE.MeshStandardMaterial({ color: 0x2a2c30, roughness: 0.55 }), 0, 0.035, L / 2);

    const tileH = 1.22;
    const doorHalf = LAYOUT.doorW / 2 + 0.12;
    const rightDoors = [3.4, 6.95, 10.5, 14.05, 24.5];
    const leftDoors = [3.4, 6.95, 10.5, 14.05];
    const tileMat = this.mat(this.tex.blue, { repeat: [8, 2.2], bump: 0.02 });
    const plasMat = this.mat(this.tex.cPlaster, { repeat: [6, 1.2], bump: 0.02 });
    tileMat.polygonOffset = true;
    tileMat.polygonOffsetFactor = 1;
    tileMat.polygonOffsetUnits = 1;
    for (const [side, doors] of [
      [1, rightDoors],
      [-1, leftDoors],
    ]) {
      const x = side * (hw + 0.08);
      for (const [a, b] of wallSegments(0, L, doors, doorHalf)) {
        const len = b - a;
        if (len < 0.12) continue;
        const z = (a + b) / 2;
        this.box(0.16, tileH, len, tileMat, x, tileH / 2, z).userData.camCollide = true;
        this.box(0.16, h - tileH, len, plasMat, x, tileH + (h - tileH) / 2, z).userData.camCollide = true;
      }
    }

    this.box(hw * 2 + 0.4, 0.28, 0.2, this.mat(this.tex.cPlaster), 0, 2.28, 0.05);
    this.box(hw * 2 + 0.5, 0.1, L, this.mat(this.tex.cPlaster, { repeat: [2, 8] }), 0, h + 0.12, L / 2);
    this.addCollider(-hw - 1, -0.55, -0.25, 0.22, 'start-l');
    this.addCollider(0.55, hw + 1, -0.25, 0.22, 'start-r');
    this.addBlockDoor();

    const endDoor = 1.28;
    const endWing = (hw * 2 - endDoor) / 2 + 0.2;
    const endX = hw + 0.08 - endWing / 2;
    const plas = this.mat(this.tex.cPlaster, { repeat: [1.2, 1.2] });
    this.box(endWing, h, 0.22, plas, -endX, h / 2, L - 0.06).userData.camCollide = true;
    this.box(endWing, h, 0.22, plas, endX, h / 2, L - 0.06).userData.camCollide = true;
    this.box(endDoor, 0.45, 0.22, plas, 0, h - 0.2, L - 0.06);
    this.box(0.1, 2.2, 0.22, plas, -endDoor / 2, 1.1, L - 0.06);
    this.box(0.1, 2.2, 0.22, plas, endDoor / 2, 1.1, L - 0.06);
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

  tickArrival(dt) {
    tickKppGate(this, dt);
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

    if (!isPlayer) {
      const hatch = new THREE.Mesh(
        new THREE.BoxGeometry(0.04, 0.16, 0.22),
        new THREE.MeshStandardMaterial({ color: 0x0f5a24, metalness: 0.3, roughness: 0.45 }),
      );
      hatch.position.set(side * 0.05, 1.52, LAYOUT.doorW / 2);
      door.add(hatch);
    }
    if (isPlayer) {
      const dark = new THREE.MeshStandardMaterial({ color: 0x120e0a, roughness: 0.9 });
      const recess = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.24, 0.38), dark);
      recess.position.set(side * 0.09, 1.52, LAYOUT.doorW / 2);
      door.add(recess);
      const rim = new THREE.MeshStandardMaterial({ color: 0x4a4e52, metalness: 0.5, roughness: 0.4 });
      this.box(0.03, 0.28, 0.42, rim, side * 0.13, 1.52, LAYOUT.doorW / 2, door);
      this.box(0.03, 0.03, 0.42, rim, side * 0.13, 1.66, LAYOUT.doorW / 2, door);
      this.box(0.03, 0.03, 0.42, rim, side * 0.13, 1.38, LAYOUT.doorW / 2, door);
      const flap = new THREE.Mesh(new THREE.BoxGeometry(0.02, 0.2, 0.34), rim);
      flap.position.set(side * 0.15, 1.63, LAYOUT.doorW / 2);
      door.add(flap);
      this.hatchFlap = flap;
      const anchor = new THREE.Object3D();
      anchor.position.set(side * 0.2, 1.52, LAYOUT.doorW / 2);
      door.add(anchor);
      this.hatchAnchor = anchor;
      const judas = new THREE.MeshStandardMaterial({ color: 0x3a3e42, metalness: 0.65, roughness: 0.35 });
      this.box(0.04, 0.09, 0.09, judas, side * 0.09, 1.82, LAYOUT.doorW / 2, door);
      const hole = new THREE.Mesh(
        new THREE.CircleGeometry(0.028, 10),
        new THREE.MeshStandardMaterial({ color: 0x0a0a0c, roughness: 0.5 }),
      );
      hole.rotation.y = side > 0 ? Math.PI / 2 : -Math.PI / 2;
      hole.position.set(side * 0.12, 1.82, LAYOUT.doorW / 2);
      door.add(hole);
      const eye = new THREE.Mesh(
        new THREE.SphereGeometry(0.022, 8, 6),
        new THREE.MeshStandardMaterial({ color: 0x3a2418, roughness: 0.7 }),
      );
      eye.position.set(side * 0.11, 1.82, LAYOUT.doorW / 2);
      eye.visible = false;
      door.add(eye);
      this.judasEye = eye;
    }

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

  closeDoor(item) {
    if (!item || !item.open || !item.hinge) return;
    item.open = false;
    const col = this.colliders.find((c) => c.id === item.colliderId);
    if (col) col.active = true;
    item.hinge.rotation.y -= item.side > 0 ? -Math.PI / 2 : Math.PI / 2;
    item.hinge.position.x -= item.side * 0.85;
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

    const wallMat = this.mat(this.tex.plaster, { repeat: [w / 1.3, h / 1.1], bump: 0.02 });
    wallMat.polygonOffset = true;
    wallMat.polygonOffsetFactor = 1;
    wallMat.polygonOffsetUnits = 1;
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
    const innerX = -w / 2 + 0.14;
    if (len1 > 0.2) this.box(0.16, h, len1, wallMat, innerX, h / 2, zA + len1 / 2, cell).userData.camCollide = true;
    if (len2 > 0.2) this.box(0.16, h, len2, wallMat, innerX, h / 2, zC + len2 / 2, cell).userData.camCollide = true;
    this.box(0.16, h - LAYOUT.doorH, LAYOUT.doorW + 0.2, wallMat, innerX, LAYOUT.doorH + (h - LAYOUT.doorH) / 2, doorRelZ, cell);
    const jamb = new THREE.MeshStandardMaterial({ color: 0x1f8c3c, roughness: 0.5, metalness: 0.2 });
    this.box(0.12, LAYOUT.doorH, 0.1, jamb, innerX + 0.04, LAYOUT.doorH / 2, doorRelZ - LAYOUT.doorW / 2, cell);
    this.box(0.12, LAYOUT.doorH, 0.1, jamb, innerX + 0.04, LAYOUT.doorH / 2, doorRelZ + LAYOUT.doorW / 2, cell);

    const teal = this.mat(this.tex.white, { repeat: [w / 0.16, 1] });
    teal.color.set(0x8ecfc4);
    this.box(w - 0.2, 0.16, 0.04, teal, 0, 1.22, d / 2 - 0.1, cell);
    this.box(w - 0.2, 0.16, 0.04, teal, 0, 1.22, -d / 2 + 0.1, cell);
    this.box(0.04, 0.16, d - 0.2, teal, w / 2 - 0.1, 1.22, 0, cell);

    const white = this.mat(this.tex.white, { roughness: 0.7, repeat: [w / 0.2, 1.12 / 0.2] });
    this.box(w - 0.25, 1.12, 0.05, white, 0, 0.58, d / 2 - 0.1, cell);
    this.box(0.05, 1.12, d - 0.25, white, w / 2 - 0.1, 0.58, 0, cell);

    const brick = this.mat(this.tex.brick);
    this.box(1.4, 0.85, 0.05, brick, 0, 1.55, d / 2 - 0.12, cell);

    const blue = this.mat(this.tex.occupied);
    this.box(2.6, 1.15, 0.04, blue, 1.4, 1.55, -d / 2 + 0.12, cell);

    this.box(w, 0.08, d, this.mat(this.tex.ceil), 0, h, 0, cell);

    this.addWindows(cell, w, d, h);
    this.addBunks(cell);
    this.addWashCorner(cell, w, d);
    this.addTable(cell);
    this.addLivedIn(cell);
    this.addCat(cell);
    this.addCellLamp(cell, 0, h - 0.12, 0);

    this.addCollider(ox + w / 2 - 0.18, ox + w / 2 + 0.3, oz - d / 2, oz + d / 2, 'cell-back');
    this.addCollider(ox - w / 2, ox + w / 2, oz + d / 2 - 0.18, oz + d / 2 + 0.25, 'cell-z+');
    this.addCollider(ox - w / 2, ox + w / 2, oz - d / 2 - 0.25, oz - d / 2 + 0.18, 'cell-z-');
    const doorGap = LAYOUT.doorW / 2 + 0.28;
    this.addCollider(ox - w / 2 - 0.12, ox - w / 2 + 0.16, oz - d / 2, 3.4 - doorGap, 'cell-inner-a');
    this.addCollider(ox - w / 2 - 0.12, ox - w / 2 + 0.16, 3.4 + doorGap, oz + d / 2, 'cell-inner-b');

    this.cellOrigin = new THREE.Vector3(ox, 0, oz);
    this.seats = makeSeats(ox, oz);
    this.cellSpawn = new THREE.Vector3(ox - w / 2 + 1.55, 0, oz - 0.35);
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
      position: new THREE.Vector3(ox - w / 2 + 0.55, 1.4, 3.42),
      radius: 3.2,
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
    this.interactables.push({
      id: 'window',
      type: 'window',
      position: new THREE.Vector3(ox, 1, oz + d / 2 - 0.45),
      radius: 1.7,
    });
    this.interactables.push({
      id: 'kettle',
      type: 'kettle',
      position: new THREE.Vector3(ox + 0.2, 1, oz + 0.2),
      radius: 1.35,
    });
    this.interactables.push({
      id: 'hatch',
      type: 'hatch',
      position: new THREE.Vector3(ox - w / 2 + 0.55, 1.4, 3.42),
      radius: 3.2,
    });
    const tray = new THREE.Group();
    tray.position.set(ox - w / 2 + 0.42, 0.92, 3.42);
    const tin = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.04, 0.18),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, metalness: 0.45, roughness: 0.4 }),
    );
    tray.add(tin);
    const mash = new THREE.Mesh(
      new THREE.SphereGeometry(0.06, 8, 6),
      new THREE.MeshStandardMaterial({ color: 0xb8a070, roughness: 0.9 }),
    );
    mash.scale.set(1.4, 0.4, 1.1);
    mash.position.y = 0.04;
    tray.add(mash);
    tray.visible = false;
    this.group.add(tray);
    this.foodTray = tray;
    this.interactables.push({
      id: 'calendar',
      type: 'calendar',
      position: new THREE.Vector3(ox - w / 2 + 0.35, 1, oz),
      radius: 1.3,
    });
    this.addStoryProps(ox, oz, w);
  }

  addStoryProps(ox, oz, w) {
    const paper = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.022, 0.18),
      new THREE.MeshStandardMaterial({
        color: 0xf2e6c4,
        roughness: 0.78,
        emissive: 0x5a4a18,
        emissiveIntensity: 0.55,
      }),
    );
    const fold = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.012, 0.16),
      new THREE.MeshStandardMaterial({ color: 0xd4c49a, roughness: 0.88 }),
    );
    fold.position.set(0.07, 0.01, 0);
    paper.add(fold);
    paper.visible = false;
    this.group.add(paper);
    this.storyNote = paper;
    const ash = new THREE.Mesh(
      new THREE.SphereGeometry(0.08, 8, 6),
      new THREE.MeshStandardMaterial({ color: 0x141410, roughness: 0.96 }),
    );
    ash.scale.set(2.1, 0.42, 1.6);
    ash.position.set(ox + 0.08, 0.79, oz + 0.16);
    ash.visible = false;
    this.group.add(ash);
    this.storyAsh = ash;
    const extra = new THREE.Mesh(
      new THREE.BoxGeometry(0.11, 0.045, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xc4a070, roughness: 0.88 }),
    );
    extra.position.set(ox - w / 2 + 0.55, 0.99, 3.42);
    extra.visible = false;
    this.group.add(extra);
    this.storyExtra = extra;
    const tea = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.04, 0.06),
      new THREE.MeshStandardMaterial({ color: 0x6a4a28, roughness: 0.78, emissive: 0x2a1808, emissiveIntensity: 0.2 }),
    );
    tea.visible = false;
    this.group.add(tea);
    this.storyTea = tea;
    const rummage = new THREE.Group();
    rummage.position.set(ox + 1.55, 0.06, oz - 1.55);
    rummage.visible = false;
    const rag = new THREE.MeshStandardMaterial({ color: 0x8a7a62, roughness: 0.94 });
    const ragA = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.03, 0.22), rag);
    ragA.rotation.y = 0.4;
    rummage.add(ragA);
    const ragB = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.025, 0.28),
      new THREE.MeshStandardMaterial({ color: 0x4a5a6a, roughness: 0.93 }),
    );
    ragB.position.set(0.18, 0.01, 0.12);
    ragB.rotation.y = -0.6;
    rummage.add(ragB);
    this.group.add(rummage);
    this.storyRummage = rummage;
    const found = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.012, 0.11),
      new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.86, emissive: 0x3a3010, emissiveIntensity: 0.25 }),
    );
    found.position.set(ox + 1.42, 0.08, oz - 1.72);
    found.rotation.set(0, 0.7, 0.08);
    found.visible = false;
    this.group.add(found);
    this.storyFound = found;
    this._storyAnchors = {
      hatch: new THREE.Vector3(ox - w / 2 + 0.62, 1.52, 3.42),
      wash: new THREE.Vector3(ox + 2.25, 1.1, oz + 2.7),
      bunk: new THREE.Vector3(ox + 1.52, 0.58, oz - 2.12),
    };
  }

  syncStoryProps(sim) {
    if (!this.storyNote || !sim) return;
    const a = this._storyAnchors;
    const waiting = sim.day >= 3 && !sim.malyava;
    const hold = sim.malyava === 'hold';
    const teaDue = sim.day >= 4 && hold && !sim.teaPaid;
    const searching = sim.stage === 'life' && sim.phase?.id === 'shmon';
    if (this.hatchFlap) this.hatchFlap.rotation.z = waiting || teaDue ? -0.7 : 0;
    if (waiting) {
      this.storyNote.visible = true;
      this.storyNote.scale.set(1.55, 1.55, 1.55);
      if (this.hatchAnchor) {
        this.hatchAnchor.getWorldPosition(this.storyNote.position);
        this.storyNote.position.x += 0.08;
        this.storyNote.rotation.set(0.28, Math.PI / 2, 0.04);
      } else {
        this.storyNote.position.copy(a.hatch);
        this.storyNote.rotation.set(0.28, Math.PI / 2, 0.04);
      }
    } else if (hold && sim.stash === 'wash') {
      this.storyNote.visible = true;
      this.storyNote.scale.set(1.8, 1.8, 1.8);
      this.storyNote.position.copy(a.wash);
      this.storyNote.rotation.set(-0.5, 0.7, 0.15);
    } else if (hold && sim.stash === 'bunk') {
      this.storyNote.visible = true;
      this.storyNote.scale.set(1, 1, 1);
      this.storyNote.position.copy(a.bunk);
      this.storyNote.rotation.set(0, -0.4, 0);
    } else {
      this.storyNote.visible = false;
      this.storyNote.scale.set(1, 1, 1);
    }
    if (this.storyAsh) this.storyAsh.visible = sim.malyava === 'burn';
    if (this.storyExtra) this.storyExtra.visible = sim.malyava === 'admin' || sim.courtTalk === 'cell';
    if (this.storyTea) {
      this.storyTea.visible = teaDue;
      if (teaDue && this.hatchAnchor) {
        this.hatchAnchor.getWorldPosition(this.storyTea.position);
        this.storyTea.position.y -= 0.05;
      }
    }
    if (this.playerMattress) {
      this.playerMattress.rotation.z = searching ? 0.85 : 0;
      this.playerMattress.position.y = searching ? 0.72 : 0.5;
    }
    if (this.storyRummage) this.storyRummage.visible = searching;
    if (this.storyFound)
      this.storyFound.visible = sim.malyava === 'found' || (searching && sim.stash === 'bunk');
    if (this.judasEye) this.judasEye.visible = searching;
    if (this.kettleSteam) {
      const cold = sim.malyava === 'admin' || sim.courtTalk === 'cell';
      this.kettleSteam.visible = sim.stage === 'life' && !cold;
    }
    if (this.cigSmoke) {
      const cold = sim.malyava === 'admin' || sim.courtTalk === 'cell';
      this.cigSmoke.visible = sim.stage === 'life' && !cold && sim.phase?.id !== 'shmon';
    }
  }

  addWindows(cell, w, d, h) {
    const view = new THREE.MeshBasicMaterial({
      map: this.tex.windowView,
      side: THREE.DoubleSide,
    });
    this.windowGlass = this.windowGlass || [];
    this.windowGlass.push(view);
    const wood = new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.82 });
    const bars = new THREE.MeshStandardMaterial({ color: 0x2a2a2c, metalness: 0.7, roughness: 0.35 });
    for (const x of [-1.35, 1.35]) {
      const z = d / 2 - 0.09;
      this.box(1.18, 0.08, 0.1, wood, x, 2.15 + 0.62, z, cell);
      this.box(1.18, 0.08, 0.1, wood, x, 2.15 - 0.62, z, cell);
      this.box(0.08, 1.32, 0.1, wood, x - 0.55, 2.15, z, cell);
      this.box(0.08, 1.32, 0.1, wood, x + 0.55, 2.15, z, cell);
      const glass = new THREE.Mesh(new THREE.PlaneGeometry(0.98, 1.16), view);
      glass.position.set(x, 2.15, d / 2 - 0.2);
      glass.rotation.y = Math.PI;
      cell.add(glass);
      const grime = new THREE.Mesh(
        new THREE.PlaneGeometry(0.98, 0.38),
        new THREE.MeshBasicMaterial({ color: 0x6a6558, transparent: true, opacity: 0.28, depthWrite: false }),
      );
      grime.position.set(x, 1.68, d / 2 - 0.19);
      grime.rotation.y = Math.PI;
      cell.add(grime);
      const haze = new THREE.Mesh(
        new THREE.PlaneGeometry(0.96, 0.28),
        new THREE.MeshBasicMaterial({ color: 0x8a8680, transparent: true, opacity: 0.18, depthWrite: false }),
      );
      haze.position.set(x, 2.52, d / 2 - 0.19);
      haze.rotation.y = Math.PI;
      cell.add(haze);
      const dropMat = new THREE.MeshBasicMaterial({
        color: 0xa8b8c0,
        transparent: true,
        opacity: 0.42,
        depthWrite: false,
      });
      for (const [dx, dy] of [
        [-0.32, 0.38],
        [-0.18, 0.22],
        [0.08, 0.42],
        [0.24, 0.28],
        [0.36, 0.12],
        [-0.05, 0.08],
      ]) {
        const drop = new THREE.Mesh(new THREE.SphereGeometry(0.028, 5, 4), dropMat);
        drop.position.set(x + dx, 2.15 + dy, d / 2 - 0.175);
        cell.add(drop);
      }
      const stuffed = new THREE.Mesh(
        new THREE.BoxGeometry(0.22, 0.28, 0.014),
        new THREE.MeshStandardMaterial({ color: 0xc8b896, roughness: 0.9 }),
      );
      stuffed.position.set(x + 0.34, 1.78, d / 2 - 0.17);
      stuffed.rotation.z = 0.18;
      cell.add(stuffed);
      for (let i = -3; i <= 3; i++) {
        this.box(0.03, 1.12, 0.03, bars, x + i * 0.13, 2.15, d / 2 - 0.16, cell);
      }
      for (let j = -2; j <= 2; j++) {
        this.box(0.96, 0.025, 0.025, bars, x, 2.15 + j * 0.22, d / 2 - 0.16, cell);
      }
    }
  }

  addBunks(cell) {
    const ox = cell.position.x;
    const oz = cell.position.z;
    const spots = [
      [1.85, -2.35, 0],
      [1.85, 2.15, 0],
      [-0.15, 2.35, Math.PI / 2],
    ];
    this.furniture = this.furniture || [];
    for (const [x, z, rot] of spots) {
      const mine = x === 1.85 && z === -2.35;
      const bunk = this.makeBunk(mine);
      bunk.position.set(x, 0, z);
      bunk.rotation.y = rot;
      if (mine) {
        const tag = cellSign('ТВОЯ');
        tag.scale.setScalar(0.55);
        tag.position.set(-0.02, 0.78, 0.42);
        bunk.add(tag);
      }
      cell.add(bunk);
      if (rot) {
        this.furniture.push({ minx: ox + x - 0.5, maxx: ox + x + 0.5, minz: oz + z - 1.05, maxz: oz + z + 1.05 });
      } else {
        this.furniture.push({ minx: ox + x - 1.05, maxx: ox + x + 1.05, minz: oz + z - 0.5, maxz: oz + z + 0.5 });
      }
    }
  }

  makeBunk(player = false) {
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
    }
    const cloth = new THREE.MeshStandardMaterial({ color: 0xc5c0b4, roughness: 0.95 });
    const lowerBed = new THREE.Group();
    lowerBed.position.set(0, 0.5, 0);
    g.add(lowerBed);
    const lower = new THREE.Mesh(new THREE.BoxGeometry(1.72, 0.12, 0.72), cloth);
    lower.position.set(0.04, 0, 0);
    lowerBed.add(lower);
    if (player) this.playerMattress = lowerBed;
    const mattress = new THREE.Mesh(new THREE.BoxGeometry(1.72, 0.1, 0.72), cloth);
    mattress.position.set(0.04, 1.26, 0);
    g.add(mattress);
    const pillow = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.1, 0.38),
      new THREE.MeshStandardMaterial({ color: 0xd8d2c4, roughness: 0.9 }),
    );
    pillow.position.set(0.72, 0.12, 0);
    lowerBed.add(pillow);
    const blanket = new THREE.Mesh(
      new THREE.BoxGeometry(0.9, 0.05, 0.7),
      new THREE.MeshStandardMaterial({ color: 0x4a5a6a, roughness: 0.92 }),
    );
    blanket.position.set(-0.28, 0.08, 0);
    lowerBed.add(blanket);
    const rumple = new THREE.Mesh(
      new THREE.BoxGeometry(0.55, 0.07, 0.62),
      new THREE.MeshStandardMaterial({ color: 0x3e4a56, roughness: 0.93 }),
    );
    rumple.position.set(-0.5, 0.11, 0.04);
    rumple.rotation.z = 0.12;
    lowerBed.add(rumple);
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
    const ox = cell.position.x;
    const oz = cell.position.z;
    this.furniture = this.furniture || [];
    this.furniture.push({ minx: ox - 0.55, maxx: ox + 0.95, minz: oz - 0.18, maxz: oz + 0.58 });
    this.furniture.push({ minx: ox + 1.7, maxx: ox + 3.1, minz: oz + 1.85, maxz: oz + 3.35 });
    const wood = new THREE.MeshStandardMaterial({ color: 0xc8b48a, roughness: 0.8 });
    this.box(1.3, 0.05, 0.55, wood, 0.2, 0.72, 0.2, cell);
    this.addStools(cell);
    const kettle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.07, 0.09, 0.16, 12),
      new THREE.MeshStandardMaterial({ color: 0x7a7a72, metalness: 0.55, roughness: 0.35 }),
    );
    kettle.position.set(-0.15, 0.84, 0.15);
    cell.add(kettle);
    const steam = new THREE.Group();
    steam.position.set(-0.15, 1.02, 0.15);
    cell.add(steam);
    for (let i = 0; i < 5; i++) {
      const puff = new THREE.Mesh(
        new THREE.SphereGeometry(0.045 + i * 0.016, 8, 8),
        new THREE.MeshBasicMaterial({ color: 0xe8e4dc, transparent: true, opacity: 0.38, depthWrite: false }),
      );
      puff.position.y = i * 0.09;
      steam.add(puff);
    }
    this.kettleSteam = steam;
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
    const lamp = new THREE.PointLight(0xffd7a0, 0.7, 7, 2);
    lamp.position.set(0.2, 1.6, 0.2);
    cell.add(lamp);
    this.cellLamp = lamp;
    const windowFill = new THREE.PointLight(0x9bb4c4, 0.4, 8, 2);
    windowFill.position.set(-1.2, 2.15, LAYOUT.cellD / 2 - 0.5);
    cell.add(windowFill);
    this.windowFills = this.windowFills || [];
    this.windowFills.push(windowFill);
  }

  addStools(cell) {
    const wood = new THREE.MeshStandardMaterial({ color: 0x6a4e32, roughness: 0.86 });
    const spots = [
      [1.08, 0.18],
      [0.18, -0.4],
      [0.22, 0.74],
    ];
    for (const [x, z] of spots) {
      this.box(0.34, 0.07, 0.34, wood, x, 0.44, z, cell);
      for (const [sx, sz] of [
        [-0.11, -0.11],
        [0.11, -0.11],
        [-0.11, 0.11],
        [0.11, 0.11],
      ]) {
        this.box(0.055, 0.4, 0.055, wood, x + sx, 0.2, z + sz, cell);
      }
    }
  }

  addLivedIn(cell) {
    const rope = new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.8 });
    this.box(2.4, 0.012, 0.012, rope, -0.4, 1.92, 2.9, cell);
    const wallCal = cellSign('СУТКИ');
    wallCal.scale.setScalar(0.85);
    wallCal.position.set(0.15, 1.88, LAYOUT.cellD / 2 - 0.16);
    wallCal.rotation.y = Math.PI;
    cell.add(wallCal);
    const cloths = [0x8a8e98, 0xd8d2c0, 0x9a6a42];
    cloths.forEach((c, i) => {
      const rag = new THREE.Mesh(
        new THREE.BoxGeometry(0.28, 0.42, 0.04),
        new THREE.MeshStandardMaterial({ color: c, roughness: 0.92 }),
      );
      rag.position.set(-1.1 + i * 0.55, 1.68, 2.9);
      rag.rotation.z = (i - 1) * 0.08;
      cell.add(rag);
    });
    const bottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.04, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a4a38, roughness: 0.3, metalness: 0.1 }),
    );
    bottle.position.set(0.55, 0.86, 0.28);
    cell.add(bottle);
    const book = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.03, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x4a2020, roughness: 0.85 }),
    );
    book.position.set(1.4, 0.58, 2.0);
    book.rotation.y = 0.4;
    cell.add(book);
    const days = cellSign('18  Х  Х');
    days.scale.setScalar(0.7);
    days.position.set(-2.15, 1.45, 1.1);
    days.rotation.y = Math.PI / 2;
    cell.add(days);
    const dampCal = new THREE.MeshStandardMaterial({ color: 0x4a524c, roughness: 0.4, transparent: true, opacity: 0.5 });
    this.box(0.02, 0.85, 0.42, dampCal, -LAYOUT.cellW / 2 + 0.21, 0.72, 1.1, cell);
    this.box(0.02, 0.45, 0.22, dampCal, -LAYOUT.cellW / 2 + 0.21, 0.48, 1.28, cell);
    const calShelf = new THREE.MeshStandardMaterial({ color: 0x5a4a38, roughness: 0.88 });
    this.box(0.16, 0.035, 0.42, calShelf, -LAYOUT.cellW / 2 + 0.32, 0.92, 1.1, cell);
    const stuffedNews = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.16, 0.12),
      new THREE.MeshStandardMaterial({ color: 0xd8d0b8, roughness: 0.92 }),
    );
    stuffedNews.position.set(-LAYOUT.cellW / 2 + 0.28, 1.08, 1.22);
    stuffedNews.rotation.set(0.15, 0.4, 0.2);
    cell.add(stuffedNews);
    const mug = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.032, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.55, metalness: 0.2 }),
    );
    mug.position.set(-LAYOUT.cellW / 2 + 0.34, 0.96, 0.98);
    cell.add(mug);
    const ticks2 = wallScratch('||||');
    ticks2.scale.set(0.85, 0.85, 0.85);
    ticks2.position.set(-LAYOUT.cellW / 2 + 0.22, 0.62, 0.95);
    ticks2.rotation.y = Math.PI / 2;
    cell.add(ticks2);
    const floorRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.38, 0.03, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.94 }),
    );
    floorRag.position.set(-1.75, 0.04, 0.85);
    floorRag.rotation.y = 0.45;
    cell.add(floorRag);
    const floorRag2 = floorRag.clone();
    floorRag2.position.set(-1.55, 0.035, 1.15);
    floorRag2.rotation.y = -0.3;
    cell.add(floorRag2);
    const buttCal = new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.82 });
    for (const [bx, bz] of [
      [-1.62, 1.02],
      [-1.48, 0.88],
      [-1.7, 1.22],
    ]) {
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.01, 0.012, 0.035, 5), buttCal);
      c.rotation.z = Math.PI / 2;
      c.position.set(bx, 0.055, bz);
      cell.add(c);
    }
    const doorPail = new THREE.Mesh(
      new THREE.CylinderGeometry(0.13, 0.11, 0.26, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, metalness: 0.35, roughness: 0.55 }),
    );
    doorPail.position.set(-1.95, 0.16, 1.35);
    cell.add(doorPail);
    const korm = wallScratch('КОРМ');
    korm.scale.set(0.9, 0.9, 0.9);
    korm.position.set(-LAYOUT.cellW / 2 + 0.22, 1.28, 2.55);
    korm.rotation.y = Math.PI / 2;
    cell.add(korm);
    const hatchRust = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.88 });
    this.box(0.02, 0.55, 0.7, hatchRust, -LAYOUT.cellW / 2 + 0.2, 1.5, 3.15, cell);
    this.box(0.02, 0.28, 0.35, hatchRust, -LAYOUT.cellW / 2 + 0.2, 1.22, 3.35, cell);

    const wet = new THREE.Mesh(
      new THREE.CircleGeometry(0.55, 10),
      new THREE.MeshStandardMaterial({ color: 0x3a3a32, roughness: 0.18, metalness: 0.12 }),
    );
    wet.rotation.x = -Math.PI / 2;
    wet.position.set(2.15, 0.04, 2.35);
    cell.add(wet);
    const ash = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.045, 0.025, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.7 }),
    );
    ash.position.set(0.48, 0.755, 0.02);
    cell.add(ash);
    const cigSmoke = new THREE.Group();
    cigSmoke.position.set(0.48, 0.82, 0.02);
    cell.add(cigSmoke);
    for (let i = 0; i < 3; i++) {
      const puff = new THREE.Mesh(
        new THREE.SphereGeometry(0.022 + i * 0.01, 6, 6),
        new THREE.MeshBasicMaterial({ color: 0xb8b4ac, transparent: true, opacity: 0.18, depthWrite: false }),
      );
      puff.position.set(i * 0.02, i * 0.05, 0);
      cigSmoke.add(puff);
    }
    this.cigSmoke = cigSmoke;
    const stain = new THREE.Mesh(
      new THREE.CircleGeometry(0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a2418, roughness: 0.95 }),
    );
    stain.rotation.x = -Math.PI / 2;
    stain.position.set(-0.12, 0.746, 0.12);
    cell.add(stain);
    const butts = new THREE.MeshStandardMaterial({ color: 0xd8c8a0, roughness: 0.7 });
    for (const [bx, bz, ry] of [
      [0.52, 0.06, 0.4],
      [0.44, -0.04, -0.7],
      [0.5, 0.0, 1.1],
    ]) {
      const butt = new THREE.Mesh(new THREE.CylinderGeometry(0.008, 0.008, 0.04, 5), butts);
      butt.rotation.set(1.2, ry, 0.4);
      butt.position.set(bx, 0.76, bz);
      cell.add(butt);
    }
    const slip = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.04, 0.1),
      new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.9 }),
    );
    slip.position.set(1.55, 0.05, -1.85);
    slip.rotation.y = 0.4;
    cell.add(slip);
    const slip2 = slip.clone();
    slip2.position.set(1.72, 0.05, -1.72);
    slip2.rotation.y = -0.2;
    cell.add(slip2);
    const ticks = wallScratch('|||| |');
    ticks.position.set(-2.18, 1.15, -0.4);
    ticks.rotation.y = Math.PI / 2;
    cell.add(ticks);
    const drip = new THREE.Mesh(
      new THREE.SphereGeometry(0.018, 6, 6),
      new THREE.MeshStandardMaterial({ color: 0x8aa0a8, roughness: 0.2, transparent: true, opacity: 0.7 }),
    );
    drip.position.set(-0.8, 2.72, 1.1);
    cell.add(drip);
    this.washDrip = drip;
    const soap = new THREE.Mesh(
      new THREE.BoxGeometry(0.07, 0.025, 0.045),
      new THREE.MeshStandardMaterial({ color: 0xd8d0c0, roughness: 0.45 }),
    );
    soap.position.set(2.0, 0.97, 2.95);
    cell.add(soap);
    const brush = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012, 0.012, 0.14, 6),
      new THREE.MeshStandardMaterial({ color: 0xc8c4bc, roughness: 0.5 }),
    );
    brush.position.set(2.08, 1.02, 2.92);
    brush.rotation.z = 0.4;
    cell.add(brush);
    const paper = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.01, 0.16),
      new THREE.MeshStandardMaterial({ color: 0xe4dcc4, roughness: 0.92 }),
    );
    paper.position.set(1.55, 0.58, -2.15);
    paper.rotation.y = -0.35;
    cell.add(paper);
    const bread = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.05, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xc4a070, roughness: 0.88 }),
    );
    bread.position.set(0.42, 0.78, 0.32);
    cell.add(bread);
    const sock = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.28, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x4a4a46, roughness: 0.94 }),
    );
    sock.position.set(0.55, 1.72, 2.9);
    sock.rotation.z = 0.15;
    cell.add(sock);
    const hangMat = new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.9 });
    for (const [sx, sy, sz, rz] of [
      [-1.52, 0.92, LAYOUT.cellD / 2 - 0.28, 0.35],
      [-1.22, 0.98, LAYOUT.cellD / 2 - 0.26, -0.2],
      [-1.38, 1.08, LAYOUT.cellD / 2 - 0.3, 0.1],
    ]) {
      const hang = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.32, 0.035), hangMat);
      hang.position.set(sx, sy, sz);
      hang.rotation.z = rz;
      cell.add(hang);
    }
    const rad = new THREE.MeshStandardMaterial({ color: 0x6a3a28, roughness: 0.68, metalness: 0.22 });
    this.box(1.15, 0.42, 0.12, rad, -1.35, 0.38, LAYOUT.cellD / 2 - 0.22, cell);
    for (let i = -2; i <= 2; i++) {
      this.box(0.06, 0.38, 0.1, rad, -1.35 + i * 0.2, 0.38, LAYOUT.cellD / 2 - 0.2, cell);
    }
    const hole = new THREE.Mesh(
      new THREE.CircleGeometry(0.035, 10),
      new THREE.MeshStandardMaterial({ color: 0x0a0a0c, roughness: 0.4 }),
    );
    hole.position.set(-LAYOUT.cellW / 2 + 0.23, 1.48, -1.8);
    hole.rotation.y = Math.PI / 2;
    cell.add(hole);
    const peel = new THREE.MeshStandardMaterial({ color: 0xc8c0b0, roughness: 0.92 });
    this.box(0.55, 0.38, 0.02, peel, -1.1, 1.55, LAYOUT.cellD / 2 - 0.14, cell);
    this.box(0.32, 0.22, 0.02, peel, -0.7, 1.38, LAYOUT.cellD / 2 - 0.14, cell);
    const leak = new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.55, metalness: 0.05 });
    this.box(0.18, 1.15, 0.015, leak, -1.35, 1.55, LAYOUT.cellD / 2 - 0.135, cell);
    this.box(0.28, 0.55, 0.012, leak, -1.22, 0.85, LAYOUT.cellD / 2 - 0.135, cell);
    const rust = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.9 });
    this.box(0.22, 0.16, 0.02, rust, -1.55, 0.18, LAYOUT.cellD / 2 - 0.16, cell);
    this.box(0.14, 0.1, 0.02, rust, -1.18, 0.14, LAYOUT.cellD / 2 - 0.16, cell);
    const shelf = new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.86 });
    this.box(0.55, 0.04, 0.18, shelf, 2.55, 1.35, 0.4, cell);
    this.box(0.04, 0.35, 0.04, shelf, 2.35, 1.16, 0.48, cell);
    this.box(0.04, 0.35, 0.04, shelf, 2.72, 1.16, 0.32, cell);
    const paste = new THREE.Mesh(
      new THREE.CylinderGeometry(0.018, 0.02, 0.11, 6),
      new THREE.MeshStandardMaterial({ color: 0xc8d0c4, roughness: 0.5 }),
    );
    paste.position.set(2.48, 1.42, 0.38);
    paste.rotation.z = 1.2;
    cell.add(paste);
    const card = cellSign('МАМА');
    card.scale.setScalar(0.42);
    card.position.set(2.7, 1.72, -0.8);
    card.rotation.y = -Math.PI / 2;
    cell.add(card);
    const hush = wallScratch('НЕ СТУЧИ');
    hush.scale.set(0.85, 0.85, 0.85);
    hush.position.set(-LAYOUT.cellW / 2 + 0.22, 1.62, 0.15);
    hush.rotation.y = Math.PI / 2;
    cell.add(hush);
    const fly = new THREE.MeshStandardMaterial({ color: 0xc8b878, roughness: 0.7 });
    this.box(0.04, 0.42, 0.01, fly, 1.1, 2.55, LAYOUT.cellD / 2 - 0.22, cell);
    const specks = new THREE.MeshStandardMaterial({ color: 0x1a1a14, roughness: 0.9 });
    for (const [fx, fy] of [
      [1.08, 2.48],
      [1.12, 2.4],
      [1.1, 2.35],
      [1.14, 2.52],
    ]) {
      this.box(0.015, 0.015, 0.012, specks, fx, fy, LAYOUT.cellD / 2 - 0.21, cell);
    }
    const broom = new THREE.MeshStandardMaterial({ color: 0x5a4030, roughness: 0.85 });
    this.box(0.035, 1.15, 0.035, broom, 2.75, 0.58, -2.4, cell);
    const bristles = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.08, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x8a7a58, roughness: 0.9 }),
    );
    bristles.position.set(2.75, 0.08, -2.4);
    cell.add(bristles);
    const news = new THREE.Mesh(
      new THREE.BoxGeometry(0.24, 0.008, 0.18),
      new THREE.MeshStandardMaterial({ color: 0xd8d0bc, roughness: 0.9 }),
    );
    news.position.set(0.48, 0.76, 0.18);
    news.rotation.y = 0.25;
    cell.add(news);
    const outlet = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.1, 0.02),
      new THREE.MeshStandardMaterial({ color: 0xb8b0a0, roughness: 0.6 }),
    );
    outlet.position.set(-LAYOUT.cellW / 2 + 0.2, 0.95, 0.6);
    outlet.rotation.y = Math.PI / 2;
    cell.add(outlet);
    const own = wallScratch('СВОЯ');
    own.scale.set(0.7, 0.7, 0.7);
    own.position.set(LAYOUT.cellW / 2 - 0.22, 1.05, -1.9);
    own.rotation.y = -Math.PI / 2;
    cell.add(own);
    const pail = new THREE.Mesh(
      new THREE.CylinderGeometry(0.11, 0.09, 0.2, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.45, roughness: 0.45 }),
    );
    pail.position.set(2.35, 0.14, 2.55);
    cell.add(pail);
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
      const lamp = new THREE.PointLight(0xffc070, 0.35, 4.5, 2);
      lamp.position.set(0.2, 1.7, 0);
      g.add(lamp);
      const rag = new THREE.Mesh(
        new THREE.BoxGeometry(0.22, 0.35, 0.04),
        new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.92 }),
      );
      rag.position.set(-0.6, 1.1, 1.5);
      g.add(rag);
      const mug = new THREE.Mesh(
        new THREE.CylinderGeometry(0.035, 0.03, 0.06, 8),
        new THREE.MeshStandardMaterial({ color: 0xc4b49a, roughness: 0.6 }),
      );
      mug.position.set(0.55, 0.72, 0.4);
      g.add(mug);
      const line = new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.8 });
      this.box(1.6, 0.01, 0.01, line, 0, 1.85, 1.55, g);
      const rag2 = rag.clone();
      rag2.material = new THREE.MeshStandardMaterial({ color: 0x8a8a82, roughness: 0.9 });
      rag2.position.set(0.2, 1.55, 1.55);
      g.add(rag2);
      const glow = new THREE.Mesh(
        new THREE.PlaneGeometry(0.22, 0.14),
        new THREE.MeshBasicMaterial({ color: 0xd4b878 }),
      );
      glow.position.set(2.05, 1.52, 0);
      glow.rotation.y = Math.PI / 2;
      g.add(glow);
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

    const plaster = new THREE.MeshStandardMaterial({
      color: 0xcfc8b8,
      roughness: 0.88,
      side: THREE.DoubleSide,
    });
    const dado = new THREE.MeshStandardMaterial({
      color: 0x3a6a62,
      roughness: 0.75,
      side: THREE.DoubleSide,
    });
    const dirt = new THREE.MeshStandardMaterial({ color: 0x5a584e, roughness: 0.96 });
    this.box(9, 0.08, 9, dirt, 0, 0.03, 0, g);
    const crack = new THREE.MeshStandardMaterial({ color: 0x3a3830, roughness: 0.9 });
    this.box(3.4, 0.015, 0.04, crack, -1.9, 0.075, -2.15, g);
    this.box(0.04, 0.015, 2.2, crack, 2.35, 0.075, 2.5, g);
    this.box(2.1, 0.015, 0.03, crack, 1.8, 0.075, -2.4, g);
    this.box(9, 3.4, 0.3, plaster, 0, 1.7, 4.45, g);
    this.box(9, 1.15, 0.04, dado, 0, 0.57, 4.28, g);
    for (const x of [-4.45, 4.45]) {
      this.box(0.3, 1.15, 9, dado, x, 0.57, 0, g);
      this.box(0.3, 2.25, 9, plaster, x, 2.27, 0, g);
    }
    const cage = new THREE.MeshStandardMaterial({ color: 0x3a3e42, metalness: 0.55, roughness: 0.4 });
    for (let i = -4; i <= 4; i++) {
      this.box(0.05, 0.05, 8.8, cage, i, 3.38, 0, g);
      this.box(8.8, 0.05, 0.05, cage, 0, 3.38, i, g);
    }
    this.addYardLife(g);

    const doorW = 1.28;
    const doorH = 2.22;
    const wallZ = -4.45;
    const wing = (9 - doorW) / 2;
    const wingX = (9 + doorW) / 4;
    this.box(wing, 3.4, 0.32, plaster, -wingX, 1.7, wallZ, g);
    this.box(wing, 3.4, 0.32, plaster, wingX, 1.7, wallZ, g);
    this.box(doorW, 3.4 - doorH, 0.32, plaster, 0, doorH + (3.4 - doorH) / 2, wallZ, g);
    this.box(0.12, doorH, 0.32, plaster, -doorW / 2, doorH / 2, wallZ, g);
    this.box(0.12, doorH, 0.32, plaster, doorW / 2, doorH / 2, wallZ, g);

    const hw = LAYOUT.corridorHalf;
    const neckZ = z0 - 0.2;
    const red = this.mat(this.tex.red, { roughness: 0.78, metalness: 0, env: 0.12, repeat: [1, 0.4] });
    red.color.set(0xb24a32);
    this.box(hw * 2, 0.06, 1.3, red, 0, 0.03, neckZ);
    this.box(0.2, LAYOUT.wallH, 1.3, plaster, hw, LAYOUT.wallH / 2, neckZ).userData.camCollide = true;
    this.box(0.2, LAYOUT.wallH, 1.3, plaster, -hw, LAYOUT.wallH / 2, neckZ).userData.camCollide = true;
    this.box(hw * 2 + 0.2, 0.14, 1.3, plaster, 0, LAYOUT.wallH + 0.2, neckZ);

    const skyLight = new THREE.Mesh(
      new THREE.PlaneGeometry(8, 8),
      new THREE.MeshBasicMaterial({ color: 0x8aa6b8, side: THREE.DoubleSide }),
    );
    skyLight.rotation.x = Math.PI / 2;
    skyLight.position.y = 3.45;
    g.add(skyLight);
    const sun = new THREE.PointLight(0xe8dcc0, 1.15, 14, 1.5);
    sun.position.set(0, 3.05, 0.4);
    g.add(sun);
    const doorLamp = new THREE.PointLight(0xf0ead0, 0.85, 8, 1.6);
    doorLamp.position.set(0, 2.45, wallZ + 0.9);
    g.add(doorLamp);

    const green = this.mat(this.tex.green, { roughness: 0.45, metalness: 0.28 });
    const gate = new THREE.Mesh(new THREE.BoxGeometry(1.18, 2.12, 0.07), green);
    gate.position.set(-1.22, 1.06, wallZ + 0.62);
    gate.rotation.y = 1.48;
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
    this.addCollider(-4.5, -doorW / 2, z0 - 0.25, z0 + 0.4, 'yard-door-l');
    this.addCollider(doorW / 2, 4.5, z0 - 0.25, z0 + 0.4, 'yard-door-r');
  }

  addYardLife(g) {
    const mesh = new THREE.MeshStandardMaterial({ color: 0x2e3236, metalness: 0.55, roughness: 0.42 });
    for (const x of [-4.28, 4.28]) {
      for (let i = -8; i <= 8; i++) {
        this.box(0.03, 3.2, 0.03, mesh, x, 1.7, i * 0.48, g);
      }
      for (let y = 0.4; y <= 3.1; y += 0.38) {
        this.box(0.03, 0.03, 8.6, mesh, x, y, 0, g);
      }
    }
    for (let i = -8; i <= 8; i++) {
      this.box(0.03, 3.2, 0.03, mesh, i * 0.5, 1.7, 4.28, g);
    }
    for (let y = 0.4; y <= 3.1; y += 0.38) {
      this.box(8.6, 0.03, 0.03, mesh, 0, y, 4.28, g);
    }
    const bench = new THREE.MeshStandardMaterial({ color: 0x5a4630, roughness: 0.88 });
    this.box(1.6, 0.08, 0.36, bench, -2.7, 0.42, -1.55, g);
    this.box(0.08, 0.4, 0.08, bench, -3.3, 0.2, -1.65, g);
    this.box(0.08, 0.4, 0.08, bench, -2.1, 0.2, -1.65, g);
    this.box(1.8, 0.08, 0.38, bench, -2.2, 0.42, 2.6, g);
    this.box(0.08, 0.4, 0.08, bench, -2.95, 0.2, 2.48, g);
    this.box(0.08, 0.4, 0.08, bench, -1.45, 0.2, 2.48, g);
    this.box(0.08, 0.4, 0.08, bench, -2.95, 0.2, 2.72, g);
    this.box(0.08, 0.4, 0.08, bench, -1.45, 0.2, 2.72, g);
    const puddle = new THREE.Mesh(
      new THREE.CircleGeometry(0.7, 12),
      new THREE.MeshStandardMaterial({ color: 0x4a4e46, roughness: 0.16, metalness: 0.18 }),
    );
    puddle.rotation.x = -Math.PI / 2;
    puddle.position.set(1.4, 0.045, -1.1);
    g.add(puddle);
    const plate = new THREE.Mesh(
      new THREE.CylinderGeometry(0.12, 0.11, 0.02, 10),
      new THREE.MeshStandardMaterial({ color: 0x6a7068, metalness: 0.4, roughness: 0.5 }),
    );
    plate.position.set(-2.55, 0.48, -1.5);
    g.add(plate);
    const mud = new THREE.MeshStandardMaterial({ color: 0x3a3830, roughness: 0.95 });
    this.box(0.55, 0.02, 0.28, mud, -0.8, 0.05, 1.4, g);
    this.box(0.4, 0.018, 0.22, mud, 0.6, 0.05, -2.0, g);
    const sockYard = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.28, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x4a4a46, roughness: 0.94 }),
    );
    sockYard.position.set(4.12, 1.15, 0.4);
    sockYard.rotation.z = 0.2;
    g.add(sockYard);
    const grate = this.box(0.42, 0.02, 0.42, mesh, 1.4, 0.05, -1.1, g);
    grate.rotation.y = 0.2;
    const stain = new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.95, transparent: true, opacity: 0.55 });
    this.box(1.6, 1.1, 0.02, stain, -2.4, 1.4, 4.22, g);
    const wetWall = new THREE.MeshStandardMaterial({ color: 0x4a524c, roughness: 0.35, transparent: true, opacity: 0.45 });
    this.box(0.55, 2.2, 0.02, wetWall, 1.8, 1.2, 4.22, g);
    this.box(0.22, 1.6, 0.02, wetWall, 2.05, 0.9, 4.22, g);
    const cam = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.1, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x1a1a1c, metalness: 0.4, roughness: 0.5 }),
    );
    cam.position.set(3.6, 2.85, -3.6);
    cam.rotation.y = -0.7;
    g.add(cam);
    const lens = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.045, 0.06, 8),
      new THREE.MeshStandardMaterial({ color: 0x111214, metalness: 0.7, roughness: 0.25 }),
    );
    lens.rotation.x = Math.PI / 2;
    lens.position.set(3.55, 2.85, -3.48);
    g.add(lens);
    const scratch = wallScratch('НЕ ОРИ');
    scratch.position.set(0.2, 1.55, 4.26);
    scratch.rotation.y = Math.PI;
    g.add(scratch);
    const horn = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.14, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a3a38, metalness: 0.45, roughness: 0.5 }),
    );
    horn.position.set(-3.6, 2.9, -3.5);
    horn.rotation.x = 0.5;
    horn.rotation.z = -0.4;
    g.add(horn);
    const num = wallScratch('13');
    num.scale.setScalar(1.6);
    num.position.set(3.2, 1.7, 4.26);
    num.rotation.y = Math.PI;
    g.add(num);
    const butt = new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.8 });
    for (const [x, z] of [
      [-0.4, 0.8],
      [0.2, 1.1],
      [-1.8, 2.4],
      [1.1, -0.4],
    ]) {
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.014, 0.04, 5), butt);
      c.rotation.z = Math.PI / 2;
      c.rotation.y = Math.random();
      c.position.set(x, 0.06, z);
      g.add(c);
    }
    const print = new THREE.MeshStandardMaterial({ color: 0x4a4a42, roughness: 0.95, transparent: true, opacity: 0.35 });
    for (let i = 0; i < 8; i++) {
      const p = new THREE.Mesh(new THREE.CircleGeometry(0.09, 6), print);
      p.rotation.x = -Math.PI / 2;
      p.scale.set(1, 1.6, 1);
      p.position.set(-0.2 + (i % 2) * 0.28, 0.042, -2.2 + i * 0.55);
      g.add(p);
    }
    const lime = new THREE.MeshStandardMaterial({ color: 0xe8e2c4, roughness: 0.74 });
    for (let a = 0; a < Math.PI * 2; a += 0.18) {
      const seg = this.box(0.78, 0.03, 0.22, lime, Math.cos(a) * 2.4, 0.06, Math.sin(a) * 2.4, g);
      seg.rotation.y = -a;
    }
    const circle = floorPaint('КРУГ');
    circle.rotation.x = -Math.PI / 2;
    circle.rotation.z = Math.PI;
    circle.position.set(0, 0.085, 1.7);
    g.add(circle);
    const wallKrug = wallScratch('КРУГ');
    wallKrug.scale.set(1.7, 1.7, 1.7);
    wallKrug.position.set(-2.6, 1.55, 4.22);
    wallKrug.rotation.y = Math.PI;
    g.add(wallKrug);
    this.box(1.4, 0.08, 0.34, bench, 2.4, 0.42, 1.8, g);
    this.box(0.08, 0.4, 0.08, bench, 1.85, 0.2, 1.68, g);
    this.box(0.08, 0.4, 0.08, bench, 2.95, 0.2, 1.68, g);
    const tin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.035, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.55, roughness: 0.4 }),
    );
    tin.position.set(2.55, 0.5, 1.78);
    g.add(tin);
    const shoe = new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.9 });
    for (const [sx, sz] of [
      [2.05, 1.55],
      [2.22, 1.62],
    ]) {
      const galosh = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.07, 0.1), shoe);
      galosh.position.set(sx, 0.08, sz);
      galosh.rotation.y = 0.3;
      g.add(galosh);
    }
    const wire = new THREE.MeshStandardMaterial({ color: 0x4a4e52, metalness: 0.55, roughness: 0.4 });
    for (let i = -7; i <= 7; i++) {
      this.box(8.6, 0.02, 0.02, wire, 0, 3.42, i * 0.55, g);
    }
    const tower = new THREE.MeshStandardMaterial({ color: 0x6a665c, roughness: 0.88 });
    this.box(1.1, 4.2, 1.1, tower, 5.6, 2.1, -3.8, g);
    this.box(1.6, 0.18, 1.6, tower, 5.6, 4.25, -3.8, g);
    const slit = new THREE.Mesh(
      new THREE.PlaneGeometry(0.35, 0.18),
      new THREE.MeshBasicMaterial({ color: 0xc4a060 }),
    );
    slit.position.set(5.05, 3.7, -3.8);
    slit.rotation.y = -Math.PI / 2;
    g.add(slit);
    const pole = new THREE.MeshStandardMaterial({ color: 0x4a4e52, metalness: 0.4, roughness: 0.5 });
    this.box(0.08, 2.6, 0.08, pole, -3.5, 1.3, -3.4, g);
    const bucket = new THREE.Mesh(
      new THREE.CylinderGeometry(0.14, 0.12, 0.28, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a2020, roughness: 0.55, metalness: 0.2 }),
    );
    bucket.position.set(3.4, 0.18, -2.8);
    g.add(bucket);
    const bucket2 = bucket.clone();
    bucket2.position.set(-2.85, 0.18, 3.55);
    g.add(bucket2);
    const rag = new THREE.Mesh(
      new THREE.BoxGeometry(0.32, 0.08, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.92 }),
    );
    rag.position.set(-2.55, 0.08, 3.35);
    rag.rotation.y = 0.4;
    g.add(rag);
    const mop = new THREE.MeshStandardMaterial({ color: 0x4a3a28, roughness: 0.8 });
    this.box(0.04, 1.15, 0.04, mop, -3.05, 0.58, 3.4, g);
    const mopHead = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.06, 0.12),
      new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.9 }),
    );
    mopHead.position.set(-3.05, 0.08, 3.4);
    g.add(mopHead);
    const rustPipe = new THREE.MeshStandardMaterial({ color: 0x6a3a28, roughness: 0.7, metalness: 0.25 });
    this.box(2.4, 0.07, 0.07, rustPipe, 0.2, 2.18, 4.12, g);
    this.box(0.08, 0.55, 0.08, rustPipe, -0.9, 1.88, 4.12, g);
    this.box(0.08, 0.55, 0.08, rustPipe, 1.3, 1.88, 4.12, g);
    const bar = new THREE.MeshStandardMaterial({ color: 0x3a3e42, metalness: 0.55, roughness: 0.4 });
    this.box(0.06, 2.15, 0.06, bar, -1.15, 1.1, 3.95, g);
    this.box(0.06, 2.15, 0.06, bar, 1.15, 1.1, 3.95, g);
    this.box(2.42, 0.05, 0.05, bar, 0, 2.18, 3.95, g);
    const jacket = new THREE.Mesh(
      new THREE.BoxGeometry(0.42, 0.55, 0.08),
      new THREE.MeshStandardMaterial({ color: 0x3a4a3c, roughness: 0.9 }),
    );
    jacket.position.set(-3.95, 1.35, 1.4);
    jacket.rotation.y = Math.PI / 2;
    g.add(jacket);
    const puddle2 = puddle.clone();
    puddle2.scale.set(0.7, 0.55, 1);
    puddle2.position.set(-1.6, 0.045, 2.9);
    g.add(puddle2);
    const chain = new THREE.MeshStandardMaterial({ color: 0x5a5e58, metalness: 0.55, roughness: 0.4 });
    for (let y = 0.5; y <= 2.6; y += 0.22) {
      this.box(0.22, 0.04, 0.04, chain, 4.18, y, 2.2, g);
    }
    const peel = new THREE.MeshStandardMaterial({ color: 0xb8b0a0, roughness: 0.92 });
    const damp = new THREE.MeshStandardMaterial({ color: 0x6a6860, roughness: 0.55, transparent: true, opacity: 0.5 });
    const moss = new THREE.MeshStandardMaterial({ color: 0x4a5a48, roughness: 0.9, transparent: true, opacity: 0.4 });
    for (const side of [-1, 1]) {
      this.box(0.02, 1.35, 1.8, damp, side * 4.22, 2.15, -0.4, g);
      this.box(0.02, 0.9, 0.85, damp, side * 4.22, 2.55, 1.6, g);
      this.box(0.02, 0.55, 1.1, peel, side * 4.21, 2.35, 0.7, g);
      this.box(0.02, 0.42, 0.7, peel, side * 4.21, 1.85, -1.8, g);
      this.box(0.02, 0.7, 0.35, moss, side * 4.21, 1.35, 2.4, g);
      this.box(0.02, 1.6, 0.18, wetWall, side * 4.22, 1.7, -2.6, g);
    }
    this.box(0.02, 1.1, 2.2, damp, 0.6, 2.4, 4.22, g);
    this.box(0.02, 0.7, 1.4, peel, -1.1, 2.5, 4.22, g);
    const dadoStain = new THREE.MeshStandardMaterial({ color: 0x2a4a44, roughness: 0.8, transparent: true, opacity: 0.55 });
    for (const side of [-1, 1]) {
      this.box(0.04, 0.85, 1.6, dadoStain, side * 4.28, 0.62, -0.8, g);
      this.box(0.04, 0.55, 0.9, dadoStain, side * 4.28, 0.48, 1.4, g);
    }
    const stand = wallScratch('СТОЙ');
    stand.scale.set(1.6, 1.6, 1.6);
    stand.position.set(4.18, 1.55, -0.8);
    stand.rotation.y = -Math.PI / 2;
    g.add(stand);
    const hushYard = wallScratch('НЕ СВИСТИ');
    hushYard.scale.set(1.1, 1.1, 1.1);
    hushYard.position.set(-4.2, 1.7, 1.2);
    hushYard.rotation.y = Math.PI / 2;
    g.add(hushYard);
    this.box(0.7, 0.02, 0.35, mud, 3.6, 0.05, -0.6, g);
    this.box(0.5, 0.018, 0.28, mud, -3.5, 0.05, 0.9, g);
    this.box(0.38, 0.016, 0.5, mud, 3.7, 0.05, 2.1, g);
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

    const puddleMat = new THREE.MeshStandardMaterial({ color: 0x3a2420, roughness: 0.22, metalness: 0.35 });
    for (const [x, z, s] of [
      [0.35, 7.2, 0.55],
      [-0.4, 19.4, 0.7],
      [0.2, 31.5, 0.45],
    ]) {
      const p = new THREE.Mesh(new THREE.CircleGeometry(s, 8), puddleMat);
      p.rotation.x = -Math.PI / 2;
      p.position.set(x, 0.045, z);
      this.group.add(p);
    }
    const quiet = cellSign('ТИХО');
    quiet.scale.set(0.55, 0.55, 0.55);
    quiet.rotation.x = -Math.PI / 2;
    quiet.position.set(-0.55, 0.05, 11.2);
    this.group.add(quiet);

    const rust = new THREE.MeshStandardMaterial({ color: 0x6a3a28, roughness: 0.7, metalness: 0.25 });
    for (const z of [5.1, 12.2, 20.4, 28.6]) {
      this.box(0.1, 0.52, 0.95, rust, -LAYOUT.corridorHalf + 0.2, 0.42, z);
      for (let i = -3; i <= 3; i++) {
        this.box(0.04, 0.48, 0.04, rust, -LAYOUT.corridorHalf + 0.16, 0.42, z + i * 0.12);
      }
    }
    const valve = new THREE.Mesh(
      new THREE.TorusGeometry(0.07, 0.015, 6, 10),
      new THREE.MeshStandardMaterial({ color: 0x8a2020, metalness: 0.5, roughness: 0.4 }),
    );
    valve.position.set(-LAYOUT.corridorHalf + 0.28, 2.18, 9.4);
    valve.rotation.y = Math.PI / 2;
    this.group.add(valve);
    const cable = new THREE.MeshStandardMaterial({ color: 0x1a1a1a, roughness: 0.9 });
    for (const z of [8.2, 16.8, 25.5]) {
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.85, 5), cable);
      c.position.set(LAYOUT.corridorHalf - 0.18, 2.15, z);
      c.rotation.z = 0.35;
      this.group.add(c);
    }
    const board = this.box(
      0.04,
      0.55,
      0.7,
      new THREE.MeshStandardMaterial({ color: 0x3a4a38, roughness: 0.85 }),
      LAYOUT.corridorHalf - 0.14,
      1.55,
      16.2,
    );
    const paper = this.box(0.01, 0.22, 0.16, new THREE.MeshStandardMaterial({ color: 0xe8e0cc }), LAYOUT.corridorHalf - 0.11, 1.62, 16.05);
    paper.rotation.z = 0.08;
    for (const z of [6.95, 10.5, 14.05]) {
      const leak = new THREE.PointLight(0xffc070, 0.08, 1.6, 2);
      leak.position.set(-LAYOUT.corridorHalf + 0.25, 1.52, z);
      this.group.add(leak);
    }
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

function floorPaint(text) {
  const c = document.createElement('canvas');
  c.width = 768;
  c.height = 256;
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, 768, 256);
  ctx.strokeStyle = 'rgba(90,70,36,0.95)';
  ctx.lineWidth = 10;
  ctx.font = '800 168px serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.strokeText(text, 384, 140);
  ctx.fillStyle = 'rgba(232,226,196,0.92)';
  ctx.fillText(text, 384, 140);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return new THREE.Mesh(
    new THREE.PlaneGeometry(3.4, 1.15),
    new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false }),
  );
}

function wallScratch(text) {
  const c = document.createElement('canvas');
  c.width = 256;
  c.height = 96;
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, 256, 96);
  ctx.fillStyle = 'rgba(40,32,24,0.85)';
  ctx.font = '700 36px serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 128, 50);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return new THREE.Mesh(
    new THREE.PlaneGeometry(0.9, 0.34),
    new THREE.MeshBasicMaterial({ map: tex, transparent: true }),
  );
}

export function makeSeats(ox, oz) {
  const w = LAYOUT.cellW;
  const d = LAYOUT.cellD;
  return {
    sedoyStool: { x: ox + 1.08, z: oz + 0.18, yaw: -Math.PI / 2, sit: true, seatY: 0.5 },
    stoolS: { x: ox + 0.18, z: oz - 0.4, yaw: 0, sit: true, seatY: 0.5 },
    stoolN: { x: ox + 0.22, z: oz + 0.74, yaw: Math.PI, sit: true, seatY: 0.5 },
    lehaSit: { x: ox + 1.5, z: oz + 1.92, yaw: -Math.PI / 2, sit: true, seatY: 0.62, sitStyle: 'bunk' },
    lehaLie: { x: ox + 1.85, z: oz + 2.15, yaw: Math.PI / 2, lie: true },
    valeraSit: { x: ox - 0.15, z: oz + 1.55, yaw: Math.PI, sit: true, seatY: 0.62, sitStyle: 'bunk' },
    valeraLie: { x: ox - 0.15, z: oz + 2.35, yaw: 0, lie: true },
    hatch: { x: ox - w / 2 + 0.82, z: 3.42, yaw: -Math.PI / 2, lean: true },
    window: { x: ox - 1.35, z: oz + d / 2 - 0.92, yaw: 0 },
    shmonSedoy: { x: ox - 1.2, z: oz + 0.4, yaw: -Math.PI / 2 },
    shmonLeha: { x: ox - 1.2, z: oz + 1.2, yaw: -Math.PI / 2 },
    shmonValera: { x: ox - 1.2, z: oz - 0.5, yaw: -Math.PI / 2 },
    aisle: { x: ox - 1.05, z: oz + 0.08, yaw: Math.PI / 2 },
    doorQueue: { x: ox - 1.35, z: oz - 0.55, yaw: -Math.PI / 2 },
    walkHall: { x: 0.2, z: LAYOUT.corridorLen + 2.8, yaw: 0 },
    walkYard: { x: -2.15, z: LAYOUT.corridorLen + 7.1, yaw: Math.PI * 0.65 },
  };
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
