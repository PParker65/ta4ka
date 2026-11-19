/**
 * Week in хата 4. Not an escape. Choices stick until Tuesday's player comes back.
 */
import { NIGHT1, DAY2_SEDOY } from './Dialogue.js';

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
  return null;
}

export function onPhaseEnter(game, id) {
  const g = game;
  const s = g.sim;
  const door = g.prison.interactables.find((it) => it.type === 'cell-door');
  if (id === 'walk') {
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
      g.unlockLook();
      g.dialog.show(DAY2_SEDOY.who, DAY2_SEDOY.text, DAY2_SEDOY.options);
      g.dialog.onPick = (opt) => {
        s.shift(opt.black || 0, opt.red || 0, opt.men || 0);
        if (opt.hope) s.hope = Math.min(100, s.hope + opt.hope);
        if (opt.heat) s.heat = Math.min(100, s.heat + opt.heat);
        g.toast(opt.reply);
      };
    } else {
      g.subtitle('Отбой. Своя койка. Чужую не занимай.');
    }
    return;
  }
  if (id === 'shmon') {
    g.audio.clang();
    if (s.stash === 'bunk') {
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
    g.subtitle('Баланда в кормушку. Не лезь без очереди. В сортир, пока едят, не ходи.');
    return;
  }
  if (id === 'wake') {
    g.fill.intensity = 0.5;
    g.audio.buzz();
    g.subtitle(
      s.day === 1
        ? 'Подъём. Мат с коряка. День не спрашивает, готов ты или нет.'
        : `Подъём. День ${s.day}. Хата уже знает, как ты дышишь.`,
    );
  }
}

export function walkLine(sim) {
  if (sim.day >= 2) return 'Валера тихо: «Этапом шепчут Херсон. Не повторяй вслух.»';
  return 'Круг по бетону. Через сетку — небо. Небо не твоё.';
}
