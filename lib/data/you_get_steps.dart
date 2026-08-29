import '../core/l10n/app_lang.dart';
import '../domain/models/crm_models.dart';

part 'you_get_extra.dart';

extension ServiceWorkYouGet on ServiceWork {
  List<L> get youGet => youGetSteps[id] ?? youGetFallback;
}

const youGetFallback = [
  L(
    'Огляд і узгодження обсягу з ціною — без сюрпризів у кінці',
    'We inspect and agree the scope and price — no surprise bill',
    'Осмотр и согласование объема с ценой — без сюрпризов в конце',
  ),
  L(
    'Робимо роботу по технології, показуємо вузли в процесі',
    'The work is done to spec; we show you the parts as we go',
    'Делаем работу по технологии, показываем узлы в процессе',
  ),
  L(
    'Перевіряємо результат разом на авто',
    'We check the result together on the car',
    'Проверяем результат вместе на авто',
  ),
  L(
    'На руки: гарантія, рекомендації і що не входило в ціну',
    'You get: warranty, aftercare and what was not in the price',
    'На руки: гарантия, рекомендации и что не входило в цену',
  ),
];

const youGetSteps = <String, List<L>>{
  'diag-comp': [
    L(
      'Підключаємо дилерський прилад (ODIS / ISTA / Xentry) до OBD',
      'We plug in dealer kit (ODIS / ISTA / Xentry) at the OBD port',
      'Подключаем дилерский прибор (ODIS / ISTA / Xentry) к OBD',
    ),
    L(
      'Зчитуємо помилки по всіх блоках: двигун, АКПП, ABS, подушки',
      'We read faults in every module: engine, gearbox, ABS, airbags',
      'Считываем ошибки по всем блокам: двигатель, АКПП, ABS, подушки',
    ),
    L(
      'Дивимось живі дані — датчики, суміш, тиски, «плаваючі» збої',
      'We watch live data — sensors, mixture, pressures, intermittent glitches',
      'Смотрим живые данные — датчики, смесь, давления, «плавающие» сбои',
    ),
    L(
      'На руки: розшифровка кодів, фото екрана і план, що робити далі',
      'You get: decoded codes, a screen photo and a clear next-step plan',
      'На руки: расшифровка кодов, фото экрана и план, что делать дальше',
    ),
  ],
  'diag-chassis': [
    L(
      'Ставимо авто на підйомник — повний огляд знизу',
      'The car goes on a lift for a full underside inspection',
      'Ставим авто на подъемник — полный осмотр снизу',
    ),
    L(
      'Перевіряємо важелі, сайлентблоки, опори, пильовики, ступиці',
      'We check arms, bushings, mounts, boots and wheel hubs',
      'Проверяем рычаги, сайлентблоки, опоры, пыльники, ступицы',
    ),
    L(
      'Показуємо люфт руками — ви самі бачите, що стукає',
      'We show you the play by hand so you see what knocks',
      'Показываем люфт руками — вы сами видите, что стучит',
    ),
    L(
      'На руки: фото вузлів і список «міняти зараз / ще походить»',
      'You get: photos and a list of “replace now / still ok”',
      'На руки: фото узлов и список «менять сейчас / ещё походит»',
    ),
  ],
  'pads': [
    L(
      'Знімаємо колеса, міряємо залишкову товщину колодок',
      'Wheels off — we measure remaining pad thickness',
      'Снимаем колеса, меряем остаточную толщину колодок',
    ),
    L(
      'Оглядаємо диски, супорти, направляючі, гальмівні шланги',
      'We inspect discs, calipers, sliders and brake hoses',
      'Осматриваем диски, суппорта, направляющие, тормозные шланги',
    ),
    L(
      'Ставимо нові колодки, змащуємо напрямні, прокачуємо якщо треба',
      'New pads go on, sliders get greased, we bleed if needed',
      'Ставим новые колодки, смазываем направляющие, прокачиваем если нужно',
    ),
    L(
      'На руки: старі колодки, замір дисків і рекомендація по осі',
      'You get: old pads, disc measurements and an axle recommendation',
      'На руки: старые колодки, замер дисков и рекомендация по оси',
    ),
  ],
  'discs': [
    L(
      'Міняємо диски комплектом на вісь — щоб не вело при гальмуванні',
      'Discs are replaced as an axle set so the car does not pull',
      'Меняем диски комплектом на ось — чтобы не вело при торможении',
    ),
    L(
      'Разом ставимо колодки, чистимо супорт і направляючі',
      'Pads go on with them; caliper and sliders are cleaned',
      'Вместе ставим колодки, чистим суппорт и направляющие',
    ),
    L(
      'Прокачуємо контур, перевіряємо рівень і хід педалі',
      'We bleed the circuit and check fluid level and pedal feel',
      'Прокачиваем контур, проверяем уровень и ход педали',
    ),
    L(
      'На руки: старі диски, момент затяжки і коротке обкатування',
      'You get: old discs, torque notes and a short bedding-in brief',
      'На руки: старые диски, момент затяжки и короткое обкатывание',
    ),
  ],
  'align': [
    L(
      'Спочатку дивимось тяги і сайлентблоки — кривий важіль зʼїсть гуму',
      'First we check rods and bushings — a bent arm will eat the tires',
      'Сначала смотрим тяги и сайлентблоки — кривой рычаг съест резину',
    ),
    L(
      'Ставимо авто на стенд Hunter, знімаємо поточні кути',
      'On the Hunter rack we capture the current angles',
      'Ставим авто на стенд Hunter, снимаем текущие углы',
    ),
    L(
      'Виставляємо розвал, сходження і кермо «в нуль» за заводськими допусками',
      'Camber, toe and steering wheel are set to factory spec',
      'Выставляем развал, схождение и руль «в ноль» по заводским допускам',
    ),
    L(
      'На руки: роздрук кутів «було / стало» і рекомендація по гумі',
      'You get: a before/after printout and a tire-wear note',
      'На руки: распечатка углов «было / стало» и рекомендация по резине',
    ),
  ],
  'battery': [
    L(
      'Міряємо напругу, пусковий струм і зарядку з генератора під навантаженням',
      'We measure voltage, cranking amps and charging under load',
      'Меряем напряжение, пусковой ток и зарядку с генератора под нагрузкой',
    ),
    L(
      'Якщо АКБ «мертва» — ставимо нову з правильним типом (AGM / EFB / звичайна)',
      'If the battery is dead we fit the right type (AGM / EFB / flooded)',
      'Если АКБ «мертвая» — ставим новую с правильным типом (AGM / EFB / обычная)',
    ),
    L(
      'Реєструємо АКБ у блоці, де це треба (BMW, VAG, Mercedes)',
      'We register the battery in the module where the car requires it',
      'Регистрируем АКБ в блоке, где это нужно (BMW, VAG, Mercedes)',
    ),
    L(
      'На руки: протокол тесту і адаптація вікон / годинника, якщо злетіло',
      'You get: a test printout plus window/clock reset if they dropped',
      'На руки: протокол теста и адаптация окон / часов, если слетело',
    ),
  ],
  'coding': [
    L(
      'Підключаємо ICOM / ODIS / ISTA, читаємо комплектацію авто',
      'We connect ICOM / ODIS / ISTA and read the car’s equipment',
      'Подключаем ICOM / ODIS / ISTA, читаем комплектацию авто',
    ),
    L(
      'Привʼязуємо фари, блоки, датчики — без «сірих» кодів після заміни',
      'We pair headlights, modules and sensors — no leftover grey codes',
      'Привязываем фары, блоки, датчики — без «серых» кодов после замены',
    ),
    L(
      'Вмикаємо опції, які машина вже вміє: відео в русі, дзеркала, світло',
      'We enable options the car already supports: video in motion, mirrors, lights',
      'Включаем опции, которые машина уже умеет: видео в движении, зеркала, свет',
    ),
    L(
      'На руки: список змін, резервна копія кодування і перевірка помилок',
      'You get: a change list, a coding backup and a clean fault scan',
      'На руки: список изменений, резервная копия кодирования и проверка ошибок',
    ),
  ],
  'oil': [
    L(
      'Беремо допуск оливи по VIN, а не «як у сусіда»',
      'Oil spec comes from the VIN, not from a neighbour’s advice',
      'Берем допуск масла по VIN, а не «как у соседа»',
    ),
    L(
      'Зливаємо стару, міняємо фільтр і шайбу / зливний болт, якщо треба',
      'Old oil out, new filter in, washer/drain bolt replaced when required',
      'Сливаем старое, меняем фильтр и шайбу / сливной болт, если нужно',
    ),
    L(
      'Заливаємо точний обʼєм, скидаємо інспекцію / сервісний інтервал',
      'We fill the exact volume and reset the service interval',
      'Заливаем точный объем, сбрасываем инспекцию / сервисный интервал',
    ),
    L(
      'На руки: фото рівня, наклейка з датою і допуск оливи',
      'You get: a level photo, a dated sticker and the oil spec used',
      'На руки: фото уровня, наклейка с датой и допуск масла',
    ),
  ],
  'coolant': [
    L(
      'Перевіряємо тип антифризу (G11 / G12 / G13) — не змішуємо кольори',
      'We confirm coolant type (G11 / G12 / G13) and never mix colours',
      'Проверяем тип антифриза (G11 / G12 / G13) — не смешиваем цвета',
    ),
    L(
      'Зливаємо систему, промиваємо якщо в бачку іржа або «майонез»',
      'We drain the system and flush if the tank shows rust or mayonnaise',
      'Сливаем систему, промываем если в бачке ржавчина или «майонез»',
    ),
    L(
      'Заливаємо свіжий, ганяємо повітря, перевіряємо кришку і патрубки',
      'Fresh fill, air bled, cap and hoses checked',
      'Заливаем свежий, гоняем воздух, проверяем крышку и патрубки',
    ),
    L(
      'На руки: тип рідини, температура відкриття термостата і рекомендація',
      'You get: fluid type, thermostat note and a follow-up recommendation',
      'На руки: тип жидкости, температура открытия термостата и рекомендация',
    ),
  ],
  'timing': [
    L(
      'Фіксуємо вали за мітками, ставимо новий комплект ГРМ',
      'Shafts locked to marks, a new timing kit goes on',
      'Фиксируем валы по меткам, ставим новый комплект ГРМ',
    ),
    L(
      'Разом міняємо помпу і ролики — щоб не розкривати мотор двічі',
      'Water pump and rollers are replaced so the engine is not opened twice',
      'Вместе меняем помпу и ролики — чтобы не вскрывать мотор дважды',
    ),
    L(
      'Виставляємо фази, перевіряємо натяг, запускаємо і слухаємо',
      'Timing is set, tension checked, then we start and listen',
      'Выставляем фазы, проверяем натяг, запускаем и слушаем',
    ),
    L(
      'На руки: фото міток, список заміненого і рекомендація по оливі',
      'You get: mark photos, a parts list and an oil recommendation',
      'На руки: фото меток, список замененного и рекомендация по маслу',
    ),
  ],
  'plugs': [
    L(
      'Дістаємо свічки, дивимось нагар — по ньому видно суміш і пропуски',
      'Plugs come out; the soot tells us about mixture and misfires',
      'Достаем свечи, смотрим нагар — по нему видно смесь и пропуски',
    ),
    L(
      'Ставимо правильний тип (іридій / платина) із зазором по мануалу',
      'The correct type goes in (iridium / platinum) gapped to spec',
      'Ставим правильный тип (иридий / платина) с зазором по мануалу',
    ),
    L(
      'Затягуємо динамометричним ключем — без зірваної різьби в ГБЦ',
      'Torque wrench only — no stripped threads in the head',
      'Затягиваем динамометрическим ключом — без сорванной резьбы в ГБЦ',
    ),
    L(
      'На руки: старі свічки, момент затяжки і скидання адаптацій, якщо треба',
      'You get: old plugs, torque used and adaptations reset if needed',
      'На руки: старые свечи, момент затяжки и сброс адаптаций, если нужно',
    ),
  ],
  'insurance': [
    L(
      'Збираємо дані авто і водія, дивимось історію і франшизу',
      'We collect car and driver data, history and deductible',
      'Собираем данные авто и водителя, смотрим историю и франшизу',
    ),
    L(
      'Підбираємо КАСКО / ОСЦПВ під бюджет — без навʼязаних опцій',
      'CASCO / third-party cover is matched to budget, no forced extras',
      'Подбираем КАСКО / ОСАГО под бюджет — без навязанных опций',
    ),
    L(
      'Пояснюємо, що криє поліс при ДТП, евакуаторі й «тотальній»',
      'We explain what the policy covers in a crash, tow and write-off',
      'Объясняем, что покрывает полис при ДТП, эвакуаторе и «тотальной»',
    ),
    L(
      'На руки: порівняння тарифів, чернетка поліса і чек-лист для ДТП',
      'You get: a rate comparison, a draft policy and an accident checklist',
      'На руки: сравнение тарифов, черновик полиса и чек-лист для ДТП',
    ),
  ],
  'paint': [
    L(
      'Оцінюємо скол / вмʼятину: локалка чи фарбування елемента',
      'We judge the chip or dent: spot repair or a full-panel respray',
      'Оцениваем скол / вмятину: локалка или покраска элемента',
    ),
    L(
      'Підбираємо колір по коду і вифарбовуємо пробник',
      'Colour is matched to the code and a spray-out sample',
      'Подбираем цвет по коду и выкрашиваем пробник',
    ),
    L(
      'Ґрунт, база, лак, сушка в камері — без пилу «з двору»',
      'Primer, base, clear, booth dry — not dust from the yard',
      'Грунт, база, лак, сушка в камере — без пыли «со двора»',
    ),
    L(
      'На руки: фото етапів, полірування стику і гарантія на лак',
      'You get: stage photos, blend polish and a clear-coat warranty',
      'На руки: фото этапов, полировка стыка и гарантия на лак',
    ),
  ],
  'wash': [
    L(
      'Двофазна мийка кузова: піна, потім ручний прохід без піску на лаку',
      'Two-stage body wash: foam, then a hand pass that does not grind grit',
      'Двухфазная мойка кузова: пена, затем ручной проход без песка на лаке',
    ),
    L(
      'Арки, пороги, диски — там, де звичайна мийка не дістає',
      'Arches, sills and wheels — where a quick wash never reaches',
      'Арки, пороги, диски — там, где обычная мойка не достает',
    ),
    L(
      'Салон: пил, килимки, пластик; за бажанням — хімчистка сидінь',
      'Cabin: dust, mats, plastics; seat shampoo on request',
      'Салон: пыль, коврики, пластик; по желанию — химчистка сидений',
    ),
    L(
      'На руки: сухе авто без розводів і захист (віск / кварц), якщо обрали',
      'You get: a dry, streak-free car plus wax/quartz if you chose it',
      'На руки: сухое авто без разводов и защита (воск / кварц), если выбрали',
    ),
  ],
  'tires': [
    L(
      'Знімаємо колеса, демонтуємо гуму, перевіряємо диск на биття',
      'Wheels off, tyres demounted, rims checked for runout',
      'Снимаем колеса, демонтируем резину, проверяем диск на биение',
    ),
    L(
      'Ставимо нові / сезонні шини, балансуємо кожне колесо',
      'New or seasonal tyres go on; every wheel is balanced',
      'Ставим новые / сезонные шины, балансируем каждое колесо',
    ),
    L(
      'Якщо прокол — грибок або латка зсередини, не «джгут на око»',
      'A puncture gets an inside patch or mushroom — not a guesswork plug',
      'Если прокол — грибок или заплатка изнутри, не «жгут на глаз»',
    ),
    L(
      'На руки: протокол балансу, тиск по табличці і мітка сезону',
      'You get: a balance sheet, placard pressures and a season mark',
      'На руки: протокол баланса, давление по табличке и метка сезона',
    ),
  ],
  'tuning': [
    L(
      'Знімаємо стокову прошивку, робимо резервну копію ECU',
      'We read the stock map and back up the ECU',
      'Снимаем стоковую прошивку, делаем резервную копию ECU',
    ),
    L(
      'Пишемо Stage 1 або Stage 2 під залізо: впуск, вихлоп, даунпайп',
      'Stage 1 or Stage 2 is written to match the hardware: intake, exhaust, downpipe',
      'Пишем Stage 1 или Stage 2 под железо: впуск, выхлоп, даунпайп',
    ),
    L(
      'Перевіряємо суміш, наддув і температуру на тестовій поїздці',
      'Mixture, boost and temps are checked on a test drive',
      'Проверяем смесь, наддув и температуру на тестовой поездке',
    ),
    L(
      'На руки: графики «до / після», відкат на сток і список обмежень',
      'You get: before/after graphs, a stock rollback and a limits list',
      'На руки: графики «до / после», откат на сток и список ограничений',
    ),
  ],
  'stage3': [
    L(
      'Дефектування мотора: компресія, ендоскоп, люфти турбіни',
      'Engine survey: compression, borescope, turbo play',
      'Дефектовка мотора: компрессия, эндоскоп, люфты турбины',
    ),
    L(
      'Підбираємо ковані поршні, турбіну, інтеркулер і паливо під ціль',
      'Forged pistons, turbo, intercooler and fueling are specced to the target',
      'Подбираем кованые поршни, турбину, интеркулер и топливо под цель',
    ),
    L(
      'Збірка з моментами, прокладками і контролем фаз',
      'Build with torque specs, gaskets and cam timing control',
      'Сборка с моментами, прокладками и контролем фаз',
    ),
    L(
      'На руки: кошторис заліза, фото розбору і карта обкатки Stage 3',
      'You get: a hardware quote, teardown photos and a Stage 3 break-in map',
      'На руки: смета железа, фото разбора и карта обкатки Stage 3',
    ),
  ],
  'exhaust': [
    L(
      'Оглядаємо тракт: кат, гофра, банки, датчики лямбда',
      'We inspect the tract: cat, flex, boxes, lambda sensors',
      'Осматриваем тракт: кат, гофра, банки, датчики лямбда',
    ),
    L(
      'Ставимо даунпайп / вихлоп під задачу: звук, потік, Євро-норми',
      'Downpipe / system is fitted for the job: sound, flow, emissions',
      'Ставим даунпайп / выхлоп под задачу: звук, поток, Евро-нормы',
    ),
    L(
      'Варимо стики, перевіряємо на витік димом або мильним розчином',
      'Joints are welded; leaks are checked with smoke or soapy water',
      'Варим стыки, проверяем на утечку дымом или мыльным раствором',
    ),
    L(
      'На руки: фото швів, заміри протитиску і рекомендація по прошивці',
      'You get: weld photos, backpressure notes and a remap recommendation',
      'На руки: фото швов, замеры противодавления и рекомендация по прошивке',
    ),
  ],
  'hydro': [
    L(
      'Демонтуємо деталь, миємо і готуємо під плівку',
      'The part comes off, is washed and prepped for film',
      'Демонтируем деталь, моем и готовим под пленку',
    ),
    L(
      'Підбираємо малюнок аквадруку: карбон, дерево, камуфляж',
      'Hydro pattern is chosen: carbon, wood, camo',
      'Подбираем рисунок аквапечати: карбон, дерево, камуфляж',
    ),
    L(
      'Друкуємо у ванні, сушимо, покриваємо лаком',
      'Printed in the tank, dried, then clear-coated',
      'Печатаем в ванне, сушим, покрываем лаком',
    ),
    L(
      'На руки: деталь на авто, фото «було / стало» і догляд за лаком',
      'You get: the part back on the car, before/after photos and care notes',
      'На руки: деталь на авто, фото «было / стало» и уход за лаком',
    ),
  ],
  'carbon': [
    L(
      'Заміряємо елемент, узгоджуємо real carbon чи плівку «під карбон»',
      'We measure the piece and agree real carbon vs carbon-look wrap',
      'Замеряем элемент, согласовываем real carbon или пленку «под карбон»',
    ),
    L(
      'Готуємо поверхню, клеїмо / ставимо накладку без бульбашок',
      'Surface is prepped; overlay or wrap goes on without bubbles',
      'Готовим поверхность, клеим / ставим накладку без пузырей',
    ),
    L(
      'Підрізаємо краї, прогріваємо складки, лакуємо якщо це real carbon',
      'Edges are trimmed, folds heated; real carbon gets a clear coat',
      'Подрезаем края, прогреваем складки, лакируем если это real carbon',
    ),
    L(
      'На руки: гарантія на відшарування і інструкція по мийці',
      'You get: a lift warranty and a wash-care note',
      'На руки: гарантия на отслоение и инструкция по мойке',
    ),
  ],
  'wrap': [
    L(
      'Мийка і глина кузова — плівка не ляже на пісок і бітум',
      'Wash and clay first — wrap will not sit on grit or tar',
      'Мойка и глина кузова — пленка не ляжет на песок и битум',
    ),
    L(
      'Обклеюємо елементи: мат, глянець або брендинг під макет',
      'Panels are wrapped: matte, gloss or branding from the artwork',
      'Оклеиваем элементы: мат, глянец или брендинг под макет',
    ),
    L(
      'Прогріваємо кромки, вирізаємо під ручки, камери, емблеми',
      'Edges are heated; handles, cameras and badges are cut around',
      'Прогреваем кромки, вырезаем под ручки, камеры, эмблемы',
    ),
    L(
      'На руки: фото авто, термін служби плівки і як мити перші дні',
      'You get: car photos, film lifespan and first-days wash rules',
      'На руки: фото авто, срок службы пленки и как мыть первые дни',
    ),
  ],
  'glass': [
    L(
      'Оглядаємо скол / тріщину: ремонт чи заміна лобового',
      'Chip or crack is judged: repair versus a new windshield',
      'Осматриваем скол / трещину: ремонт или замена лобового',
    ),
    L(
      'Якщо тонування — підбираємо % світла в межах правил',
      'For tint we pick a light percentage that stays legal',
      'Если тонировка — подбираем % света в пределах правил',
    ),
    L(
      'Клеїмо скло / плівку, сушимо шви, калібруємо камеру якщо є ADAS',
      'Glass or film goes in, seams cure, ADAS camera is calibrated if fitted',
      'Клеим стекло / пленку, сушим швы, калибруем камеру если есть ADAS',
    ),
    L(
      'На руки: допуск до мийки, гарантія на відшарування і чек ADAS',
      'You get: wash wait time, lift warranty and an ADAS check',
      'На руки: допуск к мойке, гарантия на отслоение и чек ADAS',
    ),
  ],
  'interior': [
    L(
      'Знімаємо сидіння / руль / стелю — фото стану шкіри і швів',
      'Seats / wheel / headliner come out; leather and seams are photographed',
      'Снимаем сиденья / руль / потолок — фото состояния кожи и швов',
    ),
    L(
      'Підбираємо шкіру, Alcantara або нитку під салон',
      'Leather, Alcantara or thread is matched to the cabin',
      'Подбираем кожу, Alcantara или нитку под салон',
    ),
    L(
      'Перетягуємо, проклеюємо, ставимо назад без скрипів і щілин',
      'Retrim, glue-up, refit — no squeaks or gaps',
      'Перетягиваем, проклеиваем, ставим назад без скрипов и щелей',
    ),
    L(
      'На руки: фото «було / стало» і догляд за шкірою перший місяць',
      'You get: before/after photos and first-month leather care',
      'На руки: фото «было / стало» и уход за кожей первый месяц',
    ),
  ],
  'ac': [
    L(
      'Підключаємо станцію, міряємо тиски і шукаємо витік УФ / азотом',
      'The A/C station goes on; pressures and UV/nitrogen leak-down',
      'Подключаем станцию, меряем давления и ищем утечку УФ / азотом',
    ),
    L(
      'Вакуумуємо систему, міняємо фільтр-осушувач якщо треба',
      'We vacuum the system and replace the dryer if needed',
      'Вакуумируем систему, меняем фильтр-осушитель если нужно',
    ),
    L(
      'Заправляємо фреон по вагах виробника, додаємо масло компресора',
      'Refrigerant is weighed in to spec; compressor oil is topped up',
      'Заправляем фреон по весам производителя, добавляем масло компрессора',
    ),
    L(
      'На руки: протокол тисків, температура з дефлекторів і де був витік',
      'You get: a pressure log, vent temperature and where the leak was',
      'На руки: протокол давлений, температура с дефлекторов и где была утечка',
    ),
  ],
  'tow': [
    L(
      'Приймаємо виклик: координати, чи крутяться колеса, чи є ключі',
      'We take the call: pin, whether wheels roll, whether you have keys',
      'Принимаем вызов: координаты, крутятся ли колеса, есть ли ключи',
    ),
    L(
      'Подаємо евакуатор або прикурюємо / міняємо колесо на місці',
      'A truck is dispatched, or we jump-start / change the wheel on site',
      'Подаем эвакуатор или прикуриваем / меняем колесо на месте',
    ),
    L(
      'Веземо на узгоджене СТО, фіксуємо пробіг і стан кузова',
      'We take it to the agreed shop and log mileage plus body condition',
      'Везем на согласованное СТО, фиксируем пробег и состояние кузова',
    ),
    L(
      'На руки: акт передачі, маршрут і контакти майстра, який прийме',
      'You get: a handover sheet, the route and the receiving tech’s contact',
      'На руки: акт передачи, маршрут и контакты мастера, который примет',
    ),
  ],
  'engine-repair': [
    L(
      'Слухаємо мотор, міряємо компресію / витік, дивимось ендоскопом',
      'We listen, measure compression / leak-down, then borescope',
      'Слушаем мотор, меряем компрессию / утечку, смотрим эндоскопом',
    ),
    L(
      'Знімаємо вузол, який винен: ГРМ, турбо, клапанна, піддон',
      'The guilty assembly comes off: timing, turbo, valvetrain, pan',
      'Снимаем узел, который виноват: ГРМ, турбо, клапанная, поддон',
    ),
    L(
      'Дефектуємо деталі на столі, узгоджуємо кошторис до збірки',
      'Parts are surveyed on the bench; the quote is agreed before assembly',
      'Дефектуем детали на столе, согласовываем смету до сборки',
    ),
    L(
      'На руки: фото розбору, список заміни і обкатка після ремонту',
      'You get: teardown photos, a replace list and a post-repair break-in',
      'На руки: фото разбора, список замены и обкатка после ремонта',
    ),
  ],
  ...youGetExtraSteps,
};
