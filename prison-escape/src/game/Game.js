import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { SSAOPass } from 'three/addons/postprocessing/SSAOPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { Input } from '../controls/Input.js';
import { Character } from './Character.js';
import { Prison, LAYOUT } from './Prison.js';
import { Guards } from './Guards.js';
import { CCTV } from './CCTV.js';
import { updateFlickerMaterials } from '../shaders/environment.js';

export class Game {
  constructor(canvas) {
    this.canvas = canvas;
    this.mobile = isMobile();
    this.lowEnd = this.mobile || (navigator.hardwareConcurrency || 4) <= 4;
    this.alarm = false;
    this.alarmHold = 0;
    this.won = false;
    this.t0 = performance.now();
    this.clock = new THREE.Clock();
    this.camDist = 3.15;
    this.camTarget = new THREE.Vector3();
    this.lookPoint = new THREE.Vector3();
  }

  async start() {
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: !this.mobile,
      powerPreference: 'high-performance',
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.mobile ? 1.25 : 1.6));
    this.renderer.setSize(window.innerWidth, window.innerHeight, false);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 0.92;
    this.renderer.shadowMap.enabled = !this.lowEnd;
    this.renderer.shadowMap.type = THREE.BasicShadowMap;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0b0c0e);
    this.scene.fog = new THREE.FogExp2(0x1a1512, 0.045);

    this.camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.08, 70);
    this.camera.position.set(4, 1.5, 7);
    this._camRay = new THREE.Raycaster();
    this._camDir = new THREE.Vector3();

    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

    this.hemi = new THREE.HemisphereLight(0xc4c0b0, 0x3a2a22, 0.35);
    this.scene.add(this.hemi);
    this.fill = new THREE.PointLight(0xfff2d0, 1.4, 11, 1.4);
    this.fill.position.set(0, 2.4, 4);
    this.scene.add(this.fill);
    this.alarmLight = new THREE.PointLight(0xff1a12, 0, 16, 1.2);
    this.scene.add(this.alarmLight);

    this.prison = new Prison(this.scene);
    this.prison.build();

    this.player = new Character(this.scene);
    await this.player.init();
    const spawn = this.prison.playerSpawn || new THREE.Vector3(4, 0, 5);
    this.player.position.copy(spawn);
    this.player.root.rotation.y = -Math.PI / 2;

    this.guards = new Guards(this.scene, this.prison);
    this.guards.spawn();

    this.cctv = new CCTV(this.renderer, this.scene, this.prison);
    this.cctv.setup();

    this.input = new Input();
    this.input.yaw = Math.PI / 2;
    this.setupComposer();
    this.bindUi();
    window.addEventListener('resize', () => this.onResize());
    this.loop = this.loop.bind(this);
    this.renderer.setAnimationLoop(this.loop);
  }

  setupComposer() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.composer = new EffectComposer(this.renderer);
    this.composer.addPass(new RenderPass(this.scene, this.camera));
    this.useSsao = !this.lowEnd;
    this.useBloom = !this.mobile;
    if (this.useSsao) {
      try {
        const ssao = new SSAOPass(this.scene, this.camera, w, h);
        ssao.kernelRadius = 8;
        ssao.minDistance = 0.004;
        ssao.maxDistance = 0.12;
        this.composer.addPass(ssao);
        this.ssaoPass = ssao;
      } catch {
        this.useSsao = false;
      }
    }
    if (this.useBloom) {
      try {
        const bloom = new UnrealBloomPass(new THREE.Vector2(w, h), 0.28, 0.5, 0.82);
        this.composer.addPass(bloom);
        this.bloomPass = bloom;
      } catch {
        this.useBloom = false;
      }
    }
    this.composer.addPass(new OutputPass());
  }

  bindUi() {
    document.getElementById('btn-again').addEventListener('click', () => location.reload());
  }

  onResize() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);
    this.composer.setSize(w, h);
    this.ssaoPass?.setSize(w, h);
  }

  loop() {
    const dt = Math.min(0.05, this.clock.getDelta());
    if (!this.won) this.tick(dt);
    updateFlickerMaterials(this.prison.flickerMats, this.clock.elapsedTime, this.alarm);
    if (this.clock.elapsedTime % 0.2 < dt + 0.001) this.cctv.renderFeeds(this.scene);
    this.composer.render();
    const elapsed = (performance.now() - this.t0) / 1000;
    const mm = String(Math.floor(elapsed / 60)).padStart(2, '0');
    const ss = String(Math.floor(elapsed % 60)).padStart(2, '0');
    document.getElementById('clock').textContent = `${mm}:${ss}`;
  }

  tick(dt) {
    const move = this.input.moveVector();
    const crouch = this.input.crouchHeld;
    const yaw = this.input.yaw;
    const speed = crouch ? 1.25 : move.run ? 4.4 : 2.35;
    const forward = new THREE.Vector3(-Math.sin(yaw), 0, -Math.cos(yaw));
    const right = new THREE.Vector3(Math.cos(yaw), 0, -Math.sin(yaw));
    const wish = new THREE.Vector3();
    wish.addScaledVector(right, move.x);
    wish.addScaledVector(forward, -move.z);
    if (wish.lengthSq() > 0) wish.normalize();

    const next = this.player.position.clone();
    next.x += wish.x * speed * dt;
    next.z += wish.z * speed * dt;
    const resolved = this.prison.resolve(next, crouch ? 0.22 : 0.28);
    this.player.position.x = resolved.x;
    this.player.position.z = resolved.z;
    this.player.position.y = 0;
    if (wish.lengthSq() > 0.002) this.player.root.rotation.y = Math.atan2(wish.x, wish.z);
    this.player.setLocomotion(move.mag, move.run, crouch);
    this.player.update(dt);

    this.updateCamera(dt, crouch);
    this.fill.position.set(this.player.position.x, 2.35, this.player.position.z);
    this.alarmLight.position.set(this.player.position.x, 2.6, this.player.position.z);

    this.guards.update(dt);
    const guardHit = this.guards.sees(this.player.position, crouch);
    const camHit = this.cctv.update(dt, this.player.position, crouch, this.alarm);
    if (guardHit || camHit) this.alarmHold = 4.5;
    this.alarmHold = Math.max(0, this.alarmHold - dt);
    this.setAlarm(this.alarmHold > 0, guardHit ? 'Фонарь охраны' : camHit);

    const near = this.prison.nearestInteractable(this.player.position);
    const prompt = document.getElementById('prompt');
    if (near) {
      prompt.classList.remove('hidden');
      prompt.textContent = labelFor(near);
      if (this.input.consumeInteract()) this.interact(near);
    } else {
      prompt.classList.add('hidden');
      this.input.consumeInteract();
    }
  }

  updateCamera(dt, crouch) {
    const yaw = this.input.yaw;
    const pitch = Math.min(this.input.pitch, 0.62);
    const head = crouch ? 0.95 : 1.38;
    this.lookPoint.set(this.player.position.x, this.player.position.y + head, this.player.position.z);
    this._camDir.set(
      Math.sin(yaw) * Math.cos(pitch),
      Math.sin(pitch) * 0.72,
      Math.cos(yaw) * Math.cos(pitch),
    ).normalize();
    this._camRay.set(this.lookPoint, this._camDir);
    this._camRay.near = 0.2;
    this._camRay.far = this.camDist + 0.35;
    const hits = this._camRay.intersectObject(this.prison.group, true);
    let dist = this.camDist;
    for (const h of hits) {
      if (!h.object?.userData?.camCollide) continue;
      dist = Math.min(dist, Math.max(1.35, h.distance - 0.28));
      break;
    }
    const desired = this.lookPoint.clone().addScaledVector(this._camDir, dist);
    desired.y = THREE.MathUtils.clamp(desired.y, 1.05, 2.35);
    this.camera.position.lerp(desired, 1 - Math.exp(-12 * dt));
    this.camTarget.lerp(this.lookPoint, 0.28);
    this.camera.lookAt(this.camTarget);
  }

  setAlarm(on, reason) {
    if (on === this.alarm) {
      if (on) document.getElementById('status').textContent = `ТРЕВОГА · ${reason || 'СИЗО'}`;
      return;
    }
    this.alarm = on;
    document.getElementById('alarm').classList.toggle('hidden', !on);
    document.getElementById('status').textContent = on ? `ТРЕВОГА · ${reason || ''}` : 'СИЗО · Катенька';
    this.hemi.color.set(on ? 0xff6655 : 0xc4c0b0);
    this.hemi.groundColor.set(on ? 0x4a1010 : 0x3a2a22);
    this.alarmLight.intensity = on ? 2.6 : 0;
    this.scene.fog.color.set(on ? 0x3a0808 : 0x1a1512);
    this.guards.setAlarm(on);
    const toast = document.getElementById('toast');
    if (on) {
      toast.textContent = 'Тревога! Камера / фонарь';
      toast.classList.remove('hidden');
      clearTimeout(this._toast);
      this._toast = setTimeout(() => toast.classList.add('hidden'), 1600);
    }
  }

  interact(item) {
    if (item.type === 'cell-door') {
      this.prison.openDoor(item);
      document.getElementById('status').textContent = `Дверь ${item.num} открыта`;
      return;
    }
    if (item.type === 'locked-door') {
      document.getElementById('prompt').textContent = `Дверь ${item.num} закрыта`;
      return;
    }
    if (item.type === 'monitor') {
      this.cctv.setActive(item.camIndex);
      document.getElementById('status').textContent = `Монитор ${item.camIndex + 1}`;
      return;
    }
    if (item.type === 'exit') {
      this.win();
    }
  }

  win() {
    this.won = true;
    const elapsed = (performance.now() - this.t0) / 1000;
    document.getElementById('win').classList.remove('hidden');
    document.getElementById('win').classList.add('flex');
    document.getElementById('win-time').textContent = `Дворик для прогулок · ${elapsed.toFixed(0)} с`;
  }
}

function isMobile() {
  return /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) || window.innerWidth < 820;
}

function labelFor(item) {
  if (item.type === 'cell-door') return item.open ? 'Дверь открыта' : 'Открыть дверь 4';
  if (item.type === 'locked-door') return `Дверь ${item.num} · заперто`;
  if (item.type === 'monitor') return 'Смотреть CCTV';
  if (item.type === 'exit') return 'Выйти во дворик';
  return 'Действие';
}
