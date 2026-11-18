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
    if (leha && o) leha.walkTo = { x: o.x + 0.4, y: 0, z: o.z - 0.2 };
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
    const phase = g.sim.stage === 'life' ? g.sim.phase.id : 'wake';
    const starosta = g.npcs.byId('starosta');
    const leha = g.npcs.byId('cellmate');
    const valera = g.npcs.byId('bunk-bro');
    const npcs = g.npcs;

    if (phase === 'evening') {
      if (starosta) npcs.sitAt(starosta, o.x + 1.35, o.z + 1.62, Math.PI);
      if (leha) npcs.sitAt(leha, o.x + 1.35, o.z - 1.82, 0);
      if (valera) npcs.sitAt(valera, o.x - 1.15, o.z + 1.45, 0.4);
      return;
    }
    if (phase === 'shmon') {
      if (starosta) npcs.standAt(starosta, o.x - 0.95, o.z + 1.15, Math.PI);
      if (leha) npcs.standAt(leha, o.x - 0.95, o.z - 1.15, Math.PI);
      if (valera) npcs.standAt(valera, o.x - 0.95, o.z + 0.05, Math.PI);
      return;
    }
    if (phase === 'food') {
      if (starosta) npcs.standAt(starosta, o.x - 0.85, o.z + 0.2, Math.PI / 2);
      if (leha) npcs.standAt(leha, o.x + 0.2, o.z - 0.62, 0);
      if (valera) npcs.standAt(valera, o.x + 0.2, o.z + 0.88, Math.PI);
      return;
    }
    const t = this.t;
    if (starosta && !starosta.walkPath?.length) {
      const pace = Math.sin(t * 0.18);
      npcs.standAt(starosta, o.x - 0.95, o.z + pace * 1.05, pace > 0 ? 0 : Math.PI);
    }
    if (leha) npcs.standAt(leha, o.x - 0.9, o.z - 1.05, 0.35);
    if (valera) {
      if ((t % 28) < 14) npcs.standAt(valera, o.x + 0.55, o.z + 2.55, 0);
      else npcs.standAt(valera, o.x - 0.85, o.z + 1.35, -0.4);
    }
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
