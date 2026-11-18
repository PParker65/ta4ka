import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { FBXLoader } from 'three/addons/loaders/FBXLoader.js';

/**
 * MIXAMO / GLB stubs — drop real files and they load automatically:
 *   public/models/prisoner.glb
 *   public/models/mixamo/Idle.fbx
 *   public/models/mixamo/Walking.fbx
 *   public/models/mixamo/Running.fbx   (run clip)
 *   public/models/mixamo/Crouching.fbx (optional)
 * Until then, a grey kazenka placeholder + AnimationMixer clips.
 */
const GLB_PATH = '/models/prisoner.glb';
const MIXAMO = {
  idle: '/models/mixamo/Idle.fbx',
  walk: '/models/mixamo/Walking.fbx',
  run: '/models/mixamo/Running.fbx',
  crouch: '/models/mixamo/Crouching.fbx',
};

export class Character {
  constructor(scene) {
    this.scene = scene;
    this.root = new THREE.Group();
    this.root.name = 'Player';
    this.mixer = null;
    this.actions = {};
    this.state = 'idle';
    this.crouching = false;
    this.ready = false;
    this.height = 1.72;
    scene.add(this.root);
  }

  async init() {
    const glb = await tryLoadGltf(GLB_PATH);
    if (glb) {
      this.root.add(glb.scene);
      this.mixer = new THREE.AnimationMixer(glb.scene);
      for (const clip of glb.animations) this.actions[guessClipName(clip.name)] = this.mixer.clipAction(clip);
    } else {
      this.buildPlaceholder();
      this.mixer = new THREE.AnimationMixer(this.root);
      this.installProceduralClips();
    }
    await this.tryMixamo();
    if (!this.actions.idle) this.installProceduralClips();
    this.play('idle');
    this.ready = true;
  }

  buildPlaceholder() {
    const skin = new THREE.MeshStandardMaterial({ color: 0xc4a07a, roughness: 0.7 });
    const robe = new THREE.MeshStandardMaterial({ color: 0x6a6a68, roughness: 0.7, metalness: 0.02 });
    const robeDark = new THREE.MeshStandardMaterial({ color: 0x3a3a38, roughness: 0.72 });
    this._robeMats = [robe, robeDark];
    const hair = new THREE.MeshStandardMaterial({ color: 0x2a221c, roughness: 0.9 });
    const shoe = new THREE.MeshStandardMaterial({ color: 0x3a3530, roughness: 0.85 });

    const hip = new THREE.Group();
    hip.name = 'Hip';
    hip.position.y = 0.92;
    this.root.add(hip);

    const torso = new THREE.Mesh(new THREE.BoxGeometry(0.42, 0.58, 0.26), robe);
    torso.name = 'Torso';
    torso.castShadow = true;
    hip.add(torso);

    const skirt = new THREE.Mesh(new THREE.BoxGeometry(0.46, 0.34, 0.3), robeDark);
    skirt.position.y = -0.4;
    torso.add(skirt);

    const head = new THREE.Mesh(new THREE.SphereGeometry(0.13, 10, 8), skin);
    head.name = 'Head';
    head.position.y = 0.42;
    torso.add(head);
    const scalp = new THREE.Mesh(new THREE.SphereGeometry(0.132, 10, 8, 0, Math.PI * 2, 0, 1.1), hair);
    scalp.position.y = 0.02;
    head.add(scalp);

    const number = makeNumberDecal('104');
    number.position.set(0, 0.05, -0.14);
    torso.add(number);

    this.makeLimb(hip, 'LeftArm', -0.26, 0.22, 0, robe, 0.22, true);
    this.makeLimb(hip, 'RightArm', 0.26, 0.22, 0, robe, 0.22, true);
    this.makeLimb(hip, 'LeftLeg', -0.1, -0.28, 0, robeDark, 0.38, false);
    this.makeLimb(hip, 'RightLeg', 0.1, -0.28, 0, robeDark, 0.38, false);

    const lshoe = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.06, 0.2), shoe);
    lshoe.position.set(-0.1, 0.03, 0.04);
    this.root.add(lshoe);
    const rshoe = lshoe.clone();
    rshoe.position.x = 0.1;
    this.root.add(rshoe);
    this._shoes = [lshoe, rshoe];
    this._scalp = scalp;
  }

  hideForFirstPerson() {
    this.root.visible = false;
  }

  shave() {
    if (this._scalp) this._scalp.visible = false;
  }

  applyKazenka() {
    for (const m of this._robeMats || []) m.color.set(0x5c5c5a);
  }

  makeLimb(parent, name, x, y, z, mat, len, isArm) {
    const g = new THREE.Group();
    g.name = name;
    g.position.set(x, y, z);
    const mesh = new THREE.Mesh(
      new THREE.BoxGeometry(isArm ? 0.1 : 0.13, len, isArm ? 0.1 : 0.14),
      mat,
    );
    mesh.position.y = isArm ? -len * 0.35 : -len * 0.5;
    mesh.castShadow = true;
    g.add(mesh);
    parent.add(g);
    return g;
  }

  installProceduralClips() {
    if (!this.mixer) this.mixer = new THREE.AnimationMixer(this.root);
    const idle = this.makeClip('idle', 2.2, 0.06, 0.08, 0);
    const walk = this.makeClip('walk', 0.7, 0.45, 0.55, 0.12);
    const run = this.makeClip('run', 0.42, 0.7, 0.75, 0.2);
    const crouch = this.makeClip('crouch', 1.1, 0.2, 0.25, 0, true);
    for (const clip of [idle, walk, run, crouch]) {
      if (!this.actions[clip.name]) {
        const action = this.mixer.clipAction(clip);
        action.enabled = true;
        this.actions[clip.name] = action;
      }
    }
  }

  makeClip(name, duration, legAmp, armAmp, bob, crouch = false) {
    const times = [];
    const frames = 9;
    for (let i = 0; i < frames; i++) times.push((i / (frames - 1)) * duration);
    const qTrack = (objName, axisAmp, phase) => {
      const values = [];
      const q = new THREE.Quaternion();
      const e = new THREE.Euler();
      for (let i = 0; i < frames; i++) {
        const t = i / (frames - 1);
        const a = Math.sin(t * Math.PI * 2 + phase) * axisAmp;
        e.set(a, 0, 0);
        q.setFromEuler(e);
        values.push(q.x, q.y, q.z, q.w);
      }
      return new THREE.QuaternionKeyframeTrack(`${objName}.quaternion`, times, values);
    };
    const tracks = [
      qTrack('LeftLeg', legAmp, 0),
      qTrack('RightLeg', legAmp, Math.PI),
      qTrack('LeftArm', armAmp, Math.PI),
      qTrack('RightArm', armAmp, 0),
    ];
    const hipY = [];
    for (let i = 0; i < frames; i++) {
      const t = i / (frames - 1);
      const base = crouch ? 0.62 : 0.92;
      hipY.push(base + Math.abs(Math.sin(t * Math.PI * 2)) * bob);
    }
    tracks.push(new THREE.NumberKeyframeTrack('Hip.position[y]', times, hipY));
    const clip = new THREE.AnimationClip(name, duration, tracks);
    return clip;
  }

  async tryMixamo() {
    const loader = new FBXLoader();
    for (const [key, url] of Object.entries(MIXAMO)) {
      const ok = await exists(url);
      if (!ok) continue;
      try {
        const fbx = await loader.loadAsync(url);
        const clip = fbx.animations?.[0];
        if (clip && this.mixer) this.actions[key] = this.mixer.clipAction(clip);
      } catch {
        /* stub path missing or incompatible — keep placeholder clip */
      }
    }
  }

  play(name) {
    if (this.state === name) return;
    const next = this.actions[name] || this.actions.idle;
    if (!next) return;
    const prev = this.actions[this.state];
    next.reset().setEffectiveWeight(1).play();
    if (prev && prev !== next) prev.crossFadeTo(next, 0.18, false);
    else next.fadeIn(0.12);
    this.state = name;
  }

  setLocomotion(mag, run, crouch) {
    this.crouching = crouch;
    if (crouch) {
      this.play(this.actions.crouch ? 'crouch' : mag > 0.08 ? 'walk' : 'idle');
      if (this.root.getObjectByName('Hip') && !this.actions.crouch) {
        this.root.getObjectByName('Hip').position.y = THREE.MathUtils.lerp(
          this.root.getObjectByName('Hip').position.y,
          0.62,
          0.2,
        );
      }
      return;
    }
    if (mag < 0.08) this.play('idle');
    else if (run && mag > 0.55) this.play('run');
    else this.play('walk');
  }

  update(dt) {
    this.mixer?.update(dt);
    if (this._shoes) {
      const hip = this.root.getObjectByName('Hip');
      const y = hip ? 0.03 : 0.03;
      this._shoes[0].position.y = y;
      this._shoes[1].position.y = y;
    }
  }

  get position() {
    return this.root.position;
  }

  get yawFacing() {
    return this.root.rotation.y;
  }
}

function makeNumberDecal(text) {
  const c = document.createElement('canvas');
  c.width = 128;
  c.height = 64;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#d9d2c4';
  ctx.fillRect(0, 0, 128, 64);
  ctx.strokeStyle = '#222';
  ctx.strokeRect(4, 4, 120, 56);
  ctx.fillStyle = '#111';
  ctx.font = 'bold 36px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 64, 34);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.MeshBasicMaterial({ map: tex });
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(0.18, 0.09), mat);
  mesh.rotation.y = Math.PI;
  return mesh;
}

function guessClipName(n) {
  const s = n.toLowerCase();
  if (s.includes('run')) return 'run';
  if (s.includes('walk')) return 'walk';
  if (s.includes('crouch')) return 'crouch';
  return 'idle';
}

async function exists(url) {
  try {
    const res = await fetch(url, { method: 'HEAD' });
    return res.ok;
  } catch {
    return false;
  }
}

async function tryLoadGltf(url) {
  if (!(await exists(url))) return null;
  try {
    return await new GLTFLoader().loadAsync(url);
  } catch {
    return null;
  }
}
