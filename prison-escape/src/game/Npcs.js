import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const NPC_GLB = {
  inmate: '/models/npc/inmate.glb',
  guard: '/models/npc/guard.glb',
};

export class Npcs {
  constructor(scene) {
    this.scene = scene;
    this.list = [];
  }

  async spawnCell(ox, oz) {
    await this.add('inmate', {
      id: 'starosta',
      name: 'Седой',
      x: ox + 0.2,
      z: oz + 0.45,
      yaw: Math.PI,
      tattoos: true,
      robe: 0x4a4a46,
    });
    await this.add('inmate', {
      id: 'cellmate',
      name: 'Лёха',
      x: ox + 0.55,
      z: oz - 1.15,
      yaw: 0.5,
      robe: 0x5a5854,
    });
    await this.add('inmate', {
      id: 'bunk-bro',
      name: 'Валера',
      x: ox + 0.2,
      z: oz + 1.15,
      yaw: -0.4,
      robe: 0x3e3c38,
    });
  }

  async spawnConvoy() {
    await this.add('guard', { id: 'convoy', name: 'Конвой', x: 0.85, z: -78.6, yaw: Math.PI, follow: 0 });
    await this.add('guard', { id: 'convoy', name: 'Конвой', x: -0.85, z: -78.4, yaw: Math.PI, follow: 1 });
    await this.add('guard', { id: 'kpp-officer', name: 'Дежурный', x: 4.2, z: -55.4, yaw: Math.PI, follow: null });
    await this.add('inmate', {
      id: 'fresh',
      name: '',
      x: 0.42,
      z: -82.55,
      yaw: Math.PI,
      robe: 0x3a3a38,
    });
    const fresh = this.list.find((n) => n.id === 'fresh');
    if (fresh) {
      const plate = fresh.root.children.find((c) => c.userData.billboard);
      if (plate) plate.visible = false;
      this.fresh = fresh;
    }
    this.dogs = [makeDog(-3.6, -73.2, 0.4), makeDog(2.4, -71.4, -0.3), makeDog(-1.2, -75.5, 0.9)];
    for (const d of this.dogs) {
      this.scene.add(d.root);
      this.list.push(d);
    }
  }

  dogsAlert(on) {
    this._dogsOn = on;
  }

  async spawnHatches(doors) {
    for (const d of doors) {
      if (d.type !== 'locked-door' || d.num === 'Д') continue;
      const face = hatchFace();
      const side = d.side || 1;
      face.position.set(d.position.x + side * 0.12, 1.52, d.position.z);
      face.rotation.y = side > 0 ? -Math.PI / 2 : Math.PI / 2;
      this.scene.add(face);
      this.list.push({
        root: face,
        id: 'hatch',
        kind: 'inmate',
        name: `Хата ${d.num}`,
        bob: false,
      });
    }
  }

  async add(kind, spec) {
    const glb = await tryGltf(NPC_GLB[kind]);
    const root = glb || human(kind, spec);
    root.position.set(spec.x, 0, spec.z);
    root.rotation.y = spec.yaw || 0;
    this.scene.add(root);
    if (spec.name) {
      const label = nameplate(spec.name);
      label.position.set(0, 1.95, 0);
      root.add(label);
    }
    this.list.push({
      root,
      id: spec.id,
      kind,
      name: spec.name,
      follow: spec.follow,
      home: new THREE.Vector3(spec.x, 0, spec.z),
      bob: true,
    });
    return root;
  }

  nearestKind(pos, max = 2.4) {
    const n = this.nearestPerson(pos, max);
    return n ? (n.id === 'convoy' ? 'convoy' : n.id) : 'default';
  }

  byId(id) {
    return this.list.find((n) => n.id === id);
  }

  nearestPerson(pos, max = 1.85) {
    let best = null;
    let bestD = max;
    for (const n of this.list) {
      if (!n.name || n.kind === 'dog' || n.id === 'hatch' || n.id === 'fresh') continue;
      if (n.gone) continue;
      const d = Math.hypot(pos.x - n.root.position.x, pos.z - n.root.position.z);
      if (d < bestD) {
        bestD = d;
        best = n;
      }
    }
    return best;
  }

  dismissConvoy() {
    for (const n of this.list) {
      if (n.follow == null) continue;
      n.follow = null;
      n.walkPath = [
        { x: 1.5, z: 3.4 },
        { x: 0, z: 3.35 },
        { x: 0, z: -1.2 },
        { x: 0, z: -14 },
      ];
    }
  }

  sitAt(n, x, z) {
    if (!n) return;
    n.walkTo = null;
    n.walkPath = null;
    n.root.position.x += (x - n.root.position.x) * 0.08;
    n.root.position.z += (z - n.root.position.z) * 0.08;
    this.pose(n, 'sit');
  }

  standAt(n, x, z, yaw) {
    if (!n) return;
    n.walkTo = null;
    const dx = x - n.root.position.x;
    const dz = z - n.root.position.z;
    if (Math.hypot(dx, dz) > 0.12) n.walkTo = { x, y: 0, z };
    else {
      n.root.rotation.y = yaw;
      this.pose(n, 'stand');
    }
  }

  pose(n, kind) {
    const limbs = n.root.userData.limbs;
    if (!limbs) return;
    n.pose = kind;
    if (kind === 'sit') {
      limbs.hips.position.y = 0.4;
      limbs.legs[0].rotation.x = -1.35;
      limbs.legs[1].rotation.x = -1.28;
      limbs.arms[0].rotation.x = 0.35;
      limbs.arms[1].rotation.x = 0.3;
    } else if (kind === 'lean') {
      limbs.hips.position.y = 0.92;
      limbs.hips.rotation.x = 0.12;
      limbs.arms[0].rotation.x = -0.4;
    } else {
      limbs.hips.position.y = 0.92;
      limbs.hips.rotation.x = 0;
    }
  }

  keepInCell(n) {
    if (!n || n.kind !== 'inmate' || n.id === 'hatch' || n.gone) return;
    const o = this.cellOrigin;
    if (!o) return;
    n.root.position.x = Math.max(o.x - 2.55, Math.min(o.x + 2.7, n.root.position.x));
    n.root.position.z = Math.max(o.z - 2.9, Math.min(o.z + 2.9, n.root.position.z));
  }

  keepOutOfFurniture(n) {
    if (!n || n.kind === 'dog' || n.gone || n.id === 'hatch') return;
    const boxes = this.furniture;
    if (!boxes?.length) return;
    const p = n.root.position;
    const r = 0.28;
    for (const c of boxes) {
      const nx = Math.max(c.minx, Math.min(p.x, c.maxx));
      const nz = Math.max(c.minz, Math.min(p.z, c.maxz));
      const dx = p.x - nx;
      const dz = p.z - nz;
      const d2 = dx * dx + dz * dz;
      if (d2 < r * r) {
        const d = Math.sqrt(d2) || 0.0001;
        const push = (r - d) / d;
        p.x += dx * push;
        p.z += dz * push;
        n.walkTo = null;
      }
    }
  }

  followEscort(player, yaw, t) {
    for (const n of this.list) {
      if (n.follow == null) continue;
      const side = n.follow === 0 ? 0.7 : -0.7;
      const back = 0.85;
      const tx = player.x + Math.cos(yaw) * side - Math.sin(yaw) * back;
      const tz = player.z - Math.sin(yaw) * side - Math.cos(yaw) * back;
      n.root.position.x += (tx - n.root.position.x) * 0.12;
      n.root.position.z += (tz - n.root.position.z) * 0.12;
      n.root.rotation.y = yaw;
    }
  }

  update(t, player, camera, dt = 0.016) {
    for (const n of this.list) {
      if (n.walkPath?.length) {
        n.walkTo = n.walkPath[0];
        const dx = n.walkTo.x - n.root.position.x;
        const dz = n.walkTo.z - n.root.position.z;
        if (Math.hypot(dx, dz) < 0.28) {
          n.walkPath.shift();
          if (!n.walkPath.length) {
            n.walkTo = null;
            if (n.id === 'convoy') {
              n.gone = true;
              n.root.visible = false;
            }
          }
        }
      }
      if (n.walkTo && !n.gone) {
        const dx = n.walkTo.x - n.root.position.x;
        const dz = n.walkTo.z - n.root.position.z;
        const d = Math.hypot(dx, dz) || 1;
        if (d > 0.2) {
          n.root.position.x += (dx / d) * dt * 1.55;
          n.root.position.z += (dz / d) * dt * 1.55;
          n.root.rotation.y = Math.atan2(dx, dz);
        } else {
          n.walkTo = null;
        }
      }
      if (camera) {
        n.root.traverse((c) => {
          if (c.userData.billboard) c.quaternion.copy(camera.quaternion);
        });
      }
      if (n.kind === 'dog') {
        const pace = Math.sin(t * 1.1 + n.phase) * 0.55;
        n.root.position.x = n.home.x + Math.cos(n.phase) * pace;
        n.root.position.z = n.home.z + Math.sin(n.phase) * pace * 0.4;
        if (this._dogsOn && player) {
          const dx = player.x - n.root.position.x;
          const dz = player.z - n.root.position.z;
          n.root.position.x += dx * 0.02;
          n.root.position.z += dz * 0.02;
          n.root.rotation.y = Math.atan2(dx, dz);
        }
        n.root.position.y = 0;
        (n.legs || []).forEach((leg, i) => {
          leg.rotation.x = Math.sin(t * 8 + n.phase + i) * 0.55;
        });
        if (n.tail) n.tail.rotation.z = Math.sin(t * 6 + n.phase) * 0.4;
        continue;
      }
      const limbs = n.root.userData.limbs;
      const walking = !!n.walkTo;
      if (limbs && walking) {
        const s = Math.sin(t * 8);
        limbs.arms[0].rotation.x = s * 0.55;
        limbs.arms[1].rotation.x = -s * 0.55;
        limbs.legs[0].rotation.x = -s * 0.6;
        limbs.legs[1].rotation.x = s * 0.6;
        limbs.hips.position.y = 0.92 + Math.abs(s) * 0.03;
      } else if (limbs && n.pose === 'sit') {
        this.pose(n, 'sit');
      }
      if (n.bob !== false && n.pose !== 'sit') n.root.position.y = Math.sin(t * 1.4 + n.root.position.z) * 0.012;
      else if (n.pose === 'sit') n.root.position.y = 0;
      this.keepOutOfFurniture(n);
      this.keepInCell(n);
      if (this.prison && n.kind === 'inmate' && n.id !== 'hatch' && !n.gone) {
        const r = this.prison.resolve(n.root.position, 0.32);
        n.root.position.x = r.x;
        n.root.position.z = r.z;
      }
      if (player && n.kind === 'inmate' && n.id !== 'hatch' && !n.walkTo && n.pose !== 'sit') {
        const dx = player.x - n.root.position.x;
        const dz = player.z - n.root.position.z;
        if (dx * dx + dz * dz < 16) {
          n.root.rotation.y += (Math.atan2(dx, dz) - n.root.rotation.y) * 0.04;
        }
      }
    }
  }
}

function makeDog(x, z, phase) {
  const root = new THREE.Group();
  root.position.set(x, 0, z);
  const fur = new THREE.MeshStandardMaterial({ color: 0x5a3a22, roughness: 0.85 });
  const dark = new THREE.MeshStandardMaterial({ color: 0x1a120e, roughness: 0.8 });
  const tan = new THREE.MeshStandardMaterial({ color: 0x8a6a44, roughness: 0.85 });
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.14, 0.42, 4, 8), fur);
  body.rotation.z = Math.PI / 2;
  body.position.set(0, 0.38, 0);
  root.add(body);
  const chest = new THREE.Mesh(new THREE.SphereGeometry(0.13, 8, 6), tan);
  chest.position.set(0, 0.36, 0.22);
  root.add(chest);
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.1, 10, 8), dark);
  head.position.set(0, 0.48, 0.38);
  root.add(head);
  const snout = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.05, 0.12), dark);
  snout.position.set(0, 0.44, 0.48);
  root.add(snout);
  for (const s of [-1, 1]) {
    const ear = new THREE.Mesh(new THREE.ConeGeometry(0.035, 0.1, 5), dark);
    ear.position.set(s * 0.06, 0.58, 0.34);
    root.add(ear);
    const leg = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.028, 0.32, 6), fur);
    leg.position.set(s * 0.08, 0.16, 0.14);
    root.add(leg);
    const hind = leg.clone();
    hind.position.z = -0.16;
    root.add(hind);
  }
  const tail = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.01, 0.28, 5), dark);
  tail.rotation.x = 0.7;
  tail.position.set(0, 0.48, -0.32);
  root.add(tail);
  const legs = [];
  root.traverse((c) => {
    if (c.isMesh && c.geometry?.type === 'CylinderGeometry' && c.position.y < 0.3) legs.push(c);
  });
  return {
    root,
    id: 'dog',
    kind: 'dog',
    name: 'овчарка',
    bob: false,
    home: new THREE.Vector3(x, 0, z),
    phase,
    legs,
    tail,
  };
}

function human(kind, spec) {
  const root = new THREE.Group();
  const skin = new THREE.MeshStandardMaterial({ color: 0xd4a07a, roughness: 0.55, emissive: 0x3a2010, emissiveIntensity: 0.08 });
  const cloth =
    kind === 'guard'
      ? new THREE.MeshStandardMaterial({ color: 0x1c2228, roughness: 0.55, metalness: 0.08 })
      : striped(spec.robe || 0x5a5a56);
  const pants = new THREE.MeshStandardMaterial({
    color: kind === 'guard' ? 0x15181c : 0x3a3936,
    roughness: 0.7,
  });

  const hips = new THREE.Group();
  hips.position.y = 0.92;
  root.add(hips);

  const torso = new THREE.Mesh(new THREE.CapsuleGeometry(0.16, 0.38, 4, 8), cloth);
  torso.position.y = 0.08;
  torso.castShadow = true;
  hips.add(torso);

  const neck = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.06, 0.1, 8), skin);
  neck.position.y = 0.32;
  hips.add(neck);
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.13, 20, 16), skin);
  head.position.y = 0.5;
  hips.add(head);
  const jaw = new THREE.Mesh(new THREE.SphereGeometry(0.1, 12, 8), skin);
  jaw.scale.set(0.92, 0.7, 0.85);
  jaw.position.set(0, 0.42, 0.02);
  hips.add(jaw);
  const nose = new THREE.Mesh(new THREE.SphereGeometry(0.026, 8, 6), skin);
  nose.scale.set(0.7, 0.9, 1.15);
  nose.position.set(0, 0.48, 0.13);
  hips.add(nose);
  const brow = new THREE.MeshStandardMaterial({ color: 0x3a2a22, roughness: 0.85 });
  for (const x of [-0.045, 0.045]) {
    const b = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.008, 0.012), brow);
    b.position.set(x, 0.545, 0.11);
    b.rotation.z = x > 0 ? -0.15 : 0.15;
    hips.add(b);
    const ear = new THREE.Mesh(new THREE.SphereGeometry(0.028, 8, 6), skin);
    ear.scale.set(0.55, 1, 0.7);
    ear.position.set(x * 2.6, 0.5, 0);
    hips.add(ear);
  }
  const white = new THREE.MeshStandardMaterial({ color: 0xf2eee8, roughness: 0.35 });
  const iris = new THREE.MeshStandardMaterial({ color: 0x2a241c });
  for (const x of [-0.04, 0.04]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.02, 10, 8), white);
    eye.scale.set(1, 0.75, 0.7);
    eye.position.set(x, 0.515, 0.108);
    hips.add(eye);
    const p = new THREE.Mesh(new THREE.SphereGeometry(0.009, 8, 6), iris);
    p.position.set(x, 0.515, 0.122);
    hips.add(p);
  }
  const mouth = new THREE.Mesh(
    new THREE.BoxGeometry(0.048, 0.01, 0.012),
    new THREE.MeshStandardMaterial({ color: 0x6a3a38, roughness: 0.6 }),
  );
  mouth.position.set(0, 0.425, 0.12);
  hips.add(mouth);

  if (kind === 'guard') {
    const cap = new THREE.Mesh(
      new THREE.CylinderGeometry(0.13, 0.14, 0.08, 12),
      new THREE.MeshStandardMaterial({ color: 0x0d0e10 }),
    );
    cap.position.y = 0.58;
    hips.add(cap);
    const brim = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.02, 0.14),
      new THREE.MeshStandardMaterial({ color: 0x0d0e10 }),
    );
    brim.position.set(0, 0.55, 0.08);
    hips.add(brim);
    const belt = new THREE.Mesh(
      new THREE.BoxGeometry(0.38, 0.05, 0.24),
      new THREE.MeshStandardMaterial({ color: 0x6a5a38, metalness: 0.3 }),
    );
    belt.position.y = -0.12;
    hips.add(belt);
    const stock = new THREE.MeshStandardMaterial({ color: 0x2a241c, roughness: 0.7 });
    const gun = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.06, 0.72), stock);
    gun.position.set(0.18, -0.02, 0.22);
    gun.rotation.x = 0.15;
    hips.add(gun);
    const barrel = new THREE.Mesh(
      new THREE.CylinderGeometry(0.015, 0.015, 0.38, 6),
      new THREE.MeshStandardMaterial({ color: 0x3a3a3c, metalness: 0.6, roughness: 0.35 }),
    );
    barrel.rotation.x = Math.PI / 2;
    barrel.position.set(0.18, 0.0, 0.62);
    hips.add(barrel);
  } else {
    const buzz = new THREE.Mesh(
      new THREE.SphereGeometry(0.128, 10, 8, 0, Math.PI * 2, 0, 1.05),
      new THREE.MeshStandardMaterial({ color: spec.tattoos ? 0x9a9a98 : 0x2a221c, roughness: 0.85 }),
    );
    buzz.position.set(0, 0.5, 0);
    hips.add(buzz);
  }

  if (spec.tattoos) {
    const ink = new THREE.Mesh(
      new THREE.PlaneGeometry(0.14, 0.18),
      new THREE.MeshBasicMaterial({ map: tattooTex(), transparent: true }),
    );
    ink.position.set(0.17, 0.1, 0);
    ink.rotation.y = Math.PI / 2;
    hips.add(ink);
  }

  const limbs = { hips, arms: [], legs: [] };
  for (const side of [-1, 1]) {
    const armG = new THREE.Group();
    armG.position.set(side * 0.22, 0.02, 0);
    hips.add(armG);
    const arm = new THREE.Mesh(new THREE.CapsuleGeometry(0.045, 0.38, 3, 6), cloth);
    arm.position.y = -0.16;
    arm.rotation.z = side * 0.12;
    armG.add(arm);
    const hand = new THREE.Mesh(new THREE.SphereGeometry(0.045, 8, 6), skin);
    hand.position.set(0, -0.38, 0.02);
    armG.add(hand);
    limbs.arms.push(armG);
    const legG = new THREE.Group();
    legG.position.set(side * 0.08, 0.92, 0);
    root.add(legG);
    const leg = new THREE.Mesh(new THREE.CapsuleGeometry(0.055, 0.55, 3, 6), pants);
    leg.position.y = -0.54;
    legG.add(leg);
    const shoe = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.06, 0.18),
      new THREE.MeshStandardMaterial({ color: 0x2c2a28 }),
    );
    shoe.position.set(0, -0.88, 0.02);
    legG.add(shoe);
    limbs.legs.push(legG);
  }
  root.userData.limbs = limbs;
  return root;
}

function striped(hex) {
  const c = document.createElement('canvas');
  c.width = 64;
  c.height = 64;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#5c5c58';
  ctx.fillRect(0, 0, 64, 64);
  ctx.fillStyle = '#2a2a28';
  for (let y = 0; y < 64; y += 7) ctx.fillRect(0, y, 64, 3);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(1, 3);
  const m = new THREE.MeshStandardMaterial({ map: tex, roughness: 0.72 });
  m.color.setHex(hex);
  return m;
}

function nameplate(text) {
  const c = document.createElement('canvas');
  c.width = 256;
  c.height = 64;
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, 256, 64);
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  round(ctx, 12, 8, 232, 48, 10);
  ctx.fill();
  ctx.fillStyle = '#f1e6c8';
  ctx.font = '600 28px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 128, 34);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false });
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(0.7, 0.18), mat);
  mesh.userData.billboard = true;
  return mesh;
}

function hatchFace() {
  const g = new THREE.Group();
  const skin = new THREE.MeshStandardMaterial({ color: 0xb8926c });
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.09, 10, 8), skin);
  g.add(head);
  const eye = new THREE.MeshStandardMaterial({ color: 0x1a120e });
  for (const x of [-0.03, 0.03]) {
    const e = new THREE.Mesh(new THREE.SphereGeometry(0.015, 6, 4), eye);
    e.position.set(x, 0.01, 0.08);
    g.add(e);
  }
  return g;
}

function tattooTex() {
  const c = document.createElement('canvas');
  c.width = c.height = 64;
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, 64, 64);
  ctx.strokeStyle = '#1a1a1a';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(10, 50);
  ctx.lineTo(32, 12);
  ctx.lineTo(54, 50);
  ctx.stroke();
  ctx.fillStyle = '#111';
  ctx.font = '10px sans-serif';
  ctx.fillText('СИЗО', 16, 40);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

function round(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

async function tryGltf(url) {
  try {
    const res = await fetch(url, { method: 'HEAD' });
    if (!res.ok) return null;
    return (await new GLTFLoader().loadAsync(url)).scene;
  } catch {
    return null;
  }
}
