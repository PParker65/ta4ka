import '../../core/l10n/app_lang.dart';
import '../../data/auto_spheres.dart';
import 'desk_master.dart';
import 'shop_models.dart';
import '../shop_commission.dart';

class ShopAccount {
  const ShopAccount({
    required this.login,
    required this.shopName,
    required this.city,
    required this.address,
    required this.phone,
    required this.sphereIds,
    this.offeredWorkIds = const [],
    this.customServices = const [],
    this.about = '',
    this.staffCount = 4,
    this.positioning = 'service',
    this.priceGrade = 'standard',
    this.dailyLoadPercent = 40,
    this.partsDelivery = false,
    this.cameraConnected = false,
    this.liveOn = false,
    this.commissionDebtUah = 0,
    this.lastSettledAt,
    this.paymentRequisites = '',
    this.forceUnblocked = false,
    this.hoursText = '',
    this.openHour = 9,
    this.closeHour = 18,
    this.catalogShopId = 'pitlane',
    this.deskMasters = const [],
    this.mapaHelpOptIn = false,
    this.mapaHelpPaused = false,
    this.logoVariant = 0,
    this.titleFont = 0,
    this.logoWord = '',
  });

  final String login;
  final String shopName;
  final String city;
  final String address;
  final String phone;
  final List<String> sphereIds;
  final List<String> offeredWorkIds;
  final List<String> customServices;
  final String about;
  final int staffCount;
  final String positioning; // garage | service | dealer
  final String priceGrade; // economy | standard | premium
  final int dailyLoadPercent; // 0..100
  final bool partsDelivery;
  final bool cameraConnected;
  final bool liveOn;

  /// Negative platform balance: 5% of completed bookings owed to Ta4ka.
  final int commissionDebtUah;
  final DateTime? lastSettledAt;
  final String paymentRequisites;
  /// Manual override after payment confirmation.
  final bool forceUnblocked;
  /// Custom hours label; empty → default [kShopHours].
  final String hoursText;
  /// Weekday open hour (0–23), Mon–Sat by default.
  final int openHour;
  final int closeHour;
  /// Seeded catalog shop that shows this desk's technicians to clients.
  final String catalogShopId;
  final List<DeskMaster> deskMasters;
  /// Opt-in: night / roadside help — shows MAPA Help badge in the shop list.
  final bool mapaHelpOptIn;
  /// Temporarily off after client no-answer reports until owner re-confirms.
  final bool mapaHelpPaused;
  /// 0..11 generated logo frame chosen at register / design desk.
  final int logoVariant;
  /// 0..4 title typeface for the shop name in the client list.
  final int titleFont;
  /// Optional monogram (1–4 letters) drawn on the mark.
  final String logoWord;

  bool get mapaHelpActive => mapaHelpOptIn && !mapaHelpPaused;

  bool get isBlocked =>
      !forceUnblocked &&
      ShopCommission.shouldBlock(
        debtUah: commissionDebtUah,
        lastSettledAt: lastSettledAt,
      );

  static const defaults = ShopAccount(
    login: '',
    shopName: '',
    city: 'Warsaw',
    address: '',
    phone: '',
    sphereIds: ['diag', 'chassis', 'engine', 'service'],
    offeredWorkIds: [],
    customServices: [],
    about: '',
    staffCount: 4,
    positioning: 'service',
    priceGrade: 'standard',
    dailyLoadPercent: 40,
    partsDelivery: false,
    hoursText: '',
    openHour: 9,
    closeHour: 18,
    catalogShopId: 'pitlane',
    deskMasters: [],
    mapaHelpOptIn: false,
    mapaHelpPaused: false,
    logoVariant: 0,
    titleFont: 0,
    logoWord: '',
  );

  List<String> get workIds {
    final ids = <String>{};
    for (final sphere in spheresFromIds(sphereIds)) {
      ids.addAll(sphere.workIds);
    }
    return ids.toList();
  }

  L get hours {
    if (hoursText.trim().isNotEmpty) {
      final t = hoursText.trim();
      return L(t, t, t, t);
    }
    return kShopHours;
  }

  /// Highlight when within Mon–Sat open hours (local time).
  bool get isOpenNow {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) {
      return false;
    }
    final minutes = now.hour * 60 + now.minute;
    return minutes >= openHour * 60 && minutes < closeHour * 60;
  }

  ShopAccount copyWith({
    String? login,
    String? shopName,
    String? city,
    String? address,
    String? phone,
    List<String>? sphereIds,
    List<String>? offeredWorkIds,
    List<String>? customServices,
    String? about,
    int? staffCount,
    String? positioning,
    String? priceGrade,
    int? dailyLoadPercent,
    bool? partsDelivery,
    bool? cameraConnected,
    bool? liveOn,
    int? commissionDebtUah,
    DateTime? lastSettledAt,
    bool clearSettled = false,
    String? paymentRequisites,
    bool? forceUnblocked,
    String? hoursText,
    int? openHour,
    int? closeHour,
    String? catalogShopId,
    List<DeskMaster>? deskMasters,
    bool? mapaHelpOptIn,
    bool? mapaHelpPaused,
    int? logoVariant,
    int? titleFont,
    String? logoWord,
  }) {
    return ShopAccount(
      login: login ?? this.login,
      shopName: shopName ?? this.shopName,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      sphereIds: sphereIds ?? this.sphereIds,
      offeredWorkIds: offeredWorkIds ?? this.offeredWorkIds,
      customServices: customServices ?? this.customServices,
      about: about ?? this.about,
      staffCount: staffCount ?? this.staffCount,
      positioning: positioning ?? this.positioning,
      priceGrade: priceGrade ?? this.priceGrade,
      dailyLoadPercent: dailyLoadPercent ?? this.dailyLoadPercent,
      partsDelivery: partsDelivery ?? this.partsDelivery,
      cameraConnected: cameraConnected ?? this.cameraConnected,
      liveOn: liveOn ?? this.liveOn,
      commissionDebtUah: commissionDebtUah ?? this.commissionDebtUah,
      lastSettledAt: clearSettled ? null : (lastSettledAt ?? this.lastSettledAt),
      paymentRequisites: paymentRequisites ?? this.paymentRequisites,
      forceUnblocked: forceUnblocked ?? this.forceUnblocked,
      hoursText: hoursText ?? this.hoursText,
      openHour: openHour ?? this.openHour,
      closeHour: closeHour ?? this.closeHour,
      catalogShopId: catalogShopId ?? this.catalogShopId,
      deskMasters: deskMasters ?? this.deskMasters,
      mapaHelpOptIn: mapaHelpOptIn ?? this.mapaHelpOptIn,
      mapaHelpPaused: mapaHelpPaused ?? this.mapaHelpPaused,
      logoVariant: logoVariant ?? this.logoVariant,
      titleFont: titleFont ?? this.titleFont,
      logoWord: logoWord ?? this.logoWord,
    );
  }

  Map<String, dynamic> toJson() => {
        'login': login,
        'shopName': shopName,
        'city': city,
        'address': address,
        'phone': phone,
        'sphereIds': sphereIds,
        'offeredWorkIds': offeredWorkIds,
        'customServices': customServices,
        'about': about,
        'staffCount': staffCount,
        'positioning': positioning,
        'priceGrade': priceGrade,
        'dailyLoadPercent': dailyLoadPercent,
        'partsDelivery': partsDelivery,
        'cameraConnected': cameraConnected,
        'liveOn': liveOn,
        'commissionDebtUah': commissionDebtUah,
        'lastSettledAt': lastSettledAt?.toIso8601String(),
        'paymentRequisites': paymentRequisites,
        'forceUnblocked': forceUnblocked,
        'hoursText': hoursText,
        'openHour': openHour,
        'closeHour': closeHour,
        'catalogShopId': catalogShopId,
        'deskMasters': [for (final m in deskMasters) m.toJson()],
        'mapaHelpOptIn': mapaHelpOptIn,
        'mapaHelpPaused': mapaHelpPaused,
        'logoVariant': logoVariant,
        'titleFont': titleFont,
        'logoWord': logoWord,
      };

  factory ShopAccount.fromJson(Map<String, dynamic> json) {
    DateTime? settled;
    final rawSettled = json['lastSettledAt'] as String?;
    if (rawSettled != null && rawSettled.isNotEmpty) {
      settled = DateTime.tryParse(rawSettled);
    }
    return ShopAccount(
      login: json['login'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      city: json['city'] as String? ?? 'Warsaw',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      sphereIds: [
        for (final id in json['sphereIds'] as List<dynamic>? ?? const [])
          id as String,
      ],
      offeredWorkIds: [
        for (final id in json['offeredWorkIds'] as List<dynamic>? ?? const [])
          id as String,
      ],
      customServices: [
        for (final item in json['customServices'] as List<dynamic>? ?? const [])
          item as String,
      ],
      about: json['about'] as String? ?? '',
      staffCount: (json['staffCount'] as num?)?.toInt() ?? 4,
      positioning: json['positioning'] as String? ?? 'service',
      priceGrade: json['priceGrade'] as String? ?? 'standard',
      dailyLoadPercent: ((json['dailyLoadPercent'] as num?)?.toInt() ?? 40).clamp(0, 100),
      partsDelivery: json['partsDelivery'] == true,
      cameraConnected: json['cameraConnected'] == true,
      liveOn: json['liveOn'] == true,
      commissionDebtUah: (json['commissionDebtUah'] as num?)?.toInt() ?? 0,
      lastSettledAt: settled,
      paymentRequisites: json['paymentRequisites'] as String? ?? '',
      forceUnblocked: json['forceUnblocked'] == true,
      hoursText: json['hoursText'] as String? ?? '',
      openHour: (json['openHour'] as num?)?.toInt() ?? 9,
      closeHour: (json['closeHour'] as num?)?.toInt() ?? 18,
      catalogShopId: json['catalogShopId'] as String? ?? 'pitlane',
      deskMasters: [
        for (final item in json['deskMasters'] as List<dynamic>? ?? const [])
          DeskMaster.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      mapaHelpOptIn: json['mapaHelpOptIn'] == true,
      mapaHelpPaused: json['mapaHelpPaused'] == true,
      logoVariant: ((json['logoVariant'] as num?)?.toInt() ?? 0).clamp(0, 11),
      titleFont: ((json['titleFont'] as num?)?.toInt() ?? 0).clamp(0, 4),
      logoWord: json['logoWord'] as String? ?? '',
    );
  }
}
