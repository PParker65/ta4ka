import 'package:flutter/cupertino.dart';

import '../core/l10n/app_lang.dart';

part 'auto_spheres_extra.dart';

class AutoSphere {
  const AutoSphere({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.priceHint,
    required this.keywords,
    required this.workIds,
    required this.icon,
    required this.color,
  });

  final String id;
  final L title;
  final L subtitle;
  final L detail;
  final L priceHint;
  final List<String> keywords;
  final List<String> workIds;
  final IconData icon;
  final Color color;

  String get imageUrl => 'assets/categories/$id.jpg';
}

const autoSpheres = <AutoSphere>[
  AutoSphere(
    id: 'usa',
    title: L(
      'Доставка авто зі США',
      'Car delivery from the USA',
      'Доставка авто из США',
      'Dostawa aut ze USA',
    ),
    subtitle: L('Послуги', 'Services', 'Услуги', 'Usługi'),
    detail: L(
      'Єдиний партнер Ta4ka — Lion Trans, офіційний IAAI в Україні. Під ключ: підбір на Copart/IAAI, ставка, океан, розмитнення, ключі в вашому місті.',
      'Sole Ta4ka partner — Lion Trans, official IAAI in Ukraine. Turnkey: Copart/IAAI pick, bid, ocean, customs, keys in your city.',
      'Единственный партнёр Ta4ka — Lion Trans, официальный IAAI в Украине. Под ключ: подбор Copart/IAAI, ставка, океан, растаможка, ключи в вашем городе.',
    ),
    priceHint: L(
      'від 1000 \$ · доставка',
      'from \$1,000 · delivery',
      'от 1000 \$ · доставка',
      'od 1000 \$ · dostawa',
    ),
    keywords: [
      'сша', 'usa', 'america', 'copart', 'iaai', 'manheim',
      'розмитнен', 'растамож', 'митниц', 'тамож', 'акциз',
      'доставк', 'під ключ', 'под ключ', 'import', 'аукцион сша',
      'пригон', 'авто из сша', 'авто з сша', 'океан',
    ],
    workIds: [],
    icon: CupertinoIcons.flag_fill,
    color: Color(0xFF1C3D8A),
  ),
  AutoSphere(
    id: 'insurance',
    title: L('Страховка / КАСКО', 'Insurance / CASCO', 'Страховка / КАСКО'),
    subtitle: L(
      'ОСЦПВ, КАСКО, франшиза, допомога після ДТП',
      'MTPL, CASCO, deductible, post-crash help',
      'ОСАГО, КАСКО, франшиза, помощь после ДТП',
    ),
    detail: L(
      'Консультація та оформлення ОСЦПВ і КАСКО за VIN: порівнюємо франшизу, покриття скла, удари тварин і асистанс. Після ДТП допоможемо зібрати фото, схему і заяву страховику. Консультація безкоштовна; премія — за тарифом компанії.',
      'We issue MTPL and CASCO by VIN: deductible, glass, animal strikes and roadside assist. After a crash we help with photos, a sketch and the insurer claim. Advice is free; the premium is the insurer’s tariff.',
      'Консультация и оформление ОСАГО и КАСКО по VIN: франшиза, стекло, животные и ассистанс. После ДТП поможем собрать фото, схему и заявление. Консультация бесплатная; премия — по тарифу страховщика.',
    ),
    priceHint: L(
      'від 0 ₴ · консультація',
      'from ₴0 · advice',
      'от 0 ₴ · консультация',
    ),
    keywords: ['страх', 'каско', 'осаго', 'dtp', 'insurance', 'policy'],
    workIds: ['insurance'],
    icon: CupertinoIcons.shield,
    color: Color(0xFF5856D6),
  ),
  AutoSphere(
    id: 'diag',
    title: L('Компʼютерна діагностика', 'Computer diagnostics', 'Компьютерная диагностика'),
    subtitle: L(
      'Дилерський сканер, усі блоки, живі дані, план ремонту',
      'Dealer scan, all modules, live data, repair plan',
      'Дилерский сканер, все блоки, живые данные, план ремонта',
    ),
    detail: L(
      'Повне зчитування всіх блоків дилерським сканером (ODIS, ISTA, Xentry, Autel): коди, живі дані, тести актуаторів. Коди не стираємо, поки не підтверджена причина. 40–60 хв; робота від 1 400 ₴, запчастини окремо.',
      'Full dealer-level scan (ODIS, ISTA, Xentry, Autel): codes, live data, actuator tests. Codes stay until the cause is confirmed. 40–60 min; labour from ₴1,400, parts extra.',
      'Полное считывание всех блоков дилерским сканером (ODIS, ISTA, Xentry, Autel): коды, живые данные, тесты актуаторов. Коды не стираем, пока не подтверждена причина. 40–60 мин; работа от 1 400 ₴, запчасти отдельно.',
    ),
    priceHint: L(
      'від 1 400 ₴ · робота',
      'from ₴1,400 · labour',
      'от 1 400 ₴ · работа',
    ),
    keywords: ['чек', 'check', 'diag', 'скан', 'ошиб', 'помил', 'adblue', 'scr'],
    workIds: ['diag-comp'],
    icon: CupertinoIcons.graph_square,
    color: Color(0xFF007AFF),
  ),
  AutoSphere(
    id: 'engine',
    title: L('Двигун / ГРМ', 'Engine / timing', 'Двигатель / ГРМ'),
    subtitle: L(
      'ГРМ, компресія, турбіна, свічки, дефектування мотора',
      'Timing, compression, turbo, plugs, engine survey',
      'ГРМ, компрессия, турбина, свечи, дефектовка мотора',
    ),
    detail: L(
      'Моторний цех: компресія і leak-down, ендоскоп, ГРМ за регламентом, турбіна, свічки. Кошторис після огляду на підйомнику, не «на слух з парковки». Свічки від 1 000 ₴, комплект ГРМ від 6 800 ₴; капіталка — після дефектування.',
      'Engine bay: compression and leak-down, borescope, timing by mileage, turbo, plugs. Quote after a lift inspection, not by ear in the yard. Plugs from ₴1,000, timing kit labour from ₴6,800; a rebuild is quoted after teardown.',
      'Моторный цех: компрессия и leak-down, эндоскоп, ГРМ по регламенту, турбина, свечи. Смета после осмотра на подъёмнике. Свечи от 1 000 ₴, комплект ГРМ от 6 800 ₴; капиталка — после дефектовки.',
    ),
    priceHint: L(
      'від 1 000 ₴ · робота',
      'from ₴1,000 · labour',
      'от 1 000 ₴ · работа',
    ),
    keywords: ['мотор', 'двиг', 'грм', 'lanцюг', 'chain', 'timing', 'turbo', 'турб'],
    workIds: ['engine-repair', 'timing', 'plugs', 'turbo'],
    icon: CupertinoIcons.gear_alt,
    color: Color(0xFFFF9500),
  ),
  AutoSphere(
    id: 'electronics',
    title: L('Електрика / ECU', 'Electrics / ECU', 'Электрика / ECU'),
    subtitle: L(
      'АКБ, стартер, генератор, джгути, CAN-блоки',
      'Battery, starter, alternator, looms, CAN modules',
      'АКБ, стартер, генератор, жгуты, CAN-блоки',
    ),
    detail: L(
      'Електрика авто: тест АКБ під навантаженням, стартер і генератор, джгути, CAN і блоки. Після заміни акумулятора робимо адаптації вікон і дроселя, якщо цього просить блок. Від 800 ₴ за перевірку/заміну АКБ.',
      'Vehicle electrics: load-test the battery, starter and alternator, looms, CAN and modules. After a battery swap we run window and throttle adaptations if the car asks. From ₴800 for battery test/replace.',
      'Автоэлектрика: тест АКБ под нагрузкой, стартер и генератор, жгуты, CAN и блоки. После замены аккумулятора — адаптации окон и дросселя. От 800 ₴ за проверку/замену АКБ.',
    ),
    priceHint: L(
      'від 800 ₴ · робота',
      'from ₴800 · labour',
      'от 800 ₴ · работа',
    ),
    keywords: ['електр', 'ecu', 'can', 'провод', 'датчик', 'battery', 'акб'],
    workIds: ['battery', 'diag-comp', 'coding', 'wiring', 'starter-alt'],
    icon: CupertinoIcons.bolt,
    color: Color(0xFFFFCC00),
  ),
  AutoSphere(
    id: 'coding',
    title: L('Кодування / ODIS / ICOM', 'Coding / ODIS / ICOM', 'Кодирование / ODIS / ICOM'),
    subtitle: L(
      'ODIS / ISTA / Xentry: опції, фари, привʼязка блоків',
      'ODIS / ISTA / Xentry: options, lamps, module pairing',
      'ODIS / ISTA / Xentry: опции, фары, привязка блоков',
    ),
    detail: L(
      'Кодування опцій і привʼязка блоків VAG / BMW / Mercedes: ODIS, ISTA, Xentry, ENET. Перед записом перевіряємо напругу мережі — слабкий генератор обриває прошивку. Робота від 5 500 ₴; калібрування фар і ADAS — окремі позиції.',
      'Option coding and module pairing for VAG / BMW / Mercedes: ODIS, ISTA, Xentry, ENET. We confirm charging voltage before a write — a weak alternator bricks the flash. Labour from ₴5,500; lamp and ADAS calibration billed separately.',
      'Кодирование опций и привязка блоков VAG / BMW / Mercedes: ODIS, ISTA, Xentry, ENET. Перед записью проверяем зарядку. Работа от 5 500 ₴; калибровка фар и ADAS — отдельно.',
    ),
    priceHint: L(
      'від 5 500 ₴ · робота',
      'from ₴5,500 · labour',
      'от 5 500 ₴ · работа',
    ),
    keywords: ['фара', 'привяз', 'odis', 'icom', 'vag', 'bmw', 'coding', 'headlight'],
    workIds: ['coding'],
    icon: CupertinoIcons.chevron_left_slash_chevron_right,
    color: Color(0xFF5AC8FA),
  ),
  AutoSphere(
    id: 'chassis',
    title: L('Ходова / підвіска', 'Chassis / suspension', 'Ходовая / подвеска'),
    subtitle: L(
      'Підйомник: важелі, опори, ШРУС, пневмо, люфти',
      'Lift: arms, mounts, CV joints, air springs, play',
      'Подъёмник: рычаги, опоры, ШРУС, пневмо, люфты',
    ),
    detail: L(
      'Ходова на підйомнику: важелі, сайлентблоки, опори, ШРУС, пневмо. Люфт показуємо клієнту на місці і ділимо на «міняти зараз / ще походить». Діагностика від 1 200 ₴; заміна вузлів — за окремим кошторисом.',
      'Chassis on the lift: arms, bushes, mounts, CV joints, air springs. We show play in person and split “replace now / still serviceable”. Inspection from ₴1,200; parts and labour quoted per item.',
      'Ходовая на подъёмнике: рычаги, сайлентблоки, опоры, ШРУС, пневмо. Люфт показываем на месте. Диагностика от 1 200 ₴; замена узлов — по отдельной смете.',
    ),
    priceHint: L(
      'від 1 200 ₴ · робота',
      'from ₴1,200 · labour',
      'от 1 200 ₴ · работа',
    ),
    keywords: ['стук', 'ходов', 'подвес', 'колес', 'wheel', 'knock', 'suspension'],
    workIds: ['diag-chassis', 'align', 'steering', 'cv-joint', 'air-suspension'],
    icon: CupertinoIcons.car_detailed,
    color: Color(0xFF34C759),
  ),
  AutoSphere(
    id: 'brakes',
    title: L('Гальма / колодки / диски', 'Brakes / pads / discs', 'Тормоза / колодки / диски'),
    subtitle: L(
      'Колодки і диски на вісь, проточка, рідина DOT',
      'Pads and discs per axle, machining, DOT fluid',
      'Колодки и диски на ось, проточка, жидкость DOT',
    ),
    detail: L(
      'Гальма комплектом на вісь: колодки, диски, супорти, рідина DOT4/DOT5.1. Завжди міряємо товщину дисків — проточка лише якщо залишається запас. Колодки від 1 800 ₴ робота; диски від 3 200 ₴; запчастини окремо.',
      'Brakes as an axle set: pads, discs, calipers, DOT4/DOT5.1 fluid. Disc thickness is measured first — machining only with enough meat left. Pad labour from ₴1,800; discs from ₴3,200; parts extra.',
      'Тормоза комплектом на ось: колодки, диски, суппорта, жидкость DOT4/DOT5.1. Толщину дисков меряем всегда. Колодки от 1 800 ₴ работа; диски от 3 200 ₴; запчасти отдельно.',
    ),
    priceHint: L(
      'від 1 800 ₴ · робота',
      'from ₴1,800 · labour',
      'от 1 800 ₴ · работа',
    ),
    keywords: ['гальм', 'тормоз', 'колод', 'диск', 'brake', 'pad'],
    workIds: ['pads', 'discs', 'brake-lathe'],
    icon: CupertinoIcons.circle,
    color: Color(0xFFFF3B30),
  ),
  AutoSphere(
    id: 'paint',
    title: L('Малярка / локальний ремонт', 'Paint / spot repair', 'Малярка / локальный ремонт'),
    subtitle: L(
      'Підбір емалі, скол або елемент у камері, лак',
      'Colour match, chip or booth panel, clear coat',
      'Подбор эмали, скол или элемент в камере, лак',
    ),
    detail: L(
      'Малярка: підбір емалі за VIN і спектрофотометром, локальний скол або фарбування елемента в камері, лак і полірування стику. Скол від 2 500 ₴, елемент від 6 500 ₴. Термін 1–3 дні залежно від площі.',
      'Paint shop: colour match by VIN and spectrophotometer, chip repair or a full panel in booth, clear coat and blend polish. A chip from ₴2,500, a panel from ₴6,500. 1–3 days depending on area.',
      'Малярка: подбор эмали по VIN и спектрофотометру, скол или покраска элемента в камере. Скол от 2 500 ₴, элемент от 6 500 ₴. Срок 1–3 дня.',
    ),
    priceHint: L(
      'від 2 500 ₴ · робота',
      'from ₴2,500 · labour',
      'от 2 500 ₴ · работа',
    ),
    keywords: ['маляр', 'покрас', 'paint', 'лак', 'кузов', 'body', 'царап'],
    workIds: ['paint', 'paint-panel', 'paint-spot', 'paint-polish'],
    icon: CupertinoIcons.paintbrush,
    color: Color(0xFFAF52DE),
  ),
  AutoSphere(
    id: 'wash',
    title: L('Мийка / детейлінг', 'Wash / detailing', 'Мойка / детейлинг'),
    subtitle: L(
      'Двофазна мийка, хімчистка, полірування, кераміка',
      'Two-stage wash, shampoo, polish, ceramic',
      'Двухфазная мойка, химчистка, полировка, керамика',
    ),
    detail: L(
      'Двофазна мийка без піску на лаку, хімчистка салону з екстракцією, полірування кузова і кераміка. Моторний відсік — окремо, зі зняттям клем. Контактна мийка від 350 ₴, стандарт від 900 ₴; кераміка від 8 900 ₴.',
      'Two-stage wash that does not grind grit into clear coat, interior extraction, machine polish and ceramic. Engine bay is a separate job with terminals disconnected. Contact wash from ₴350, standard from ₴900; ceramic from ₴8,900.',
      'Двухфазная мойка без песка на лаке, химчистка с экстракцией, полировка и керамика. Моторный отсек — отдельно. Мойка от 350 ₴, стандарт от 900 ₴; керамика от 8 900 ₴.',
    ),
    priceHint: L(
      'від 350 ₴ · робота',
      'from ₴350 · labour',
      'от 350 ₴ · работа',
    ),
    keywords: ['мойк', 'детейл', 'wash', 'detail', 'полир', 'чистк', 'хімчист', 'химчист', 'керам'],
    workIds: ['wash', 'detail-chem', 'detail-polish', 'detail-ceramic', 'detail-engine'],
    icon: CupertinoIcons.drop,
    color: Color(0xFF64D2FF),
  ),
  AutoSphere(
    id: 'tires',
    title: L('Шиномонтаж / балансування', 'Tire service / balancing', 'Шиномонтаж / балансировка'),
    subtitle: L(
      'Монтаж R15–R21, баланс, прокол зсередини, склад',
      'Fit R15–R21, balance, inside patch, storage',
      'Монтаж R15–R21, баланс, прокол изнутри, склад',
    ),
    detail: L(
      'Шиномонтаж R15–R21: демонтаж, монтаж, балансування на стенді, вентилі. Прокол латаємо зсередини; джгут — лише щоб доїхати. Сезонне зберігання комплектом. Прокол від 250 ₴, зміна комплекту від 600 ₴.',
      'Tyre fitting R15–R21: demount, mount, spin-balance, valves. Punctures are patched from inside; a plug is only to get you home. Seasonal storage for a full set. Patch from ₴250, a set change from ₴600.',
      'Шиномонтаж R15–R21: демонтаж, монтаж, балансировка, вентили. Прокол латаем изнутри. Сезонное хранение комплектом. Прокол от 250 ₴, смена комплекта от 600 ₴.',
    ),
    priceHint: L(
      'від 250 ₴ · робота',
      'from ₴250 · labour',
      'от 250 ₴ · работа',
    ),
    keywords: ['шин', 'колес', 'баланс', 'tire', 'wheel', 'монтаж'],
    workIds: ['tires', 'tire-repair', 'tire-storage'],
    icon: CupertinoIcons.circle_grid_3x3,
    color: Color(0xFF8E8E93),
  ),
  AutoSphere(
    id: 'align',
    title: L('Розвал-сходження', 'Wheel alignment', 'Развал-схождение'),
    subtitle: L(
      '3D Hunter після ходової; кути і знос шин',
      'Hunter 3D after chassis work; angles and tyre wear',
      '3D Hunter после ходовой; углы и износ шин',
    ),
    detail: L(
      '3D-стенд Hunter після заміни важелів, рульових тяг або шин. Спочатку геометрія підвіски, потім кути. 50–70 хв; робота 1 400 ₴. Якщо важіль гнутий — спочатку заміна, інакше нова гума зʼїдається за тиждень.',
      'Hunter 3D alignment after arms, track rods or tyres. Suspension geometry first, then angles. 50–70 min; labour ₴1,400. A bent arm is replaced first, or new tyres wear in a week.',
      '3D-стенд Hunter после рычагов, тяг или шин. Сначала геометрия подвески, потом углы. 50–70 мин; работа 1 400 ₴. Гнутый рычаг меняем до стенда.',
    ),
    priceHint: L(
      'від 1 400 ₴ · робота',
      'from ₴1,400 · labour',
      'от 1 400 ₴ · работа',
    ),
    keywords: ['розвал', 'развал', 'align', 'сход', 'стенд'],
    workIds: ['align'],
    icon: CupertinoIcons.compass,
    color: Color(0xFF30D158),
  ),
  AutoSphere(
    id: 'tuning',
    title: L('Чіп-тюнінг / Stage 1–2', 'Chip tuning / Stage 1–2', 'Чип-тюнинг / Stage 1–2'),
    subtitle: L(
      'Stage 1–2 з логами і бекапом стокової прошивки',
      'Stage 1–2 with logs and a stock-file backup',
      'Stage 1–2 с логами и бэкапом стоковой прошивки',
    ),
    detail: L(
      'Чіп Stage 1–2 з бекапом стоку і контрольними логами. Stage 2 ставимо лише з даунпайпом і паливом 98; інакше страждає турбіна. Перед записом — діагностика і зарядка. Від 8 900 ₴; залізо вихлопу окремо.',
      'Stage 1–2 remap with a stock backup and verification logs. Stage 2 only with a downpipe and 98 octane; otherwise the turbo pays. Diagnostics and charging voltage first. From ₴8,900; exhaust hardware extra.',
      'Чип Stage 1–2 с бэкапом стока и логами. Stage 2 только с даунпайпом и 98-м. Перед записью — диагностика и зарядка. От 8 900 ₴; железо выхлопа отдельно.',
    ),
    priceHint: L(
      'від 8 900 ₴ · робота',
      'from ₴8,900 · labour',
      'от 8 900 ₴ · работа',
    ),
    keywords: ['stage', 'чип', 'chip', 'tune', 'прошив', 'ecu', 'stage1', 'stage2'],
    workIds: ['tuning'],
    icon: CupertinoIcons.gauge,
    color: Color(0xFFFF2D55),
  ),
  AutoSphere(
    id: 'stage3',
    title: L('Stage 3 / forged / турбо', 'Stage 3 / forged / turbo', 'Stage 3 / forged / турбо'),
    subtitle: L(
      'Ковані поршні, турбо, інтеркулер, збірка на момент',
      'Forged pistons, turbo, intercooler, torque-spec build',
      'Кованые поршни, турбо, интеркулер, сборка по моменту',
    ),
    detail: L(
      'Побудова Stage 3: ковані поршні, шатуни, турбіна, інтеркулер, паливна, збірка з динамометричним контролем. Спочатку дефектування блоку, потім замовлення заліза. Робота від 78 000 ₴; комплектуючі — за специфікацією мотора.',
      'Stage 3 build: forged pistons and rods, turbo, intercooler, fuel system, torque-spec assembly. Block survey first, hardware second. Labour from ₴78,000; parts to the engine spec.',
      'Сборка Stage 3: кованые поршни, шатуны, турбина, интеркулер, топливная. Сначала дефектовка блока. Работа от 78 000 ₴; комплектующие — по спецификации.',
    ),
    priceHint: L(
      'від 78 000 ₴ · робота',
      'from ₴78,000 · labour',
      'от 78 000 ₴ · работа',
    ),
    keywords: ['stage3', 'stage 3', 'forged', 'кован', 'турб', 'turbo', 'build'],
    workIds: ['stage3'],
    icon: CupertinoIcons.flame,
    color: Color(0xFFFF375F),
  ),
  AutoSphere(
    id: 'exhaust',
    title: L('Вихлоп / даунпайп', 'Exhaust / downpipe', 'Выхлоп / даунпайп'),
    subtitle: L(
      'Даунпайп, кат, глушник; після заміни — прошивка',
      'Downpipe, cat, silencer; remap after the pipe',
      'Даунпайп, кат, глушитель; после замены — прошивка',
    ),
    detail: L(
      'Вихлоп: даунпайп, кат/пламегасник, резонатор, глушник на випуск. Після даунпайпа обовʼязкова прошивка — інакше чек і бідна суміш. Робота від 8 500 ₴; труби і фланці за заміром.',
      'Exhaust: downpipe, cat/test pipe, resonator, tail section. A downpipe needs a remap or you get a check light and a lean mix. Labour from ₴8,500; pipework by measurement.',
      'Выхлоп: даунпайп, кат/пламегаситель, резонатор, глушитель. После даунпайпа нужна прошивка. Работа от 8 500 ₴; трубы по замеру.',
    ),
    priceHint: L(
      'від 8 500 ₴ · робота',
      'from ₴8,500 · labour',
      'от 8 500 ₴ · работа',
    ),
    keywords: ['вихлоп', 'выхлоп', 'exhaust', 'downpipe', 'cat', 'глуш'],
    workIds: ['exhaust'],
    icon: CupertinoIcons.cloud,
    color: Color(0xFF8E8E93),
  ),
  AutoSphere(
    id: 'hydro',
    title: L('Аквадрук / гідродрук', 'Hydro dipping', 'Аквапечать / гидродрук'),
    subtitle: L(
      'Гідродрук пластику, кришок і дисків у ванні',
      'Hydro dip for plastic, covers and wheels',
      'Гидропечать пластика, крышек и дисков в ванне',
    ),
    detail: L(
      'Гідродрук пластику, кришок і дисків: знежирення, ґрунт, плівка у ванні, лак. Пил у ванні дає крапки на малюнку — деталь має бути сухою і чистою. Від 2 200 ₴ за кришку, диски від 4 800 ₴ за комплект.',
      'Hydro dip for plastic, covers and wheels: degrease, primer, film in tank, clear. Dust in the tank prints as dots — the part must be dry and clean. Covers from ₴2,200, a wheel set from ₴4,800.',
      'Гидропечать пластика, крышек и дисков: обезжиривание, грунт, пленка, лак. Пыль в ванне даёт точки. Крышка от 2 200 ₴, диски от 4 800 ₴ за комплект.',
    ),
    priceHint: L(
      'від 2 200 ₴ · робота',
      'from ₴2,200 · labour',
      'от 2 200 ₴ · работа',
    ),
    keywords: ['аква', 'hydro', 'гидро', 'пленк', 'dip', 'друк'],
    workIds: ['hydro', 'hydro-wheel', 'hydro-trim', 'hydro-cover'],
    icon: CupertinoIcons.drop_triangle,
    color: Color(0xFF5AC8FA),
  ),
  AutoSphere(
    id: 'carbon',
    title: L('Карбон / real carbon', 'Carbon / real carbon', 'Кarbon / real carbon'),
    subtitle: L(
      'Real carbon або плівка: капот, спойлер, накладки',
      'Real carbon or film: hood, spoiler, overlays',
      'Real carbon или пленка: капот, спойлер, накладки',
    ),
    detail: L(
      'Карбон: real carbon (препрег, автоклав) або якісна плівка — різницю пояснюємо до замовлення. Капот, спойлер, накладки салону. Від 4 800 ₴ за накладку; капот/спойлер від 8 900 ₴.',
      'Carbon: autoclave real carbon or quality film — we say which before you order. Hood, spoiler, cabin overlays. Overlay from ₴4,800; hood/spoiler from ₴8,900.',
      'Карбон: real carbon (препрег, автоклав) или качественная пленка — говорим до заказа. Капот, спойлер, накладки. От 4 800 ₴ за накладку; капот/спойлер от 8 900 ₴.',
    ),
    priceHint: L(
      'від 4 800 ₴ · робота',
      'from ₴4,800 · labour',
      'от 4 800 ₴ · работа',
    ),
    keywords: ['карбон', 'carbon', 'cf', 'real carbon', 'наклад'],
    workIds: ['carbon', 'carbon-hood'],
    icon: CupertinoIcons.square_grid_2x2,
    color: Color(0xFF636366),
  ),
  AutoSphere(
    id: 'wrap',
    title: L('Вініл / плівка / брендинг', 'Vinyl wrap / branding', 'Винил / пленка / брендинг'),
    subtitle: L(
      'Повна або зональна оклейка, підготовка глиною',
      'Full or zone wrap, clay prep',
      'Полная или зональная оклейка, подготовка глиной',
    ),
    detail: L(
      'Оклейка кузова вінілом: мийка, глина, знежирення, розкрій, сушка швів. Повне авто від 18 000 ₴, дах від 4 200 ₴, капот/дзеркала — часткова зона. Плівка на бруд і бітум не лягає.',
      'Vinyl wrap: wash, clay, degrease, plot, seam heat. Full car from ₴18,000, roof from ₴4,200, hood/mirrors as a zone. Film will not stick to dirt or tar.',
      'Оклейка винилом: мойка, глина, обезжиривание, раскрой. Полное авто от 18 000 ₴, крыша от 4 200 ₴. Пленка на грязь не ложится.',
    ),
    priceHint: L(
      'від 4 200 ₴ · робота',
      'from ₴4,200 · labour',
      'от 4 200 ₴ · работа',
    ),
    keywords: ['винил', 'vinyl', 'wrap', 'плёнк', 'оклей', 'бренд'],
    workIds: ['wrap', 'wrap-partial', 'wrap-roof'],
    icon: CupertinoIcons.square_stack,
    color: Color(0xFF48484A),
  ),
  AutoSphere(
    id: 'glass',
    title: L('Скло / тонування', 'Glass / tinting', 'Стекло / тонировка'),
    subtitle: L(
      'Скол, лобове, тонування за нормами, ADAS після скла',
      'Chip, windscreen, legal tint, ADAS after glass',
      'Скол, лобовое, тонировка по нормам, ADAS после стекла',
    ),
    detail: L(
      'Скло: скол лобового (полімер, доки тріщина не пішла), заміна лобового/бокового, тонування за нормами PL. Після лобового з камерою — калібрування ADAS. Скол від 800 ₴, тонування від 2 800 ₴.',
      'Glass: windshield chip (resin before it runs), windscreen/side replacement, tint within PL limits. A camera windshield needs ADAS calibration. Chip from ₴800, tint from ₴2,800.',
      'Стекло: скол лобового (полимер, пока трещина не ушла), замена, тонировка по нормам PL. После лобового с камерой — калибровка ADAS. Скол от 800 ₴, тонировка от 2 800 ₴.',
    ),
    priceHint: L(
      'від 800 ₴ · робота',
      'from ₴800 · labour',
      'от 800 ₴ · работа',
    ),
    keywords: ['скло', 'стекл', 'glass', 'тонир', 'tint', 'лобов'],
    workIds: ['glass', 'glass-chip', 'tint'],
    icon: CupertinoIcons.square,
    color: Color(0xFF007AFF),
  ),
  AutoSphere(
    id: 'interior',
    title: L('Салон / перетяжка', 'Interior / retrim', 'Салон / перетяжка'),
    subtitle: L(
      'Шкіра, Alcantara, кермо, стеля — матеріал під зиму',
      'Leather, Alcantara, wheel, headliner — winter-grade hide',
      'Кожа, Alcantara, руль, потолок — материал под зиму',
    ),
    detail: L(
      'Салон: перетяжка шкірою або Alcantara, кермо, стеля, люк. Беремо матеріал, який не тріскає за одну зиму; дешевшу площу краще зменшити, ніж економити на шкурі. Від 8 500 ₴ за зону; стеля від 5 500 ₴.',
      'Interior: leather or Alcantara retrim, wheel, headliner, sunroof. We use hide that survives a winter; less area is better than cheap leather. Zone from ₴8,500; headliner from ₴5,500.',
      'Салон: кожа или Alcantara, руль, потолок, люк. Материал, который не трескается за зиму. От 8 500 ₴ за зону; потолок от 5 500 ₴.',
    ),
    priceHint: L(
      'від 5 500 ₴ · робота',
      'from ₴5,500 · labour',
      'от 5 500 ₴ · работа',
    ),
    keywords: ['салон', 'перетяж', 'interior', 'кожа', 'alcantara', 'руль'],
    workIds: ['interior', 'headliner'],
    icon: CupertinoIcons.person,
    color: Color(0xFFA2845E),
  ),
  AutoSphere(
    id: 'ac',
    title: L('Кондиціонер / заправка', 'A/C recharge', 'Кондиционер / заправка'),
    subtitle: L(
      'Вакуум, течешукач, заправка R134a / R1234yf за вагою',
      'Vacuum, leak hunt, R134a / R1234yf by weight',
      'Вакуум, течеискатель, заправка R134a / R1234yf по весу',
    ),
    detail: L(
      'Кондиціонер: вакуум, пошук витоку азотом/UV, заправка R134a або R1234yf за вагою з мануалу, антифриз компресора. Заправка «на око» без вакууму — гроші в повітря. Від 1 400 ₴; радіатор і трубки — окремо.',
      'A/C: vacuum, nitrogen/UV leak hunt, R134a or R1234yf by the book weight, PAG oil. A refill without vacuum is money into the air. From ₴1,400; condenser and pipes extra.',
      'Кондиционер: вакуум, поиск утечки азотом/UV, заправка R134a или R1234yf по весу. Заправка без вакуума — деньги в воздух. От 1 400 ₴; радиатор и трубки отдельно.',
    ),
    priceHint: L(
      'від 1 400 ₴ · робота',
      'from ₴1,400 · labour',
      'от 1 400 ₴ · работа',
    ),
    keywords: ['конди', 'фреон', 'ac', 'climate', 'холод'],
    workIds: ['ac'],
    icon: CupertinoIcons.snow,
    color: Color(0xFF64D2FF),
  ),
  AutoSphere(
    id: 'tow',
    title: L('Евакуатор / допомога на дорозі', 'Tow / roadside help', 'Эвакуатор / помощь на дороге'),
    subtitle: L(
      'Платформа, AWD без прокрутки, прикурювання, кільцева',
      'Flatbed, AWD without spinning, jump, ring road',
      'Платформа, AWD без прокрутки, прикуривание, кольцевая',
    ),
    detail: L(
      'Евакуатор по Варшаві та кільцевій: платформа, часткове навантаження, прикурювання, запасне колесо. Повний привід і АКПП — лише на платформі, без прокрутки кардану. Від 1 200 ₴ у місті; за місто — за км.',
      'Tow in Warsaw and on the ring: flatbed, dollies, jump start, spare wheel. AWD and automatics travel on a flatbed only — no spinning the prop. From ₴1,200 in town; extra km billed.',
      'Эвакуатор по Варшаве и кольцевой: платформа, частичная погрузка, прикуривание. Полный привод и АКПП — только на платформе. От 1 200 ₴ в городе; за город — по км.',
    ),
    priceHint: L(
      'від 1 200 ₴ · виїзд',
      'from ₴1,200 · call-out',
      'от 1 200 ₴ · выезд',
    ),
    keywords: ['евак', 'букс', 'tow', 'roadside', 'прикур', 'дтп'],
    workIds: ['tow'],
    icon: CupertinoIcons.bus,
    color: Color(0xFFFF9500),
  ),
  AutoSphere(
    id: 'service',
    title: L('ТО / масло / фільтри', 'Service / oil / filters', 'ТО / масло / фильтры'),
    subtitle: L(
      'Олива за VIN, фільтри, антифриз, свічки за пробігом',
      'Oil by VIN, filters, coolant, plugs by mileage',
      'Масло по VIN, фильтры, антифриз, свечи по пробегу',
    ),
    detail: L(
      'Регламентне ТО: олива за допуском VIN (не «як у сусіда»), масляний, повітряний і салонний фільтри, антифриз, свічки за пробігом. Зливний болт із шайбою міняємо за мануалом. Олива від 1 100 ₴ робота + матеріали.',
      'Scheduled service: oil by VIN spec (not a neighbour’s grade), oil/air/cabin filters, coolant, plugs by mileage. Crush-washer drain bolts are replaced. Oil labour from ₴1,100 plus materials.',
      'Регламентное ТО: масло по допуску VIN, масляный, воздушный и салонный фильтры, антифриз, свечи. Сливной болт с шайбой меняем по мануалу. Масло от 1 100 ₴ работа + материалы.',
    ),
    priceHint: L(
      'від 350 ₴ · робота',
      'from ₴350 · labour',
      'от 350 ₴ · работа',
    ),
    keywords: ['то', 'масл', 'oil', 'фильтр', 'service', 'coolant', 'антифриз'],
    workIds: ['oil', 'coolant', 'plugs', 'cabin-filter'],
    icon: CupertinoIcons.wrench,
    color: Color(0xFF5AC8FA),
  ),
  ...extraSpheres,
];

List<AutoSphere> searchSpheres(String query, {AppLang lang = AppLang.uk}) {
  final q = _fold(query.trim());
  if (q.isEmpty) {
    return List<AutoSphere>.from(autoSpheres);
  }
  final scored = <({AutoSphere sphere, int score})>[];
  for (final sphere in autoSpheres) {
    var score = 0;
    final hay = _fold([
      sphere.title.uk,
      sphere.title.en,
      sphere.title.ru,
      sphere.subtitle.uk,
      sphere.subtitle.en,
      sphere.subtitle.ru,
      sphere.detail.uk,
      sphere.detail.en,
      sphere.detail.ru,
      ...sphere.keywords,
    ].join(' '));
    if (hay.contains(q)) {
      score += 12;
    }
    if (_fold(sphere.title.of(lang)).contains(q) ||
        _fold(sphere.subtitle.of(lang)).contains(q)) {
      score += 4;
    }
    for (final key in sphere.keywords) {
      final k = _fold(key);
      if (q.contains(k) || k.contains(q)) {
        score += 5;
      }
    }
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2);
    for (final token in tokens) {
      if (hay.contains(token)) {
        score += 3;
      }
    }
    if (score > 0) {
      scored.add((sphere: sphere, score: score));
    }
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return [for (final item in scored) item.sphere];
}

String _fold(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll('ґ', 'г')
      .replaceAll("'", '')
      .replaceAll('ʼ', '')
      .replaceAll('’', '');
}

AutoSphere? sphereById(String id) {
  for (final sphere in autoSpheres) {
    if (sphere.id == id) {
      return sphere;
    }
  }
  return null;
}

List<AutoSphere> spheresFromIds(List<String> ids) {
  return [
    for (final id in ids)
      if (sphereById(id) != null) sphereById(id)!,
  ];
}
