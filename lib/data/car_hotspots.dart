import '../core/l10n/app_lang.dart';

class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class CarHotspot {
  const CarHotspot({
    required this.id,
    required this.pos,
    required this.label,
    required this.hint,
    required this.sphereId,
  });

  final String id;
  final Vec3 pos;
  final L label;
  final L hint;
  final String sphereId;

  CarHotspot copyWith({Vec3? pos}) {
    return CarHotspot(
      id: id,
      pos: pos ?? this.pos,
      label: label,
      hint: hint,
      sphereId: sphereId,
    );
  }
}

const carHotspots = <CarHotspot>[
  CarHotspot(
    id: 'engine',
    pos: Vec3(58, 40, 0),
    label: L('Двигун / капот', 'Engine / hood', 'Двигатель / капот'),
    hint: L(
      'Шум мотора, індикатор несправності, ГРМ або турбіна.',
      'Engine noise, check-engine light, timing or turbo.',
      'Шум мотора, индикатор неисправности, ГРМ или турбина.',
    ),
    sphereId: 'engine',
  ),
  CarHotspot(
    id: 'battery',
    pos: Vec3(70, 36, 22),
    label: L('АКБ / електрика', 'Battery / electrics', 'АКБ / электрика'),
    hint: L(
      'АКБ під навантаженням, стартер, генератор, джгути.',
      'Load-test the battery, starter, alternator, looms.',
      'АКБ под нагрузкой, стартер, генератор, жгуты.',
    ),
    sphereId: 'electronics',
  ),
  CarHotspot(
    id: 'headlight-r',
    pos: Vec3(96, 28, 28),
    label: L('Права фара', 'Right headlight', 'Правая фара'),
    hint: L(
      'Не світить, запотіла, потрібна привʼязка після заміни.',
      'Dead, misted, or needs pairing after a replacement.',
      'Не светит, запотела, нужна привязка после замены.',
    ),
    sphereId: 'coding',
  ),
  CarHotspot(
    id: 'headlight-l',
    pos: Vec3(96, 28, -28),
    label: L('Ліва фара', 'Left headlight', 'Левая фара'),
    hint: L(
      'Не світить, запотіла, потрібна привʼязка після заміни.',
      'Dead, misted, or needs pairing after a replacement.',
      'Не светит, запотела, нужна привязка после замены.',
    ),
    sphereId: 'coding',
  ),
  CarHotspot(
    id: 'windshield',
    pos: Vec3(28, 62, 0),
    label: L('Лобове скло', 'Windshield', 'Лобовое стекло'),
    hint: L(
      'Скол, тріщина, заміна лобового, тонування, калібрування ADAS.',
      'Chip, crack, windscreen replace, tint, ADAS calibration.',
      'Скол, трещина, замена лобового, тонировка, калибровка ADAS.',
    ),
    sphereId: 'glass',
  ),
  CarHotspot(
    id: 'roof',
    pos: Vec3(-6, 80, 0),
    label: L('Дах / карбон', 'Roof / carbon', 'Крыша / карбон'),
    hint: L(
      'Оклейка даху, real carbon, сколи від гравію.',
      'Roof wrap, real carbon, stone-chip zone.',
      'Оклейка крыши, real carbon, сколы от гравия.',
    ),
    sphereId: 'carbon',
  ),
  CarHotspot(
    id: 'door-r',
    pos: Vec3(8, 38, 42),
    label: L('Праві двері', 'Right door', 'Правая дверь'),
    hint: L(
      'Подряпина до ґрунту, скол, локальне фарбування або вініл.',
      'Scratch to primer, chip, spot paint or vinyl.',
      'Царапина до грунта, скол, локальная покраска или винил.',
    ),
    sphereId: 'paint',
  ),
  CarHotspot(
    id: 'door-l',
    pos: Vec3(8, 38, -42),
    label: L('Ліві двері', 'Left door', 'Левая дверь'),
    hint: L(
      'Подряпина до ґрунту, скол, локальне фарбування або вініл.',
      'Scratch to primer, chip, spot paint or vinyl.',
      'Царапина до грунта, скол, локальная покраска или винил.',
    ),
    sphereId: 'paint',
  ),
  CarHotspot(
    id: 'interior',
    pos: Vec3(-8, 52, 8),
    label: L('Салон', 'Interior', 'Салон'),
    hint: L(
      'Перетяжка, хімчистка, кермо, стеля.',
      'Retrim, shampoo, wheel, headliner.',
      'Перетяжка, химчистка, руль, потолок.',
    ),
    sphereId: 'interior',
  ),
  CarHotspot(
    id: 'wheel-fr',
    pos: Vec3(62, 16, 40),
    label: L('Переднє праве колесо', 'Front right wheel', 'Переднее правое колесо'),
    hint: L(
      'Стук опори, важіль, ШРУС, підшипник маточини.',
      'Top-mount knock, arm, CV joint, hub bearing.',
      'Стук опоры, рычаг, ШРУС, подшипник ступицы — если стучит на неровностях.',
    ),
    sphereId: 'chassis',
  ),
  CarHotspot(
    id: 'wheel-fl',
    pos: Vec3(62, 16, -40),
    label: L('Переднє ліве колесо', 'Front left wheel', 'Переднее левое колесо'),
    hint: L(
      'Стук опори, важіль, ШРУС, підшипник маточини.',
      'Top-mount knock, arm, CV joint, hub bearing.',
      'Стук опоры, рычаг, ШРУС, подшипник ступицы — если стучит на неровностях.',
    ),
    sphereId: 'chassis',
  ),
  CarHotspot(
    id: 'wheel-rr',
    pos: Vec3(-62, 16, 40),
    label: L('Заднє праве колесо', 'Rear right wheel', 'Заднее правое колесо'),
    hint: L(
      'Шиномонтаж, баланс, прокол, биття диска.',
      'Tyre fitting, balance, puncture, wheel run-out.',
      'Шиномонтаж, баланс, прокол, биение диска.',
    ),
    sphereId: 'tires',
  ),
  CarHotspot(
    id: 'wheel-rl',
    pos: Vec3(-62, 16, -40),
    label: L('Заднє ліве колесо', 'Rear left wheel', 'Заднее левое колесо'),
    hint: L(
      'Шиномонтаж, баланс, прокол, биття диска.',
      'Tyre fitting, balance, puncture, wheel run-out.',
      'Шиномонтаж, баланс, прокол, биение диска.',
    ),
    sphereId: 'tires',
  ),
  CarHotspot(
    id: 'brake-fr',
    pos: Vec3(62, 16, 22),
    label: L('Передні гальма', 'Front brakes', 'Передние тормоза'),
    hint: L(
      'Скрегіт колодок, вібрація дисків, рідина, супорт.',
      'Pad squeal, disc vibration, fluid, caliper.',
      'Скрип колодок, вибрация дисков, жидкость, суппорт.',
    ),
    sphereId: 'brakes',
  ),
  CarHotspot(
    id: 'exhaust',
    pos: Vec3(-108, 10, 18),
    label: L('Вихлоп', 'Exhaust', 'Выхлоп'),
    hint: L(
      'Прогар, даунпайп, кат, гучний глушник — після заміни потрібна прошивка.',
      'Burn-through, downpipe, cat, loud silencer — remap after the pipe.',
      'Прогар, даунпайп, кат, громкий глушитель — после замены нужна прошивка.',
    ),
    sphereId: 'exhaust',
  ),
  CarHotspot(
    id: 'rear',
    pos: Vec3(-100, 32, 0),
    label: L('Багажник / зад', 'Trunk / rear', 'Багажник / зад'),
    hint: L(
      'Бампер, скол, PPF, оклейка задньої частини.',
      'Bumper, chip, PPF, rear wrap.',
      'Бампер, скол, PPF, оклейка задней части.',
    ),
    sphereId: 'wrap',
  ),
  CarHotspot(
    id: 'undercarriage',
    pos: Vec3(0, 6, 0),
    label: L('Днище / підвіска', 'Undercarriage', 'Днище / подвеска'),
    hint: L(
      'Люфти підвіски, антикор днища, витік оливи або антифризу.',
      'Suspension play, underbody rustproofing, oil or coolant leak.',
      'Люфты подвески, антикор днища, течь масла или антифриза.',
    ),
    sphereId: 'chassis',
  ),
  CarHotspot(
    id: 'ac',
    pos: Vec3(18, 48, 0),
    label: L('Кондиціонер', 'A/C', 'Кондиционер'),
    hint: L(
      'Не холодить: вакуум, витік, заправка за вагою фреону.',
      'Not cooling: vacuum, leak, refrigerant by weight.',
      'Не холодит: вакуум, утечка, заправка по весу фреона.',
    ),
    sphereId: 'ac',
  ),
  CarHotspot(
    id: 'steering',
    pos: Vec3(18, 44, -12),
    label: L('Кермо', 'Steering wheel', 'Руль'),
    hint: L(
      'Перетяжка керма, шлейф SRS, люфт рейки.',
      'Wheel retrim, SRS clock spring, rack play.',
      'Перетяжка руля, шлейф SRS, люфт рейки.',
    ),
    sphereId: 'interior',
  ),
  CarHotspot(
    id: 'headunit',
    pos: Vec3(16, 42, 0),
    label: L('ГУ / магнітола', 'Head unit', 'ГУ / магнитола'),
    hint: L(
      'CarPlay / Android Auto, рамка під модель, камера заднього виду.',
      'CarPlay / Android Auto, model fascia, reversing camera.',
      'CarPlay / Android Auto, рамка под модель, камера заднего вида.',
    ),
    sphereId: 'electronics',
  ),
  CarHotspot(
    id: 'seat-l',
    pos: Vec3(-6, 34, -14),
    label: L('Сидіння', 'Seat', 'Сиденье'),
    hint: L(
      'Перетяжка, знос бічної підтримки, хімчистка тканини.',
      'Retrim, worn bolster, fabric shampoo.',
      'Перетяжка, износ боковой поддержки, химчистка ткани.',
    ),
    sphereId: 'interior',
  ),
];

CarHotspot? hotspotById(String id) {
  for (final hotspot in carHotspots) {
    if (hotspot.id == id) {
      return hotspot;
    }
  }
  return null;
}
