import type {
  Boss,
  Clothes,
  Daily,
  Job,
  ShopOffer,
  Talent,
  Tattoo,
  TattooCat,
  Zone,
} from "./types";

/** Classic 2011–13 energy tables (turagino / infotyuryaga). Not Telegram-wiki retunes. */
export const ENERGY_TICK_MS = 5 * 60 * 1000;
export const ENERGY_CAP_BASE = 50;
export const BUSINESS_MS = 8 * 60 * 60 * 1000;
export const RAID_MS = 8 * 60 * 60 * 1000;
export const HODKA_AUTH = 100;
export const BIZ_UPGRADE_PAP = 180;
export const NAEZD_COST = 50;
export const NAEZD_AUTH = 3000;
export const NIGHT_TATTOOS = 16; // original ~100; catalog is smaller in v1
export const WORKSHOP_LEVEL = 50;
export const HIDDEN_AUTH = 4000;
export const YARD_STEAL_CAP = 300;
export const PODGREV_CAP = 50;
export const TITLE = "СРОК";

export const CAT_LABEL: Record<TattooCat, string> = {
  patsan: "Пацанские",
  fraer: "Фраерские",
  blat: "Блатные",
  zhigan: "Жиганские",
  avtor: "Дворовые",
  ponto: "Понтовые",
};

const COSTS = [10, 8, 7, 6, 5, 12, 9, 4, 11, 15, 3];

function factorize(total: number): { energy: number; repeats: number } {
  for (const e of COSTS) {
    if (total >= e * 2 && total % e === 0) {
      const r = total / e;
      if (r <= 28) return { energy: e, repeats: r };
    }
  }
  for (let e = 4; e <= 16; e++) {
    if (total % e === 0) {
      const r = total / e;
      if (r >= 2 && r <= 32) return { energy: e, repeats: r };
    }
  }
  return { energy: 1, repeats: total };
}

function pack(
  zoneId: string,
  shift: "day" | "night",
  titles: [string, string][],
  target: number,
  papPer: number,
  night: boolean,
): Job[] {
  const n = titles.length;
  const jobs: Job[] = [];
  let used = 0;
  const pref = [5, 6, 7, 8, 10, 8, 6];
  for (let i = 0; i < n; i++) {
    const leftJobs = n - i;
    const leftEnergy = target - used;
    let energy: number;
    let repeats: number;
    if (i === n - 1) {
      ({ energy, repeats } = factorize(leftEnergy));
    } else {
      const share = Math.round(leftEnergy / leftJobs);
      energy = pref[i % pref.length];
      repeats = Math.max(3, Math.round(share / energy));
      const minLeave = 10 * (leftJobs - 1);
      while (energy * repeats > leftEnergy - minLeave && repeats > 2) repeats--;
    }
    used += energy * repeats;
    const [title, blurb] = titles[i];
    jobs.push({
      id: `${zoneId}-${shift}-${i}`,
      title,
      blurb,
      energy,
      repeats,
      authority: night ? 2 + (i % 2) : 2 + (i % 3),
      pap: night ? Math.max(1, Math.round(energy * papPer * 0.35)) : Math.max(1, Math.round(energy * papPer)),
      respect: night ? 0 : 1 + (i % 3),
      hate: night ? 3 + (i % 8) : 0,
      sugar: night && i % 3 === 2 ? 1 : 0,
      loot: night ? 0.1 : 0.08,
    });
  }
  if (used !== target) {
    const last = jobs[jobs.length - 1];
    const diff = target - used;
    if (diff !== 0) {
      const fix = factorize(last.energy * last.repeats + diff);
      last.energy = fix.energy;
      last.repeats = fix.repeats;
    }
  }
  return jobs;
}

export const ZONES: Zone[] = [
  {
    id: "butyrka",
    name: "Бутырка",
    city: "Москва",
    blurb: "Стартовая хата. Папиросы тут капают лучше всего.",
    tattoosNeeded: 0,
    dayEnergy: 190,
    nightEnergy: 343,
    phoneParts: 4,
    escapeParts: 3,
    businessName: "Лавка у проходной",
    businessKind: "pap",
    day: pack(
      "butyrka",
      "day",
      [
        ["Качнуть штангу у турников", "Дворовый жим. Спину не гни."],
        ["Сбегать за баландой", "Котелок горячий — уважуха тёплая."],
        ["Помочь на раздаче", "Повар орёт, ты молчишь и режешь лук."],
        ["Постоять на стрёме у бани", "Кто-то моется, кто-то сторожит."],
        ["Раскидать малявы по хатам", "Бумага ходит быстрее ног."],
        ["Прижучить фраера во дворе", "Пусть знает, где двор."],
        ["Подмести проходную", "Чистота — тоже ход."],
      ],
      190,
      1.053,
      false,
    ),
    night: pack(
      "butyrka",
      "night",
      [
        ["Подпилить пруток у окна", "Тихо. Напильник поёт."],
        ["Запереть дежурного в клетушке", "Ключ на пол, дверь на щеколду."],
        ["Снять почётные фотки со щита", "Пусть смотрят пустую фанеру."],
        ["Опрокинуть ведро у служебки", "Запах — тоже аргумент."],
        ["Задуть свет в коридоре", "Тьма любит своих."],
        ["Кинуть камешек в будку", "Сторож вскочит — ты уже в тени."],
        ["Шёпотом собрать народ", "Ночь любит компанию."],
      ],
      343,
      0.4,
      true,
    ),
  },
  {
    id: "presnya",
    name: "Красная Пресня",
    city: "Москва",
    blurb: "Тесно и шумно. Папиросы хуже, чем в Бутырке — не зависай.",
    tattoosNeeded: 3,
    dayEnergy: 380,
    nightEnergy: 461,
    phoneParts: 0,
    escapeParts: 0,
    businessName: "Чайная",
    businessKind: "pap",
    day: pack(
      "presnya",
      "day",
      [
        ["Таскать баулы с бельём", "Мокрое тяжелее сухого."],
        ["Сдать весточку на кухню", "Соль дороже золота."],
        ["Починить табурет в хате", "Гвоздь кривой, но держит."],
        ["Сыграть в домино на папиросу", "Кости щёлкают, двор слушает."],
        ["Провести новичка до бани", "Чтоб не заблудился и не зазнался."],
        ["Подать воду на этаж", "Ведро на этаж — уважение в карман."],
        ["Постоять у калитки", "Кто входит — ты первый видишь."],
      ],
      380,
      0.72,
      false,
    ),
    night: pack(
      "presnya",
      "night",
      [
        ["Смазать петли камеры", "Чтоб ночью не скрипело."],
        ["Перекинуть нитку через двор", "Связь без проводов."],
        ["Замазать глазок кашей", "Пусть смотрят на манную крупу."],
        ["Спугнуть дежурного стуком", "Он бежит налево — ты направо."],
        ["Спрятать лом в матрас", "На чёрный день."],
        ["Обойти двор по тени", "Ночные маршруты запоминают ноги."],
      ],
      461,
      0.35,
      true,
    ),
  },
  {
    id: "sofiika",
    name: "Софийка",
    city: "Москва",
    blurb: "Маленькая, злая. Часто выпадала из гайдов новичков.",
    tattoosNeeded: 6,
    dayEnergy: 346,
    nightEnergy: 446,
    phoneParts: 0,
    escapeParts: 0,
    businessName: "Сапожная",
    businessKind: "pap",
    day: pack(
      "sofiika",
      "day",
      [
        ["Шить тапки из тряпья", "Подошва из старого ремня."],
        ["Носить письма в соседний корпус", "Ноги знают дырки в заборе."],
        ["Мешать известь", "Белые руки — не наш стиль."],
        ["Сторожить сушку у окна", "Бельё воруют чаще папирос."],
        ["Растащить слухи по этажам", "Язык — тоже инструмент."],
        ["Помочь костоправу с бинтами", "Он молчит — ты тоже."],
      ],
      346,
      0.8,
      false,
    ),
    night: pack(
      "sofiika",
      "night",
      [
        ["Срезать печать с ящика", "Тихо, воск крошится."],
        ["Протолкнуть свёрток в вентиляцию", "Тяга сама донесёт."],
        ["Залить замок водой", "К утру прихватит."],
        ["Перекликнуться через стену", "Двойной стук — свой."],
        ["Снять фонарь с крюка", "Пусть коридор ослепнет."],
      ],
      446,
      0.32,
      true,
    ),
  },
  {
    id: "kresty",
    name: "Кресты",
    city: "Петербург",
    blurb: "Длинные коридоры. Отсюда открываются ночные разборки с вертухаями.",
    tattoosNeeded: 10,
    dayEnergy: 305,
    nightEnergy: 511,
    phoneParts: 6,
    escapeParts: 4,
    businessName: "Столярка",
    businessKind: "pap",
    day: pack(
      "kresty",
      "day",
      [
        ["Строгать рейки", "Стружка в волосах — знак мастера."],
        ["Сносить стружку во двор", "Путь знакомый до сантиметра."],
        ["Подсобить на кухне с тестом", "Мука везде, даже в карманах."],
        ["Починить полку в хате", "Гвозди считаем."],
        ["Провести экскурсию новичку", "Кресты любят путать."],
        ["Собрать очередь в баню", "Кто первый — тот чистый."],
      ],
      305,
      0.85,
      false,
    ),
    night: pack(
      "kresty",
      "night",
      [
        ["Подпилить напильником решётку", "Пруток тонкий, терпение толстое."],
        ["Запереть надзирателя", "Щеколда снаружи — поэзия."],
        ["Порезать фотки на доске", "Пустые рамки смотрят лучше."],
        ["Зачмырить охранника шёпотом", "Слова бьют тише кулака."],
        ["Опрокинуть парашу к служебке", "Классика жанра."],
        ["Угрожать охраннику расправой", "Ночью храбрость дешевле."],
        ["Травануть чай в курилке", "Пусть заварится не то."],
      ],
      511,
      0.3,
      true,
    ),
  },
  {
    id: "vladimir",
    name: "Владимирский централ",
    city: "Владимир",
    blurb: "Песня знакомая, двор чужой.",
    tattoosNeeded: 14,
    dayEnergy: 507,
    nightEnergy: 767,
    phoneParts: 6,
    escapeParts: 4,
    businessName: "Прачечная",
    businessKind: "pap",
    day: pack(
      "vladimir",
      "day",
      [
        ["Таскать котлы", "Чугун не прощает спину."],
        ["Развесить простыни", "Белая стена на верёвке."],
        ["Точить ножи на кухне", "Остриё смотрит вниз."],
        ["Мести плац", "Камешки знают твоё имя."],
        ["Носить дрова в кочегарку", "Зима длинная."],
        ["Чинить кран в умывалке", "Капает — нервы капают громче."],
        ["Сидеть на баулах у КПП", "Жди и смотри."],
      ],
      507,
      0.7,
      false,
    ),
    night: pack(
      "vladimir",
      "night",
      [
        ["Срезать засов ниткой", "Терпение вместо лома."],
        ["Перекинуть крючок на крышу", "Крыша ближе, чем кажется."],
        ["Залить чернила в журнал", "Пусть пишут пальцем."],
        ["Снять колодку с сарая", "Инструмент любит ночь."],
        ["Провести своих двором", "Маршрут без фонарей."],
        ["Заткнуть свисток тряпкой", "Тишина — союзник."],
      ],
      767,
      0.28,
      true,
    ),
  },
  {
    id: "ugolki",
    name: "Угольки",
    city: "Север",
    blurb: "Появились в таблицах 2013-го. Копоть и короткие дни.",
    tattoosNeeded: 18,
    dayEnergy: 555,
    nightEnergy: 468,
    phoneParts: 0,
    escapeParts: 0,
    businessName: "Кочегарка",
    businessKind: "pap",
    day: pack(
      "ugolki",
      "day",
      [
        ["Кидать уголь в топку", "Чёрные руки, белые зубы."],
        ["Чистить колосники", "Жар не спрашивает."],
        ["Таскать шлак во двор", "Серый снег под ногами."],
        ["Латать рукавицы", "Дырка жжёт быстрее огня."],
        ["Дежурить у котла", "Давление — характер."],
        ["Разносить чай кочегарам", "Кружка за кружку."],
      ],
      555,
      0.65,
      false,
    ),
    night: pack(
      "ugolki",
      "night",
      [
        ["Приглушить тягу", "Пусть котёл чихнет."],
        ["Вынести лом в тень", "Металл холодный, дело горячее."],
        ["Запереть зольник", "Ключ в саже."],
        ["Стучать по трубам азбукой", "Двор слышит лучше охраны."],
        ["Спрятать свёрток в угле", "Чёрное в чёрном."],
      ],
      468,
      0.3,
      true,
    ),
  },
  {
    id: "matrosskaya",
    name: "Матросская тишина",
    city: "Москва",
    blurb: "Тишина тут только в названии.",
    tattoosNeeded: 22,
    dayEnergy: 729,
    nightEnergy: 729,
    phoneParts: 5,
    escapeParts: 7,
    businessName: "Швейка",
    businessKind: "pap",
    day: pack(
      "matrosskaya",
      "day",
      [
        ["Строчить робы", "Игла быстрее языка."],
        ["Пришивать номера", "Цифра на груди — не имя."],
        ["Гладить воротнички", "Пар в лицо, характер в кулак."],
        ["Носить рулоны", "Ткань тяжёлая, как слухи."],
        ["Сидеть на приёмке", "Считаем нитки, не людей."],
        ["Чинить сетку на окне", "Ячейка в ячейку."],
        ["Развозить катушки", "По этажам, без лишних слов."],
      ],
      729,
      0.6,
      false,
    ),
    night: pack(
      "matrosskaya",
      "night",
      [
        ["Распороть шов с тайником", "Нитка знает секрет."],
        ["Отключить утюг в щитке", "Искра — и темно."],
        ["Перекинуть свёрток в цех", "Окно узкое, рука узкая."],
        ["Смазать решётку мылом", "Чтобы не скрипела."],
        ["Собрать тихий круг", "Шёпот вместо собрания."],
        ["Замкнуть коридор на крючок", "Пусть ходят в обход."],
      ],
      729,
      0.28,
      true,
    ),
  },
  {
    id: "pyatak",
    name: "Вологодский пятак",
    city: "Остров",
    blurb: "Вода кругом. Двор маленький, понятия большие.",
    tattoosNeeded: 28,
    dayEnergy: 729,
    nightEnergy: 729,
    phoneParts: 7,
    escapeParts: 5,
    businessName: "Рыбный сарай",
    businessKind: "respect",
    day: pack(
      "pyatak",
      "day",
      [
        ["Чистить сети", "Чешуя везде."],
        ["Солить бочки", "Соль ест руки."],
        ["Таскать лёд", "Скользко и честно."],
        ["Латать лодку", "На берегу, не на воде."],
        ["Сушить верёвки", "Узел — характер."],
        ["Дежурить у причала", "Туман врёт о расстоянии."],
        ["Варить уху на всех", "Котелок на двадцать ложек."],
      ],
      729,
      0.55,
      false,
    ),
    night: pack(
      "pyatak",
      "night",
      [
        ["Спустить шлюпку на тихую воду", "Вёсла в тряпке."],
        ["Перерезать сигнальный трос", "Пусть буй молчит."],
        ["Залить фонарь сажей", "Берег слепнет."],
        ["Перепрятать вёсла", "Кто ищет — не там."],
        ["Стучать по днищу азбукой", "Рыба слышит, охрана нет."],
        ["Собрать своих у сарая", "Остров любит шёпот."],
      ],
      729,
      0.25,
      true,
    ),
  },
  {
    id: "lebed",
    name: "Белый лебедь",
    city: "Соликамск",
    blurb: "Белое только в названии. Двор жёсткий.",
    tattoosNeeded: 32,
    dayEnergy: 837,
    nightEnergy: 837,
    phoneParts: 6,
    escapeParts: 14,
    businessName: "Кузница",
    businessKind: "pap",
    day: pack(
      "lebed",
      "day",
      [
        ["Качать мехи", "Искра в усы."],
        ["Ковать скобы", "Металл помнит удар."],
        ["Таскать уголь", "Опять чёрные руки."],
        ["Закалять пруток", "Шипение — музыка."],
        ["Точить зубило", "Остриё вниз."],
        ["Мести окалину", "Пол горячий."],
        ["Носить воду к горну", "Ведро кипит от взгляда."],
      ],
      837,
      0.5,
      false,
    ),
    night: pack(
      "lebed",
      "night",
      [
        ["Приглушить горн", "Пусть остынет не вовремя."],
        ["Вынести клещи в снег", "След растает."],
        ["Сбить замок с ящика", "Один удар — и тишина."],
        ["Засыпать сажей журнал", "Пишите на ощупь."],
        ["Собрать круг у кузни", "Искры вместо слов."],
        ["Перекрыть воду к пожарке", "Пусть бегают с вёдрами."],
      ],
      837,
      0.22,
      true,
    ),
  },
  {
    id: "orel",
    name: "Орловский централ",
    city: "Орёл",
    blurb: "Старый камень, новые правила.",
    tattoosNeeded: 38,
    dayEnergy: 871,
    nightEnergy: 871,
    phoneParts: 10,
    escapeParts: 7,
    businessName: "Пекарня",
    businessKind: "pap",
    day: pack(
      "orel",
      "day",
      [
        ["Месить тесто", "Кулаки в муке."],
        ["Сажать хлеб в печь", "Жар в лицо."],
        ["Таскать мешки", "Мука пылит, как снег."],
        ["Делить пайки", "Весы врут, глаза нет."],
        ["Мыть противни", "Чёрное отходит неохотно."],
        ["Сторожить дрожжи", "Их любят больше сахара."],
        ["Разносить тёплый хлеб", "Запах открывает двери."],
      ],
      871,
      0.48,
      false,
    ),
    night: pack(
      "orel",
      "night",
      [
        ["Вынуть заслонку печи", "Жар гуляет по цеху."],
        ["Подсунуть дрожжи не туда", "Пусть взойдёт лишнее."],
        ["Спрятать нож для теста", "Лезвие в муке."],
        ["Запереть склад с мукой", "Ключ в кармане."],
        ["Собрать народ у печи", "Тепло и разговор."],
        ["Задуть контрольный фонарь", "Коридор слепнет."],
      ],
      871,
      0.2,
      true,
    ),
  },
  {
    id: "dolphin",
    name: "Чёрный дельфин",
    city: "Соль-Илецк",
    blurb: "Край карты. Дальше только легенды.",
    tattoosNeeded: 44,
    dayEnergy: 893,
    nightEnergy: 887,
    phoneParts: 10,
    escapeParts: 10,
    businessName: "Каменный двор",
    businessKind: "respect",
    day: pack(
      "dolphin",
      "day",
      [
        ["Таскать камень", "Плита помнит спину."],
        ["Класть стену", "Ровный ряд — ровный характер."],
        ["Мешать раствор", "Серое на сером."],
        ["Пилить блок", "Пыль в зубах."],
        ["Носить воду в жару", "Ведро звенит.",],
        ["Дежурить у ворот", "Степь смотрит в оба."],
        ["Чинить тележку", "Колесо важнее спины."],
      ],
      893,
      0.45,
      false,
    ),
    night: pack(
      "dolphin",
      "night",
      [
        ["Сдвинуть блок у забора", "Щель на ладонь."],
        ["Засыпать замок песком", "Пусть клинит."],
        ["Перестучаться через стену", "Камень проводит стук."],
        ["Снять колючку с угла", "Перчатка из тряпья."],
        ["Собрать тихий круг во дворе", "Степь слышит шёпот."],
        ["Погасить прожектор камнем", "Тьма на пять минут."],
      ],
      887,
      0.18,
      true,
    ),
  },
];

export const BOSSES: Boss[] = [
  {
    id: "sparring",
    name: "Борзый",
    title: "дежурный по камере",
    kind: "sparring",
    hp: 400,
    authGate: 0,
    keyFrom: null,
    keysNeeded: 0,
    rewardAuth: 12,
    rewardPap: 40,
    rewardKey: null,
    dailyCap: 3,
  },
  {
    id: "plita",
    name: "Плита",
    title: "смотрит за баулами",
    kind: "inmate",
    hp: 1000,
    authGate: 3000,
    keyFrom: null,
    keysNeeded: 0,
    rewardAuth: 25,
    rewardPap: 80,
    rewardKey: "plita",
    cellTheme: "plita",
    dailyCap: 6,
  },
  {
    id: "dymok",
    name: "Дымок",
    title: "курилка и долги",
    kind: "inmate",
    hp: 10000,
    authGate: 3000,
    keyFrom: "plita",
    keysNeeded: 3,
    rewardAuth: 30,
    rewardPap: 100,
    rewardKey: "dymok",
    cellTheme: "dymok",
  },
  {
    id: "batko",
    name: "Батько",
    title: "усатый распорядитель двора",
    kind: "inmate",
    hp: 50000,
    authGate: 4000,
    keyFrom: "dymok",
    keysNeeded: 3,
    rewardAuth: 50,
    rewardPap: 300,
    rewardKey: "batko",
  },
  {
    id: "zver",
    name: "Зверь",
    title: "редко моргает",
    kind: "inmate",
    hp: 100000,
    authGate: 5000,
    keyFrom: "batko",
    keysNeeded: 3,
    rewardAuth: 100,
    rewardPap: 500,
    rewardKey: "zver",
    cellTheme: "zver",
  },
  {
    id: "katok",
    name: "Каток",
    title: "широкий, как ворота",
    kind: "inmate",
    hp: 500000,
    authGate: 8000,
    keyFrom: "zver",
    keysNeeded: 1,
    rewardAuth: 250,
    rewardPap: 5000,
    rewardKey: "katok",
    cellTheme: "katok",
  },
  {
    id: "stepnyak",
    name: "Степняк",
    title: "пришёл с этапа",
    kind: "inmate",
    hp: 2000000,
    authGate: 12000,
    keyFrom: "katok",
    keysNeeded: 1,
    rewardAuth: 400,
    rewardPap: 8000,
    rewardKey: "stepnyak",
  },
  {
    id: "kosto",
    name: "Костоправ",
    title: "белые руки, чёрный характер",
    kind: "inmate",
    hp: 2500000,
    authGate: 15000,
    keyFrom: "stepnyak",
    keysNeeded: 1,
    rewardAuth: 500,
    rewardPap: 9000,
    rewardKey: "kosto",
  },
  {
    id: "kolya",
    name: "Дядя Коля",
    title: "кухня и семёрка",
    kind: "inmate",
    hp: 3000000,
    authGate: 20000,
    keyFrom: "kosto",
    keysNeeded: 1,
    rewardAuth: 700,
    rewardPap: 12000,
    rewardKey: null,
    cellTheme: "kolya",
  },
  {
    id: "starley",
    name: "Старлей",
    title: "первый вертухай",
    kind: "guard",
    hp: 100000,
    authGate: 3000,
    keyFrom: null,
    keysNeeded: 0,
    riotsZone: "kresty",
    riotsNeeded: 2,
    rewardAuth: 80,
    rewardPap: 200,
    rewardKey: "starley",
  },
  {
    id: "oneeye",
    name: "Одноглазый",
    title: "видит лучше двоих",
    kind: "guard",
    hp: 300000,
    authGate: 5000,
    keyFrom: "starley",
    keysNeeded: 3,
    riotsZone: "matrosskaya",
    riotsNeeded: 2,
    rewardAuth: 120,
    rewardPap: 400,
    rewardKey: "oneeye",
  },
  {
    id: "zoya",
    name: "Тётя Зоя",
    title: "кошка, халат, характер",
    kind: "guard",
    hp: 300000,
    authGate: 4000,
    keyFrom: null,
    keysNeeded: 0,
    rewardAuth: 140,
    rewardPap: 350,
    rewardKey: null,
  },
  {
    id: "besok",
    name: "Бесёнок",
    title: "свисток и ухмылка",
    kind: "guard",
    hp: 700000,
    authGate: 8000,
    keyFrom: "oneeye",
    keysNeeded: 3,
    riotsZone: "pyatak",
    riotsNeeded: 2,
    rewardAuth: 200,
    rewardPap: 600,
    rewardKey: "besok",
  },
  {
    id: "paleny",
    name: "Паленый",
    title: "форма цвета гари",
    kind: "guard",
    hp: 1500000,
    authGate: 10000,
    keyFrom: "besok",
    keysNeeded: 3,
    riotsZone: "lebed",
    riotsNeeded: 2,
    rewardAuth: 350,
    rewardPap: 1000,
    rewardKey: "paleny",
  },
  {
    id: "twins",
    name: "Близнята",
    title: "двое в одну дверь",
    kind: "guard",
    hp: 2000000,
    authGate: 12000,
    keyFrom: null,
    keysNeeded: 0,
    rewardAuth: 400,
    rewardPap: 1200,
    rewardKey: null,
  },
  {
    id: "mayor",
    name: "Майор",
    title: "голова охраны",
    kind: "guard",
    hp: 3000000,
    authGate: 18000,
    keyFrom: "paleny",
    keysNeeded: 1,
    riotsZone: "orel",
    riotsNeeded: 2,
    rewardAuth: 800,
    rewardPap: 2500,
    rewardKey: "mayor",
  },
  {
    id: "omon",
    name: "Щит",
    title: "гости в касках",
    kind: "guard",
    hp: 40000000,
    authGate: 25000,
    keyFrom: "mayor",
    keysNeeded: 1,
    rewardAuth: 2500,
    rewardPap: 8000,
    rewardKey: null,
  },
];

export const MODE_HP: Record<string, number> = { patsan: 1, blatnoy: 3, avtoritet: 6 };
export const MODE_LABEL: Record<string, string> = {
  patsan: "Пацанский",
  blatnoy: "Блатной",
  avtoritet: "Авторитетный",
};

function tat(
  id: string,
  name: string,
  cat: TattooCat,
  slot: string,
  cost: number,
  currency: Tattoo["currency"],
  dmg: number,
): Tattoo {
  // Fan rule of thumb from 2011–13: authority ≈ price/10 for pap-priced ink.
  const auth = currency === "pap" ? Math.max(1, Math.round(cost / 10)) : Math.max(3, Math.round(cost * 2));
  return { id, name, cat, slot, cost, currency, auth, dmg };
}

export const TATTOOS: Tattoo[] = [
  tat("cat-fence", "Кот на заборе", "patsan", "shoulder-l", 40, "pap", 1),
  tat("rose-arm", "Роза на плече", "patsan", "shoulder-r", 50, "pap", 1),
  tat("ship", "Кораблик", "patsan", "chest", 60, "pap", 1),
  tat("clock", "Часы без стрелок", "patsan", "forearm-l", 55, "pap", 1),
  tat("web", "Паутина на локте", "patsan", "elbow", 45, "pap", 1),
  tat("swallow", "Ласточка", "patsan", "neck", 70, "pap", 2),
  tat("knife", "Перочинный", "patsan", "forearm-r", 50, "pap", 1),
  tat("anchor", "Якорь", "patsan", "calf-l", 65, "pap", 1),
  tat("grin", "Оскал", "fraer", "chest", 90, "pap", 1),
  tat("dice", "Кости", "fraer", "hand-l", 80, "pap", 1),
  tat("chain", "Цепь", "fraer", "torso", 100, "pap", 1),
  tat("mask", "Маска", "fraer", "shoulder-l", 110, "pap", 2),
  tat("crown-small", "Маленькая корона", "fraer", "hand-r", 120, "pap", 2),
  tat("rose-leg", "Роза на икре", "fraer", "calf-r", 95, "pap", 1),
  tat("spider", "Паук", "fraer", "elbow", 85, "pap", 1),
  tat("lantern", "Фонарь", "fraer", "forearm-l", 105, "pap", 1),
  tat("epaulette", "Погоны", "blat", "shoulder-l", 8, "rub", 3),
  tat("dome", "Купола", "blat", "back", 10, "rub", 3),
  tat("wolf", "Волк", "blat", "chest", 12, "rub", 4),
  tat("tiger", "Тигр", "blat", "back", 14, "rub", 4),
  tat("cross-chest", "Крест на груди", "blat", "chest", 9, "tp", 3),
  tat("bells", "Купола-маковки", "blat", "back", 11, "rub", 3),
  tat("snake", "Змея", "blat", "arm-l", 10, "rub", 3),
  tat("eagle", "Орёл", "blat", "back", 16, "rub", 5),
  tat("cards-q", "Дама пик", "zhigan", "forearm-r", 8, "sugar", 2),
  tat("fire", "Огонь по ребру", "zhigan", "ribs", 10, "sugar", 3),
  tat("scarab", "Жук", "zhigan", "hand-l", 7, "sugar", 2),
  tat("moon", "Серп луны", "zhigan", "neck", 9, "sugar", 2),
  tat("raven", "Ворон", "zhigan", "shoulder-r", 12, "sugar", 3),
  tat("barbed", "Колючка", "zhigan", "arm-r", 8, "sugar", 2),
  tat("eye-palm", "Глаз на ладони", "zhigan", "hand-r", 11, "sugar", 3),
  tat("wave", "Волна", "zhigan", "calf-l", 9, "sugar", 2),
  tat("lion", "Лев", "avtor", "chest", 18, "rub", 6),
  tat("bear", "Медведь", "avtor", "back", 20, "rub", 6),
  tat("knight", "Всадник", "avtor", "torso", 22, "rub", 7),
  tat("chapel", "Часовня", "avtor", "back", 19, "rub", 6),
  tat("ring", "Перстень", "avtor", "hand-r", 14, "rub", 4),
  tat("torch", "Факел", "avtor", "forearm-l", 16, "rub", 5),
  tat("oak", "Дуб", "avtor", "calf-r", 15, "rub", 4),
  tat("banner", "Знамя", "avtor", "shoulder-l", 21, "rub", 6),
  tat("gold-chain", "Цепь на шею", "ponto", "neck", 4, "soap", 5),
  tat("watch", "Брегет", "ponto", "forearm-r", 5, "soap", 5),
  tat("rose-gold", "Золотая роза", "ponto", "chest", 6, "soap", 6),
  tat("panther", "Пантера", "ponto", "back", 7, "soap", 7),
  tat("crown-big", "Корона двора", "ponto", "chest", 8, "soap", 8),
  tat("wings", "Крылья", "ponto", "back", 6, "soap", 6),
  tat("grin-gold", "Золотой оскал", "ponto", "shoulder-r", 5, "soap", 5),
  tat("laurel", "Лавры", "ponto", "neck", 7, "soap", 7),
];

export const CLOTHES: Clothes[] = [
  { id: "cap-black", name: "Чёрная кепка", slot: "head", cost: 40, currency: "pap", auth: 4 },
  { id: "cap-knit", name: "Подшлемник", slot: "head", cost: 80, currency: "pap", auth: 8 },
  { id: "ushanka", name: "Ушанка", slot: "head", cost: 6, currency: "rub", auth: 12 },
  { id: "shorts", name: "Трусы с кантом", slot: "legs", cost: 30, currency: "pap", auth: 3 },
  { id: "sweats", name: "Штаны спортивные", slot: "legs", cost: 120, currency: "pap", auth: 12 },
  { id: "robe", name: "Халат", slot: "torso", cost: 200, currency: "pap", auth: 20 },
  { id: "wifebeater", name: "Майка", slot: "torso", cost: 50, currency: "pap", auth: 5 },
  { id: "slippers", name: "Сланцы", slot: "feet", cost: 25, currency: "pap", auth: 2 },
  { id: "sneakers", name: "Кеды", slot: "feet", cost: 90, currency: "pap", auth: 9 },
  { id: "red-slippers", name: "Красные тапки", slot: "feet", cost: 8, currency: "rub", auth: 16 },
  { id: "beads", name: "Чётки", slot: "extra", cost: 70, currency: "pap", auth: 7 },
  { id: "chain-gold", name: "Цепь", slot: "extra", cost: 5, currency: "soap", auth: 25 },
];

export const SHOP: ShopOffer[] = [
  { id: "pap-40", tab: "pap", name: "Пачка", blurb: "40 папирос", give: { pap: 40 }, cost: 1, currency: "votes" },
  { id: "pap-120", tab: "pap", name: "Блок", blurb: "120 папирос", give: { pap: 120 }, cost: 2, currency: "votes" },
  { id: "pap-400", tab: "pap", name: "Ящик", blurb: "400 папирос", give: { pap: 400 }, cost: 5, currency: "votes" },
  { id: "rub-16", tab: "rub", name: "Куча монет", blurb: "16 деревянных", give: { rub: 16 }, cost: 1, currency: "votes" },
  { id: "rub-36", tab: "rub", name: "Кружка", blurb: "36 деревянных", give: { rub: 36 }, cost: 2, currency: "votes" },
  { id: "rub-56", tab: "rub", name: "Кастрюлька", blurb: "56 деревянных", give: { rub: 56 }, cost: 3, currency: "votes" },
  { id: "rub-100", tab: "rub", name: "Банка", blurb: "100 деревянных", give: { rub: 100 }, cost: 5, currency: "votes" },
  { id: "rub-600", tab: "rub", name: "Мешок", blurb: "600 деревянных", give: { rub: 600 }, cost: 30, currency: "votes" },
  { id: "rub-2000", tab: "rub", name: "Сундук", blurb: "2000 деревянных", give: { rub: 2000 }, cost: 100, currency: "votes" },
  { id: "sugar-5", tab: "sugar", name: "Кубики", blurb: "5 сахара", give: { sugar: 5 }, cost: 40, currency: "pap" },
  { id: "sugar-20", tab: "sugar", name: "Голова", blurb: "20 сахара", give: { sugar: 20 }, cost: 3, currency: "votes" },
  { id: "tp-3", tab: "tp", name: "Рулон", blurb: "3 туалетки", give: { tp: 3 }, cost: 50, currency: "pap" },
  { id: "tp-10", tab: "tp", name: "Пачка рулонов", blurb: "10 туалетки", give: { tp: 10 }, cost: 4, currency: "votes" },
  { id: "soap-1", tab: "soap", name: "Хозяйственное", blurb: "1 мыло", give: { soap: 1 }, cost: 8, currency: "votes" },
  { id: "soap-5", tab: "soap", name: "Связка", blurb: "5 мыла", give: { soap: 5 }, cost: 35, currency: "votes" },
  { id: "chifir", tab: "energy", name: "Чифирнуть", blurb: "+50 энергии сразу", give: { energy: 50 }, cost: 3, currency: "votes" },
  { id: "poison-5", tab: "weapon", name: "Яд ×5", blurb: "накрутка по боссу", give: { poison: 5 }, cost: 4, currency: "votes" },
  { id: "finka-8", tab: "weapon", name: "Финка ×8", blurb: "с движух и с прилавка", give: { finka: 8 }, cost: 80, currency: "pap" },
  { id: "samopal-3", tab: "weapon", name: "Самопал ×3", blurb: "громко и коротко", give: { samopal: 3 }, cost: 6, currency: "votes" },
];

export const TALENTS: Talent[] = [
  { id: "chemist", name: "Химик", blurb: "Яд бьёт на 25% сильнее.", cost: 1 },
  { id: "science", name: "Знание наук", blurb: "Ещё +20% к яду.", cost: 2 },
  { id: "adrenalin", name: "Адреналин", blurb: "Потолок энергии +25.", cost: 3 },
  { id: "howl", name: "Вой", blurb: "Потолок энергии +15.", cost: 4 },
  { id: "beast", name: "Звериная сила", blurb: "Бицуха растёт быстрее, потолок +10.", cost: 3 },
  { id: "unarmed", name: "Боец двора", blurb: "Голые руки ×2.", cost: 2 },
  { id: "eternal", name: "Вечный бой", blurb: "Друзья бьют босса чуть чаще.", cost: 5 },
];

export const DAILIES: Daily[] = [
  { id: "naezd", title: "Наехать на терпилу", hint: "Карты во дворе или спарринг.", auth: 3, pap: 0 },
  { id: "rise", title: "Подняться", hint: "Закрой любую движуху.", auth: 5, pap: 0 },
  { id: "profit", title: "Собрать прибыль", hint: "Кнопка «Собрать всё» на проходной.", auth: 3, pap: 0 },
  { id: "gift", title: "Отправить подогрев", hint: "Батон корешу в хату.", auth: 0, pap: 10 },
  { id: "spit", title: "Харкнуть в баланду", hint: "Чужая камера, жест.", auth: 2, pap: 0 },
  { id: "respect", title: "Завоевать уважение", hint: "Дневная движуха до конца.", auth: 4, pap: 0 },
];

export const NYCHKA_NAMES = [
  "Спички",
  "Леска",
  "Иголка",
  "Пуговица",
  "Карандаш",
  "Марка",
  "Нитка",
];

export const FRIEND_NAMES = [
  "Лёха",
  "Санёк",
  "Кузя",
  "Гена",
  "Вован",
  "Тоха",
  "Юрец",
  "Макс",
  "Боря",
  "Витек",
  "Жека",
  "Диман",
  "Серый",
  "Паша",
  "Колян",
  "Тёма",
  "Гоша",
  "Игорёк",
  "Рома",
  "Вадик",
  "Митя",
  "Федя",
  "Ярик",
  "Славик",
];

export const RANK_NPC = [
  ["Хмурый", 18400],
  ["Бугор", 15220],
  ["Карп", 12890],
  ["Седой", 11040],
  ["Гвоздь", 9870],
  ["Малой", 8440],
  ["Крот", 7310],
  ["Шило-старший", 6120],
  ["Валет", 5080],
  ["Глеб", 4210],
] as const;

export const WORKSHOP = [
  { id: "stepa", name: "Стёпа", bench: "Верстак", energy: 438, pap: 1800, rub: 3 },
  { id: "garik", name: "Гарик", bench: "Пила", energy: 538, pap: 2200, rub: 4 },
  { id: "mityai", name: "Митяй", bench: "Тиски", energy: 630, pap: 3300, rub: 5 },
  { id: "zinka", name: "Зинка", bench: "Швейка", energy: 930, pap: 5600, rub: 6 },
  { id: "grach", name: "Грач", bench: "Ковка", energy: 994, pap: 4000, rub: 7 },
  { id: "feliks", name: "Феликс", bench: "Жесть", energy: 994, pap: 4200, rub: 7 },
  { id: "makar", name: "Макар", bench: "Токарка", energy: 1152, pap: 5000, rub: 8 },
  { id: "seva", name: "Сева", bench: "Сборка", energy: 1210, pap: 5200, rub: 6 },
  { id: "zhora", name: "Жора", bench: "Полировка", energy: 1238, pap: 5400, rub: 9 },
  { id: "yana", name: "Яна", bench: "Ангелы", energy: 1408, pap: 7000, rub: 8 },
  { id: "vanja", name: "Ваня", bench: "Демоны", energy: 1599, pap: 7200, rub: 8 },
];

export function zoneById(id: string): Zone {
  const z = ZONES.find((x) => x.id === id);
  if (!z) throw new Error(`zone ${id}`);
  return z;
}

export function jobEnergySum(jobs: Job[]): number {
  return jobs.reduce((s, j) => s + j.energy * j.repeats, 0);
}

export function assertEnergyTables(): void {
  for (const z of ZONES) {
    const d = jobEnergySum(z.day);
    const n = jobEnergySum(z.night);
    if (d !== z.dayEnergy || n !== z.nightEnergy) {
      console.warn(`[srok] energy mismatch ${z.name}: day ${d}/${z.dayEnergy} night ${n}/${z.nightEnergy}`);
    }
  }
}
