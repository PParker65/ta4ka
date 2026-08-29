import '../core/l10n/app_lang.dart';

const kUsaPartnerPhoto = 'assets/usa/partner.jpg';
const kUsaCategoryPhoto = 'assets/categories/usa.jpg';
const kUsaSiteUrl = 'https://l-trans.org/';

/// FX snapshot for the Sept 2026 landed-cost quote (NBU-style ballpark).
/// USD/UAH ~41.70; EUR/USD ~1.17 ⇒ EUR/UAH ~48.8.
const kUsdToUah = 41.70;
const kEurToUsd = 1.17;

/// Tax year the excise age coefficient is pinned to (PKU 215.3.51, Sept 2026).
const kUsaRatesYear = 2026;

/// Typical passenger-EV pack when the UI has no kWh field (Model 3/Y class).
const kUsaDefaultBatteryKwh = 75.0;

class UsaPartner {
  const UsaPartner();

  String name(AppLang lang) => const L(
        'Lion Trans',
        'Lion Trans',
        'Lion Trans',
        'Lion Trans',
      ).of(lang);

  String role(AppLang lang) => const L(
        'operated by Lion Trans · офіційний IAAI в Україні',
        'operated by Lion Trans · official IAAI in Ukraine',
        'operated by Lion Trans · официальный IAAI в Украине',
        'operated by Lion Trans · oficjalny IAAI w UA',
      ).of(lang);

  String manager(AppLang lang) => const L(
        'Доставка авто з США та Канади',
        'Car delivery from USA and Canada',
        'Доставка авто из США и Канады',
        'Dostawa aut z USA i Kanady',
      ).of(lang);
}

class UsaLot {
  const UsaLot({
    required this.id,
    required this.title,
    required this.yard,
    required this.photo,
    required this.year,
    required this.miles,
    required this.bidUsd,
    required this.engineL,
    required this.fuel,
    required this.damage,
    required this.status,
  });

  final String id;
  final L title;
  final L yard;
  final String photo;
  final int year;
  final int miles;
  final int bidUsd;
  final double engineL;
  final String fuel; // petrol diesel hybrid ev
  final L damage;
  final L status;
}

const kUsaStockLotIds = {'camry', 'f150'};

List<UsaLot> usaStockLots() => [
      for (final lot in kUsaLots)
        if (kUsaStockLotIds.contains(lot.id)) lot,
    ];

List<UsaLot> usaPickedLots() => [
      for (final lot in kUsaLots)
        if (!kUsaStockLotIds.contains(lot.id)) lot,
    ];

const kUsaLots = <UsaLot>[
  UsaLot(
    id: 'm3',
    title: L('Tesla Model 3 Long Range', 'Tesla Model 3 Long Range', 'Tesla Model 3 Long Range'),
    yard: L('IAAI · New Jersey', 'IAAI · New Jersey', 'IAAI · New Jersey'),
    photo: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=900&q=75',
    year: 2021,
    miles: 28400,
    bidUsd: 21400,
    engineL: 0,
    fuel: 'ev',
    damage: L('Мінор, задній бампер', 'Minor, rear bumper', 'Минор, задний бампер'),
    status: L('На аукціоні · завтра 19:00', 'On auction · tomorrow 19:00', 'На аукционе · завтра 19:00'),
  ),
  UsaLot(
    id: 'g30',
    title: L('BMW 530i xDrive', 'BMW 530i xDrive', 'BMW 530i xDrive'),
    yard: L('Copart · Dallas', 'Copart · Dallas', 'Copart · Dallas'),
    photo: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=900&q=75',
    year: 2019,
    miles: 41200,
    bidUsd: 16800,
    engineL: 2.0,
    fuel: 'petrol',
    damage: L('Град по даху, лак цілий', 'Hail on roof, clear coat OK', 'Град по крыше, лак целый'),
    status: L('В океані · 16 днів до Одеси', 'At sea · 16 days to Odesa', 'В океане · 16 дней до Одессы'),
  ),
  UsaLot(
    id: 'camry',
    title: L('Toyota Camry XSE', 'Toyota Camry XSE', 'Toyota Camry XSE'),
    yard: L('Copart · Savannah', 'Copart · Savannah', 'Copart · Savannah'),
    photo: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?auto=format&fit=crop&w=900&q=75',
    year: 2020,
    miles: 35600,
    bidUsd: 14200,
    engineL: 2.5,
    fuel: 'petrol',
    damage: L('Clean title · без ударів', 'Clean title · no hits', 'Clean title · без ударов'),
    status: L('Під ключ від 18 днів', 'Turnkey from 18 days', 'Под ключ от 18 дней'),
  ),
  UsaLot(
    id: 'f150',
    title: L('Ford F-150 Lariat', 'Ford F-150 Lariat', 'Ford F-150 Lariat'),
    yard: L('Manheim · Houston', 'Manheim · Houston', 'Manheim · Houston'),
    photo: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58dd?auto=format&fit=crop&w=900&q=75',
    year: 2018,
    miles: 62100,
    bidUsd: 22900,
    engineL: 3.5,
    fuel: 'petrol',
    damage: L('Ліве крило, заміна панелі', 'Left fender, panel replace', 'Левое крыло, замена панели'),
    status: L('На майданчику США', 'At US yard', 'На площадке США'),
  ),
  UsaLot(
    id: 'eclass',
    title: L('Mercedes-Benz E 300', 'Mercedes-Benz E 300', 'Mercedes-Benz E 300'),
    yard: L('Copart · Los Angeles', 'Copart · Los Angeles', 'Copart · Los Angeles'),
    photo: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=900&q=75',
    year: 2020,
    miles: 29800,
    bidUsd: 24600,
    engineL: 2.0,
    fuel: 'petrol',
    damage: L('Перед, фари цілі', 'Front, lamps intact', 'Перед, фары целые'),
    status: L('Перевірка Carfax · можна бити', 'Carfax done · ready to bid', 'Проверка Carfax · можно бить'),
  ),
];

/// Painted glyph inside the USA pipeline node (not a digit).
enum UsaPipelineScene { auction, pay, ship, keys }

class UsaStep {
  const UsaStep({
    required this.title,
    required this.body,
    required this.days,
    required this.scene,
  });

  final L title;
  final L body;
  final String days;
  final UsaPipelineScene scene;
}

const kUsaSteps = <UsaStep>[
  UsaStep(
    scene: UsaPipelineScene.auction,
    title: L('Вибір авто', 'Pick a car', 'Выбор авто'),
    body: L(
      'Бюджет, кузов, рік, мотор. Відсікаємо лоти, які невигідно везти в Україну.',
      'Budget, body, year, engine. We drop lots that do not pay off in Ukraine.',
      'Бюджет, кузов, год, мотор. Отсекаем лоты, которые невыгодно везти в Украину.',
    ),
    days: '1',
  ),
  UsaStep(
    scene: UsaPipelineScene.pay,
    title: L('Покупка', 'Buy', 'Покупка'),
    body: L(
      'Copart / IAAI / Manheim: підбір, ставка з вашим лімітом, викуп і експортний title.',
      'Copart / IAAI / Manheim: pick, bid to your cap, purchase and export title.',
      'Copart / IAAI / Manheim: подбор, ставка с вашим лимитом, выкуп и экспортный title.',
    ),
    days: '2–7',
  ),
  UsaStep(
    scene: UsaPipelineScene.ship,
    title: L('Доставка', 'Delivery', 'Доставка'),
    body: L(
      'Океан, страхування, брокер, розмитнення. Ви не стоїте в черзі — пакет збирає L-Trans.',
      'Ocean, insurance, broker, customs. You do not queue — L-Trans files the pack.',
      'Океан, страхование, брокер, растаможка. Вы не стоите в очереди — пакет собирает L-Trans.',
    ),
    days: '',
  ),
  UsaStep(
    scene: UsaPipelineScene.keys,
    title: L('Ключі', 'Keys', 'Ключи'),
    body: L(
      'Забираєте машину у своєму місті. Ключі, сервісна книга Ta4ka, запис на перше ТО.',
      'You pick the car up in your city. Keys, Ta4ka service book, first service booking.',
      'Забираете машину в своём городе. Ключи, сервисная книга Ta4ka, запись на первое ТО.',
    ),
    days: '1–3',
  ),
];

class UsaInclude {
  const UsaInclude({required this.title, required this.ok});

  final L title;
  final bool ok;
}

const kUsaIncludes = <UsaInclude>[
  UsaInclude(title: L('Підбір під ринок UA, не «що дешевше на Copart»', 'Picked for UA market, not “cheapest on Copart”', 'Подбор под рынок UA, не «что дешевле на Copart»'), ok: true),
  UsaInclude(title: L('Carfax + фото зі слотів до ставки', 'Carfax + slot photos before the bid', 'Carfax + фото слотов до ставки'), ok: true),
  UsaInclude(title: L('Ставка, викуп, експортні документи', 'Bid, purchase, export papers', 'Ставка, выкуп, экспортные документы'), ok: true),
  UsaInclude(title: L('Океан + страхування вантажу', 'Ocean + cargo insurance', 'Океан + страхование груза'), ok: true),
  UsaInclude(title: L('Розмитнення під ключ (мито, акциз, ПДВ)', 'Turnkey customs (duty, excise, VAT)', 'Растаможка под ключ (пошлина, акциз, НДС)'), ok: true),
  UsaInclude(title: L('Доставка в місто і перше ТО в мережі Ta4ka', 'City delivery and first service in Ta4ka', 'Доставка в город и первое ТО в сети Ta4ka'), ok: true),
  UsaInclude(title: L('Ремонт після удару — окремо, в СТО Ta4ka', 'Post-hit repair — extra, at an Ta4ka shop', 'Ремонт после удара — отдельно, на СТО Ta4ka'), ok: false),
];

/// Line-item landed cost in Ukraine (USD). Sum of the eight public terms.
class UsaLandedQuote {
  const UsaLandedQuote({
    required this.bidUsd,
    required this.auctionFeeUsd,
    required this.inlandUsd,
    required this.oceanUsd,
    required this.dutyUsd,
    required this.exciseUsd,
    required this.vatUsd,
    required this.brokerUsd,
    required this.exciseEur,
  });

  final int bidUsd;
  final int auctionFeeUsd;
  final int inlandUsd;
  final int oceanUsd;
  final int dutyUsd;
  final int exciseUsd;
  final int vatUsd;
  final int brokerUsd;
  final double exciseEur;

  /// CIF / customs value: bid + auction extras + US inland + ocean to UA.
  int get customsValueUsd => bidUsd + auctionFeeUsd + inlandUsd + oceanUsd;

  int get totalUsd =>
      bidUsd + auctionFeeUsd + inlandUsd + oceanUsd + dutyUsd + exciseUsd + vatUsd + brokerUsd;

  int get totalUah => (totalUsd * kUsdToUah).round();
}

/// Copart / IAAI buyer-fee bands (public US 2025 chart, still the Sept 2026 proxy)
/// plus virtual-bid fee, $95 gate, $15 environmental. Not a live auction invoice.
int usaAuctionFeeUsd(int bidUsd) {
  final bid = bidUsd < 0 ? 0 : bidUsd;
  return _copartBuyerFee(bid) + _copartVirtualBidFee(bid) + 95 + 15;
}

int _copartBuyerFee(int bid) {
  // Hammer-price bands, Copart US schedule condensed for passenger lots.
  const bands = <(int, int)>[
    (499, 125),
    (999, 185),
    (1499, 250),
    (1999, 300),
    (2499, 355),
    (2999, 370),
    (3499, 400),
    (3999, 450),
    (4499, 475),
    (4999, 500),
    (5499, 525),
    (5999, 550),
    (6499, 575),
    (6999, 590),
    (7499, 610),
    (7999, 630),
    (8499, 650),
    (8999, 670),
    (9999, 695),
    (10499, 720),
    (11499, 770),
    (12499, 790),
    (14999, 850),
    (19999, 920),
    (24999, 990),
    (29999, 1060),
    (34999, 1130),
    (39999, 1200),
    (49999, 1270),
  ];
  for (final band in bands) {
    if (bid <= band.$1) return band.$2;
  }
  return 1270 + ((bid - 50000) * 0.01).round().clamp(0, 5000);
}

int _copartVirtualBidFee(int bid) {
  if (bid < 100) return 0;
  if (bid < 500) return 49;
  if (bid < 1000) return 59;
  if (bid < 1500) return 79;
  if (bid < 2000) return 89;
  if (bid < 4000) return 99;
  if (bid < 6000) return 109;
  if (bid < 7500) return 119;
  return 129;
}

/// PKU art. 215.3.51: Квік = full years from year after production, min 1, max 15.
/// UA calculators (and this quote) use taxYear − productionYear, clamped.
int usaExciseAgeCoeff(int productionYear, {int taxYear = kUsaRatesYear}) {
  final raw = taxYear - productionYear;
  if (raw < 1) return 1;
  if (raw > 15) return 15;
  return raw;
}

/// Excise in EUR. Spark-ignition (petrol + hybrid HEV) vs diesel vs BEV.
/// HEV uses petrol cm³ rates (Camry Hybrid etc.). PHEV 100 €/unit is not modeled.
double usaExciseEur({
  required String fuel,
  required double engineL,
  required int year,
  double batteryKwh = kUsaDefaultBatteryKwh,
}) {
  if (fuel == 'ev') {
    return batteryKwh; // 1 € / kWh, UKT ZED 8703 80
  }
  final cm3 = (engineL * 1000).clamp(1.0, 8000.0);
  final diesel = fuel == 'diesel';
  final base = diesel
      ? (cm3 > 3500 ? 150.0 : 75.0)
      : (cm3 > 3000 ? 100.0 : 50.0);
  return base * (cm3 / 1000) * usaExciseAgeCoeff(year);
}

/// Sept 2026 quote. Assumptions (also shown as a footnote in the UI):
/// - Inland: East/Gulf yard → port (Savannah / NJ / Houston). West Coast is more.
/// - Ocean: RoRo sedan US East → Constanța/Odesa, incl. marine insurance ~1.2%.
/// - Duty 10% of CIF for ICE; 0% for BEV. VAT 20% on (CIF + duty + excise) for all
///   (EV VAT exemption ended 1 Jan 2026).
/// - Broker line folds UA broker + terminal + last-mile so the eight terms = car in UA.
UsaLandedQuote usaLandedQuote({
  required int bidUsd,
  required double engineL,
  required int year,
  required String fuel,
  double batteryKwh = kUsaDefaultBatteryKwh,
}) {
  final bid = bidUsd < 0 ? 0 : bidUsd;
  final fee = usaAuctionFeeUsd(bid);
  const inland = 625; // US inland, East/Gulf default
  const ocean = 1690; // RoRo East Coast → UA, Sept 2026
  const broker = 480; // broker + terminal + city delivery
  final cif = bid + fee + inland + ocean;
  final duty = fuel == 'ev' ? 0 : (cif * 0.10).round();
  final exciseEur = usaExciseEur(
    fuel: fuel,
    engineL: engineL,
    year: year,
    batteryKwh: batteryKwh,
  );
  final excise = (exciseEur * kEurToUsd).round();
  final vat = ((cif + duty + excise) * 0.20).round();
  return UsaLandedQuote(
    bidUsd: bid,
    auctionFeeUsd: fee,
    inlandUsd: inland,
    oceanUsd: ocean,
    dutyUsd: duty,
    exciseUsd: excise,
    vatUsd: vat,
    brokerUsd: broker,
    exciseEur: exciseEur,
  );
}

int usaLandedUsd({
  required int bidUsd,
  required double engineL,
  required int year,
  required String fuel,
}) {
  return usaLandedQuote(bidUsd: bidUsd, engineL: engineL, year: year, fuel: fuel).totalUsd;
}

int usaLandedUah({
  required int bidUsd,
  required double engineL,
  required int year,
  required String fuel,
}) {
  return usaLandedQuote(bidUsd: bidUsd, engineL: engineL, year: year, fuel: fuel).totalUah;
}
