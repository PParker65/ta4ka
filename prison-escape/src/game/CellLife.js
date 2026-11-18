/**
 * Life inside хата 4 after the door closes.
 * Never idle: convoy leaves, прописка fires, then tasks, talk, routine.
 */
import { CIG_ASK, HATCH_TALK, KETTLE_TALK, WINDOW_TALK, TALK_STAROSTA, TALK_LEHA, TALK_VALERA } from './Dialogue.js';

const AMBIENT = [
  (g) => g.subtitle('Седой, не глядя: «Ноги с чужой шконки. Это не просьба.»'),
  (g) => g.subtitle('Лёха шепчет: «Кормушка сейчас глухая. Ночью — живая.»'),
  (g) => {
    g.audio.clang();
    g.subtitle('Шаги на коряке. Свет в щели. Мимо. Сердце всё равно стучит.');
    g.sim.stress = Math.min(100, g.sim.stress + 6);
  },
  (g) => g.subtitle('Валера насвистывает едва слышно. На секунду хата — не камера.'),
  (g) => g.subtitle('Из трубы: кап-кап. Кто-то считает это вместо дней.'),
  (g) => g.subtitle('Седой: «Общак не спрашивает. Общак помнит, кто кинул чай.»'),
];

const TASKS = [
  { id: 'cig', label: 'Седой ждёт цигарку. Подойди, E — отдай или откажи.' },
  { id: 'hatch', label: 'Кормушка стучит. Подойди к двери хаты — послушай.' },
  { id: 'window', label: 'Посмотри в окно. Не махай — считай дни.' },
  { id: 'kettle', label: 'Чайник на столе. Чифир — общий, не твой карман.' },
  { id: 'bunk', label: 'Своя шконка — нижняя у окна. Лечь. Чужую не занимай.' },
];

export class CellLife {
  constructor(game) {
    this.g = game;
    this.active = false;
    this.t = 0;
    this.seen = new Set();
    this.talkCd = {};
    this.taskI = 0;
    this.ambientT = 0;
    this.convoyGone = false;
  }

  begin() {
    this.active = true;
    this.t = 0;
    this.seen.clear();
    this.g.npcs.dismissConvoy();
    this.g.audio.clang();
    this.g.subtitle('Конвой: «Хату принял. Живи. Кормушку без команды не открывай.»');
  }

  tick(dt) {
    if (!this.active) return;
    this.t += dt;
    this.directNpcs(dt);
    this.scriptBeats();
    this.ambientAir(dt);
    this.phaseMood();
  }

  scriptBeats() {
    const g = this.g;
    if (this.t > 3.2 && !this.convoyGone) {
      this.convoyGone = true;
      const door = g.prison.interactables.find((it) => it.type === 'cell-door');
      if (door) g.prison.closeDoor(door);
      g.audio.clang();
      if (!g.dialog.open) g.subtitle('Замок. Теперь хата слышит тебя лучше, чем конвой.');
    }
    if (this.t > 0.35 && !this.seen.has('greet') && g.sim.stage === 'propiska' && !g.dialog.open) {
      this.seen.add('greet');
      g.greetingMenu();
    }
  }

  onPropiskaDone() {
    this.nextTask();
    const o = this.g.prison.cellOrigin;
    const leha = this.g.npcs.byId('cellmate');
    const s = cellSpots(o);
    if (leha && s) this.g.npcs.goTo(leha, s.lehaBunk);
    this.g.subtitle('Лёха: «Не стой в дверях. Сядь, когда посадят. Дальше — слушай хату.»');
  }

  nextTask() {
    const t = TASKS[this.taskI];
    if (!t) {
      this.g.sim.task = {
        id: 'live',
        label: 'Живи по распорядку. Говори с хатой. Не дай надежде погаснуть.',
      };
      return;
    }
    this.g.sim.task = { id: t.id, label: t.label };
    this.taskI += 1;
  }

  completeTask(id) {
    if (this.g.sim.task?.id !== id) return;
    this.g.sim.hope = Math.min(100, this.g.sim.hope + 5);
    this.g.sim.rep += 1;
    this.nextTask();
    this.g.toast('Хатка это заметила.');
  }

  ambientAir(dt) {
    if (this.g.overlaysOpen()) return;
    if (this.g.sim.stage !== 'life' && this.g.sim.stage !== 'propiska') return;
    this.ambientT += dt;
    const idle = this.g.idle || 0;
    if ((idle > 4.5 || this.ambientT > 11) && !this.g.dialog.open) {
      this.ambientT = 0;
      this.g.idle = 0;
      AMBIENT[(Math.random() * AMBIENT.length) | 0](this.g);
    }
  }

  phaseMood() {
    const g = this.g;
    if (g.sim.stage !== 'life') return;
    const id = g.sim.phase.id;
    if (id === this._phase) return;
    this._phase = id;
    if (id === 'shmon') {
      g.audio.clang();
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно. Нычку не проверяй при них.»');
    } else if (id === 'food') {
      g.subtitle('Баланда в кормушку. Не лезь без очереди. В сортир, пока едят, не ходи.');
    } else if (id === 'walk') {
      g.subtitle('Прогулка. Круг по бетону. Через стену не ори — уши у всех.');
    } else if (id === 'evening') {
      g.fill.intensity = 0.22;
      g.subtitle('Отбой. Своя койка. Чужую не занимай. Завтра опять шмон.');
    } else if (id === 'wake') {
      g.fill.intensity = 0.5;
      g.audio.buzz();
      g.subtitle('Подъём. Мат с коряка. День не спрашивает, готов ты или нет.');
    }
  }

  directNpcs() {
    const g = this.g;
    const o = g.prison.cellOrigin;
    if (!o) return;
    const s = cellSpots(o);
    const phase = g.sim.stage === 'life' ? g.sim.phase.id : 'wake';
    if (phase !== this._npcPhase) {
      this._npcPhase = phase;
      for (const id of ['starosta', 'cellmate', 'bunk-bro']) {
        const n = g.npcs.byId(id);
        if (n) {
          n.duty = null;
          n.dutyIndex = 0;
        }
      }
    }
    const starosta = g.npcs.byId('starosta');
    const leha = g.npcs.byId('cellmate');
    const valera = g.npcs.byId('bunk-bro');
    const ask = this.askSpot(o);

    if (phase === 'evening') {
      this.hold(starosta, 'sleep', s.sedoyBunk, 99);
      this.hold(leha, 'sleep', s.lehaBunk, 99);
      this.hold(valera, 'sleep', s.valeraBunk, 99);
      return;
    }
    if (phase === 'shmon') {
      this.hold(starosta, 'shmon', s.aisleN, 99);
      this.hold(leha, 'shmon', s.aisleS, 99);
      this.hold(valera, 'shmon', s.aisle, 99);
      return;
    }
    if (phase === 'food') {
      this.hold(starosta, 'food', s.tableSit, 99);
      this.hold(leha, 'food', s.tableS, 99);
      this.hold(valera, 'food', s.tableN, 99);
      return;
    }

    this.cycle(starosta, [
      { name: 'throne', spot: s.tableSit, hold: 16 },
      { name: 'ask', spot: ask || s.aisle, hold: 7, line: 'Седой: «Статья. Первый раз? Цигарка — на стол, не в карман.»' },
      { name: 'watch', spot: s.hatchWatch, hold: 9 },
    ]);
    this.cycle(leha, [
      { name: 'bunk', spot: s.lehaBunk, hold: 14 },
      { name: 'hatch', spot: s.hatchWatch, hold: 8 },
      { name: 'ask', spot: ask || s.aisleS, hold: 6, line: 'Лёха тихо: «Свежак. Кормушку без команды не открывай.»' },
    ]);
    this.cycle(valera, [
      { name: 'bunk', spot: s.valeraBunk, hold: 15 },
      { name: 'window', spot: s.window, hold: 10 },
      { name: 'ask', spot: ask || s.tableN, hold: 6, line: 'Валера: «Карты вечером, если цигарка есть. Пока хата смотрит.»' },
    ]);
  }

  hold(n, name, spot, hold) {
    if (!n || !spot) return;
    if (n.duty === name) return;
    n.duty = name;
    n.dutyUntil = this.t + hold;
    this.g.npcs.goTo(n, spot);
  }

  cycle(n, steps) {
    if (!n || !steps?.length) return;
    const i = n.dutyIndex || 0;
    const step = steps[i % steps.length];
    if (n.duty !== step.name) {
      n.duty = step.name;
      n.dutyUntil = this.t + step.hold;
      n.asked = false;
      this.g.npcs.goTo(n, step.spot);
      return;
    }
    if (!n.walkTo && step.line && !n.asked && this.t > (n.dutyUntil || 0) - step.hold + 1.4) {
      n.asked = true;
      if (!this.g.dialog.open) this.g.subtitle(step.line);
    }
    if (!n.walkTo && this.t > (n.dutyUntil || 0)) {
      n.dutyIndex = (i + 1) % steps.length;
      n.duty = null;
    }
  }

  askSpot(o) {
    const p = this.g.player?.position;
    if (!p) return null;
    if (Math.abs(p.x - o.x) > 3.2 || Math.abs(p.z - o.z) > 3.5) return cellSpots(o).aisle;
    const x = clamp(p.x - 0.15, o.x - 1.55, o.x + 0.25);
    const z = clamp(p.z + 1.2, o.z - 1.35, o.z + 1.35);
    return { x, z, yaw: Math.atan2(p.x - x, p.z - z), sit: false };
  }

  talkTo(id) {
    const g = this.g;
    const now = this.t;
    if ((this.talkCd[id] || 0) > now) {
      g.toast('Потом. Не приставай.');
      return true;
    }
    this.talkCd[id] = now + 8;
    if (id === 'starosta') {
      if (g.sim.task?.id === 'cig') {
        g.unlockLook();
        g.dialog.show(CIG_ASK.who, CIG_ASK.text, CIG_ASK.options);
        g.dialog.onPick = (opt) => this.pickCig(opt);
        return true;
      }
      if (!g.sim.propiska) {
        g.starostaTalk();
        return true;
      }
      g.unlockLook();
      g.dialog.show(TALK_STAROSTA.who, TALK_STAROSTA.text, TALK_STAROSTA.options);
      g.dialog.onPick = (opt) => this.applyTalk(opt);
      return true;
    }
    if (id === 'cellmate') {
      g.unlockLook();
      g.dialog.show(TALK_LEHA.who, TALK_LEHA.text, TALK_LEHA.options);
      g.dialog.onPick = (opt) => this.applyTalk(opt);
      return true;
    }
    if (id === 'bunk-bro') {
      g.unlockLook();
      g.dialog.show(TALK_VALERA.who, TALK_VALERA.text, TALK_VALERA.options);
      g.dialog.onPick = (opt) => {
        this.applyTalk(opt);
        if (opt.minigame === 'cards') g.minigames.playCards();
      };
      return true;
    }
    return false;
  }

  pickCig(opt) {
    const g = this.g;
    g.sim.shift(opt.black, opt.red, opt.men);
    if (opt.takeCig) {
      if (g.sim.inv.cigs <= 0) {
        g.toast('Цигарки нет. Седой это тоже запомнил.');
        g.sim.shift(0, 0, 0);
        g.sim.stress = Math.min(100, g.sim.stress + 8);
      } else {
        g.sim.inv.cigs -= 1;
        g.sim.rep += 2;
        g.toast(opt.reply);
      }
    } else {
      g.toast(opt.reply);
    }
    this.completeTask('cig');
  }

  applyTalk(opt) {
    const g = this.g;
    g.sim.shift(opt.black || 0, opt.red || 0, opt.men || 0);
    if (opt.hope) g.sim.hope = Math.min(100, g.sim.hope + opt.hope);
    if (opt.stress) g.sim.stress = Math.max(0, Math.min(100, g.sim.stress + opt.stress));
    if (opt.heat) g.sim.heat = Math.max(0, Math.min(100, g.sim.heat + opt.heat));
    g.toast(opt.reply);
  }

  useHatch() {
    const g = this.g;
    g.unlockLook();
    if (g.sim.phase.id === 'food' && g.sim.stage === 'life') {
      g.sim.inv.food += 1;
      g.sim.attended = true;
      g.toast('Пайка через кормушку. Тёплая ещё, пока не остыла.');
      g.subtitle('Седой: «Ешь. В сортир — после.»');
      return;
    }
    g.dialog.show(HATCH_TALK.who, HATCH_TALK.text, HATCH_TALK.options);
    g.dialog.onPick = (opt) => {
      this.applyTalk(opt);
      if (opt.passTea && g.sim.inv.tea > 0) {
        g.sim.inv.tea -= 1;
        g.sim.shift(1, 0, 0);
        g.sim.rep += 1;
        g.toast('Чай ушёл в щель. С той стороны кивнули.');
      }
      this.completeTask('hatch');
    };
  }

  useWindow() {
    const g = this.g;
    g.unlockLook();
    g.dialog.show(WINDOW_TALK.who, WINDOW_TALK.text, WINDOW_TALK.options);
    g.dialog.onPick = (opt) => {
      this.applyTalk(opt);
      this.completeTask('window');
    };
  }

  useKettle() {
    const g = this.g;
    g.unlockLook();
    g.dialog.show(KETTLE_TALK.who, KETTLE_TALK.text, KETTLE_TALK.options);
    g.dialog.onPick = (opt) => {
      if (opt.brew) {
        if (g.sim.inv.tea <= 0) {
          g.toast('Чай кончился. Чифир из воздуха не варят.');
        } else {
          g.sim.inv.tea -= 1;
          g.sim.stress = Math.max(0, g.sim.stress - 12);
          g.sim.hunger = Math.min(100, g.sim.hunger + 8);
          g.sim.shift(1, 0, 0);
          g.toast(opt.reply);
        }
      } else {
        this.applyTalk(opt);
      }
      this.completeTask('kettle');
    };
  }
}

function cellSpots(o) {
  return {
    tableSit: { x: o.x - 0.8, z: o.z + 0.12, yaw: Math.PI / 2, sit: true },
    tableS: { x: o.x + 0.12, z: o.z - 0.72, yaw: 0, sit: true },
    tableN: { x: o.x + 0.12, z: o.z + 0.82, yaw: Math.PI, sit: true },
    lehaBunk: { x: o.x + 1.2, z: o.z - 1.78, yaw: 0, sit: true },
    sedoyBunk: { x: o.x + 1.2, z: o.z + 1.55, yaw: Math.PI, sit: true },
    valeraBunk: { x: o.x - 0.2, z: o.z + 1.62, yaw: 0.15, sit: true },
    hatchWatch: { x: o.x - 2.05, z: o.z - 0.4, yaw: -Math.PI / 2, lean: true },
    window: { x: o.x - 1.55, z: o.z + 2.2, yaw: 0 },
    aisle: { x: o.x - 0.95, z: o.z + 0.1, yaw: Math.PI / 2 },
    aisleN: { x: o.x - 0.95, z: o.z + 1.05, yaw: Math.PI },
    aisleS: { x: o.x - 0.95, z: o.z - 1.05, yaw: Math.PI },
  };
}

function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}
