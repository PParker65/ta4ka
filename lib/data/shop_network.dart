import 'dart:math' as math;

import '../core/l10n/app_lang.dart';
import '../domain/models/crm_models.dart';
import '../domain/models/shop_models.dart';
import 'geo_point.dart';

/// Density of the Ta4ka network (demo scale of UA + EU).
class NetworkCity {
  const NetworkCity({
    required this.id,
    required this.nameUk,
    required this.nameEn,
    required this.nameRu,
    required this.lat,
    required this.lng,
    required this.count,
    this.mapaEvery = 3,
  });

  final String id;
  final String nameUk;
  final String nameEn;
  final String nameRu;
  final double lat;
  final double lng;
  final int count;
  final int mapaEvery;
}

const networkCities = <NetworkCity>[
  NetworkCity(id: 'warsaw', nameUk: 'Варшава', nameEn: 'Warsaw', nameRu: 'Варшава', lat: 52.2297, lng: 21.0122, count: 35, mapaEvery: 3),
  NetworkCity(id: 'krakow', nameUk: 'Краків', nameEn: 'Krakow', nameRu: 'Краков', lat: 50.0647, lng: 19.9450, count: 18, mapaEvery: 4),
  NetworkCity(id: 'gdansk', nameUk: 'Гданськ', nameEn: 'Gdansk', nameRu: 'Гданьск', lat: 54.3520, lng: 18.6466, count: 12, mapaEvery: 4),
  NetworkCity(id: 'kyiv', nameUk: 'Київ', nameEn: 'Kyiv', nameRu: 'Киев', lat: 50.4501, lng: 30.5234, count: 48, mapaEvery: 3),
  NetworkCity(id: 'lviv', nameUk: 'Львів', nameEn: 'Lviv', nameRu: 'Львов', lat: 49.8397, lng: 24.0297, count: 22, mapaEvery: 3),
  NetworkCity(id: 'odesa', nameUk: 'Одеса', nameEn: 'Odesa', nameRu: 'Одесса', lat: 46.4825, lng: 30.7233, count: 20, mapaEvery: 3),
  NetworkCity(id: 'kharkiv', nameUk: 'Харків', nameEn: 'Kharkiv', nameRu: 'Харьков', lat: 49.9935, lng: 36.2304, count: 18, mapaEvery: 4),
  NetworkCity(id: 'dnipro', nameUk: 'Дніпро', nameEn: 'Dnipro', nameRu: 'Днепр', lat: 48.4647, lng: 35.0462, count: 14, mapaEvery: 4),
  NetworkCity(id: 'vinnytsia', nameUk: 'Вінниця', nameEn: 'Vinnytsia', nameRu: 'Винница', lat: 49.2331, lng: 28.4682, count: 8, mapaEvery: 3),
  NetworkCity(id: 'brussels', nameUk: 'Брюссель', nameEn: 'Brussels', nameRu: 'Брюссель', lat: 50.8503, lng: 4.3517, count: 4, mapaEvery: 2),
  NetworkCity(id: 'antwerp', nameUk: 'Антверпен', nameEn: 'Antwerp', nameRu: 'Антверпен', lat: 51.2194, lng: 4.4025, count: 3, mapaEvery: 2),
  NetworkCity(id: 'berlin', nameUk: 'Берлін', nameEn: 'Berlin', nameRu: 'Берлин', lat: 52.5200, lng: 13.4050, count: 14, mapaEvery: 4),
  NetworkCity(id: 'prague', nameUk: 'Прага', nameEn: 'Prague', nameRu: 'Прага', lat: 50.0755, lng: 14.4378, count: 10, mapaEvery: 4),
  NetworkCity(id: 'vienna', nameUk: 'Відень', nameEn: 'Vienna', nameRu: 'Вена', lat: 48.2082, lng: 16.3738, count: 9, mapaEvery: 3),
  NetworkCity(id: 'budapest', nameUk: 'Будапешт', nameEn: 'Budapest', nameRu: 'Будапешт', lat: 47.4979, lng: 19.0402, count: 8, mapaEvery: 4),
];

const _brandPrefixes = [
  'AutoPro', 'DriveFix', 'MotorHub', 'PitStop', 'CarLab', 'GearBox',
  'EuroGarage', 'ShiftLine', 'BoltService', 'Ta4kaAuto', 'PrimeSTO',
  'FastLane', 'TechBay', 'WheelHouse', 'Ignite', 'ServicePoint',
  'MasterBay', 'RoadCare', 'AutoCraft', 'MechZone',
];

const _brandSuffixes = [
  'СТО', 'Garage', 'Service', 'Motors', 'Center', 'Workshop', 'Bay', 'Lab',
];

const _streets = [
  'Main', 'Industrial', 'Garage', 'Station', 'Park', 'Central', 'North', 'South',
];

List<ShopProfile>? _generatedCache;

const _techNames = <(String, String, String)>[
  ('Олексій', 'Alex', 'Алексей'),
  ('Павло', 'Paul', 'Павел'),
  ('Ігор', 'Ihor', 'Игорь'),
  ('Марк', 'Mark', 'Марк'),
  ('Тарас', 'Taras', 'Тарас'),
];

const _techBios = <(String, String, String)>[
  ('Діагностика і ремонт у боксі. Пн–Сб 09:00–18:00.', 'Bay diagnostics and repair. Mon–Sat 09:00–18:00.', 'Диагностика и ремонт в боксе. Пн–Сб 09:00–18:00.'),
  ('Ходова і гальма. Слоти щогодини.', 'Chassis and brakes. Hourly slots.', 'Ходовая и тормоза. Слоты каждый час.'),
  ('Двигун і ТО. Камера боксу на записі.', 'Engine and service. Bay camera on the booking.', 'Двигатель и ТО. Камера бокса на записи.'),
];

List<ShopProfile> generateNetworkShops() {
  if (_generatedCache != null) return _generatedCache!;
  final rnd = math.Random(42);
  final out = <ShopProfile>[];
  final workPools = <List<String>>[
    ['diag-comp', 'battery', 'coding', 'oil', 'pads'],
    ['pads', 'discs', 'align', 'diag-chassis', 'steering'],
    ['timing', 'oil', 'coolant', 'plugs', 'turbo'],
    ['glass', 'tint', 'lights-led', 'alarm', 'keys'],
    ['wiring', 'srs', 'adas', 'android', 'starter-alt'],
  ];
  const specialties = [
    MasterSpecialty.electrician,
    MasterSpecialty.chassis,
    MasterSpecialty.motorist,
    MasterSpecialty.maintenance,
  ];

  for (final city in networkCities) {
    for (var i = 0; i < city.count; i++) {
      final id = 'net-${city.id}-$i';
      final prefix = _brandPrefixes[(i + city.id.hashCode.abs()) % _brandPrefixes.length];
      final suffix = _brandSuffixes[(i * 3 + city.count) % _brandSuffixes.length];
      final name = '$prefix $suffix';
      final lat = city.lat + (rnd.nextDouble() - 0.5) * 0.12;
      final lng = city.lng + (rnd.nextDouble() - 0.5) * 0.16;
      final rating = 3.8 + rnd.nextDouble() * 1.2;
      final mapa = (i % city.mapaEvery) == 0;
      final works = workPools[i % workPools.length];
      final street = _streets[i % _streets.length];
      final tech = _techNames[i % _techNames.length];
      final bio = _techBios[i % _techBios.length];
      out.add(
        ShopProfile(
          id: id,
          name: L(name, name, name),
          cityId: city.id,
          city: L(city.nameUk, city.nameEn, city.nameRu),
          address: L(
            'ul. $street ${10 + i}',
            '$street St ${10 + i}',
            'ул. $street ${10 + i}',
          ),
          distanceKm: 1.2 + i * 0.35,
          lat: lat,
          lng: lng,
          rating: double.parse(rating.toStringAsFixed(1)),
          reviewCount: 12 + rnd.nextInt(220),
          tags: [
            L(works.first, works.first, works.first),
          ],
          workIds: works,
          liveFromBay: true,
          mapaHelp: mapa,
          positioning: const ['garage', 'service', 'dealer'][i % 3],
          hours: mapa ? kTowHours : kShopHours,
          phone: '+48${600000000 + i + city.count * 17}',
          lead: L(
            'Мережа Ta4ka · ${city.nameUk}. Камера боксу і запис — як у будь-якого сервісу.',
            'Ta4ka network · ${city.nameEn}. Bay camera and booking — same as any shop.',
            'Сеть Ta4ka · ${city.nameRu}. Камера бокса и запись — как у любого сервиса.',
          ),
          masters: [
            ShopMaster(
              id: '$id-tech',
              name: L(tech.$1, tech.$2, tech.$3),
              specialty: specialties[i % specialties.length],
              bio: L(bio.$1, bio.$2, bio.$3),
            ),
          ],
          reviews: [
            ShopReview(
              author: 'Ta4ka',
              stars: 5,
              text: L(
                'Запис і камера боксу працюють.',
                'Booking and bay camera work.',
                'Запись и камера бокса работают.',
              ),
            ),
          ],
          gallery: [
            ShopGalleryItem(
              title: L('Бокс', 'Bay', 'Бокс'),
              icon: IconKey.bay,
            ),
          ],
        ),
      );
    }
  }
  _generatedCache = out;
  return out;
}

GeoPoint centerForNetworkCity(String cityId) {
  for (final c in networkCities) {
    if (c.id == cityId) return GeoPoint(c.lat, c.lng);
  }
  return warsawCenter;
}

String matchNetworkCityId(String raw) {
  final q = raw.trim().toLowerCase();
  if (q.isEmpty) return 'warsaw';
  for (final c in networkCities) {
    if (q.contains(c.id) ||
        q.contains(c.nameEn.toLowerCase()) ||
        q.contains(c.nameUk.toLowerCase()) ||
        q.contains(c.nameRu.toLowerCase())) {
      return c.id;
    }
  }
  if (q.contains('льв') || q.contains('lviv')) return 'lviv';
  if (q.contains('варш') || q.contains('warsaw') || q.contains('warszawa')) {
    return 'warsaw';
  }
  if (q.contains('ки') || q.contains('kyiv') || q.contains('kiev')) return 'kyiv';
  return 'all';
}
