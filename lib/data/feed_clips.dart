/// Local Ta4ka feed clips — bundled MP4 under assets/feed/.
import 'dart:math';

import '../core/l10n/app_lang.dart';
import '../domain/models/shop_models.dart';

const feedClips = <FeedClip>[
  FeedClip(
    id: 'local-bmw-m2',
    shopId: 'nordlift',
    cityId: 'warsaw',
    videoAsset: 'bmw_m2_body.mp4',
    viewCount: 12800,
    channel: L('Ta4ka · кузов', 'Ta4ka · body', 'Ta4ka · кузов'),
    title: L(
      'BMW M2 після удару — кузовний кейс',
      'BMW M2 after a hit — body case',
      'BMW M2 после удара — кузовной кейс',
    ),
    caption: L(
      'Синій M2 без кришки багажника: оцінка ремонту vs «як є» на аукціон.',
      'Blue M2 without trunk lid: repair quote vs sell as-is on auction.',
      'Синий M2 без крышки багажника: оценка ремонта vs «как есть» на аукцион.',
    ),
    live: false,
    video: true,
  ),
  FeedClip(
    id: 'local-tesla-screen',
    shopId: 'pitlane',
    cityId: 'warsaw',
    videoAsset: 'tesla_screen.mp4',
    viewCount: 9400,
    channel: L('Ta4ka · EV', 'Ta4ka · EV', 'Ta4ka · EV'),
    title: L(
      'Tesla: екран, карта і запас ходу',
      'Tesla: screen, map and range',
      'Tesla: экран, карта и запас хода',
    ),
    caption: L(
      'Салонний екран, супутник і 336 км — так клієнт бачить авто перед сервісом.',
      'Cabin screen, satellite map and 336 km — how the client sees the car before service.',
      'Салонный экран, спутник и 336 км — так клиент видит авто перед сервисом.',
    ),
    live: true,
    video: true,
  ),
  FeedClip(
    id: 'local-app-demo',
    shopId: 'pitlane',
    cityId: null,
    videoAsset: 'app_brand_pick.mp4',
    viewCount: 6100,
    channel: L('Ta4ka', 'Ta4ka', 'Ta4ka'),
    title: L(
      'Ta4ka у руках клієнта — вибір марки',
      'Ta4ka in the client’s hands — pick a brand',
      'Ta4ka в руках клиента — выбор марки',
    ),
    caption: L(
      'Екран «Марка твого авто?» — перший крок до запису на СТО.',
      '“What’s your car brand?” — first step to booking a shop.',
      'Экран «Марка твоего авто?» — первый шаг к записи на СТО.',
    ),
    live: false,
    video: true,
  ),
  FeedClip(
    id: 'local-bay-walk',
    shopId: 'torque-lviv',
    cityId: 'lviv',
    videoAsset: 'bay_walkin.mp4',
    viewCount: 4200,
    channel: L('Ta4ka · бокс', 'Ta4ka · bay', 'Ta4ka · бокс'),
    title: L(
      'Вхід у бокс · зйомка з місця майстра',
      'Entering the bay · tech POV',
      'Вход в бокс · съёмка с места мастера',
    ),
    caption: L(
      'Перші секунди в сервісі — підлога боксу і робочий ритм.',
      'First seconds in the shop — bay floor and work pace.',
      'Первые секунды в сервисе — пол бокса и рабочий ритм.',
    ),
    live: false,
    video: true,
  ),
];

/// Rank clips for [cityId] (local + city-agnostic first), then shuffle both
/// buckets with [seed] so each Стрічка tap yields a new stack.
List<FeedClip> rotateFeedClips({
  required int seed,
  required String cityId,
  String? shopFilter,
}) {
  final pool = [
    for (final clip in feedClips)
      if (shopFilter == null || clip.shopId == shopFilter) clip,
  ];
  if (pool.isEmpty) return const [];

  final local = <FeedClip>[];
  final rest = <FeedClip>[];
  for (final clip in pool) {
    final cid = clip.cityId;
    if (cid == null || cid == cityId) {
      local.add(clip);
    } else {
      rest.add(clip);
    }
  }
  final primary = local.isEmpty ? List<FeedClip>.from(pool) : local;
  final secondary = local.isEmpty ? <FeedClip>[] : rest;
  final rng = Random(seed);
  primary.shuffle(rng);
  secondary.shuffle(rng);
  return [...primary, ...secondary];
}
