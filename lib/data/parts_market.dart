import '../core/l10n/app_lang.dart';

class PartsGroup {
  const PartsGroup(this.id, this.markup);
  final String id;
  final double markup;
}

class PartsSupplier {
  const PartsSupplier(this.id, this.name);
  final String id;
  final String name;
}

class PartsOffer {
  const PartsOffer({
    required this.supplier,
    required this.sku,
    required this.brand,
    required this.buyUah,
    required this.qty,
    required this.days,
  });

  final PartsSupplier supplier;
  final String sku;
  final String brand;
  final int buyUah;
  final int qty;
  final int days;

  int sellUah(double markup) => (buyUah * markup).round();
}

class PartsItem {
  const PartsItem({
    required this.id,
    required this.oem,
    required this.titleUk,
    required this.titleEn,
    required this.titleRu,
    required this.group,
    required this.keywords,
    required this.offers,
  });

  final String id;
  final String oem;
  final String titleUk;
  final String titleEn;
  final String titleRu;
  final PartsGroup group;
  final List<String> keywords;
  final List<PartsOffer> offers;

  String title(AppLang lang) => switch (lang) {
        AppLang.uk => titleUk,
        AppLang.en => titleEn,
        AppLang.ru => titleRu,
        AppLang.pl => titleEn,
      };
}

const kOmega = PartsSupplier('omega', 'Omega');
const kElit = PartsSupplier('elit', 'Elit');
const kInter = PartsSupplier('intercars', 'Inter Cars');
const kUnik = PartsSupplier('unik', 'Unik Trade');
const kVesna = PartsSupplier('vesna', 'Vesna');
const kBus = PartsSupplier('busmarket', 'BusMarket');

const gFilters = PartsGroup('filters', 1.30);
const gBrakes = PartsGroup('brakes', 1.35);
const gChassis = PartsGroup('chassis', 1.32);
const gElectrical = PartsGroup('electrical', 1.40);
const gEngine = PartsGroup('engine', 1.28);
const gOther = PartsGroup('other', 1.25);

const kPartsCatalog = <PartsItem>[
  PartsItem(
    id: 'oil_filter',
    oem: '03C115561H',
    titleUk: 'Фільтр масляний',
    titleEn: 'Oil filter',
    titleRu: 'Масляный фильтр',
    group: gFilters,
    keywords: ['масл', 'oil', 'фільтр', 'фильтр', '03c115561'],
    offers: const [
      PartsOffer(supplier: kOmega, sku: 'OM-OF-561', brand: 'MANN', buyUah: 280, qty: 14, days: 0),
      PartsOffer(supplier: kElit, sku: 'EL-W712', brand: 'Bosch', buyUah: 310, qty: 8, days: 1),
      PartsOffer(supplier: kInter, sku: 'IC-HU718', brand: 'Mahle', buyUah: 265, qty: 22, days: 0),
      PartsOffer(supplier: kVesna, sku: 'VS-OFH', brand: 'WIX', buyUah: 240, qty: 3, days: 2),
    ],
  ),
  PartsItem(
    id: 'air_filter',
    oem: '1K0129620D',
    titleUk: 'Фільтр повітряний',
    titleEn: 'Air filter',
    titleRu: 'Воздушный фильтр',
    group: gFilters,
    keywords: ['повітря', 'воздуш', 'air', '1k0129620'],
    offers: const [
      PartsOffer(supplier: kOmega, sku: 'OM-AF-620', brand: 'MANN', buyUah: 420, qty: 9, days: 0),
      PartsOffer(supplier: kElit, sku: 'EL-C3515', brand: 'Filtron', buyUah: 360, qty: 11, days: 0),
      PartsOffer(supplier: kUnik, sku: 'UT-AF1K', brand: 'Knecht', buyUah: 390, qty: 4, days: 1),
    ],
  ),
  PartsItem(
    id: 'cabin_filter',
    oem: '5Q0819653',
    titleUk: 'Фільтр салону',
    titleEn: 'Cabin filter',
    titleRu: 'Салонный фильтр',
    group: gFilters,
    keywords: ['салон', 'cabin', 'пилок', '5q0819653'],
    offers: const [
      PartsOffer(supplier: kInter, sku: 'IC-LAO386', brand: 'Mahle', buyUah: 510, qty: 7, days: 0),
      PartsOffer(supplier: kOmega, sku: 'OM-CF-653', brand: 'MANN', buyUah: 480, qty: 12, days: 0),
    ],
  ),
  PartsItem(
    id: 'pads_front',
    oem: '5Q0698151',
    titleUk: 'Колодки передні',
    titleEn: 'Front brake pads',
    titleRu: 'Колодки передние',
    group: gBrakes,
    keywords: ['колод', 'pad', 'тормоз', 'гальм', '5q0698151'],
    offers: const [
      PartsOffer(supplier: kElit, sku: 'EL-GDB1550', brand: 'TRW', buyUah: 1480, qty: 6, days: 0),
      PartsOffer(supplier: kInter, sku: 'IC-098649', brand: 'Brembo', buyUah: 1890, qty: 4, days: 1),
      PartsOffer(supplier: kOmega, sku: 'OM-FDB1619', brand: 'Ferodo', buyUah: 1620, qty: 5, days: 0),
      PartsOffer(supplier: kVesna, sku: 'VS-PAD-F', brand: 'ATE', buyUah: 1710, qty: 2, days: 2),
    ],
  ),
  PartsItem(
    id: 'disc_front',
    oem: '5Q0615301',
    titleUk: 'Диск гальмівний передній',
    titleEn: 'Front brake disc',
    titleRu: 'Диск тормозной передний',
    group: gBrakes,
    keywords: ['диск', 'disc', 'гальм', 'тормоз', '5q0615301'],
    offers: const [
      PartsOffer(supplier: kInter, sku: 'IC-09A407', brand: 'Brembo', buyUah: 2140, qty: 8, days: 0),
      PartsOffer(supplier: kElit, sku: 'EL-DF4287', brand: 'TRW', buyUah: 1680, qty: 10, days: 0),
      PartsOffer(supplier: kOmega, sku: 'OM-DDF', brand: 'ATE', buyUah: 1920, qty: 3, days: 1),
    ],
  ),
  PartsItem(
    id: 'cv_joint',
    oem: '1K0407331',
    titleUk: 'ШРУС зовнішній',
    titleEn: 'Outer CV joint',
    titleRu: 'ШРУС наружный',
    group: gChassis,
    keywords: ['шрус', 'cv', 'граната', 'привод', '1k0407331'],
    offers: const [
      PartsOffer(supplier: kOmega, sku: 'OM-CV-331', brand: 'GKN', buyUah: 2450, qty: 3, days: 1),
      PartsOffer(supplier: kElit, sku: 'EL-CVJ', brand: 'Ruville', buyUah: 1980, qty: 5, days: 0),
      PartsOffer(supplier: kUnik, sku: 'UT-CV1K', brand: 'Metelli', buyUah: 1760, qty: 2, days: 2),
    ],
  ),
  PartsItem(
    id: 'ball_joint',
    oem: '1K0407365',
    titleUk: 'Кульова опора',
    titleEn: 'Ball joint',
    titleRu: 'Шаровая опора',
    group: gChassis,
    keywords: ['шаров', 'кульов', 'ball', 'опора', '1k0407365'],
    offers: const [
      PartsOffer(supplier: kElit, sku: 'EL-JBJ', brand: 'Lemförder', buyUah: 890, qty: 9, days: 0),
      PartsOffer(supplier: kInter, sku: 'IC-BJ365', brand: 'TRW', buyUah: 760, qty: 14, days: 0),
      PartsOffer(supplier: kOmega, sku: 'OM-BJ', brand: 'Moog', buyUah: 820, qty: 6, days: 1),
    ],
  ),
  PartsItem(
    id: 'tie_rod',
    oem: '1K0423811',
    titleUk: 'Наконечник рульової',
    titleEn: 'Tie rod end',
    titleRu: 'Наконечник рулевой',
    group: gChassis,
    keywords: ['наконечник', 'рульов', 'tie', '1k0423811'],
    offers: const [
      PartsOffer(supplier: kInter, sku: 'IC-JTE', brand: 'TRW', buyUah: 540, qty: 11, days: 0),
      PartsOffer(supplier: kElit, sku: 'EL-TRE', brand: 'Lemförder', buyUah: 610, qty: 7, days: 0),
    ],
  ),
  PartsItem(
    id: 'shock_front',
    oem: '5Q0413031',
    titleUk: 'Амортизатор передній',
    titleEn: 'Front shock absorber',
    titleRu: 'Амортизатор передний',
    group: gChassis,
    keywords: ['аморт', 'shock', 'стойк', 'стійк', '5q0413031'],
    offers: const [
      PartsOffer(supplier: kOmega, sku: 'OM-SACHS', brand: 'Sachs', buyUah: 3120, qty: 4, days: 1),
      PartsOffer(supplier: kElit, sku: 'EL-BIL', brand: 'Bilstein', buyUah: 4280, qty: 2, days: 3),
      PartsOffer(supplier: kInter, sku: 'IC-KYB', brand: 'KYB', buyUah: 2680, qty: 6, days: 0),
    ],
  ),
  PartsItem(
    id: 'battery',
    oem: '000915105DE',
    titleUk: 'Акумулятор 70Ah',
    titleEn: 'Battery 70Ah',
    titleRu: 'АКБ 70Ah',
    group: gElectrical,
    keywords: ['акб', 'акумул', 'battery', '70ah'],
    offers: const [
      PartsOffer(supplier: kVesna, sku: 'VS-VARTA', brand: 'Varta', buyUah: 4200, qty: 5, days: 0),
      PartsOffer(supplier: kOmega, sku: 'OM-BOSCH', brand: 'Bosch', buyUah: 4450, qty: 3, days: 0),
      PartsOffer(supplier: kElit, sku: 'EL-EXIDE', brand: 'Exide', buyUah: 3890, qty: 4, days: 1),
    ],
  ),
  PartsItem(
    id: 'spark',
    oem: '04E905601B',
    titleUk: 'Свічка запалювання',
    titleEn: 'Spark plug',
    titleRu: 'Свеча зажигания',
    group: gEngine,
    keywords: ['свіч', 'свеч', 'spark', '04e905601'],
    offers: const [
      PartsOffer(supplier: kInter, sku: 'IC-NGK', brand: 'NGK', buyUah: 210, qty: 40, days: 0),
      PartsOffer(supplier: kOmega, sku: 'OM-BCP', brand: 'Bosch', buyUah: 190, qty: 28, days: 0),
      PartsOffer(supplier: kElit, sku: 'EL-DENSO', brand: 'Denso', buyUah: 230, qty: 16, days: 1),
    ],
  ),
  PartsItem(
    id: 'timing',
    oem: '03C109119',
    titleUk: 'Комплект ГРМ',
    titleEn: 'Timing belt kit',
    titleRu: 'Комплект ГРМ',
    group: gEngine,
    keywords: ['грм', 'timing', 'ремінь', 'ремень', '03c109119'],
    offers: const [
      PartsOffer(supplier: kOmega, sku: 'OM-CT', brand: 'Contitech', buyUah: 3860, qty: 3, days: 1),
      PartsOffer(supplier: kElit, sku: 'EL-GATES', brand: 'Gates', buyUah: 4120, qty: 2, days: 2),
      PartsOffer(supplier: kInter, sku: 'IC-INA', brand: 'INA', buyUah: 4480, qty: 1, days: 3),
    ],
  ),
  PartsItem(
    id: 'alternator',
    oem: '03L903023',
    titleUk: 'Генератор',
    titleEn: 'Alternator',
    titleRu: 'Генератор',
    group: gElectrical,
    keywords: ['генератор', 'alternator', '03l903023'],
    offers: const [
      PartsOffer(supplier: kBus, sku: 'BM-ALT', brand: 'Bosch', buyUah: 6200, qty: 2, days: 2),
      PartsOffer(supplier: kElit, sku: 'EL-VALEO', brand: 'Valeo', buyUah: 5480, qty: 3, days: 1),
      PartsOffer(supplier: kUnik, sku: 'UT-ALT', brand: 'Hella', buyUah: 4990, qty: 1, days: 4),
    ],
  ),
  PartsItem(
    id: 'lambda',
    oem: '03C906262',
    titleUk: 'Лямбда-зонд',
    titleEn: 'Lambda sensor',
    titleRu: 'Лямбда-зонд',
    group: gElectrical,
    keywords: ['лямбда', 'lambda', 'зонд', 'sensor', '03c906262'],
    offers: const [
      PartsOffer(supplier: kOmega, sku: 'OM-BOS-L', brand: 'Bosch', buyUah: 2180, qty: 5, days: 0),
      PartsOffer(supplier: kInter, sku: 'IC-NTK', brand: 'NTK', buyUah: 1890, qty: 4, days: 1),
    ],
  ),
  PartsItem(
    id: 'coolant',
    oem: 'G013A8JM1',
    titleUk: 'Антифриз G13 5л',
    titleEn: 'Coolant G13 5L',
    titleRu: 'Антифриз G13 5л',
    group: gEngine,
    keywords: ['антифриз', 'coolant', 'тосол', 'g13'],
    offers: const [
      PartsOffer(supplier: kVesna, sku: 'VS-G13', brand: 'Febi', buyUah: 890, qty: 18, days: 0),
      PartsOffer(supplier: kOmega, sku: 'OM-G13', brand: 'Hepu', buyUah: 940, qty: 9, days: 0),
    ],
  ),
];

List<PartsItem> searchPartsMarket(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kPartsCatalog.take(8).toList();
  final hits = [
    for (final item in kPartsCatalog)
      if (item.keywords.any((k) => k.contains(q) || q.contains(k)) ||
          item.oem.toLowerCase().contains(q) ||
          item.titleUk.toLowerCase().contains(q) ||
          item.titleRu.toLowerCase().contains(q) ||
          item.titleEn.toLowerCase().contains(q) ||
          item.offers.any((o) => o.sku.toLowerCase().contains(q) || o.brand.toLowerCase().contains(q)))
        item,
  ];
  if (hits.isNotEmpty) return hits;
  return kPartsCatalog.take(6).toList();
}

PartsOffer cheapest(PartsItem item) {
  return item.offers.reduce((a, b) => a.buyUah <= b.buyUah ? a : b);
}
