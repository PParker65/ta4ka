/**
 * Week in хата 4. Not an escape. Choices stick until Tuesday's player comes back.
 */
import { NIGHT1, DAY2_SEDOY, DAY3_NIGHT, DAY4_LEHA, DAY5_COURT, WEEK_HELD } from './Dialogue.js';

export function plotObjective(sim) {
  if (sim.stage !== 'life' || !sim.propiska) return null;
  const d = sim.day;
  const ph = sim.phase.id;
  if (d === 1 && ph === 'evening') return 'Отбой. Лёха шепчет про шмон. Своя койка, не чужая.';
  if (d === 1 && ph === 'walk') return 'Конвой вывел. Круг по дворику. Назад сам не пойдёшь — заведут.';
  if (d === 2 && ph === 'shmon') {
    return sim.stash === 'bunk'
      ? 'Шмон. Нычка в матрасе — плохое место. Стой. Руки видно.'
      : 'Шмон. К стене. Руки видно. Нычку в матрасе не клади.';
  }
  if (d === 2 && ph === 'food') return 'Баланда. Очередь. В сортир, пока едят, не ходи.';
  if (d === 2 && ph === 'walk') return 'Дворик. Валера знает слух. Через стену не ори.';
  if (d === 2 && ph === 'evening') return 'Седой смотрит, кем ты стал за сутки. Не ври зря.';
  if (d >= 3 && ph === 'wake') return 'Третий день. Хата уже не спрашивает имя — спрашивает дело.';
  if (d >= 3 && sim.malyava === 'hold') return 'Малява жжёт карман. Несу, жгу или к куму — это уже сюжет, не квест.';
  if (d === 4) return 'Долг через кормушку. Лёха не забыл чай.';
  if (d >= 5) return 'Следователь на свежака. Хата спрашивает, что скажешь про них.';
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
    for (const m of g.prison.windowGlass || []) m.emissiveIntensity = 0.05;
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    if (s.day === 1 && !s.seenNight1) {
      s.seenNight1 = true;
      g.unlockLook();
      g.dialog.show(NIGHT1.who, NIGHT1.text, NIGHT1.options);
      g.dialog.onPick = (opt) => {
        if (opt.stash) s.stash = opt.stash;
        s.shift(opt.black || 0, opt.red || 0, opt.men || 0);
        if (opt.heat) s.heat = Math.min(100, s.heat + opt.heat);
        g.toast(opt.reply);
      };
    } else if (s.day === 2 && !s.seenDay2) {
      s.seenDay2 = true;
      pickDialog(g, DAY2_SEDOY);
    } else if (s.day === 3 && !s.seenDay3) {
      s.seenDay3 = true;
      pickDialog(g, DAY3_NIGHT);
    } else if (s.day === 4 && !s.seenDay4) {
      s.seenDay4 = true;
      pickDialog(g, DAY4_LEHA);
    } else if (s.day >= 5 && !s.seenDay5) {
      s.seenDay5 = true;
      pickDialog(g, DAY5_COURT);
    } else if (s.day >= 7 && !s.seenWeek) {
      s.seenWeek = true;
      pickDialog(g, WEEK_HELD);
    } else {
      g.subtitle('Отбой. Своя койка. Чужую не занимай.');
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
      g.subtitle('Кормушка: «Малява. Свежак нёс дорогу в матрасе.»');
      return;
    }
    if (s.stash === 'bunk' && s.day === 2) {
      s.heat = Math.min(100, s.heat + 22);
      s.stress = Math.min(100, s.stress + 14);
      s.hope = Math.max(0, s.hope - 8);
      g.toast('Нашли. Матрас — первое место. Жар.');
      g.subtitle('Кормушка: «Нычка. Свежак думал, что первый.»');
    } else {
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.»');
    }
    return;
  }
  if (id === 'food') {
    if (g.prison.foodTray) g.prison.foodTray.visible = true;
    g.subtitle('Баланда в кормушку. Не лезь без очереди. В сортир, пока едят, не ходи.');
    return;
  }
  if (id === 'wake') {
    g.fill.intensity = 0.5;
    for (const l of g.prison.windowFills || []) l.intensity = 0.4;
    for (const m of g.prison.windowGlass || []) m.emissiveIntensity = 0.22;
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    g.audio.buzz();
    g.subtitle(
      s.day === 1
        ? 'Подъём. Мат с коряка. День не спрашивает, готов ты или нет.'
        : `Подъём. День ${s.day}. Хата уже знает, как ты дышишь.`,
    );
  }
}

function pickDialog(g, pack) {
  const s = g.sim;
  g.unlockLook();
  g.dialog.show(pack.who, pack.text, pack.options);
  g.dialog.onPick = (opt) => {
    s.shift(opt.black || 0, opt.red || 0, opt.men || 0);
    if (opt.hope) s.hope = Math.min(100, s.hope + opt.hope);
    if (opt.heat) s.heat = Math.min(100, Math.max(0, s.heat + opt.heat));
    if (opt.stress) s.stress = Math.min(100, s.stress + opt.stress);
    if (opt.stash) s.stash = opt.stash;
    if (opt.passTea && s.inv.tea > 0) {
      s.inv.tea -= 1;
      s.rep += 1;
    }
    g.toast(opt.reply);
  };
}

export function walkLine(sim) {
  if (sim.day >= 2) return 'Валера тихо: «Этапом шепчут Херсон. Не повторяй вслух.»';
  return 'Круг по бетону. Через сетку — небо. Небо не твоё.';
}
