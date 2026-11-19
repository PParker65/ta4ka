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
  { id: 'cards', label: 'Валера кличет на карты. Подойди — сыграй или откажи.' },
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
    if (g.sim.stage !== 'life' || g.dialog.open) return;
    const life = this.t - (this.lifeT || this.t);
    if (life > 7 && !this.seen.has('watch')) {
      this.seen.add('watch');
      g.subtitle('Седой не смотрит на тебя. Смотрит, сядешь ли сам, или будешь столбом у двери.');
    }
    if (life > 16 && !this.seen.has('pipe')) {
      this.seen.add('pipe');
      g.subtitle('Из трубы кап-кап. Лёха считает это вместо дней. Завтра научит, если не сорвёшься.');
    }
    if (life > 28 && !this.seen.has('whistle')) {
      this.seen.add('whistle');
      g.subtitle('Валера свистит в нос. На секунду крыша выше, чем три метра. Потом снова известь.');
    }
    if (life > 40 && !this.seen.has('hatch-tap') && g.sim.task?.id === 'hatch') {
      this.seen.add('hatch-tap');
      g.audio.clang();
      g.subtitle('Кормушка. Два коротких. Соседи знают, что в четвёртой свежак.');
    }
    if (life > 55 && !this.seen.has('hope')) {
      this.seen.add('hope');
      g.subtitle('Надежда здесь прячется, как малява. Кто орёт про волю вслух — уже на карандаше.');
    }
  }

  onPropiskaDone() {
    this.lifeT = this.t;
    this.nextTask();
    const leha = this.g.npcs.byId('cellmate');
    const s = this.g.prison.seats;
    if (leha && s) this.g.npcs.goTo(leha, s.lehaSit);
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
    if (this.g.sim.stage === 'life' && this.t - (this.lifeT || 0) < 50) return;
    if ((idle > 5.5 || this.ambientT > 14) && !this.g.dialog.open) {
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
      g.audio.clang();
      this.setCellDoor(true);
      g.subtitle('Прогулка. Круг по бетону. Через стену не ори — уши у всех. Седой уже у двери.');
    } else if (id === 'evening') {
      g.fill.intensity = 0.12;
      this.setCellDoor(false);
      g.subtitle('Отбой. Своя койка. Чужую не занимай. Завтра опять шмон.');
    } else if (id === 'wake') {
      g.fill.intensity = 0.5;
      this.setCellDoor(false);
      g.audio.buzz();
      g.subtitle('Подъём. Мат с коряка. День не спрашивает, готов ты или нет.');
    }
  }

  directNpcs() {
    const g = this.g;
    const s = g.prison.seats;
    if (!s) return;
    const phase = g.sim.stage === 'life' ? g.sim.phase.id : 'wake';
    if (phase !== this._npcPhase) {
      this._npcPhase = phase;
      for (const id of ['starosta', 'cellmate', 'bunk-bro']) {
        const n = g.npcs.byId(id);
        if (n) {
          n.duty = null;
          n.dutyIndex = 0;
          n.askFrozen = null;
        }
      }
    }
    const starosta = g.npcs.byId('starosta');
    const leha = g.npcs.byId('cellmate');
    const valera = g.npcs.byId('bunk-bro');

    if (phase === 'evening') {
      this.hold(starosta, 'sleep', s.sedoyStool, 99);
      this.hold(leha, 'sleep', s.lehaLie, 99);
      this.hold(valera, 'sleep', s.valeraLie, 99);
      return;
    }
    if (phase === 'shmon') {
      this.hold(starosta, 'shmon', s.shmonSedoy, 99);
      this.hold(leha, 'shmon', s.shmonLeha, 99);
      this.hold(valera, 'shmon', s.shmonValera, 99);
      return;
    }
    if (phase === 'food') {
      this.hold(starosta, 'food', s.sedoyStool, 99);
      this.hold(leha, 'food', s.stoolS, 99);
      this.hold(valera, 'food', s.stoolN, 99);
      return;
    }
    if (phase === 'walk') {
      this.hold(starosta, 'walk', s.aisle, 99);
      this.hold(leha, 'walk', s.hatch, 99);
      this.hold(valera, 'walk', s.doorQueue, 99);
      return;
    }

    this.cycle(starosta, [{ name: 'throne', spot: s.sedoyStool, hold: 48, line: 'Седой, не глядя: «Цигарка — на стол, не в карман.»' }]);
    this.cycle(leha, [
      { name: 'bunk', spot: s.lehaSit, hold: 38 },
      { name: 'hatch', spot: s.hatch, hold: 14, line: 'Лёха тихо: «Кормушку без команды не открывай.»' },
    ]);
    this.cycle(valera, [
      { name: 'bunk', spot: s.valeraSit, hold: 34 },
      { name: 'window', spot: s.window, hold: 16, line: 'Валера: «Карты вечером, если цигарка есть.»' },
    ]);
  }

  setCellDoor(open) {
    const door = this.g.prison.interactables.find((it) => it.type === 'cell-door');
    if (!door) return;
    if (open && !door.open) {
      this.g.prison.openDoor(door);
      this.g.audio.clang();
    }
    if (!open && door.open) {
      this.g.prison.closeDoor(door);
      this.g.audio.clang();
    }
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
    const spot = step.spot === 'ask' ? this.frozenAsk(n) : step.spot;
    if (n.duty !== step.name) {
      n.duty = step.name;
      n.dutyUntil = this.t + step.hold;
      n.asked = false;
      if (step.spot !== 'ask') n.askFrozen = null;
      this.g.npcs.goTo(n, spot);
      return;
    }
    if (!n.walkTo && step.line && !n.asked && this.t > (n.dutyUntil || 0) - step.hold + 1.6) {
      n.asked = true;
      if (!this.g.dialog.open) this.g.subtitle(step.line);
    }
    if (!n.walkTo && this.t > (n.dutyUntil || 0)) {
      n.dutyIndex = (i + 1) % steps.length;
      n.duty = null;
      n.askFrozen = null;
    }
  }

  frozenAsk(n) {
    if (n.askFrozen) return n.askFrozen;
    n.askFrozen = this.askSpotOnce();
    return n.askFrozen;
  }

  askSpotOnce() {
    const o = this.g.prison.cellOrigin;
    const s = this.g.prison.seats;
    const p = this.g.player?.position;
    if (!p || !o) return s?.aisle;
    if (Math.abs(p.x - o.x) > 3.2 || Math.abs(p.z - o.z) > 3.5) return s?.aisle;
    const x = clamp(p.x - 0.2, o.x - 1.55, o.x + 0.35);
    const z = clamp(p.z + 1.15, o.z - 1.25, o.z + 1.15);
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
        if (opt.minigame === 'cards') {
          g.minigames.playCards();
          this.completeTask('cards');
        }
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

function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}
