/** RPG state: stages, physiology, path, inventory. */
import { plotObjective } from './Plot.js';

export const PHASES = [
  { id: 'wake', label: 'Подъём' },
  { id: 'shmon', label: 'Шмон камеры' },
  { id: 'food', label: 'Баландежка' },
  { id: 'walk', label: 'Прогулка' },
  { id: 'evening', label: 'Отбой' },
];

export class Sim {
  constructor() {
    this.stage = 'kpp';
    this.hunger = 62;
    this.hygiene = 38;
    this.stress = 58;
    this.day = 1;
    this.phaseIndex = 0;
    this.phaseT = 0;
    this.black = 0;
    this.red = 0;
    this.men = 0;
    this.path = 'unset';
    this.cuffed = true;
    this.haircut = false;
    this.robe = 'street';
    this.docs = false;
    this.photo = false;
    this.med = false;
    this.locked = false;
    this.greeting = null;
    this.bunkAssigned = false;
    this.tea = false;
    this.surrendered = [];
    this.pending = ['телефон', 'деньги', 'ремень', 'шнурки', 'часы'];
    this.inv = { tea: 0, cigs: 1, food: 0, phone: 0, notes: 0 };
    this.ragChoice = null;
    this.propiska = false;
    this.frozen = false;
    this.heat = 8;
    this.rep = 0;
    this.guided = false;
    this.hope = 26;
    this.attended = false;
    this._lifePhase = null;
    this.task = null;
    this.stash = 'none';
    this.seenNight1 = false;
    this.seenDay2 = false;
    this.seenDay3 = false;
    this.seenDay4 = false;
    this.seenDay5 = false;
    this.seenWeek = false;
    this.heardYard = false;
    this.seenDay2Food = false;
    this.seenDay3Morning = false;
    this.seenDay5Wake = false;
    this.seenDay6 = false;
    this.heardDay4Yard = false;
    this.seenDay4Food = false;
    this.seenFoundNight = false;
    this.malyava = null;
    this.courtTalk = null;
    this.seenDay5Sled = false;
    this.heardDay5Yard = false;
    this.seenDay7Morning = false;
    this.seenDay2Shmon = false;
    this.seenDay6Food = false;
    this.heardDay6Yard = false;
    this.teaPaid = false;
    this.seenDay3Food = false;
  }

  objective() {
    if (!this.docs) return 'Вышел из автозака. Собаки. КПП у ворот — в хату сразу не ведут.';
    if (this.pending.length) return 'Сборник. Сдай вещи на опись. Шнурки, ремень, телефон — всё.';
    if (!this.photo) return 'Фото и дактилоскопия. Тебе дадут номер, как всем.';
    if (!this.med) return 'Медосмотр. Фельдшер смотрит, нет ли заразы и побоев.';
    if (!this.haircut) return 'Санитарная: стрижка под машинку и помывка. Так встречают всех.';
    if (this.robe !== 'kazenka') return 'Казёнка и бельё. Свою одежду уже сдал.';
    if (this.stage === 'escort') return 'Конвой ведёт по коряку. В хату — только через дверь, когда откроют.';
    if (this.task?.label) return this.task.label;
    if (!this.propiska) return 'Прописка. Хатка проверяет, кто ты. Не шарься, пока не скажут.';
    const plot = plotObjective(this);
    if (plot) return plot;
    if (this.phase.id === 'food') return 'Баландежка. Возьми пайку, не лезь без очереди.';
    if (this.phase.id === 'walk') return 'Прогулка. Круг по дворику, без болтовни через стену.';
    if (this.phase.id === 'shmon') return 'Шмон камеры. Стой, пока смотрят койки.';
    if (this.phase.id === 'evening') return 'Отбой. Своя койка, не чужая.';
    return 'Живи по распорядку. «Говорить» — с хатой. На волю через суд, не через дверь.';
  }

  get phase() {
    return PHASES[this.phaseIndex];
  }

  get pathLabel() {
    if (this.path === 'black') return 'Чёрный ход';
    if (this.path === 'red') return 'Красный ход';
    if (this.path === 'men') return 'Мужики';
    return 'Новичок';
  }

  shift(black = 0, red = 0, men = 0) {
    this.black += black;
    this.red += red;
    this.men += men;
    const b = this.black;
    const r = this.red;
    const m = this.men;
    if (b >= r && b >= m && b >= 2) this.path = 'black';
    else if (r >= b && r >= m && r >= 2) this.path = 'red';
    else if (m >= 2) this.path = 'men';
  }

  tick(dt) {
    if (this.stage !== 'life') return;
    this.phaseT += dt;
    if (this.phaseT > 80) {
      this.phaseT = 0;
      this.phaseIndex = (this.phaseIndex + 1) % PHASES.length;
      if (this.phaseIndex === 0) this.day += 1;
    }
    this.hunger = clamp(this.hunger - dt * 0.55, 0, 100);
    this.hygiene = clamp(this.hygiene - dt * 0.22, 0, 100);
    this.stress = clamp(this.stress + dt * 0.18 - (this.path === 'men' ? dt * 0.08 : 0), 0, 100);
    this.heat = clamp(this.heat - dt * 0.35, 0, 100);
    this.hope = clamp(this.hope - dt * 0.05 + (this.path === 'men' ? dt * 0.02 : 0), 0, 100);
    if (this.hunger < 18) this.stress = clamp(this.stress + dt * 0.4, 0, 100);
    if (this.hope < 12) this.stress = clamp(this.stress + dt * 0.25, 0, 100);
  }

  eat() {
    if (this.inv.food <= 0 && this.inv.tea <= 0) return false;
    if (this.inv.food > 0) {
      this.inv.food -= 1;
      this.hunger = clamp(this.hunger + 34, 0, 100);
    } else {
      this.inv.tea -= 1;
      this.hunger = clamp(this.hunger + 12, 0, 100);
      this.stress = clamp(this.stress - 10, 0, 100);
    }
    return true;
  }

  wash() {
    this.hygiene = clamp(this.hygiene + 40, 0, 100);
    this.stress = clamp(this.stress - 6, 0, 100);
  }

  rest() {
    this.stress = clamp(this.stress - 18, 0, 100);
    this.hunger = clamp(this.hunger - 4, 0, 100);
    this.hope = clamp(this.hope + 5, 0, 100);
  }

  smoke() {
    if (this.inv.cigs <= 0) return false;
    this.inv.cigs -= 1;
    this.stress = clamp(this.stress - 14, 0, 100);
    return true;
  }
}

function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}
