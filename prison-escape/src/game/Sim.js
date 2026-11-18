/** RPG state: stages, physiology, path, inventory. */

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
    this.surrendered = [];
    this.pending = ['телефон', 'деньги', 'ремень', 'шнурки', 'часы'];
    this.inv = { tea: 0, cigs: 1, food: 0, phone: 0, notes: 0 };
    this.ragChoice = null;
    this.propiska = false;
    this.frozen = false;
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
    if (this.phaseT > 28) {
      this.phaseT = 0;
      this.phaseIndex = (this.phaseIndex + 1) % PHASES.length;
      if (this.phaseIndex === 0) this.day += 1;
    }
    this.hunger = clamp(this.hunger - dt * 0.55, 0, 100);
    this.hygiene = clamp(this.hygiene - dt * 0.22, 0, 100);
    this.stress = clamp(this.stress + dt * 0.18 - (this.path === 'men' ? dt * 0.08 : 0), 0, 100);
    if (this.hunger < 18) this.stress = clamp(this.stress + dt * 0.4, 0, 100);
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
