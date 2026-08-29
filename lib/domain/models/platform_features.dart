import 'dart:convert';
import 'dart:typed_data';

/// Shared platform blacklist entry (visible to every shop).
class BlacklistEntry {
  const BlacklistEntry({
    required this.id,
    required this.clientKey,
    required this.clientLabel,
    required this.reason,
    required this.shopId,
    required this.shopName,
    required this.at,
  });

  final String id;
  /// Phone or login normalized.
  final String clientKey;
  final String clientLabel;
  final String reason;
  final String shopId;
  final String shopName;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientKey': clientKey,
        'clientLabel': clientLabel,
        'reason': reason,
        'shopId': shopId,
        'shopName': shopName,
        'at': at.millisecondsSinceEpoch,
      };

  factory BlacklistEntry.fromJson(Map<String, dynamic> json) {
    return BlacklistEntry(
      id: json['id'] as String? ?? '',
      clientKey: json['clientKey'] as String? ?? '',
      clientLabel: json['clientLabel'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
    );
  }
}

enum OpenJobStatus { open, awarded, closed }

class OpenJobBid {
  const OpenJobBid({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.priceUah,
    required this.proposedAt,
    this.note = '',
  });

  final String id;
  final String shopId;
  final String shopName;
  final int priceUah;
  final DateTime proposedAt;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'shopName': shopName,
        'priceUah': priceUah,
        'proposedAt': proposedAt.millisecondsSinceEpoch,
        'note': note,
      };

  factory OpenJobBid.fromJson(Map<String, dynamic> json) {
    return OpenJobBid(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      priceUah: (json['priceUah'] as num?)?.toInt() ?? 0,
      proposedAt: DateTime.fromMillisecondsSinceEpoch(json['proposedAt'] as int? ?? 0),
      note: json['note'] as String? ?? '',
    );
  }
}

/// Client marketplace request — shops bid price + date.
class OpenJobRequest {
  const OpenJobRequest({
    required this.id,
    required this.ownerLogin,
    required this.ownerLabel,
    required this.title,
    required this.details,
    required this.createdAt,
    this.plate = '',
    this.vin = '',
    this.brand = '',
    this.model = '',
    this.photoNote = '',
    this.city = '',
    this.status = OpenJobStatus.open,
    this.bids = const [],
    this.awardedShopId,
    this.awardedBidId,
    this.orderId,
  });

  final String id;
  final String ownerLogin;
  final String ownerLabel;
  final String title;
  final String details;
  final DateTime createdAt;
  final String plate;
  final String vin;
  final String brand;
  final String model;
  final String photoNote;
  final String city;
  final OpenJobStatus status;
  final List<OpenJobBid> bids;
  final String? awardedShopId;
  final String? awardedBidId;
  final String? orderId;

  OpenJobRequest copyWith({
    OpenJobStatus? status,
    List<OpenJobBid>? bids,
    String? awardedShopId,
    String? awardedBidId,
    String? orderId,
  }) {
    return OpenJobRequest(
      id: id,
      ownerLogin: ownerLogin,
      ownerLabel: ownerLabel,
      title: title,
      details: details,
      createdAt: createdAt,
      plate: plate,
      vin: vin,
      brand: brand,
      model: model,
      photoNote: photoNote,
      city: city,
      status: status ?? this.status,
      bids: bids ?? this.bids,
      awardedShopId: awardedShopId ?? this.awardedShopId,
      awardedBidId: awardedBidId ?? this.awardedBidId,
      orderId: orderId ?? this.orderId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerLogin': ownerLogin,
        'ownerLabel': ownerLabel,
        'title': title,
        'details': details,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'plate': plate,
        'vin': vin,
        'brand': brand,
        'model': model,
        'photoNote': photoNote,
        'city': city,
        'status': status.name,
        'bids': [for (final b in bids) b.toJson()],
        'awardedShopId': awardedShopId,
        'awardedBidId': awardedBidId,
        'orderId': orderId,
      };

  factory OpenJobRequest.fromJson(Map<String, dynamic> json) {
    OpenJobStatus status = OpenJobStatus.open;
    for (final value in OpenJobStatus.values) {
      if (value.name == json['status']) {
        status = value;
        break;
      }
    }
    return OpenJobRequest(
      id: json['id'] as String? ?? '',
      ownerLogin: json['ownerLogin'] as String? ?? '',
      ownerLabel: json['ownerLabel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      plate: json['plate'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      photoNote: json['photoNote'] as String? ?? '',
      city: json['city'] as String? ?? '',
      status: status,
      bids: [
        for (final item in json['bids'] as List<dynamic>? ?? const [])
          OpenJobBid.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      awardedShopId: json['awardedShopId'] as String?,
      awardedBidId: json['awardedBidId'] as String?,
      orderId: json['orderId'] as String?,
    );
  }
}

class GarageCar {
  const GarageCar({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    this.year = 0,
    this.vin = '',
  });

  final String id;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String vin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate': plate,
        'brand': brand,
        'model': model,
        'year': year,
        'vin': vin,
      };

  factory GarageCar.fromJson(Map<String, dynamic> json) {
    return GarageCar(
      id: json['id'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      vin: json['vin'] as String? ?? '',
    );
  }
}

class BusinessInvoice {
  const BusinessInvoice({
    required this.id,
    required this.ownerLogin,
    required this.createdAt,
    required this.totalUah,
    required this.carIds,
    required this.lineLabels,
    this.paid = false,
  });

  final String id;
  final String ownerLogin;
  final DateTime createdAt;
  final int totalUah;
  final List<String> carIds;
  final List<String> lineLabels;
  final bool paid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerLogin': ownerLogin,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'totalUah': totalUah,
        'carIds': carIds,
        'lineLabels': lineLabels,
        'paid': paid,
      };

  factory BusinessInvoice.fromJson(Map<String, dynamic> json) {
    return BusinessInvoice(
      id: json['id'] as String? ?? '',
      ownerLogin: json['ownerLogin'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      totalUah: (json['totalUah'] as num?)?.toInt() ?? 0,
      carIds: [
        for (final id in json['carIds'] as List<dynamic>? ?? const []) id as String,
      ],
      lineLabels: [
        for (final line in json['lineLabels'] as List<dynamic>? ?? const [])
          line as String,
      ],
      paid: json['paid'] == true,
    );
  }
}

String normalizeClientKey(String raw) {
  return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

String normalizeVin(String raw) {
  return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

enum PartsRequestStatus { draft, pendingShop, ordered, ready, received, rejected }

/// Master → shop approval → parts dealer chat / warehouse.
class PartsRequest {
  const PartsRequest({
    required this.id,
    required this.masterId,
    required this.masterName,
    required this.partName,
    required this.createdAt,
    this.orderId = '',
    this.vin = '',
    this.carLabel = '',
    this.query = '',
    this.status = PartsRequestStatus.pendingShop,
    this.note = '',
  });

  final String id;
  final String masterId;
  final String masterName;
  final String partName;
  final DateTime createdAt;
  final String orderId;
  final String vin;
  final String carLabel;
  final String query;
  final PartsRequestStatus status;
  final String note;

  PartsRequest copyWith({
    PartsRequestStatus? status,
    String? note,
  }) {
    return PartsRequest(
      id: id,
      masterId: masterId,
      masterName: masterName,
      partName: partName,
      createdAt: createdAt,
      orderId: orderId,
      vin: vin,
      carLabel: carLabel,
      query: query,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'masterId': masterId,
        'masterName': masterName,
        'partName': partName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'orderId': orderId,
        'vin': vin,
        'carLabel': carLabel,
        'query': query,
        'status': status.name,
        'note': note,
      };

  factory PartsRequest.fromJson(Map<String, dynamic> json) {
    PartsRequestStatus status = PartsRequestStatus.pendingShop;
    for (final value in PartsRequestStatus.values) {
      if (value.name == json['status']) {
        status = value;
        break;
      }
    }
    return PartsRequest(
      id: json['id'] as String? ?? '',
      masterId: json['masterId'] as String? ?? '',
      masterName: json['masterName'] as String? ?? '',
      partName: json['partName'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      orderId: json['orderId'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      carLabel: json['carLabel'] as String? ?? '',
      query: json['query'] as String? ?? '',
      status: status,
      note: json['note'] as String? ?? '',
    );
  }
}

/// Simple AI-style parts suggestions from free text (VIN already known).
class PartsCatalogHint {
  const PartsCatalogHint(this.id, this.titleUk, this.titleEn, this.titleRu, this.keywords);

  final String id;
  final String titleUk;
  final String titleEn;
  final String titleRu;
  final List<String> keywords;

  String title(String langCode) => switch (langCode) {
        'en' => titleEn,
        'ru' => titleRu,
        _ => titleUk,
      };
}

const partsCatalogHints = <PartsCatalogHint>[
  PartsCatalogHint('cv_joint', 'ШРУС', 'CV joint', 'ШРУС', ['шрус', 'cv', 'граната', 'привод']),
  PartsCatalogHint('ball_joint', 'Кульова опора', 'Ball joint', 'Шаровая опора', ['шаров', 'кульов', 'ball']),
  PartsCatalogHint('control_arm', 'Важіль / опора', 'Control arm', 'Рычаг / опора', ['опор', 'важіль', 'рычаг', 'arm']),
  PartsCatalogHint('tie_rod', 'Наконечник рульової', 'Tie rod end', 'Наконечник рулевой', ['наконечник', 'рульов', 'tie']),
  PartsCatalogHint('brake_pad', 'Колодки', 'Brake pads', 'Колодки', ['колодк', 'pad', 'тормоз']),
  PartsCatalogHint('brake_disc', 'Гальмівний диск', 'Brake disc', 'Тормозной диск', ['диск', 'disc']),
  PartsCatalogHint('oil_filter', 'Масляний фільтр', 'Oil filter', 'Масляный фильтр', ['масл', 'oil', 'фільтр', 'фильтр']),
  PartsCatalogHint('air_filter', 'Повітряний фільтр', 'Air filter', 'Воздушный фильтр', ['повітря', 'воздуш', 'air']),
  PartsCatalogHint('spark_plug', 'Свічки', 'Spark plugs', 'Свечи', ['свіч', 'свеч', 'spark']),
  PartsCatalogHint('programmer', 'Програматор / діаг. адаптер', 'Programmer / diag adapter', 'Программатор', ['програм', 'адаптер', 'obd', 'diag']),
  PartsCatalogHint('battery', 'Акумулятор', 'Battery', 'АКБ', ['акб', 'акумул', 'battery']),
  PartsCatalogHint('alternator', 'Генератор', 'Alternator', 'Генератор', ['генератор', 'alternator']),
  PartsCatalogHint('starter', 'Стартер', 'Starter', 'Стартер', ['стартер', 'starter']),
  PartsCatalogHint('sensor', 'Датчик', 'Sensor', 'Датчик', ['датчик', 'sensor', 'лямбда']),
];

List<PartsCatalogHint> suggestParts(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return partsCatalogHints.take(8).toList();
  }
  final hits = [
    for (final hint in partsCatalogHints)
      if (hint.keywords.any((k) => q.contains(k)) ||
          hint.titleUk.toLowerCase().contains(q) ||
          hint.titleRu.toLowerCase().contains(q) ||
          hint.titleEn.toLowerCase().contains(q))
        hint,
  ];
  if (hits.isNotEmpty) {
    return hits;
  }
  return partsCatalogHints.take(6).toList();
}

class MapaHelpReport {
  const MapaHelpReport({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.clientLogin,
    required this.reason,
    required this.at,
    this.photoBytes = const [],
  });

  final String id;
  final String shopId;
  final String shopName;
  final String clientLogin;
  final String reason;
  final DateTime at;
  final List<int> photoBytes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'shopName': shopName,
        'clientLogin': clientLogin,
        'reason': reason,
        'at': at.millisecondsSinceEpoch,
        'photoBytes': photoBytes.isEmpty
            ? ''
            : base64Encode(Uint8List.fromList(photoBytes)),
      };

  factory MapaHelpReport.fromJson(Map<String, dynamic> json) {
    final raw = json['photoBytes'] as String? ?? '';
    return MapaHelpReport(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      clientLogin: json['clientLogin'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
      photoBytes: raw.isEmpty ? const [] : base64Decode(raw),
    );
  }
}

/// Fix-or-Sell: wrecked / uneconomical cars auction (2h live window).
enum AuctionStatus { live, sold, cancelled, expired }

class AuctionBid {
  const AuctionBid({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.amountUah,
    required this.at,
    this.note = '',
  });

  final String id;
  final String buyerId;
  final String buyerName;
  final int amountUah;
  final DateTime at;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'amountUah': amountUah,
        'at': at.millisecondsSinceEpoch,
        'note': note,
      };

  factory AuctionBid.fromJson(Map<String, dynamic> json) {
    return AuctionBid(
      id: json['id'] as String? ?? '',
      buyerId: json['buyerId'] as String? ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      amountUah: (json['amountUah'] as num?)?.toInt() ?? 0,
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
      note: json['note'] as String? ?? '',
    );
  }
}

class VehicleAuction {
  const VehicleAuction({
    required this.id,
    required this.ownerLogin,
    required this.ownerLabel,
    required this.title,
    required this.details,
    required this.createdAt,
    required this.startsAt,
    required this.endsAt,
    this.plate = '',
    this.vin = '',
    this.brand = '',
    this.model = '',
    this.year = '',
    this.photoNote = '',
    this.photoUrls = const [],
    this.mileageKm = 0,
    this.damage = '',
    this.sellReason = '',
    this.buyNowUah = 0,
    this.estimateUah = 0,
    this.shopId = '',
    this.shopName = '',
    this.orderId = '',
    this.status = AuctionStatus.live,
    this.bids = const [],
    this.winningBidId,
    this.isBot = false,
  });

  final String id;
  final String ownerLogin;
  final String ownerLabel;
  final String title;
  final String details;
  final DateTime createdAt;
  /// When bidding opens (shown on the lot card).
  final DateTime startsAt;
  final DateTime endsAt;
  final String plate;
  final String vin;
  final String brand;
  final String model;
  final String year;
  final String photoNote;
  /// Lot gallery (Copart-style), typically 3–5 photos.
  final List<String> photoUrls;
  final int mileageKm;
  final String damage;
  final String sellReason;
  /// Instant purchase price (0 = disabled).
  final int buyNowUah;
  /// Repair estimate that made the client refuse to fix.
  final int estimateUah;
  /// Diagnosing shop — earns commission on completed sale.
  final String shopId;
  final String shopName;
  final String orderId;
  final AuctionStatus status;
  final List<AuctionBid> bids;
  final String? winningBidId;
  final bool isBot;

  bool get hasStarted => !DateTime.now().isBefore(startsAt);
  bool get isLive =>
      status == AuctionStatus.live &&
      hasStarted &&
      DateTime.now().isBefore(endsAt);
  bool get isScheduled =>
      status == AuctionStatus.live && DateTime.now().isBefore(startsAt);
  bool get hasBuyNow => buyNowUah > 0 && isLive;

  AuctionBid? get topBid {
    if (bids.isEmpty) {
      return null;
    }
    return bids.reduce((a, b) => a.amountUah >= b.amountUah ? a : b);
  }

  /// ~5% of winning bid for the diagnosing shop (min 500).
  int get shopCommissionUah {
    final win = topBid?.amountUah ?? 0;
    if (win <= 0) {
      return 0;
    }
    final cut = (win * 0.05).round();
    return cut < 500 ? 500 : cut;
  }

  VehicleAuction copyWith({
    AuctionStatus? status,
    List<AuctionBid>? bids,
    String? winningBidId,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? isBot,
    List<String>? photoUrls,
    int? mileageKm,
    String? damage,
    String? sellReason,
    int? buyNowUah,
  }) {
    return VehicleAuction(
      id: id,
      ownerLogin: ownerLogin,
      ownerLabel: ownerLabel,
      title: title,
      details: details,
      createdAt: createdAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      plate: plate,
      vin: vin,
      brand: brand,
      model: model,
      year: year,
      photoNote: photoNote,
      photoUrls: photoUrls ?? this.photoUrls,
      mileageKm: mileageKm ?? this.mileageKm,
      damage: damage ?? this.damage,
      sellReason: sellReason ?? this.sellReason,
      buyNowUah: buyNowUah ?? this.buyNowUah,
      estimateUah: estimateUah,
      shopId: shopId,
      shopName: shopName,
      orderId: orderId,
      status: status ?? this.status,
      bids: bids ?? this.bids,
      winningBidId: winningBidId ?? this.winningBidId,
      isBot: isBot ?? this.isBot,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerLogin': ownerLogin,
        'ownerLabel': ownerLabel,
        'title': title,
        'details': details,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'startsAt': startsAt.millisecondsSinceEpoch,
        'endsAt': endsAt.millisecondsSinceEpoch,
        'plate': plate,
        'vin': vin,
        'brand': brand,
        'model': model,
        'year': year,
        'photoNote': photoNote,
        'photoUrls': photoUrls,
        'mileageKm': mileageKm,
        'damage': damage,
        'sellReason': sellReason,
        'buyNowUah': buyNowUah,
        'estimateUah': estimateUah,
        'shopId': shopId,
        'shopName': shopName,
        'orderId': orderId,
        'status': status.name,
        'bids': [for (final b in bids) b.toJson()],
        'winningBidId': winningBidId,
        'isBot': isBot,
      };

  factory VehicleAuction.fromJson(Map<String, dynamic> json) {
    AuctionStatus status = AuctionStatus.live;
    for (final value in AuctionStatus.values) {
      if (value.name == json['status']) {
        status = value;
        break;
      }
    }
    final created = DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0);
    final ends = DateTime.fromMillisecondsSinceEpoch(json['endsAt'] as int? ?? 0);
    final startsRaw = json['startsAt'] as int?;
    return VehicleAuction(
      id: json['id'] as String? ?? '',
      ownerLogin: json['ownerLogin'] as String? ?? '',
      ownerLabel: json['ownerLabel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      createdAt: created,
      startsAt: startsRaw != null
          ? DateTime.fromMillisecondsSinceEpoch(startsRaw)
          : created,
      endsAt: ends,
      plate: json['plate'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as String? ?? '',
      photoNote: json['photoNote'] as String? ?? '',
      photoUrls: [
        for (final u in json['photoUrls'] as List<dynamic>? ?? const [])
          '$u',
      ],
      mileageKm: (json['mileageKm'] as num?)?.toInt() ?? 0,
      damage: json['damage'] as String? ?? '',
      sellReason: json['sellReason'] as String? ?? '',
      buyNowUah: (json['buyNowUah'] as num?)?.toInt() ?? 0,
      estimateUah: (json['estimateUah'] as num?)?.toInt() ?? 0,
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: status,
      bids: [
        for (final item in json['bids'] as List<dynamic>? ?? const [])
          AuctionBid.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      winningBidId: json['winningBidId'] as String?,
      isBot: json['isBot'] == true,
    );
  }
}
