/** Procedural SFX plus speech for dialogue. */

export class AudioFx {
  constructor() {
    this.ctx = null;
  }

  unlock() {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    if (!this.ctx) this.ctx = new AC();
    if (this.ctx.state === 'suspended') this.ctx.resume();
  }

  voice(text, who = '') {
    if (!text || typeof window === 'undefined' || !window.speechSynthesis) return;
    const clean = String(text)
      .replace(/[«»]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
    if (clean.length < 2) return;
    window.speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(clean.slice(0, 280));
    u.lang = 'ru-RU';
    u.rate = 0.94;
    const w = (who || '').toLowerCase();
    if (w.includes('седой') || w.includes('смотрящ')) {
      u.pitch = 0.68;
      u.rate = 0.88;
    } else if (w.includes('лёха') || w.includes('леха')) {
      u.pitch = 1.08;
    } else if (w.includes('валера')) {
      u.pitch = 0.95;
    } else if (w.includes('конвой') || w.includes('дежурн')) {
      u.pitch = 0.72;
      u.rate = 1.02;
    } else {
      u.pitch = 0.9;
    }
    window.speechSynthesis.speak(u);
  }

  clang() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'square';
    o.frequency.setValueAtTime(160, t);
    o.frequency.exponentialRampToValueAtTime(52, t + 0.32);
    g.gain.setValueAtTime(0.22, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.4);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.42);
  }

  buzz() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sawtooth';
    o.frequency.value = 90;
    g.gain.setValueAtTime(0.1, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.55);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.55);
  }

  bark() {
    this.unlock();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'square';
    o.frequency.setValueAtTime(190, t);
    o.frequency.exponentialRampToValueAtTime(80, t + 0.14);
    g.gain.setValueAtTime(0.16, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.2);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.22);
  }

  ambient() {
    this.unlock();
    if (!this.ctx || this._amb) return;
    const ctx = this.ctx;
    const buffer = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * 0.22;
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    src.loop = true;
    const f = ctx.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.value = 420;
    const g = ctx.createGain();
    g.gain.value = 0.08;
    src.connect(f).connect(g).connect(ctx.destination);
    src.start();
    this._amb = src;
    this.drip();
    this.murmur();
  }

  drip() {
    if (!this.ctx || this._drip) return;
    const loop = () => {
      if (!this.ctx) return;
      const t = this.ctx.currentTime;
      const o = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      o.type = 'sine';
      o.frequency.setValueAtTime(880, t);
      o.frequency.exponentialRampToValueAtTime(220, t + 0.08);
      g.gain.setValueAtTime(0.045, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
      o.connect(g).connect(this.ctx.destination);
      o.start(t);
      o.stop(t + 0.14);
      this._drip = setTimeout(loop, 1400 + Math.random() * 2200);
    };
    loop();
  }

  murmur() {
    if (!this.ctx || this._mur) return;
    const ctx = this.ctx;
    const buffer = ctx.createBuffer(1, ctx.sampleRate * 3, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * 0.5;
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    src.loop = true;
    const f = ctx.createBiquadFilter();
    f.type = 'bandpass';
    f.frequency.value = 280;
    f.Q.value = 0.7;
    const g = ctx.createGain();
    g.gain.value = 0.03;
    src.connect(f).connect(g).connect(ctx.destination);
    src.start();
    this._mur = src;
  }

  rumble() {
    this.unlock();
    if (!this.ctx || this._rumble) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = 'sawtooth';
    o.frequency.value = 42;
    g.gain.value = 0.06;
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
    g.gain.setValueAtTime(0.12, t);
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
    g.gain.setValueAtTime(0.06, t);
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
    g.gain.setValueAtTime(0.07 + Math.random() * 0.03, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 0.13);
    const o2 = this.ctx.createOscillator();
    const g2 = this.ctx.createGain();
    o2.type = 'square';
    o2.frequency.value = 90 + Math.random() * 40;
    g2.gain.setValueAtTime(0.025, t);
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
    g.gain.setValueAtTime(0.08, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 1.4);
    o.connect(g).connect(this.ctx.destination);
    o.start(t);
    o.stop(t + 1.42);
  }
}
