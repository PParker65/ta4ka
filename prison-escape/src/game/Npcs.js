import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

/**
 * Dynamic NPC loader stub:
 *   public/models/npc/inmate.glb  — cellmates with tattoos
 *   public/models/npc/guard.glb
 * Falls back to a tattooed placeholder mesh.
 */
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
    const starosta = await this.make('inmate', 0x3a3530, true);
    starosta.position.set(ox + 0.3, 0, oz + 0.4);
    starosta.rotation.y = Math.PI;
    this.scene.add(starosta);
    this.list.push({ root: starosta, id: 'starosta', kind: 'inmate' });

    const bro = await this.make('inmate', 0x4a4038, false);
    bro.position.set(ox + 1.6, 0, oz - 1.8);
    bro.rotation.y = 0.4;
    this.scene.add(bro);
    this.list.push({ root: bro, id: 'cellmate', kind: 'inmate' });
  }

  async spawnConvoy() {
    for (const z of [-16.2, -15.1]) {
      const g = await this.make('guard', 0x1a1c1e, false);
      g.position.set(0.7, 0, z);
      g.rotation.y = Math.PI;
      this.scene.add(g);
      this.list.push({ root: g, id: 'convoy', kind: 'guard' });
    }
  }

  async make(kind, cloth, tattoos) {
    const glb = await tryGltf(NPC_GLB[kind]);
    if (glb) return glb.scene;
    return placeholder(kind, cloth, tattoos);
  }

  update(t) {
    for (const n of this.list) {
      n.root.position.y = Math.sin(t * 1.5 + n.root.position.z) * 0.01;
    }
  }
}

function placeholder(kind, cloth, tattoos) {
  const root = new THREE.Group();
  const body = new THREE.Mesh(
    new THREE.BoxGeometry(0.42, 0.72, 0.26),
    new THREE.MeshStandardMaterial({ color: cloth, roughness: 0.7 }),
  );
  body.position.y = 1.16;
  root.add(body);
  const legs = new THREE.Mesh(
    new THREE.BoxGeometry(0.32, 0.7, 0.22),
    new THREE.MeshStandardMaterial({ color: kind === 'guard' ? 0x1a1c1e : 0x3a3532, roughness: 0.75 }),
  );
  legs.position.y = 0.42;
  root.add(legs);
  const head = new THREE.Mesh(
    new THREE.SphereGeometry(0.13, 10, 8),
    new THREE.MeshStandardMaterial({ color: 0xb08a68, roughness: 0.75 }),
  );
  head.position.y = 1.64;
  root.add(head);
  if (kind === 'guard') {
    const cap = new THREE.Mesh(
      new THREE.CylinderGeometry(0.14, 0.15, 0.09, 10),
      new THREE.MeshStandardMaterial({ color: 0x111 }),
    );
    cap.position.y = 1.76;
    root.add(cap);
  } else {
    const buzz = new THREE.Mesh(
      new THREE.SphereGeometry(0.132, 10, 8, 0, Math.PI * 2, 0, 1.0),
      new THREE.MeshStandardMaterial({ color: 0x2a221c }),
    );
    buzz.position.set(0, 1.66, 0);
    root.add(buzz);
  }
  if (tattoos) {
    const ink = new THREE.Mesh(
      new THREE.PlaneGeometry(0.16, 0.22),
      new THREE.MeshBasicMaterial({ map: tattooTex(), transparent: true }),
    );
    ink.position.set(0.22, 1.22, 0);
    ink.rotation.y = Math.PI / 2;
    root.add(ink);
  }
  return root;
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

async function tryGltf(url) {
  try {
    const res = await fetch(url, { method: 'HEAD' });
    if (!res.ok) return null;
    return await new GLTFLoader().loadAsync(url);
  } catch {
    return null;
  }
}
