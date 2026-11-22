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
import { Sim, PHASES } from './Sim.js';
import { Dialogue, KPP_DOCS, PHOTO_Q, MED_Q, BATH_Q, GREETING, ARTICLE_Q, TEA_Q } from './Dialogue.js';
import { Npcs } from './Npcs.js';
import { Minigames } from './Minigames.js';
import { AudioFx } from './AudioFx.js';
import { makeHands } from './Hands.js';
import { Chat } from './Chat.js';
import { storyLine, wayFor } from './Story.js';
import { plotObjective, walkLine } from './Plot.js';
import { lifeTick } from './Life.js';
import { CellLife } from './CellLife.js';

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
    window.speechSynthesis?.cancel();
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

    this.camera = new THREE.PerspectiveCamera(62, window.innerWidth / window.innerHeight, 0.08, 260);
    this.hands = makeHands();
    this.camera.add(this.hands);
    this.scene.add(this.camera);

    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.02).texture;
    if ('environmentIntensity' in this.scene) this.scene.environmentIntensity = 0.22;

    this.hemi = new THREE.HemisphereLight(0xd8e4ee, 0x6a6050, 0.9);
    this.scene.add(this.hemi);
    this.fill = new THREE.PointLight(0xffe6c0, 0.22, 12, 2);
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
    this.beacon = makeBeacon();
    this.scene.add(this.beacon);

    this.player = new Character(this.scene);
    await this.player.init();
    this.player.hideForFirstPerson();
    this.player.position.copy(this.prison.playerSpawn);

    this.npcs = new Npcs(this.scene);
    await this.npcs.spawnConvoy();
    await this.npcs.spawnCell(this.prison.cellOrigin.x, this.prison.cellOrigin.z, this.prison.seats);
    await this.npcs.spawnHatches(this.prison.doors || []);
    this.npcs.furniture = this.prison.furniture || [];
    this.npcs.prison = this.prison;
    this.npcs.cellOrigin = this.prison.cellOrigin;
    this.npcs.list.forEach((n) => {
      n.root.traverse((c) => {
        if (c.userData.billboard) c.visible = false;
      });
    });

    this.guards = new Guards(this.scene, this.prison);
    this.guards.spawn();
    this.cctv = new CCTV(this.renderer, this.scene, this.prison);
    this.cctv.setup();

    this.input = new Input({ mobile: this.mobile, canvas: this.canvas });
    this.input.onUnlockAudio = () => this.audio.unlock();
    this.cellLife = new CellLife(this);
    this.input.yaw = 0;
    this.input.pitch = 0.06;
    this.camera.fov = 48;
    this.camera.updateProjectionMatrix();
    this.renderer.toneMappingExposure = 0.38;
    this.hands.visible = false;
    if (this.mobile) document.getElementById('look-hint')?.classList.add('hidden');
    this.dialog = new Dialogue();
    this.chat = new Chat();
    this.minigames = new Minigames(this.sim, (m) => this.toast(m));
    this.setupComposer();
    this.bindUi();
    document.getElementById('hud')?.classList.add('hud-quiet');
    this.audio.ambient();
    this.audio.rumble();
    this.audio.siren();
    window.addEventListener('resize', () => this.onResize());
    this.renderer.setAnimationLoop(() => this.loop());
    const params = new URLSearchParams(location.search);
    const at = params.get('at');
    if (at) {
      this.skipToPlace(at);
      this.applySkipFlags(params);
      this.applyLook(params);
    } else if (params.has('cell')) {
      this.skipToCell();
      this.applySkipFlags(params);
      const ph = params.get('phase');
      const story =
        Number(params.get('day') || 0) >= 2 ||
        params.get('malyava') ||
        params.get('court') ||
        params.get('look');
      if (ph) this.forcePhase(ph);
      else if (story) this.forcePhase('wake');
      this.applyLook(params);
      if (params.get('look')) this._skipPlotDialog = true;
    }
  }

  skipToCell() {
    this.sim.docs = true;
    this.sim.pending = [];
    this.sim.photo = true;
    this.sim.med = true;
    this.sim.haircut = true;
    this.sim.robe = 'kazenka';
    this.sim.cuffed = false;
    this.sim.inv.tea = Math.max(1, this.sim.inv.tea);
    this.sim.inv.cigs = Math.max(1, this.sim.inv.cigs);
    this.player.shave();
    this.player.applyKazenka();
    this.hands.userData.setKazenka?.();
    this.hands.visible = true;
    this.introT = 22;
    this._introHud = true;
    this._introControl = true;
    this._introOut = true;
    this._introDoors = true;
    this._introLook = true;
    this.renderer.toneMappingExposure = 1.18;
    this.camera.fov = 62;
    this.camera.updateProjectionMatrix();
    const fade = document.getElementById('fade');
    if (fade) {
      fade.style.opacity = '0';
      fade.style.display = 'none';
    }
    document.getElementById('hud')?.classList.remove('hud-quiet');
    document.getElementById('quest')?.classList.remove('hidden');
    document.getElementById('look-hint')?.classList.add('hidden');
    this.scene.fog.near = 9;
    this.scene.fog.far = 34;
    this.scene.fog.color.set(0x161410);
    this.scene.background.set(0x161410);
    this.player.position.copy(this.prison.cellSpawn);
    this.npcs.list.forEach((n) => {
      n.root.traverse((c) => {
        if (c.userData.billboard) c.visible = true;
      });
    });
    const door = this.prison.interactables.find((it) => it.type === 'cell-door');
    if (door?.open) this.prison.closeDoor(door);
    this.prison.closeDoor(this.prison.blockDoor);
    this.finishEscort();
  }

  applySkipFlags(params) {
    const day = Number(params.get('day') || 0);
    if (day >= 2 && day <= 14) this.sim.day = day | 0;
    const mal = params.get('malyava');
    if (mal === 'hold' || mal === 'burn' || mal === 'admin' || mal === 'found' || mal === 'gone') this.sim.malyava = mal;
    if (mal === 'hold') this.sim.inv.tea = Math.max(this.sim.inv.tea, 1);
    const talk = params.get('court');
    if (talk === 'silent' || talk === 'cell' || talk === 'self') this.sim.courtTalk = talk;
    const stash = params.get('stash');
    if (stash === 'wash' || stash === 'bunk' || stash === 'none') this.sim.stash = stash;
    if (params.get('tea') === 'paid') this.sim.teaPaid = true;
  }

  applyLook(params) {
    const look = params.get('look');
    if (look === 'yardwall') {
      this.player.position.set(2.85, 0, LAYOUT.corridorLen + 3.85);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'krug') {
      this.player.position.set(-0.2, 0, LAYOUT.corridorLen + 5.2);
      this.input.yaw = 0.12;
      this.input.pitch = -0.92;
      return;
    }
    if (look === 'yardblank') {
      this.player.position.set(2.65, 0, LAYOUT.corridorLen + 7.35);
      this.input.yaw = 0.78;
      this.input.pitch = -0.28;
      return;
    }
    if (look === 'yardgate') {
      this.player.position.set(-0.15, 0, LAYOUT.corridorLen + 6.4);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'cage') {
      this.player.position.set(0.35, 0, LAYOUT.corridorLen + 6.15);
      this.input.yaw = Math.PI;
      this.input.pitch = 0.92;
      return;
    }
    if (look === 'cager') {
      this.player.position.set(-1.15, 0, LAYOUT.corridorLen + 6.95);
      this.input.yaw = Math.PI;
      this.input.pitch = 0.92;
      return;
    }
    if (look === 'cageb') {
      this.player.position.set(1.55, 0, LAYOUT.corridorLen + 4.85);
      this.input.yaw = Math.PI;
      this.input.pitch = 0.92;
      return;
    }
    if (look === 'shall') {
      this.player.position.set(0.15, 0, -36.4);
      this.input.yaw = 0;
      this.input.pitch = -0.52;
      return;
    }
    if (look === 'halls') {
      this.player.position.set(-0.38, 0, -41.45);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallq') {
      this.player.position.set(-0.85, 0, -39.85);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halt') {
      this.player.position.set(-0.85, 0, -27.2);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halln') {
      this.player.position.set(0.85, 0, -20.6);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halla') {
      this.player.position.set(0.85, 0, -33.8);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halll') {
      this.player.position.set(0.35, 0, -22.4);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallr') {
      this.player.position.set(0.85, 0, -36.4);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallw') {
      this.player.position.set(0.4, 0, -22.0);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'hallp') {
      this.player.position.set(0.2, 0, -36.0);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'hallv') {
      this.player.position.set(-0.58, 0, -14.2);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'hallk') {
      this.player.position.set(0.17, 0, -30.4);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'hallj') {
      this.player.position.set(-0.33, 0, -19.8);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'halli') {
      this.player.position.set(0.52, 0, -11.6);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'hallb') {
      this.player.position.set(0.55, 0, -11.2);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.52;
      return;
    }
    if (look === 'hallc') {
      this.player.position.set(-0.55, 0, -18.0);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.52;
      return;
    }
    if (look === 'halld') {
      this.player.position.set(-0.55, 0, -32.0);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.52;
      return;
    }
    if (look === 'halle') {
      this.player.position.set(0.55, 0, -25.6);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.52;
      return;
    }
    if (look === 'hallf') {
      this.player.position.set(0.55, 0, -38.4);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.52;
      return;
    }
    if (look === 'hallg') {
      this.player.position.set(0.85, 0, -28.05);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallh') {
      this.player.position.set(-0.85, 0, -33.2);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallm') {
      this.player.position.set(0.85, 0, -15.8);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallo') {
      this.player.position.set(-0.85, 0, -30.15);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallu') {
      this.player.position.set(0.85, 0, -40.5);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallz') {
      this.player.position.set(-0.85, 0, -12.4);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallt') {
      this.player.position.set(-0.85, 0, -22.6);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallaa') {
      this.player.position.set(0.85, 0, -30.85);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallbb') {
      this.player.position.set(0.85, 0, -18.1);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallcc') {
      this.player.position.set(-0.85, 0, -24.8);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halldd') {
      this.player.position.set(0.85, 0, -32.25);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallee') {
      this.player.position.set(-0.85, 0, -28.6);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallff') {
      this.player.position.set(0.85, 0, -23.2);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallgg') {
      this.player.position.set(-0.85, 0, -15.2);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallhh') {
      this.player.position.set(-0.85, 0, -20.5);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallii') {
      this.player.position.set(0.85, 0, -29.45);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halljj') {
      this.player.position.set(-0.85, 0, -13.8);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallkk') {
      this.player.position.set(0.85, 0, -21.85);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallll') {
      this.player.position.set(0.85, 0, -16.95);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallmm') {
      this.player.position.set(-0.85, 0, -16.55);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallnn') {
      this.player.position.set(-0.85, 0, -21.55);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halloo') {
      this.player.position.set(-0.85, 0, -25.9);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallpp') {
      this.player.position.set(0.85, 0, -34.95);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallqq') {
      this.player.position.set(-0.85, 0, -34.7);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallrr') {
      this.player.position.set(0.85, 0, -32.95);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallss') {
      this.player.position.set(-0.85, 0, -38.16);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halltt') {
      this.player.position.set(0.85, 0, -39.45);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'halluu') {
      this.player.position.set(0.85, 0, -35.6);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallvv') {
      this.player.position.set(-0.85, 0, -29.38);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallww') {
      this.player.position.set(0.85, 0, -26.85);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hallbag') {
      this.player.position.set(-0.72, 0, -31.55);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'hallx') {
      this.player.position.set(0.38, 0, -25.2);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'hally') {
      this.player.position.set(-0.22, 0, -17.4);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.48;
      return;
    }
    if (look === 'photo') {
      this.player.position.set(-0.2, 0, -28.2);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.58;
      return;
    }
    if (look === 'med') {
      this.player.position.set(-0.2, 0, -22.2);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.62;
      return;
    }
    if (look === 'bath') {
      this.player.position.set(0.45, 0, -15.4);
      this.input.yaw = Math.PI / 2;
      this.input.pitch = -0.58;
      return;
    }
    const o = this.prison.cellOrigin;
    if (!o) return;
    this.hands.position.set(0, 0, 0);
    if (look === 'hatch') {
      this.player.position.set(o.x - LAYOUT.cellW / 2 + 1.05, 0, 3.42);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.12;
    } else if (look === 'table') {
      this.player.position.set(o.x - 0.05, 0, o.z - 0.55);
      this.input.yaw = 0.18;
      this.input.pitch = -0.58;
    } else if (look === 'steam') {
      this.player.position.set(o.x - 0.7, 0, o.z - 0.85);
      this.input.yaw = Math.atan2(0.55, 1.0);
      this.input.pitch = -0.36;
    } else if (look === 'bunk') {
      this.player.position.set(o.x + 0.48, 0, o.z - 1.08);
      this.input.yaw = Math.atan2(1.08, -1.18);
      this.input.pitch = -0.58;
    } else if (look === 'hands') {
      this.player.position.set(o.x - 0.85, 0, o.z - 0.15);
      this.input.yaw = 0.22;
      this.input.pitch = -0.42;
      this.sim.cuffed = false;
      this.hands.position.set(0.04, 0.16, 0.12);
      if (this.hands.userData.holdNote && this.sim.malyava === 'hold') {
        this.hands.userData.holdNote.visible = true;
      }
    } else if (look === 'window') {
      this.player.position.set(o.x - 1.35, 0, o.z + 1.55);
      this.input.yaw = 0;
      this.input.pitch = 0.18;
      this.hands.position.set(0, -0.55, 0.08);
    } else if (look === 'winwall') {
      this.player.position.set(o.x - 0.05, 0, o.z - 2.15);
      this.input.yaw = 0.02;
      this.input.pitch = -0.48;
    } else if (look === 'cal') {
      this.player.position.set(o.x - 1.45, 0, o.z + 0.62);
      this.input.yaw = -Math.PI / 2 + 0.22;
      this.input.pitch = -0.42;
    } else if (look === 'wash') {
      this.player.position.set(o.x + 1.48, 0, o.z + 2.38);
      this.input.yaw = Math.atan2(0.78, 0.32);
      this.input.pitch = -0.46;
    } else if (look === 'rad') {
      this.player.position.set(o.x - 1.35, 0, o.z + 1.65);
      this.input.yaw = 0.08;
      this.input.pitch = -0.58;
    } else if (look === 'door') {
      this.player.position.set(o.x - 0.45, 0, 3.42);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.58;
    } else if (look === 'walkin') {
      this.player.position.set(o.x - 0.5, 0, 3.78);
      this.input.yaw = -Math.PI / 2 + 0.18;
      this.input.pitch = -0.58;
    } else if (look === 'walkdoor') {
      this.player.position.set(o.x - 0.4, 0, 3.55);
      this.input.yaw = -Math.PI / 2;
      this.input.pitch = -0.38;
    } else if (look === 'ceil') {
      this.player.position.set(o.x - 0.2, 0, o.z + 0.15);
      this.input.yaw = 0.18;
      this.input.pitch = 0.92;
    } else if (look === 'stool') {
      this.player.position.set(o.x + 0.18, 0, o.z - 0.85);
      this.input.yaw = 0.08;
      this.input.pitch = -0.72;
    } else if (look === 'stoolx') {
      this.player.position.set(o.x + 0.22, 0, o.z + 1.22);
      this.input.yaw = Math.PI;
      this.input.pitch = -0.72;
    }
  }

  forcePhase(id) {
    const i = PHASES.findIndex((p) => p.id === id);
    if (i < 0) return;
    this.sim.propiska = true;
    this.sim.locked = false;
    this.sim.stage = 'life';
    this.sim.phaseIndex = i;
    this.sim.phaseT = 2;
    this.sim.attended = true;
    this.cellLife.active = true;
    this.cellLife.seen.add('greet');
    this.cellLife.convoyGone = true;
    this.cellLife.lifeT = this.cellLife.t;
    this.cellLife._phase = null;
    this.cellLife._npcPhase = null;
    this.dialog.hide();
    if (id === 'walk') {
      const door = this.prison.interactables.find((it) => it.type === 'cell-door');
      if (door && !door.open) this.prison.openDoor(door);
      this.player.position.set(0.15, 0, LAYOUT.corridorLen - 2.2);
      this.input.yaw = 0;
      this.input.pitch = -0.16;
    }
  }

  skipToArrival() {
    this.hands.visible = true;
    this.introT = 22;
    this._introHud = true;
    this._introControl = true;
    this._introOut = true;
    this._introDoors = true;
    this._introLook = true;
    this.renderer.toneMappingExposure = 1.18;
    this.camera.fov = 62;
    this.camera.updateProjectionMatrix();
    const fade = document.getElementById('fade');
    if (fade) {
      fade.style.opacity = '0';
      fade.style.display = 'none';
    }
    document.getElementById('hud')?.classList.remove('hud-quiet');
    document.getElementById('quest')?.classList.remove('hidden');
    this.audio.stopRumble();
    if (this.prison.vanDoors) {
      this.prison.vanDoors.left.rotation.y = 1.28;
      this.prison.vanDoors.right.rotation.y = -1.28;
    }
    this.input.pitch = 0;
  }

  skipToPlace(at) {
    if (at === 'propiska') {
      this.skipToCell();
      return;
    }
    if (at === 'yard') {
      this.skipToCell();
      this.forcePhase('walk');
      this.player.position.set(-0.2, 0, LAYOUT.corridorLen + 5.2);
      this.input.yaw = 0.12;
      this.input.pitch = -0.82;
      return;
    }
    if (at === 'kpp' || at === 'van' || at === 'shmon' || at === 'photo' || at === 'med' || at === 'bath' || at === 'neck' || at === 'escort') {
      this.skipToArrival();
      this.sim.locked = false;
      this.sim.cuffed = false;
      if (at === 'kpp') {
        this.player.position.set(1.55, 0, -59.2);
        this.input.yaw = 0.55;
        this.npcs.dogsAlert?.(true);
      } else if (at === 'van') {
        this.player.position.set(0, 0, -80.8);
        this.input.yaw = 0;
        this.npcs.dogsAlert?.(true);
      } else if (at === 'shmon') {
        this.sim.docs = true;
        this.sim.stage = 'shmon';
        this.prison.openKpp();
        this.player.position.set(0, 0, -36.4);
        this.input.yaw = -Math.PI / 2;
      } else if (at === 'photo') {
        this.sim.docs = true;
        this.sim.pending = [];
        this.sim.stage = 'photo';
        this.prison.openKpp();
        this.player.position.set(-0.2, 0, -28.2);
        this.input.yaw = Math.PI / 2;
      } else if (at === 'med') {
        this.sim.docs = true;
        this.sim.pending = [];
        this.sim.photo = true;
        this.sim.stage = 'med';
        this.prison.openKpp();
        this.player.position.set(-0.2, 0, -22.2);
        this.input.yaw = -Math.PI / 2;
      } else if (at === 'bath') {
        this.sim.docs = true;
        this.sim.pending = [];
        this.sim.photo = true;
        this.sim.med = true;
        this.sim.stage = 'bath';
        this.prison.openKpp();
        this.player.position.set(0.45, 0, -15.4);
        this.input.yaw = Math.PI / 2;
        this.input.pitch = -0.22;
      } else if (at === 'escort') {
        this.sim.docs = true;
        this.sim.pending = [];
        this.sim.photo = true;
        this.sim.med = true;
        this.sim.haircut = true;
        this.sim.robe = 'kazenka';
        this.player.shave?.();
        this.player.applyKazenka?.();
        this.hands.userData.setKazenka?.();
        this.prison.openKpp();
        this.player.position.set(0, 0, -13.2);
        this.input.yaw = 0;
        this.input.pitch = 0.04;
        this.startEscort();
        return;
      } else if (at === 'neck') {
        this.sim.docs = true;
        this.sim.pending = [];
        this.sim.photo = true;
        this.sim.med = true;
        this.sim.haircut = true;
        this.sim.robe = 'kazenka';
        this.sim.stage = 'escort';
        this.escort = null;
        this.prison.openKpp();
        this.prison.openDoor(this.prison.blockDoor);
        this.player.position.set(0, 0, 1.85);
        this.input.yaw = 0;
        this.input.pitch = 0.04;
        this.sim.locked = false;
        this.sim.cuffed = false;
      }
      return;
    }
    this.skipToCell();
    this.cellLife.active = false;
    this.cellLife.seen.add('greet');
    this.prison.openDoor(this.prison.blockDoor);
    this.input.pitch = 0;
    if (at === 'yard') {
      this.player.position.set(0, 0, LAYOUT.corridorLen + 3.2);
      this.input.yaw = Math.PI;
    } else {
      this.player.position.set(0, 0, -3.6);
      this.input.yaw = 0;
    }
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
    const raw = this.clock.getDelta();
    const dt = Math.min(this.escort ? 0.4 : 0.05, raw);
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
    this.prison.tickArrival?.(dt);
    this.stepFlash(dt);
    if (this.overlaysOpen()) {
      this.updateCamera(this.input.crouchHeld, dt);
      this.npcs.update(this.clock.elapsedTime, this.player.position, this.camera, dt);
      this.cellLife?.tick(dt);
      this.prison.syncStoryProps?.(this.sim);
      this.syncHud();
      return;
    }

    const move = this.input.moveVector();
    const crouch = this.input.crouchHeld;
    const yaw = this.input.yaw;

    this.stepIntro(dt);
    this.stepRain(dt);
    if (this.introT >= 8) {
      if (this.escort) this.stepEscort(dt);
      else this.stepWalk(dt, move, crouch, yaw);
    }

    this.player.setLocomotion(this.escort ? 0.6 : move.mag, !!move.run, crouch);
    this.player.update(dt);
    this.npcs.update(this.clock.elapsedTime, this.player.position, this.camera, dt);

    this.updateCamera(crouch, dt);
    const outside = this.player.position.z < -53;
    this.sun.intensity = outside ? 1.35 : 0.1;
    this.hemi.intensity = outside ? 1.05 : 0.4;
    this.hemi.color.set(outside ? 0xd8e4ee : 0xc4b8a8);
    this.fill.intensity = outside
      ? 0.05
      : this.sim.stage === 'life' && this.sim.phase.id === 'evening'
        ? 0.12
        : 0.22;
    if (!outside) this.fill.position.set(this.player.position.x, 2.55, this.player.position.z);
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
    this.hands.userData.step?.(this.clock.elapsedTime, move.mag, move.run, this.sim.cuffed);
    if (this.hands.userData.holdNote) {
      const pocket = this.sim.malyava === 'hold' && this.sim.stash !== 'wash' && this.sim.stash !== 'bunk';
      this.hands.userData.holdNote.visible = pocket && this.sim.stage === 'life';
    }
    this.cellLife?.tick(dt);
    lifeTick(this, dt);

    this.guards.update(dt, this.sim.stage === 'life' ? this.sim.phase.id : null);
    if (this.prison.washDrip) {
      const fall = this.clock.elapsedTime % 1.7;
      this.prison.washDrip.position.y = 2.72 - fall * 0.5;
      this.prison.washDrip.material.opacity = 0.72 - fall * 0.32;
    }
    if (this.prison.kettleSteam?.visible) {
      const t = this.clock.elapsedTime;
      this.prison.kettleSteam.children.forEach((p, i) => {
        p.position.y = ((t * 0.32 + i * 0.18) % 0.5);
        p.material.opacity = Math.max(0.04, 0.3 - p.position.y * 0.45);
      });
    }
    if (this.prison.cigSmoke?.visible) {
      const t = this.clock.elapsedTime;
      this.prison.cigSmoke.children.forEach((p, i) => {
        p.position.y = ((t * 0.22 + i * 0.14) % 0.36);
        p.position.x = Math.sin(t * 0.7 + i) * 0.03;
        p.material.opacity = Math.max(0.03, 0.2 - p.position.y * 0.4);
      });
    }
    const inOwnCell = this.player.position.x > 1.55;
    const onWalk = this.sim.stage === 'life' && this.sim.phase.id === 'walk';
    if (onWalk && this.player.position.z > LAYOUT.corridorLen + 0.6) {
      if (!this._inYard) {
        this._inYard = true;
        this.subtitle(walkLine(this.sim));
        this.audio.buzz();
      }
    } else if (!onWalk) this._inYard = false;
    const guardHit = this.sim.stage === 'life' && !onWalk && !inOwnCell && this.guards.sees(this.player.position, crouch);
    const camHit = this.cctv.update(dt, this.player.position, crouch, this.alarm);
    if (this.sim.stage === 'life' && !onWalk && !inOwnCell && (guardHit || camHit)) {
      this.alarmHold = 3.5;
      this.sim.heat = Math.min(100, this.sim.heat + dt * 18);
      if (!this._guardSee || performance.now() - this._guardSee > 2800) {
        this._guardSee = performance.now();
        this.subtitle(guardHit ? 'Конвой: «Стой! В хату! Руки!»' : 'Камера вела. Свет красный.');
        this.audio.clang();
        this.toast('Мурчики не чай пьют.');
      }
    }
    this.alarmHold = Math.max(0, this.alarmHold - dt);
    this.setAlarm(this.alarmHold > 0);

    this.sim.tick(dt);
    this.prison.syncStoryProps?.(this.sim);
    this.updateStages();
    this.autoGuide(dt, move.mag);
    this.stepCompass(dt);
    this.stepStory();
    this.stepNerves();
    this._lastMove = move;

    if (this.input.consumeTalk()) this.openTalk();

    const npc = this.npcs.nearestPerson(this.player.position, 1.9);
    const near = this.nearestUsable();
    const prompt = document.getElementById('prompt');
    const searching = this.sim.stage === 'life' && this.sim.phase.id === 'shmon';
    const npcD = npc
      ? Math.hypot(this.player.position.x - npc.root.position.x, this.player.position.z - npc.root.position.z)
      : 99;
    const itemD = near
      ? Math.hypot(this.player.position.x - near.position.x, this.player.position.z - near.position.z)
      : 99;
    if (searching) {
      prompt.classList.remove('hidden');
      prompt.textContent = 'К стене. Руки видно.';
      this.input.consumeInteract();
    } else if (npc && npcD <= itemD && (this.sim.stage === 'propiska' || this.sim.stage === 'life')) {
      prompt.classList.remove('hidden');
      prompt.textContent = `${npc.name} · говорить`;
      if (this.input.consumeInteract()) this.cellLife.talkTo(npc.id);
    } else if (near && this.canUse(near)) {
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
    const speed = crouch ? 1.25 : move.run ? 4.2 : this.sim.cuffed ? 1.45 : 2.3;
    const forward = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    const right = new THREE.Vector3(Math.cos(yaw), 0, -Math.sin(yaw));
    const wish = new THREE.Vector3();
    wish.addScaledVector(right, move.x);
    wish.addScaledVector(forward, -move.z);
    if (wish.lengthSq() > 0) wish.normalize();
    if (!this.wishVel) this.wishVel = new THREE.Vector3();
    if (move.mag < 0.05) {
      this.wishVel.set(0, 0, 0);
      return;
    }
    this.wishVel.copy(wish).multiplyScalar(speed);
    const next = this.player.position.clone();
    next.x += wish.x * speed * dt;
    next.z += wish.z * speed * dt;
    const resolved = this.prison.resolve(next, crouch ? 0.2 : 0.26);
    this.player.position.x = resolved.x;
    this.player.position.z = resolved.z;
    this.confineInmate(dt);
    this._footT = (this._footT || 0) + dt;
    if (this._footT > (move.run ? 0.3 : 0.48)) {
      this._footT = 0;
      this.audio.foot();
    }
    if (!this.sim.docs) {
      if (this.player.position.z < -88) {
        this.player.position.z = -88;
        this.audio.bark();
        this.toast('Конвой: «Стой. КПП впереди, не к забору.»');
        this.sim.stress = Math.min(100, this.sim.stress + 6);
      }
      if (move.run) {
        this.npcs.dogsAlert?.(true);
        if (!this._ranWarn) {
          this._ranWarn = true;
          this.subtitle('Конвой: «Шагом! Собака не игрушка.»');
          this.audio.bark();
          this.sim.stress = Math.min(100, this.sim.stress + 8);
        }
      }
    }
  }

  stepEscort(dt) {
    const pts = this.escort.pts;
    const i = this.escort.i;
    if (
      i >= pts.length - 1 ||
      (this.player.position.x > LAYOUT.corridorHalf + 1.15 && this.player.position.z > 4.0)
    ) {
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
    const step = Math.min(2.85 * dt, dist);
    next.x += dir.x * step;
    next.z += dir.z * step;
    this.player.position.x = next.x;
    this.player.position.z = next.z;
    if (!this.escort.freeLook) {
      const want = Math.atan2(dir.x, dir.z);
      let d = want - this.input.yaw;
      while (d > Math.PI) d -= Math.PI * 2;
      while (d < -Math.PI) d += Math.PI * 2;
      this.input.yaw += d * Math.min(1, dt * 3.2);
      this.input.pitch += (0.04 - this.input.pitch) * Math.min(1, dt * 2.6);
    }
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
    if (ev === 'doors') {
      this.subtitle('Зелёные номера. За каждой — своя масть, свой воздух. Свою не пропусти.');
    }
    if (ev === 'duty') {
      this.audio.clang();
      this.subtitle('Дежурка справа. Свет другой. Сюда без команды — как на вышку.');
    }
    if (ev === 'cell') {
      const door = this.prison.interactables.find((it) => it.type === 'cell-door');
      if (door) this.prison.openDoor(door);
      const col = this.prison.colliders.find((c) => c.id === door?.colliderId);
      if (col) col.active = false;
      this.audio.clang();
      this.subtitle('Конвой: «Четвёртая. Заходи в дверь. Не боком — через порог.»');
      if (this.escort) this.escort.freeLook = true;
    }
  }

  startEscort() {
    if (this.escort) return;
    this.sim.stage = 'escort';
    this.sim.cuffed = true;
    this.guide = null;
    const spawn = this.prison.cellSpawn;
    const origin = this.prison.cellOrigin;
    this.escort = {
      i: 0,
      stuck: 0,
      pts: [
        { x: this.player.position.x, z: this.player.position.z },
        { x: 0, z: this.player.position.z },
        { x: 0, z: -4.2 },
        { x: 0, z: -0.85, event: 'block' },
        { x: 0, z: 1.2, event: 'doors' },
        { x: 0, z: 2.45, event: 'voice' },
        { x: 0, z: 3.2, event: 'cell' },
        { x: LAYOUT.corridorHalf + 0.12, z: 3.4 },
        { x: LAYOUT.corridorHalf + 1.05, z: 3.45 },
        { x: spawn.x, z: spawn.z },
        { x: origin.x - 0.6, z: origin.z },
      ],
    };
    for (const n of this.npcs.list) {
      if (n.follow == null) continue;
      n.gone = false;
      n.root.visible = true;
      const side = n.follow === 0 ? 0.65 : -0.65;
      n.root.position.set(this.player.position.x + side, 0, this.player.position.z - 0.9);
    }
    this.prison.openDoor(this.prison.blockDoor);
    const cellDoor = this.prison.interactables.find((it) => it.type === 'cell-door');
    if (cellDoor) this.prison.openDoor(cellDoor);
    this.subtitle('Конвой: «Хату четыре. Шагом. Голову не поднимай без команды.»');
    this.audio.voiceOnce('cell', 'Хату четыре. Шагом.', 'Конвой');
    this.audio.clang();
  }

  finishEscort() {
    this.escort = null;
    if (this.wishVel) this.wishVel.set(0, 0, 0);
    if (this.player.position.x < LAYOUT.corridorHalf + 0.9) {
      this.player.position.copy(this.prison.cellSpawn);
    }
    this.sim.cuffed = false;
    this.sim.locked = false;
    this.sim.stage = 'propiska';
    this.prison.closeDoor(this.prison.blockDoor);
    const shut = this.prison.interactables.find((it) => it.type === 'cell-door');
    if (shut?.open) this.prison.closeDoor(shut);
    this.input.yaw = Math.PI / 2;
    this.input.pitch = 0;
    this.subtitle('Ты зашёл через дверь. Теперь хата — не конвой.');
    this.audio.clang();
    this.cellLife.begin();
  }

  stepIntro(dt) {
    if (this._introHud) return;
    this.introT += dt;
    const t = this.introT;
    const fade = document.getElementById('fade');
    if (fade) {
      const o = Math.max(0, 1 - t / 2.4);
      fade.style.opacity = String(o);
      if (o <= 0) fade.style.display = 'none';
    }

    const doors = this.prison.vanDoors;
    if (doors) {
      const k = smoothstep((t - 2.4) / 1.8);
      doors.left.rotation.y = k * 1.28;
      doors.right.rotation.y = -k * 1.28;
    }

    if (!this._introDoors && t > 2.4) {
      this._introDoors = true;
      this.audio.stopRumble();
      this.audio.doorScrape();
      this.audio.clang();
    }
    if (!this._introLook && t > 4.2) {
      this._introLook = true;
      this.audio.bark();
      this.npcs.dogsAlert?.(true);
    }
    if (!this._introOut && t > 7.2) {
      this._introOut = true;
      this.subtitle('Конвой: «Выходи.»');
      this.audio.voiceOnce('out', 'Выходи.', 'Конвой');
      this.audio.bark();
      this.pullFresh();
    }
    if (!this._introControl && t > 8) {
      this._introControl = true;
      this.hands.visible = true;
      document.getElementById('quest')?.classList.remove('hidden');
    }
    if (!this._introHud && t > 18) {
      this._introHud = true;
      document.getElementById('hud')?.classList.remove('hud-quiet');
      this.introDone = true;
      this.npcs.list.forEach((n) => {
        n.root.traverse((c) => {
          if (c.userData.billboard) c.visible = true;
        });
      });
    }

    if (t < 11) {
      const lookK = smoothstep((t - 3.6) / 2.2);
      this.input.pitch = 0.06 + lookK * -0.28;
      this.camera.fov = 48 + lookK * 14;
      this.camera.updateProjectionMatrix();
      this.renderer.toneMappingExposure = 0.38 + lookK * 0.8;
    }
  }

  flashPhoto() {
    const fade = document.getElementById('fade');
    if (!fade) return;
    fade.style.display = 'block';
    fade.style.backgroundColor = '#f3ead4';
    fade.style.opacity = '1';
    this._flashT = 0.7;
  }

  stepFlash(dt) {
    if (!(this._flashT > 0)) return;
    this._flashT -= dt;
    const fade = document.getElementById('fade');
    if (!fade) return;
    fade.style.opacity = String(Math.max(0, this._flashT / 0.7));
    if (this._flashT <= 0) {
      fade.style.display = 'none';
      fade.style.backgroundColor = '';
      fade.style.opacity = '0';
    }
  }

  pullFresh() {
    const n = this.npcs.fresh;
    if (!n) return;
    n.walkTo = new THREE.Vector3(0, 0, -70);
  }

  stepRain(dt) {
    const rain = this.prison.rain;
    if (!rain) return;
    const arr = rain.geometry.attributes.position.array;
    for (let i = 1; i < arr.length; i += 3) {
      arr[i] -= dt * 9;
      if (arr[i] < 0) arr[i] = 14 + Math.random() * 4;
    }
    rain.geometry.attributes.position.needsUpdate = true;
  }

  autoGuide(dt, mag) {
    this.idle = mag > 0.12 || this.escort || this.introT < 10 ? 0 : this.idle + dt;
    if (this.idle > 9 && !this._lost) {
      this._lost = true;
      const w = wayFor(this.sim, this.prison);
      this.subtitle(`${w.name}. ${w.hint} Компас сверху.`);
    }
    if (mag > 0.12) this._lost = false;
  }

  stepCompass(dt) {
    const w = wayFor(this.sim, this.prison);
    const dx = w.x - this.player.position.x;
    const dz = w.z - this.player.position.z;
    const dist = Math.hypot(dx, dz);
    let ang = Math.atan2(dx, dz) - this.input.yaw;
    while (ang > Math.PI) ang -= Math.PI * 2;
    while (ang < -Math.PI) ang += Math.PI * 2;
    const needle = document.getElementById('needle');
    if (needle) needle.style.transform = `rotate(${(ang * 180) / Math.PI}deg)`;
    const name = document.getElementById('way-name');
    const dEl = document.getElementById('way-dist');
    if (name) name.textContent = w.name;
    if (dEl) dEl.textContent = dist < 1.4 ? w.hint : `${Math.round(dist)} м · ${w.hint}`;
    if (this.beacon) {
      this.beacon.position.set(w.x, 1.7 + Math.sin(this.clock.elapsedTime * 2.2) * 0.12, w.z);
      const guiding =
        this.sim.stage === 'kpp' ||
        this.sim.stage === 'shmon' ||
        this.sim.stage === 'photo' ||
        this.sim.stage === 'med' ||
        this.sim.stage === 'bath';
      this.beacon.visible = guiding && dist > 1.6 && !this.escort;
      this.beacon.rotation.y += dt * 1.4;
    }
    this.guide = new THREE.Vector3(w.x, 0, w.z);
  }

  stepStory() {
    const beat = storyLine(this.sim, this.player.position, this.introT);
    if (!beat || beat.id === this._beat) return;
    this._beat = beat.id;
    this.subtitle(beat.text);
  }

  stepNerves() {
    const n = document.getElementById('nerves');
    if (!n) return;
    const s = this.sim.stress;
    if (s < 62) {
      n.classList.add('hidden');
      return;
    }
    n.classList.remove('hidden');
    n.style.opacity = String(Math.min(0.85, (s - 60) / 50));
  }

  updateCamera(crouch, dt = 0.016) {
    const yaw = this.input.yaw;
    const pitch = this.input.pitch;
    const eye = crouch ? 1.08 : 1.64;
    let x = this.player.position.x;
    let z = this.player.position.z;
    const inHall = Math.abs(this.player.position.x) < LAYOUT.corridorHalf;
    if (inHall && z > -1.2 && z < LAYOUT.corridorLen) {
      const limit = LAYOUT.corridorHalf - 0.42;
      if (x > limit) x = limit;
      if (x < -limit) x = -limit;
    }
    const spd = this.wishVel ? this.wishVel.length() : 0;
    this._bob = (this._bob || 0) + dt * (0.8 + spd * 2.8);
    const bob = Math.sin(this._bob) * Math.min(0.038, spd * 0.014);
    const sway = Math.cos(this._bob * 0.5) * Math.min(0.018, spd * 0.007);
    this.camera.position.set(x + sway, eye + bob, z);
    const look = new THREE.Vector3(
      this.camera.position.x + Math.sin(yaw) * Math.cos(pitch),
      this.camera.position.y + Math.sin(pitch),
      this.camera.position.z + Math.cos(yaw) * Math.cos(pitch),
    );
    this.camera.lookAt(look);
    if (this.introT > 11) {
      const running = this._lastMove?.run && !crouch;
      const want = running ? 70 : 62;
      this.camera.fov += (want - this.camera.fov) * 0.1;
      this.camera.updateProjectionMatrix();
    }
  }

  updateStages() {
    if (this.sim.stage === 'bath' && this.sim.robe === 'kazenka' && !this.escort) this.startEscort();
  }

  nearestUsable() {
    const pos = this.player.position;
    let best = null;
    let bestD = Infinity;
    for (const it of this.prison.interactables) {
      if (!this.canUse(it)) continue;
      const d = Math.hypot(pos.x - it.position.x, pos.z - it.position.z);
      if (d < it.radius && d < bestD) {
        best = it;
        bestD = d;
      }
    }
    return best;
  }

  canUse(item) {
    if (this.escort) return false;
    if (item.type === 'kpp') return !this.sim.docs;
    if (item.type === 'shmon') return this.sim.docs && this.sim.pending.length > 0;
    if (item.type === 'photo') return this.sim.pending.length === 0 && !this.sim.photo;
    if (item.type === 'med') return this.sim.photo && !this.sim.med;
    if (item.type === 'bath') return this.sim.med && !this.sim.haircut;
    if (item.type === 'robe') return this.sim.haircut && this.sim.robe !== 'kazenka';
    if (item.type === 'block-door') return false;
    if (item.type === 'cell-door') return this.sim.stage === 'propiska' || this.sim.stage === 'life';
    if (item.type === 'exit') return this.sim.stage === 'life' && this.sim.phase.id === 'walk';
    if (item.type === 'admin') return this.sim.stage === 'life' && this.sim.day >= 3;
    if (item.type === 'rag') return !this.sim.ragChoice && this.sim.stage === 'propiska';
    if (item.type === 'starosta') return this.sim.stage === 'propiska' || this.sim.stage === 'life';
    if (['window', 'kettle', 'hatch', 'calendar'].includes(item.type))
      return this.sim.stage === 'propiska' || this.sim.stage === 'life';
    if (item.type === 'food') return this.sim.stage === 'life' && this.sim.phase.id === 'food';
    if (['bunk', 'bunk-other', 'wash', 'cards', 'malyava', 'obshak', 'admin'].includes(item.type))
      return this.sim.stage === 'life' || this.sim.stage === 'propiska';
    return true;
  }

  label(item) {
    if ((item.type === 'hatch' || item.type === 'malyava') && this.sim.malyava === 'gone')
      return 'Щель пустая';
    if (item.type === 'hatch' && this.sim.day >= 3 && !this.sim.malyava) return 'Бумага в кормушке';
    if (item.type === 'malyava' && this.sim.day >= 3 && !this.sim.malyava) return 'Бумага в кормушке';
    if (
      (item.type === 'hatch' || item.type === 'malyava') &&
      this.sim.day >= 4 &&
      this.sim.malyava === 'hold' &&
      !this.sim.teaPaid
    )
      return 'Чай в щели';
    if ((item.type === 'hatch' || item.type === 'malyava') && this.sim.malyava === 'hold')
      return this.sim.stash === 'bunk'
        ? 'Бумага в матрасе'
        : this.sim.stash === 'wash'
          ? 'Чаша не смотри'
          : 'Карман жжёт';
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
      window: 'Окно · решётка',
      kettle: 'Чайник · чифир',
      hatch: 'Кормушка',
      calendar: 'Календарь хаты',
      'cell-door': item.open ? 'Дверь открыта конвоем' : 'Замок. Конвой открывает, не ты',
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
        this.audio.voiceOnce('kpp', 'Ворота. Шагом. Вещи на стол.', 'Конвой');
        this.npcs.dogsAlert?.(false);
        this.input.yaw = Math.atan2(-this.player.position.x, -54.2 - this.player.position.z);
        this.input.pitch = 0.05;
        this.subtitle('Створки разъезжаются. Не стой в проёме. Дальше сборник: шмон, фото, врач, стрижка.');
        this.guide = new THREE.Vector3(-1.2, 0, -36.2);
      };
      return;
    }
    if (item.type === 'shmon') {
      this.openShmon();
      return;
    }
    if (item.type === 'photo') {
      this.unlockLook();
      this.dialog.show(PHOTO_Q.who, PHOTO_Q.text, PHOTO_Q.options);
      this.dialog.onPick = (opt) => {
        this.sim.photo = true;
        this.sim.stage = 'med';
        this.sim.shift(opt.black, opt.red, opt.men);
        this.toast(opt.reply);
        this.subtitle('Дальше фельдшер. Ищут вшей, побои, заразу.');
        this.guide = new THREE.Vector3(-1.0, 0, -22.2);
        this.audio.buzz();
        this.flashPhoto();
        this.audio.voiceOnce('photo', 'Не моргай. Ещё раз. Боком.', 'Конвой');
      };
      return;
    }
    if (item.type === 'med') {
      this.unlockLook();
      this.dialog.show(MED_Q.who, MED_Q.text, MED_Q.options);
      this.dialog.onPick = (opt) => {
        this.sim.med = true;
        this.sim.stage = 'bath';
        this.sim.shift(opt.black, opt.red, opt.men);
        this.toast(opt.reply);
        this.subtitle('Санитарная обработка: машинка и помывка. Как в кино — с тебя делают зэка.');
        this.guide = new THREE.Vector3(1.2, 0, -15.4);
        this.audio.voiceOnce('med', 'В баню. Машинка ждёт.', 'Фельдшер');
      };
      return;
    }
    if (item.type === 'bath') {
      this.unlockLook();
      this.dialog.show(BATH_Q.who, BATH_Q.text, BATH_Q.options);
      this.dialog.onPick = (opt) => {
        this.player.shave();
        this.sim.haircut = true;
        this.sim.hygiene = Math.min(100, this.sim.hygiene + 25);
        this.sim.shift(opt.black, opt.red, opt.men);
        this.toast(opt.reply);
        this.subtitle('Казёнка у стула. Полосатая роба, тапочки. Не через коридор.');
        this.audio.clippers();
        this.guide = new THREE.Vector3(2.35, 0, -15.32);
      };
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
      this.cellLife.talkTo('starosta');
      return;
    }
    if (item.type === 'window') {
      this.cellLife.useWindow();
      return;
    }
    if (item.type === 'kettle') {
      this.cellLife.useKettle();
      return;
    }
    if (item.type === 'hatch') {
      this.cellLife.useHatch();
      return;
    }
    if (item.type === 'calendar') {
      this.sim.hope = Math.min(100, this.sim.hope + 3);
      this.toast(
        this.sim.malyava === 'gone'
          ? `День ${this.sim.day}. Чёрточки есть. Бумаги в щели нет.`
          : `День ${this.sim.day}. Чёрточка на стене ещё не стала стеной.`,
      );
      return;
    }
    if (item.type === 'bunk') {
      if (!this.sim.propiska) {
        this.toast('Пока смотрящий не укажет койку — не садись.');
        return;
      }
      this.sim.rest();
      this.sim.heat = Math.max(0, this.sim.heat - 6);
      if (this.sim.seenNight1 && this.sim.phase.id === 'evening') this.sim.stash = 'bunk';
      this.toast(
        this.sim.stash === 'bunk'
          ? 'Сунул под матрас. Лёха сказал — плохое место.'
          : this.sim.path === 'black'
            ? 'Нычка под матрасом на месте.'
            : 'Своя шконка. Чужую не занимай.',
      );
      this.cellLife.completeTask('bunk');
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
      if (this.sim.seenNight1) this.sim.stash = 'wash';
      this.toast(
        this.sim.stash === 'wash'
          ? 'Нычка у чаши. Лёха кивнул в темноте.'
          : 'Холодная вода, чаша Генуя. Гигиена — не для красоты, для хаты.',
      );
      return;
    }
    if (item.type === 'cards') {
      this.minigames.playCards();
      this.cellLife.completeTask('cards');
      return;
    }
    if (item.type === 'malyava') {
      if (this.sim.day >= 3 && !this.sim.malyava) {
        this.cellLife.useHatch();
        return;
      }
      if (this.sim.malyava === 'hold') {
        this.toast('Бумага в кармане. Не читай вслух.');
        return;
      }
      if (this.sim.malyava === 'admin' || this.sim.path === 'red' || this.sim.courtTalk === 'cell') {
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
      this.toast('Замок с той стороны. Конвой открывает, не ты.');
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
      if (this.sim.phase.id !== 'walk') {
        this.toast('Не время. Прогулка по распорядку, не когда вздумается.');
        this.sim.heat = Math.min(100, this.sim.heat + 12);
        return;
      }
      this.toast(walkLine(this.sim));
      this.sim.stress = Math.max(0, this.sim.stress - 10);
      this.sim.attended = true;
    }
  }

  confineInmate(dt) {
    if (this.escort) return;
    const s = this.sim;
    const p = this.player.position;
    const inside = s.stage === 'propiska' || s.stage === 'life' || s.stage === 'escort';
    if (s.docs && p.z < -52 && s.stage !== 'kpp') {
      p.z = -51.4;
      this.toast('Ворота только внутрь.');
      this.audio.bark();
    }
    if (!inside) return;
    if (p.z < 0.5) {
      p.z = 0.62;
      if (!this._blockWarn || performance.now() - this._blockWarn > 4000) {
        this._blockWarn = performance.now();
        this.toast('Створки на сборник закрыты. Назад — только с конвоем.');
        this.audio.clang();
      }
    }
    const walk = s.stage === 'life' && s.phase.id === 'walk';
    const inCell = p.x > 1.55;
    if (walk && inCell && s.phaseT > 8) {
      p.x -= dt * 2.2;
      if (p.z < 3.2) p.z += dt * 1.2;
      if (p.z > 3.7) p.z -= dt * 1.2;
      if (!this._walkYell || performance.now() - this._walkYell > 3800) {
        this._walkYell = performance.now();
        this.subtitle('Конвой: «Прогулка! Шагом на коряк! Не дрыхни.»');
        this.audio.clang();
      }
      return;
    }
    if (walk || inCell) return;
    this.alarmHold = Math.max(this.alarmHold, 2.4);
    s.heat = Math.min(100, s.heat + dt * 32);
    s.stress = Math.min(100, s.stress + dt * 14);
    const doorZ = 3.4;
    p.x += dt * 2.6;
    if (p.z < doorZ) p.z += dt * 1.4;
    if (p.z > doorZ) p.z -= dt * 1.4;
    if (!this._guardYell || performance.now() - this._guardYell > 3200) {
      this._guardYell = performance.now();
      this.subtitle('Конвой: «Стой! В хату! Руки!»');
      this.audio.clang();
      this.toast('Мурчики не чай пьют. Тебя видят.');
    }
    if (s.heat > 62) {
      p.copy(this.prison.cellSpawn);
      const door = this.prison.interactables.find((it) => it.type === 'cell-door');
      if (door?.open) this.prison.closeDoor(door);
      this.prison.closeDoor(this.prison.blockDoor);
      this.toast('Запихнули. Замок с той стороны.');
      this.audio.clang();
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
      this.cellLife.onPropiskaDone();
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

  syncHud() {
    const s = this.sim;
    document.getElementById('clock').textContent =
      s.stage === 'life' ? `День ${s.day} · ${s.phase.label}` : `День 1 · ${stageName(s.stage)}`;
    document.getElementById('status').textContent = this.alarm ? 'ТРЕВОГА' : 'СИЗО · Катенька';
    document.getElementById('path-label').textContent = `Путь: ${s.pathLabel}`;
    document.getElementById('bar-hunger').style.setProperty('--w', `${s.hunger}%`);
    document.getElementById('bar-hygiene').style.setProperty('--w', `${s.hygiene}%`);
    document.getElementById('bar-stress').style.setProperty('--w', `${s.stress}%`);
    document.getElementById('bar-hope')?.style.setProperty('--w', `${s.hope}%`);
    document.getElementById('inv').textContent = `чай ${s.inv.tea} · циг. ${s.inv.cigs} · пайка ${s.inv.food} · жар ${Math.round(s.heat)}`;
    const quest = document.getElementById('quest');
    if (quest) quest.textContent = s.objective();
    const way = document.getElementById('way');
    if (way && this.introT > 9) way.classList.remove('opacity-0');
    if (s.stage === 'life' || s.stage === 'propiska') document.getElementById('look-hint')?.classList.add('hidden');
  }
}

function stageName(st) {
  return {
    kpp: 'КПП',
    shmon: 'Шмон',
    photo: 'Фото',
    med: 'Мед',
    bath: 'Баня',
    escort: 'Коряк',
    propiska: 'Прописка',
    life: 'Хата',
  }[st] || st;
}

function isMobile() {
  return /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) || window.innerWidth < 820;
}

function smoothstep(x) {
  const t = Math.max(0, Math.min(1, x));
  return t * t * (3 - 2 * t);
}

function makeBeacon() {
  const g = new THREE.Group();
  const m = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.16, 0),
    new THREE.MeshBasicMaterial({ color: 0xe8b84a, transparent: true, opacity: 0.9, depthWrite: false }),
  );
  g.add(m);
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(0.22, 0.28, 16),
    new THREE.MeshBasicMaterial({ color: 0xe8b84a, transparent: true, opacity: 0.45, side: THREE.DoubleSide, depthWrite: false }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = -1.55;
  g.add(ring);
  g.visible = false;
  return g;
}
