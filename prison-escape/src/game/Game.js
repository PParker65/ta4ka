import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { Input } from '../controls/Input.js';
import { Character } from './Character.js';
import { Prison, LAYOUT } from './Prison.js';
import { Guards } from './Guards.js';
import { CCTV } from './CCTV.js';
import { updateFlickerMaterials } from '../shaders/environment.js';
import { Sim } from './Sim.js';
import { Dialogue, KPP_DOCS, GREETING, ARTICLE_Q, TEA_Q } from './Dialogue.js';
import { Npcs } from './Npcs.js';
import { Minigames } from './Minigames.js';
import { AudioFx } from './AudioFx.js';
import { makeHands } from './Hands.js';
import { Chat } from './Chat.js';

export class Game {
  constructor(canvas) {
    this.canvas = canvas;
    this.mobile = isMobile();
    this.lowEnd = this.mobile || (navigator.hardwareConcurrency || 4) <= 4;
    this.alarm = false;
    this.alarmHold = 0;
    this.clock = new THREE.Clock();
    this.sim = new Sim();
    this.audio = new AudioFx();
    this.escort = null;
    this.guide = null;
    this.idle = 0;
    this.introT = 0;
  }

  async start() {
    this.audio.unlock();
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: !this.mobile,
      powerPreference: 'high-performance',
      logarithmicDepthBuffer: true,
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.mobile ? 1.15 : 1.5));
    this.renderer.setSize(window.innerWidth, window.innerHeight, false);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.18;
    this.renderer.shadowMap.enabled = !this.lowEnd;
    if (this.renderer.shadowMap.enabled) this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x8ea8bc);
    this.scene.fog = new THREE.Fog(0x9aadb8, 55, 170);

    this.camera = new THREE.PerspectiveCamera(62, window.innerWidth / window.innerHeight, 0.32, 260);
    this.hands = makeHands();
    this.camera.add(this.hands);
    this.scene.add(this.camera);

    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.02).texture;
    if ('environmentIntensity' in this.scene) this.scene.environmentIntensity = 0.22;

    this.hemi = new THREE.HemisphereLight(0xd8e4ee, 0x6a6050, 0.9);
    this.scene.add(this.hemi);
    this.fill = new THREE.PointLight(0xffe6c0, 0.35, 9, 1.6);
    this.scene.add(this.fill);
    this.alarmLight = new THREE.PointLight(0xff1a12, 0, 14, 1.2);
    this.scene.add(this.alarmLight);
    this.sun = new THREE.DirectionalLight(0xfff1d6, 1.35);
    this.sun.position.set(36, 54, -28);
    this.sun.castShadow = !this.lowEnd;
    if (this.sun.castShadow) {
      this.sun.shadow.mapSize.set(1024, 1024);
      this.sun.shadow.camera.near = 4;
      this.sun.shadow.camera.far = 140;
      this.sun.shadow.camera.left = -50;
      this.sun.shadow.camera.right = 50;
      this.sun.shadow.camera.top = 50;
      this.sun.shadow.camera.bottom = -50;
      this.sun.shadow.bias = -0.0008;
    }
    this.scene.add(this.sun);

    this.prison = new Prison(this.scene);
    this.prison.build();

    this.player = new Character(this.scene);
    await this.player.init();
    this.player.hideForFirstPerson();
    this.player.position.copy(this.prison.playerSpawn);

    this.npcs = new Npcs(this.scene);
    await this.npcs.spawnConvoy();
    await this.npcs.spawnCell(this.prison.cellOrigin.x, this.prison.cellOrigin.z);
    await this.npcs.spawnHatches(this.prison.doors || []);

    this.guards = new Guards(this.scene, this.prison);
    this.guards.spawn();
    this.cctv = new CCTV(this.renderer, this.scene, this.prison);
    this.cctv.setup();

    this.input = new Input({ mobile: this.mobile, canvas: this.canvas });
    this.input.yaw = 0;
    this.input.pitch = -0.04;
    if (this.mobile) document.getElementById('look-hint')?.classList.add('hidden');
    else document.getElementById('stick-root')?.classList.add('hidden');
    this.dialog = new Dialogue();
    this.chat = new Chat();
    this.minigames = new Minigames(this.sim, (m) => this.toast(m));
    this.setupComposer();
    this.bindUi();
    document.getElementById('hud')?.classList.add('hud-quiet');
    this.audio.ambient();
    this.audio.clang();
    this.audio.bark();
    this.subtitle('Двери автозака. Свет бьёт в глаза. Это уже не воля.');
    window.addEventListener('resize', () => this.onResize());
    this.renderer.setAnimationLoop(() => this.loop());
  }

  setupComposer() {
    this.composer = new EffectComposer(this.renderer);
    this.composer.addPass(new RenderPass(this.scene, this.camera));
    this.composer.addPass(new OutputPass());
  }

  bindUi() {
    document.getElementById('btn-shop').addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      this.unlockLook();
      document.getElementById('shop').classList.remove('hidden');
      document.getElementById('shop').classList.add('flex');
    });
    document.getElementById('btn-shop-close').addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      document.getElementById('shop').classList.add('hidden');
      document.getElementById('shop').classList.remove('flex');
    });
    document.querySelectorAll('.shop-btn').forEach((b) => {
      b.addEventListener('pointerdown', (e) => {
        e.stopPropagation();
        const pack = b.getAttribute('data-pack');
        if (pack === 'tea') this.sim.inv.tea += 3;
        if (pack === 'cigs') this.sim.inv.cigs += 8;
        if (pack === 'food') this.sim.inv.food += 2;
        this.sim.stress = Math.max(0, this.sim.stress - 8);
        this.sim.rep += 1;
        this.toast('Грев зачислен (демо, без оплаты)');
        this.syncHud();
      });
    });
    document.getElementById('btn-cards-close').addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      this.minigames.closeCards();
    });
    document.getElementById('btn-shmon-done').addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      this.finishShmon();
    });
    document.getElementById('btn-talk')?.addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      this.openTalk();
    });
  }

  onResize() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);
    this.composer.setSize(w, h);
  }

  loop() {
    const dt = Math.min(0.05, this.clock.getDelta());
    this.tick(dt);
    updateFlickerMaterials(this.prison.flickerMats, this.clock.elapsedTime, this.alarm);
    if (this.clock.elapsedTime % 0.25 < dt + 0.002) this.cctv.renderFeeds(this.scene);
    this.composer.render();
    this.syncHud();
  }

  overlaysOpen() {
    if (this.dialog.open || this.minigames.open || this.chat.open) return true;
    if (!document.getElementById('shmon-ui').classList.contains('hidden')) return true;
    if (!document.getElementById('shop').classList.contains('hidden')) return true;
    return false;
  }

  tick(dt) {
    this.input.yaw += this.input.turnRate() * dt;
    if (this.overlaysOpen()) {
      this.updateCamera(this.input.crouchHeld);
      return;
    }

    const move = this.input.moveVector();
    const crouch = this.input.crouchHeld;
    const yaw = this.input.yaw;

    this.stepIntro(dt);
    if (this.introT >= 2.8 || this._hold) {
      if (this.escort) this.stepEscort(dt);
      else this.stepWalk(dt, move, crouch, yaw);
    }

    this.player.setLocomotion(this.escort ? 0.6 : move.mag, false, crouch);
    this.player.update(dt);
    this.npcs.update(this.clock.elapsedTime, this.player.position, this.camera);

    this.updateCamera(crouch);
    const outside = this.player.position.z < -53;
    this.sun.intensity = outside ? 1.35 : 0.1;
    this.hemi.intensity = outside ? 1.05 : 0.4;
    this.hemi.color.set(outside ? 0xd8e4ee : 0xc4b8a8);
    this.fill.intensity = outside ? 0.05 : 0.5;
    if (!outside) this.fill.position.set(this.player.position.x, 2.15, this.player.position.z);
    this.alarmLight.position.set(this.player.position.x, 2.15, this.player.position.z);
    this.scene.fog.near = outside ? 42 : 9;
    this.scene.fog.far = outside ? 155 : 34;
    this.scene.fog.color.set(outside ? 0x9aadb8 : 0x161410);
    this.scene.background.set(outside ? 0x9aadb8 : 0x161410);
    const lights = this.prison.searchlights;
    if (lights) {
      const t = this.clock.elapsedTime;
      for (const p of lights) p.rotation.y = t * 0.18 + (p.userData.phase || 0);
    }

    this.hands.children.forEach((c, i) => {
      if (c.name === 'Cuffs') {
        c.visible = this.sim.cuffed;
        return;
      }
      if (c.userData.baseY == null) c.userData.baseY = c.position.y;
      c.position.y = c.userData.baseY + Math.sin(this.clock.elapsedTime * 6 + i) * 0.012 * (move.mag + 0.15);
    });

    this.guards.update(dt);
    const inOwnCell = this.player.position.x > 1.55;
    const guardHit = this.sim.stage === 'life' && !inOwnCell && this.guards.sees(this.player.position, crouch);
    const camHit = this.cctv.update(dt, this.player.position, crouch, this.alarm);
    if (this.sim.stage === 'life' && this.sim.path !== 'red' && !inOwnCell && (guardHit || camHit)) {
      this.alarmHold = 3.5;
      this.sim.heat = Math.min(100, this.sim.heat + dt * 18);
    }
    this.alarmHold = Math.max(0, this.alarmHold - dt);
    this.setAlarm(this.alarmHold > 0);

    this.sim.tick(dt);
    this.updateStages();
    this.autoGuide(dt, move.mag);

    if (this.input.consumeTalk()) this.openTalk();

    const near = this.prison.nearestInteractable(this.player.position);
    const prompt = document.getElementById('prompt');
    if (near && this.canUse(near)) {
      prompt.classList.remove('hidden');
      prompt.textContent = this.label(near);
      if (this.input.consumeInteract()) this.interact(near);
    } else {
      prompt.classList.add('hidden');
      this.input.consumeInteract();
    }
  }

  stepWalk(dt, move, crouch, yaw) {
    if (this.sim.locked) return;
    if (this._hold) {
      move = {
        x: this._hold.code === 'KeyA' ? -1 : this._hold.code === 'KeyD' ? 1 : 0,
        z: this._hold.code === 'KeyS' ? 1 : this._hold.code === 'KeyW' ? -1 : 0,
        mag: 1,
        run: false,
      };
    }
    if (!this.sim.docs) move.run = false;
    const speed = this.sim.cuffed ? 1.05 : crouch ? 1.2 : move.run ? 3.2 : 2.1;
    const forward = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const right = new THREE.Vector3(Math.cos(yaw), 0, -Math.sin(yaw));
    const wish = new THREE.Vector3();
    wish.addScaledVector(right, move.x);
    wish.addScaledVector(forward, -move.z);
    if (this.guide && move.mag < 0.12) {
      const g = this.guide.clone().sub(this.player.position);
      g.y = 0;
      if (g.lengthSq() > 0.04) wish.add(g.normalize());
    }
    if (wish.lengthSq() > 0) wish.normalize();
    const next = this.player.position.clone();
    next.x += wish.x * speed * dt;
    next.z += wish.z * speed * dt;
    const resolved = this.prison.resolve(next, crouch ? 0.2 : 0.26);
    this.player.position.x = resolved.x;
    this.player.position.z = resolved.z;
    if (!this.sim.docs) {
      if (this.player.position.z < -88) {
        this.player.position.z = -88;
        this.audio.bark();
        this.toast('Конвой: «Стой. КПП впереди, не к забору.»');
        this.sim.stress = Math.min(100, this.sim.stress + 6);
      }
      if (move.run || move.mag > 0.85) {
        this.npcs.dogsAlert?.(true);
      }
    }
  }

  stepEscort(dt) {
    const pts = this.escort.pts;
    const i = this.escort.i;
    if (i >= pts.length - 1) {
      this.finishEscort();
      return;
    }
    const b = pts[i + 1];
    const dir = new THREE.Vector3(b.x - this.player.position.x, 0, b.z - this.player.position.z);
    const dist = dir.length();
    if (dist < 0.22) {
      this.escort.i += 1;
      this.escortEvent(b.event);
      return;
    }
    dir.multiplyScalar(1 / dist);
    const next = this.player.position.clone();
    const step = Math.min(1.45 * dt, dist);
    next.x += dir.x * step;
    next.z += dir.z * step;
    const resolved = this.prison.resolve(next, 0.2);
    this.player.position.x = resolved.x;
    this.player.position.z = resolved.z;
    const want = Math.atan2(dir.x, dir.z);
    let d = want - this.input.yaw;
    while (d > Math.PI) d -= Math.PI * 2;
    while (d < -Math.PI) d += Math.PI * 2;
    this.input.yaw += d * Math.min(1, dt * 3.2);
    this.npcs.followEscort(this.player.position, this.input.yaw);
  }

  escortEvent(ev) {
    if (ev === 'block') {
      this.prison.openDoor(this.prison.blockDoor);
      this.audio.clang();
      this.subtitle('Дверь из сборника. Дальше коряк — зелёные двери, за ними хаты.');
    }
    if (ev === 'voice') {
      this.subtitle('Из кормушки: «Свежак! Масть какая? Не здоровайся за руку вслепую.»');
    }
    if (ev === 'cell') {
      const door = this.prison.interactables.find((it) => it.type === 'cell-door');
      if (door) this.prison.openDoor(door);
      this.audio.clang();
      this.subtitle('Конвой: «Четвёртая. Заходи в дверь. Не боком — через порог.»');
    }
  }

  startEscort() {
    if (this.escort) return;
    this.sim.stage = 'escort';
    this.sim.cuffed = true;
    this.guide = null;
    const spawn = this.prison.cellSpawn;
    this.escort = {
      i: 0,
      pts: [
        { x: this.player.position.x, z: this.player.position.z },
        { x: 0, z: -0.85, event: 'block' },
        { x: 0, z: 1.2 },
        { x: 0, z: 2.45, event: 'voice' },
        { x: 0.05, z: 3.38, event: 'cell' },
        { x: LAYOUT.corridorHalf + 0.5, z: 3.42 },
        { x: spawn.x, z: spawn.z },
      ],
    };
    this.subtitle('Конвой: «Хату четыре. Шагом. Голову не поднимай без команды.»');
    this.audio.clang();
  }

  finishEscort() {
    this.escort = null;
    this.sim.cuffed = false;
    this.sim.locked = true;
    this.sim.stage = 'propiska';
    this.input.yaw = Math.PI / 2;
    this.subtitle('Ты зашёл через дверь. Теперь хата — не конвой.');
    this.audio.clang();
    clearTimeout(this._ragAuto);
    this._ragAuto = setTimeout(() => {
      if (this.sim.stage === 'propiska' && !this.dialog.open) this.greetingMenu();
    }, 700);
  }

  stepIntro(dt) {
    if (this.introDone) return;
    this.introT += dt;
    const fade = document.getElementById('fade');
    if (fade) {
      const o = Math.max(0, 1 - this.introT / 1.6);
      fade.style.opacity = String(o);
      if (o <= 0) fade.style.display = 'none';
    }
    if (!this._introBark && this.introT > 2.15) {
      this._introBark = true;
      this.subtitle('Конвой: «Выходи. Руки. Собака не игрушка.»');
      this.audio.bark();
    }
    if (this.introT > 2.8) {
      document.getElementById('hud')?.classList.remove('hud-quiet');
      this.introDone = true;
    }
  }

  autoGuide(dt, mag) {
    this.idle = mag > 0.12 || this.escort || this.introT < 2.8 ? 0 : this.idle + dt;
    if (this.sim.stage === 'kpp' && !this.sim.docs && this.idle > 6 && !this._kppNudge) {
      this._kppNudge = true;
      this.guide = new THREE.Vector3(3.4, 0, -56.2);
      this.subtitle('КПП справа от ворот. Документы. В камеру сразу не ведут.');
    }
    if (this.sim.stage === 'bath' && !this.sim.haircut && this.idle > 7) {
      this.interact(this.prison.interactables.find((x) => x.type === 'bath'));
      this.idle = 0;
    } else if (this.sim.stage === 'bath' && this.sim.haircut && this.sim.robe !== 'kazenka' && this.idle > 5) {
      this.interact(this.prison.interactables.find((x) => x.type === 'robe'));
      this.idle = 0;
    }
  }

  updateCamera(crouch) {
    const yaw = this.input.yaw;
    const pitch = this.input.pitch;
    const eye = crouch ? 1.08 : 1.64;
    let x = this.player.position.x;
    let z = this.player.position.z;
    if (z > -1.2 && z < LAYOUT.corridorLen) {
      const limit = LAYOUT.corridorHalf - 0.42;
      if (x > limit) x = limit;
      if (x < -limit) x = -limit;
    }
    this.camera.position.set(x, eye, z);
    const look = new THREE.Vector3(
      this.camera.position.x + Math.sin(yaw) * Math.cos(pitch),
      this.camera.position.y + Math.sin(pitch),
      this.camera.position.z + Math.cos(yaw) * Math.cos(pitch),
    );
    this.camera.lookAt(look);
  }

  updateStages() {
    if (this.sim.stage === 'bath' && this.sim.robe === 'kazenka' && !this.escort) this.startEscort();
  }

  canUse(item) {
    if (this.escort) return false;
    if (item.type === 'kpp') return !this.sim.docs;
    if (item.type === 'shmon') return this.sim.docs && this.sim.pending.length > 0;
    if (item.type === 'photo') return this.sim.pending.length === 0 && !this.sim.photo;
    if (item.type === 'med') return this.sim.photo && !this.sim.med;
    if (item.type === 'bath' || item.type === 'robe') return this.sim.med;
    if (item.type === 'block-door') return false;
    if (item.type === 'rag')
      return !this.sim.ragChoice && (this.sim.stage === 'propiska' || this.sim.stage === 'life');
    if (item.type === 'starosta') return this.sim.ragChoice && !this.sim.propiska;
    if (['bunk', 'bunk-other', 'wash', 'cards', 'malyava', 'obshak', 'food', 'admin'].includes(item.type))
      return this.sim.stage === 'life';
    return true;
  }

  label(item) {
    const map = {
      kpp: 'Сверка документов · КПП',
      shmon: 'Сдать вещи на опись',
      photo: 'Фото и дактилоскопия',
      med: 'Осмотр фельдшера',
      bath: 'Стрижка под машинку',
      'block-door': 'Дверь на коряк',
      'bunk-other': 'Чужая шконка',
      robe: 'Казёнка и галоши',
      rag: 'Тряпка на полу',
      starosta: 'Говорить со смотрящим',
      bunk: 'Лечь / нычка',
      wash: 'Умыться у чаши Генуя',
      cards: 'Карты на интерес',
      malyava: 'Дорога (малява)',
      obshak: 'Общак',
      food: 'Баландежка',
      admin: 'К администрации',
      'cell-door': item.open ? 'Дверь открыта' : 'Дверь хаты',
      'locked-door': `Дверь ${item.num} · заперто. За решёткой — чужая хата.`,
      monitor: 'Монитор',
      exit: 'Дворик для прогулок',
    };
    return map[item.type] || 'Действие';
  }

  interact(item) {
    if (!item) return;
    if (item.type === 'kpp') {
      this.unlockLook();
      this.dialog.show(KPP_DOCS.who, KPP_DOCS.text, KPP_DOCS.options);
      this.dialog.onPick = (opt) => {
        this.sim.docs = true;
        this.sim.stage = 'shmon';
        this.sim.shift(opt.black, opt.red, opt.men);
        this.toast(opt.reply);
        this.prison.openKpp();
        this.audio.clang();
        this.subtitle('Ворота. Дальше сборник: шмон, фото, врач, стрижка. В хату — потом.');
        this.guide = new THREE.Vector3(-1.2, 0, -36.2);
      };
      return;
    }
    if (item.type === 'shmon') {
      this.openShmon();
      return;
    }
    if (item.type === 'photo') {
      this.sim.photo = true;
      this.sim.stage = 'med';
      this.toast('Анфас, профиль. Отпечатки. Ты теперь номер, не имя.');
      this.subtitle('Дальше фельдшер. Ищут вшей, побои, заразу.');
      this.guide = new THREE.Vector3(-1.0, 0, -22.2);
      this.audio.buzz();
      return;
    }
    if (item.type === 'med') {
      this.sim.med = true;
      this.sim.stage = 'bath';
      this.toast('Температура норма. Наружных ран нет. В баню.');
      this.subtitle('Санитарная обработка: машинка и помывка. Как в кино — с тебя делают зэка.');
      this.guide = new THREE.Vector3(1.2, 0, -15.4);
      return;
    }
    if (item.type === 'bath') {
      this.player.shave();
      this.sim.haircut = true;
      this.sim.hygiene = Math.min(100, this.sim.hygiene + 25);
      this.toast('Машинка. Волосы на пол. Так встречают всех.');
      this.subtitle('Казёнку бери слева — серая полосатая, тапочки.');
      this.audio.clippers();
      this.guide = new THREE.Vector3(-0.9, 0, -13.6);
      return;
    }
    if (item.type === 'robe') {
      this.player.applyKazenka();
      this.hands.userData.setKazenka?.();
      this.sim.robe = 'kazenka';
      this.toast('Серая полосатая роба, тапочки. Теперь ты как все.');
      this.audio.clang();
      this.startEscort();
      return;
    }
    if (item.type === 'rag') {
      this.ragMenu();
      return;
    }
    if (item.type === 'starosta') {
      this.starostaTalk();
      return;
    }
    if (item.type === 'bunk') {
      if (!this.sim.propiska) {
        this.toast('Пока смотрящий не укажет койку — не садись.');
        return;
      }
      this.sim.rest();
      this.sim.heat = Math.max(0, this.sim.heat - 6);
      this.toast(this.sim.path === 'black' ? 'Нычка под матрасом на месте.' : 'Своя шконка. Чужую не занимай.');
      return;
    }
    if (item.type === 'bunk-other') {
      this.sim.stress = Math.min(100, this.sim.stress + 18);
      this.sim.shift(0, 1, 0);
      this.toast('Чужая шконка. Хатка косится. Так опускают за глупость, не за статью.');
      return;
    }
    if (item.type === 'wash') {
      this.sim.wash();
      this.toast('Холодная вода, чаша Генуя. Гигиена — не для красоты, для хаты.');
      return;
    }
    if (item.type === 'cards') {
      this.minigames.playCards();
      return;
    }
    if (item.type === 'malyava') {
      if (this.sim.path === 'red') {
        this.toast('Красным дорогу не дают.');
        return;
      }
      this.minigames.playRope();
      return;
    }
    if (item.type === 'obshak') {
      if (this.sim.path === 'red') {
        this.toast('Общак тебя не берёт.');
        this.sim.stress = Math.min(100, this.sim.stress + 10);
        return;
      }
      this.sim.inv.tea += 1;
      this.sim.shift(1, 0, 0);
      this.sim.rep += 1;
      this.toast('Чай в общак — и тебе чуть вернули.');
      return;
    }
    if (item.type === 'food') {
      if (this.sim.phase.id !== 'food' && this.sim.inv.food === 0) this.sim.inv.food += 1;
      if (!this.sim.eat()) this.toast('Баланды нет. Жди раздачу или грев.');
      else this.toast('Баланда. Голодно, но живой.');
      return;
    }
    if (item.type === 'admin') {
      this.sim.shift(0, 2, 0);
      this.sim.inv.food += 1;
      this.sim.heat = Math.max(0, this.sim.heat - 10);
      this.toast('Кумовые. Пайка лишняя, хата косится.');
      return;
    }
    if (item.type === 'cell-door') {
      this.prison.openDoor(item);
      this.audio.clang();
      return;
    }
    if (item.type === 'locked-door') {
      this.toast(`Дверь ${item.num} на замке. За кормушкой чужая жизнь.`);
      return;
    }
    if (item.type === 'monitor') {
      this.cctv.setActive(item.camIndex);
      return;
    }
    if (item.type === 'exit') {
      if (this.sim.phase.id !== 'walk' && this.sim.path !== 'red') {
        this.toast('Не время. Прогулка по распорядку.');
        this.sim.heat = Math.min(100, this.sim.heat + 12);
        return;
      }
      this.toast('Дворик. Круг по бетону. Говорить тихо.');
      this.sim.stress = Math.max(0, this.sim.stress - 10);
    }
  }

  unlockLook() {
    document.exitPointerLock?.();
  }

  openTalk() {
    if (this.overlaysOpen() && !this.chat.open) return;
    this.unlockLook();
    this.chat.toggle();
    if (this.chat.open) {
      const who = this.npcs.nearestKind(this.player.position);
      this.chat.push('Система', 'Напиши хате. Если кто-то ещё в игре — он увидит. Рядом отвечают зэки.', 'sys');
      this.chat.whoNear = who;
    }
  }

  openShmon() {
    const ui = document.getElementById('shmon-ui');
    const list = document.getElementById('shmon-list');
    list.innerHTML = '';
    for (const name of this.sim.pending) {
      const li = document.createElement('button');
      li.type = 'button';
      li.className =
        'block min-h-[48px] w-full rounded border border-zinc-600 bg-zinc-900 px-3 text-left text-[16px]';
      li.textContent = `Сдать: ${name}`;
      li.addEventListener('pointerdown', (e) => {
        e.stopPropagation();
        this.sim.surrendered.push(name);
        this.sim.pending = this.sim.pending.filter((x) => x !== name);
        li.remove();
        if (this.sim.pending.length === 0) document.getElementById('btn-shmon-done').textContent = 'Полный досмотр';
      });
      list.appendChild(li);
    }
    this.unlockLook();
    ui.classList.remove('hidden');
    ui.classList.add('flex');
  }

  finishShmon() {
    if (this.sim.pending.length) {
      this.toast('Сдай всё по списку');
      return;
    }
    document.getElementById('shmon-ui').classList.add('hidden');
    document.getElementById('shmon-ui').classList.remove('flex');
    this.sim.stage = 'photo';
    this.sim.stress = Math.min(100, this.sim.stress + 12);
    this.guide = new THREE.Vector3(1.1, 0, -28.2);
    this.subtitle('Опись закрыта. Теперь фото и пальцы — как в фильмах: с тебя делают номер.');
    this.audio.buzz();
  }

  greetingMenu() {
    this.unlockLook();
    this.dialog.show(GREETING.who, GREETING.text, GREETING.options);
    this.dialog.onPick = (opt) => {
      this.sim.greeting = opt.label;
      this.sim.shift(opt.black, opt.red, opt.men);
      this.toast(opt.reply);
      this.ragMenu();
    };
  }

  ragMenu() {
    this.unlockLook();
    this.dialog.show('Прописка', 'На пороге половая тряпка. Как войдёшь — так и запомнят. В настоящей хате это проверка, не шутка.', [
      {
        label: 'Перешагнуть, не трогая',
        black: 1,
        red: 0,
        men: 1,
        reply: 'Молча вошёл. Нормально. Седой кивнул.',
      },
      {
        label: 'Поднять и отнести в угол',
        black: 2,
        red: 0,
        men: 0,
        reply: 'Понял с полуслова. Смотрящий кивнул.',
      },
      {
        label: 'Пнуть ногой',
        black: 0,
        red: 1,
        men: 0,
        reply: 'Хатка затихла. Плохой заход.',
      },
    ]);
    this.dialog.onPick = (opt) => {
      this.sim.ragChoice = opt.label;
      this.sim.shift(opt.black, opt.red, opt.men);
      if (this.prison.ragMesh) this.prison.ragMesh.visible = false;
      this.toast(opt.reply);
      this.starostaTalk();
    };
  }

  starostaTalk() {
    this.unlockLook();
    this.dialog.show(ARTICLE_Q.who, ARTICLE_Q.text, ARTICLE_Q.options);
    this.dialog.onPick = (opt) => {
      this.sim.shift(opt.black, opt.red, opt.men);
      this.toast(opt.reply);
      this.teaTalk();
    };
  }

  teaTalk() {
    this.dialog.show(TEA_Q.who, TEA_Q.text, TEA_Q.options);
    this.dialog.onPick = (opt) => {
      this.sim.shift(opt.black, opt.red, opt.men);
      this.sim.tea = true;
      this.sim.propiska = true;
      this.sim.locked = false;
      this.sim.bunkAssigned = true;
      this.sim.stage = 'life';
      this.sim.cuffed = false;
      this.sim.rep += 2;
      this.toast(opt.reply);
      this.subtitle(
        'Нижняя у окна — твоя. Чужую не занимай. В сортир, пока едят — не ходи. Подъём, шмон, баландежка, прогулка, отбой.',
      );
    };
  }

  openTalkFromChatSend() {
    this.chat.whoNear = this.npcs.nearestKind(this.player.position);
  }

  setAlarm(on) {
    if (on === this.alarm) return;
    this.alarm = on;
    document.getElementById('alarm').classList.toggle('hidden', !on);
    if (on) this.toast('Конвой / камера');
    this.hemi.color.set(on ? 0xff6655 : 0xc4b8a8);
    this.alarmLight.intensity = on ? 2.2 : 0;
    this.guards.setAlarm(on);
  }

  subtitle(t) {
    const el = document.getElementById('sub');
    el.textContent = t;
    el.classList.remove('hidden');
    clearTimeout(this._sub);
    this._sub = setTimeout(() => el.classList.add('hidden'), 7200);
  }

  toast(t) {
    const el = document.getElementById('toast');
    el.textContent = t;
    el.classList.remove('hidden');
    clearTimeout(this._toast);
    this._toast = setTimeout(() => el.classList.add('hidden'), 2400);
  }

  holdWalk(code, seconds = 1.6) {
    this.input.keys.add(code);
    this.input.keys.add(code === 'KeyW' ? 'w' : code === 'KeyS' ? 's' : code === 'KeyA' ? 'a' : 'd');
    this._hold = { code, t: seconds };
    clearTimeout(this._walkHold);
    this._walkHold = setTimeout(() => {
      this.input.keys.delete(code);
      this.input.keys.delete('w');
      this.input.keys.delete('s');
      this.input.keys.delete('a');
      this.input.keys.delete('d');
      this._hold = null;
    }, seconds * 1000);
  }

  syncHud() {
    const s = this.sim;
    document.getElementById('clock').textContent =
      s.stage === 'life' ? `День ${s.day} · ${s.phase.label}` : `День 1 · ${stageName(s.stage)}`;
    document.getElementById('status').textContent = this.alarm ? 'ТРЕВОГА' : 'СИЗО · Катенька';
    document.getElementById('path-label').textContent = `Путь: ${s.pathLabel}`;
    document.getElementById('bar-hunger').style.setProperty('--w', `${s.hunger}%`);
    document.getElementById('bar-hygiene').style.setProperty('--w', `${s.hygiene}%`);
    document.getElementById('bar-stress').style.setProperty('--w', `${s.stress}%`);
    document.getElementById('inv').textContent = `чай ${s.inv.tea} · циг. ${s.inv.cigs} · пайка ${s.inv.food} · жар ${Math.round(s.heat)}`;
    const quest = document.getElementById('quest');
    if (quest) quest.textContent = s.objective();
    if (s.stage === 'life' || s.stage === 'propiska') document.getElementById('look-hint')?.classList.add('hidden');
  }
}

function stageName(st) {
  return { kpp: 'КПП', shmon: 'Шмон', bath: 'Баня', escort: 'Коряк', propiska: 'Прописка', life: 'Хата' }[st] || st;
}

function isMobile() {
  return /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) || window.innerWidth < 820;
}
