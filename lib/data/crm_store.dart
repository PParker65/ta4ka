import 'dart:convert';
import 'dart:typed_data';

import '../app/theme.dart';
import '../core/l10n/app_lang.dart';
import '../domain/models/auth_session.dart';
import '../domain/models/crm_models.dart';
import '../domain/models/platform_features.dart';
import '../domain/models/referral.dart';
import '../domain/models/client_loyalty.dart';
import '../domain/models/shop_account.dart';
import '../domain/models/tap_wallet.dart';

abstract class CrmStore {
  Future<void> init();

  AppLang loadLang();
  void saveLang(AppLang lang);

  AppVisualTheme loadTheme();
  void saveTheme(AppVisualTheme theme);

  AuthSession? loadSession();
  void saveSession(AuthSession? session);

  ShopAccount? loadShopAccount();
  void saveShopAccount(ShopAccount? account);

  TapWalletState loadTapWallet();
  void saveTapWallet(TapWalletState wallet);

  int? rememberedPrice(String workId, PriceTier tier);
  void rememberPrice(String workId, PriceTier tier, int priceUah);

  List<WorkOrder> loadOrders();
  void upsertOrder(WorkOrder order);
  void deleteOrder(String id);

  List<Rating> loadRatings();
  void addRating(Rating rating);

  List<BlacklistEntry> loadBlacklist();
  void saveBlacklist(List<BlacklistEntry> items);

  List<OpenJobRequest> loadOpenJobs();
  void saveOpenJobs(List<OpenJobRequest> items);

  List<VehicleAuction> loadAuctions();
  void saveAuctions(List<VehicleAuction> items);

  List<GarageCar> loadGarageCars(String ownerLogin);
  void saveGarageCars(String ownerLogin, List<GarageCar> cars);

  List<BusinessInvoice> loadBusinessInvoices(String ownerLogin);
  void saveBusinessInvoices(String ownerLogin, List<BusinessInvoice> items);

  List<PartsRequest> loadPartsRequests();
  void savePartsRequests(List<PartsRequest> items);

  List<MapaHelpReport> loadMapaReports();
  void saveMapaReports(List<MapaHelpReport> items);

  ReferralHub loadReferralHub();
  void saveReferralHub(ReferralHub hub);

  Map<String, ClientLoyalty> loadClientLoyalty();
  void saveClientLoyalty(Map<String, ClientLoyalty> map);
}

Map<String, dynamic> inspectionToJson(VehicleInspection inspection) {
  return {
    'mileageKm': inspection.mileageKm,
    'fuelEighths': inspection.fuelEighths,
    'defects': {
      for (final entry in inspection.zoneDefects.entries)
        entry.key.name: [for (final kind in entry.value) kind.name],
    },
    'photos': [
      for (final photo in inspection.photos)
        {
          'id': photo.id,
          'name': photo.name,
          'bytes': base64Encode(Uint8List.fromList(photo.bytes)),
        },
    ],
  };
}

VehicleInspection inspectionFromJson(Map<String, dynamic> json) {
  final defectsRaw = json['defects'] as Map<String, dynamic>? ?? {};
  final photosRaw = json['photos'] as List<dynamic>? ?? [];
  return VehicleInspection(
    mileageKm: json['mileageKm'] as int?,
    fuelEighths: json['fuelEighths'] as int? ?? 4,
    zoneDefects: {
      for (final entry in defectsRaw.entries)
        BodyZone.values.byName(entry.key): {
          for (final name in entry.value as List<dynamic>)
            DefectKind.values.byName(name as String),
        },
    },
    photos: [
      for (final photo in photosRaw)
        InspectionPhoto(
          id: photo['id'] as String,
          name: photo['name'] as String,
          bytes: base64Decode(photo['bytes'] as String),
        ),
    ],
  );
}

Map<String, dynamic> orderToJson(WorkOrder order) {
  return {
    'id': order.id,
    'plate': order.plate,
    'brand': order.brand,
    'model': order.model,
    'year': order.year,
    'mileage': order.mileage,
    'vin': order.vin,
    'category': order.category.name,
    'status': order.status.name,
    'createdAt': order.createdAt.millisecondsSinceEpoch,
    'boxId': order.boxId,
    'masterId': order.masterId,
    'shopId': order.shopId,
    'clientLogin': order.clientLogin,
    'scheduledAt': order.scheduledAt?.millisecondsSinceEpoch,
    'inspection': inspectionToJson(order.inspection),
    'chat': [for (final item in order.chat) item.toJson()],
    'draftEstimate': [for (final item in order.draftEstimate) item.toJson()],
    'defectPhotos': [for (final item in order.defectPhotos) item.toJson()],
    'commissionBaseUah': order.commissionBaseUah,
    'lines': [
      for (final line in order.lines)
        {
          'workId': line.workId,
          'titleUk': line.title.uk,
          'titleEn': line.title.en,
          'titleRu': line.title.ru,
          'tier': line.tier.name,
            'priceUah': line.priceUah,
            'minutes': line.minutes,
            'approved': line.approved,
            'extra': line.extra,
        },
    ],
  };
}

WorkOrder orderFromJson(Map<String, dynamic> json) {
  final lines = json['lines'] as List<dynamic>? ?? [];
  return WorkOrder(
    id: json['id'] as String,
    plate: json['plate'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    year: json['year'] as int? ?? 0,
    mileage: json['mileage'] as int,
    vin: json['vin'] as String,
    category: RepairCategory.values.byName(json['category'] as String),
    status: JobStatus.values.byName(json['status'] as String),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    boxId: json['boxId'] as String?,
    masterId: json['masterId'] as String?,
    shopId: json['shopId'] as String? ?? '',
    clientLogin: json['clientLogin'] as String? ?? '',
    scheduledAt: json['scheduledAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['scheduledAt'] as int),
    inspection: inspectionFromJson(
      Map<String, dynamic>.from(json['inspection'] as Map? ?? {}),
    ),
    chat: [
      for (final item in json['chat'] as List<dynamic>? ?? [])
        ServiceChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    draftEstimate: [
      for (final item in json['draftEstimate'] as List<dynamic>? ?? [])
        DraftEstimateLine.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    defectPhotos: [
      for (final item in json['defectPhotos'] as List<dynamic>? ?? [])
        MarkedDefectPhoto.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
    commissionBaseUah: (json['commissionBaseUah'] as num?)?.toInt() ?? 0,
    lines: [
      for (final line in lines)
        OrderLine(
          workId: line['workId'] as String,
          title: L(
            line['titleUk'] as String,
            line['titleEn'] as String,
            line['titleRu'] as String,
          ),
          tier: PriceTier.values.byName(line['tier'] as String),
          priceUah: line['priceUah'] as int,
          minutes: line['minutes'] as int,
          approved: line['approved'] != false,
          extra: line['extra'] == true,
        ),
    ],
  );
}

Map<String, dynamic> ratingToJson(Rating rating) {
  return {
    'id': rating.id,
    'orderId': rating.orderId,
    'masterId': rating.masterId,
    'stars': rating.stars,
    'quality': rating.quality,
    'politeness': rating.politeness,
    'punctuality': rating.punctuality,
    'cleanliness': rating.cleanliness,
    'comment': rating.comment,
    'createdAt': rating.createdAt.millisecondsSinceEpoch,
  };
}

Rating ratingFromJson(Map<String, dynamic> json) {
  final stars = json['stars'] as int? ?? 5;
  return Rating(
    id: json['id'] as String,
    orderId: json['orderId'] as String,
    masterId: json['masterId'] as String,
    quality: json['quality'] as int? ?? stars,
    politeness: json['politeness'] as int? ?? stars,
    punctuality: json['punctuality'] as int? ?? stars,
    cleanliness: json['cleanliness'] as int? ?? stars,
    comment: json['comment'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
  );
}
