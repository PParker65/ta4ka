let ctx: AudioContext | null = null;

function ac(): AudioContext | null {
  try {
    ctx ??= new AudioContext();
    return ctx;
  } catch {
    return null;
  }
}

export function blip(kind: "hit" | "ok" | "no" | "coin"): void {
  const c = ac();
  if (!c) return;
  const o = c.createOscillator();
  const g = c.createGain();
  o.connect(g);
  g.connect(c.destination);
  const now = c.currentTime;
  if (kind === "hit") {
    o.type = "square";
    o.frequency.setValueAtTime(140, now);
    o.frequency.exponentialRampToValueAtTime(60, now + 0.12);
    g.gain.setValueAtTime(0.08, now);
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
  } else if (kind === "ok") {
    o.type = "triangle";
    o.frequency.setValueAtTime(420, now);
    o.frequency.exponentialRampToValueAtTime(660, now + 0.08);
    g.gain.setValueAtTime(0.06, now);
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
  } else if (kind === "coin") {
    o.type = "square";
    o.frequency.setValueAtTime(880, now);
    o.frequency.exponentialRampToValueAtTime(1320, now + 0.05);
    g.gain.setValueAtTime(0.04, now);
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
  } else {
    o.type = "sawtooth";
    o.frequency.setValueAtTime(90, now);
    g.gain.setValueAtTime(0.05, now);
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
  }
  o.start(now);
  o.stop(now + 0.2);
}
