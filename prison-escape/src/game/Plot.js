/**
 * Week in хата 4. Not an escape. Choices stick until Tuesday's player comes back.
 */
import {
  NIGHT1,
  DAY2_NIGHT,
  DAY2_NIGHT_CAUGHT,
  DAY2_NIGHT_WASH,
  DAY2_YARD,
  DAY2_YARD_CAUGHT,
  DAY2_YARD_WASH,
  DAY2_WALK_BURN,
  DAY2_WALK_GONE,
  DAY2_WALK_HOLD,
  DAY2_WALK_HOLD_WASH,
  DAY2_WALK_HOLD_BUNK,
  DAY2_WALK_FOUND,
  DAY2_WALK_FOUND_BUNK,
  DAY1_WALK_RED,
  DAY1_WALK_BURN,
  DAY1_WALK_GONE,
  DAY1_WALK,
  DAY1_WALK_HOLD,
  DAY1_WALK_HOLD_WASH,
  DAY1_WALK_HOLD_BUNK,
  DAY1_WALK_FOUND,
  DAY1_WALK_FOUND_BUNK,
  DAY2_WALK_RED,
  DAY2_FOOD,
  DAY2_FOOD_CAUGHT,
  DAY2_FOOD_WASH,
  DAY2_SHMON,
  DAY2_SHMON_CAUGHT,
  DAY2_SHMON_WASH,
  DAY2_WAKE,
  DAY2_WAKE_BUNK,
  DAY2_WAKE_WASH,
  DAY3_NIGHT,
  DAY3_NIGHT_WAIT,
  DAY3_NIGHT_FOUND,
  DAY3_NIGHT_FOUND_BUNK,
  DAY3_NIGHT_HOLD,
  DAY3_NIGHT_HOLD_WASH,
  DAY3_NIGHT_HOLD_BUNK,
  DAY3_NIGHT_BURN,
  DAY3_NIGHT_RED,
  DAY3_MORNING,
  DAY3_MORNING_RED,
  DAY3_MORNING_CAUGHT,
  DAY3_MORNING_HOLD,
  DAY3_MORNING_HOLD_WASH,
  DAY3_MORNING_HOLD_BUNK,
  DAY3_MORNING_BURN,
  DAY3_MORNING_FOUND,
  DAY3_MORNING_FOUND_BUNK,
  DAY3_FOOD,
  DAY3_FOOD_HOLD,
  DAY3_FOOD_HOLD_WASH,
  DAY3_FOOD_HOLD_BUNK,
  DAY3_FOOD_BURN,
  DAY3_FOOD_RED,
  DAY3_FOOD_FOUND,
  DAY3_FOOD_FOUND_BUNK,
  DAY3_WALK,
  DAY3_WALK_WAIT,
  DAY3_WALK_HOLD,
  DAY3_WALK_HOLD_WASH,
  DAY3_WALK_HOLD_BUNK,
  DAY3_WALK_RED,
  DAY3_WALK_BURN,
  DAY3_WALK_FOUND,
  DAY3_WALK_FOUND_BUNK,
  DAY3_SHMON_FOUND,
  DAY3_SHMON_FOUND_BUNK,
  DAY3_SHMON_HOLD,
  DAY3_SHMON_HOLD_BUNK,
  DAY3_SHMON_WASH,
  DAY3_SHMON_HATCH,
  DAY3_SHMON_BURN,
  DAY3_SHMON_RED,
  DAY4_SHMON_WAIT,
  DAY4_SHMON_WASH,
  DAY4_SHMON_HOLD,
  DAY4_SHMON_HOLD_BUNK,
  DAY4_SHMON_FOUND,
  DAY4_SHMON_FOUND_BUNK,
  DAY4_SHMON_BURN,
  DAY4_SHMON_RED,
  DAY5_SHMON,
  DAY5_SHMON_GONE,
  DAY5_SHMON_HOLD,
  DAY5_SHMON_HOLD_WASH,
  DAY5_SHMON_HOLD_BUNK,
  DAY5_SHMON_FOUND,
  DAY5_SHMON_FOUND_BUNK,
  DAY5_SHMON_BURN,
  DAY5_SHMON_RED,
  DAY6_SHMON,
  DAY6_SHMON_GONE,
  DAY6_SHMON_HOLD,
  DAY6_SHMON_HOLD_WASH,
  DAY6_SHMON_HOLD_BUNK,
  DAY6_SHMON_FOUND,
  DAY6_SHMON_FOUND_BUNK,
  DAY6_SHMON_BURN,
  DAY6_SHMON_RED,
  DAY7_SHMON,
  DAY7_SHMON_GONE,
  DAY7_SHMON_HOLD,
  DAY7_SHMON_HOLD_WASH,
  DAY7_SHMON_HOLD_BUNK,
  DAY7_SHMON_FOUND,
  DAY7_SHMON_FOUND_BUNK,
  DAY7_SHMON_BURN,
  DAY7_SHMON_RED,
  DAY4_LEHA,
  DAY4_NIGHT_WAIT,
  DAY4_LEHA_HOLD,
  DAY4_LEHA_HOLD_WASH,
  DAY4_LEHA_HOLD_BUNK,
  DAY4_LEHA_HOLD_BUNK_WAIT,
  DAY4_LEHA_FOUND,
  DAY4_LEHA_FOUND_BUNK,
  DAY4_LEHA_BURN,
  DAY4_LEHA_RED,
  DAY4_WALK,
  DAY4_WALK_WAIT,
  DAY4_WALK_PAID,
  DAY4_WALK_PAID_WASH,
  DAY4_WALK_PAID_BUNK,
  DAY4_WALK_HOLD_BUNK,
  DAY4_WALK_FOUND,
  DAY4_WALK_FOUND_BUNK,
  DAY4_WALK_BURN,
  DAY4_WALK_GONE,
  DAY4_WALK_RED,
  DAY4_FOOD,
  DAY4_FOOD_WAIT,
  DAY4_FOOD_HOLD,
  DAY4_FOOD_HOLD_WASH,
  DAY4_FOOD_HOLD_BUNK,
  DAY4_FOOD_FOUND,
  DAY4_FOOD_FOUND_BUNK,
  DAY4_FOOD_BURN,
  DAY4_FOOD_RED,
  DAY4_WAKE,
  DAY4_WAKE_BURN,
  DAY4_WAKE_RED,
  DAY4_WAKE_WAIT,
  DAY4_WAKE_FOUND,
  DAY4_WAKE_FOUND_BUNK,
  DAY4_WAKE_HOLD,
  DAY4_WAKE_HOLD_WASH,
  DAY4_WAKE_HOLD_BUNK,
  DAY4_WAKE_HOLD_BUNK_WAIT,
  FOUND_NIGHT,
  DAY5_COURT,
  DAY5_COURT_GONE,
  DAY5_NIGHT_MISS,
  DAY5_NIGHT_GONE,
  DAY5_SEDOY_NIGHT_HOLD_BUNK,
  DAY5_SEDOY_NIGHT_FOUND,
  DAY5_SEDOY_NIGHT_FOUND_BUNK,
  DAY5_WAKE,
  DAY5_WAKE_GONE,
  DAY5_WAKE_FOUND,
  DAY5_WAKE_FOUND_BUNK,
  DAY5_WAKE_BURN,
  DAY5_WAKE_HOLD,
  DAY5_WAKE_HOLD_WASH,
  DAY5_WAKE_HOLD_BUNK,
  DAY5_WAKE_RED,
  DAY5_SLED,
  DAY5_SLED_GONE,
  DAY5_SLED_RED,
  DAY5_SLED_FOUND,
  DAY5_SLED_FOUND_BUNK,
  DAY5_SLED_BURN,
  DAY5_SLED_HOLD,
  DAY5_SLED_HOLD_WASH,
  DAY5_SLED_HOLD_BUNK,
  DAY5_BACK_SILENT,
  DAY5_BACK_CELL,
  DAY5_BACK_SELF,
  DAY5_WALK,
  DAY5_WALK_GONE,
  DAY5_WALK_HOLD,
  DAY5_WALK_HOLD_WASH,
  DAY5_WALK_HOLD_BUNK,
  DAY5_WALK_FOUND,
  DAY5_WALK_FOUND_BUNK,
  DAY5_WALK_BURN,
  DAY5_WALK_RED,
  DAY6_NIGHT,
  DAY6_NIGHT_GONE,
  DAY6_NIGHT_RED,
  DAY6_NIGHT_FOUND,
  DAY6_NIGHT_FOUND_BUNK,
  DAY6_NIGHT_BURN,
  DAY6_NIGHT_HOLD,
  DAY6_NIGHT_HOLD_WASH,
  DAY6_NIGHT_HOLD_BUNK,
  DAY6_FOOD,
  DAY6_FOOD_GONE,
  DAY6_FOOD_RED,
  DAY6_FOOD_FOUND,
  DAY6_FOOD_FOUND_BUNK,
  DAY6_FOOD_BURN,
  DAY6_FOOD_HOLD,
  DAY6_FOOD_HOLD_WASH,
  DAY6_FOOD_HOLD_BUNK,
  DAY6_WALK,
  DAY6_WALK_GONE,
  DAY6_WALK_RED,
  DAY6_WALK_FOUND,
  DAY6_WALK_FOUND_BUNK,
  DAY6_WALK_BURN,
  DAY6_WALK_HOLD,
  DAY6_WALK_HOLD_WASH,
  DAY6_WALK_HOLD_BUNK,
  DAY7_WALK,
  DAY7_WALK_GONE,
  DAY7_WALK_RED,
  DAY7_WALK_FOUND,
  DAY7_WALK_FOUND_BUNK,
  DAY7_WALK_BURN,
  DAY7_WALK_HOLD,
  DAY7_WALK_HOLD_WASH,
  DAY7_WALK_HOLD_BUNK,
  DAY7_WAKE,
  DAY7_WAKE_GONE,
  DAY7_WAKE_RED,
  DAY7_WAKE_FOUND,
  DAY7_WAKE_FOUND_BUNK,
  DAY7_WAKE_BURN,
  DAY7_WAKE_HOLD,
  DAY7_WAKE_HOLD_WASH,
  DAY7_WAKE_HOLD_BUNK,
  WEEK_HELD,
  WEEK_HELD_GONE,
  WEEK_HELD_RED,
  WEEK_HELD_FOUND,
  WEEK_HELD_FOUND_BUNK,
  WEEK_HELD_BURN,
  WEEK_HELD_HOLD,
  WEEK_HELD_HOLD_WASH,
  WEEK_HELD_HOLD_BUNK,
  DAY7_SEDOY_NIGHT_HOLD_BUNK,
  DAY7_SEDOY_NIGHT_FOUND_BUNK,
  DAY7_SEDOY_FOOD_HOLD_BUNK,
  DAY7_SEDOY_FOOD_FOUND_BUNK,
  HOLD_NIGHT,
  BURN_NIGHT,
  SNITCH_NIGHT,
} from './Dialogue.js';

export function plotObjective(sim) {
  if (sim.stage !== 'life' || !sim.propiska) return null;
  const d = sim.day;
  const ph = sim.phase.id;
  if (d === 1 && ph === 'evening') return 'Отбой. Лёха шепчет про шмон. Своя койка, не чужая.';
  if (d === 1 && ph === 'walk')
    return weekRed(sim)
      ? 'Первый круг. Свист кончился в щели. Через стену — ни звука.'
      : sim.malyava === 'burn'
        ? 'Первый круг. Зола в хате. Про дым — ни звука.'
        : sim.malyava === 'gone'
          ? 'Первый круг. Бумагу взяли без тебя. Через стену не ори.'
          : sim.malyava === 'hold'
            ? sim.stash === 'bunk'
              ? 'Первый круг. Бумага в матрасе. Через стену не ори.'
              : sim.stash === 'wash'
                ? 'Первый круг. Чаша в хате. Через стену не ори.'
                : 'Первый круг. Карман жжёт. Через стену не ори.'
          : sim.malyava === 'found'
            ? sim.stash === 'bunk'
              ? 'Первый круг. Нашли в матрасе. Через стену не ори.'
              : 'Первый круг. Нашли в кармане. Через стену не ори.'
        : 'Первый круг. Конвой вывел. Назад сам не пойдёшь — заведут.';
  if (d === 2 && ph === 'wake')
    return sim.stash === 'bunk'
      ? 'Второй подъём. Нычка в матрасе. Шмон будет до пайки. К стене.'
      : sim.stash === 'wash'
        ? 'Второй подъём. Чаша, не матрас. Не смотри на неё. Руки пустые.'
        : 'Второй подъём. Шмон до пайки. Чаша, не матрас.';
  if (d === 2 && ph === 'shmon') {
    return sim.stash === 'bunk'
      ? 'Второй шмон. Нашли в матрасе. Койка в воздухе. Стой. Руки видно.'
      : sim.stash === 'wash'
        ? 'Второй шмон. Матрас чистый. Чашу не трогают. Не смотри на неё.'
        : 'Второй шмон. К стенам. Руки видно. Нычку в матрасе не клади.';
  }
  if (d === 2 && ph === 'food')
    return sim.stash === 'bunk'
      ? 'Пайка после шмона. Нашли в матрасе. Ешь не первым. Про нычку — ни звука.'
      : sim.stash === 'wash'
        ? 'Пайка. Матрас чистый. Чашу за столом не вспоминай.'
        : 'Баланда. Очередь. В сортир, пока едят, не ходи.';
  if (d === 2 && ph === 'walk')
    return weekRed(sim)
      ? 'Второй круг. Свист кончился в щели. Через стену — ни звука.'
      : sim.malyava === 'burn'
        ? 'Второй круг. Зола в хате. Про дым — ни звука.'
        : sim.malyava === 'gone'
          ? 'Второй круг. Бумагу взяли без тебя. Через стену не ори.'
          : sim.malyava === 'hold'
            ? sim.stash === 'bunk'
              ? 'Второй круг. Бумага в матрасе. Через стену не ори.'
              : sim.stash === 'wash'
                ? 'Второй круг. Чаша в хате. Через стену не ори.'
                : 'Второй круг. Карман жжёт. Через стену не ори.'
          : sim.malyava === 'found'
            ? sim.stash === 'bunk'
              ? 'Второй круг. Нашли в матрасе. Через стену не ори.'
              : 'Второй круг. Нашли в кармане. Через стену не ори.'
        : sim.stash === 'bunk'
        ? 'Второй круг. Нашли в матрасе. Через стену не ори.'
        : sim.stash === 'wash'
          ? 'Второй круг. Матрас чистый. Через стену не рассказывай про чашу.'
          : 'Второй круг. Этапом шепчут Херсон. Через стену не ори.';
  if (d === 2 && ph === 'evening')
    return sim.stash === 'bunk'
      ? 'Отбой. Нашли в матрасе. Не объясняйся. Оправдания — вторая нычка.'
      : sim.stash === 'wash'
        ? 'Отбой. Чаша сегодня не их дело. Завтра щель стукнет два коротких. Не зевай.'
        : 'Отбой. Завтра щель стукнет два коротких. Не зевай.';
  if (d === 3 && ph === 'wake')
    return sim.path === 'red' || sim.malyava === 'admin'
      ? 'Третий подъём. Вчера слово село. Кормушка днём живая. Не зевай.'
      : sim.malyava === 'found'
        ? sim.stash === 'bunk'
          ? 'Третий подъём. Вчера нашли в матрасе. Молчи. Оправдания — вторая малява.'
          : 'Третий подъём. Вчера нашли в кармане. Молчи. Оправдания — вторая малява.'
        : sim.malyava === 'hold'
          ? sim.stash === 'bunk'
            ? 'Третий подъём. Бумага в матрасе. Шмон до пайки. Первое место.'
            : sim.stash === 'wash'
              ? 'Третий подъём. Чаша, не карман. Шмон до пайки. Не смотри на неё.'
              : 'Третий подъём. Карман жжёт. Шмон до пайки. Чаша, не матрас.'
          : sim.malyava === 'burn'
            ? 'Третий подъём. Зола на столе. Два коротких тебе уже не нужны.'
            : sim.stash === 'bunk'
              ? 'Третий подъём. Вчера матрас пел. Щель уже тихая. Два коротких — после пайки. Не зевай.'
              : 'Третий подъём. Щель уже тихая. Два коротких — после пайки. Не зевай.';
  if (d === 3 && ph === 'shmon') {
    if (sim.malyava === 'found')
      return sim.stash === 'bunk'
        ? 'Третий шмон. Нашли в матрасе. К стене. Руки видно. Рот на замок.'
        : 'Третий шмон. Нашли в кармане. К стене. Руки видно. Рот на замок.';
    if (sim.malyava === 'admin' || sim.path === 'red') return 'Третий шмон. Вчера слово село. К стене. Не оправдывайся.';
    if (sim.malyava === 'hold')
      return holdStash(sim, {
        pocket: 'Третий шмон. Карман жжёт. Руки пустые.',
        wash: 'Третий шмон. Чаша сегодня не их дело. Не смотри на неё.',
        bunk: 'Третий шмон. Матрас первым. Не смотри на койку. Руки видно.',
      });
    if (sim.malyava === 'burn') return 'Третий шмон. Пахнет золой. К стене. Нос казённый.';
    if (!sim.malyava) return 'Третий шмон. Щель ещё живая. Койки шарят. Кормушку — пока нет.';
    return 'Третий шмон. К стенам. Руки видно. Карман не шарь сам.';
  }
  if (d === 3 && ph === 'food' && !sim.malyava)
    return 'Третья пайка. Два коротких в щель — бумага, не ложка. Не зевай.';
  if (d === 3 && ph === 'food' && sim.malyava === 'hold')
    return sim.stash === 'bunk'
      ? 'Третья пайка. Бумага в матрасе. Ешь. Койку за столом не вспоминай.'
      : sim.stash === 'wash'
        ? 'Третья пайка. Чаша, не карман. Ешь. Не смотри на неё.'
        : 'Третья пайка. Карман жжёт. Ешь. Не читай вслух.';
  if (d === 3 && ph === 'food' && sim.malyava === 'burn')
    return 'Третья пайка пахнет золой. Ешь. Не свисти.';
  if (d === 3 && ph === 'food' && sim.malyava === 'found')
    return sim.stash === 'bunk'
      ? 'Третья пайка. Нашли в матрасе. Жар ест вместе с баландой. Рот на замок.'
      : 'Третья пайка. Нашли в кармане. Жар ест вместе с баландой. Рот на замок.';
  if (d === 3 && ph === 'food' && sim.malyava === 'admin')
    return 'Третья пайка лишняя. Красному ложку дают последним.';
  if (d === 3 && ph === 'evening' && !sim.malyava)
    return 'Отбой. Бумага ещё в щели. Завтра либо твоя, либо кума.';
  if (d === 3 && ph === 'evening' && sim.malyava === 'found')
    return sim.stash === 'bunk'
      ? 'Третий отбой. Нашли в матрасе днём. Молчи. Оправдания — вторая малява.'
      : 'Третий отбой. Нашли в кармане днём. Молчи. Оправдания — вторая малява.';
  if (d === 3 && ph === 'evening' && (sim.malyava === 'admin' || sim.path === 'red'))
    return 'Третий отбой. Чайник не щёлкнул. Слово село. Не оправдывайся.';
  if (d === 3 && ph === 'evening' && sim.malyava === 'hold')
    return sim.stash === 'bunk'
      ? 'Третий отбой. Бумага в матрасе. Завтра шмон. Чаша, или жги.'
      : sim.stash === 'wash'
        ? 'Третий отбой. Чаша знает. Не шарь при лампе. Или жги.'
        : 'Третий отбой. Карман жжёт. Чаша, не матрас. Или жги.';
  if (d === 3 && ph === 'evening' && sim.malyava === 'burn')
    return 'Третий отбой. Дым ещё в хате. Не свисти в полный голос.';
  if (d === 3 && ph === 'walk') {
    if (sim.malyava === 'admin') return 'Третий круг без свиста. Хата уже считает.';
    if (sim.malyava === 'hold')
      return sim.stash === 'bunk'
        ? 'Третий круг. Бумага в матрасе. Через стену — ни звука.'
        : sim.stash === 'wash'
          ? 'Третий круг. Чаша осталась в хате. Через стену не ори про неё.'
          : 'Карман жжёт даже на круге. Через стену — ни звука.';
    if (sim.malyava === 'burn') return 'Третий круг. Зола осталась в хате. Не ори про дым.';
    if (sim.malyava === 'found')
      return sim.stash === 'bunk'
        ? 'Третий круг. Нашли в матрасе. Через стену не ори про шмон.'
        : 'Третий круг. Нашли в кармане. Через стену не ори про шмон.';
    if (!sim.malyava) return 'Третий круг. Бумага ещё в щели. К щели — после. Через стену не ори.';
    return 'Третий круг. Щель днём стучала. Бумага либо твоя, либо чужая.';
  }
  if (d === 4 && ph === 'shmon')
    return weekRed(sim)
      ? 'Четвёртый шмон. Тебя записали. К стене. Не оправдывайся.'
      : sim.malyava === 'found'
        ? sim.stash === 'bunk'
          ? 'Четвёртый шмон. Нашли в матрасе. К стене. Рот на замок.'
          : 'Четвёртый шмон. Нашли в кармане. К стене. Рот на замок.'
        : sim.malyava === 'burn'
          ? 'Четвёртый шмон. Пахнет золой. К стене. Не объясняй чайник.'
          : sim.malyava === 'hold'
            ? holdStash(sim, {
                pocket: 'Четвёртый шмон. Карман жжёт. Руки пустые.',
                wash: 'Четвёртый шмон. Чашу не смотри. Бумага там вторые сутки.',
                bunk: 'Четвёртый шмон. Матрас первым. Не смотри на койку.',
              })
            : !sim.malyava
              ? 'Четвёртый шмон. Щель живая. Койки, не кормушку.'
              : 'Четвёртый шмон. К стенам. Руки видно.';
  if (d === 4 && ph === 'walk')
    return weekRed(sim)
      ? 'Четвёртый круг. Свист кончился. Через сетку — ни звука.'
      : !sim.malyava
        ? 'Четвёртый круг. Бумага в щели. Не зевай вечером.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Четвёртый круг. Нашли в матрасе. Через стену не ори про шмон.'
            : 'Четвёртый круг. Нашли в кармане. Через стену не ори про шмон.'
          : sim.malyava === 'burn'
            ? 'Четвёртый круг. Зола в хате. Про дым — ни звука.'
            : sim.malyava === 'gone'
              ? 'Четвёртый круг. Бумагу взяли без тебя. Через стену не ори.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? holdStash(sim, {
                  pocket: 'Четвёртый круг. Чай ушёл. Карман жжёт. Через стену — ни звука.',
                  wash: 'Четвёртый круг. Чай ушёл. Чаша осталась в хате. Через стену не ори про неё.',
                  bunk: 'Четвёртый круг. Чай ушёл. Бумага в матрасе. Через стену — ни звука.',
                })
              : sim.malyava === 'hold' && sim.stash === 'bunk'
                ? 'Четвёртый круг. Бумага в матрасе. Чай ещё в щели. Через стену — ни звука.'
              : 'Дворик. Долг чая сидит в щели, не гуляет с тобой.';
  if (d === 4 && ph === 'food')
    return weekRed(sim)
      ? 'Четвёртая пайка. Ложка последняя. Чайник молчит. Ешь после хаты.'
      : !sim.malyava
        ? 'Четвёртая пайка. Щель живая. Ешь. Потом бери. Не зевай.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Четвёртая пайка. Нашли в матрасе. Жар ест вместе с баландой. Рот на замок.'
            : 'Четвёртая пайка. Нашли в кармане. Жар ест вместе с баландой. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Четвёртая пайка. Пахнет золой. Про дым — ни слова.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? holdStash(sim, {
                  pocket: 'Четвёртая пайка. Чай ушёл. Карман жжёт. За столом не читай.',
                  wash: 'Четвёртая пайка. Чай ушёл. Чаша, не карман. За столом не вспоминай.',
                  bunk: 'Четвёртая пайка. Чай ушёл. Бумага в матрасе. Койку за столом не вспоминай.',
                })
              : 'Четвёртая пайка. Кто не отдаёт чай в щель — пустое место.';
  if (d === 4 && ph === 'evening')
    return weekRed(sim)
      ? 'Четвёртый отбой. Чайник молчит. Хата не здоровается.'
      : !sim.malyava
        ? 'Четвёртый отбой. Бумага в щели уже двое суток. Не зевай.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Четвёртый отбой. Нашли в матрасе. Жар не сняли. Молчи.'
            : 'Четвёртый отбой. Нашли в кармане. Жар не сняли. Молчи.'
          : sim.malyava === 'burn'
            ? 'Четвёртый отбой. Зола ещё пахнет. Не свисти в полный голос.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? holdStash(sim, {
                  pocket: 'Четвёртый отбой. Чай ушёл. Карман жжёт. Не читай при лампе.',
                  wash: 'Четвёртый отбой. Чай ушёл. Чаша знает. Не шарь при лампе.',
                  bunk: 'Четвёртый отбой. Чай ушёл. Бумага в матрасе. Чаша, или жги.',
                })
              : sim.malyava === 'hold' && sim.stash === 'bunk'
                ? 'Четвёртый отбой. Бумага в матрасе. Чай ещё в щели. Чаша, или жги.'
              : 'Чай, что через кормушку ушёл, ждут обратно.';
  if (d === 4 && ph === 'wake')
    return weekRed(sim)
      ? 'Четвёртый подъём. Чайник молчит. Пайка лишняя.'
      : !sim.malyava
        ? 'Четвёртый подъём. Бумага вчера не ушла. Щель всё ещё живая.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Четвёртый подъём. Нашли в матрасе. Жар не сняли за ночь. Рот на замок.'
            : 'Четвёртый подъём. Нашли в кармане. Жар не сняли за ночь. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Четвёртый подъём. Зола ещё пахнет. Не свисти в полный голос.'
            : sim.malyava === 'hold' && sim.teaPaid
              ? holdStash(sim, {
                  pocket: 'Четвёртый подъём. Чай ушёл. Карман жжёт. Не шарь при лампе.',
                  wash: 'Четвёртый подъём. Чай ушёл. Чаша, не карман. Не шарь при лампе.',
                  bunk: 'Четвёртый подъём. Чай ушёл. Бумага в матрасе. Шмон это любит.',
                })
              : sim.malyava === 'hold' && sim.stash === 'bunk'
                ? 'Четвёртый подъём. Бумага в матрасе. Чай ещё в щели. Шмон это любит.'
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
          ? sim.stash === 'bunk'
            ? 'Шестая пайка. Нашли в матрасе. Ложка после смотрящего. Рот на замок.'
            : 'Шестая пайка. Нашли в кармане. Ложка после смотрящего. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Шестая пайка. Пахнет золой. Ложка после смотрящего. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Шестая пайка. Карман жжёт. Ложка после смотрящего. Бумагу за столом не читай.',
                  wash: 'Шестая пайка. Чаша, не карман. Ложка после смотрящего. Чашу за столом не вспоминай.',
                  bunk: 'Шестая пайка. Бумага в матрасе. Ложка после смотрящего. Койку за столом не вспоминай.',
                })
              : 'Шестая пайка. Ложка после смотрящего. Завтра свежак кончается.';
  if (d === 6 && ph === 'shmon')
    return weekRed(sim)
      ? 'Шестой шмон. Свежак кончается красным. К стене. Не оправдывайся.'
      : sim.malyava === 'gone'
        ? 'Шестой шмон. Щель пустая с пятого. Папка уже не пустая. К стене.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Шестой шмон. Нашли в матрасе. Свежак кончается. Рот на замок.'
            : 'Шестой шмон. Нашли в кармане. Свежак кончается. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Шестой шмон. Пахнет золой. Свежак кончается. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Шестой шмон. Карман жжёт. Свежак кончается. Руки пустые.',
                  wash: 'Шестой шмон. Чашу не смотри. Свежак кончается. Руки пустые.',
                  bunk: 'Шестой шмон. Матрас первым. Свежак кончается. Не смотри на койку.',
                })
              : 'Шестой шмон. Свежак кончается. Койки для порядка. К стене.';
  if (d === 6 && ph === 'walk')
    return weekRed(sim)
      ? 'Шестой круг. Свист кончился в щели. Через стену — ни звука.'
      : sim.malyava === 'gone'
        ? 'Шестой круг. Бумагу взяли без тебя. Завтра не ори про волю.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Шестой круг. Нашли в матрасе. Через стену не ори про шмон.'
            : 'Шестой круг. Нашли в кармане. Через стену не ори про шмон.'
          : sim.malyava === 'burn'
            ? 'Шестой круг. Зола в хате. Не ори про дым.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Шестой круг. Карман жжёт даже на бетоне. Через стену — ни звука.',
                  wash: 'Шестой круг. Чаша осталась в хате. Через стену про неё — ни звука.',
                  bunk: 'Шестой круг. Бумага в матрасе. Через стену про койку — ни звука.',
                })
              : 'Шестой круг. Завтра не ори про волю.';
  if (d === 5 && ph === 'wake')
    return weekRed(sim)
      ? 'Пятый подъём. Чайник молчит. Список всё равно дойдёт.'
      : sim.malyava === 'gone'
        ? 'Щель пустая. Бумагу взяли без тебя. Днём щель станет кабинетом.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Пятый подъём. Нашли в матрасе. Жар не сняли. Днём щель станет кабинетом.'
            : 'Пятый подъём. Нашли в кармане. Жар не сняли. Днём щель станет кабинетом.'
          : sim.malyava === 'burn'
            ? 'Пятый подъём. Зола ещё пахнет. Днём щель станет кабинетом.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Пятый подъём. Карман жжёт. Днём щель станет кабинетом. Не шарь.',
                  wash: 'Пятый подъём. Чаша, не карман. Днём щель станет кабинетом. Не смотри на неё.',
                  bunk: 'Пятый подъём. Бумага в матрасе. Днём щель станет кабинетом. Первое место.',
                })
              : 'С коряка шепчут список. Днём щель станет кабинетом.';
  if (d === 5 && ph === 'shmon')
    return weekRed(sim)
      ? 'Пятый шмон. Тебя записали. Сегодня вызов. К стене. Не оправдывайся.'
      : sim.malyava === 'gone'
        ? 'Пятый шмон. Щель пустая с утра. Следак уже забрал бумагу. К стене.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Пятый шмон. Нашли в матрасе. Сегодня вызов. Рот на замок.'
            : 'Пятый шмон. Нашли в кармане. Сегодня вызов. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Пятый шмон. Пахнет золой. Сегодня вызов. Не объясняй чайник.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Пятый шмон. Карман жжёт. Сегодня вызов. Руки пустые.',
                  wash: 'Пятый шмон. Чашу не смотри. Сегодня вызов. Руки пустые.',
                  bunk: 'Пятый шмон. Матрас первым. Сегодня вызов. Не смотри на койку.',
                })
              : 'Пятый шмон. Сегодня вызов. Койки для порядка. К стене.';
  if (d === 5 && ph === 'food' && !sim.courtTalk)
    return weekRed(sim)
      ? 'Вызов. Имена уже в щели. Следователь просит ещё.'
      : sim.malyava === 'gone'
        ? 'Вызов. Бумага уже в папке. Следователь знает щель. Про хату — или про срок.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Вызов. Нашли в матрасе. Теперь имена. Про хату — или про срок.'
            : 'Вызов. Карман нашли. Теперь имена. Про хату — или про срок.'
          : sim.malyava === 'burn'
            ? 'Вызов. Нос казённый. Про дым — или про хату.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Вызов. Карман шуршит. Следователь слышит. Про хату — или про срок.',
                  wash: 'Вызов. Чаша в хате. Следователь слышит. Про хату — или про срок.',
                  bunk: 'Вызов. Бумага в матрасе. Следователь слышит. Про хату — или про срок.',
                })
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
          ? sim.stash === 'bunk'
            ? 'Пятый круг. Нашли в матрасе. Через сетку не ори про шмон.'
            : 'Пятый круг. Нашли в кармане. Через сетку не ори про шмон.'
          : sim.malyava === 'burn'
            ? 'Пятый круг. Зола в хате. Про дым — ни звука.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Пятый круг. Карман жжёт. Через сетку про карман — ни звука.',
                  wash: 'Пятый круг. Чаша осталась в хате. Через сетку про неё — ни звука.',
                  bunk: 'Пятый круг. Бумага в матрасе. Через сетку про койку — ни звука.',
                })
              : 'Пятый круг. С коряка звали. Что скажешь — хата узнает.';
  if (d === 5 && ph === 'evening')
    return weekRed(sim)
      ? 'Пятый отбой. Имена в щели. Чайник молчит. Койку не занимай.'
      : sim.malyava === 'gone'
        ? 'Пятый отбой. Щель отдала бумагу без тебя. Своя койка.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Пятый отбой. Нашли в матрасе. Щель уже была кабинетом. Койку не вспоминай.'
            : 'Пятый отбой. Нашли в кармане. Щель уже была кабинетом. Не оправдывайся.'
          : sim.malyava === 'burn'
            ? 'Пятый отбой. Зола. Щель уже была кабинетом. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Пятый отбой. Карман жжёт. Щель уже была кабинетом. Не читай при лампе.',
                  wash: 'Пятый отбой. Чаша знает. Щель уже была кабинетом. Не шарь при лампе.',
                  bunk: 'Пятый отбой. Бумага в матрасе. Щель уже была кабинетом. Койку не вспоминай.',
                })
              : 'Пятый отбой. Щель уже была кабинетом. Своя койка.';
  if (d === 5 && sim.malyava === 'gone') return 'Щель отдала бумагу без тебя. Следователь уже читал.';
  if (d === 5) return 'Следователь на свежака. Хата спрашивает, что скажешь про них.';
  if (d === 6 && ph === 'wake')
    return weekRed(sim)
      ? 'Шестой подъём. Имена в щели. Свежак кончается красным.'
      : sim.malyava === 'gone'
        ? 'Шестой подъём. Щель пустая с пятого. Свежак кончается.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Шестой подъём. Нашли в матрасе. Свежак кончается. Не оправдывайся.'
            : 'Шестой подъём. Нашли в кармане. Свежак кончается. Не оправдывайся.'
          : sim.malyava === 'burn'
            ? 'Шестой подъём. Зола. Свежак кончается. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Шестой подъём. Карман жжёт. Свежак кончается. Не шарь при лампе.',
                  wash: 'Шестой подъём. Чаша знает. Свежак кончается. Не смотри на неё.',
                  bunk: 'Шестой подъём. Бумага в матрасе. Свежак кончается. Койку не смотри.',
                })
              : 'Шестой подъём. Свежак кончается. Не ори про волю.';
  if (d === 6 && ph === 'evening')
    return weekRed(sim)
      ? 'Шестой отбой. Имена в щели. Свежак кончается красным.'
      : sim.malyava === 'gone'
        ? 'Шестой отбой. Щель пустая с пятого. Свежак кончается. Не ори про волю.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Шестой отбой. Нашли в матрасе. Свежак кончается. Не оправдывайся.'
            : 'Шестой отбой. Нашли в кармане. Свежак кончается. Не оправдывайся.'
          : sim.malyava === 'burn'
            ? 'Шестой отбой. Зола. Свежак кончается. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Шестой отбой. Карман жжёт. Свежак кончается. Неси или жги.',
                  wash: 'Шестой отбой. Чаша знает. Свежак кончается. Неси или жги.',
                  bunk: 'Шестой отбой. Бумага в матрасе. Свежак кончается. Чаша, или жги.',
                })
              : 'Шестой отбой. Свежак кончается. Не ори про волю.';
  if (d === 6)
    return weekRed(sim)
      ? 'Шестой день. Имена в щели. Свежак кончается красным.'
      : sim.malyava === 'gone'
        ? 'Шестой день. Щель пустая с пятого. Свежак кончается. Не ори про волю.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Шестой день. Нашли в матрасе. Свежак кончается. Не оправдывайся.'
            : 'Шестой день. Нашли в кармане. Свежак кончается. Не оправдывайся.'
          : sim.malyava === 'burn'
            ? 'Шестой день. Зола. Свежак кончается. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Шестой день. Карман жжёт. Свежак кончается. Неси или жги.',
                  wash: 'Шестой день. Чаша знает. Свежак кончается. Неси или жги.',
                  bunk: 'Шестой день. Бумага в матрасе. Свежак кончается. Чаша, или жги.',
                })
              : 'Шестой день. Свежак кончается. Не ори про волю.';
  if (d === 7 && ph === 'shmon')
    return weekRed(sim)
      ? 'Седьмой шмон. Свежак кончился красным. К стене. Не оправдывайся.'
      : sim.malyava === 'gone'
        ? 'Седьмой шмон. Щель пустая с пятого. Бумагу взяли без тебя. К стене.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Седьмой шмон. Нашли в матрасе. Свежак кончился. Рот на замок.'
            : 'Седьмой шмон. Нашли в кармане. Свежак кончился. Рот на замок.'
          : sim.malyava === 'burn'
            ? 'Седьмой шмон. Пахнет золой. Свежак кончился. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Седьмой шмон. Карман жжёт. Свежак кончился. Руки пустые.',
                  wash: 'Седьмой шмон. Чашу не смотри. Свежак кончился. Руки пустые.',
                  bunk: 'Седьмой шмон. Матрас первым. Свежак кончился. Не смотри на койку.',
                })
              : 'Седьмой шмон. Свежак кончился. Шарят как в первый. К стене.';
  if (d === 7 && ph === 'walk')
    return weekRed(sim)
      ? 'Седьмой круг. Свежак кончился красным. Сетка та же. Через стену — ни звука.'
      : sim.malyava === 'gone'
        ? 'Седьмой круг. Свежак кончился. Бумагу взяли без тебя. Не ори про волю.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Седьмой круг. Нашли в матрасе. Свежак кончился на карандаше. Через стену не ори.'
            : 'Седьмой круг. Нашли в кармане. Свежак кончился на карандаше. Через стену не ори.'
          : sim.malyava === 'burn'
            ? 'Седьмой круг. Зола в хате. Свежак кончился. Про дым — ни звука.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Седьмой круг. Свежак кончился. Карман жжёт даже на бетоне. Ни звука.',
                  wash: 'Седьмой круг. Свежак кончился. Чаша осталась в хате. Через стену про неё — ни звука.',
                  bunk: 'Седьмой круг. Свежак кончился. Бумага в матрасе. Через стену про койку — ни звука.',
                })
              : 'Седьмой круг. Свежак кончился. Сетка та же. Не ори про волю.';
  if (d === 7 && ph === 'evening')
    return weekRed(sim)
      ? 'Седьмой отбой. Свежак кончился красным. Молчи. Не рассказывай сон.'
      : sim.malyava === 'gone'
        ? 'Седьмой отбой. Бумагу взяли без тебя. Свежак кончился. Молчи.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Седьмой отбой. Нашли в матрасе. Не выселили. Свежак кончился на карандаше.'
            : 'Седьмой отбой. Нашли в кармане. Не выселили. Свежак кончился на карандаше.'
          : sim.malyava === 'burn'
            ? 'Седьмой отбой. Бумага зола. Свежак кончился. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Седьмой отбой. Свежак кончился. Карман нет. Неси или жги.',
                  wash: 'Седьмой отбой. Свежак кончился. Чаша знает. Неси или жги.',
                  bunk: 'Седьмой отбой. Свежак кончился. Бумага в матрасе. Чаша, или жги.',
                })
              : 'Седьмой отбой. Свежак кончился. Молчи. Не ори про волю.';
  if (d === 7 && ph === 'wake')
    return weekRed(sim)
      ? 'Седьмой подъём. Свежак кончился красным. Молчи. Ешь последним.'
      : sim.malyava === 'gone'
        ? 'Седьмой подъём. Бумагу взяли без тебя. Свежак кончился. Молчи.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Седьмой подъём. Нашли в матрасе. Свежак кончился. Койку не вспоминать.'
            : 'Седьмой подъём. Нашли в кармане. Свежак кончился. Карман не вспоминать.'
          : sim.malyava === 'burn'
            ? 'Седьмой подъём. Пахнет золой. Свежак кончился. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Седьмой подъём. Свежак кончился. Карман нет. Неси или жги.',
                  wash: 'Седьмой подъём. Свежак кончился. Чаша знает. Неси или жги.',
                  bunk: 'Седьмой подъём. Свежак кончился. Бумага в матрасе. Шмон первым трогает койку.',
                })
              : 'Седьмой подъём. Свежак кончился. Молчи. Ешь. Неси, если несут.';
  if (d === 7 && ph === 'food')
    return weekRed(sim)
      ? 'Седьмая пайка. Свежак кончился красным. Ложка последняя. Молчи.'
      : sim.malyava === 'gone'
        ? 'Седьмая пайка. Бумагу взяли без тебя. Свежак кончился. Молчи. Ешь.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Седьмая пайка. Нашли в матрасе. Не выселили. Койку за столом не вспоминай.'
            : 'Седьмая пайка. Нашли в кармане. Не выселили. Карман за столом не вспоминай.'
          : sim.malyava === 'burn'
            ? 'Седьмая пайка. Пахнет золой. Свежак кончился. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Седьмая пайка. Свежак кончился. Карман жжёт даже у ложки.',
                  wash: 'Седьмая пайка. Свежак кончился. Чашу за столом не вспоминай.',
                  bunk: 'Седьмая пайка. Свежак кончился. Бумага в матрасе. Койку за столом не вспоминай.',
                })
              : 'Седьмая пайка. Свежак кончился. Хлеб общий. Ложка после смотрящего.';
  if (d === 7)
    return weekRed(sim)
      ? 'Неделя. Свежак кончился красным. Молчи. Ешь последним.'
      : sim.malyava === 'gone'
        ? 'Неделя. Бумагу взяли без тебя. Свежак кончился. Молчи. Ешь.'
        : sim.malyava === 'found'
          ? sim.stash === 'bunk'
            ? 'Неделя. Нашли в матрасе. Не выселили. Свежак кончился на карандаше.'
            : 'Неделя. Нашли в кармане. Не выселили. Свежак кончился на карандаше.'
          : sim.malyava === 'burn'
            ? 'Неделя. Бумага зола. Свежак кончился. Про дым — ни слова.'
            : sim.malyava === 'hold'
              ? holdStash(sim, {
                  pocket: 'Неделя. Свежак кончился. Карман нет. Неси или жги.',
                  wash: 'Неделя. Свежак кончился. Чаша знает. Неси или жги.',
                  bunk: 'Неделя. Свежак кончился. Бумага в матрасе. Чаша, или жги.',
                })
              : 'Неделя. Свежак кончился. Молчи. Ешь. Неси, если несут.';
  if (d >= 3 && !sim.malyava && (ph === 'food' || ph === 'wake' || ph === 'evening')) {
    return 'Кормушка стучит. Бумага: нести, жечь или к куму.';
  }
  if (d >= 3 && sim.malyava === 'hold')
    return holdStash(sim, {
      pocket: 'Малява жжёт карман. Несу, жгу или к куму — это уже сюжет, не квест.',
      wash: 'Малява в чаше. Несу, жгу или к куму — это уже сюжет, не квест.',
      bunk: 'Малява в матрасе. Несу, жгу или к куму — это уже сюжет, не квест.',
    });
  if (d >= 3 && sim.malyava === 'burn') return 'Бумага зола. Хата напротив тише, чем надо.';
  if (d >= 3 && sim.malyava === 'admin') return 'Хата молчит. Красный ход. Пайка не греет.';
  if (d >= 3 && sim.malyava === 'found')
    return sim.stash === 'bunk'
      ? 'Нашли в матрасе. Жар. Хата это уже знает.'
      : 'Нашли бумагу. Жар. Хата это уже знает.';
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
      pickDialog(g, weekPick(s, { red: DAY5_WALK_RED, gone: DAY5_WALK_GONE, found: s.stash === 'bunk' ? DAY5_WALK_FOUND_BUNK : DAY5_WALK_FOUND, burn: DAY5_WALK_BURN, hold: holdStash(s, { pocket: DAY5_WALK_HOLD, wash: DAY5_WALK_HOLD_WASH, bunk: DAY5_WALK_HOLD_BUNK }), ok: DAY5_WALK }));
    } else if (s.day === 6 && !s.heardDay6Yard) {
      s.heardDay6Yard = true;
      pickDialog(g, weekPick(s, { red: DAY6_WALK_RED, gone: DAY6_WALK_GONE, found: s.stash === 'bunk' ? DAY6_WALK_FOUND_BUNK : DAY6_WALK_FOUND, burn: DAY6_WALK_BURN, hold: holdStash(s, { pocket: DAY6_WALK_HOLD, wash: DAY6_WALK_HOLD_WASH, bunk: DAY6_WALK_HOLD_BUNK }), ok: DAY6_WALK }));
    } else if (s.day === 7 && !s.heardDay7Yard) {
      s.heardDay7Yard = true;
      pickDialog(g, weekPick(s, { red: DAY7_WALK_RED, gone: DAY7_WALK_GONE, found: s.stash === 'bunk' ? DAY7_WALK_FOUND_BUNK : DAY7_WALK_FOUND, burn: DAY7_WALK_BURN, hold: holdStash(s, { pocket: DAY7_WALK_HOLD, wash: DAY7_WALK_HOLD_WASH, bunk: DAY7_WALK_HOLD_BUNK }), ok: DAY7_WALK }));
    } else if (s.day >= 4 && !s.heardDay4Yard) {
      s.heardDay4Yard = true;
      pickDialog(g, day4Walk(s));
    } else if (s.day === 3 && !s.heardDay3Yard) {
      s.heardDay3Yard = true;
      pickDialog(g, day3Walk(s));
    } else if (s.day >= 2 && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, weekRed(s) ? DAY2_WALK_RED : s.malyava === 'burn' ? DAY2_WALK_BURN : s.malyava === 'gone' ? DAY2_WALK_GONE : s.malyava === 'hold' ? holdStash(s, { pocket: DAY2_WALK_HOLD, wash: DAY2_WALK_HOLD_WASH, bunk: DAY2_WALK_HOLD_BUNK }) : s.malyava === 'found' ? (s.stash === 'bunk' ? DAY2_WALK_FOUND_BUNK : DAY2_WALK_FOUND) : s.stash === 'bunk' ? DAY2_YARD_CAUGHT : s.stash === 'wash' ? DAY2_YARD_WASH : DAY2_YARD);
    } else if (s.day === 1 && weekRed(s) && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, DAY1_WALK_RED);
    } else if (s.day === 1 && s.malyava === 'burn' && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, DAY1_WALK_BURN);
    } else if (s.day === 1 && s.malyava === 'gone' && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, DAY1_WALK_GONE);
    } else if (s.day === 1 && s.malyava === 'hold' && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, holdStash(s, { pocket: DAY1_WALK_HOLD, wash: DAY1_WALK_HOLD_WASH, bunk: DAY1_WALK_HOLD_BUNK }));
    } else if (s.day === 1 && s.malyava === 'found' && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, s.stash === 'bunk' ? DAY1_WALK_FOUND_BUNK : DAY1_WALK_FOUND);
    } else if (s.day === 1 && !s.heardYard) {
      s.heardYard = true;
      pickDialog(g, DAY1_WALK);
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
      pickDialog(g, s.stash === 'bunk' ? DAY2_NIGHT_CAUGHT : s.stash === 'wash' ? DAY2_NIGHT_WASH : DAY2_NIGHT);
    } else if (s.day <= 3 && s.malyava === 'found' && !s.seenFoundNight) {
      s.seenFoundNight = true;
      if (s.day === 3) s.seenDay3 = true;
      pickDialog(g, s.day === 3 && s.stash === 'bunk' ? DAY3_NIGHT_FOUND_BUNK : s.day === 3 ? DAY3_NIGHT_FOUND : FOUND_NIGHT);
    } else if (s.day === 3 && !s.seenDay3) {
      s.seenDay3 = true;
      if (s.malyava === 'admin' || s.path === 'red') pickDialog(g, DAY3_NIGHT_RED);
      else if (s.malyava === 'hold')
        pickDialog(g, holdStash(s, { pocket: DAY3_NIGHT_HOLD, wash: DAY3_NIGHT_HOLD_WASH, bunk: DAY3_NIGHT_HOLD_BUNK }));
      else if (s.malyava === 'burn') pickDialog(g, DAY3_NIGHT_BURN);
      else pickDialog(g, s.malyava ? DAY3_NIGHT : DAY3_NIGHT_WAIT);
    } else if (s.day === 4 && !s.seenDay4) {
      s.seenDay4 = true;
      pickDialog(g, day4Evening(s));
    } else if (s.day === 5 && !s.seenDay5) {
      s.seenDay5 = true;
      pickDialog(g, day5Evening(s));
    } else if (s.day === 6 && !s.seenDay6) {
      s.seenDay6 = true;
      pickDialog(g, weekPick(s, { red: DAY6_NIGHT_RED, gone: DAY6_NIGHT_GONE, found: s.stash === 'bunk' ? DAY6_NIGHT_FOUND_BUNK : DAY6_NIGHT_FOUND, burn: DAY6_NIGHT_BURN, hold: holdStash(s, { pocket: DAY6_NIGHT_HOLD, wash: DAY6_NIGHT_HOLD_WASH, bunk: DAY6_NIGHT_HOLD_BUNK }), ok: DAY6_NIGHT }));
    } else if (s.day >= 7 && !s.seenWeek) {
      s.seenWeek = true;
      pickDialog(
        g,
        s.malyava === 'found' && s.stash === 'bunk'
          ? DAY7_SEDOY_NIGHT_FOUND_BUNK
          : s.malyava === 'hold' && s.stash === 'bunk'
            ? DAY7_SEDOY_NIGHT_HOLD_BUNK
            : weekPick(s, { red: WEEK_HELD_RED, gone: WEEK_HELD_GONE, found: s.stash === 'bunk' ? WEEK_HELD_FOUND_BUNK : WEEK_HELD_FOUND, burn: WEEK_HELD_BURN, hold: holdStash(s, { pocket: WEEK_HELD_HOLD, wash: WEEK_HELD_HOLD_WASH, bunk: WEEK_HELD_HOLD_BUNK }), ok: WEEK_HELD }),
      );
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
    if (s.malyava === 'hold' && s.stash !== 'wash' && s.day >= 8) {
      s.malyava = 'found';
      s.heat = Math.min(100, s.heat + 28);
      s.stress = Math.min(100, s.stress + 16);
      s.hope = Math.max(0, s.hope - 10);
      g.toast(
        s.stash === 'bunk'
          ? 'Нашли в матрасе. Койка пустая, жар полный.'
          : 'Нашли бумагу. Карман пустой, жар полный.',
      );
      if (s.day === 7 && !s.seenDay7Shmon) {
        s.seenDay7Shmon = true;
        pickDialog(g, s.stash === 'bunk' ? DAY7_SHMON_FOUND_BUNK : DAY7_SHMON_FOUND);
      } else if (s.day === 6 && !s.seenDay6Shmon) {
        s.seenDay6Shmon = true;
        pickDialog(g, s.stash === 'bunk' ? DAY6_SHMON_FOUND_BUNK : DAY6_SHMON_FOUND);
      } else if (s.day === 5 && !s.seenDay5Shmon) {
        s.seenDay5Shmon = true;
        pickDialog(g, s.stash === 'bunk' ? DAY5_SHMON_FOUND_BUNK : DAY5_SHMON_FOUND);
      } else if (s.day === 4 && !s.seenDay4Shmon) {
        s.seenDay4Shmon = true;
        pickDialog(g, s.stash === 'bunk' ? DAY4_SHMON_FOUND_BUNK : DAY4_SHMON_FOUND);
      } else if (!s.seenDay3Shmon) {
        s.seenDay3Shmon = true;
        pickDialog(g, s.stash === 'bunk' ? DAY3_SHMON_FOUND_BUNK : DAY3_SHMON_FOUND);
      } else {
        g.subtitle(
          s.stash === 'bunk'
            ? 'Кормушка: «Малява. Свежак нёс дорогу в матрасе.»'
            : 'Кормушка: «Малява. Свежак нёс дорогу в кармане.»',
        );
      }
      return;
    }
    if (s.day === 7 && !s.seenDay7Shmon) {
      s.seenDay7Shmon = true;
      pickDialog(g, weekPick(s, {
        red: DAY7_SHMON_RED,
        gone: DAY7_SHMON_GONE,
        found: s.stash === 'bunk' ? DAY7_SHMON_FOUND_BUNK : DAY7_SHMON_FOUND,
        burn: DAY7_SHMON_BURN,
        hold: holdStash(s, { pocket: DAY7_SHMON_HOLD, wash: DAY7_SHMON_HOLD_WASH, bunk: DAY7_SHMON_HOLD_BUNK }),
        ok: DAY7_SHMON,
      }));
      return;
    }
    if (s.day === 6 && !s.seenDay6Shmon) {
      s.seenDay6Shmon = true;
      pickDialog(g, weekPick(s, {
        red: DAY6_SHMON_RED,
        gone: DAY6_SHMON_GONE,
        found: s.stash === 'bunk' ? DAY6_SHMON_FOUND_BUNK : DAY6_SHMON_FOUND,
        burn: DAY6_SHMON_BURN,
        hold: holdStash(s, { pocket: DAY6_SHMON_HOLD, wash: DAY6_SHMON_HOLD_WASH, bunk: DAY6_SHMON_HOLD_BUNK }),
        ok: DAY6_SHMON,
      }));
      return;
    }
    if (s.day === 5 && !s.seenDay5Shmon) {
      s.seenDay5Shmon = true;
      pickDialog(g, weekPick(s, {
        red: DAY5_SHMON_RED,
        gone: DAY5_SHMON_GONE,
        found: s.stash === 'bunk' ? DAY5_SHMON_FOUND_BUNK : DAY5_SHMON_FOUND,
        burn: DAY5_SHMON_BURN,
        hold: holdStash(s, { pocket: DAY5_SHMON_HOLD, wash: DAY5_SHMON_HOLD_WASH, bunk: DAY5_SHMON_HOLD_BUNK }),
        ok: DAY5_SHMON,
      }));
      return;
    }
    if (s.day === 4 && !s.seenDay4Shmon) {
      s.seenDay4Shmon = true;
      pickDialog(g, day4Shmon(s));
      return;
    }
    if (s.day === 3 && !s.seenDay3Shmon) {
      s.seenDay3Shmon = true;
      if (s.malyava === 'admin' || s.path === 'red') pickDialog(g, DAY3_SHMON_RED);
      else if (s.malyava === 'hold' && s.stash === 'wash') pickDialog(g, DAY3_SHMON_WASH);
      else if (s.malyava === 'hold' && s.stash === 'bunk') pickDialog(g, DAY3_SHMON_HOLD_BUNK);
      else if (s.malyava === 'hold') pickDialog(g, DAY3_SHMON_HOLD);
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
      g.toast('Нашли в матрасе. Койка в воздухе, жар полный.');
      g.subtitle('Кормушка: «Нычка в матрасе. Свежак думал, что первый.»');
    } else if (s.stash === 'wash' && s.day === 2) {
      g.subtitle('Кормушка: «Второй шмон. К стенам. Руки видно.» Матрас чистый. Чаша не их дело — сегодня.');
    } else if (!(s.day === 2 && s.seenDay2Shmon)) {
      g.subtitle('Кормушка: «Шмон. К стенам. Руки видно.»');
    }
    return;
  }
  if (id === 'food') {
    if (g.prison.foodTray) g.prison.foodTray.visible = true;
    if (
      s.malyava === 'hold' &&
      s.stash !== 'wash' &&
      ((s.day === 3 && s.seenDay3Shmon) || (s.day === 4 && s.seenDay4Shmon) || (s.day === 5 && s.seenDay5Shmon) || (s.day === 6 && s.seenDay6Shmon) || (s.day === 7 && s.seenDay7Shmon))
    ) {
      s.malyava = 'found';
      s.heat = Math.min(100, s.heat + 28);
      s.stress = Math.min(100, s.stress + 16);
      s.hope = Math.max(0, s.hope - 10);
      g.toast(
        s.stash === 'bunk'
          ? 'Нашли в матрасе. Койка пустая, жар полный.'
          : 'Нашли бумагу. Карман пустой, жар полный.',
      );
    }
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
      pickDialog(g, weekPick(s, { red: DAY5_SLED_RED, gone: DAY5_SLED_GONE, found: s.stash === 'bunk' ? DAY5_SLED_FOUND_BUNK : DAY5_SLED_FOUND, burn: DAY5_SLED_BURN, hold: holdStash(s, { pocket: DAY5_SLED_HOLD, wash: DAY5_SLED_HOLD_WASH, bunk: DAY5_SLED_HOLD_BUNK }), ok: DAY5_SLED }));
      return;
    }
    if (s.day === 6 && !s.seenDay6Food) {
      s.seenDay6Food = true;
      pickDialog(g, weekPick(s, { red: DAY6_FOOD_RED, gone: DAY6_FOOD_GONE, found: s.stash === 'bunk' ? DAY6_FOOD_FOUND_BUNK : DAY6_FOOD_FOUND, burn: DAY6_FOOD_BURN, hold: holdStash(s, { pocket: DAY6_FOOD_HOLD, wash: DAY6_FOOD_HOLD_WASH, bunk: DAY6_FOOD_HOLD_BUNK }), ok: DAY6_FOOD }));
      return;
    }
    if (s.day === 7 && !s.seenDay7Food) {
      s.seenDay7Food = true;
      if (s.malyava === 'found' && s.stash === 'bunk') {
        pickDialog(g, DAY7_SEDOY_FOOD_FOUND_BUNK);
        return;
      }
      if (s.malyava === 'hold' && s.stash === 'bunk') {
        pickDialog(g, DAY7_SEDOY_FOOD_HOLD_BUNK);
        return;
      }
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
      pickDialog(g, s.stash === 'bunk' ? DAY2_WAKE_BUNK : s.stash === 'wash' ? DAY2_WAKE_WASH : DAY2_WAKE);
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
      }
      pickDialog(g, weekPick(s, { red: DAY5_WAKE_RED, gone: DAY5_WAKE_GONE, found: s.stash === 'bunk' ? DAY5_WAKE_FOUND_BUNK : DAY5_WAKE_FOUND, burn: DAY5_WAKE_BURN, hold: holdStash(s, { pocket: DAY5_WAKE_HOLD, wash: DAY5_WAKE_HOLD_WASH, bunk: DAY5_WAKE_HOLD_BUNK }), ok: DAY5_WAKE }));
      return;
    }
    if (s.day === 7 && !s.seenDay7Morning) {
      s.seenDay7Morning = true;
      pickDialog(g, weekPick(s, { red: DAY7_WAKE_RED, gone: DAY7_WAKE_GONE, found: s.stash === 'bunk' ? DAY7_WAKE_FOUND_BUNK : DAY7_WAKE_FOUND, burn: DAY7_WAKE_BURN, hold: holdStash(s, { pocket: DAY7_WAKE_HOLD, wash: DAY7_WAKE_HOLD_WASH, bunk: DAY7_WAKE_HOLD_BUNK }), ok: DAY7_WAKE }));
      return;
    }
    g.subtitle(wakeLine(s));
  }
}

function day4Walk(s) {
  if (weekRed(s)) return DAY4_WALK_RED;
  if (!s.malyava) return DAY4_WALK_WAIT;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY4_WALK_FOUND_BUNK : DAY4_WALK_FOUND;
  if (s.malyava === 'burn') return DAY4_WALK_BURN;
  if (s.malyava === 'gone') return DAY4_WALK_GONE;
  if (s.malyava === 'hold' && s.teaPaid)
    return holdStash(s, { pocket: DAY4_WALK_PAID, wash: DAY4_WALK_PAID_WASH, bunk: DAY4_WALK_PAID_BUNK });
  if (s.malyava === 'hold' && s.stash === 'bunk') return DAY4_WALK_HOLD_BUNK;
  return DAY4_WALK;
}

function day4Food(s) {
  if (weekRed(s)) return DAY4_FOOD_RED;
  if (!s.malyava) return DAY4_FOOD_WAIT;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY4_FOOD_FOUND_BUNK : DAY4_FOOD_FOUND;
  if (s.malyava === 'burn') return DAY4_FOOD_BURN;
  if (s.malyava === 'hold' && s.teaPaid)
    return holdStash(s, { pocket: DAY4_FOOD_HOLD, wash: DAY4_FOOD_HOLD_WASH, bunk: DAY4_FOOD_HOLD_BUNK });
  return DAY4_FOOD;
}

function day4Evening(s) {
  if (weekRed(s)) return DAY4_LEHA_RED;
  if (!s.malyava) return DAY4_NIGHT_WAIT;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY4_LEHA_FOUND_BUNK : DAY4_LEHA_FOUND;
  if (s.malyava === 'burn') return DAY4_LEHA_BURN;
  if (s.malyava === 'hold' && s.teaPaid)
    return holdStash(s, { pocket: DAY4_LEHA_HOLD, wash: DAY4_LEHA_HOLD_WASH, bunk: DAY4_LEHA_HOLD_BUNK });
  if (s.malyava === 'hold' && s.stash === 'bunk') return DAY4_LEHA_HOLD_BUNK_WAIT;
  return DAY4_LEHA;
}

function day4Wake(s) {
  if (weekRed(s)) return DAY4_WAKE_RED;
  if (!s.malyava) return DAY4_WAKE_WAIT;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY4_WAKE_FOUND_BUNK : DAY4_WAKE_FOUND;
  if (s.malyava === 'burn') return DAY4_WAKE_BURN;
  if (s.malyava === 'hold' && s.teaPaid)
    return holdStash(s, { pocket: DAY4_WAKE_HOLD, wash: DAY4_WAKE_HOLD_WASH, bunk: DAY4_WAKE_HOLD_BUNK });
  if (s.malyava === 'hold' && s.stash === 'bunk') return DAY4_WAKE_HOLD_BUNK_WAIT;
  return DAY4_WAKE;
}

function day4Shmon(s) {
  if (weekRed(s)) return DAY4_SHMON_RED;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY4_SHMON_FOUND_BUNK : DAY4_SHMON_FOUND;
  if (s.malyava === 'burn') return DAY4_SHMON_BURN;
  if (s.malyava === 'hold') return holdStash(s, { pocket: DAY4_SHMON_HOLD, wash: DAY4_SHMON_WASH, bunk: DAY4_SHMON_HOLD_BUNK });
  return DAY4_SHMON_WAIT;
}

function day3Walk(s) {
  if (s.malyava === 'admin' || s.path === 'red') return DAY3_WALK_RED;
  if (!s.malyava) return DAY3_WALK_WAIT;
  if (s.malyava === 'hold') return holdStash(s, { pocket: DAY3_WALK_HOLD, wash: DAY3_WALK_HOLD_WASH, bunk: DAY3_WALK_HOLD_BUNK });
  if (s.malyava === 'burn') return DAY3_WALK_BURN;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY3_WALK_FOUND_BUNK : DAY3_WALK_FOUND;
  return DAY3_WALK;
}

function day3Food(s) {
  if (!s.malyava) return DAY3_FOOD;
  if (s.malyava === 'hold') return holdStash(s, { pocket: DAY3_FOOD_HOLD, wash: DAY3_FOOD_HOLD_WASH, bunk: DAY3_FOOD_HOLD_BUNK });
  if (s.malyava === 'burn') return DAY3_FOOD_BURN;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY3_FOOD_FOUND_BUNK : DAY3_FOOD_FOUND;
  return DAY3_FOOD_RED;
}

function day3Morning(s) {
  if (s.malyava === 'admin' || s.path === 'red') return DAY3_MORNING_RED;
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY3_MORNING_FOUND_BUNK : DAY3_MORNING_FOUND;
  if (s.malyava === 'hold') return holdStash(s, { pocket: DAY3_MORNING_HOLD, wash: DAY3_MORNING_HOLD_WASH, bunk: DAY3_MORNING_HOLD_BUNK });
  if (s.malyava === 'burn') return DAY3_MORNING_BURN;
  if (s.stash === 'bunk') return DAY3_MORNING_CAUGHT;
  return DAY3_MORNING;
}

export function weekRed(s) {
  return s.courtTalk === 'cell' || s.malyava === 'admin';
}

export function holdStash(s, packs) {
  if (s.stash === 'bunk') return packs.bunk;
  if (s.stash === 'wash') return packs.wash;
  return packs.pocket;
}

export function weekPick(s, packs) {
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
  if (s.malyava === 'found') return s.stash === 'bunk' ? DAY5_SEDOY_NIGHT_FOUND_BUNK : DAY5_SEDOY_NIGHT_FOUND;
  if (s.malyava === 'hold' && s.stash === 'bunk') return DAY5_SEDOY_NIGHT_HOLD_BUNK;
  if (s.malyava === 'gone') return DAY5_NIGHT_GONE;
  return DAY5_NIGHT_MISS;
}

function eveningLine(s) {
  if (s.courtTalk === 'cell' || s.malyava === 'admin') return 'Отбой. Чайник молчит. Так спят с красным в хате.';
  if (s.malyava === 'hold')
    return holdStash(s, {
      pocket: 'Отбой. Карман жжёт. Своя койка, бумага не на столе.',
      wash: 'Отбой. Чаша знает. Своя койка, не шарь при лампе.',
      bunk: 'Отбой. Бумага в матрасе. Своя койка, не вспоминай койку.',
    });
  if (s.malyava === 'found')
    return s.stash === 'bunk'
      ? 'Отбой. Нашли в матрасе днём. Ночь длиннее пайки.'
      : 'Отбой. Нашли в кармане днём. Ночь длиннее пайки.';
  if (s.malyava === 'burn') return 'Отбой. Пахнет золой. Своя койка.';
  if (s.malyava === 'gone') return 'Отбой. Щель пустая с утра. Своя койка.';
  if (s.courtTalk === 'silent') return 'Отбой. Щель закрылась. Своя койка.';
  return 'Отбой. Своя койка. Чужую не занимай.';
}

function wakeLine(s) {
  if (s.day === 1) return 'Подъём. Мат с коряка. День не спрашивает, готов ты или нет.';
  if (s.courtTalk === 'cell' || s.malyava === 'admin') return `Подъём. День ${s.day}. Хата не здоровается. Так начинают красных.`;
  if (s.malyava === 'found')
    return s.stash === 'bunk'
      ? `Подъём. День ${s.day}. Нашли в матрасе. Жар с вчера. Рот на замок.`
      : `Подъём. День ${s.day}. Нашли в кармане. Жар с вчера. Рот на замок.`;
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
  if (sim.malyava === 'admin' && sim.day === 3) return 'Валера молчит. Третий круг без свиста. Свист кончился.';
  if (sim.malyava === 'admin' && sim.day === 4) return 'Валера молчит. Свист кончился на четвёртый круг.';
  if (sim.malyava === 'admin' && sim.day === 5) return 'Валера молчит. Свист кончился на пятый круг.';
  if (sim.malyava === 'admin' && sim.day === 6) return 'Валера молчит. Свист кончился на шестой круг.';
  if (sim.malyava === 'admin' && sim.day === 7) return 'Валера молчит. Свист кончился на седьмой круг.';
  if (sim.malyava === 'admin' && sim.day === 2) return 'Валера молчит. Свист кончился на второй круг.';
  if (sim.malyava === 'admin' && sim.day === 1) return 'Валера молчит. Свист кончился на первый круг.';
  if (sim.malyava === 'admin') return 'Валера молчит. Свист кончился на третий день.';
  if (sim.malyava === 'burn' && sim.day === 3) return 'Валера коротко: «Третий круг. Зола осталась в хате. Свист кончился.»';
  if (sim.malyava === 'burn' && sim.day === 4) return 'Валера коротко: «Зола в хате. Свист кончился на четвёртый круг.»';
  if (sim.malyava === 'burn' && sim.day === 5) return 'Валера коротко: «Зола в хате. Свист кончился на пятый круг.»';
  if (sim.malyava === 'burn' && sim.day === 6) return 'Валера коротко: «Зола в хате. Свист кончился на шестой круг.»';
  if (sim.malyava === 'burn' && sim.day === 7) return 'Валера коротко: «Зола в хате. Свист кончился на седьмой круг.»';
  if (sim.malyava === 'burn' && sim.day === 2) return 'Валера коротко: «Зола в хате. Свист кончился на второй круг.»';
  if (sim.malyava === 'burn' && sim.day === 1) return 'Валера коротко: «Зола в хате. Свист кончился на первый круг.»';
  if (sim.malyava === 'burn') return 'Валера коротко: «Зола в хате. На дворе про дым не ори.»';
  if (sim.malyava === 'gone' && sim.day === 5) return 'Валера коротко: «Щель пустая. Свист кончился на пятый круг.»';
  if (sim.malyava === 'gone' && sim.day === 6) return 'Валера коротко: «Щель пустая. Свист кончился на шестой круг.»';
  if (sim.malyava === 'gone' && sim.day === 7) return 'Валера коротко: «Щель пустая. Свист кончился на седьмой круг.»';
  if (sim.malyava === 'gone' && sim.day === 3) return 'Валера коротко: «Третий круг. Щель днём стучала. Свист кончился.»';
  if (sim.malyava === 'gone' && sim.day === 4) return 'Валера коротко: «Щель пустая. Свист кончился на четвёртый круг.»';
  if (sim.malyava === 'gone' && sim.day === 2) return 'Валера коротко: «Щель пустая. Свист кончился на второй круг.»';
  if (sim.malyava === 'gone' && sim.day === 1) return 'Валера коротко: «Щель пустая. Свист кончился на первый круг.»';
  if (!sim.malyava && sim.day === 3) return 'Валера коротко: «Третий круг. Бумага в щели. Свист кончился.»';
  if (sim.malyava === 'hold' && sim.day === 3)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Третий круг. Бумага в матрасе. Свист кончился.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Третий круг. Чаша осталась в хате. Свист кончился.»'
        : 'Валера коротко: «Карман жжёт. Свист кончился на третий круг.»';
  if (sim.malyava === 'found' && sim.day === 3)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Третий круг. Нашли в матрасе. Свист кончился.»'
      : 'Валера коротко: «Третий круг. Нашли в кармане. Свист кончился.»';
  if (!sim.malyava && sim.day === 4) return 'Валера коротко: «Четвёртый круг. Бумага в щели. Свист кончился.»';
  if (sim.malyava === 'hold' && sim.day === 4)
    return sim.teaPaid
      ? sim.stash === 'bunk'
        ? 'Валера коротко: «Четвёртый круг. Чай ушёл. Бумага в матрасе. Свист кончился.»'
        : sim.stash === 'wash'
          ? 'Валера коротко: «Четвёртый круг. Чай ушёл. Чаша в хате. Свист кончился.»'
          : 'Валера коротко: «Четвёртый круг. Чай ушёл. Карман жжёт. Свист кончился.»'
      : sim.stash === 'bunk'
        ? 'Валера коротко: «Четвёртый круг. Бумага в матрасе. Чай ещё в щели. Свист кончился.»'
        : sim.stash === 'wash'
          ? 'Валера коротко: «Чаша в хате. Чай ещё в щели. Свист кончился на четвёртый круг.»'
          : 'Валера коротко: «Долг чая в щели. Свист кончился на четвёртый круг.»';
  if (sim.malyava === 'found' && sim.day === 4)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Нашли в матрасе. Свист кончился на четвёртый круг.»'
      : 'Валера коротко: «Нашли в кармане. Свист кончился на четвёртый круг.»';
  if (!sim.malyava && sim.day === 5) return 'Валера коротко: «С коряка звали. Свист кончился на пятый круг.»';
  if (sim.malyava === 'hold' && sim.day === 5)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Бумага в матрасе. Свист кончился на пятый круг.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Чаша в хате. Свист кончился на пятый круг.»'
        : 'Валера коротко: «Карман жжёт. Свист кончился на пятый круг.»';
  if (sim.malyava === 'found' && sim.day === 5)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Нашли в матрасе. Свист кончился на пятый круг.»'
      : 'Валера коротко: «Нашли в кармане. Свист кончился на пятый круг.»';
  if (!sim.malyava && sim.day === 6) return 'Валера коротко: «Завтра не ори про волю. Свист кончился на шестой круг.»';
  if (sim.malyava === 'hold' && sim.day === 6)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Бумага в матрасе. Свист кончился на шестой круг.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Чаша в хате. Свист кончился на шестой круг.»'
        : 'Валера коротко: «Карман жжёт. Свист кончился на шестой круг.»';
  if (sim.malyava === 'found' && sim.day === 6)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Нашли в матрасе. Свист кончился на шестой круг.»'
      : 'Валера коротко: «Нашли в кармане. Свист кончился на шестой круг.»';
  if (!sim.malyava && sim.day === 7) return 'Валера коротко: «Свежак кончился. Не ори про волю. Свист кончился на седьмой круг.»';
  if (sim.malyava === 'hold' && sim.day === 7)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Бумага в матрасе. Свист кончился на седьмой круг.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Чаша в хате. Свист кончился на седьмой круг.»'
        : 'Валера коротко: «Карман жжёт. Свист кончился на седьмой круг.»';
  if (sim.malyava === 'found' && sim.day === 7)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Нашли в матрасе. Свист кончился на седьмой круг.»'
      : 'Валера коротко: «Нашли в кармане. Свист кончился на седьмой круг.»';
  if (!sim.malyava && sim.day === 2)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Второй круг. Нашли в матрасе. Свист кончился.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Второй круг. Матрас чистый. Свист кончился.»'
        : 'Валера коротко: «Второй круг. Этапом шепчут Херсон. Свист кончился.»';
  if (sim.malyava === 'hold' && sim.day === 2)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Второй круг. Бумага в матрасе. Свист кончился.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Второй круг. Чаша в хате. Свист кончился.»'
        : 'Валера коротко: «Второй круг. Карман жжёт. Свист кончился.»';
  if (sim.malyava === 'found' && sim.day === 2)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Второй круг. Нашли в матрасе. Свист кончился.»'
      : 'Валера коротко: «Второй круг. Нашли в кармане. Свист кончился.»';
  if (!sim.malyava && sim.day === 1) return 'Валера коротко: «Конвой вывел. Свист кончился на первый круг.»';
  if (sim.malyava === 'hold' && sim.day === 1)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Бумага в матрасе. Свист кончился на первый круг.»'
      : sim.stash === 'wash'
        ? 'Валера коротко: «Чаша в хате. Свист кончился на первый круг.»'
        : 'Валера коротко: «Карман жжёт. Свист кончился на первый круг.»';
  if (sim.malyava === 'found' && sim.day === 1)
    return sim.stash === 'bunk'
      ? 'Валера коротко: «Нашли в матрасе. Свист кончился на первый круг.»'
      : 'Валера коротко: «Нашли в кармане. Свист кончился на первый круг.»';
  if (sim.day === 5) return 'Валера: «С коряка звали. Что сказал — хата узнает вечером.»';
  if (sim.day >= 2) return 'Валера тихо: «Этапом шепчут Херсон. Не повторяй вслух.»';
  return 'Круг по бетону. Через сетку — небо. Небо не твоё.';
}

export function hatchReady(sim) {
  return sim.day >= 3 && !sim.malyava;
}
