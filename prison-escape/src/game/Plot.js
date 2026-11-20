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
  DAY3_MORNING_HOLD,
  DAY3_MORNING_BURN,
  DAY3_FOOD,
  DAY3_FOOD_HOLD,
  DAY3_FOOD_BURN,
  DAY3_FOOD_RED,
  DAY3_FOOD_FOUND,
  DAY3_WALK,
  DAY3_WALK_HOLD,
  DAY3_WALK_RED,
  DAY3_WALK_BURN,
  DAY3_WALK_FOUND,
  DAY3_SHMON_FOUND,
  DAY3_SHMON_WASH,
  DAY3_SHMON_HATCH,
  DAY3_SHMON_BURN,
  DAY4_LEHA,
  DAY4_NIGHT_WAIT,
  DAY4_LEHA_HOLD,
  DAY4_LEHA_FOUND,
  DAY4_LEHA_BURN,
  DAY4_LEHA_RED,
  DAY4_WALK,
  DAY4_WALK_WAIT,
  DAY4_WALK_PAID,
  DAY4_WALK_FOUND,
  DAY4_WALK_BURN,
  DAY4_WALK_RED,
  DAY4_FOOD,
  DAY4_FOOD_WAIT,
  DAY4_FOOD_HOLD,
  DAY4_FOOD_FOUND,
  DAY4_FOOD_BURN,
  DAY4_FOOD_RED,
  DAY4_WAKE,
  DAY4_WAKE_BURN,
  DAY4_WAKE_RED,
  DAY4_WAKE_WAIT,
  DAY4_WAKE_FOUND,
  DAY4_WAKE_HOLD,
  FOUND_NIGHT,
  DAY5_COURT,
  DAY5_COURT_GONE,
  DAY5_WAKE,
  DAY5_WAKE_GONE,
  DAY5_SLED,
  DAY5_SLED_GONE,
  DAY5_SLED_RED,
  DAY5_BACK_SILENT,
  DAY5_BACK_CELL,
  DAY5_BACK_SELF,
  DAY5_WALK,
  DAY5_WALK_GONE,
  DAY5_WALK_HOLD,
  DAY5_WALK_FOUND,
  DAY5_WALK_BURN,
  DAY5_WALK_RED,
  DAY6_NIGHT,
  DAY6_NIGHT_GONE,
  DAY6_NIGHT_RED,
  DAY6_NIGHT_FOUND,
  DAY6_NIGHT_BURN,
  DAY6_NIGHT_HOLD,
  DAY6_FOOD,
  DAY6_FOOD_GONE,
  DAY6_FOOD_RED,
  DAY6_FOOD_FOUND,
  DAY6_FOOD_BURN,
  DAY6_FOOD_HOLD,
  DAY6_WALK,
  DAY6_WALK_GONE,
  DAY6_WALK_RED,
  DAY6_WALK_FOUND,
  DAY6_WALK_BURN,
  DAY6_WALK_HOLD,
  DAY7_WAKE,
  DAY7_WAKE_GONE,
  DAY7_WAKE_RED,
  DAY7_WAKE_FOUND,
  DAY7_WAKE_BURN,
  DAY7_WAKE_HOLD,
  WEEK_HELD,
  WEEK_HELD_GONE,
  WEEK_HELD_RED,
  WEEK_HELD_FOUND,
  WEEK_HELD_BURN,
  WEEK_HELD_HOLD,
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
  if (d === 3 && ph === 'food' && sim.malyava === 'found')
    return 'Третья пайка. Нашли. Жар ест вместе с баландой. Рот на замок.';
  if (d === 3 && ph === 'food' && sim.malyava === 'admin')
    return 'Пайка лишняя. Красному ложку дают последним.';
  if (d === 3 && ph === 'evening' && !sim.malyava)
    return 'Отбой. Бумага ещё в щели. Завтра либо твоя, либо кума.';
  if (d === 3 && ph === 'walk') {
    if (sim.malyava === 'admin') return 'Третий круг без свиста. Хата уже считает.';
    if (sim.malyava === 'hold') return 'Карман жжёт даже на круге. Через стену — ни звука.';
    if (sim.malyava === 'burn') return 'Третий круг. Зола осталась в хате. Не ори про дым.';
    if (sim.malyava === 'found') return 'Третий круг. Нашли. Через стену не ори про шмон.';
    return 'Третий круг. Щель днём стучала. Бумага либо твоя, либо чужая.';
  }
  if (d === 4 && ph === 'walk')
    return weekRed(sim)
      ? 'Четвёртый круг. Свист кончился. Через сетку — ни звука.'
      : !sim.malyava
        ? 'Четвёртый круг. Бумага в щели. Не зевай вечером.'
        : sim.malyava === 'found'
          ? 'Четвёртый круг. Нашли. Через стену не ори про шмон.'
          : sim.malyava === 'burn'
            ? 'Четвёртый круг. Зола в хате. Про дым — ни звука.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? 'Четвёртый круг. Чай ушёл. Карман нет. Через стену — ни звука.'
              : 'Дворик. Долг чая сидит в щели, не гуляет с тобой.';
  if (d === 4 && ph === 'food')
    return weekRed(sim)
      ? 'Четвёртая пайка. Ложка последняя. Чайник молчит. Ешь после хаты.'
      : !sim.malyava
        ? 'Четвёртая пайка. Щель живая. Ешь. Потом бери. Не зевай.'
        : sim.malyava === 'found'
          ? 'Четвёртая пайка. Нашли. Жар ест вместе с баландой. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Четвёртая пайка. Пахнет золой. Про дым — ни слова.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? 'Четвёртая пайка. Чай ушёл. Карман жжёт. За столом не читай.'
              : 'Четвёртая пайка. Кто не отдаёт чай в щель — пустое место.';
  if (d === 4 && ph === 'evening')
    return weekRed(sim)
      ? 'Четвёртый отбой. Чайник молчит. Хата не здоровается.'
      : !sim.malyava
        ? 'Четвёртый отбой. Бумага в щели уже двое суток. Не зевай.'
        : sim.malyava === 'found'
          ? 'Четвёртый отбой. Нашли. Жар не сняли. Молчи.'
          : sim.malyava === 'burn'
            ? 'Четвёртый отбой. Зола ещё пахнет. Не свисти в полный голос.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? 'Четвёртый отбой. Чай ушёл. Карман жжёт. Не читай при лампе.'
              : 'Чай, что через кормушку ушёл, ждут обратно.';
  if (d === 4 && ph === 'wake')
    return weekRed(sim)
      ? 'Четвёртый подъём. Чайник молчит. Пайка лишняя.'
      : !sim.malyava
        ? 'Четвёртый подъём. Бумага вчера не ушла. Щель всё ещё живая.'
        : sim.malyava === 'found'
          ? 'Четвёртый подъём. Нашли. Жар не сняли за ночь. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Четвёртый подъём. Зола ещё пахнет. Не свисти в полный голос.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? 'Четвёртый подъём. Чай ушёл. Карман жжёт. Не шарь при лампе.'
              : 'Четвёртый подъём. Чай ждут в щели, не после прогулки.';
  if (d === 4 && !sim.malyava)
    return 'Четвёртый день. Бумага вчера не ушла. Щель всё ещё живая.';
  if (d === 4 && ph === 'wake' && sim.malyava === 'hold' && !sim.teaPaid)
    return 'Четвёртый подъём. Чай ждут в щели, не после прогулки.';
  if (d === 4 && !sim.teaPaid && sim.malyava === 'hold') return 'Чай в щели ждут. Не долг на воле.';
  if (d === 4) return 'Долг через кормушку. Лёха не забыл чай.';
  if (d === 6 && ph === 'food')
    return weekRed(sim)
      ? 'Шестая пайка. Ложка последняя. Чайник молчит. Ешь после хаты.'
      : sim.malyava === 'gone'
        ? 'Шестая пайка. Щель пустая с пятого. Ложка после смотрящего. Папка уже не пустая.'
        : sim.malyava === 'found'
          ? 'Шестая пайка. Жар с шмона. Ложка после смотрящего. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Шестая пайка. Пахнет золой. Ложка после смотрящего. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? 'Шестая пайка. Карман жжёт. Ложка после смотрящего. Бумагу за столом не читай.'
              : 'Шестая пайка. Ложка после смотрящего. Завтра свежак кончается.';
  if (d === 6 && ph === 'walk')
    return weekRed(sim)
      ? 'Шестой круг. Свист кончился в щели. Через стену — ни звука.'
      : sim.malyava === 'gone'
        ? 'Шестой круг. Бумагу взяли без тебя. Завтра не ори про волю.'
        : sim.malyava === 'found'
          ? 'Шестой круг. Нашли в кармане. Через стену не ори про шмон.'
          : sim.malyava === 'burn'
            ? 'Шестой круг. Зола в хате. Не ори про дым.'
            : sim.malyava === 'hold'
              ? 'Шестой круг. Карман жжёт даже на бетоне. Через стену — ни звука.'
              : 'Шестой круг. Завтра не ори про волю.';
  if (d === 5 && ph === 'wake')
    return sim.malyava === 'gone'
      ? 'Щель пустая. Бумагу взяли без тебя. Днём щель станет кабинетом.'
      : 'С коряка шепчут список. Днём щель станет кабинетом.';
  if (d === 5 && ph === 'food' && !sim.courtTalk)
    return sim.malyava === 'gone'
      ? 'Вызов. Бумага уже в папке. Следователь знает щель. Про хату — или про срок.'
      : 'Вызов. Следователь в щели. Про хату — или про срок.';
  if (d === 5 && sim.courtTalk === 'cell') return 'Сказал про хату. Пайка лишняя. Вечером спросят уже не словами.';
  if (d === 5 && sim.courtTalk === 'silent') return 'Про хату — ничего. Жар есть. Хата ещё дышит.';
  if (d === 5 && sim.courtTalk === 'self') return '«Ничего не видел.» Хата слышала тон. Не рассказывай сон.';
  if (d === 5 && ph === 'walk')
    return weekRed(sim)
      ? 'Пятый круг. Свист кончился. Через сетку — ни звука.'
      : sim.malyava === 'gone'
        ? 'Пятый круг. Щель пустая. Через сетку не ори.'
        : sim.malyava === 'found'
          ? 'Пятый круг. Нашли. Через сетку не ори про шмон.'
          : sim.malyava === 'burn'
            ? 'Пятый круг. Зола в хате. Про дым — ни звука.'
            : sim.malyava === 'hold'
              ? 'Пятый круг. Карман жжёт. Через сетку про карман — ни звука.'
              : 'Пятый круг. С коряка звали. Что скажешь — хата узнает.';
  if (d === 5 && sim.malyava === 'gone') return 'Щель отдала бумагу без тебя. Следователь уже читал.';
  if (d === 5) return 'Следователь на свежака. Хата спрашивает, что скажешь про них.';
  if (d === 6)
    return weekRed(sim)
      ? 'Шестой день. Имена в щели. Свежак кончается красным.'
      : sim.malyava === 'gone'
        ? 'Шестой день. Щель пустая с пятого. Свежак кончается. Не ори про волю.'
        : sim.malyava === 'found'
          ? 'Шестой день. Жар с кармана. Свежак кончается. Не оправдывайся.'
          : sim.malyava === 'burn'
            ? 'Шестой день. Зола. Свежак кончается. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? 'Шестой день. Карман жжёт. Свежак кончается. Неси или жги.'
              : 'Шестой день. Свежак кончается. Не ори про волю.';
  if (d === 7)
    return weekRed(sim)
      ? 'Неделя. Свежак кончился красным. Молчи. Ешь последним.'
      : sim.malyava === 'gone'
        ? 'Неделя. Бумагу взяли без тебя. Свежак кончился. Молчи. Ешь.'
        : sim.malyava === 'found'
          ? 'Неделя. Нашли. Не выселили. Свежак кончился на карандаше.'
          : sim.malyava === 'burn'
            ? 'Неделя. Бумага зола. Свежак кончился. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? 'Неделя. Свежак кончился. Карман нет. Неси или жги.'
              : 'Неделя. Свежак кончился. Молчи. Ешь. Неси, если несут.';
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
      pickDialog(g, weekPick(s, { red: DAY5_WALK_RED, gone: DAY5_WALK_GONE, found: DAY5_WALK_FOUND, burn: DAY5_WALK_BURN, hold: DAY5_WALK_HOLD, ok: DAY5_WALK }));
    } else if (s.day === 6 && !s.heardDay6Yard) {
      s.heardDay6Yard = true;
      pickDialog(g, weekPick(s, { red: DAY6_WALK_RED, gone: DAY6_WALK_GONE, found: DAY6_WALK_FOUND, burn: DAY6_WALK_BURN, hold: DAY6_WALK_HOLD, ok: DAY6_WALK }));
    } else if (s.day >= 4 && !s.heardDay4Yard) {
      s.heardDay4Yard = true;
      pickDialog(g, day4Walk(s));
    } else if (s.day === 3 && !s.heardDay3Yard) {
      s.heardDay3Yard = true;
      pickDialog(g, day3Walk(s));
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
    } else if (s.day <= 3 && s.malyava === 'found' && !s.seenFoundNight) {
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
      pickDialog(g, day4Evening(s));
    } else if (s.day === 5 && !s.seenDay5) {
      s.seenDay5 = true;
      pickDialog(g, day5Evening(s));
    } else if (s.day === 6 && !s.seenDay6) {
      s.seenDay6 = true;
      pickDialog(g, weekPick(s, { red: DAY6_NIGHT_RED, gone: DAY6_NIGHT_GONE, found: DAY6_NIGHT_FOUND, burn: DAY6_NIGHT_BURN, hold: DAY6_NIGHT_HOLD, ok: DAY6_NIGHT }));
    } else if (s.day >= 7 && !s.seenWeek) {
      s.seenWeek = true;
      pickDialog(g, weekPick(s, { red: WEEK_HELD_RED, gone: WEEK_HELD_GONE, found: WEEK_HELD_FOUND, burn: WEEK_HELD_BURN, hold: WEEK_HELD_HOLD, ok: WEEK_HELD }));
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
      pickDialog(g, day3Food(s));
      return;
    }
    if (s.day === 5 && !s.seenDay5Sled) {
      s.seenDay5Sled = true;
      if (!s.malyava) {
        s.malyava = 'gone';
        s.heat = Math.min(100, s.heat + 12);
      }
      pickDialog(g, s.malyava === 'admin' ? DAY5_SLED_RED : s.malyava === 'gone' ? DAY5_SLED_GONE : DAY5_SLED);
      return;
    }
    if (s.day === 6 && !s.seenDay6Food) {
      s.seenDay6Food = true;
      pickDialog(g, weekPick(s, { red: DAY6_FOOD_RED, gone: DAY6_FOOD_GONE, found: DAY6_FOOD_FOUND, burn: DAY6_FOOD_BURN, hold: DAY6_FOOD_HOLD, ok: DAY6_FOOD }));
      return;
    }
    if (s.day === 4 && !s.seenDay4Food) {
      s.seenDay4Food = true;
      pickDialog(g, day4Food(s));
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
      pickDialog(g, day3Morning(s));
      return;
    }
    if (s.day === 4 && !s.seenDay4Wake) {
      s.seenDay4Wake = true;
      pickDialog(g, day4Wake(s));
      return;
    }
    if (s.day === 5 && !s.seenDay5Wake) {
      s.seenDay5Wake = true;
      if (!s.malyava) {
        s.malyava = 'gone';
        s.heat = Math.min(100, s.heat + 12);
        s.hope = Math.max(0, s.hope - 6);
        pickDialog(g, DAY5_WAKE_GONE);
      } else {
        pickDialog(g, DAY5_WAKE);
      }
      return;
    }
    if (s.day === 7 && !s.seenDay7Morning) {
      s.seenDay7Morning = true;
      pickDialog(g, weekPick(s, { red: DAY7_WAKE_RED, gone: DAY7_WAKE_GONE, found: DAY7_WAKE_FOUND, burn: DAY7_WAKE_BURN, hold: DAY7_WAKE_HOLD, ok: DAY7_WAKE }));
      return;
    }
    g.subtitle(wakeLine(s));
  }
}

function day4Walk(s) {
  if (weekRed(s)) return DAY4_WALK_RED;
  if (!s.malyava) return DAY4_WALK_WAIT;
  if (s.malyava === 'found') return DAY4_WALK_FOUND;
  if (s.malyava === 'burn') return DAY4_WALK_BURN;
  if (s.malyava === 'hold' && s.teaPaid) return DAY4_WALK_PAID;
  return DAY4_WALK;
}

function day4Food(s) {
  if (weekRed(s)) return DAY4_FOOD_RED;
  if (!s.malyava) return DAY4_FOOD_WAIT;
  if (s.malyava === 'found') return DAY4_FOOD_FOUND;
  if (s.malyava === 'burn') return DAY4_FOOD_BURN;
  if (s.malyava === 'hold' && s.teaPaid) return DAY4_FOOD_HOLD;
  return DAY4_FOOD;
}

function day4Evening(s) {
  if (weekRed(s)) return DAY4_LEHA_RED;
  if (!s.malyava) return DAY4_NIGHT_WAIT;
  if (s.malyava === 'found') return DAY4_LEHA_FOUND;
  if (s.malyava === 'burn') return DAY4_LEHA_BURN;
  if (s.malyava === 'hold' && s.teaPaid) return DAY4_LEHA_HOLD;
  return DAY4_LEHA;
}

function day4Wake(s) {
  if (weekRed(s)) return DAY4_WAKE_RED;
  if (!s.malyava) return DAY4_WAKE_WAIT;
  if (s.malyava === 'found') return DAY4_WAKE_FOUND;
  if (s.malyava === 'burn') return DAY4_WAKE_BURN;
  if (s.malyava === 'hold' && s.teaPaid) return DAY4_WAKE_HOLD;
  return DAY4_WAKE;
}

function day3Walk(s) {
  if (s.malyava === 'admin' || s.path === 'red') return DAY3_WALK_RED;
  if (s.malyava === 'hold') return DAY3_WALK_HOLD;
  if (s.malyava === 'burn') return DAY3_WALK_BURN;
  if (s.malyava === 'found') return DAY3_WALK_FOUND;
  return DAY3_WALK;
}

function day3Food(s) {
  if (!s.malyava) return DAY3_FOOD;
  if (s.malyava === 'hold') return DAY3_FOOD_HOLD;
  if (s.malyava === 'burn') return DAY3_FOOD_BURN;
  if (s.malyava === 'found') return DAY3_FOOD_FOUND;
  return DAY3_FOOD_RED;
}

function day3Morning(s) {
  if (s.malyava === 'admin' || s.path === 'red') return DAY3_MORNING_RED;
  if (s.malyava === 'hold') return DAY3_MORNING_HOLD;
  if (s.malyava === 'burn') return DAY3_MORNING_BURN;
  if (s.stash === 'bunk') return DAY3_MORNING_CAUGHT;
  return DAY3_MORNING;
}

function weekRed(s) {
  return s.courtTalk === 'cell' || s.malyava === 'admin';
}

function weekPick(s, packs) {
  if (weekRed(s) && packs.red) return packs.red;
  if (s.malyava === 'gone' && packs.gone) return packs.gone;
  if (s.malyava === 'found' && packs.found) return packs.found;
  if (s.malyava === 'burn' && packs.burn) return packs.burn;
  if (s.malyava === 'hold' && packs.hold) return packs.hold;
  return packs.ok;
}

function day5Evening(s) {
  if (s.courtTalk === 'cell') return DAY5_BACK_CELL;
  if (s.courtTalk === 'silent') return DAY5_BACK_SILENT;
  if (s.courtTalk === 'self') return DAY5_BACK_SELF;
  if (s.malyava === 'gone') return DAY5_COURT_GONE;
  return DAY5_COURT;
}

function eveningLine(s) {
  if (s.courtTalk === 'cell' || s.malyava === 'admin') return 'Отбой. Чайник молчит. Так спят с красным в хате.';
  if (s.malyava === 'hold') return 'Отбой. Карман жжёт. Своя койка, бумага не на столе.';
  if (s.malyava === 'found') return 'Отбой. Нашли днём. Ночь длиннее пайки.';
  if (s.malyava === 'burn') return 'Отбой. Пахнет золой. Своя койка.';
  if (s.malyava === 'gone') return 'Отбой. Щель пустая с утра. Своя койка.';
  if (s.courtTalk === 'silent') return 'Отбой. Щель закрылась. Своя койка.';
  return 'Отбой. Своя койка. Чужую не занимай.';
}

function wakeLine(s) {
  if (s.day === 1) return 'Подъём. Мат с коряка. День не спрашивает, готов ты или нет.';
  if (s.courtTalk === 'cell' || s.malyava === 'admin') return `Подъём. День ${s.day}. Хата не здоровается. Так начинают красных.`;
  if (s.malyava === 'found') return `Подъём. День ${s.day}. Жар с вчера. Руки видно, рот на замок.`;
  if (s.malyava === 'gone') return `Подъём. День ${s.day}. Щель пустая. Бумагу взяли без тебя.`;
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
