/**
 * Life inside хата 4 after the door closes.
 * Never idle: convoy leaves, прописка fires, then tasks, talk, routine.
 */
import {
  CIG_ASK,
  HATCH_TALK,
  HATCH_GONE,
  KETTLE_TALK,
  KETTLE_TALK_HOLD,
  KETTLE_TALK_RED,
  WINDOW_TALK,
  WINDOW_TALK_HOLD,
  WINDOW_TALK_GONE,
  WINDOW_TALK_RED,
  TALK_STAROSTA,
  TALK_LEHA,
  TALK_VALERA,
  DAY2_SEDOY,
  DAY2_SEDOY_CAUGHT,
  DAY2_SEDOY_WASH,
  DAY2_SEDOY_SHMON,
  DAY2_SEDOY_SHMON_CAUGHT,
  DAY2_SEDOY_SHMON_WASH,
  DAY4_SEDOY_SHMON_WAIT,
  DAY4_SEDOY_SHMON_WASH,
  DAY4_SEDOY_SHMON_FOUND,
  DAY4_SEDOY_SHMON_BURN,
  DAY4_SEDOY_SHMON_RED,
  DAY5_SEDOY_SHMON,
  DAY5_SEDOY_SHMON_GONE,
  DAY5_SEDOY_SHMON_HOLD,
  DAY5_SEDOY_SHMON_FOUND,
  DAY5_SEDOY_SHMON_BURN,
  DAY5_SEDOY_SHMON_RED,
  DAY6_SEDOY_SHMON,
  DAY6_SEDOY_SHMON_GONE,
  DAY6_SEDOY_SHMON_HOLD,
  DAY6_SEDOY_SHMON_FOUND,
  DAY6_SEDOY_SHMON_BURN,
  DAY6_SEDOY_SHMON_RED,
  DAY7_SEDOY_SHMON,
  DAY7_SEDOY_SHMON_GONE,
  DAY7_SEDOY_SHMON_HOLD,
  DAY7_SEDOY_SHMON_FOUND,
  DAY7_SEDOY_SHMON_FOUND_BUNK,
  DAY7_SEDOY_SHMON_BURN,
  DAY7_SEDOY_SHMON_RED,
  DAY2_YARD,
  DAY2_YARD_CAUGHT,
  DAY2_YARD_WASH,
  DAY2_VALERA,
  DAY2_VALERA_CAUGHT,
  DAY2_VALERA_WASH,
  DAY2_VALERA_SHMON,
  DAY2_VALERA_SHMON_CAUGHT,
  DAY2_VALERA_SHMON_WASH,
  DAY3_VALERA,
  DAY3_VALERA_WAIT,
  DAY3_VALERA_HOLD,
  DAY3_VALERA_HOLD_WASH,
  DAY3_VALERA_HOLD_BUNK,
  DAY3_VALERA_SHMON_HOLD_BUNK,
  DAY3_FOOD_HOLD_WASH,
  DAY3_FOOD_HOLD_BUNK,
  DAY3_NIGHT_HOLD_WASH,
  DAY3_NIGHT_HOLD_BUNK,
  DAY3_WALK_HOLD_WASH,
  DAY3_WALK_HOLD_BUNK,
  DAY3_LEHA_HOLD_WASH,
  DAY3_LEHA_HOLD_BUNK,
  DAY3_MORNING_HOLD_WASH,
  DAY3_MORNING_HOLD_BUNK,
  DAY3_VALERA_BURN,
  DAY3_VALERA_FOUND,
  DAY3_VALERA_RED,
  DAY3_VALERA_SHMON,
  DAY3_VALERA_SHMON_HATCH,
  DAY3_VALERA_SHMON_HOLD,
  DAY3_VALERA_SHMON_WASH,
  DAY3_VALERA_SHMON_FOUND,
  DAY3_VALERA_SHMON_FOUND_BUNK,
  DAY3_VALERA_SHMON_BURN,
  DAY3_VALERA_SHMON_RED,
  DAY3_VALERA_SHMON_CAUGHT,
  DAY4_VALERA,
  DAY4_VALERA_WAIT,
  DAY4_VALERA_PAID,
  DAY4_VALERA_FOUND,
  DAY4_VALERA_BURN,
  DAY4_VALERA_RED,
  DAY4_VALERA_SHMON_WAIT,
  DAY4_VALERA_SHMON_WASH,
  DAY4_VALERA_SHMON_FOUND,
  DAY4_VALERA_SHMON_FOUND_BUNK,
  DAY4_VALERA_SHMON_BURN,
  DAY4_VALERA_SHMON_RED,
  DAY5_VALERA_SHMON,
  DAY5_VALERA_SHMON_GONE,
  DAY5_VALERA_SHMON_HOLD,
  DAY5_VALERA_SHMON_FOUND,
  DAY5_VALERA_SHMON_FOUND_BUNK,
  DAY5_VALERA_SHMON_BURN,
  DAY5_VALERA_SHMON_RED,
  DAY6_VALERA_SHMON,
  DAY6_VALERA_SHMON_GONE,
  DAY6_VALERA_SHMON_HOLD,
  DAY6_VALERA_SHMON_FOUND,
  DAY6_VALERA_SHMON_FOUND_BUNK,
  DAY6_VALERA_SHMON_BURN,
  DAY6_VALERA_SHMON_RED,
  DAY7_VALERA_SHMON,
  DAY7_VALERA_SHMON_GONE,
  DAY7_VALERA_SHMON_HOLD,
  DAY7_VALERA_SHMON_FOUND,
  DAY7_VALERA_SHMON_FOUND_BUNK,
  DAY7_VALERA_SHMON_BURN,
  DAY7_VALERA_SHMON_RED,
  DAY5_VALERA,
  DAY5_VALERA_GONE,
  DAY5_VALERA_HOLD,
  DAY5_VALERA_FOUND,
  DAY5_VALERA_BURN,
  DAY5_VALERA_RED,
  WEEK_VALERA,
  WEEK_VALERA_GONE,
  WEEK_VALERA_HOLD,
  WEEK_VALERA_FOUND,
  WEEK_VALERA_FOUND_BUNK,
  WEEK_VALERA_BURN,
  WEEK_VALERA_RED,
  DAY7_VALERA,
  DAY7_VALERA_GONE,
  DAY7_VALERA_HOLD,
  DAY7_VALERA_FOUND,
  DAY7_VALERA_BURN,
  DAY7_VALERA_RED,
  DAY3_NOTE,
  DAY3_NOTE_SHMON,
  DAY3_WALK,
  DAY3_WALK_WAIT,
  DAY3_WALK_HOLD,
  DAY3_WALK_RED,
  DAY3_WALK_BURN,
  DAY3_WALK_FOUND,
  DAY3_WALK_FOUND_BUNK,
  DAY3_MORNING,
  DAY3_MORNING_RED,
  DAY3_MORNING_CAUGHT,
  DAY3_MORNING_HOLD,
  DAY3_MORNING_BURN,
  DAY3_MORNING_FOUND,
  DAY3_MORNING_FOUND_BUNK,
  DAY3_SEDOY_SHMON,
  DAY3_SEDOY_SHMON_HATCH,
  DAY3_SEDOY_SHMON_HOLD,
  DAY3_SEDOY_SHMON_WASH,
  DAY3_SEDOY_SHMON_FOUND,
  DAY3_SEDOY_SHMON_FOUND_BUNK,
  DAY3_SEDOY_SHMON_BURN,
  DAY3_SEDOY_SHMON_RED,
  DAY3_SEDOY_SHMON_CAUGHT,
  DAY3_NIGHT,
  DAY3_NIGHT_WAIT,
  DAY3_NIGHT_FOUND,
  DAY3_NIGHT_FOUND_BUNK,
  DAY3_NIGHT_HOLD,
  DAY3_NIGHT_BURN,
  DAY3_NIGHT_RED,
  DAY2_WAKE,
  DAY2_WAKE_WASH,
  DAY2_WAKE_BUNK,
  DAY2_NIGHT,
  DAY2_NIGHT_WASH,
  DAY2_NIGHT_CAUGHT,
  DAY2_FOOD,
  DAY2_FOOD_CAUGHT,
  DAY2_FOOD_WASH,
  DAY2_LEHA_SHMON,
  DAY2_LEHA_SHMON_CAUGHT,
  DAY2_LEHA_SHMON_WASH,
  DAY3_FOOD,
  DAY3_FOOD_HOLD,
  DAY3_FOOD_BURN,
  DAY3_LEHA,
  DAY3_LEHA_HOLD,
  DAY3_LEHA_BURN,
  DAY3_LEHA_FOUND,
  DAY3_LEHA_FOUND_BUNK,
  DAY3_LEHA_RED,
  DAY3_LEHA_CAUGHT,
  DAY3_LEHA_SHMON,
  DAY3_LEHA_SHMON_HATCH,
  DAY3_LEHA_SHMON_HOLD,
  DAY3_LEHA_SHMON_WASH,
  DAY3_LEHA_SHMON_FOUND,
  DAY3_LEHA_SHMON_FOUND_BUNK,
  DAY3_LEHA_SHMON_BURN,
  DAY3_LEHA_SHMON_RED,
  DAY3_LEHA_SHMON_CAUGHT,
  DAY4_LEHA,
  DAY4_NIGHT_WAIT,
  DAY4_LEHA_HOLD,
  DAY4_LEHA_HOLD_WASH,
  DAY4_LEHA_HOLD_BUNK,
  DAY4_LEHA_FOUND,
  DAY4_LEHA_FOUND_BUNK,
  DAY4_LEHA_BURN,
  DAY4_LEHA_RED,
  DAY4_LEHA_SHMON_WAIT,
  DAY4_LEHA_SHMON_WASH,
  DAY4_LEHA_SHMON_FOUND,
  DAY4_LEHA_SHMON_FOUND_BUNK,
  DAY4_LEHA_SHMON_BURN,
  DAY4_LEHA_SHMON_RED,
  DAY5_LEHA_SHMON,
  DAY5_LEHA_SHMON_GONE,
  DAY5_LEHA_SHMON_HOLD,
  DAY5_LEHA_SHMON_FOUND,
  DAY5_LEHA_SHMON_FOUND_BUNK,
  DAY5_LEHA_SHMON_BURN,
  DAY5_LEHA_SHMON_RED,
  DAY6_LEHA_SHMON,
  DAY6_LEHA_SHMON_GONE,
  DAY6_LEHA_SHMON_HOLD,
  DAY6_LEHA_SHMON_FOUND,
  DAY6_LEHA_SHMON_FOUND_BUNK,
  DAY6_LEHA_SHMON_BURN,
  DAY6_LEHA_SHMON_RED,
  DAY7_LEHA_SHMON,
  DAY7_LEHA_SHMON_GONE,
  DAY7_LEHA_SHMON_HOLD,
  DAY7_LEHA_SHMON_FOUND,
  DAY7_LEHA_SHMON_FOUND_BUNK,
  DAY7_LEHA_SHMON_BURN,
  DAY7_LEHA_SHMON_RED,
  DAY7_LEHA,
  DAY7_LEHA_GONE,
  DAY7_LEHA_HOLD,
  DAY7_LEHA_HOLD_WASH,
  DAY7_LEHA_HOLD_BUNK,
  DAY7_LEHA_FOUND,
  DAY7_LEHA_BURN,
  DAY7_LEHA_RED,
  DAY4_HATCH,
  DAY4_WALK,
  DAY4_WALK_WAIT,
  DAY4_WALK_PAID,
  DAY4_WALK_PAID_WASH,
  DAY4_WALK_PAID_BUNK,
  DAY4_WALK_FOUND,
  DAY4_WALK_BURN,
  DAY4_WALK_RED,
  DAY4_FOOD,
  DAY4_FOOD_WAIT,
  DAY4_FOOD_HOLD,
  DAY4_FOOD_HOLD_WASH,
  DAY4_FOOD_HOLD_BUNK,
  DAY4_FOOD_FOUND,
  DAY4_FOOD_BURN,
  DAY4_FOOD_RED,
  DAY5_COURT,
  DAY5_COURT_GONE,
  DAY5_WALK,
  DAY5_WALK_GONE,
  DAY5_WALK_HOLD,
  DAY5_WALK_HOLD_WASH,
  DAY5_WALK_HOLD_BUNK,
  DAY5_WALK_FOUND,
  DAY5_WALK_BURN,
  DAY5_WALK_RED,
  DAY5_WAKE,
  DAY5_WAKE_GONE,
  DAY5_WAKE_FOUND,
  DAY5_WAKE_BURN,
  DAY5_WAKE_HOLD,
  DAY5_WAKE_HOLD_WASH,
  DAY5_WAKE_HOLD_BUNK,
  DAY5_WAKE_RED,
  DAY6_WALK,
  DAY6_WALK_GONE,
  DAY6_WALK_RED,
  DAY6_WALK_FOUND,
  DAY6_WALK_BURN,
  DAY6_WALK_HOLD,
  DAY6_WALK_HOLD_WASH,
  DAY6_WALK_HOLD_BUNK,
  DAY7_WALK,
  DAY7_WALK_GONE,
  DAY7_WALK_RED,
  DAY7_WALK_FOUND,
  DAY7_WALK_BURN,
  DAY7_WALK_HOLD,
  DAY7_WALK_HOLD_WASH,
  DAY7_WALK_HOLD_BUNK,
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
  DAY6_FOOD_BURN,
  DAY6_FOOD_HOLD,
  DAY6_FOOD_HOLD_WASH,
  DAY6_FOOD_HOLD_BUNK,
  WEEK_HELD,
  WEEK_HELD_GONE,
  WEEK_HELD_RED,
  WEEK_HELD_FOUND,
  WEEK_HELD_FOUND_BUNK,
  WEEK_HELD_BURN,
  WEEK_HELD_HOLD,
  WEEK_HELD_HOLD_WASH,
  WEEK_HELD_HOLD_BUNK,
  DAY6_SEDOY,
  DAY6_SEDOY_HOLD,
  DAY6_SEDOY_HOLD_WASH,
  DAY6_SEDOY_HOLD_BUNK,
  DAY6_SEDOY_GONE,
  DAY6_SEDOY_FOUND,
  DAY6_SEDOY_BURN,
  DAY6_SEDOY_RED,
  DAY5_BACK_SILENT,
  DAY5_BACK_CELL,
  DAY5_BACK_SELF,
} from './Dialogue.js';
import { onPhaseEnter, plotObjective, hatchReady, weekPick, weekRed, holdStash } from './Plot.js';

function valeraInCell(s) {
  if (s.day >= 7) {
    if (s.phase.id === 'shmon') {
      return weekPick(s, {
        red: DAY7_VALERA_SHMON_RED,
        gone: DAY7_VALERA_SHMON_GONE,
        found: s.stash === 'bunk' ? DAY7_VALERA_SHMON_FOUND_BUNK : DAY7_VALERA_SHMON_FOUND,
        burn: DAY7_VALERA_SHMON_BURN,
        hold: DAY7_VALERA_SHMON_HOLD,
        ok: DAY7_VALERA_SHMON,
      });
    }
    return weekPick(s, {
      red: DAY7_VALERA_RED,
      gone: DAY7_VALERA_GONE,
      found: DAY7_VALERA_FOUND,
      burn: DAY7_VALERA_BURN,
      hold: DAY7_VALERA_HOLD,
      ok: DAY7_VALERA,
    });
  }
  if (s.day >= 6) {
    if (s.phase.id === 'shmon') {
      return weekPick(s, {
        red: DAY6_VALERA_SHMON_RED,
        gone: DAY6_VALERA_SHMON_GONE,
        found: s.stash === 'bunk' ? DAY6_VALERA_SHMON_FOUND_BUNK : DAY6_VALERA_SHMON_FOUND,
        burn: DAY6_VALERA_SHMON_BURN,
        hold: DAY6_VALERA_SHMON_HOLD,
        ok: DAY6_VALERA_SHMON,
      });
    }
    return weekPick(s, {
      red: WEEK_VALERA_RED,
      gone: WEEK_VALERA_GONE,
      found: s.stash === 'bunk' ? WEEK_VALERA_FOUND_BUNK : WEEK_VALERA_FOUND,
      burn: WEEK_VALERA_BURN,
      hold: WEEK_VALERA_HOLD,
      ok: WEEK_VALERA,
    });
  }
  if (s.day >= 5) {
    if (s.phase.id === 'shmon') {
      return weekPick(s, {
        red: DAY5_VALERA_SHMON_RED,
        gone: DAY5_VALERA_SHMON_GONE,
        found: s.stash === 'bunk' ? DAY5_VALERA_SHMON_FOUND_BUNK : DAY5_VALERA_SHMON_FOUND,
        burn: DAY5_VALERA_SHMON_BURN,
        hold: DAY5_VALERA_SHMON_HOLD,
        ok: DAY5_VALERA_SHMON,
      });
    }
    return weekPick(s, {
      red: DAY5_VALERA_RED,
      gone: DAY5_VALERA_GONE,
      found: DAY5_VALERA_FOUND,
      burn: DAY5_VALERA_BURN,
      hold: DAY5_VALERA_HOLD,
      ok: DAY5_VALERA,
    });
  }
  if (s.day >= 4) {
    if (s.phase.id === 'shmon') {
      return day4ShmonTalk(s, {
        red: DAY4_VALERA_SHMON_RED,
        found: s.stash === 'bunk' ? DAY4_VALERA_SHMON_FOUND_BUNK : DAY4_VALERA_SHMON_FOUND,
        burn: DAY4_VALERA_SHMON_BURN,
        wash: DAY4_VALERA_SHMON_WASH,
        wait: DAY4_VALERA_SHMON_WAIT,
      });
    }
    if (weekRed(s)) return DAY4_VALERA_RED;
    if (!s.malyava) return DAY4_VALERA_WAIT;
    if (s.malyava === 'found') return DAY4_VALERA_FOUND;
    if (s.malyava === 'burn') return DAY4_VALERA_BURN;
    if (s.malyava === 'hold' && s.teaPaid) return DAY4_VALERA_PAID;
    return DAY4_VALERA;
  }
  if (s.day >= 3) {
    if (s.phase.id === 'shmon') {
      if (s.malyava === 'admin' || s.path === 'red') return DAY3_VALERA_SHMON_RED;
      if (s.malyava === 'found') return s.stash === 'bunk' ? DAY3_VALERA_SHMON_FOUND_BUNK : DAY3_VALERA_SHMON_FOUND;
      if (s.malyava === 'hold' && s.stash === 'wash') return DAY3_VALERA_SHMON_WASH;
      if (s.malyava === 'hold' && s.stash === 'bunk') return DAY3_VALERA_SHMON_HOLD_BUNK;
      if (s.malyava === 'hold') return DAY3_VALERA_SHMON_HOLD;
      if (s.malyava === 'burn') return DAY3_VALERA_SHMON_BURN;
      if (!s.malyava) return DAY3_VALERA_SHMON_HATCH;
      if (s.stash === 'bunk') return DAY3_VALERA_SHMON_CAUGHT;
      return DAY3_VALERA_SHMON;
    }
    if (s.malyava === 'admin' || s.path === 'red') return DAY3_VALERA_RED;
    if (s.malyava === 'found') return DAY3_VALERA_FOUND;
    if (s.malyava === 'hold') return holdStash(s, { pocket: DAY3_VALERA_HOLD, wash: DAY3_VALERA_HOLD_WASH, bunk: DAY3_VALERA_HOLD_BUNK });
    if (s.malyava === 'burn') return DAY3_VALERA_BURN;
    if (!s.malyava) return DAY3_VALERA_WAIT;
    return DAY3_VALERA;
  }
  if (s.day >= 2) {
    if (s.phase.id === 'shmon') {
      if (s.stash === 'bunk') return DAY2_VALERA_SHMON_CAUGHT;
      if (s.stash === 'wash') return DAY2_VALERA_SHMON_WASH;
      return DAY2_VALERA_SHMON;
    }
    if (s.stash === 'bunk') return DAY2_VALERA_CAUGHT;
    if (s.stash === 'wash') return DAY2_VALERA_WASH;
    return DAY2_VALERA;
  }
  return TALK_VALERA;
}

function day4ShmonTalk(s, packs) {
  if (weekRed(s)) return packs.red;
  if (s.malyava === 'found') return packs.found;
  if (s.malyava === 'burn') return packs.burn;
  if (s.malyava === 'hold') return packs.wash;
  return packs.wait;
}

function ambientFor(g) {
  const s = g.sim;
  if (s.courtTalk === 'cell' || s.malyava === 'admin') {
    return [
      () => g.subtitle('Чайник стоит. Никто не наливает. Так выглядит красный ход изнутри.'),
      () => g.subtitle('Лёха смотрит в стену. Слов нет. Слова ушли в щель.'),
      () => {
        g.audio.clang();
        g.subtitle('Шаги. Могли за тобой. Могли мимо. Красному всё равно.');
        s.stress = Math.min(100, s.stress + 8);
      },
    ];
  }
  if (s.day === 5 && !s.courtTalk) {
    return [
      () => g.subtitle('С коряка шепчут фамилию. Не твою — пока.'),
      () => g.subtitle('Седой: «Про хату — ничего. Про себя — коротко.»'),
      () => {
        g.audio.clang();
        g.subtitle('Ключ в щели. Не пайка. Вызов.');
        s.stress = Math.min(100, s.stress + 5);
      },
    ];
  }
  if (s.malyava === 'hold') {
    return [
      () => g.subtitle('Карман жжёт. Бумага шуршит громче шагов на коряке.'),
      () => g.subtitle('Лёха шепчет: «Не в матрас. Чаша. Или жги.»'),
      () => g.subtitle('Валера не свистит. Свист сейчас — как малява вслух.'),
    ];
  }
  if (s.malyava === 'gone') {
    return [
      () => g.subtitle('Щель пустая с пятого. Бумагу взяли без тебя.'),
      () => g.subtitle('Лёха смотрит мимо. Пустая щель громче полного кармана.'),
      () => {
        g.audio.clang();
        g.subtitle('Ключ. Не пайка. Папка уже толще.');
        s.stress = Math.min(100, s.stress + 5);
      },
    ];
  }
  if (s.malyava === 'found') {
    return [
      () => g.subtitle('Жар. Хата знает, что нашли. Не спрашивает вслух.'),
      () => {
        g.audio.clang();
        g.subtitle('Кормушка: ключ, пауза, ушли. Бумаги уже нет. Жар есть.');
        s.stress = Math.min(100, s.stress + 6);
      },
    ];
  }
  if (s.malyava === 'burn') {
    return [
      () => g.subtitle('Пахнет золой. Соседи тише, чем вчера.'),
      () => g.subtitle('Валера свистит короче. Песня обгорела с краю.'),
    ];
  }
  if (s.day === 2) {
    return [
      () => g.subtitle('Лёха: «Шмон до пайки. Чаша, не матрас.»'),
      () => g.subtitle('Седой не смотрит. Значит, сутки ещё не человек и не пустое место.'),
      () => {
        g.audio.clang();
        g.subtitle('Шаги на коряке. Не пайка. Шмон будет раньше ложки.');
        s.stress = Math.min(100, s.stress + 4);
      },
    ];
  }
  if (s.day >= 3) {
    return [
      () => g.subtitle('Седой: «Имя уже знаем. Дело ещё нет.»'),
      () => g.subtitle('Лёха: «Кормушка днём живая. Не зевай.»'),
      () => {
        g.audio.clang();
        g.subtitle('Два коротких в щель. Не пайка. Бумага.');
      },
      () => g.subtitle('Из трубы: кап-кап. Третий день считается иначе, чем первый.'),
    ];
  }
  return [
    () => g.subtitle('Седой, не глядя: «Ноги с чужой шконки. Это не просьба.»'),
    () => g.subtitle('Лёха шепчет: «Кормушка сейчас глухая. Ночью — живая.»'),
    () => {
      g.audio.clang();
      g.subtitle('Шаги на коряке. Свет в щели. Мимо. Сердце всё равно стучит.');
      s.stress = Math.min(100, s.stress + 6);
    },
    () => g.subtitle('Валера насвистывает едва слышно. На секунду хата — не камера.'),
    () => g.subtitle('Из трубы: кап-кап. Кто-то считает это вместо дней.'),
    () => g.subtitle('Седой: «Общак не спрашивает. Общак помнит, кто кинул чай.»'),
  ];
}

const TASKS = [
  { id: 'cig', label: 'Седой ждёт цигарку. Подойди, E — отдай или откажи.' },
  { id: 'hatch', label: 'Кормушка стучит. Подойди к двери хаты — послушай.' },
  { id: 'window', label: 'Посмотри в окно. Не махай — считай дни.' },
  { id: 'kettle', label: 'Чайник на столе. Чифир — общий, не твой карман.' },
  { id: 'cards', label: 'Валера кличет на карты. Подойди — сыграй или откажи.' },
  { id: 'bunk', label: 'Своя шконка — нижняя у окна. Лечь. Чужую не занимай.' },
];

export class CellLife {
  constructor(game) {
    this.g = game;
    this.active = false;
    this.t = 0;
    this.seen = new Set();
    this.talkCd = {};
    this.taskI = 0;
    this.ambientT = 0;
    this.convoyGone = false;
  }

  begin() {
    this.active = true;
    this.t = 0;
    this.seen.clear();
    this.g.npcs.dismissConvoy();
    this.g.audio.clang();
    this.g.subtitle('Конвой: «Хату принял. Живи. Кормушку без команды не открывай.»');
  }

  tick(dt) {
    if (!this.active) return;
    this.t += dt;
    this.directNpcs(dt);
    this.scriptBeats();
    this.ambientAir(dt);
    this.phaseMood();
  }

  scriptBeats() {
    const g = this.g;
    if (this.t > 3.2 && !this.convoyGone) {
      this.convoyGone = true;
      const door = g.prison.interactables.find((it) => it.type === 'cell-door');
      if (door) g.prison.closeDoor(door);
      g.audio.clang();
      if (!g.dialog.open) g.subtitle('Замок. Теперь хата слышит тебя лучше, чем конвой.');
    }
    if (this.t > 0.35 && !this.seen.has('greet') && g.sim.stage === 'propiska' && !g.dialog.open) {
      this.seen.add('greet');
      g.greetingMenu();
    }
    if (g.sim.stage !== 'life' || g.dialog.open) return;
    const life = this.t - (this.lifeT || this.t);
    if (life > 7 && !this.seen.has('watch')) {
      this.seen.add('watch');
      g.subtitle('Седой не смотрит на тебя. Смотрит, сядешь ли сам, или будешь столбом у двери.');
    }
    if (life > 16 && !this.seen.has('pipe')) {
      this.seen.add('pipe');
      g.subtitle('Из трубы кап-кап. Лёха считает это вместо дней. Завтра научит, если не сорвёшься.');
    }
    if (life > 28 && !this.seen.has('whistle')) {
      this.seen.add('whistle');
      g.subtitle('Валера свистит в нос. На секунду крыша выше, чем три метра. Потом снова известь.');
    }
    if (life > 40 && !this.seen.has('hatch-tap') && g.sim.task?.id === 'hatch') {
      this.seen.add('hatch-tap');
      g.audio.clang();
      g.subtitle('Кормушка. Два коротких. Соседи знают, что в четвёртой свежак.');
    }
    if (life > 55 && !this.seen.has('hope')) {
      this.seen.add('hope');
      g.subtitle('Надежда здесь прячется, как малява. Кто орёт про волю вслух — уже на карандаше.');
    }
  }

  onPropiskaDone() {
    this.lifeT = this.t;
    this.nextTask();
    const leha = this.g.npcs.byId('cellmate');
    const s = this.g.prison.seats;
    if (leha && s) this.g.npcs.goTo(leha, s.lehaSit);
    this.g.subtitle('Лёха: «Не стой в дверях. Сядь, когда посадят. Дальше — слушай хату.»');
  }

  nextTask() {
    const t = TASKS[this.taskI];
    if (!t) {
      this.g.sim.task = {
        id: 'live',
        label: plotObjective(this.g.sim) || 'Живи по распорядку. Говори с хатой. Дверь сам не откроешь.',
      };
      return;
    }
    this.g.sim.task = { id: t.id, label: t.label };
    this.taskI += 1;
  }

  completeTask(id) {
    if (this.g.sim.task?.id !== id) return;
    this.g.sim.hope = Math.min(100, this.g.sim.hope + 5);
    this.g.sim.rep += 1;
    this.nextTask();
    this.g.toast('Хатка это заметила.');
  }

  ambientAir(dt) {
    if (this.g.overlaysOpen()) return;
    if (this.g.sim.stage !== 'life' && this.g.sim.stage !== 'propiska') return;
    this.ambientT += dt;
    const idle = this.g.idle || 0;
    if (this.g.sim.stage === 'life' && this.t - (this.lifeT || 0) < 50) return;
    if ((idle > 5.5 || this.ambientT > 14) && !this.g.dialog.open) {
      this.ambientT = 0;
      this.g.idle = 0;
      const lines = ambientFor(this.g);
      lines[(Math.random() * lines.length) | 0]();
    }
  }

  phaseMood() {
    const g = this.g;
    if (g.sim.stage !== 'life') return;
    const id = g.sim.phase.id;
    if (id === this._phase) return;
    this._phase = id;
    onPhaseEnter(g, id);
  }

  directNpcs() {
    const g = this.g;
    const s = g.prison.seats;
    if (!s) return;
    const phase = g.sim.stage === 'life' ? g.sim.phase.id : 'wake';
    if (phase !== this._npcPhase) {
      this._npcPhase = phase;
      for (const id of ['starosta', 'cellmate', 'bunk-bro']) {
        const n = g.npcs.byId(id);
        if (n) {
          n.duty = null;
          n.dutyIndex = 0;
          n.askFrozen = null;
        }
      }
    }
    const starosta = g.npcs.byId('starosta');
    const leha = g.npcs.byId('cellmate');
    const valera = g.npcs.byId('bunk-bro');
    const shunned = g.sim.malyava === 'admin' || g.sim.courtTalk === 'cell';
    if (shunned && phase !== 'walk' && phase !== 'shmon') {
      this.snap(starosta, 'cold', { ...s.sedoyStool, yaw: Math.PI / 2 });
      this.snap(leha, 'cold', { ...s.lehaSit, yaw: 0 });
      this.snap(valera, 'cold', { ...s.valeraSit, yaw: -Math.PI / 2 });
      return;
    }

    if (phase === 'evening') {
      this.snap(starosta, 'sleep', s.sedoyStool);
      this.snap(leha, 'sleep', s.lehaLie);
      this.snap(valera, 'sleep', s.valeraLie);
      return;
    }
    if (phase === 'shmon') {
      this.snap(starosta, 'shmon', s.shmonSedoy);
      this.snap(leha, 'shmon', s.shmonLeha);
      this.snap(valera, 'shmon', s.shmonValera);
      return;
    }
    if (phase === 'food') {
      this.hold(starosta, 'food', s.sedoyStool, 99);
      this.hold(leha, 'food', s.stoolS, 99);
      this.hold(valera, 'food', s.stoolN, 99);
      return;
    }
    if (phase === 'walk') {
      this.hold(starosta, 'walk', s.doorQueue, 99);
      this.route(leha, 'walk', s.walkHall, [
        { x: s.aisle.x, z: s.aisle.z },
        { x: s.doorQueue.x, z: 3.42 },
        { x: 0.12, z: 3.42 },
        { x: 0.12, z: 18 },
        { x: s.walkHall.x, z: s.walkHall.z },
      ]);
      this.route(valera, 'walk', s.walkYard, [
        { x: s.aisle.x + 0.2, z: s.aisle.z },
        { x: s.doorQueue.x, z: 3.5 },
        { x: 0.22, z: 3.55 },
        { x: 0.2, z: 22 },
        { x: s.walkYard.x, z: s.walkYard.z },
      ]);
      return;
    }

    this.cycle(starosta, [{ name: 'throne', spot: s.sedoyStool, hold: 48, line: 'Седой, не глядя: «Цигарка — на стол, не в карман.»' }]);
    this.cycle(leha, [
      { name: 'bunk', spot: s.lehaSit, hold: 38 },
      { name: 'hatch', spot: s.hatch, hold: 14, line: 'Лёха тихо: «Кормушку без команды не открывай.»' },
    ]);
    this.cycle(valera, [
      { name: 'bunk', spot: s.valeraSit, hold: 34 },
      { name: 'window', spot: s.window, hold: 16, line: 'Валера: «Карты вечером, если цигарка есть.»' },
    ]);
  }

  setCellDoor(open) {
    const door = this.g.prison.interactables.find((it) => it.type === 'cell-door');
    if (!door) return;
    if (open && !door.open) {
      this.g.prison.openDoor(door);
      this.g.audio.clang();
    }
    if (!open && door.open) {
      this.g.prison.closeDoor(door);
      this.g.audio.clang();
    }
  }

  hold(n, name, spot, hold) {
    if (!n || !spot) return;
    if (n.duty === name) return;
    n.duty = name;
    n.dutyUntil = this.t + hold;
    this.g.npcs.goTo(n, spot);
  }

  route(n, name, spot, path) {
    if (!n || n.duty === name) return;
    this.hold(n, name, spot, 99);
    n.walkPath = path.slice();
  }

  snap(n, name, spot) {
    if (!n || !spot) return;
    if (n.duty === name && n.pose === (spot.lie ? 'lie' : spot.sit ? 'sit' : 'stand')) return;
    n.duty = name;
    n.dutyUntil = this.t + 99;
    n.walkPath = [];
    n.walkTo = null;
    this.g.npcs.goTo(n, spot);
    this.g.npcs.arrive(n, spot.x, spot.z);
  }

  cycle(n, steps) {
    if (!n || !steps?.length) return;
    const i = n.dutyIndex || 0;
    const step = steps[i % steps.length];
    const spot = step.spot === 'ask' ? this.frozenAsk(n) : step.spot;
    if (n.duty !== step.name) {
      n.duty = step.name;
      n.dutyUntil = this.t + step.hold;
      n.asked = false;
      if (step.spot !== 'ask') n.askFrozen = null;
      this.g.npcs.goTo(n, spot);
      return;
    }
    if (!n.walkTo && step.line && !n.asked && this.t > (n.dutyUntil || 0) - step.hold + 1.6) {
      n.asked = true;
      if (!this.g.dialog.open) this.g.subtitle(step.line);
    }
    if (!n.walkTo && this.t > (n.dutyUntil || 0)) {
      n.dutyIndex = (i + 1) % steps.length;
      n.duty = null;
      n.askFrozen = null;
    }
  }

  frozenAsk(n) {
    if (n.askFrozen) return n.askFrozen;
    n.askFrozen = this.askSpotOnce();
    return n.askFrozen;
  }

  askSpotOnce() {
    const o = this.g.prison.cellOrigin;
    const s = this.g.prison.seats;
    const p = this.g.player?.position;
    if (!p || !o) return s?.aisle;
    if (Math.abs(p.x - o.x) > 3.2 || Math.abs(p.z - o.z) > 3.5) return s?.aisle;
    const x = clamp(p.x - 0.2, o.x - 1.55, o.x + 0.35);
    const z = clamp(p.z + 1.15, o.z - 1.25, o.z + 1.15);
    return { x, z, yaw: Math.atan2(p.x - x, p.z - z), sit: false };
  }

  talkTo(id) {
    const g = this.g;
    const now = this.t;
    if ((this.talkCd[id] || 0) > now) {
      g.toast('Потом. Не приставай.');
      return true;
    }
    this.talkCd[id] = now + 8;
    if ((g.sim.malyava === 'admin' || g.sim.courtTalk === 'cell') && id !== 'starosta') {
      g.toast('Хата молчит. Так разговаривают с красным.');
      g.sim.stress = Math.min(100, g.sim.stress + 6);
      return true;
    }
    if (id === 'starosta') {
      if (g.sim.task?.id === 'cig') {
        g.unlockLook();
        g.dialog.show(CIG_ASK.who, CIG_ASK.text, CIG_ASK.options);
        g.dialog.onPick = (opt) => this.pickCig(opt);
        return true;
      }
      if (!g.sim.propiska) {
        g.starostaTalk();
        return true;
      }
      g.unlockLook();
      const sedoy =
        g.sim.day >= 7 && g.sim.phase.id === 'shmon'
          ? weekPick(g.sim, {
              red: DAY7_SEDOY_SHMON_RED,
              gone: DAY7_SEDOY_SHMON_GONE,
              found: g.sim.stash === 'bunk' ? DAY7_SEDOY_SHMON_FOUND_BUNK : DAY7_SEDOY_SHMON_FOUND,
              burn: DAY7_SEDOY_SHMON_BURN,
              hold: DAY7_SEDOY_SHMON_HOLD,
              ok: DAY7_SEDOY_SHMON,
            })
          : g.sim.day >= 6 && g.sim.phase.id === 'shmon'
            ? weekPick(g.sim, {
                red: DAY6_SEDOY_SHMON_RED,
                gone: DAY6_SEDOY_SHMON_GONE,
                found: DAY6_SEDOY_SHMON_FOUND,
                burn: DAY6_SEDOY_SHMON_BURN,
                hold: DAY6_SEDOY_SHMON_HOLD,
                ok: DAY6_SEDOY_SHMON,
              })
          : g.sim.day >= 5 && g.sim.phase.id === 'shmon'
            ? weekPick(g.sim, {
                red: DAY5_SEDOY_SHMON_RED,
                gone: DAY5_SEDOY_SHMON_GONE,
                found: DAY5_SEDOY_SHMON_FOUND,
                burn: DAY5_SEDOY_SHMON_BURN,
                hold: DAY5_SEDOY_SHMON_HOLD,
                ok: DAY5_SEDOY_SHMON,
              })
          : g.sim.day >= 7
            ? weekPick(g.sim, {
                red: WEEK_HELD_RED,
                gone: WEEK_HELD_GONE,
                found: g.sim.stash === 'bunk' ? WEEK_HELD_FOUND_BUNK : WEEK_HELD_FOUND,
                burn: WEEK_HELD_BURN,
                hold: holdStash(g.sim, { pocket: WEEK_HELD_HOLD, wash: WEEK_HELD_HOLD_WASH, bunk: WEEK_HELD_HOLD_BUNK }),
                ok: WEEK_HELD,
              })
          : g.sim.day >= 6 && g.sim.phase.id === 'food'
            ? weekPick(g.sim, {
                red: DAY6_FOOD_RED,
                gone: DAY6_FOOD_GONE,
                found: DAY6_FOOD_FOUND,
                burn: DAY6_FOOD_BURN,
                hold: holdStash(g.sim, { pocket: DAY6_FOOD_HOLD, wash: DAY6_FOOD_HOLD_WASH, bunk: DAY6_FOOD_HOLD_BUNK }),
                ok: DAY6_FOOD,
              })
          : g.sim.day >= 6
            ? weekPick(g.sim, {
                red: DAY6_SEDOY_RED,
                gone: DAY6_SEDOY_GONE,
                found: DAY6_SEDOY_FOUND,
                burn: DAY6_SEDOY_BURN,
                hold: holdStash(g.sim, { pocket: DAY6_SEDOY_HOLD, wash: DAY6_SEDOY_HOLD_WASH, bunk: DAY6_SEDOY_HOLD_BUNK }),
                ok: DAY6_SEDOY,
              })
          : g.sim.day >= 5 && g.sim.courtTalk === 'cell'
          ? DAY5_BACK_CELL
          : g.sim.day >= 5 && g.sim.courtTalk === 'silent'
            ? DAY5_BACK_SILENT
            : g.sim.day >= 5 && g.sim.courtTalk === 'self'
              ? DAY5_BACK_SELF
              : g.sim.day >= 5 && g.sim.malyava === 'gone'
                ? DAY5_COURT_GONE
              : g.sim.day >= 5
                ? DAY5_COURT
                : g.sim.day >= 4 && g.sim.phase.id === 'shmon'
                  ? day4ShmonTalk(g.sim, {
                      red: DAY4_SEDOY_SHMON_RED,
                      found: DAY4_SEDOY_SHMON_FOUND,
                      burn: DAY4_SEDOY_SHMON_BURN,
                      wash: DAY4_SEDOY_SHMON_WASH,
                      wait: DAY4_SEDOY_SHMON_WAIT,
                    })
                : g.sim.day >= 4 && g.sim.phase.id === 'food'
                  ? g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
                    ? DAY4_FOOD_RED
                    : !g.sim.malyava
                      ? DAY4_FOOD_WAIT
                      : g.sim.malyava === 'found'
                        ? DAY4_FOOD_FOUND
                        : g.sim.malyava === 'burn'
                          ? DAY4_FOOD_BURN
                          : g.sim.malyava === 'hold' && g.sim.teaPaid
                            ? holdStash(g.sim, { pocket: DAY4_FOOD_HOLD, wash: DAY4_FOOD_HOLD_WASH, bunk: DAY4_FOOD_HOLD_BUNK })
                            : DAY4_FOOD
                : g.sim.day >= 3 && g.sim.phase.id === 'shmon'
                  ? g.sim.malyava === 'admin' || g.sim.path === 'red'
                    ? DAY3_SEDOY_SHMON_RED
                    : g.sim.malyava === 'found'
                      ? g.sim.stash === 'bunk'
                        ? DAY3_SEDOY_SHMON_FOUND_BUNK
                        : DAY3_SEDOY_SHMON_FOUND
                      : g.sim.malyava === 'hold' && g.sim.stash === 'wash'
                        ? DAY3_SEDOY_SHMON_WASH
                        : g.sim.malyava === 'hold'
                          ? DAY3_SEDOY_SHMON_HOLD
                          : g.sim.malyava === 'burn'
                            ? DAY3_SEDOY_SHMON_BURN
                            : !g.sim.malyava
                              ? DAY3_SEDOY_SHMON_HATCH
                              : g.sim.stash === 'bunk'
                                ? DAY3_SEDOY_SHMON_CAUGHT
                                : DAY3_SEDOY_SHMON
                : g.sim.day >= 3
                  ? g.sim.malyava === 'admin' || g.sim.path === 'red'
                    ? DAY3_MORNING_RED
                    : g.sim.malyava === 'found'
                      ? g.sim.stash === 'bunk'
                        ? DAY3_MORNING_FOUND_BUNK
                        : DAY3_MORNING_FOUND
                      : g.sim.malyava === 'hold'
                        ? holdStash(g.sim, { pocket: DAY3_MORNING_HOLD, wash: DAY3_MORNING_HOLD_WASH, bunk: DAY3_MORNING_HOLD_BUNK })
                        : g.sim.malyava === 'burn'
                          ? DAY3_MORNING_BURN
                          : g.sim.stash === 'bunk'
                            ? DAY3_MORNING_CAUGHT
                            : DAY3_MORNING
                : g.sim.day >= 2 && g.sim.phase.id === 'shmon'
                  ? g.sim.stash === 'bunk'
                    ? DAY2_SEDOY_SHMON_CAUGHT
                    : g.sim.stash === 'wash'
                      ? DAY2_SEDOY_SHMON_WASH
                      : DAY2_SEDOY_SHMON
                : g.sim.day >= 2
                  ? g.sim.stash === 'bunk'
                    ? DAY2_SEDOY_CAUGHT
                    : g.sim.stash === 'wash'
                      ? DAY2_SEDOY_WASH
                      : DAY2_SEDOY
                  : TALK_STAROSTA;
      g.dialog.show(sedoy.who, sedoy.text, sedoy.options);
      g.dialog.onPick = (opt) => this.applyTalk(opt);
      return true;
    }
    if (id === 'cellmate') {
      g.unlockLook();
      const leha =
        g.sim.day >= 7 && g.sim.phase.id === 'shmon'
          ? weekPick(g.sim, {
              red: DAY7_LEHA_SHMON_RED,
              gone: DAY7_LEHA_SHMON_GONE,
              found: g.sim.stash === 'bunk' ? DAY7_LEHA_SHMON_FOUND_BUNK : DAY7_LEHA_SHMON_FOUND,
              burn: DAY7_LEHA_SHMON_BURN,
              hold: DAY7_LEHA_SHMON_HOLD,
              ok: DAY7_LEHA_SHMON,
            })
          : g.sim.day >= 6 && g.sim.phase.id === 'shmon'
          ? weekPick(g.sim, {
              red: DAY6_LEHA_SHMON_RED,
              gone: DAY6_LEHA_SHMON_GONE,
              found: g.sim.stash === 'bunk' ? DAY6_LEHA_SHMON_FOUND_BUNK : DAY6_LEHA_SHMON_FOUND,
              burn: DAY6_LEHA_SHMON_BURN,
              hold: DAY6_LEHA_SHMON_HOLD,
              ok: DAY6_LEHA_SHMON,
            })
          : g.sim.day >= 5 && g.sim.phase.id === 'shmon'
          ? weekPick(g.sim, {
              red: DAY5_LEHA_SHMON_RED,
              gone: DAY5_LEHA_SHMON_GONE,
              found: g.sim.stash === 'bunk' ? DAY5_LEHA_SHMON_FOUND_BUNK : DAY5_LEHA_SHMON_FOUND,
              burn: DAY5_LEHA_SHMON_BURN,
              hold: DAY5_LEHA_SHMON_HOLD,
              ok: DAY5_LEHA_SHMON,
            })
          : g.sim.day >= 7
          ? weekPick(g.sim, {
              red: DAY7_LEHA_RED,
              gone: DAY7_LEHA_GONE,
              found: DAY7_LEHA_FOUND,
              burn: DAY7_LEHA_BURN,
              hold: holdStash(g.sim, { pocket: DAY7_LEHA_HOLD, wash: DAY7_LEHA_HOLD_WASH, bunk: DAY7_LEHA_HOLD_BUNK }),
              ok: DAY7_LEHA,
            })
          : g.sim.day >= 6
          ? weekPick(g.sim, {
              red: DAY6_NIGHT_RED,
              gone: DAY6_NIGHT_GONE,
              found: g.sim.stash === 'bunk' ? DAY6_NIGHT_FOUND_BUNK : DAY6_NIGHT_FOUND,
              burn: DAY6_NIGHT_BURN,
              hold: holdStash(g.sim, { pocket: DAY6_NIGHT_HOLD, wash: DAY6_NIGHT_HOLD_WASH, bunk: DAY6_NIGHT_HOLD_BUNK }),
              ok: DAY6_NIGHT,
            })
          : g.sim.day >= 5 && (g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin')
          ? DAY5_WAKE_RED
          : g.sim.day >= 5 && g.sim.malyava === 'gone'
          ? DAY5_WAKE_GONE
          : g.sim.day >= 5 && g.sim.malyava === 'found'
          ? DAY5_WAKE_FOUND
          : g.sim.day >= 5 && g.sim.malyava === 'burn'
          ? DAY5_WAKE_BURN
          : g.sim.day >= 5 && g.sim.malyava === 'hold'
          ? holdStash(g.sim, { pocket: DAY5_WAKE_HOLD, wash: DAY5_WAKE_HOLD_WASH, bunk: DAY5_WAKE_HOLD_BUNK })
          : g.sim.day >= 5
          ? DAY5_WAKE
          : g.sim.day >= 4 && g.sim.phase.id === 'shmon'
            ? day4ShmonTalk(g.sim, {
                red: DAY4_LEHA_SHMON_RED,
                found: g.sim.stash === 'bunk' ? DAY4_LEHA_SHMON_FOUND_BUNK : DAY4_LEHA_SHMON_FOUND,
                burn: DAY4_LEHA_SHMON_BURN,
                wash: DAY4_LEHA_SHMON_WASH,
                wait: DAY4_LEHA_SHMON_WAIT,
              })
          : g.sim.day >= 4
            ? g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
              ? DAY4_LEHA_RED
              : !g.sim.malyava
                ? DAY4_NIGHT_WAIT
                : g.sim.malyava === 'found'
                  ? g.sim.stash === 'bunk'
                    ? DAY4_LEHA_FOUND_BUNK
                    : DAY4_LEHA_FOUND
                  : g.sim.malyava === 'burn'
                    ? DAY4_LEHA_BURN
                    : g.sim.malyava === 'hold' && g.sim.teaPaid
                      ? holdStash(g.sim, { pocket: DAY4_LEHA_HOLD, wash: DAY4_LEHA_HOLD_WASH, bunk: DAY4_LEHA_HOLD_BUNK })
                      : DAY4_LEHA
          : g.sim.day >= 3 && g.sim.phase.id === 'food'
            ? !g.sim.malyava
              ? DAY3_FOOD
              : g.sim.malyava === 'hold'
                ? holdStash(g.sim, { pocket: DAY3_FOOD_HOLD, wash: DAY3_FOOD_HOLD_WASH, bunk: DAY3_FOOD_HOLD_BUNK })
                : g.sim.malyava === 'burn'
                  ? DAY3_FOOD_BURN
                  : g.sim.malyava === 'found'
                    ? g.sim.stash === 'bunk'
                      ? DAY3_LEHA_FOUND_BUNK
                      : DAY3_LEHA_FOUND
                    : g.sim.malyava === 'admin' || g.sim.path === 'red'
                      ? DAY3_LEHA_RED
                      : DAY3_FOOD
          : g.sim.day >= 3 && g.sim.phase.id === 'evening'
            ? g.sim.malyava === 'admin' || g.sim.path === 'red'
              ? DAY3_NIGHT_RED
              : g.sim.malyava === 'found'
                ? g.sim.stash === 'bunk'
                  ? DAY3_NIGHT_FOUND_BUNK
                  : DAY3_NIGHT_FOUND
                : g.sim.malyava === 'hold'
                  ? holdStash(g.sim, { pocket: DAY3_NIGHT_HOLD, wash: DAY3_NIGHT_HOLD_WASH, bunk: DAY3_NIGHT_HOLD_BUNK })
                  : g.sim.malyava === 'burn'
                    ? DAY3_NIGHT_BURN
                    : !g.sim.malyava
                      ? DAY3_NIGHT_WAIT
                      : DAY3_NIGHT
          : g.sim.day >= 3 && g.sim.phase.id === 'shmon'
            ? g.sim.malyava === 'admin' || g.sim.path === 'red'
              ? DAY3_LEHA_SHMON_RED
              : g.sim.malyava === 'found'
                ? g.sim.stash === 'bunk'
                  ? DAY3_LEHA_SHMON_FOUND_BUNK
                  : DAY3_LEHA_SHMON_FOUND
                : g.sim.malyava === 'hold' && g.sim.stash === 'wash'
                  ? DAY3_LEHA_SHMON_WASH
                  : g.sim.malyava === 'hold'
                    ? DAY3_LEHA_SHMON_HOLD
                    : g.sim.malyava === 'burn'
                      ? DAY3_LEHA_SHMON_BURN
                      : !g.sim.malyava
                        ? DAY3_LEHA_SHMON_HATCH
                        : g.sim.stash === 'bunk'
                          ? DAY3_LEHA_SHMON_CAUGHT
                          : DAY3_LEHA_SHMON
          : g.sim.day >= 3
            ? g.sim.malyava === 'admin' || g.sim.path === 'red'
              ? DAY3_LEHA_RED
              : g.sim.malyava === 'found'
                ? g.sim.stash === 'bunk'
                  ? DAY3_LEHA_FOUND_BUNK
                  : DAY3_LEHA_FOUND
                : g.sim.malyava === 'hold'
                  ? holdStash(g.sim, { pocket: DAY3_LEHA_HOLD, wash: DAY3_LEHA_HOLD_WASH, bunk: DAY3_LEHA_HOLD_BUNK })
                  : g.sim.malyava === 'burn'
                    ? DAY3_LEHA_BURN
                    : g.sim.stash === 'bunk'
                      ? DAY3_LEHA_CAUGHT
                      : DAY3_LEHA
            : g.sim.day >= 2 && g.sim.phase.id === 'shmon'
              ? g.sim.stash === 'bunk'
                ? DAY2_LEHA_SHMON_CAUGHT
                : g.sim.stash === 'wash'
                  ? DAY2_LEHA_SHMON_WASH
                  : DAY2_LEHA_SHMON
            : g.sim.day >= 2 && g.sim.phase.id === 'food'
              ? g.sim.stash === 'bunk'
                ? DAY2_FOOD_CAUGHT
                : g.sim.stash === 'wash'
                  ? DAY2_FOOD_WASH
                  : DAY2_FOOD
            : g.sim.day >= 2 && g.sim.phase.id === 'evening'
              ? g.sim.stash === 'bunk'
                ? DAY2_NIGHT_CAUGHT
                : g.sim.stash === 'wash'
                  ? DAY2_NIGHT_WASH
                  : DAY2_NIGHT
            : g.sim.day >= 2
              ? g.sim.stash === 'bunk'
                ? DAY2_WAKE_BUNK
                : g.sim.stash === 'wash'
                  ? DAY2_WAKE_WASH
                  : DAY2_WAKE
              : TALK_LEHA;
      g.dialog.show(leha.who, leha.text, leha.options);
      g.dialog.onPick = (opt) => this.applyTalk(opt);
      return true;
    }
    if (id === 'bunk-bro') {
      g.unlockLook();
      const valera =
        g.sim.phase.id === 'walk' && g.sim.day >= 7
          ? weekPick(g.sim, {
              red: DAY7_WALK_RED,
              gone: DAY7_WALK_GONE,
              found: DAY7_WALK_FOUND,
              burn: DAY7_WALK_BURN,
              hold: holdStash(g.sim, { pocket: DAY7_WALK_HOLD, wash: DAY7_WALK_HOLD_WASH, bunk: DAY7_WALK_HOLD_BUNK }),
              ok: DAY7_WALK,
            })
          : g.sim.phase.id === 'walk' && g.sim.day >= 6
          ? g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
            ? DAY6_WALK_RED
            : g.sim.malyava === 'gone'
            ? DAY6_WALK_GONE
            : g.sim.malyava === 'found'
            ? DAY6_WALK_FOUND
            : g.sim.malyava === 'burn'
            ? DAY6_WALK_BURN
            : g.sim.malyava === 'hold'
            ? holdStash(g.sim, { pocket: DAY6_WALK_HOLD, wash: DAY6_WALK_HOLD_WASH, bunk: DAY6_WALK_HOLD_BUNK })
            : DAY6_WALK
          : g.sim.phase.id === 'walk' && g.sim.day >= 5
          ? g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
            ? DAY5_WALK_RED
            : g.sim.malyava === 'gone'
            ? DAY5_WALK_GONE
            : g.sim.malyava === 'found'
            ? DAY5_WALK_FOUND
            : g.sim.malyava === 'burn'
            ? DAY5_WALK_BURN
            : g.sim.malyava === 'hold'
            ? holdStash(g.sim, { pocket: DAY5_WALK_HOLD, wash: DAY5_WALK_HOLD_WASH, bunk: DAY5_WALK_HOLD_BUNK })
            : DAY5_WALK
          : g.sim.phase.id === 'walk' && g.sim.day >= 4
            ? g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
              ? DAY4_WALK_RED
              : !g.sim.malyava
                ? DAY4_WALK_WAIT
                : g.sim.malyava === 'found'
                  ? DAY4_WALK_FOUND
                  : g.sim.malyava === 'burn'
                    ? DAY4_WALK_BURN
                    : g.sim.malyava === 'hold' && g.sim.teaPaid
                      ? holdStash(g.sim, { pocket: DAY4_WALK_PAID, wash: DAY4_WALK_PAID_WASH, bunk: DAY4_WALK_PAID_BUNK })
                      : DAY4_WALK
            : g.sim.phase.id === 'walk' && g.sim.day === 3 && (g.sim.malyava === 'admin' || g.sim.path === 'red')
              ? DAY3_WALK_RED
              : g.sim.phase.id === 'walk' && g.sim.day === 3 && g.sim.malyava === 'hold'
                ? holdStash(g.sim, { pocket: DAY3_WALK_HOLD, wash: DAY3_WALK_HOLD_WASH, bunk: DAY3_WALK_HOLD_BUNK })
                : g.sim.phase.id === 'walk' && g.sim.day === 3 && g.sim.malyava === 'burn'
                  ? DAY3_WALK_BURN
                  : g.sim.phase.id === 'walk' && g.sim.day === 3 && g.sim.malyava === 'found'
                    ? g.sim.stash === 'bunk'
                      ? DAY3_WALK_FOUND_BUNK
                      : DAY3_WALK_FOUND
                    : g.sim.phase.id === 'walk' && g.sim.day === 3 && !g.sim.malyava
                      ? DAY3_WALK_WAIT
                      : g.sim.phase.id === 'walk' && g.sim.day === 3
                        ? DAY3_WALK
                    : g.sim.day >= 2 && g.sim.phase.id === 'walk'
                    ? g.sim.stash === 'bunk'
                      ? DAY2_YARD_CAUGHT
                      : g.sim.stash === 'wash'
                        ? DAY2_YARD_WASH
                        : DAY2_YARD
                    : valeraInCell(g.sim);
      g.dialog.show(valera.who, valera.text, valera.options);
      g.dialog.onPick = (opt) => {
        this.applyTalk(opt);
        if (opt.minigame === 'cards') {
          g.minigames.playCards();
          this.completeTask('cards');
        }
      };
      return true;
    }
    return false;
  }

  pickCig(opt) {
    const g = this.g;
    g.sim.shift(opt.black, opt.red, opt.men);
    if (opt.takeCig) {
      if (g.sim.inv.cigs <= 0) {
        g.toast('Цигарки нет. Седой это тоже запомнил.');
        g.sim.shift(0, 0, 0);
        g.sim.stress = Math.min(100, g.sim.stress + 8);
      } else {
        g.sim.inv.cigs -= 1;
        g.sim.rep += 2;
        g.toast(opt.reply);
      }
    } else {
      g.toast(opt.reply);
    }
    this.completeTask('cig');
  }

  applyTalk(opt) {
    const g = this.g;
    g.sim.shift(opt.black || 0, opt.red || 0, opt.men || 0);
    if (opt.hope) g.sim.hope = Math.min(100, g.sim.hope + opt.hope);
    if (opt.stress) g.sim.stress = Math.max(0, Math.min(100, g.sim.stress + opt.stress));
    if (opt.heat) g.sim.heat = Math.max(0, Math.min(100, g.sim.heat + opt.heat));
    if (opt.stash) g.sim.stash = opt.stash;
    if (opt.malyava) g.sim.malyava = opt.malyava;
    if (opt.courtTalk) g.sim.courtTalk = opt.courtTalk;
    if (opt.passTea && g.sim.inv.tea > 0) {
      g.sim.inv.tea -= 1;
      g.sim.rep += 1;
      g.sim.teaPaid = true;
    }
    g.toast(opt.reply);
  }

  useHatch() {
    const g = this.g;
    g.unlockLook();
    if (g.sim.phase.id === 'food' && g.sim.stage === 'life') {
      g.sim.inv.food += 1;
      g.sim.attended = true;
      g.toast('Пайка через кормушку. Тёплая ещё, пока не остыла.');
      g.subtitle('Седой: «Ешь. В сортир — после.»');
      return;
    }
    if (hatchReady(g.sim)) {
      const pack = g.sim.phase.id === 'shmon' ? DAY3_NOTE_SHMON : DAY3_NOTE;
      g.dialog.show(pack.who, pack.text, pack.options);
      g.dialog.onPick = (opt) => {
        this.applyTalk(opt);
        if (opt.malyava === 'admin') {
          g.sim.inv.food += 1;
          g.sim.shift(0, 1, 0);
        }
      };
      return;
    }
    if (g.sim.malyava === 'gone') {
      g.dialog.show(HATCH_GONE.who, HATCH_GONE.text, HATCH_GONE.options);
      g.dialog.onPick = (opt) => this.applyTalk(opt);
      return;
    }
    if (g.sim.day >= 4 && g.sim.malyava === 'hold' && !g.sim.teaPaid) {
      g.dialog.show(DAY4_HATCH.who, DAY4_HATCH.text, DAY4_HATCH.options);
      g.dialog.onPick = (opt) => this.applyTalk(opt);
      return;
    }
    g.dialog.show(HATCH_TALK.who, HATCH_TALK.text, HATCH_TALK.options);
    g.dialog.onPick = (opt) => {
      this.applyTalk(opt);
      if (opt.passTea && g.sim.inv.tea > 0) {
        g.sim.inv.tea -= 1;
        g.sim.shift(1, 0, 0);
        g.sim.rep += 1;
        g.toast('Чай ушёл в щель. С той стороны кивнули.');
      }
      this.completeTask('hatch');
    };
  }

  useWindow() {
    const g = this.g;
    g.unlockLook();
    const pack =
      g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
        ? WINDOW_TALK_RED
        : g.sim.malyava === 'gone'
          ? WINDOW_TALK_GONE
          : g.sim.malyava === 'hold'
            ? WINDOW_TALK_HOLD
            : WINDOW_TALK;
    g.dialog.show(pack.who, pack.text, pack.options);
    g.dialog.onPick = (opt) => {
      this.applyTalk(opt);
      this.completeTask('window');
    };
  }

  useKettle() {
    const g = this.g;
    g.unlockLook();
    const pack =
      g.sim.courtTalk === 'cell' || g.sim.malyava === 'admin'
        ? KETTLE_TALK_RED
        : g.sim.malyava === 'hold'
          ? KETTLE_TALK_HOLD
          : KETTLE_TALK;
    g.dialog.show(pack.who, pack.text, pack.options);
    g.dialog.onPick = (opt) => {
      if (opt.malyava === 'burn') {
        this.applyTalk(opt);
        this.completeTask('kettle');
        return;
      }
      if (opt.brew) {
        if (g.sim.inv.tea <= 0) {
          g.toast('Чай кончился. Чифир из воздуха не варят.');
        } else {
          g.sim.inv.tea -= 1;
          g.sim.stress = Math.max(0, g.sim.stress - 12);
          g.sim.hunger = Math.min(100, g.sim.hunger + 8);
          g.sim.shift(1, 0, 0);
          g.toast(opt.reply);
        }
      } else {
        this.applyTalk(opt);
      }
      this.completeTask('kettle');
    };
  }
}

function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}
