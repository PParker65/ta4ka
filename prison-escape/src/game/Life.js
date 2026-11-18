/**
 * The Escapists loop: be where the statute says, then steal minutes for yourself.
 * Shawshank: hope is a thing they can take. Variable events so the next hour might matter.
 */

const PLACE = {
  wake: 'bunk',
  shmon: 'bunk',
  food: 'food',
  walk: 'exit',
  evening: 'bunk',
};

const EVENTS = [
  (g) => {
    g.sim.inv.notes += 1;
    g.sim.hope = Math.min(100, g.sim.hope + 14);
    g.sim.stress = Math.max(0, g.sim.stress - 6);
    g.toast('Из щели — малява. Бумага пахнет волей.');
    g.subtitle('Кто-то с этажа помнит твоё имя. Имена здесь — контрабанда.');
  },
  (g) => {
    g.subtitle('Лёха, тихо: «Цигарка есть — расскажу, как ходит конвой после отбоя.»');
  },
  (g) => {
    g.sim.stress = Math.min(100, g.sim.stress + 10);
    g.subtitle('Шаги на коряке. Свет в кормушке. Нет — мимо. Сердце всё равно стучит.');
  },
  (g) => {
    g.subtitle('Седой: «Общак не спрашивает. Общак помнит, кто кинул чай.»');
  },
  (g) => {
    g.sim.hope = Math.min(100, g.sim.hope + 8);
    g.subtitle('Валера насвистывает. На секунду хата — не камера.');
  },
  (g) => {
    g.audio.clang();
    g.subtitle('Кормушка: «Свежак. Масть какую держишь? Руку через решётку не суй.»');
  },
];

const HATCH = [
  'Из четвёртой: «Не здоровайся за руку вслепую.»',
  'Шепот: «Баланда сегодня как клей. Не спорь.»',
  'Смех за дверью. Не про тебя. Ещё нет.',
  '«Адвокат — после бани. Сейчас ты мясо в описи.»',
  'Металл о металл. Кто-то считает дни вслух.',
];

export function lifeTick(game, dt) {
  const s = game.sim;
  if (s.stage === 'life') {
    const need = PLACE[s.phase.id];
    const it = game.prison.interactables.find((x) => x.type === need);
    if (it) {
      const d = Math.hypot(game.player.position.x - it.position.x, game.player.position.z - it.position.z);
      if (d < 2.4) s.attended = true;
    }
    if (s.phaseIndex !== s._lifePhase) {
      if (s._lifePhase != null && !s.attended) {
        s.heat = Math.min(100, s.heat + 16);
        s.stress = Math.min(100, s.stress + 8);
        s.hope = Math.max(0, s.hope - 6);
        game.toast('Распорядок прошёл мимо. Жар. Конвой замечает дыры.');
      } else if (s._lifePhase != null && s.attended) {
        s.hope = Math.min(100, s.hope + 4);
        s.heat = Math.max(0, s.heat - 5);
      }
      s.attended = false;
      s._lifePhase = s.phaseIndex;
      if (Math.random() < 0.72) EVENTS[(Math.random() * EVENTS.length) | 0](game);
    }
  }

  const p = game.player.position;
  if (p.z > 0.4 && p.z < 36 && Math.abs(p.x) < 1.5 && s.stage !== 'kpp') {
    game._hatchT = (game._hatchT || 0) + dt;
    if (game._hatchT > 7.5) {
      game._hatchT = 0;
      game.subtitle(HATCH[(Math.random() * HATCH.length) | 0]);
    }
  }
}
