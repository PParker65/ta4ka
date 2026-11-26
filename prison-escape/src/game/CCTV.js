import * as THREE from 'three';
import { createCrtMaterial } from '../shaders/crt.js';
import { LAYOUT } from './Prison.js';

export class CCTV {
  constructor(renderer, scene, prison) {
    this.renderer = renderer;
    this.scene = scene;
    this.prison = prison;
    this.cams = [];
    this.monitors = [];
    this.active = 0;
    this.hudCanvas = document.getElementById('cctv-hud');
    this.hudCtx = this.hudCanvas ? this.hudCanvas.getContext('2d') : null;
    this.scratch = document.createElement('canvas');
    this.scratch.width = 176;
    this.scratch.height = 120;
    this.time = 0;
    this.frame = 0;
    this.hudCam = null;
  }

  setup() {
    const size = 160;
    this.prison.cameras.forEach((spec, i) => {
      const cam = new THREE.PerspectiveCamera(42, 176 / 120, 0.1, 40);
      cam.position.copy(spec.position);
      cam.lookAt(spec.lookAt);
      const rt = new THREE.WebGLRenderTarget(size, 96, { depthBuffer: true });
      rt.texture.colorSpace = THREE.SRGBColorSpace;
      this.cams.push({ cam, rt, spec, dwell: 0 });

      const mat = createCrtMaterial(rt.texture);
      const screen = new THREE.Mesh(new THREE.PlaneGeometry(0.72, 0.48), mat);
      screen.position.set(LAYOUT.corridorHalf - 0.14, 1.62, 8.4 + i * 0.95);
      screen.rotation.y = -Math.PI / 2;
      this.scene.add(screen);
      const bezel = new THREE.Mesh(
        new THREE.BoxGeometry(0.08, 0.56, 0.8),
        new THREE.MeshStandardMaterial({ color: 0x1a1c18, roughness: 0.7 }),
      );
      bezel.position.copy(screen.position);
      bezel.position.x += 0.04;
      this.scene.add(bezel);
      this.monitors.push({ mesh: screen, mat });

      this.prison.interactables.push({
        id: `monitor-${i}`,
        type: 'monitor',
        position: new THREE.Vector3(0.35, 1, 8.4 + i * 0.95),
        radius: 1.5,
        camIndex: i,
      });
    });

    this.hudCam = new THREE.PerspectiveCamera(50, 176 / 120, 0.12, 40);
  }

  update(dt, playerPos, crouching, alarm) {
    this.time += dt;
    this.frame++;
    let spotted = null;
    this.cams.forEach((c, i) => {
      const origin = c.spec.position;
      const look = c.spec.lookAt.clone().sub(origin).normalize();
      const to = playerPos.clone();
      to.y = crouching ? 0.7 : 1.15;
      const delta = to.sub(origin);
      const dist = delta.length();
      const range = crouching ? c.spec.range * 0.6 : c.spec.range;
      if (dist < range && delta.normalize().dot(look) > Math.cos(c.spec.angle)) {
        c.dwell += dt;
        if (c.dwell > 0.35) spotted = c.spec.id;
      } else {
        c.dwell = Math.max(0, c.dwell - dt * 2);
      }
      this.monitors[i].mat.uniforms.uTime.value = this.time;
    });
    return spotted;
  }

  renderFeeds(scene) {
    const i = this.frame % this.cams.length;
    const c = this.cams[i];
    if (!c) return;
    for (const m of this.monitors) m.mesh.visible = false;
    const prev = this.renderer.getRenderTarget();
    this.renderer.setRenderTarget(c.rt);
    this.renderer.render(scene, c.cam);
    this.renderer.setRenderTarget(prev);
    for (const m of this.monitors) m.mesh.visible = true;
    this.blitHud();
  }

  blitHud() {
    const src = this.cams[this.active];
    if (!src || !this.hudCtx) return;
    const ctx = this.hudCtx;
    try {
      const w = src.rt.width;
      const h = src.rt.height;
      const buf = new Uint8Array(w * h * 4);
      this.renderer.readRenderTargetPixels(src.rt, 0, 0, w, h, buf);
      if (this.scratch.width !== w || this.scratch.height !== h) {
        this.scratch.width = w;
        this.scratch.height = h;
      }
      const img = this.scratch.getContext('2d').createImageData(w, h);
      for (let y = 0; y < h; y++) {
        const srcRow = (h - 1 - y) * w * 4;
        img.data.set(buf.subarray(srcRow, srcRow + w * 4), y * w * 4);
      }
      this.scratch.getContext('2d').putImageData(img, 0, 0);
      ctx.drawImage(this.scratch, 0, 0, w, h, 0, 0, 176, 120);
    } catch {
      ctx.fillStyle = '#031a08';
      ctx.fillRect(0, 0, 176, 120);
    }
    ctx.fillStyle = 'rgba(0,255,70,0.12)';
    for (let y = 0; y < 120; y += 3) ctx.fillRect(0, y, 176, 1);
    ctx.fillStyle = 'rgba(180,255,180,0.12)';
    for (let i = 0; i < 40; i++) ctx.fillRect(Math.random() * 176, Math.random() * 120, 2, 1);
    const lab = document.getElementById('cctv-label');
    if (lab) lab.textContent = src.spec.id;
  }

  setActive(i) {
    this.active = i % this.cams.length;
  }

  seesPlayer() {
    return null;
  }
}
