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
      const hatchStain = new THREE.Mesh(
        new THREE.CircleGeometry(0.045, 7),
        new THREE.MeshStandardMaterial({ color: 0x3a2a18, roughness: 0.85, transparent: true, opacity: 0.55 }),
      );
      hatchStain.rotation.x = -Math.PI / 2;
      hatchStain.position.set(side * 0.12, 1.405, LAYOUT.doorW / 2);
      door.add(hatchStain);
      const hatchCrumb = new THREE.Mesh(
        new THREE.BoxGeometry(0.03, 0.012, 0.022),
        new THREE.MeshStandardMaterial({ color: 0xc4a070, roughness: 0.9 }),
      );
      hatchCrumb.position.set(side * 0.13, 1.41, LAYOUT.doorW / 2 - 0.08);
      hatchCrumb.rotation.y = 0.4;
      door.add(hatchCrumb);
      const hatchGrease = new THREE.Mesh(
        new THREE.CircleGeometry(0.07, 8),
        new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.35, metalness: 0.12, transparent: true, opacity: 0.55 }),
      );
      hatchGrease.rotation.x = -Math.PI / 2;
      hatchGrease.position.set(side * 0.125, 1.392, LAYOUT.doorW / 2 + 0.04);
      door.add(hatchGrease);
      const hatchDrip = new THREE.MeshStandardMaterial({ color: 0x4a3a22, roughness: 0.4, transparent: true, opacity: 0.55 });
      this.box(0.018, 0.16, 0.018, hatchDrip, side * 0.14, 1.3, LAYOUT.doorW / 2 - 0.02, door);
      this.box(0.014, 0.08, 0.014, hatchDrip, side * 0.14, 1.2, LAYOUT.doorW / 2 - 0.02, door);
      const hatchRag = new THREE.Mesh(
        new THREE.BoxGeometry(0.03, 0.28, 0.1),
        new THREE.MeshStandardMaterial({ color: 0x6a5a42, roughness: 0.96 }),
      );
      hatchRag.position.set(side * 0.155, 1.32, LAYOUT.doorW / 2 + 0.1);
      hatchRag.rotation.set(0.12, 0.2, 0.18);
      door.add(hatchRag);
      const hatchCrust = new THREE.Mesh(
        new THREE.BoxGeometry(0.04, 0.01, 0.03),
        new THREE.MeshStandardMaterial({ color: 0xb89058, roughness: 0.92 }),
      );
      hatchCrust.position.set(side * 0.132, 1.4, LAYOUT.doorW / 2 + 0.09);
      hatchCrust.rotation.y = -0.5;
      door.add(hatchCrust);
      const hatchTin = new THREE.Mesh(
        new THREE.CylinderGeometry(0.028, 0.03, 0.055, 8),
        new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
      );
      hatchTin.position.set(side * 0.16, 1.43, LAYOUT.doorW / 2 + 0.12);
      door.add(hatchTin);
      const hatchSock = new THREE.Mesh(
        new THREE.BoxGeometry(0.05, 0.2, 0.04),
        new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
      );
      hatchSock.position.set(side * 0.16, 1.22, LAYOUT.doorW / 2 - 0.12);
      hatchSock.rotation.z = 0.25;
      door.add(hatchSock);
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
    const ceilDamp = new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.92, transparent: true, opacity: 0.72 });
    this.box(1.4, 0.02, 0.55, ceilDamp, -0.4, h - 0.05, 0.8, cell);
    this.box(0.7, 0.02, 0.9, ceilDamp, 0.85, h - 0.05, -0.4, cell);
    this.box(0.35, 0.02, 1.6, ceilDamp, -1.1, h - 0.05, 0.2, cell);
    this.box(0.95, 0.02, 0.72, ceilDamp, -1.55, h - 0.05, doorRelZ + 0.15, cell);
    this.box(0.5, 0.02, 1.15, ceilDamp, -0.15, h - 0.05, doorRelZ - 0.2, cell);
    this.box(0.8, 0.02, 0.4, ceilDamp, 1.4, h - 0.05, doorRelZ + 0.9, cell);
    const conduit = new THREE.Mesh(
      new THREE.CylinderGeometry(0.025, 0.025, 2.4, 6),
      new THREE.MeshStandardMaterial({ color: 0x3a3a38, metalness: 0.4, roughness: 0.55 }),
    );
    conduit.rotation.z = Math.PI / 2;
    conduit.position.set(0.2, h - 0.18, -0.55);
    cell.add(conduit);
    const conduitDoor = new THREE.Mesh(
      new THREE.CylinderGeometry(0.02, 0.02, 2.1, 6),
      new THREE.MeshStandardMaterial({ color: 0x4a4238, metalness: 0.35, roughness: 0.6 }),
    );
    conduitDoor.rotation.x = Math.PI / 2;
    conduitDoor.position.set(-1.55, h - 0.22, doorRelZ + 0.4);
    cell.add(conduitDoor);
    const hangWire = new THREE.Mesh(
      new THREE.CylinderGeometry(0.008, 0.008, 0.55, 5),
      new THREE.MeshStandardMaterial({ color: 0x1c1c18, roughness: 0.9 }),
    );
    hangWire.position.set(-1.35, h - 0.38, doorRelZ + 0.55);
    hangWire.rotation.z = 0.18;
    cell.add(hangWire);
    this.addCellLamp(cell, -1.15, h - 0.14, doorRelZ + 0.35);
    const peel = new THREE.Mesh(
      new THREE.BoxGeometry(0.55, 0.04, 0.28),
      new THREE.MeshStandardMaterial({ color: 0xc8c0b0, roughness: 0.9 }),
    );
    peel.position.set(0.6, h - 0.08, 1.1);
    peel.rotation.z = 0.12;
    cell.add(peel);
    const ceilPeel2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.9, 0.045, 0.48),
      new THREE.MeshStandardMaterial({ color: 0xb8b09c, roughness: 0.94 }),
    );
    ceilPeel2.position.set(-0.12, h - 0.055, 0.32);
    ceilPeel2.rotation.z = -0.1;
    cell.add(ceilPeel2);
    const ceilPeel3 = new THREE.Mesh(
      new THREE.BoxGeometry(0.52, 0.038, 0.72),
      new THREE.MeshStandardMaterial({ color: 0xc4bcac, roughness: 0.92 }),
    );
    ceilPeel3.position.set(0.42, h - 0.06, -0.12);
    ceilPeel3.rotation.y = 0.28;
    cell.add(ceilPeel3);
    const ceilRust = new THREE.MeshStandardMaterial({ color: 0x5a3a28, roughness: 0.88 });
    this.box(0.14, 0.025, 0.62, ceilRust, 0.08, h - 0.04, 0.18, cell);
    this.box(0.1, 0.022, 0.38, ceilRust, -0.38, h - 0.04, 0.52, cell);
    const ceilCord = new THREE.Mesh(
      new THREE.CylinderGeometry(0.01, 0.01, 0.42, 5),
      new THREE.MeshStandardMaterial({ color: 0x2a2a26, roughness: 0.9 }),
    );
    ceilCord.position.set(0.22, h - 0.28, 0.08);
    ceilCord.rotation.z = 0.22;
    cell.add(ceilCord);
    const ceilPeel4 = new THREE.Mesh(
      new THREE.BoxGeometry(0.82, 0.042, 0.6),
      new THREE.MeshStandardMaterial({ color: 0xa89a82, roughness: 0.94 }),
    );
    ceilPeel4.position.set(-0.4, h - 0.048, 0.04);
    ceilPeel4.rotation.z = 0.08;
    cell.add(ceilPeel4);
    const ceilBlotch = new THREE.MeshStandardMaterial({ color: 0x4a3828, roughness: 0.9 });
    this.box(1.05, 0.03, 0.82, ceilBlotch, -0.06, h - 0.03, 0.1, cell);
    this.box(0.48, 0.028, 0.58, ceilBlotch, 0.52, h - 0.03, 0.38, cell);
    this.box(1.15, 0.032, 0.9, ceilBlotch, 0.12, h - 0.03, 0.88, cell);
    this.box(0.72, 0.028, 0.58, ceilBlotch, -0.48, h - 0.03, 0.68, cell);
    const ceilPeel5 = new THREE.Mesh(
      new THREE.BoxGeometry(0.7, 0.045, 0.5),
      new THREE.MeshStandardMaterial({ color: 0xb0a48c, roughness: 0.94 }),
    );
    ceilPeel5.position.set(0.18, h - 0.05, 0.92);
    ceilPeel5.rotation.z = -0.06;
    cell.add(ceilPeel5);
    const ceilRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.44, 0.045),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3c, roughness: 0.96 }),
    );
    ceilRag.position.set(0.12, h - 0.34, 0.58);
    ceilRag.rotation.z = 0.28;
    cell.add(ceilRag);
    const ceilRag2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.32, 0.035),
      new THREE.MeshStandardMaterial({ color: 0x3e342c, roughness: 0.96 }),
    );
    ceilRag2.position.set(-0.28, h - 0.3, -0.18);
    ceilRag2.rotation.z = -0.22;
    cell.add(ceilRag2);
    const flyStrip = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.55, 0.01),
      new THREE.MeshStandardMaterial({ color: 0x3a2a18, roughness: 0.85, transparent: true, opacity: 0.7 }),
    );
    flyStrip.position.set(0.48, h - 0.36, 0.22);
    flyStrip.rotation.z = 0.08;
    cell.add(flyStrip);
    const ceilSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.07, 0.22, 0.045),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    ceilSock.position.set(-0.08, h - 0.28, 0.32);
    ceilSock.rotation.z = 0.35;
    cell.add(ceilSock);
    const ceilTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.055, 0.06, 0.11, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    ceilTin.position.set(0.22, h - 0.58, 0.08);
    cell.add(ceilTin);
    const ceilBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    ceilBottle.position.set(0.48, h - 0.52, 0.18);
    ceilBottle.rotation.z = 0.28;
    cell.add(ceilBottle);
    const ceilHook = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012, 0.012, 0.08, 6),
      new THREE.MeshStandardMaterial({ color: 0x4a4e48, metalness: 0.45, roughness: 0.5 }),
    );
    ceilHook.position.set(0.22, h - 0.5, 0.08);
    ceilHook.rotation.z = 0.35;
    cell.add(ceilHook);
    const ceilDrip = new THREE.MeshStandardMaterial({ color: 0x6a5a40, roughness: 0.35, transparent: true, opacity: 0.45 });
    this.box(0.04, 0.18, 0.04, ceilDrip, 0.08, h - 0.22, 0.18, cell);
    this.box(0.03, 0.1, 0.03, ceilDrip, 0.08, h - 0.38, 0.18, cell);
    const ceilRing = new THREE.MeshStandardMaterial({ color: 0x6a4a32, roughness: 0.82, metalness: 0.12 });
    this.box(0.42, 0.022, 0.42, ceilRing, 0.02, h - 0.038, 0.02, cell);
    const lintelPeel = new THREE.Mesh(
      new THREE.BoxGeometry(0.025, 0.22, 0.48),
      new THREE.MeshStandardMaterial({ color: 0xb8b09c, roughness: 0.94 }),
    );
    lintelPeel.position.set(innerX + 0.1, LAYOUT.doorH + 0.22, doorRelZ);
    lintelPeel.rotation.z = 0.04;
    cell.add(lintelPeel);
    const lintelRust = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.88 });
    this.box(0.02, 0.58, 0.08, lintelRust, innerX + 0.09, LAYOUT.doorH + 0.02, doorRelZ - 0.2, cell);
    this.box(0.02, 0.4, 0.06, lintelRust, innerX + 0.09, LAYOUT.doorH - 0.12, doorRelZ + 0.24, cell);
    const lintelRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.46, 0.18),
      new THREE.MeshStandardMaterial({ color: 0x6a5a46, roughness: 0.95 }),
    );
    lintelRag.position.set(innerX + 0.12, LAYOUT.doorH - 0.08, doorRelZ + 0.06);
    lintelRag.rotation.set(0.1, 0.18, 0.16);
    cell.add(lintelRag);
    const lintelWire = new THREE.Mesh(
      new THREE.BoxGeometry(0.016, 0.016, 0.58),
      new THREE.MeshStandardMaterial({ color: 0x3a3e42, metalness: 0.4, roughness: 0.5 }),
    );
    lintelWire.position.set(innerX + 0.11, LAYOUT.doorH + 0.4, doorRelZ);
    lintelWire.rotation.z = 0.1;
    cell.add(lintelWire);

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
    const doorBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.055, 0.062, 0.26, 8),
      new THREE.MeshStandardMaterial({ color: 0xc4a050, roughness: 0.24, metalness: 0.28, transparent: true, opacity: 0.9 }),
    );
    doorBottle.position.set(ox - w / 2 + 0.92, 0.08, 3.28);
    doorBottle.rotation.z = 1.22;
    doorBottle.rotation.y = 0.35;
    doorBottle.name = 'doorBottle';
    this.group.add(doorBottle);
    const doorStick = new THREE.Mesh(
      new THREE.BoxGeometry(0.035, 1.12, 0.035),
      new THREE.MeshStandardMaterial({ color: 0x5a3a22, roughness: 0.9 }),
    );
    doorStick.position.set(ox - w / 2 + 0.28, 0.52, 3.18);
    doorStick.rotation.z = 0.38;
    doorStick.rotation.y = 0.12;
    doorStick.name = 'doorStick';
    this.group.add(doorStick);
    const doorTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.045, 0.05, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8680, metalness: 0.45, roughness: 0.4 }),
    );
    doorTin.position.set(ox - w / 2 + 0.58, 0.055, 3.08);
    doorTin.name = 'doorTin';
    this.group.add(doorTin);
    const doorSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.09, 0.035, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x3a3a36, roughness: 0.95 }),
    );
    doorSock.position.set(ox - w / 2 + 0.78, 0.04, 3.22);
    doorSock.rotation.y = 0.55;
    doorSock.name = 'doorSock';
    this.group.add(doorSock);
    const doorPaper = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.008, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xc8c0a8, roughness: 0.85 }),
    );
    doorPaper.position.set(ox - w / 2 + 0.98, 0.03, 3.14);
    doorPaper.rotation.y = 0.4;
    doorPaper.name = 'doorPaper';
    this.group.add(doorPaper);
    const doorCig = new THREE.Mesh(
      new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
    );
    doorCig.position.set(ox - w / 2 + 0.32, 0.03, 2.72);
    doorCig.rotation.z = Math.PI / 2;
    doorCig.rotation.y = 0.55;
    doorCig.name = 'doorCig';
    this.group.add(doorCig);
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
      new THREE.BoxGeometry(0.13, 0.007, 0.085),
      new THREE.MeshStandardMaterial({
        color: 0xe8d9b0,
        roughness: 0.82,
        emissive: 0x4a3a12,
        emissiveIntensity: 0.22,
      }),
    );
    const fold = new THREE.Mesh(
      new THREE.BoxGeometry(0.058, 0.006, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xd0c094, roughness: 0.88 }),
    );
    fold.position.set(0.034, 0.005, 0);
    paper.add(fold);
    const ink = new THREE.MeshStandardMaterial({ color: 0x2a2418, roughness: 0.7 });
    for (const [ix, iz, iw] of [
      [-0.02, 0.018, 0.07],
      [-0.018, 0.004, 0.055],
      [-0.01, -0.012, 0.048],
      [0.012, -0.022, 0.03],
    ]) {
      const line = new THREE.Mesh(new THREE.BoxGeometry(iw, 0.002, 0.004), ink);
      line.position.set(ix, 0.005, iz);
      paper.add(line);
    }
    paper.visible = false;
    this.group.add(paper);
    this.storyNote = paper;
    const ash = new THREE.Mesh(
      new THREE.SphereGeometry(0.07, 8, 6),
      new THREE.MeshStandardMaterial({ color: 0x1a1814, roughness: 0.96 }),
    );
    ash.scale.set(1.8, 0.38, 1.35);
    ash.position.set(ox + 0.02, 0.775, oz + 0.18);
    ash.visible = false;
    this.group.add(ash);
    this.storyAsh = ash;
    const char = new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.9 });
    for (const [ax, az, ry] of [
      [0.06, 0.04, 0.5],
      [-0.05, 0.02, -0.4],
      [0.02, -0.05, 1.1],
    ]) {
      const bit = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.012, 0.018), char);
      bit.position.set(ax, 0.02, az);
      bit.rotation.y = ry;
      ash.add(bit);
    }
    const extra = new THREE.Mesh(
      new THREE.BoxGeometry(0.11, 0.045, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xc4a070, roughness: 0.88 }),
    );
    extra.position.set(ox - w / 2 + 0.55, 0.99, 3.42);
    extra.visible = false;
    this.group.add(extra);
    this.storyExtra = extra;
    const tea = new THREE.Group();
    const foil = new THREE.Mesh(
      new THREE.BoxGeometry(0.072, 0.02, 0.11),
      new THREE.MeshStandardMaterial({
        color: 0x2a4a28,
        roughness: 0.48,
        metalness: 0.22,
        emissive: 0x142810,
        emissiveIntensity: 0.38,
      }),
    );
    tea.add(foil);
    const band = new THREE.Mesh(
      new THREE.BoxGeometry(0.074, 0.022, 0.028),
      new THREE.MeshStandardMaterial({
        color: 0xc4a048,
        roughness: 0.42,
        metalness: 0.35,
        emissive: 0x3a2a08,
        emissiveIntensity: 0.28,
      }),
    );
    band.position.z = 0.008;
    tea.add(band);
    const crease = new THREE.Mesh(
      new THREE.BoxGeometry(0.073, 0.003, 0.112),
      new THREE.MeshStandardMaterial({ color: 0x1a3018, roughness: 0.7 }),
    );
    crease.position.y = 0.011;
    tea.add(crease);
    const leaf = new THREE.Mesh(
      new THREE.BoxGeometry(0.018, 0.004, 0.028),
      new THREE.MeshStandardMaterial({ color: 0x1e3a1c, roughness: 0.65, emissive: 0x0a1808, emissiveIntensity: 0.2 }),
    );
    leaf.position.set(0, 0.012, -0.028);
    tea.add(leaf);
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
      wash: new THREE.Vector3(ox + 2.28, 1.125, oz + 2.62),
      bunk: new THREE.Vector3(ox + 1.18, 0.66, oz - 2.02),
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
      this.storyNote.scale.set(1.12, 1.12, 1.12);
      if (this.hatchAnchor) {
        this.hatchAnchor.getWorldPosition(this.storyNote.position);
        this.storyNote.position.x += 0.06;
        this.storyNote.rotation.set(0.18, Math.PI / 2, 0.08);
      } else {
        this.storyNote.position.copy(a.hatch);
        this.storyNote.rotation.set(0.28, Math.PI / 2, 0.04);
      }
    } else if (hold && sim.stash === 'wash') {
      this.storyNote.visible = true;
      this.storyNote.scale.set(1.2, 1.2, 1.2);
      this.storyNote.position.copy(a.wash);
      this.storyNote.rotation.set(0.04, 0.55, 0.06);
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
        this.storyTea.position.x += 0.07;
        this.storyTea.position.y -= 0.03;
        this.storyTea.rotation.set(0.22, Math.PI / 2, 0.1);
      }
    }
    if (this.playerMattress) {
      const peek = hold && sim.stash === 'bunk' && !searching;
      this.playerMattress.rotation.z = searching ? 0.85 : peek ? 0.28 : 0;
      this.playerMattress.position.y = searching ? 0.72 : peek ? 0.58 : 0.5;
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
    const bars = new THREE.MeshStandardMaterial({ color: 0x5a5a5e, metalness: 0.55, roughness: 0.42 });
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
        new THREE.BoxGeometry(0.18, 0.22, 0.012),
        new THREE.MeshBasicMaterial({ color: 0xf0e6c8 }),
      );
      stuffed.position.set(x + 0.36, 1.72, d / 2 - 0.17);
      stuffed.rotation.z = 0.22;
      cell.add(stuffed);
      const stuffed2 = stuffed.clone();
      stuffed2.position.set(x + 0.32, 1.74, d / 2 - 0.168);
      stuffed2.rotation.z = 0.08;
      stuffed2.material = stuffed.material.clone();
      stuffed2.material.color.setHex(0xe4d4b0);
      cell.add(stuffed2);
      const sillRust = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.9, transparent: true, opacity: 0.55 });
      this.box(0.22, 0.18, 0.02, sillRust, x - 0.38, 1.64, d / 2 - 0.14, cell);
      this.box(0.12, 0.28, 0.02, sillRust, x + 0.42, 1.7, d / 2 - 0.14, cell);
      const winRag = new THREE.Mesh(
        new THREE.BoxGeometry(0.16, 0.08, 0.05),
        new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.94 }),
      );
      winRag.position.set(x - 0.28, 1.58, d / 2 - 0.18);
      winRag.rotation.z = 0.4;
      cell.add(winRag);
      const winHang = new THREE.Mesh(
        new THREE.BoxGeometry(0.08, 0.42, 0.04),
        new THREE.MeshStandardMaterial({ color: 0x4a3a32, roughness: 0.96 }),
      );
      winHang.position.set(x - 0.12, 2.42, d / 2 - 0.17);
      winHang.rotation.z = 0.18;
      cell.add(winHang);
      const winTin = new THREE.Mesh(
        new THREE.CylinderGeometry(0.035, 0.04, 0.07, 7),
        new THREE.MeshStandardMaterial({ color: 0x8a8e86, metalness: 0.4, roughness: 0.5 }),
      );
      winTin.position.set(x + 0.18, 1.56, d / 2 - 0.2);
      cell.add(winTin);
      const winBottle = new THREE.Mesh(
        new THREE.CylinderGeometry(0.028, 0.032, 0.12, 8),
        new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
      );
      winBottle.position.set(x + 0.02, 1.58, d / 2 - 0.19);
      winBottle.rotation.z = 1.12;
      cell.add(winBottle);
      const winSock = new THREE.Mesh(
        new THREE.BoxGeometry(0.06, 0.22, 0.05),
        new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
      );
      winSock.position.set(x + 0.38, 1.72, d / 2 - 0.18);
      winSock.rotation.z = -0.28;
      cell.add(winSock);
      const winDrip = new THREE.Mesh(
        new THREE.SphereGeometry(0.02, 5, 4),
        new THREE.MeshStandardMaterial({ color: 0x5a3a22, roughness: 0.75 }),
      );
      winDrip.position.set(x - 0.06, 1.51, d / 2 - 0.18);
      cell.add(winDrip);
      const winStreak = new THREE.Mesh(
        new THREE.BoxGeometry(0.028, 0.24, 0.012),
        new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.9, transparent: true, opacity: 0.62 }),
      );
      winStreak.position.set(x - 0.06, 1.66, d / 2 - 0.145);
      cell.add(winStreak);
      for (let i = -2; i <= 2; i++) {
        this.box(0.022, 1.12, 0.022, bars, x + i * 0.18, 2.15, d / 2 - 0.16, cell);
      }
      for (let j = -1; j <= 1; j++) {
        this.box(0.92, 0.02, 0.02, bars, x, 2.15 + j * 0.34, d / 2 - 0.16, cell);
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
      const flake = new THREE.Mesh(
        new THREE.BoxGeometry(0.042, 0.09, 0.014),
        new THREE.MeshStandardMaterial({ color: 0x3a1810, roughness: 0.88, metalness: 0.2 }),
      );
      flake.position.set(x + (x > 0 ? 0.03 : -0.03), 0.52, z);
      g.add(flake);
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
    const stain = new THREE.Mesh(
      new THREE.CircleGeometry(0.11, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a40, roughness: 0.95, transparent: true, opacity: 0.55 }),
    );
    stain.rotation.x = -Math.PI / 2;
    stain.position.set(0.18, 0.065, 0.08);
    lowerBed.add(stain);
    const slit = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.03, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.92 }),
    );
    slit.position.set(0.12, 0.07, -0.08);
    slit.rotation.y = 0.35;
    lowerBed.add(slit);
    const rag = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.28, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x4a3e34, roughness: 0.95 }),
    );
    rag.position.set(-0.92, 0.28, 0.18);
    rag.rotation.z = 0.28;
    g.add(rag);
    const sock = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.04, 0.07),
      new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.9 }),
    );
    sock.position.set(0.55, 0.09, 0.18);
    sock.rotation.y = -0.4;
    lowerBed.add(sock);
    if (player) {
      const tear = new THREE.Mesh(
        new THREE.BoxGeometry(0.18, 0.04, 0.09),
        new THREE.MeshStandardMaterial({ color: 0x1c1610, roughness: 0.9 }),
      );
      tear.position.set(0.32, 0.075, 0.06);
      tear.rotation.y = -0.2;
      lowerBed.add(tear);
      const foam = new THREE.Mesh(
        new THREE.BoxGeometry(0.1, 0.03, 0.06),
        new THREE.MeshStandardMaterial({ color: 0xc8bca8, roughness: 0.88 }),
      );
      foam.position.set(0.34, 0.095, 0.06);
      lowerBed.add(foam);
      const bunkTin = new THREE.Mesh(
        new THREE.CylinderGeometry(0.032, 0.035, 0.07, 8),
        new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
      );
      bunkTin.position.set(0.78, 0.04, 0.34);
      g.add(bunkTin);
      const bunkBottle = new THREE.Mesh(
        new THREE.CylinderGeometry(0.036, 0.04, 0.16, 8),
        new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
      );
      bunkBottle.position.set(-0.12, 0.07, 0.64);
      bunkBottle.rotation.z = 1.22;
      bunkBottle.rotation.y = 0.35;
      g.add(bunkBottle);
      const frameRust = new THREE.Mesh(
        new THREE.BoxGeometry(0.22, 0.018, 0.09),
        new THREE.MeshStandardMaterial({ color: 0x5a2414, roughness: 0.7, metalness: 0.35 }),
      );
      frameRust.position.set(-0.42, 0.45, 0.38);
      g.add(frameRust);
    }
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
    const grout = new THREE.MeshStandardMaterial({ color: 0x9aa090, roughness: 0.92, transparent: true, opacity: 0.45 });
    this.box(1.2, 0.02, 0.02, grout, -0.05, 0.38, 0.54, g);
    this.box(1.2, 0.02, 0.02, grout, -0.05, 0.72, 0.54, g);
    const rustWash = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.88, transparent: true, opacity: 0.55 });
    this.box(0.22, 0.45, 0.02, rustWash, 0.55, 0.55, 0.54, g);
    this.box(0.14, 0.28, 0.02, rustWash, -0.55, 0.4, 0.54, g);
    this.box(0.18, 0.62, 0.02, rustWash, 0.28, 0.48, 0.54, g);
    this.box(0.1, 0.38, 0.02, rustWash, -0.22, 0.32, 0.54, g);
    const scum = new THREE.MeshStandardMaterial({ color: 0x8a7a62, roughness: 0.92, transparent: true, opacity: 0.7 });
    this.box(0.28, 0.012, 0.22, scum, -0.35, 0.992, 0.42, g);
    this.box(0.16, 0.01, 0.12, scum, -0.28, 0.988, 0.48, g);
    const dampFloor = new THREE.MeshStandardMaterial({ color: 0x4a5248, roughness: 0.35, transparent: true, opacity: 0.55 });
    this.box(0.55, 0.012, 0.4, dampFloor, -0.15, 0.07, 0.22, g);
    this.box(0.38, 0.01, 0.28, dampFloor, 0.22, 0.068, -0.08, g);
    this.box(0.24, 0.01, 0.18, dampFloor, -0.42, 0.068, 0.05, g);
    const soapScum = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.018, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xc8b8a0, roughness: 0.7 }),
    );
    soapScum.position.set(-0.48, 0.08, 0.32);
    soapScum.rotation.y = 0.4;
    g.add(soapScum);
    const washHang = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.42, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3c, roughness: 0.95 }),
    );
    washHang.position.set(0.62, 0.88, 0.42);
    washHang.rotation.z = 0.18;
    g.add(washHang);
    const washSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.22, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    washSock.position.set(0.48, 0.42, 0.08);
    washSock.rotation.set(0.18, 0.12, 0.32);
    g.add(washSock);
    const washTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.038, 0.08, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    washTin.position.set(-0.42, 0.08, -0.08);
    g.add(washTin);
    const washBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    washBottle.position.set(-0.18, 0.05, 0.02);
    washBottle.rotation.z = 1.18;
    g.add(washBottle);
    const washScrap = new THREE.Mesh(
      new THREE.BoxGeometry(0.14, 0.008, 0.1),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    washScrap.position.set(0.28, 0.075, 0.18);
    washScrap.rotation.y = 0.55;
    g.add(washScrap);
    const soapWash = new THREE.Mesh(
      new THREE.BoxGeometry(0.07, 0.025, 0.045),
      new THREE.MeshStandardMaterial({ color: 0xd8d0c0, roughness: 0.45 }),
    );
    soapWash.position.set(-0.18, 1.13, 0.22);
    soapWash.scale.set(1.6, 1.4, 1.6);
    g.add(soapWash);
    const mugWash = new THREE.Mesh(
      new THREE.CylinderGeometry(0.042, 0.038, 0.11, 8),
      new THREE.MeshStandardMaterial({ color: 0xc4b49a, roughness: 0.6 }),
    );
    mugWash.position.set(-0.42, 1.16, 0.18);
    g.add(mugWash);
    const pasteTube = new THREE.Mesh(
      new THREE.CylinderGeometry(0.016, 0.02, 0.12, 6),
      new THREE.MeshStandardMaterial({ color: 0xe8e4d8, roughness: 0.55 }),
    );
    pasteTube.position.set(-0.12, 1.14, 0.28);
    pasteTube.rotation.z = 1.15;
    pasteTube.rotation.y = 0.35;
    g.add(pasteTube);
    const pasteCap = new THREE.Mesh(
      new THREE.CylinderGeometry(0.018, 0.018, 0.022, 6),
      new THREE.MeshStandardMaterial({ color: 0x2a5a38, roughness: 0.5 }),
    );
    pasteCap.position.set(-0.05, 1.155, 0.32);
    pasteCap.rotation.z = 1.15;
    pasteCap.rotation.y = 0.35;
    g.add(pasteCap);
    const pasteBlob = new THREE.Mesh(
      new THREE.SphereGeometry(0.018, 6, 5),
      new THREE.MeshStandardMaterial({ color: 0xf2efe6, roughness: 0.35 }),
    );
    pasteBlob.position.set(-0.22, 1.128, 0.2);
    pasteBlob.scale.set(1.4, 0.45, 1.1);
    g.add(pasteBlob);
    const ragWash = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.03, 0.14),
      new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.94 }),
    );
    ragWash.position.set(0.18, 1.125, 0.02);
    ragWash.rotation.set(0.04, 0.55, 0.08);
    g.add(ragWash);
    const tooth = new THREE.Mesh(
      new THREE.CylinderGeometry(0.007, 0.008, 0.11, 5),
      new THREE.MeshStandardMaterial({ color: 0xc8c0b0, roughness: 0.55 }),
    );
    tooth.position.set(-0.42, 1.2, 0.18);
    tooth.rotation.z = 0.35;
    g.add(tooth);
    const toothHead = new THREE.Mesh(
      new THREE.BoxGeometry(0.018, 0.012, 0.028),
      new THREE.MeshStandardMaterial({ color: 0xe8e0d4, roughness: 0.7 }),
    );
    toothHead.position.set(-0.38, 1.255, 0.18);
    toothHead.rotation.z = 0.35;
    g.add(toothHead);
    const bottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.022, 0.026, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a4a38, roughness: 0.35, metalness: 0.08 }),
    );
    bottle.position.set(0.38, 1.18, -0.08);
    g.add(bottle);
    const bottleCap = new THREE.Mesh(
      new THREE.CylinderGeometry(0.016, 0.016, 0.018, 8),
      new THREE.MeshStandardMaterial({ color: 0x1a2a20, roughness: 0.5 }),
    );
    bottleCap.position.set(0.38, 1.258, -0.08);
    g.add(bottleCap);
    const hangTowel = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.38, 0.03),
      new THREE.MeshStandardMaterial({ color: 0x8a7a68, roughness: 0.94 }),
    );
    hangTowel.position.set(0.62, 0.72, 0.12);
    hangTowel.rotation.z = 0.12;
    g.add(hangTowel);
    const mold = new THREE.MeshStandardMaterial({ color: 0x4a5248, roughness: 0.9, transparent: true, opacity: 0.55 });
    this.box(0.18, 0.22, 0.02, mold, 0.62, 0.28, 0.54, g);
    this.box(0.12, 0.14, 0.02, mold, -0.48, 0.22, 0.54, g);
    const printMat = new THREE.MeshStandardMaterial({ color: 0x3a3a32, roughness: 0.25, metalness: 0.08, transparent: true, opacity: 0.35 });
    for (const [px, pz, ry] of [
      [-0.12, -0.42, 0.4],
      [0.08, -0.58, -0.2],
      [0.22, -0.38, 0.7],
    ]) {
      const print = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.008, 0.18), printMat);
      print.position.set(px, 0.045, pz);
      print.rotation.y = ry;
      g.add(print);
    }
    const wetTile = new THREE.Mesh(
      new THREE.CircleGeometry(0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8880, roughness: 0.2, metalness: 0.08, transparent: true, opacity: 0.45 }),
    );
    wetTile.rotation.x = -Math.PI / 2;
    wetTile.position.set(0.02, 1.112, 0.08);
    g.add(wetTile);
    const stallGrout = new THREE.MeshStandardMaterial({ color: 0x7a786c, roughness: 0.95, transparent: true, opacity: 0.55 });
    this.box(0.9, 0.006, 0.012, stallGrout, -0.08, 1.112, 0.05, g);
    this.box(0.9, 0.006, 0.012, stallGrout, -0.08, 1.112, 0.28, g);
    this.box(0.012, 0.006, 0.55, stallGrout, -0.22, 1.112, 0.12, g);
    this.box(0.012, 0.006, 0.55, stallGrout, 0.18, 1.112, 0.12, g);
    const rustStall = new THREE.Mesh(
      new THREE.CircleGeometry(0.09, 7),
      new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.9, transparent: true, opacity: 0.5 }),
    );
    rustStall.rotation.x = -Math.PI / 2;
    rustStall.position.set(-0.32, 1.114, 0.32);
    g.add(rustStall);
    const brush = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012, 0.012, 0.16, 6),
      new THREE.MeshStandardMaterial({ color: 0x3a4a38, roughness: 0.7 }),
    );
    brush.position.set(0.28, 1.13, 0.22);
    brush.rotation.z = 1.2;
    g.add(brush);
    const floorRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.2, 0.025, 0.12),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.94 }),
    );
    floorRag.position.set(0.18, 0.1, -0.12);
    floorRag.rotation.y = 0.35;
    g.add(floorRag);
    const floorWet = new THREE.Mesh(
      new THREE.CircleGeometry(0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8880, roughness: 0.2, metalness: 0.08, transparent: true, opacity: 0.4 }),
    );
    floorWet.rotation.x = -Math.PI / 2;
    floorWet.position.set(0.05, 0.108, -0.18);
    g.add(floorWet);
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
    const soot = new THREE.Mesh(
      new THREE.CircleGeometry(0.11, 10),
      new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.95, transparent: true, opacity: 0.55 }),
    );
    soot.rotation.x = -Math.PI / 2;
    soot.position.set(-0.15, 0.748, 0.15);
    cell.add(soot);
    const ashPile = new THREE.Mesh(
      new THREE.SphereGeometry(0.04, 6, 5),
      new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 1 }),
    );
    ashPile.scale.set(1.4, 0.35, 1.1);
    ashPile.position.set(-0.28, 0.76, 0.28);
    cell.add(ashPile);
    const charPaper = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.008, 0.08),
      new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.92 }),
    );
    charPaper.position.set(-0.02, 0.752, 0.32);
    charPaper.rotation.y = 0.6;
    cell.add(charPaper);
    const kettleRust = new THREE.Mesh(
      new THREE.CircleGeometry(0.035, 7),
      new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.8, transparent: true, opacity: 0.55 }),
    );
    kettleRust.rotation.x = -Math.PI / 2;
    kettleRust.position.set(-0.12, 0.922, 0.12);
    cell.add(kettleRust);
    const kettleTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.035, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    kettleTin.position.set(-0.38, 0.79, 0.02);
    cell.add(kettleTin);
    const kettleSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.18, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    kettleSock.position.set(-0.48, 0.78, 0.22);
    kettleSock.rotation.set(1.2, 0.15, 0.28);
    cell.add(kettleSock);
    const kettleBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    kettleBottle.position.set(-0.34, 0.78, 0.32);
    kettleBottle.rotation.z = 1.18;
    kettleBottle.rotation.y = 0.42;
    cell.add(kettleBottle);
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
    const mug2 = mug.clone();
    mug2.position.set(0.42, 0.78, -0.02);
    cell.add(mug2);
    const sugar = new THREE.Mesh(
      new THREE.BoxGeometry(0.07, 0.05, 0.07),
      new THREE.MeshStandardMaterial({ color: 0xe8e0d0, roughness: 0.75 }),
    );
    sugar.position.set(-0.02, 0.77, 0.28);
    cell.add(sugar);
    const spoon = new THREE.Mesh(
      new THREE.BoxGeometry(0.14, 0.012, 0.03),
      new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.55, roughness: 0.4 }),
    );
    spoon.position.set(0.22, 0.755, 0.22);
    spoon.rotation.y = 0.6;
    cell.add(spoon);
    const crust = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.04, 0.08),
      new THREE.MeshStandardMaterial({ color: 0xc4a070, roughness: 0.85 }),
    );
    crust.position.set(0.58, 0.77, 0.08);
    crust.rotation.y = -0.3;
    cell.add(crust);
    const stain = new THREE.Mesh(
      new THREE.CircleGeometry(0.09, 7),
      new THREE.MeshStandardMaterial({ color: 0x6a5a40, roughness: 0.9, transparent: true, opacity: 0.45 }),
    );
    stain.rotation.x = -Math.PI / 2;
    stain.position.set(0.08, 0.748, 0.18);
    cell.add(stain);
    const ashtray = new THREE.Mesh(
      new THREE.CylinderGeometry(0.04, 0.038, 0.025, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.7 }),
    );
    ashtray.position.set(0.48, 0.76, 0.28);
    cell.add(ashtray);
    const butt = new THREE.Mesh(
      new THREE.CylinderGeometry(0.008, 0.01, 0.04, 6),
      new THREE.MeshStandardMaterial({ color: 0xc8b090, roughness: 0.8 }),
    );
    butt.position.set(0.49, 0.78, 0.29);
    butt.rotation.z = 0.9;
    cell.add(butt);
    const onion = new THREE.Mesh(
      new THREE.SphereGeometry(0.035, 8, 6),
      new THREE.MeshStandardMaterial({ color: 0xc8b070, roughness: 0.7 }),
    );
    onion.position.set(-0.18, 0.78, 0.12);
    cell.add(onion);
    const salt = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, 0.07, 0.04),
      new THREE.MeshStandardMaterial({ color: 0xd8d0c4, roughness: 0.85 }),
    );
    salt.position.set(0.32, 0.79, -0.12);
    cell.add(salt);
    const matchbox = new THREE.Mesh(
      new THREE.BoxGeometry(0.06, 0.018, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x8a2a22, roughness: 0.7 }),
    );
    matchbox.position.set(0.08, 0.752, 0.32);
    matchbox.rotation.y = 0.35;
    cell.add(matchbox);
    const teaRing = new THREE.Mesh(
      new THREE.CircleGeometry(0.045, 10),
      new THREE.MeshStandardMaterial({ color: 0x5a3a22, roughness: 0.85, transparent: true, opacity: 0.55 }),
    );
    teaRing.rotation.x = -Math.PI / 2;
    teaRing.position.set(0.18, 0.748, -0.02);
    cell.add(teaRing);
    const crumb = new THREE.MeshStandardMaterial({ color: 0xb89058, roughness: 0.9 });
    this.box(0.04, 0.012, 0.03, crumb, 0.62, 0.752, 0.18, cell);
    this.box(0.03, 0.01, 0.025, crumb, 0.52, 0.751, 0.02, cell);
    this.box(0.035, 0.011, 0.028, crumb, 0.28, 0.751, 0.32, cell);
    const foilWrap = new THREE.Mesh(
      new THREE.BoxGeometry(0.07, 0.02, 0.05),
      new THREE.MeshStandardMaterial({ color: 0xa8b090, metalness: 0.35, roughness: 0.45 }),
    );
    foilWrap.position.set(-0.32, 0.752, 0.28);
    foilWrap.rotation.y = -0.5;
    cell.add(foilWrap);
    const tableCig = new THREE.Mesh(
      new THREE.CylinderGeometry(0.008, 0.009, 0.07, 6),
      new THREE.MeshStandardMaterial({ color: 0xd8d0c0, roughness: 0.7 }),
    );
    tableCig.rotation.z = Math.PI / 2;
    tableCig.rotation.y = 0.4;
    tableCig.position.set(0.42, 0.758, 0.08);
    cell.add(tableCig);
    const tableStain = new THREE.Mesh(
      new THREE.CircleGeometry(0.06, 10),
      new THREE.MeshStandardMaterial({ color: 0x4a3020, roughness: 0.9, transparent: true, opacity: 0.45 }),
    );
    tableStain.rotation.x = -Math.PI / 2;
    tableStain.position.set(0.05, 0.748, 0.22);
    cell.add(tableStain);
    const tableTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.035, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    tableTin.position.set(-0.08, 0.79, 0.38);
    cell.add(tableTin);
    const tableBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.028, 0.032, 0.12, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    tableBottle.position.set(0.22, 0.78, 0.22);
    tableBottle.rotation.z = 1.18;
    cell.add(tableBottle);
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
      const stoolScratch = new THREE.Mesh(
        new THREE.CircleGeometry(0.055, 6),
        new THREE.MeshStandardMaterial({ color: 0x3a2414, roughness: 0.95, transparent: true, opacity: 0.5 }),
      );
      stoolScratch.rotation.x = -Math.PI / 2;
      stoolScratch.position.set(x + 0.04, 0.478, z - 0.03);
      cell.add(stoolScratch);
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
    const doorRelZ = 3.4 - 5.2;
    const rope = new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.8 });
    this.box(2.4, 0.012, 0.012, rope, -0.4, 1.92, 2.9, cell);
    const wallCal = cellSign('СУТКИ');
    wallCal.scale.setScalar(0.85);
    wallCal.position.set(0.15, 1.88, LAYOUT.cellD / 2 - 0.16);
    wallCal.rotation.y = Math.PI;
    cell.add(wallCal);
    const dadoWin = new THREE.MeshStandardMaterial({ color: 0x3a524c, roughness: 0.45, transparent: true, opacity: 0.42 });
    this.box(1.4, 0.7, 0.02, dadoWin, 0.15, 0.72, LAYOUT.cellD / 2 - 0.14, cell);
    this.box(0.7, 0.45, 0.02, dadoWin, 0.55, 0.5, LAYOUT.cellD / 2 - 0.14, cell);
    const winShelf = new THREE.MeshStandardMaterial({ color: 0x5a4a38, roughness: 0.88 });
    this.box(0.42, 0.035, 0.14, winShelf, 0.2, 0.95, LAYOUT.cellD / 2 - 0.22, cell);
    const winMug = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.03, 0.06, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.55, metalness: 0.2 }),
    );
    winMug.position.set(0.12, 0.99, LAYOUT.cellD / 2 - 0.22);
    cell.add(winMug);
    const winNews = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.14, 0.03),
      new THREE.MeshStandardMaterial({ color: 0xd8d0b8, roughness: 0.92 }),
    );
    winNews.position.set(0.32, 1.06, LAYOUT.cellD / 2 - 0.2);
    winNews.rotation.set(0.1, 0.2, 0.15);
    cell.add(winNews);
    const winTicks = wallScratch('||||');
    winTicks.scale.set(0.9, 0.9, 0.9);
    winTicks.position.set(0.55, 0.62, LAYOUT.cellD / 2 - 0.15);
    winTicks.rotation.y = Math.PI;
    cell.add(winTicks);
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
    const extraCloth = new THREE.Mesh(
      new THREE.BoxGeometry(0.32, 0.5, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x4a5a48, roughness: 0.92 }),
    );
    extraCloth.position.set(0.85, 1.7, 2.9);
    extraCloth.rotation.z = 0.12;
    cell.add(extraCloth);
    const sockLine = extraCloth.clone();
    sockLine.scale.set(0.35, 0.55, 1);
    sockLine.material = new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.94 });
    sockLine.position.set(-1.55, 1.55, 2.9);
    cell.add(sockLine);
    const shoeMat = new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.9 });
    for (const [sx, sz, ry] of [
      [1.15, 1.55, 0.4],
      [1.32, 1.62, 0.35],
      [0.35, 1.85, -0.2],
      [0.52, 1.92, -0.15],
    ]) {
      const shoe = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.07, 0.1), shoeMat);
      shoe.position.set(sx, 0.08, sz);
      shoe.rotation.y = ry;
      cell.add(shoe);
    }
    const bunkRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.42, 0.03, 0.28),
      new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.95 }),
    );
    bunkRag.position.set(0.7, 0.04, 1.45);
    bunkRag.rotation.y = 0.35;
    cell.add(bunkRag);
    const bunkBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.16, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x4a4030, roughness: 0.88 }),
    );
    bunkBox.position.set(1.55, 0.12, 1.7);
    bunkBox.rotation.y = 0.2;
    cell.add(bunkBox);
    const aisleMud = new THREE.MeshStandardMaterial({ color: 0x3a2a18, roughness: 0.98 });
    this.box(0.55, 0.02, 0.32, aisleMud, -0.95, 0.055, 0.12, cell);
    this.box(0.38, 0.018, 0.24, aisleMud, -0.72, 0.052, 0.85, cell);
    this.box(0.48, 0.018, 0.28, aisleMud, -1.05, 0.052, -0.55, cell);
    this.box(0.32, 0.016, 0.4, aisleMud, -0.4, 0.05, 1.15, cell);
    const aislePaper = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.012, 0.12),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    aislePaper.position.set(-0.82, 0.07, 0.42);
    aislePaper.rotation.y = 0.55;
    cell.add(aislePaper);
    const aisleRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.03, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x4a3c32, roughness: 0.95 }),
    );
    aisleRag.position.set(-0.55, 0.07, -0.35);
    aisleRag.rotation.y = -0.4;
    cell.add(aisleRag);
    const winPeel = new THREE.MeshStandardMaterial({ color: 0x6a5240, roughness: 0.92 });
    this.box(0.55, 0.22, 0.03, winPeel, -0.35, 1.55, LAYOUT.cellD / 2 - 0.14, cell);
    this.box(0.32, 0.16, 0.03, winPeel, 0.72, 1.38, LAYOUT.cellD / 2 - 0.14, cell);
    this.box(0.18, 0.55, 0.03, winPeel, 0.95, 0.85, LAYOUT.cellD / 2 - 0.14, cell);
    const winAisleHang = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.38, 0.04),
      new THREE.MeshStandardMaterial({ color: 0x4a3c32, roughness: 0.95 }),
    );
    winAisleHang.position.set(-0.15, 1.12, LAYOUT.cellD / 2 - 0.16);
    winAisleHang.rotation.z = 0.18;
    cell.add(winAisleHang);
    const aisleTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.038, 0.08, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    aisleTin.position.set(-0.62, 0.08, 0.22);
    cell.add(aisleTin);
    const aisleBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    aisleBottle.position.set(-0.38, 0.05, 0.08);
    aisleBottle.rotation.z = 1.18;
    cell.add(aisleBottle);
    const handsBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.045, 0.05, 0.2, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.9 }),
    );
    handsBottle.position.set(1.28, 0.1, 1.02);
    handsBottle.rotation.z = 1.15;
    handsBottle.rotation.y = 0.4;
    cell.add(handsBottle);
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
    const calRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.38, 0.025, 0.26),
      new THREE.MeshStandardMaterial({ color: 0x6a5a48, roughness: 0.95 }),
    );
    calRag.position.set(-1.45, 0.04, 0.95);
    calRag.rotation.y = 0.35;
    cell.add(calRag);
    const calPail = new THREE.Mesh(
      new THREE.CylinderGeometry(0.11, 0.09, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a7068, roughness: 0.55, metalness: 0.25 }),
    );
    calPail.position.set(-LAYOUT.cellW / 2 + 0.28, 0.14, 0.58);
    cell.add(calPail);
    const calPailRust = new THREE.MeshStandardMaterial({ color: 0x5a2a18, roughness: 0.85, metalness: 0.15 });
    this.box(0.04, 0.08, 0.03, calPailRust, -LAYOUT.cellW / 2 + 0.36, 0.16, 0.52, cell);
    this.box(0.03, 0.06, 0.03, calPailRust, -LAYOUT.cellW / 2 + 0.22, 0.12, 0.62, cell);
    const calSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.22, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    calSock.position.set(-LAYOUT.cellW / 2 + 0.24, 0.58, 0.72);
    calSock.rotation.set(0.18, 0.1, 0.32);
    cell.add(calSock);
    const calTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.038, 0.08, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    calTin.position.set(-LAYOUT.cellW / 2 + 0.42, 0.07, 0.48);
    cell.add(calTin);
    const calBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    calBottle.position.set(-LAYOUT.cellW / 2 + 0.52, 0.05, 0.68);
    calBottle.rotation.z = 1.18;
    cell.add(calBottle);
    const calScrap = new THREE.Mesh(
      new THREE.BoxGeometry(0.14, 0.008, 0.1),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    calScrap.position.set(-LAYOUT.cellW / 2 + 0.48, 0.055, 0.92);
    calScrap.rotation.y = 0.45;
    cell.add(calScrap);
    const calWet = new THREE.Mesh(
      new THREE.CircleGeometry(0.28, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a423c, roughness: 0.18, metalness: 0.12, transparent: true, opacity: 0.45 }),
    );
    calWet.rotation.x = -Math.PI / 2;
    calWet.position.set(-LAYOUT.cellW / 2 + 0.34, 0.042, 0.68);
    cell.add(calWet);
    const calFloorRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.03, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x4a3a32, roughness: 0.94 }),
    );
    calFloorRag.position.set(-LAYOUT.cellW / 2 + 0.4, 0.04, 0.78);
    calFloorRag.rotation.y = -0.5;
    cell.add(calFloorRag);
    const calButt = new THREE.MeshStandardMaterial({ color: 0x2a2218, roughness: 0.82 });
    for (const [bx, bz] of [
      [-1.32, 0.82],
      [-1.52, 1.08],
    ]) {
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.01, 0.012, 0.035, 5), calButt);
      c.rotation.z = Math.PI / 2;
      c.position.set(bx, 0.055, bz);
      cell.add(c);
    }
    const dampCal = new THREE.MeshStandardMaterial({ color: 0x4a524c, roughness: 0.4, transparent: true, opacity: 0.5 });
    this.box(0.02, 0.85, 0.42, dampCal, -LAYOUT.cellW / 2 + 0.21, 0.72, 1.1, cell);
    this.box(0.02, 0.45, 0.22, dampCal, -LAYOUT.cellW / 2 + 0.21, 0.48, 1.28, cell);
    const calShelf = new THREE.MeshStandardMaterial({ color: 0x5a4a38, roughness: 0.88 });
    this.box(0.16, 0.035, 0.42, calShelf, -LAYOUT.cellW / 2 + 0.32, 0.92, 1.1, cell);
    const chalkStick = new THREE.Mesh(
      new THREE.CylinderGeometry(0.008, 0.009, 0.055, 6),
      new THREE.MeshStandardMaterial({ color: 0xe8e0d0, roughness: 0.78 }),
    );
    chalkStick.rotation.z = Math.PI / 2;
    chalkStick.rotation.y = 0.35;
    chalkStick.position.set(-LAYOUT.cellW / 2 + 0.34, 0.955, 1.18);
    cell.add(chalkStick);
    const chalkDust = new THREE.Mesh(
      new THREE.CircleGeometry(0.035, 6),
      new THREE.MeshStandardMaterial({ color: 0xd8d0c0, roughness: 0.95, transparent: true, opacity: 0.45 }),
    );
    chalkDust.rotation.x = -Math.PI / 2;
    chalkDust.position.set(-LAYOUT.cellW / 2 + 0.36, 0.94, 1.18);
    cell.add(chalkDust);
    const powderBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.055, 0.07, 0.04),
      new THREE.MeshStandardMaterial({ color: 0xd4c8b4, roughness: 0.88 }),
    );
    powderBox.position.set(-LAYOUT.cellW / 2 + 0.34, 0.975, 1.06);
    powderBox.rotation.y = 0.18;
    cell.add(powderBox);
    const powderLid = new THREE.Mesh(
      new THREE.BoxGeometry(0.058, 0.01, 0.043),
      new THREE.MeshStandardMaterial({ color: 0xb8aa94, roughness: 0.82 }),
    );
    powderLid.position.set(-LAYOUT.cellW / 2 + 0.34, 1.012, 1.06);
    powderLid.rotation.y = 0.18;
    cell.add(powderLid);
    const comb = new THREE.Mesh(
      new THREE.BoxGeometry(0.09, 0.008, 0.022),
      new THREE.MeshStandardMaterial({ color: 0x2a221c, roughness: 0.7 }),
    );
    comb.position.set(-LAYOUT.cellW / 2 + 0.33, 0.948, 0.9);
    comb.rotation.y = -0.45;
    cell.add(comb);
    const chalkTallies = wallScratch('|||| ||');
    chalkTallies.scale.set(0.7, 0.7, 0.7);
    chalkTallies.position.set(-LAYOUT.cellW / 2 + 0.22, 1.18, 1.02);
    chalkTallies.rotation.y = Math.PI / 2;
    cell.add(chalkTallies);
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
    doorPail.position.set(-1.95, 0.16, doorRelZ + 0.58);
    cell.add(doorPail);
    const korm = wallScratch('КОРМ');
    korm.scale.set(0.9, 0.9, 0.9);
    korm.position.set(-LAYOUT.cellW / 2 + 0.22, 1.28, doorRelZ + 0.92);
    korm.rotation.y = Math.PI / 2;
    cell.add(korm);
    const hatchRust = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.88 });
    this.box(0.02, 0.55, 0.7, hatchRust, -LAYOUT.cellW / 2 + 0.2, 1.5, 3.15, cell);
    this.box(0.02, 0.28, 0.35, hatchRust, -LAYOUT.cellW / 2 + 0.2, 1.22, 3.35, cell);
    this.box(0.02, 0.85, 0.12, hatchRust, -LAYOUT.cellW / 2 + 0.2, 1.35, doorRelZ - 0.42, cell);
    this.box(0.02, 0.4, 0.18, hatchRust, -LAYOUT.cellW / 2 + 0.2, 0.55, doorRelZ + 0.28, cell);
    this.box(0.02, 0.22, 0.22, hatchRust, -LAYOUT.cellW / 2 + 0.2, 1.08, 3.22, cell);
    const hatchSmear = new THREE.Mesh(
      new THREE.CircleGeometry(0.11, 8),
      new THREE.MeshStandardMaterial({ color: 0x5a4028, roughness: 0.4, metalness: 0.08, transparent: true, opacity: 0.5 }),
    );
    hatchSmear.rotation.y = Math.PI / 2;
    hatchSmear.position.set(-LAYOUT.cellW / 2 + 0.21, 1.18, 3.28);
    cell.add(hatchSmear);
    const hatchCloth = new THREE.Mesh(
      new THREE.BoxGeometry(0.03, 0.34, 0.12),
      new THREE.MeshStandardMaterial({ color: 0x4a3a2c, roughness: 0.96 }),
    );
    hatchCloth.position.set(-LAYOUT.cellW / 2 + 0.24, 1.28, 3.48);
    hatchCloth.rotation.set(0.08, 0.12, 0.22);
    cell.add(hatchCloth);
    const doorWet = new THREE.Mesh(
      new THREE.CircleGeometry(0.42, 10),
      new THREE.MeshStandardMaterial({ color: 0x3a3830, roughness: 0.2, metalness: 0.1 }),
    );
    doorWet.rotation.x = -Math.PI / 2;
    doorWet.position.set(-LAYOUT.cellW / 2 + 0.7, 0.04, doorRelZ);
    cell.add(doorWet);
    const doorWire = new THREE.Mesh(
      new THREE.CylinderGeometry(0.01, 0.01, 0.7, 5),
      new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.85 }),
    );
    doorWire.position.set(-LAYOUT.cellW / 2 + 0.28, 2.15, doorRelZ + 0.35);
    doorWire.rotation.z = 0.45;
    cell.add(doorWire);

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
    const radWet = new THREE.MeshStandardMaterial({ color: 0x3a4038, roughness: 0.18, metalness: 0.35 });
    this.box(0.08, 0.36, 0.11, radWet, -1.15, 0.38, LAYOUT.cellD / 2 - 0.19, cell);
    const radRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.02, 0.14),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.95 }),
    );
    radRag.position.set(-1.48, 0.61, LAYOUT.cellD / 2 - 0.28);
    radRag.rotation.z = 0.35;
    cell.add(radRag);
    const radSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.22, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    radSock.position.set(-1.22, 0.58, LAYOUT.cellD / 2 - 0.32);
    radSock.rotation.set(0.2, 0.12, 0.28);
    cell.add(radSock);
    const radPaper = new THREE.Mesh(
      new THREE.BoxGeometry(0.14, 0.008, 0.1),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    radPaper.position.set(-1.42, 0.055, LAYOUT.cellD / 2 - 0.48);
    radPaper.rotation.y = 0.45;
    cell.add(radPaper);
    const radRust = new THREE.MeshStandardMaterial({ color: 0x5a2a18, roughness: 0.85, metalness: 0.15 });
    this.box(0.18, 0.28, 0.04, radRust, -1.52, 0.42, LAYOUT.cellD / 2 - 0.16, cell);
    this.box(0.12, 0.16, 0.03, radRust, -1.08, 0.28, LAYOUT.cellD / 2 - 0.16, cell);
    const dripMat = new THREE.MeshStandardMaterial({ color: 0x6a7a78, roughness: 0.15, metalness: 0.2, transparent: true, opacity: 0.55 });
    for (const [dx, dy] of [
      [-1.15, 0.12],
      [-1.12, 0.22],
      [-1.18, 0.05],
    ]) {
      const drop = new THREE.Mesh(new THREE.SphereGeometry(0.012, 6, 4), dripMat);
      drop.position.set(dx, dy, LAYOUT.cellD / 2 - 0.28);
      cell.add(drop);
    }
    const radPuddle = new THREE.Mesh(
      new THREE.CircleGeometry(0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a4038, roughness: 0.18, metalness: 0.22 }),
    );
    radPuddle.rotation.x = -Math.PI / 2;
    radPuddle.position.set(-1.16, 0.045, LAYOUT.cellD / 2 - 0.55);
    cell.add(radPuddle);
    const tin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.038, 0.08, 8),
      new THREE.MeshStandardMaterial({ color: 0x7a7e72, metalness: 0.45, roughness: 0.4 }),
    );
    tin.position.set(-1.58, 0.64, LAYOUT.cellD / 2 - 0.28);
    cell.add(tin);
    const radBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    radBottle.position.set(-1.02, 0.05, LAYOUT.cellD / 2 - 0.62);
    radBottle.rotation.z = 1.18;
    cell.add(radBottle);
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
    const shelfRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.22, 0.03),
      new THREE.MeshStandardMaterial({ color: 0x5a4a38, roughness: 0.95 }),
    );
    shelfRag.position.set(2.62, 1.22, 0.42);
    shelfRag.rotation.z = 0.18;
    cell.add(shelfRag);
    const matches = new THREE.Mesh(
      new THREE.BoxGeometry(0.06, 0.02, 0.035),
      new THREE.MeshStandardMaterial({ color: 0x8a2020, roughness: 0.7 }),
    );
    matches.position.set(2.42, 1.38, 0.44);
    cell.add(matches);
    const shelfMug = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.028, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8070, roughness: 0.65 }),
    );
    shelfMug.position.set(2.68, 1.42, 0.36);
    cell.add(shelfMug);
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
    const gateDado = new THREE.MeshStandardMaterial({ color: 0x3a6a62, roughness: 0.75 });
    this.box(wing - 0.1, 1.15, 0.04, gateDado, -wingX, 0.57, wallZ + 0.18, g);
    this.box(wing - 0.1, 1.15, 0.04, gateDado, wingX, 0.57, wallZ + 0.18, g);
    const gatePeel = new THREE.MeshStandardMaterial({ color: 0x6a5240, roughness: 0.92 });
    const gateDamp = new THREE.MeshStandardMaterial({ color: 0x5a5850, roughness: 0.62, transparent: true, opacity: 0.42 });
    this.box(0.12, 1.15, 0.03, gateDamp, -2.55, 2.12, wallZ + 0.18, g);
    this.box(0.1, 1.05, 0.03, gateDamp, 2.72, 2.18, wallZ + 0.18, g);
    this.box(0.1, 0.22, 0.03, gatePeel, -1.85, 2.52, wallZ + 0.18, g);
    this.box(0.11, 0.18, 0.03, gatePeel, 2.18, 1.88, wallZ + 0.18, g);
    this.box(1.2, 0.58, 0.03, gatePeel, -1.55, 2.78, wallZ + 0.18, g);
    this.box(0.92, 0.45, 0.03, gatePeel, 1.48, 2.7, wallZ + 0.18, g);
    this.box(0.62, 0.32, 0.03, gatePeel, 0.05, 2.92, wallZ + 0.18, g);
    const gateLintelRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.24, 0.52, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x4a3a32, roughness: 0.95 }),
    );
    gateLintelRag.position.set(0.58, 2.38, wallZ + 0.3);
    gateLintelRag.rotation.z = 0.2;
    g.add(gateLintelRag);
    const gateFuse = new THREE.MeshStandardMaterial({ color: 0x3a4238, metalness: 0.38, roughness: 0.52 });
    this.box(0.32, 0.42, 0.08, gateFuse, -3.15, 1.55, wallZ + 0.22, g);
    this.box(0.08, 0.06, 0.04, gateFuse, -3.15, 1.68, wallZ + 0.28, g);
    this.box(0.28, 0.36, 0.08, gateFuse, 3.2, 1.52, wallZ + 0.22, g);
    const gateDrip = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.85, transparent: true, opacity: 0.55 });
    this.box(0.08, 0.85, 0.03, gateDrip, -2.52, 2.15, wallZ + 0.18, g);
    this.box(0.07, 0.7, 0.03, gateDrip, 2.68, 2.22, wallZ + 0.18, g);
    this.box(0.2, 1.45, 0.03, gateDrip, -1.12, 2.45, wallZ + 0.18, g);
    this.box(0.16, 1.2, 0.03, gateDrip, 1.28, 2.52, wallZ + 0.18, g);
    const gateSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.22, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    gateSock.position.set(-0.42, 1.38, wallZ + 0.32);
    gateSock.rotation.set(0.18, 0.12, 0.32);
    g.add(gateSock);
    const gateTinFloor = new THREE.Mesh(
      new THREE.CylinderGeometry(0.05, 0.055, 0.1, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    gateTinFloor.position.set(0.28, 0.1, -1.15);
    g.add(gateTinFloor);
    const gateBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.038, 0.042, 0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    gateBottle.position.set(0.02, 0.06, -0.92);
    gateBottle.rotation.z = 1.18;
    g.add(gateBottle);
    const gateCig = new THREE.Mesh(
      new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
    );
    gateCig.position.set(0.18, 0.055, -0.68);
    gateCig.rotation.z = Math.PI / 2;
    gateCig.rotation.y = 0.4;
    gateCig.name = 'gateCig';
    g.add(gateCig);
    const haltYard = wallScratch('СТОЙ');
    haltYard.scale.set(1.1, 1.1, 1.1);
    haltYard.position.set(-3.15, 2.05, wallZ + 0.22);
    g.add(haltYard);
    const gateRust = new THREE.MeshStandardMaterial({ color: 0x6a3a28, roughness: 0.7, metalness: 0.22 });
    this.box(1.6, 0.06, 0.06, gateRust, -2.6, 2.05, wallZ + 0.2, g);
    this.box(0.07, 0.55, 0.07, gateRust, -3.3, 1.75, wallZ + 0.2, g);
    this.box(1.4, 0.06, 0.06, gateRust, 2.5, 2.22, wallZ + 0.2, g);
    const gateWet = new THREE.MeshStandardMaterial({ color: 0x4a524c, roughness: 0.35, transparent: true, opacity: 0.45 });
    this.box(0.22, 1.5, 0.03, gateWet, -3.5, 1.0, wallZ + 0.18, g);
    this.box(0.18, 1.2, 0.03, gateWet, 3.4, 0.9, wallZ + 0.18, g);
    const hushGate = wallScratch('ТИХО');
    hushGate.scale.set(1.2, 1.2, 1.2);
    hushGate.position.set(-2.5, 1.65, wallZ + 0.22);
    g.add(hushGate);
    const gateNum = wallScratch('4');
    gateNum.scale.setScalar(1.4);
    gateNum.position.set(2.4, 1.7, wallZ + 0.22);
    g.add(gateNum);
    const gateRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.55, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.94 }),
    );
    gateRag.position.set(3.55, 1.25, wallZ + 0.28);
    gateRag.rotation.z = 0.12;
    g.add(gateRag);

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
    const cageRagMat = new THREE.MeshStandardMaterial({ color: 0x4a3e34, roughness: 0.95 });
    const cageRagA = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.58, 0.04), cageRagMat);
    cageRagA.position.set(-1.15, 3.02, 1.35);
    cageRagA.rotation.z = 0.22;
    g.add(cageRagA);
    const cageRagB = new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.44, 0.04), cageRagMat);
    cageRagB.position.set(1.55, 3.08, -0.75);
    cageRagB.rotation.z = -0.16;
    g.add(cageRagB);
    const cageRagC = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.5, 0.04), cageRagMat);
    cageRagC.position.set(0.35, 3.04, 0.55);
    cageRagC.rotation.z = 0.12;
    g.add(cageRagC);
    const cageRust = new THREE.MeshStandardMaterial({ color: 0x5a3824, roughness: 0.7, metalness: 0.2 });
    this.box(1.55, 0.04, 0.07, cageRust, -0.35, 3.34, 0.55, g);
    this.box(0.07, 0.04, 1.2, cageRust, 1.15, 3.34, -0.25, g);
    this.box(0.9, 0.035, 0.06, cageRust, 0.2, 3.34, -1.4, g);
    const cageTarp = new THREE.MeshStandardMaterial({
      color: 0x5c5a52,
      roughness: 0.94,
      side: THREE.DoubleSide,
    });
    this.box(2.6, 0.04, 1.9, cageTarp, -1.35, 3.32, 0.55, g);
    this.box(2.1, 0.04, 2.3, cageTarp, 1.55, 3.32, -0.85, g);
    this.box(1.7, 0.038, 1.5, cageTarp, 0.15, 3.32, 1.85, g);
    const cageTarpDark = new THREE.MeshStandardMaterial({
      color: 0x3e3c36,
      roughness: 0.96,
      side: THREE.DoubleSide,
    });
    this.box(2.8, 0.045, 2.2, cageTarpDark, 0.05, 3.31, -0.15, g);
    this.box(2.2, 0.04, 1.7, cageTarp, -2.05, 3.32, -1.75, g);
    this.box(2.0, 0.04, 1.6, cageTarp, 2.15, 3.32, 1.65, g);
    this.box(1.8, 0.038, 1.4, cageTarpDark, -0.9, 3.31, 2.35, g);
    this.box(2.4, 0.042, 1.8, cageTarpDark, -0.8, 3.31, -2.65, g);
    this.box(2.2, 0.04, 1.6, cageTarp, 1.4, 3.32, -3.15, g);
    this.box(1.9, 0.038, 1.5, cageTarp, -2.2, 3.32, -3.35, g);
    const cageTarpHang = new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.55, 0.03), cageTarpDark);
    cageTarpHang.position.set(-0.4, 3.08, 0.2);
    cageTarpHang.rotation.x = 0.18;
    g.add(cageTarpHang);
    const cageTarpHang2 = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.42, 0.03), cageTarp);
    cageTarpHang2.position.set(1.1, 3.1, -0.55);
    cageTarpHang2.rotation.x = -0.14;
    g.add(cageTarpHang2);
    const cageTarpHang3 = new THREE.Mesh(new THREE.BoxGeometry(1.1, 0.48, 0.03), cageTarpDark);
    cageTarpHang3.position.set(0.2, 3.05, -2.4);
    cageTarpHang3.rotation.x = 0.22;
    g.add(cageTarpHang3);
    const cageDrop = new THREE.MeshStandardMaterial({ color: 0xd4ccc0, roughness: 0.72, transparent: true, opacity: 0.5 });
    this.box(0.1, 0.02, 0.55, cageDrop, -0.55, 3.345, 0.15, g);
    this.box(0.08, 0.02, 0.4, cageDrop, 1.25, 3.345, -1.05, g);
    this.box(0.09, 0.02, 0.48, cageDrop, 0.4, 3.345, 1.1, g);
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
    const limeMud = new THREE.MeshStandardMaterial({ color: 0x3a2414, roughness: 0.98 });
    this.box(0.62, 0.04, 0.28, limeMud, 0.55, 0.09, 2.15, g);
    this.box(0.48, 0.036, 0.22, limeMud, -0.7, 0.088, 1.85, g);
    this.box(0.4, 0.034, 0.3, limeMud, 0.15, 0.087, 2.55, g);
    const spit = new THREE.MeshStandardMaterial({ color: 0x5a5848, roughness: 0.22, metalness: 0.08, transparent: true, opacity: 0.4 });
    for (const [sx, sz] of [
      [0.35, 1.45],
      [-0.22, 1.95],
      [0.08, 2.35],
    ]) {
      const s = new THREE.Mesh(new THREE.CircleGeometry(0.07, 6), spit);
      s.rotation.x = -Math.PI / 2;
      s.position.set(sx, 0.048, sz);
      g.add(s);
    }
    const paperYard = new THREE.Mesh(
      new THREE.BoxGeometry(0.34, 0.014, 0.24),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    paperYard.position.set(0.22, 0.07, 0.95);
    paperYard.rotation.y = 0.55;
    g.add(paperYard);
    const paperYard2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.012, 0.16),
      new THREE.MeshStandardMaterial({ color: 0xb8a888, roughness: 0.93 }),
    );
    paperYard2.position.set(-0.28, 0.065, 0.52);
    paperYard2.rotation.y = -0.7;
    g.add(paperYard2);
    const krugRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.32, 0.04, 0.2),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.95 }),
    );
    krugRag.position.set(0.18, 0.1, 0.42);
    krugRag.rotation.y = 0.45;
    g.add(krugRag);
    const core = new THREE.Mesh(
      new THREE.SphereGeometry(0.045, 6, 5),
      new THREE.MeshStandardMaterial({ color: 0x6a3a28, roughness: 0.9 }),
    );
    core.scale.set(1, 0.45, 1);
    core.position.set(-0.12, 0.1, 0.68);
    g.add(core);
    const krugPrint = new THREE.MeshStandardMaterial({ color: 0x2a1810, roughness: 0.96 });
    this.box(0.22, 0.02, 0.34, krugPrint, -0.35, 0.086, 0.58, g);
    this.box(0.2, 0.018, 0.3, krugPrint, 0.08, 0.085, 0.78, g);
    this.box(0.78, 0.042, 0.4, limeMud, -0.15, 0.092, 1.05, g);
    this.box(0.55, 0.038, 0.3, limeMud, 0.55, 0.09, 1.12, g);
    this.box(0.7, 0.04, 0.36, limeMud, -0.65, 0.09, 1.55, g);
    this.box(0.5, 0.036, 0.42, limeMud, 0.72, 0.088, 1.85, g);
    this.box(0.62, 0.034, 0.3, limeMud, 0.15, 0.087, 2.15, g);
    this.box(0.9, 0.045, 0.38, limeMud, 0.05, 0.094, 1.7, g);
    const paperKrug3 = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.01, 0.11),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    paperKrug3.position.set(-0.55, 0.1, 1.42);
    paperKrug3.rotation.y = 0.4;
    g.add(paperKrug3);
    const krugRag2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.26, 0.035, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x4a3c32, roughness: 0.95 }),
    );
    krugRag2.position.set(0.48, 0.1, 1.55);
    krugRag2.rotation.y = -0.55;
    g.add(krugRag2);
    const krugTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.038, 0.08, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    krugTin.position.set(0.32, 0.08, 1.28);
    g.add(krugTin);
    const krugSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.22, 0.05),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    krugSock.position.set(-0.42, 0.14, 1.22);
    krugSock.rotation.set(1.15, 0.2, 0.35);
    g.add(krugSock);
    const krugBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.032, 0.036, 0.14, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.16, transparent: true, opacity: 0.82 }),
    );
    krugBottle.position.set(0.12, 0.05, 1.42);
    krugBottle.rotation.z = 1.2;
    g.add(krugBottle);
    const krugCig = new THREE.Mesh(
      new THREE.CylinderGeometry(0.025, 0.025, 0.16, 8),
      new THREE.MeshStandardMaterial({ color: 0xe8dcc0, roughness: 0.65 }),
    );
    krugCig.position.set(0.18, 0.055, 1.05);
    krugCig.rotation.z = Math.PI / 2;
    krugCig.rotation.y = 0.55;
    krugCig.name = 'krugCig';
    g.add(krugCig);
    const buttKrug = new THREE.MeshStandardMaterial({ color: 0xc8b090, roughness: 0.8 });
    for (const [bx, bz, ry] of [
      [0.42, 1.62, 0.6],
      [-0.18, 2.05, -0.4],
      [0.12, 1.38, 1.1],
      [0.08, 1.78, 0.9],
      [-0.32, 1.48, -0.7],
    ]) {
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.008, 0.01, 0.035, 5), buttKrug);
      c.rotation.z = Math.PI / 2;
      c.rotation.y = ry;
      c.position.set(bx, 0.055, bz);
      g.add(c);
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
    const wallRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.06, 0.42, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.94 }),
    );
    wallRag.position.set(4.12, 1.05, -0.35);
    wallRag.rotation.x = 0.15;
    g.add(wallRag);
    const wallRagHi = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, 0.58, 0.2),
      new THREE.MeshStandardMaterial({ color: 0x4a3a32, roughness: 0.95 }),
    );
    wallRagHi.position.set(4.14, 2.18, -0.12);
    wallRagHi.rotation.set(0.12, 0.06, 0.24);
    g.add(wallRagHi);
    const wallCoat = new THREE.Mesh(
      new THREE.BoxGeometry(0.07, 0.72, 0.34),
      new THREE.MeshStandardMaterial({ color: 0x3a4a42, roughness: 0.92 }),
    );
    wallCoat.position.set(4.15, 1.58, 0.52);
    wallCoat.rotation.z = 0.1;
    g.add(wallCoat);
    const wallPeelHi = new THREE.MeshStandardMaterial({ color: 0xb8b09c, roughness: 0.93 });
    this.box(0.03, 0.85, 0.55, wallPeelHi, 4.21, 2.42, -0.25, g);
    this.box(0.03, 0.48, 0.32, wallPeelHi, 4.21, 2.65, 0.35, g);
    const wallMoss = new THREE.MeshStandardMaterial({ color: 0x3a4a38, roughness: 0.96 });
    this.box(0.04, 0.35, 0.55, wallMoss, 4.22, 0.72, -0.45, g);
    const wallFuse = new THREE.Mesh(
      new THREE.BoxGeometry(0.06, 0.18, 0.14),
      new THREE.MeshStandardMaterial({ color: 0x4a4030, metalness: 0.2, roughness: 0.7 }),
    );
    wallFuse.position.set(4.2, 2.05, -0.95);
    g.add(wallFuse);
    const wallSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, 0.28, 0.12),
      new THREE.MeshStandardMaterial({ color: 0x4a4038, roughness: 0.96 }),
    );
    wallSock.position.set(4.13, 0.95, -0.72);
    wallSock.rotation.set(0.18, 0.08, 0.22);
    g.add(wallSock);
    const wallTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.045, 0.05, 0.09, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, metalness: 0.4, roughness: 0.5 }),
    );
    wallTin.position.set(3.95, 0.08, -0.55);
    g.add(wallTin);
    const wallBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.038, 0.042, 0.18, 8),
      new THREE.MeshStandardMaterial({ color: 0x6a5a32, roughness: 0.32, metalness: 0.18, transparent: true, opacity: 0.82 }),
    );
    wallBottle.position.set(3.72, 0.05, -0.22);
    wallBottle.rotation.z = 1.22;
    g.add(wallBottle);
    const wallPaper = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.008, 0.11),
      new THREE.MeshStandardMaterial({ color: 0xc8b898, roughness: 0.92 }),
    );
    wallPaper.position.set(3.82, 0.052, -0.38);
    wallPaper.rotation.y = 0.55;
    g.add(wallPaper);
    const wallMossLow = new THREE.MeshStandardMaterial({ color: 0x3a4a38, roughness: 0.96 });
    this.box(0.04, 0.28, 0.42, wallMossLow, 4.22, 0.42, -0.7, g);
    const wallDrip = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.85, transparent: true, opacity: 0.55 });
    this.box(0.03, 1.15, 0.08, wallDrip, 4.22, 1.85, -1.15, g);
    this.box(0.03, 0.85, 0.06, wallDrip, 4.22, 1.55, -0.55, g);
    this.box(0.03, 0.95, 0.07, wallDrip, 4.22, 1.65, -0.82, g);
    const wallBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.28, 0.22),
      new THREE.MeshStandardMaterial({ color: 0x3a4238, metalness: 0.35, roughness: 0.55 }),
    );
    wallBox.position.set(4.18, 1.35, 0.15);
    g.add(wallBox);
    const wallWire = new THREE.Mesh(
      new THREE.CylinderGeometry(0.01, 0.01, 0.85, 5),
      new THREE.MeshStandardMaterial({ color: 0x2a2a28, roughness: 0.85 }),
    );
    wallWire.position.set(4.16, 2.05, 0.15);
    wallWire.rotation.z = 0.15;
    g.add(wallWire);
    const hushYard = wallScratch('НЕ СВИСТИ');
    hushYard.scale.set(1.1, 1.1, 1.1);
    hushYard.position.set(-4.2, 1.7, 1.2);
    hushYard.rotation.y = Math.PI / 2;
    g.add(hushYard);
    this.box(0.7, 0.02, 0.35, mud, 3.6, 0.05, -0.6, g);
    this.box(0.5, 0.018, 0.28, mud, -3.5, 0.05, 0.9, g);
    this.box(0.38, 0.016, 0.5, mud, 3.7, 0.05, 2.1, g);
    const cornerDamp = new THREE.MeshStandardMaterial({ color: 0x6a6860, roughness: 0.5, transparent: true, opacity: 0.62 });
    this.box(1.8, 1.7, 0.03, cornerDamp, 3.4, 2.15, 4.22, g);
    this.box(0.03, 1.9, 1.6, cornerDamp, 4.22, 2.2, 3.5, g);
    this.box(0.55, 0.42, 0.03, peel, 3.55, 2.35, 4.21, g);
    this.box(0.03, 0.38, 0.48, peel, 4.21, 2.28, 3.7, g);
    this.box(0.7, 0.22, 0.03, peel, 3.9, 2.72, 4.21, g);
    this.box(0.03, 0.55, 0.22, moss, 4.21, 1.55, 3.55, g);
    const piss = new THREE.MeshStandardMaterial({ color: 0x7a6a38, roughness: 0.35, transparent: true, opacity: 0.45 });
    this.box(0.55, 0.95, 0.03, piss, 4.05, 0.7, 4.2, g);
    this.box(0.03, 1.05, 0.7, piss, 4.26, 0.72, 3.95, g);
    const drainPipe = new THREE.Mesh(
      new THREE.CylinderGeometry(0.045, 0.045, 2.4, 6),
      new THREE.MeshStandardMaterial({ color: 0x5a3a28, roughness: 0.7, metalness: 0.25 }),
    );
    drainPipe.position.set(4.05, 1.35, 4.05);
    g.add(drainPipe);
    const drainElbow = new THREE.Mesh(
      new THREE.CylinderGeometry(0.05, 0.05, 0.35, 6),
      drainPipe.material,
    );
    drainElbow.rotation.x = Math.PI / 2;
    drainElbow.position.set(4.05, 0.22, 3.9);
    g.add(drainElbow);
    const cornerGrate = this.box(0.38, 0.03, 0.38, mesh, 3.85, 0.055, 3.85, g);
    cornerGrate.rotation.y = 0.2;
    const cornerRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.28, 0.08, 0.18),
      new THREE.MeshStandardMaterial({ color: 0x5a4a3a, roughness: 0.94 }),
    );
    cornerRag.position.set(3.55, 0.08, 3.95);
    cornerRag.rotation.y = 0.5;
    g.add(cornerRag);
    const rustDrip = new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.88 });
    this.box(0.1, 0.62, 0.035, rustDrip, 4.0, 2.12, 4.1, g);
    this.box(0.07, 0.48, 0.03, rustDrip, 4.1, 1.62, 4.0, g);
    this.box(0.08, 1.05, 0.02, rustDrip, 3.78, 2.45, 4.22, g);
    this.box(0.02, 0.95, 0.1, rustDrip, 4.22, 2.55, 3.82, g);
    const hangRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.24, 0.62, 0.045),
      new THREE.MeshStandardMaterial({ color: 0x6a5a46, roughness: 0.95 }),
    );
    hangRag.position.set(3.9, 2.08, 4.08);
    hangRag.rotation.set(0.08, 0.35, 0.22);
    g.add(hangRag);
    const hangRag2 = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.42, 0.03),
      new THREE.MeshStandardMaterial({ color: 0x4a3a32, roughness: 0.94 }),
    );
    hangRag2.position.set(4.02, 1.78, 3.92);
    hangRag2.rotation.set(0.05, -0.2, -0.28);
    g.add(hangRag2);
    const mossMound = new THREE.MeshStandardMaterial({ color: 0x3a4a38, roughness: 0.96 });
    this.box(0.72, 0.045, 0.58, mossMound, 3.72, 0.05, 3.72, g);
    this.box(0.24, 0.07, 0.2, mossMound, 3.95, 0.075, 3.95, g);
    const grateBar = new THREE.MeshStandardMaterial({ color: 0x1e221e, metalness: 0.45, roughness: 0.5 });
    for (let i = 0; i < 4; i++) {
      this.box(0.34, 0.014, 0.028, grateBar, 3.85, 0.074, 3.7 + i * 0.09, g);
    }
    const buttCorner = new THREE.MeshStandardMaterial({ color: 0xc4a070, roughness: 0.82 });
    this.box(0.042, 0.014, 0.012, buttCorner, 3.52, 0.06, 3.52, g);
    this.box(0.036, 0.012, 0.01, buttCorner, 3.62, 0.055, 3.68, g);
    const wetSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.15, 0.04, 0.08),
      new THREE.MeshStandardMaterial({ color: 0x32363a, roughness: 0.92 }),
    );
    wetSock.position.set(3.38, 0.06, 3.58);
    wetSock.rotation.y = -0.7;
    g.add(wetSock);
    const drainTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.045, 0.05, 0.12, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a6a3a, metalness: 0.35, roughness: 0.55 }),
    );
    drainTin.position.set(3.48, 0.09, 3.78);
    drainTin.rotation.z = 1.15;
    drainTin.rotation.y = 0.4;
    g.add(drainTin);
    const drainBottle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.04, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a4a42, roughness: 0.45, transparent: true, opacity: 0.72 }),
    );
    drainBottle.position.set(3.68, 0.13, 3.42);
    drainBottle.rotation.z = 1.35;
    g.add(drainBottle);
    const drainSplash = new THREE.Mesh(
      new THREE.CircleGeometry(0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a4238, roughness: 0.22, metalness: 0.12, transparent: true, opacity: 0.5 }),
    );
    drainSplash.rotation.x = -Math.PI / 2;
    drainSplash.position.set(3.9, 0.048, 3.78);
    g.add(drainSplash);
    const drainWire = new THREE.Mesh(
      new THREE.BoxGeometry(0.02, 0.55, 0.02),
      new THREE.MeshStandardMaterial({ color: 0x2a2a28, metalness: 0.4, roughness: 0.55 }),
    );
    drainWire.position.set(3.78, 1.55, 4.12);
    drainWire.rotation.z = 0.18;
    g.add(drainWire);
    const cornerNum = wallScratch('4');
    cornerNum.scale.setScalar(1.8);
    cornerNum.position.set(4.18, 1.85, 3.2);
    cornerNum.rotation.y = -Math.PI / 2;
    g.add(cornerNum);
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
      [0.15, 3.55, 0.38],
      [-0.25, 3.15, 0.28],
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
    for (const z of [3.55, 8.2, 16.8, 25.5]) {
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.85, 5), cable);
      c.position.set(LAYOUT.corridorHalf - 0.18, 2.15, z);
      c.rotation.z = 0.35;
      this.group.add(c);
    }
    const doorPaper = new THREE.Mesh(
      new THREE.BoxGeometry(0.22, 0.008, 0.16),
      new THREE.MeshStandardMaterial({ color: 0xd8d0bc, roughness: 0.92 }),
    );
    doorPaper.position.set(0.35, 0.05, 3.62);
    doorPaper.rotation.y = 0.4;
    this.group.add(doorPaper);
    const hushHall = cellSign('4');
    hushHall.scale.setScalar(0.38);
    hushHall.position.set(LAYOUT.corridorHalf - 0.14, 1.72, 3.95);
    hushHall.rotation.y = -Math.PI / 2;
    this.group.add(hushHall);
    const hallRag = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.42, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x5a4a38, roughness: 0.95 }),
    );
    hallRag.position.set(LAYOUT.corridorHalf - 0.16, 1.95, 3.55);
    hallRag.rotation.set(0.08, 0.12, 0.18);
    this.group.add(hallRag);
    const hallMud = new THREE.Mesh(
      new THREE.CircleGeometry(0.32, 8),
      new THREE.MeshStandardMaterial({ color: 0x3a2414, roughness: 0.85 }),
    );
    hallMud.rotation.x = -Math.PI / 2;
    hallMud.position.set(0.55, 0.048, 3.48);
    this.group.add(hallMud);
    const hallBoot = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.012, 0.28),
      new THREE.MeshStandardMaterial({ color: 0x2a1a10, roughness: 0.9 }),
    );
    hallBoot.position.set(0.22, 0.05, 3.72);
    hallBoot.rotation.y = 0.35;
    this.group.add(hallBoot);
    const hallFoil = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.006, 0.05),
      new THREE.MeshStandardMaterial({ color: 0xb8b0a0, metalness: 0.45, roughness: 0.4 }),
    );
    hallFoil.position.set(0.48, 0.052, 3.35);
    hallFoil.rotation.y = -0.7;
    this.group.add(hallFoil);
    const hallTin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.035, 0.038, 0.07, 8),
      new THREE.MeshStandardMaterial({ color: 0x8a8e86, roughness: 0.45, metalness: 0.35 }),
    );
    hallTin.position.set(0.68, 0.09, 3.58);
    this.group.add(hallTin);
    const hallSock = new THREE.Mesh(
      new THREE.BoxGeometry(0.08, 0.04, 0.18),
      new THREE.MeshStandardMaterial({ color: 0x3a342c, roughness: 0.95 }),
    );
    hallSock.position.set(0.38, 0.06, 3.28);
    hallSock.rotation.y = 0.5;
    this.group.add(hallSock);
    this.box(
      0.08,
      0.38,
      0.22,
      new THREE.MeshStandardMaterial({ color: 0x6a3a22, roughness: 0.88 }),
      LAYOUT.corridorHalf - 0.16,
      0.55,
      3.7,
    );
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
