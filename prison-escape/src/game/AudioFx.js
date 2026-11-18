/** Procedural door clangs / buzz — no sample files. */

export class AudioFx {
  constructor() {
    this.ctx = null;
  }

  unlock() {
    if (this.ctx) return;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    this.ctx = new AC();
  }

  clang() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'square';
    o.frequency.setValueAtTime(140, t);
    o.frequency.exponentialRampToValueAtTime(48, t + 0.28);
    g.gain.setValueAtTime(0.12, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.35);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.36);
  }

  buzz() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sawtooth';
    o.frequency.value = 90;
    g.gain.setValueAtTime(0.05, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.5);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.5);
  }

  bark() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'square';
    o.frequency.setValueAtTime(180, t);
    o.frequency.exponentialRampToValueAtTime(90, t + 0.12);
    g.gain.setValueAtTime(0.09, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.2);
  }

  ambient() {
    this.unlock();
    if (!this.ctx || this._amb) return;
    const ctx = this.ctx;
    const buffer = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * 0.15;
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    src.loop = true;
    const f = ctx.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.value = 380;
    const g = ctx.createGain();
    g.gain.value = 0.045;
    src.connect(f).connect(g).connect(ctx.destination);
    src.start();
    this._amb = src;
  }

  rumble() {
    this.unlock();
    if (!this.ctx || this._rumble) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sawtooth';
    o.frequency.value = 42;
    g.gain.value = 0.035;
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    this._rumble = { o, g };
  }

  stopRumble() {
    if (!this._rumble || !this.ctx) return;
    const t = this.ctx.currentTime;
    this._rumble.g.gain.exponentialRampToValueAtTime(0.001, t + 0.8);
    this._rumble.o.stop(t + 0.85);
    this._rumble = null;
  }

  doorScrape() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sawtooth';
    o.frequency.setValueAtTime(90, t);
    o.frequency.exponentialRampToValueAtTime(38, t + 1.6);
    g.gain.setValueAtTime(0.07, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 1.7);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 1.72);
  }

  siren() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sine';
    o.frequency.setValueAtTime(620, t);
    o.frequency.linearRampToValueAtTime(410, t + 1.1);
    g.gain.setValueAtTime(0.03, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 1.4);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 1.42);
  }

  foot() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'triangle';
    o.frequency.value = 52 + Math.random() * 36;
    g.gain.setValueAtTime(0.03 + Math.random() * 0.025, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.11);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.12);
    const o2 = this.ctx.createOscillator();
    const g2 = this.ctx.createGain();
    o2.type = 'square';
    o2.frequency.value = 90 + Math.random() * 40;
    g2.gain.setValueAtTime(0.012, t);
    g2.gain.exponentialRampToValueAtTime(0.001, t + 0.05);
    o2.connect(g2).connect(this.ctx.destination);
    o2.start(t);
    o2.stop(t + 0.06);
  }

  clippers() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sawtooth';
    o.frequency.value = 70;
    g.gain.setValueAtTime(0.04, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 1.4);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 1.42);
  }
}
