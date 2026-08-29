import 'dart:math' as math;

import '../core/l10n/app_lang.dart';
import '../domain/models/crm_models.dart';
import '../domain/models/shop_models.dart';
import 'shop_network.dart';

export 'shop_network.dart'
    show generateNetworkShops, networkCities, matchNetworkCityId, centerForNetworkCity;

part 'shop_extra.dart';

List<ShopProfile>? _allShopsCache;

List<ShopProfile> get allNetworkShops {
  return _allShopsCache ??= [...seededShops, ...generateNetworkShops()];
}

const seededShops = <ShopProfile>[
  ShopProfile(
    id: 'pitlane',
    name: L('Ta4ka Варшава · кодинг', 'Ta4ka Warsaw · coding', 'Ta4ka Варшава · кодинг'),
    cityId: 'warsaw',
    city: L('Варшава', 'Warsaw', 'Варшава'),
    address: L('ul. Waryńskiego, 12', '12 Waryńskiego St', 'ul. Waryńskiego, 12'),
    distanceKm: 2.1,
    lat: 52.2204,
    lng: 21.0158,
    rating: 4.9,
    reviewCount: 186,
    tags: [
      L('BMW / M', 'BMW / M', 'BMW / M'),
      L('Чіп-тюнінг', 'Chip tuning', 'Чип-тюнинг'),
      L('Авто електрика', 'Auto electrics', 'Автоэлектрика'),
    ],
    workIds: [
      'diag-comp',
      'battery',
      'coding',
      'tuning',
      'wiring',
      'starter-alt',
      'alarm',
      'keys',
      'lights-led',
      'lights-restore',
      'android',
      'srs',
      'adas',
    ],
    liveFromBay: true,
    mapaHelp: true,
    positioning: 'service',
    phone: '+380441112233',
    lead: L(
      'Кодування BMW і діагностика електрики. Камера в боксі, слоти з 09:00 до 18:00.',
      'BMW coding and electrical diagnostics. Bay camera on, slots 09:00–18:00.',
      'Кодирование BMW и диагностика электрики. Камера в боксе, слоты с 09:00 до 18:00.',
    ),
    masters: [
      ShopMaster(
        id: 'm-oleg',
        name: L('Олег', 'Oleg', 'Олег'),
        specialty: MasterSpecialty.electrician,
        bio: L(
          'Автоелектрик. Кодування F/G-серії BMW, ODIS/ISTA, стабільне живлення перед записом.',
          'Auto electrician. BMW F/G-series coding, ODIS/ISTA, stable voltage before a write.',
          'Автоэлектрик. Кодирование F/G-серии BMW, ODIS/ISTA, стабильное питание перед записью.',
        ),
      ),
      ShopMaster(
        id: 'm-igor',
        name: L('Ігор', 'Ihor', 'Игорь'),
        specialty: MasterSpecialty.chassis,
        bio: L(
          'Ходова: люфти на підйомнику, колодки і розвал після заміни важелів.',
          'Chassis: play on the lift, pads and alignment after arm replacement.',
          'Ходовая: люфты на подъёмнике, колодки и развал после замены рычагов.',
        ),
      ),
    ],
    reviews: [
      ShopReview(
        author: 'Марина',
        stars: 5,
        text: L(
          'Показали код помилки на екрані сканера і пояснили, що міняти. Без зайвих робіт.',
          'They showed the fault on the scanner and explained what to replace. No extra jobs.',
          'Показали код ошибки на экране сканера и объяснили, что менять. Без лишних работ.',
        ),
      ),
      ShopReview(
        author: 'Taras',
        stars: 5,
        text: L(
          'Прошивка з бекапом стоку. Відео з боксу прийшло під час запису.',
          'Remap with a stock backup. Bay video arrived while the file was writing.',
          'Прошивка с бэкапом стока. Видео из бокса пришло во время записи.',
        ),
      ),
    ],
    gallery: [
      ShopGalleryItem(title: L('Бокс 2, ніч', 'Bay 2, night', 'Бокс 2, ночь'), icon: IconKey.night),
      ShopGalleryItem(title: L('Стенд ECU', 'ECU bench', 'Стенд ECU'), icon: IconKey.chips),
      ShopGalleryItem(title: L('Після M-пакета', 'After M pack', 'После M-пакета'), icon: IconKey.bay),
    ],
  ),
  ShopProfile(
    id: 'voltwerk',
    name: L('Ta4ka Варшава · електрика', 'Ta4ka Warsaw · electrics', 'Ta4ka Варшава · электрика'),
    cityId: 'warsaw',
    city: L('Варшава', 'Warsaw', 'Варшава'),
    address: L('ul. Grochowska, 41', '41 Grochowska St', 'ul. Grochowska, 41'),
    distanceKm: 4.6,
    lat: 52.2491,
    lng: 21.0832,
    rating: 4.7,
    reviewCount: 94,
    tags: [
      L('VAG', 'VAG', 'VAG'),
      L('Авто електрика', 'Auto electrics', 'Автоэлектрика'),
      L('Фари / захист', 'Lights / covers', 'Фары / защита'),
    ],
    workIds: [
      'diag-comp',
      'battery',
      'coding',
      'glass',
      'glass-chip',
      'tint',
      'lights-restore',
      'adas',
      'srs',
      'wiring',
    ],
    liveFromBay: true,
    mapaHelp: false,
    positioning: 'garage',
    phone: '+380442223344',
    lead: L(
      'Електрика VAG: привʼязка фар, джгути, ADAS після лобового. Слоти по годині, Пн–Сб 09:00–18:00.',
      'VAG electrics: headlight pairing, looms, ADAS after glass. Hourly slots, Mon–Sat 09:00–18:00.',
      'Электрика VAG: привязка фар, жгуты, ADAS после лобового. Слоты по часу, Пн–Сб 09:00–18:00.',
    ),
    masters: [
      ShopMaster(
        id: 'm-andriy',
        name: L('Андрій', 'Andriy', 'Андрей'),
        specialty: MasterSpecialty.electrician,
        bio: L(
          'VAG-електрик. Привʼязка фар, блоки, джгути CAN.',
          'VAG electrician. Headlight pairing, modules, CAN looms.',
          'VAG-электрик. Привязка фар, блоки, жгуты CAN.',
        ),
      ),
      ShopMaster(
        id: 'm-iryna',
        name: L('Ірина', 'Iryna', 'Ирина'),
        specialty: MasterSpecialty.maintenance,
        bio: L(
          'Регламентне ТО поруч із електрикою, щоб не ганяти авто на другий візит.',
          'Scheduled service next to electrics so the car is not booked twice.',
          'Регламентное ТО рядом с электрикой, чтобы не гонять авто на второй визит.',
        ),
      ),
    ],
    reviews: [
      ShopReview(
        author: 'Оксана',
        stars: 5,
        text: L(
          'Привʼязали фару за годину. У звіті видно момент кодування.',
          'Paired the headlight in an hour. The report shows the coding moment.',
          'Привязали фару за час. В отчёте видно момент кодирования.',
        ),
      ),
      ShopReview(
        author: 'Nazar',
        stars: 4,
        text: L(
          'Слот на 11:00 витриманий. Не просили «підʼїжджайте зранку і чекайте».',
          'The 11:00 slot was kept. Nobody asked us to “come in the morning and wait”.',
          'Слот на 11:00 выдержан. Не просили «подъезжайте с утра и ждите».',
        ),
      ),
    ],
    gallery: [
      ShopGalleryItem(title: L('Діагностика CAN', 'CAN diagnostics', 'Диагностика CAN'), icon: IconKey.chips),
      ShopGalleryItem(title: L('Бокс електрики', 'Electrics bay', 'Бокс электрики'), icon: IconKey.bay),
    ],
  ),
  ShopProfile(
    id: 'nordlift',
    name: L('Ta4ka Варшава · ходова', 'Ta4ka Warsaw · chassis', 'Ta4ka Варшава · ходовая'),
    cityId: 'warsaw',
    city: L('Варшава', 'Warsaw', 'Варшава'),
    address: L('al. Jerozolimskie, 16', '16 Jerozolimskie Ave', 'al. Jerozolimskie, 16'),
    distanceKm: 7.8,
    lat: 52.2297,
    lng: 21.0022,
    rating: 4.5,
    reviewCount: 61,
    tags: [
      L('Ходова', 'Chassis', 'Ходовая'),
      L('Малярка', 'Paint', 'Малярка'),
      L('Розвал', 'Alignment', 'Развал'),
    ],
    workIds: [
      'pads',
      'discs',
      'brake-lathe',
      'align',
      'diag-chassis',
      'steering',
      'cv-joint',
      'air-suspension',
    ],
    liveFromBay: true,
    mapaHelp: true,
    positioning: 'dealer',
    phone: '+380443334455',
    lead: L(
      'Ходова і гальма: підйомник, проточка дисків, розвал Hunter після заміни важелів. Пн–Сб 09:00–18:00.',
      'Chassis and brakes: lift, disc machining, Hunter alignment after arms. Mon–Sat 09:00–18:00.',
      'Ходовая и тормоза: подъёмник, проточка дисков, развал Hunter после рычагов. Пн–Сб 09:00–18:00.',
    ),
    masters: [
      ShopMaster(
        id: 'm-dmytro',
        name: L('Дмитро', 'Dmytro', 'Дмитрий'),
        specialty: MasterSpecialty.chassis,
        bio: L(
          'Ходова: колодки, диски, люфти. Показує знос на підйомнику до кошторису.',
          'Chassis: pads, discs, play. Shows wear on the lift before the quote.',
          'Ходовая: колодки, диски, люфты. Показывает износ на подъёмнике до сметы.',
        ),
      ),
      ShopMaster(
        id: 'm-serhiy',
        name: L('Сергій', 'Serhiy', 'Сергей'),
        specialty: MasterSpecialty.motorist,
        bio: L(
          'Моторист. Закриває стук, якщо після ходової він іде з моторного відсіку.',
          'Engine tech. Covers a knock if after chassis work it is coming from the bay.',
          'Моторист. Закрывает стук, если после ходовой он идёт из моторного отсека.',
        ),
      ),
    ],
    reviews: [
      ShopReview(
        author: 'Віктор',
        stars: 5,
        text: L(
          'Взяли в ранковий слот. Колодки і розвал за один заїзд, без другого візиту.',
          'Taken in the morning slot. Pads and alignment in one visit, no second trip.',
          'Взяли в утренний слот. Колодки и развал за один заезд, без второго визита.',
        ),
      ),
    ],
    gallery: [
      ShopGalleryItem(title: L('Чотири стійки', 'Four-post lift', 'Четыре стойки'), icon: IconKey.lift),
      ShopGalleryItem(title: L('Камера малярки', 'Paint booth', 'Камера малярки'), icon: IconKey.paint),
    ],
  ),
  ShopProfile(
    id: 'torque-lviv',
    name: L('Ta4ka Варшава · двигун', 'Ta4ka Warsaw · engine', 'Ta4ka Варшава · двигатель'),
    cityId: 'warsaw',
    city: L('Варшава', 'Warsaw', 'Варшава'),
    address: L('ul. Modlińska, 355', '355 Modlińska St', 'ul. Modlińska, 355'),
    distanceKm: 11.4,
    lat: 52.2921,
    lng: 20.9674,
    rating: 4.8,
    reviewCount: 112,
    tags: [
      L('Двигун', 'Engine', 'Двигатель'),
      L('ГРМ', 'Timing', 'ГРМ'),
      L('ТО', 'Service', 'ТО'),
    ],
    workIds: [
      'timing',
      'oil',
      'coolant',
      'plugs',
      'cabin-filter',
      'diag-comp',
      'exhaust',
      'stage3',
      'engine-repair',
      'turbo',
      'dpf',
      'clutch',
      'gearbox',
      'gearbox-flush',
      'injectors',
      'radiator',
      'lpg',
    ],
    liveFromBay: true,
    positioning: 'garage',
    phone: '+380322556677',
    lead: L(
      'Моторний цех: ГРМ, турбіна, ТО за VIN, дефектування до кошторису. Пн–Сб 09:00–18:00.',
      'Engine shop: timing, turbo, VIN-spec service, survey before the quote. Mon–Sat 09:00–18:00.',
      'Моторный цех: ГРМ, турбина, ТО по VIN, дефектовка до сметы. Пн–Сб 09:00–18:00.',
    ),
    masters: [
      ShopMaster(
        id: 'm-pavlo',
        name: L('Павло', 'Pavlo', 'Павел'),
        specialty: MasterSpecialty.motorist,
        bio: L(
          'Моторист. ГРМ, ланцюги, ендоскоп до розбору, фото дефектування.',
          'Engine. Timing, chains, borescope before teardown, survey photos.',
          'Моторист. ГРМ, цепи, эндоскоп до разбора, фото дефектовки.',
        ),
      ),
      ShopMaster(
        id: 'm-sofia',
        name: L('Софія', 'Sofia', 'София'),
        specialty: MasterSpecialty.maintenance,
        bio: L(
          'Регламентне ТО і рідини. Антифризи не змішує, допуск оливи — по VIN.',
          'Scheduled service and fluids. Does not mix coolant; oil spec from the VIN.',
          'Регламентное ТО и жидкости. Антифризы не смешивает, допуск масла — по VIN.',
        ),
      ),
    ],
    reviews: [
      ShopReview(
        author: 'Andrii',
        stars: 5,
        text: L(
          'Бачив розбір мотора на камері боксу, потім записався на те саме авто. Кошторис після фото.',
          'Watched the engine teardown on the bay camera, then booked the same car. Quote after photos.',
          'Видел разбор мотора на камере бокса, потом записался на то же авто. Смета после фото.',
        ),
      ),
    ],
    gallery: [
      ShopGalleryItem(title: L('Розбір 2.0 TSI', '2.0 TSI teardown', 'Разбор 2.0 TSI'), icon: IconKey.engine),
      ShopGalleryItem(title: L('Нічний бокс', 'Night bay', 'Ночной бокс'), icon: IconKey.night),
    ],
  ),
  ...extraShops,
];

const slotClock = <(int, int)>[
  (9, 0),
  (10, 0),
  (11, 0),
  (12, 0),
  (13, 0),
  (14, 0),
  (15, 0),
  (16, 0),
  (17, 0),
];

ShopProfile? shopById(String id) {
  for (final shop in allNetworkShops) {
    if (shop.id == id) return shop;
  }
  return null;
}

bool presetSlotBusy(String shopId, String masterId, DateTime start) {
  if (shopId == 'pitlane' && start.hour == 14 && start.minute == 0) {
    return false;
  }
  if (shopId == 'nordlift' && start.hour == 9 && start.minute == 0) {
    return false;
  }
  final stamp = Object.hash(
    shopId,
    masterId,
    start.year,
    start.month,
    start.day,
    start.hour,
    start.minute,
  );
  return stamp % 5 == 0;
}

String slotKey(String shopId, String masterId, DateTime start) =>
    '$shopId|$masterId|${start.toIso8601String()}';

List<ShopTimeSlot> buildShopSlots({
  required ShopProfile shop,
  required DateTime now,
  required Set<String> taken,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final slots = <ShopTimeSlot>[];
    for (var day = 0; day < 45; day++) {
    final date = today.add(Duration(days: day));
    if (date.weekday == DateTime.sunday) {
      continue;
    }
    for (final clock in slotClock) {
      final start = DateTime(date.year, date.month, date.day, clock.$1, clock.$2);
      if (start.isBefore(now.add(const Duration(minutes: 20)))) {
        continue;
      }
      for (final master in shop.masters) {
        final busy = presetSlotBusy(shop.id, master.id, start) ||
            taken.contains(slotKey(shop.id, master.id, start));
        slots.add(
          ShopTimeSlot(start: start, masterId: master.id, open: !busy),
        );
      }
    }
  }
  return slots;
}

int openSlotsToday(ShopProfile shop, DateTime now, Set<String> taken) {
  return openTimesToday(shop, now, taken).length;
}

List<DateTime> openTimesToday(ShopProfile shop, DateTime now, Set<String> taken) {
  final today = DateTime(now.year, now.month, now.day);
  final seen = <String>{};
  final times = <DateTime>[];
  for (final slot in buildShopSlots(shop: shop, now: now, taken: taken)) {
    if (!slot.open || !sameCalendarDay(slot.start, today)) {
      continue;
    }
    final key = '${slot.start.hour}:${slot.start.minute}';
    if (seen.add(key)) {
      times.add(slot.start);
    }
  }
  times.sort((a, b) => a.compareTo(b));
  return times;
}

bool sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<ShopProfile> filterShops({
  required String cityId,
  required String query,
  required ShopSort sort,
  required DateTime now,
  required Set<String> taken,
  AppLang lang = AppLang.uk,
  double? fromLat,
  double? fromLng,
  Set<String>? sphereWorkIds,
}) {
  var list = allNetworkShops.where((shop) {
    if (cityId != 'all' && shop.cityId != cityId) {
      return false;
    }
    if (sphereWorkIds != null && sphereWorkIds.isNotEmpty) {
      final hit = shop.workIds.any(sphereWorkIds.contains);
      if (!hit) {
        return false;
      }
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    final hay = [
      shop.name.of(lang),
      shop.address.of(lang),
      shop.city.of(lang),
      ...shop.tags.map((tag) => tag.of(lang)),
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }).toList();

  if (fromLat != null && fromLng != null) {
    list = [
      for (final shop in list)
        shop.copyWith(distanceKm: haversineKm(fromLat, fromLng, shop.lat, shop.lng)),
    ];
  }

  int slots(ShopProfile shop) => openSlotsToday(shop, now, taken);

  list.sort((a, b) {
    return switch (sort) {
      ShopSort.rating => b.rating.compareTo(a.rating),
      ShopSort.distance => a.distanceKm.compareTo(b.distanceKm),
      ShopSort.slotsToday => slots(b).compareTo(slots(a)),
    };
  });
  return list;
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;
