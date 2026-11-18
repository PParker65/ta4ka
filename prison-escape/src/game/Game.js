import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { SSAOPass } from 'three/addons/postprocessing/SSAOPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { Input } from '../controls/Input.js';
import { Character } from './Character.js';
import { Prison } from './Prison.js';
import { Guards } from './Guards.js';
import { CCTV } from './CCTV.js';
import { updateFlickerMaterials } from '../shaders/environment.js';
import { Sim } from './Sim.js';
import { Dialogue, STAROSTA_INTRO } from './Dialogue.js';
import { Npcs } from './Npcs.js';
import { Minigames } from './Minigames.js';
import { AudioFx } from './AudioFx.js';
import { makeHands } from './Hands.js';

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
  }

  async start() {
    this.audio.unlock();
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: !this.mobile,
      powerPreference: 'high-performance',
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.mobile ? 1.25 : 1.6));
    this.renderer.setSize(window.innerWidth, window.innerHeight, false);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 0.78;
    this.renderer.shadowMap.enabled = !this.lowEnd;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0b0c0e);
    this.scene.fog = new THREE.FogExp2(0x1a1512, 0.048);

    this.camera = new THREE.PerspectiveCamera(68, window.innerWidth / window.innerHeight, 0.07, 70);
    this.hands = makeHands();
    this.camera.add(this.hands);
    this.scene.add(this.camera);

    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

    this.hemi = new THREE.HemisphereLight(0xb8b0a0, 0x2a2018, 0.32);
    this.scene.add(this.hemi);
    this.fill = new THREE.PointLight(0xffe6c0, 1.15, 10, 1.5);
    this.scene.add(this.fill);
    this.alarmLight = new THREE.PointLight(0xff1a12, 0, 14, 1.2);
    this.scene.add(this.alarmLight);

    this.prison = new Prison(this.scene);
    this.prison.build();

    this.player = new Character(this.scene);
    await this.player.init();
    this.player.hideForFirstPerson();
    const spawn = this.prison.playerSpawn;
    this.player.position.copy(spawn);

    this.npcs = new Npcs(this.scene);
    await this.npcs.spawnConvoy();
    await this.npcs.spawnCell(this.prison.cellOrigin.x, this.prison.cellOrigin.z);

    this.guards = new Guards(this.scene, this.prison);
    this.guards.spawn();
    this.cctv = new CCTV(this.renderer, this.scene, this.prison);
    this.cctv.setup();

    this.input = new Input();
    this.input.yaw = 0;
    this.dialog = new Dialogue();
    this.minigames = new Minigames(this.sim, (m) => this.toast(m));
    this.setupComposer();
    this.bindUi();
    this.subtitle('Наручники. КПП. Не поднимай голову без команды.');
    this.audio.clang();
    window.addEventListener('resize', () => this.onResize());
    this.renderer.setAnimationLoop(() => this.loop());
  }

  setupComposer() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.composer = new EffectComposer(this.renderer);
    this.composer.addPass(new RenderPass(this.scene, this.camera));
    if (!this.lowEnd) {
      try {
        const ssao = new SSAOPass(this.scene, this.camera, w, h);
        ssao.kernelRadius = 8;
        this.composer.addPass(ssao);
        this.ssaoPass = ssao;
      } catch {
        /* skip */
      }
    }
    if (!this.mobile) {
      try {
        this.composer.addPass(new UnrealBloomPass(new THREE.Vector2(w, h), 0.22, 0.45, 0.85));
      } catch {
        /* skip */
      }
    }
    this.composer.addPass(new OutputPass());
  }

  bindUi() {
    document.getElementById('btn-shop').addEventListener('pointerdown', (e) => {
      e.stopPropagation();
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
    this.tick(dt);
    updateFlickerMaterials(this.prison.flickerMats, this.clock.elapsedTime, this.alarm);
    if (this.clock.elapsedTime % 0.25 < dt + 0.002) this.cctv.renderFeeds(this.scene);
    this.composer.render();
    this.syncHud();
  }

  tick(dt) {
    if (this.dialog.open || this.minigames.open) return;
    if (!document.getElementById('shmon-ui').classList.contains('hidden')) return;
    if (!document.getElementById('shop').classList.contains('hidden')) return;

    const move = this.input.moveVector();
    const crouch = this.input.crouchHeld;
    const yaw = this.input.yaw;
    const speed = this.sim.cuffed ? 1.15 : crouch ? 1.2 : move.run ? 3.2 : 2.1;
    const forward = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const right = new THREE.Vector3(Math.cos(yaw), 0, -Math.sin(yaw));
    const wish = new THREE.Vector3();
    wish.addScaledVector(right, move.x);
    wish.addScaledVector(forward, -move.z);
    if (wish.lengthSq() > 0) wish.normalize();

    const next = this.player.position.clone();
    next.x += wish.x * speed * dt;
    next.z += wish.z * speed * dt;
    const resolved = this.prison.resolve(next, crouch ? 0.2 : 0.26);
    this.player.position.x = resolved.x;
    this.player.position.z = resolved.z;
    this.player.setLocomotion(move.mag, false, crouch);
    this.player.update(dt);
    this.npcs.update(this.clock.elapsedTime);

    this.updateCamera(crouch);
    this.fill.position.set(this.player.position.x, 2.2, this.player.position.z);
    this.alarmLight.position.copy(this.fill.position);

    this.hands.children.forEach((c, i) => {
      if (c.name === 'Cuffs') {
        c.visible = this.sim.cuffed;
        return;
      }
      if (c.userData.baseY == null) c.userData.baseY = c.position.y;
      c.position.y = c.userData.baseY + Math.sin(this.clock.elapsedTime * 6 + i) * 0.012 * (move.mag + 0.15);
    });

    this.guards.update(dt);
    const guardHit = this.sim.stage === 'life' && this.guards.sees(this.player.position, crouch);
    const camHit = this.cctv.update(dt, this.player.position, crouch, this.alarm);
    if (this.sim.stage === 'life' && this.sim.path !== 'red' && (guardHit || camHit)) this.alarmHold = 3.5;
    this.alarmHold = Math.max(0, this.alarmHold - dt);
    this.setAlarm(this.alarmHold > 0);

    this.sim.tick(dt);
    this.updateStages();

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

  updateCamera(crouch) {
    const yaw = this.input.yaw;
    const pitch = this.input.pitch;
    const eye = crouch ? 1.05 : 1.58;
    this.camera.position.set(this.player.position.x, eye, this.player.position.z);
    const look = new THREE.Vector3(
      this.camera.position.x + Math.sin(yaw) * Math.cos(pitch),
      this.camera.position.y + Math.sin(pitch),
      this.camera.position.z + Math.cos(yaw) * Math.cos(pitch),
    );
    this.camera.lookAt(look);
  }

  updateStages() {
    const z = this.player.position.z;
    if (this.sim.stage === 'kpp' && z > -13.5) {
      this.sim.stage = 'shmon';
      this.subtitle('Кабинет досмотра. Сдай вещи на опись.');
      this.audio.clang();
    }
    if (this.sim.stage === 'bath' && this.sim.robe === 'kazenka' && z > -1) {
      this.sim.stage = 'escort';
      this.sim.cuffed = false;
      const door = this.prison.interactables.find((it) => it.type === 'cell-door');
      if (door) this.prison.openDoor(door);
      this.subtitle('Коряк. Ведут в хату. Зелёные двери — камеры.');
    }
    if (this.sim.stage === 'escort' && z > 3.1 && this.player.position.x > 1.5) {
      this.sim.stage = 'propiska';
      this.subtitle('На полу тряпка. Не наступи вслепую — это прописка.');
    }
  }

  canUse(item) {
    if (item.type === 'kpp')
      return (this.sim.stage === 'kpp' || this.sim.stage === 'shmon') && this.sim.pending.length > 0;
    if (item.type === 'shmon')
      return this.sim.pending.length > 0 && (this.sim.stage === 'shmon' || this.sim.stage === 'kpp');
    if (item.type === 'bath' || item.type === 'robe') return this.sim.stage === 'bath' || this.sim.pending.length === 0;
    if (item.type === 'rag')
      return !this.sim.ragChoice && (this.sim.stage === 'propiska' || this.sim.stage === 'life');
    if (item.type === 'starosta') return this.sim.ragChoice && !this.sim.propiska;
    if (['bunk', 'wash', 'cards', 'malyava', 'obshak', 'food', 'admin'].includes(item.type))
      return this.sim.stage === 'life';
    return true;
  }

  label(item) {
    const map = {
      kpp: 'Дальше, на шмон',
      shmon: 'Сдать вещи',
      bath: 'Стрижка под машинку',
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
      'locked-door': `Дверь ${item.num} · заперто`,
      monitor: 'Монитор',
      exit: 'Дворик для прогулок',
    };
    return map[item.type] || 'Действие';
  }

  interact(item) {
    if (item.type === 'kpp' || (item.type === 'shmon' && this.sim.pending.length)) {
      this.openShmon();
      return;
    }
    if (item.type === 'shmon') {
      this.openShmon();
      return;
    }
    if (item.type === 'bath') {
      this.player.shave();
      this.sim.haircut = true;
      this.sim.hygiene = Math.min(100, this.sim.hygiene + 25);
      this.toast('Машинка. Волосы на пол.');
      this.subtitle('Казёнку бери слева.');
      return;
    }
    if (item.type === 'robe') {
      this.player.applyKazenka();
      this.sim.robe = 'kazenka';
      this.sim.stage = 'bath';
      this.toast('Серая полосатая роба, тапочки.');
      this.audio.clang();
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
      this.sim.rest();
      this.toast(this.sim.path === 'black' ? 'Нычка под матрасом на месте.' : 'Лёг. Стресс чуть спал.');
      return;
    }
    if (item.type === 'wash') {
      this.sim.wash();
      this.toast('Холодная вода, чаша Генуя.');
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
      this.toast('Чай в общак — и тебе чуть вернули.');
      return;
    }
    if (item.type === 'food') {
      if (this.sim.phase.id !== 'food' && this.sim.inv.food === 0) {
        this.sim.inv.food += 1;
      }
      if (!this.sim.eat()) this.toast('Баланды нет. Жди раздачу или грев.');
      else this.toast('Баланда. Голодно, но живой.');
      return;
    }
    if (item.type === 'admin') {
      this.sim.shift(0, 2, 0);
      this.sim.inv.food += 1;
      this.toast('Кумовые. Пайка лишняя, хата косится.');
      return;
    }
    if (item.type === 'cell-door') {
      this.prison.openDoor(item);
      this.audio.clang();
      return;
    }
    if (item.type === 'locked-door') {
      this.toast(`Дверь ${item.num} на замке`);
      return;
    }
    if (item.type === 'monitor') {
      this.cctv.setActive(item.camIndex);
      return;
    }
    if (item.type === 'exit') {
      if (this.sim.phase.id !== 'walk' && this.sim.path !== 'red') {
        this.toast('Не время. Прогулка по распорядку.');
        return;
      }
      this.toast('Дворик. Круг по бетону.');
      this.sim.stress = Math.max(0, this.sim.stress - 10);
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
    this.sim.stage = 'bath';
    this.sim.stress = Math.min(100, this.sim.stress + 12);
    this.subtitle('Досмотр окончен. Баня. Стрижка обязательно.');
    this.audio.buzz();
  }

  ragMenu() {
    this.dialog.show('Прописка', 'На пороге половая тряпка. Как войдёшь — так и запомнят.', [
      {
        label: 'Перешагнуть, не трогая',
        black: 1,
        red: 0,
        men: 1,
        reply: 'Молча вошёл. Нормально.',
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
    this.dialog.show(STAROSTA_INTRO.who, STAROSTA_INTRO.text, STAROSTA_INTRO.options);
    this.dialog.onPick = (opt) => {
      this.sim.shift(opt.black, opt.red, opt.men);
      this.sim.propiska = true;
      this.sim.stage = 'life';
      this.sim.cuffed = false;
      this.toast(opt.reply);
      this.subtitle('Распорядок: подъём, шмон, баландежка, прогулка. Живи.');
    };
  }

  setAlarm(on) {
    if (on === this.alarm) return;
    this.alarm = on;
    document.getElementById('alarm').classList.toggle('hidden', !on);
    if (on) this.toast('Конвой / камера');
    this.hemi.color.set(on ? 0xff6655 : 0xb8b0a0);
    this.alarmLight.intensity = on ? 2.2 : 0;
    this.guards.setAlarm(on);
  }

  subtitle(t) {
    const el = document.getElementById('sub');
    el.textContent = t;
    el.classList.remove('hidden');
    clearTimeout(this._sub);
    this._sub = setTimeout(() => el.classList.add('hidden'), 5200);
  }

  toast(t) {
    const el = document.getElementById('toast');
    el.textContent = t;
    el.classList.remove('hidden');
    clearTimeout(this._toast);
    this._toast = setTimeout(() => el.classList.add('hidden'), 2200);
  }

  holdWalk(code, seconds = 1.6) {
    this.input.keys.add(code);
    this.input.keys.add(code === 'KeyW' ? 'w' : code === 'KeyS' ? 's' : code === 'KeyA' ? 'a' : 'd');
    clearTimeout(this._walkHold);
    this._walkHold = setTimeout(() => {
      this.input.keys.delete(code);
      this.input.keys.delete('w');
      this.input.keys.delete('s');
      this.input.keys.delete('a');
      this.input.keys.delete('d');
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
    document.getElementById('inv').textContent = `чай ${s.inv.tea} · циг. ${s.inv.cigs} · пайка ${s.inv.food}`;
  }
}

function stageName(st) {
  return { kpp: 'КПП', shmon: 'Шмон', bath: 'Баня', escort: 'Коряк', propiska: 'Прописка', life: 'Хата' }[st] || st;
}

function isMobile() {
  return /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) || window.innerWidth < 820;
}
