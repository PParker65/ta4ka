/**
 * Week in хата 4. Not an escape. Choices stick until Tuesday's player comes back.
 */
import {
  NIGHT1,
  DAY2_SEDOY,
  DAY2_SEDOY_CAUGHT,
  DAY2_SEDOY_WASH,
  DAY2_YARD,
  DAY2_YARD_CAUGHT,
  DAY2_YARD_WASH,
  DAY2_FOOD,
  DAY2_FOOD_CAUGHT,
  DAY2_FOOD_WASH,
  DAY2_SHMON,
  DAY2_SHMON_CAUGHT,
  DAY2_SHMON_WASH,
  DAY2_WAKE,
  DAY2_WAKE_BUNK,
  DAY3_NIGHT,
  DAY3_NIGHT_WAIT,
  DAY3_MORNING,
  DAY3_MORNING_RED,
  DAY3_MORNING_CAUGHT,
  DAY3_FOOD,
  DAY3_FOOD_HOLD,
  DAY3_FOOD_BURN,
  DAY3_FOOD_RED,
  DAY3_WALK,
  DAY3_WALK_HOLD,
  DAY3_WALK_RED,
  DAY3_WALK_BURN,
  DAY3_SHMON_FOUND,
  DAY3_SHMON_WASH,
  DAY3_SHMON_HATCH,
  DAY3_SHMON_BURN,
  DAY4_LEHA,
  DAY4_NIGHT_WAIT,
  DAY4_WALK,
  DAY4_FOOD,
  DAY4_FOOD_WAIT,
  DAY4_WAKE,
  DAY4_WAKE_BURN,
  DAY4_WAKE_RED,
  DAY4_WAKE_WAIT,
  FOUND_NIGHT,
  DAY5_COURT,
  DAY5_WAKE,
  DAY5_SLED,
  DAY5_SLED_RED,
  DAY5_BACK_SILENT,
  DAY5_BACK_CELL,
  DAY5_BACK_SELF,
  DAY5_WALK,
  DAY6_NIGHT,
  DAY6_FOOD,
  DAY6_WALK,
  DAY7_WAKE,
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
  if (d === 2 && ph === 'wake')
    return sim.stash === 'bunk'
      ? 'Второй подъём. Нычка в матрасе. Шмон будет до пайки. К стене.'
      : 'Второй подъём. Шмон до пайки. Чаша, не матрас.';
  if (d === 2 && ph === 'shmon') {
    return sim.stash === 'bunk'
      ? 'Шмон. Нычка в матрасе — плохое место. Стой. Руки видно.'
      : 'Шмон. К стенам. Руки видно. Нычку в матрасе не клади.';
  }
  if (d === 2 && ph === 'food')
    return sim.stash === 'bunk'
      ? 'Пайка после шмона. Матрас на карандаше. Ешь не первым. Про нычку — ни звука.'
      : sim.stash === 'wash'
        ? 'Пайка. Матрас чистый. Чашу за столом не вспоминай.'
        : 'Баланда. Очередь. В сортир, пока едят, не ходи.';
  if (d === 2 && ph === 'walk')
    return sim.stash === 'bunk'
      ? 'Круг после шмона. Матрас знают. Через стену не ори.'
      : sim.stash === 'wash'
        ? 'Круг. Матрас чистый. Через стену не рассказывай про чашу.'
        : 'Дворик. Валера знает слух. Через стену не ори.';
  if (d === 2 && ph === 'evening')
    return sim.stash === 'bunk'
      ? 'Отбой. Матрас знают. Не объясняйся. Оправдания — вторая нычка.'
      : sim.stash === 'wash'
        ? 'Отбой. Чаша сегодня не их дело. Завтра бумага. Не зевай.'
        : 'Седой смотрит, кем ты стал за сутки. Не ври зря.';
  if (d === 3 && ph === 'wake')
    return sim.path === 'red'
      ? 'Третий подъём. Вчера слово село. Кормушка днём живая. Не зевай.'
      : sim.stash === 'bunk'
        ? 'Третий подъём. Вчера матрас пел. Кормушка днём живая. Не зевай.'
        : 'Третий день. Кормушка днём живая. Не зевай.';
  if (d === 3 && ph === 'shmon') {
    if (sim.malyava === 'found') return 'Нашли бумагу. К стене. Руки видно. Рот на замок.';
    if (sim.malyava === 'hold' && sim.stash === 'wash') return 'Шмон. Чаша сегодня не их дело. Не смотри на неё.';
    if (sim.malyava === 'burn') return 'Шмон. Пахнет золой. К стене. Нос казённый.';
    if (!sim.malyava) return 'Шмон. Щель ещё живая. Койки шарят. Кормушку — пока нет.';
    return 'Шмон. К стенам. Руки видно. Карман не шарь сам.';
  }
  if (d === 3 && ph === 'food' && !sim.malyava)
    return 'Пайка. Два коротких в щель — бумага, не ложка. Не зевай.';
  if (d === 3 && ph === 'food' && sim.malyava === 'hold')
    return 'Пайка. Карман жжёт. Ешь. Не читай вслух.';
  if (d === 3 && ph === 'food' && sim.malyava === 'burn')
    return 'Пайка пахнет золой. Ешь. Не свисти.';
  if (d === 3 && ph === 'food' && sim.malyava === 'admin')
    return 'Пайка лишняя. Красному ложку дают последним.';
  if (d === 3 && ph === 'evening' && !sim.malyava)
    return 'Отбой. Бумага ещё в щели. Завтра либо твоя, либо кума.';
  if (d === 3 && ph === 'walk') {
    if (sim.malyava === 'admin') return 'Третий круг без свиста. Хата уже считает.';
    if (sim.malyava === 'hold') return 'Карман жжёт даже на круге. Через стену — ни звука.';
    if (sim.malyava === 'burn') return 'Третий круг. Зола осталась в хате. Не ори про дым.';
    return 'Третий круг. Щель днём стучала. Бумага либо твоя, либо чужая.';
  }
  if (d === 4 && !sim.malyava)
    return 'Четвёртый день. Бумага вчера не ушла. Щель всё ещё живая.';
  if (d === 4 && ph === 'wake' && sim.malyava === 'hold' && !sim.teaPaid)
    return 'Четвёртый подъём. Чай ждут в щели, не после прогулки.';
  if (d === 4 && ph === 'walk') return 'Дворик. Долг чая сидит в щели, не гуляет с тобой.';
  if (d === 4 && !sim.teaPaid && sim.malyava === 'hold') return 'Чай в щели ждут. Не долг на воле.';
  if (d === 4) return 'Долг через кормушку. Лёха не забыл чай.';
  if (d === 6 && ph === 'food') return 'Шестая пайка. Ложка после смотрящего. Завтра свежак кончается.';
  if (d === 6 && ph === 'walk') return 'Шестой круг. Завтра не ори про волю.';
  if (d === 5 && ph === 'wake') return 'С коряка шепчут список. Днём щель станет кабинетом.';
  if (d === 5 && ph === 'food' && !sim.courtTalk) return 'Вызов. Следователь в щели. Про хату — или про срок.';
  if (d === 5 && sim.courtTalk === 'cell') return 'Сказал про хату. Пайка лишняя. Вечером спросят уже не словами.';
  if (d === 5 && sim.courtTalk === 'silent') return 'Про хату — ничего. Жар есть. Хата ещё дышит.';
  if (d === 5 && sim.courtTalk === 'self') return '«Ничего не видел.» Хата слышала тон. Не рассказывай сон.';
  if (d === 5) return 'Следователь на свежака. Хата спрашивает, что скажешь про них.';
  if (d === 6) return 'Шестой день. Свежак кончается. Не ори про волю.';
  if (d === 7) return 'Неделя. Свежак кончился. Молчи. Ешь. Неси, если несут.';
  if (d >= 3 && !sim.malyava && (ph === 'food' || ph === 'wake' || ph === 'evening')) {
    return 'Кормушка стучит. Бумага: нести, жечь или к куму.';
  }
  if (d >= 3 && sim.malyava === 'hold') return 'Малява жжёт карман. Несу, жгу или к куму — это уже сюжет, не квест.';
  if (d >= 3 && sim.malyava === 'burn') return 'Бумага зола. Хата напротив тише, чем надо.';
  if (d >= 3 && sim.malyava === 'admin') return 'Хата молчит. Красный ход. Пайка не греет.';
  if (d >= 3 && sim.malyava === 'found') return 'Нашли бумагу. Жар. Хата это уже знает.';
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
    if (s.day === 5 && !s.heardDay5Yard) {
      s.heardDay5Yard = true;
      pickDialog(g, DAY5_WALK);
    } else if (s.day === 6 && !s.heardDay6Yard) {
      s.heardDay6Yard = true;
      pickDialog(g, DAY6_WALK);
    } else if (s.day >= 4 && !s.heardDay4Yard) {
      s.heardDay4Yard = true;
      pickDialog(g, DAY4_WALK);
    } else if (s.day === 3 && !s.heardDay3Yard) {
      s.heardDay3Yard = true;
      if (s.malyava === 'admin' || s.path === 'red') pickDialog(g, DAY3_WALK_RED);
      else if (s.malyava === 'hold') pickDialog(g, DAY3_WALK_HOLD);
      else if (s.malyava === 'burn') pickDialog(g, DAY3_WALK_BURN);
      else pickDialog(g, DAY3_WALK);
    } else if (s.day >= 2 && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, s.stash === 'bunk' ? DAY2_YARD_CAUGHT : s.stash === 'wash' ? DAY2_YARD_WASH : DAY2_YARD);
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
    if (g.prison.cellLamp) g.prison.cellLamp.intensity = 0.18;
    for (const l of g.prison.windowFills || []) l.intensity = 0.08;
    for (const m of g.prison.windowGlass || []) {
      if ('emissiveIntensity' in m) m.emissiveIntensity = 0.05;
      if (m.color) m.color.setHex(0x9aa8b4);
    }
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    if (s.day === 1 && !s.seenNight1) {
      s.seenNight1 = true;
      pickDialog(g, NIGHT1);
    } else if (s.day === 2 && !s.seenDay2) {
      s.seenDay2 = true;
      pickDialog(g, s.stash === 'bunk' ? DAY2_SEDOY_CAUGHT : s.stash === 'wash' ? DAY2_SEDOY_WASH : DAY2_SEDOY);
    } else if (s.malyava === 'found' && !s.seenFoundNight) {
      s.seenFoundNight = true;
      pickDialog(g, FOUND_NIGHT);
    } else if (s.day === 3 && !s.seenDay3) {
      s.seenDay3 = true;
      if (s.malyava === 'admin') pickDialog(g, SNITCH_NIGHT);
      else if (s.malyava === 'hold') pickDialog(g, HOLD_NIGHT);
      else if (s.malyava === 'burn') pickDialog(g, BURN_NIGHT);
      else pickDialog(g, s.malyava ? DAY3_NIGHT : DAY3_NIGHT_WAIT);
    } else if (s.day === 4 && !s.seenDay4) {
      s.seenDay4 = true;
      pickDialog(g, s.malyava ? DAY4_LEHA : DAY4_NIGHT_WAIT);
    } else if (s.day === 5 && !s.seenDay5) {
      s.seenDay5 = true;
      pickDialog(g, day5Evening(s));
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
    if (door && !door.open) g.prison.openDoor(door);
    g.audio.clang();
    g.subtitle('Конвой в хате. К стенам. Руки видно.');
    if (s.malyava === 'hold' && s.stash !== 'wash' && s.day >= 3) {
      s.malyava = 'found';
      s.heat = Math.min(100, s.heat + 28);
      s.stress = Math.min(100, s.stress + 16);
      s.hope = Math.max(0, s.hope - 10);
      g.toast('Нашли бумагу. Карман пустой, жар полный.');
      if (!s.seenDay3Shmon) {
        s.seenDay3Shmon = true;
        pickDialog(g, DAY3_SHMON_FOUND);
      } else {
        g.subtitle('Кормушка: «Малява. Свежак нёс дорогу в кармане.»');
      }
      return;
    }
    if (s.day === 3 && !s.seenDay3Shmon) {
      s.seenDay3Shmon = true;
      if (s.malyava === 'hold' && s.stash === 'wash') pickDialog(g, DAY3_SHMON_WASH);
      else if (s.malyava === 'burn') pickDialog(g, DAY3_SHMON_BURN);
      else if (!s.malyava) pickDialog(g, DAY3_SHMON_HATCH);
      else g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.»');
      return;
    }
    if (s.day === 2 && !s.seenDay2Shmon) {
      s.seenDay2Shmon = true;
      pickDialog(g, s.stash === 'bunk' ? DAY2_SHMON_CAUGHT : s.stash === 'wash' ? DAY2_SHMON_WASH : DAY2_SHMON);
    }
    if (s.stash === 'bunk' && s.day === 2) {
      s.heat = Math.min(100, s.heat + 22);
      s.stress = Math.min(100, s.stress + 14);
      s.hope = Math.max(0, s.hope - 8);
      g.toast('Нашли. Матрас — первое место. Жар.');
      g.subtitle('Кормушка: «Нычка. Свежак думал, что первый.»');
    } else if (s.stash === 'wash' && s.day === 2) {
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.» Матрас чистый. Чаша не их дело — сегодня.');
    } else if (!(s.day === 2 && s.seenDay2Shmon)) {
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.»');
    }
    return;
  }
  if (id === 'food') {
    if (g.prison.foodTray) g.prison.foodTray.visible = true;
    if (s.day === 2 && !s.seenDay2Food) {
      s.seenDay2Food = true;
      pickDialog(g, s.stash === 'bunk' ? DAY2_FOOD_CAUGHT : s.stash === 'wash' ? DAY2_FOOD_WASH : DAY2_FOOD);
      return;
    }
    if (s.day === 3 && !s.seenDay3Food) {
      s.seenDay3Food = true;
      if (!s.malyava) pickDialog(g, DAY3_FOOD);
      else if (s.malyava === 'hold') pickDialog(g, DAY3_FOOD_HOLD);
      else if (s.malyava === 'burn') pickDialog(g, DAY3_FOOD_BURN);
      else pickDialog(g, DAY3_FOOD_RED);
      return;
    }
    if (s.day === 5 && !s.seenDay5Sled) {
      s.seenDay5Sled = true;
      pickDialog(g, s.malyava === 'admin' ? DAY5_SLED_RED : DAY5_SLED);
      return;
    }
    if (s.day === 6 && !s.seenDay6Food) {
      s.seenDay6Food = true;
      pickDialog(g, DAY6_FOOD);
      return;
    }
    if (s.day === 4 && !s.seenDay4Food) {
      s.seenDay4Food = true;
      pickDialog(g, s.malyava ? DAY4_FOOD : DAY4_FOOD_WAIT);
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
    if (g.prison.cellLamp) g.prison.cellLamp.intensity = 0.7;
    for (const l of g.prison.windowFills || []) l.intensity = 0.4;
    for (const m of g.prison.windowGlass || []) {
      if ('emissiveIntensity' in m) m.emissiveIntensity = 0.22;
      if (m.color) m.color.setHex(0xffffff);
    }
    if (g.prison.foodTray) g.prison.foodTray.visible = false;
    g.audio.buzz();
    if (s.day === 2 && !s.seenDay2Wake) {
      s.seenDay2Wake = true;
      pickDialog(g, s.stash === 'bunk' ? DAY2_WAKE_BUNK : DAY2_WAKE);
      return;
    }
    if (s.day === 3 && !s.seenDay3Morning) {
      s.seenDay3Morning = true;
      pickDialog(g, s.path === 'red' ? DAY3_MORNING_RED : s.stash === 'bunk' ? DAY3_MORNING_CAUGHT : DAY3_MORNING);
      return;
    }
    if (s.day === 4 && !s.seenDay4Wake) {
      s.seenDay4Wake = true;
      if (!s.malyava) pickDialog(g, DAY4_WAKE_WAIT);
      else if (s.malyava === 'admin' || s.courtTalk === 'cell') pickDialog(g, DAY4_WAKE_RED);
      else if (s.malyava === 'burn') pickDialog(g, DAY4_WAKE_BURN);
      else pickDialog(g, DAY4_WAKE);
      return;
    }
    if (s.day === 5 && !s.seenDay5Wake) {
      s.seenDay5Wake = true;
      pickDialog(g, DAY5_WAKE);
      return;
    }
    if (s.day === 7 && !s.seenDay7Morning) {
      s.seenDay7Morning = true;
      pickDialog(g, DAY7_WAKE);
      return;
    }
    g.subtitle(wakeLine(s));
  }
}

function day5Evening(s) {
  if (s.courtTalk === 'cell') return DAY5_BACK_CELL;
  if (s.courtTalk === 'silent') return DAY5_BACK_SILENT;
  if (s.courtTalk === 'self') return DAY5_BACK_SELF;
  return DAY5_COURT;
}

function eveningLine(s) {
  if (s.courtTalk === 'cell' || s.malyava === 'admin') return 'Отбой. Чайник молчит. Так спят с красным в хате.';
  if (s.malyava === 'hold') return 'Отбой. Карман жжёт. Своя койка, бумага не на столе.';
  if (s.malyava === 'found') return 'Отбой. Нашли днём. Ночь длиннее пайки.';
  if (s.malyava === 'burn') return 'Отбой. Пахнет золой. Своя койка.';
  if (s.courtTalk === 'silent') return 'Отбой. Щель закрылась. Своя койка.';
  return 'Отбой. Своя койка. Чужую не занимай.';
}

function wakeLine(s) {
  if (s.day === 1) return 'Подъём. Мат с коряка. День не спрашивает, готов ты или нет.';
  if (s.courtTalk === 'cell' || s.malyava === 'admin') return `Подъём. День ${s.day}. Хата не здоровается. Так начинают красных.`;
  if (s.malyava === 'found') return `Подъём. День ${s.day}. Жар с вчера. Руки видно, рот на замок.`;
  return `Подъём. День ${s.day}. Хата уже знает, как ты дышишь.`;
}

function pickDialog(g, pack) {
  const s = g.sim;
  if (g._skipPlotDialog) {
    g._skipPlotDialog = false;
    g.subtitle(`${pack.who}: ${pack.text.slice(0, 88)}`);
    return;
  }
  g.unlockLook();
  g.dialog.show(pack.who, pack.text, pack.options);
  g.dialog.onPick = (opt) => {
    s.shift(opt.black || 0, opt.red || 0, opt.men || 0);
    if (opt.hope) s.hope = Math.min(100, Math.max(0, s.hope + opt.hope));
    if (opt.heat) s.heat = Math.min(100, Math.max(0, s.heat + opt.heat));
    if (opt.stress) s.stress = Math.min(100, Math.max(0, s.stress + opt.stress));
    if (opt.stash) s.stash = opt.stash;
    if (opt.malyava) s.malyava = opt.malyava;
    if (opt.courtTalk) s.courtTalk = opt.courtTalk;
    if (opt.passTea && s.inv.tea > 0) {
      s.inv.tea -= 1;
      s.rep += 1;
      s.teaPaid = true;
    }
    g.toast(opt.reply);
  };
}

export function walkLine(sim) {
  if (sim.courtTalk === 'cell') return 'Валера не смотрит. Свист кончился в щели.';
  if (sim.malyava === 'admin') return 'Валера молчит. Свист кончился на третий день.';
  if (sim.malyava === 'burn') return 'Валера коротко: «Зола в хате. На дворе про дым не ори.»';
  if (sim.day === 5) return 'Валера: «С коряка звали. Что сказал — хата узнает вечером.»';
  if (sim.day >= 2) return 'Валера тихо: «Этапом шепчут Херсон. Не повторяй вслух.»';
  return 'Круг по бетону. Через сетку — небо. Небо не твоё.';
}

export function hatchReady(sim) {
  return sim.day >= 3 && !sim.malyava;
}
