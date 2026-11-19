/**
 * Week in хата 4. Not an escape. Choices stick until Tuesday's player comes back.
 */
import {
  NIGHT1,
  DAY2_SEDOY,
  DAY2_YARD,
  DAY2_FOOD,
  DAY3_NIGHT,
  DAY3_MORNING,
  DAY4_LEHA,
  DAY4_WALK,
  DAY5_COURT,
  DAY5_WAKE,
  DAY6_NIGHT,
  WEEK_HELD,
  HOLD_NIGHT,
  BURN_NIGHT,
  SNITCH_NIGHT,
} from './Dialogue.js';

export function plotObjective(sim) {
  if (sim.stage !== 'life' || !sim.propiska) return null;
  const d = sim.day;
  const ph = sim.phase.id;
  if (d === 1 && ph === 'evening') return 'Отбой. Лёха шепчет про шмон. Своя койка, не чужая.';
  if (d === 1 && ph === 'walk') return 'Конвой вывел. Круг по дворику. Назад сам не пойдёшь — заведут.';
  if (d === 2 && ph === 'shmon') {
    return sim.stash === 'bunk'
      ? 'Шмон. Нычка в матрасе — плохое место. Стой. Руки видно.'
      : 'Шмон. К стенам. Руки видно. Нычку в матрасе не клади.';
  }
  if (d === 2 && ph === 'food') return 'Баланда. Очередь. В сортир, пока едят, не ходи.';
  if (d === 2 && ph === 'walk') return 'Дворик. Валера знает слух. Через стену не ори.';
  if (d === 2 && ph === 'evening') return 'Седой смотрит, кем ты стал за сутки. Не ври зря.';
  if (d === 3 && ph === 'wake') return 'Третий день. Кормушка днём живая. Не зевай.';
  if (d >= 3 && !sim.malyava && (ph === 'food' || ph === 'wake' || ph === 'evening')) {
    return 'Кормушка стучит. Бумага: нести, жечь или к куму.';
  }
  if (d >= 3 && sim.malyava === 'hold') return 'Малява жжёт карман. Несу, жгу или к куму — это уже сюжет, не квест.';
  if (d >= 3 && sim.malyava === 'burn') return 'Бумага зола. Хата напротив тише, чем надо.';
  if (d >= 3 && sim.malyava === 'admin') return 'Хата молчит. Красный ход. Пайка не греет.';
  if (d >= 3 && sim.malyava === 'found') return 'Нашли бумагу. Жар. Хата это уже знает.';
  if (d === 4 && ph === 'walk') return 'Дворик. Долг чая сидит в щели, не гуляет с тобой.';
  if (d === 4) return 'Долг через кормушку. Лёха не забыл чай.';
  if (d === 5 && ph === 'wake') return 'С коряка шепчут список. Вечером хата спросит про вас.';
  if (d === 5) return 'Следователь на свежака. Хата спрашивает, что скажешь про них.';
  if (d === 6) return 'Шестой день. Свежак кончается. Не ори про волю.';
  return null;
}

export function onPhaseEnter(game, id) {
  const g = game;
  const s = g.sim;
  const door = g.prison.interactables.find((it) => it.type === 'cell-door');
  if (id === 'walk') {
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    g.prison.closeDoor(g.prison.blockDoor);
    if (door && !door.open) g.prison.openDoor(door);
    g.audio.clang();
    g.subtitle('Конвой: «Прогулка. Шагом. Дворик — круг. КПП — не твоё.»');
    g.audio.voiceOnce('walk', 'Прогулка. Шагом. Голову не поднимай.', 'Конвой');
    if (s.day >= 4 && !s.heardDay4Yard) {
      s.heardDay4Yard = true;
      pickDialog(g, DAY4_WALK);
    } else if (s.day >= 2 && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, DAY2_YARD);
    }
    return;
  }
  if (door?.open) g.prison.closeDoor(door);
  g.prison.closeDoor(g.prison.blockDoor);
  const inCell = g.player.position.x > 1.55;
  if (!inCell) {
    g.player.position.copy(g.prison.cellSpawn);
    g.input.yaw = Math.PI / 2;
    g.input.pitch = 0;
    g.toast('Конвой загнал. Дверь с той стороны.');
    g.audio.clang();
  }
  if (id === 'evening') {
    g.fill.intensity = 0.12;
    for (const l of g.prison.windowFills || []) l.intensity = 0.08;
    for (const m of g.prison.windowGlass || []) {
      if ('emissiveIntensity' in m) m.emissiveIntensity = 0.05;
      if (m.color) m.color.setHex(0x6a7380);
    }
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    if (s.day === 1 && !s.seenNight1) {
      s.seenNight1 = true;
      pickDialog(g, NIGHT1);
    } else if (s.day === 2 && !s.seenDay2) {
      s.seenDay2 = true;
      pickDialog(g, DAY2_SEDOY);
    } else if (s.day === 3 && !s.seenDay3) {
      s.seenDay3 = true;
      if (s.malyava === 'admin') pickDialog(g, SNITCH_NIGHT);
      else if (s.malyava === 'hold') pickDialog(g, HOLD_NIGHT);
      else if (s.malyava === 'burn') pickDialog(g, BURN_NIGHT);
      else pickDialog(g, DAY3_NIGHT);
    } else if (s.day === 4 && !s.seenDay4) {
      s.seenDay4 = true;
      pickDialog(g, DAY4_LEHA);
    } else if (s.day === 5 && !s.seenDay5) {
      s.seenDay5 = true;
      pickDialog(g, DAY5_COURT);
    } else if (s.day === 6 && !s.seenDay6) {
      s.seenDay6 = true;
      pickDialog(g, DAY6_NIGHT);
    } else if (s.day >= 7 && !s.seenWeek) {
      s.seenWeek = true;
      pickDialog(g, WEEK_HELD);
    } else {
      g.subtitle(eveningLine(s));
    }
    return;
  }
  if (id === 'shmon') {
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    g.audio.clang();
    if (s.malyava === 'hold' && s.day >= 3) {
      s.malyava = 'found';
      s.heat = Math.min(100, s.heat + 28);
      s.stress = Math.min(100, s.stress + 16);
      s.hope = Math.max(0, s.hope - 10);
      g.toast('Нашли бумагу. Карман пустой, жар полный.');
      g.subtitle('Кормушка: «Малява. Свежак нёс дорогу в кармане.»');
      return;
    }
    if (s.stash === 'bunk' && s.day === 2) {
      s.heat = Math.min(100, s.heat + 22);
      s.stress = Math.min(100, s.stress + 14);
      s.hope = Math.max(0, s.hope - 8);
      g.toast('Нашли. Матрас — первое место. Жар.');
      g.subtitle('Кормушка: «Нычка. Свежак думал, что первый.»');
    } else if (s.stash === 'wash' && s.day === 2) {
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.» Матрас чистый. Чаша не их дело — сегодня.');
    } else {
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.»');
    }
    return;
  }
  if (id === 'food') {
    if (g.prison.foodTray) g.prison.foodTray.visible = true;
    if (s.day === 2 && !s.seenDay2Food) {
      s.seenDay2Food = true;
      pickDialog(g, DAY2_FOOD);
      return;
    }
    if (s.day >= 3 && !s.malyava) {
      g.subtitle('Баланда. Кормушка стучит два коротких — не за пайку.');
      return;
    }
    g.subtitle('Баланда в кормушку. Не лезь без очереди. В сортир, пока едят, не ходи.');
    return;
  }
  if (id === 'wake') {
    g.fill.intensity = 0.5;
    for (const l of g.prison.windowFills || []) l.intensity = 0.4;
    for (const m of g.prison.windowGlass || []) {
      if ('emissiveIntensity' in m) m.emissiveIntensity = 0.22;
      if (m.color) m.color.setHex(0xffffff);
    }
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    g.audio.buzz();
    if (s.day === 3 && !s.seenDay3Morning) {
      s.seenDay3Morning = true;
      pickDialog(g, DAY3_MORNING);
      return;
    }
    if (s.day === 5 && !s.seenDay5Wake) {
      s.seenDay5Wake = true;
      pickDialog(g, DAY5_WAKE);
      return;
    }
    g.subtitle(wakeLine(s));
  }
}

function eveningLine(s) {
  if (s.malyava === 'admin') return 'Отбой. Чайник молчит. Так спят с красным в хате.';
  if (s.malyava === 'hold') return 'Отбой. Карман жжёт. Своя койка, бумага не на столе.';
  if (s.malyava === 'found') return 'Отбой. Нашли днём. Ночь длиннее пайки.';
  if (s.malyava === 'burn') return 'Отбой. Пахнет золой. Своя койка.';
  return 'Отбой. Своя койка. Чужую не занимай.';
}

function wakeLine(s) {
  if (s.day === 1) return 'Подъём. Мат с коряка. День не спрашивает, готов ты или нет.';
  if (s.malyava === 'admin') return `Подъём. День ${s.day}. Хата не здоровается. Так начинают красных.`;
  if (s.malyava === 'found') return `Подъём. День ${s.day}. Жар с вчера. Руки видно, рот на замок.`;
  return `Подъём. День ${s.day}. Хата уже знает, как ты дышишь.`;
}

function pickDialog(g, pack) {
  const s = g.sim;
  g.unlockLook();
  g.dialog.show(pack.who, pack.text, pack.options);
  g.dialog.onPick = (opt) => {
    s.shift(opt.black || 0, opt.red || 0, opt.men || 0);
    if (opt.hope) s.hope = Math.min(100, Math.max(0, s.hope + opt.hope));
    if (opt.heat) s.heat = Math.min(100, Math.max(0, s.heat + opt.heat));
    if (opt.stress) s.stress = Math.min(100, Math.max(0, s.stress + opt.stress));
    if (opt.stash) s.stash = opt.stash;
    if (opt.malyava) s.malyava = opt.malyava;
    if (opt.passTea && s.inv.tea > 0) {
      s.inv.tea -= 1;
      s.rep += 1;
    }
    g.toast(opt.reply);
  };
}

export function walkLine(sim) {
  if (sim.malyava === 'admin') return 'Валера молчит. Свист кончился на третий день.';
  if (sim.day >= 2) return 'Валера тихо: «Этапом шепчут Херсон. Не повторяй вслух.»';
  return 'Круг по бетону. Через сетку — небо. Небо не твоё.';
}

export function hatchReady(sim) {
  return sim.day >= 3 && !sim.malyava;
}
