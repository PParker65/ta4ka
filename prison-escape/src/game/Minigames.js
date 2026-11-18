/** Cards (на интерес) and malyava-on-a-rope overlays. */

export class Minigames {
  constructor(sim, toast) {
    this.sim = sim;
    this.toast = toast;
    this.cards = document.getElementById('cards');
    this.rope = document.getElementById('rope');
    this.open = false;
  }

  playCards() {
    if (this.sim.inv.cigs < 1) {
      this.toast('Нет сигарет на интерес');
      return;
    }
    this.open = true;
    this.cards.classList.remove('hidden');
    this.cards.classList.add('flex');
    const you = 2 + Math.floor(Math.random() * 13);
    const them = 2 + Math.floor(Math.random() * 13);
    const names = ['', '', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'В', 'Д', 'К', 'Т'];
    document.getElementById('card-you').textContent = names[you];
    document.getElementById('card-them').textContent = names[them];
    const win = you > them;
    document.getElementById('card-result').textContent = win
      ? 'Взял. +1 цигарка, уважение хаты.'
      : 'Проиграл цигарку.';
    if (win) {
      this.sim.inv.cigs += 1;
      this.sim.shift(1, 0, 0);
    } else {
      this.sim.inv.cigs -= 1;
      this.sim.stress = Math.min(100, this.sim.stress + 8);
    }
  }

  closeCards() {
    this.cards.classList.add('hidden');
    this.cards.classList.remove('flex');
    this.open = false;
  }

  playRope() {
    this.open = true;
    this.rope.classList.remove('hidden');
    this.rope.classList.add('flex');
    const bar = document.getElementById('rope-bar');
    const knob = document.getElementById('rope-knob');
    let x = 8;
    let dir = 1;
    const tick = () => {
      if (this.rope.classList.contains('hidden')) return;
      x += dir * 2.4;
      if (x > 92) dir = -1;
      if (x < 8) dir = 1;
      knob.style.left = `${x}%`;
      this._ropeX = x;
      this._ropeRaf = requestAnimationFrame(tick);
    };
    cancelAnimationFrame(this._ropeRaf);
    this._ropeRaf = requestAnimationFrame(tick);
    bar.onclick = (e) => {
      e.stopPropagation();
      this.finishRope();
    };
  }

  finishRope() {
    cancelAnimationFrame(this._ropeRaf);
    this.rope.classList.add('hidden');
    this.rope.classList.remove('flex');
    this.open = false;
    const hit = Math.abs((this._ropeX || 50) - 50) < 14;
    if (hit) {
      this.sim.inv.notes += 1;
      this.sim.shift(1, 0, 0);
      this.toast('Малява прошла по дороге');
    } else {
      this.sim.stress = Math.min(100, this.sim.stress + 12);
      this.toast('Верёвка дёрнулась — чуть не спалили');
    }
  }
}
