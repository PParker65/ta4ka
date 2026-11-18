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
      x: ox + 0.35,
      z: oz + 0.55,
      yaw: Math.PI,
      tattoos: true,
      robe: 0x4a4a46,
    });
    await this.add('inmate', {
      id: 'cellmate',
      name: 'Лёха',
      x: ox + 1.55,
      z: oz - 1.7,
      yaw: 0.5,
      robe: 0x5a5854,
    });
    await this.add('inmate', {
      id: 'bunk-bro',
      name: 'Валера',
      x: ox + 1.7,
      z: oz + 2.0,
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
    let best = 'default';
    let bestD = max;
    for (const n of this.list) {
      const d = Math.hypot(pos.x - n.root.position.x, pos.z - n.root.position.z);
      if (d < bestD) {
        bestD = d;
        best = n.id === 'convoy' ? 'convoy' : n.id;
      }
    }
    return best;
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
      if (n.walkTo) {
        const dx = n.walkTo.x - n.root.position.x;
        const dz = n.walkTo.z - n.root.position.z;
        const d = Math.hypot(dx, dz) || 1;
        if (d > 0.2) {
          n.root.position.x += (dx / d) * dt * 1.25;
          n.root.position.z += (dz / d) * dt * 1.25;
          n.root.rotation.y = Math.atan2(dx, dz);
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
        continue;
      }
      if (n.bob !== false) n.root.position.y = Math.sin(t * 1.4 + n.root.position.z) * 0.012;
      if (player && n.kind === 'inmate' && n.id !== 'hatch') {
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
  return {
    root,
    id: 'dog',
    kind: 'dog',
    name: 'овчарка',
    bob: false,
    home: new THREE.Vector3(x, 0, z),
    phase,
  };
}

function human(kind, spec) {
  const root = new THREE.Group();
  const skin = new THREE.MeshStandardMaterial({ color: 0xc2a07a, roughness: 0.62 });
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

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.125, 16, 12), skin);
  head.position.y = 0.48;
  hips.add(head);
  const nose = new THREE.Mesh(new THREE.SphereGeometry(0.028, 8, 6), skin);
  nose.position.set(0, 0.46, 0.12);
  hips.add(nose);
  const white = new THREE.MeshStandardMaterial({ color: 0xf2eee8, roughness: 0.4 });
  const iris = new THREE.MeshStandardMaterial({ color: 0x2a241c });
  for (const x of [-0.038, 0.038]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.018, 8, 6), white);
    eye.position.set(x, 0.5, 0.1);
    hips.add(eye);
    const p = new THREE.Mesh(new THREE.SphereGeometry(0.008, 6, 4), iris);
    p.position.set(x, 0.5, 0.115);
    hips.add(p);
  }
  const mouth = new THREE.Mesh(
    new THREE.BoxGeometry(0.05, 0.012, 0.01),
    new THREE.MeshStandardMaterial({ color: 0x6a3a38 }),
  );
  mouth.position.set(0, 0.415, 0.112);
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

  for (const side of [-1, 1]) {
    const arm = new THREE.Mesh(new THREE.CapsuleGeometry(0.045, 0.38, 3, 6), cloth);
    arm.position.set(side * 0.22, 0.02, 0);
    arm.rotation.z = side * 0.12;
    hips.add(arm);
    const hand = new THREE.Mesh(new THREE.SphereGeometry(0.045, 8, 6), skin);
    hand.position.set(side * 0.24, -0.28, 0.02);
    hips.add(hand);
    const leg = new THREE.Mesh(new THREE.CapsuleGeometry(0.055, 0.55, 3, 6), pants);
    leg.position.set(side * 0.08, 0.38, 0);
    root.add(leg);
    const shoe = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.06, 0.18),
      new THREE.MeshStandardMaterial({ color: 0x2c2a28 }),
    );
    shoe.position.set(side * 0.08, 0.04, 0.02);
    root.add(shoe);
  }
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
