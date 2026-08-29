import 'dart:convert';
import 'dart:typed_data';

import '../../core/l10n/app_lang.dart';

enum RepairCategory { diagnostics, chassis, electrical, maintenance, engine }

enum PriceTier { basic, standard, premium }

enum JobStatus { created, inProgress, approval, ready, cancelled }

enum MasterSpecialty { electrician, motorist, chassis, maintenance }

enum BodyZone {
  frontBumper,
  hood,
  leftFender,
  rightFender,
  leftDoor,
  rightDoor,
  roof,
  glass,
  rearBumper,
}

enum DefectKind { scratch, dent, other }

class ServiceWork {
  const ServiceWork({
    required this.id,
    required this.category,
    required this.title,
    required this.specialty,
    required this.minutes,
    required this.priceBasic,
    required this.priceStandard,
    required this.pricePremium,
    required this.olegTip,
  });

  final String id;
  final RepairCategory category;
  final L title;
  final MasterSpecialty specialty;
  final int minutes;
  final int priceBasic;
  final int priceStandard;
  final int pricePremium;
  final L olegTip;

  int priceFor(PriceTier tier) => switch (tier) {
        PriceTier.basic => priceBasic,
        PriceTier.standard => priceStandard,
        PriceTier.premium => pricePremium,
      };
}

class Master {
  const Master({
    required this.id,
    required this.name,
    required this.specialty,
  });

  final String id;
  final L name;
  final MasterSpecialty specialty;
}

class WorkshopBox {
  const WorkshopBox({required this.id, required this.name});

  final String id;
  final L name;
}

class InspectionPhoto {
  const InspectionPhoto({
    required this.id,
    required this.name,
    required this.bytes,
  });

  final String id;
  final String name;
  final List<int> bytes;
}

class VehicleInspection {
  const VehicleInspection({
    this.mileageKm,
    this.fuelEighths = 4,
    this.zoneDefects = const {},
    this.photos = const [],
  });

  final int? mileageKm;
  final int fuelEighths;
  final Map<BodyZone, Set<DefectKind>> zoneDefects;
  final List<InspectionPhoto> photos;

  VehicleInspection copyWith({
    int? mileageKm,
    bool clearMileage = false,
    int? fuelEighths,
    Map<BodyZone, Set<DefectKind>>? zoneDefects,
    List<InspectionPhoto>? photos,
  }) {
    return VehicleInspection(
      mileageKm: clearMileage ? null : (mileageKm ?? this.mileageKm),
      fuelEighths: fuelEighths ?? this.fuelEighths,
      zoneDefects: zoneDefects ?? this.zoneDefects,
      photos: photos ?? this.photos,
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.workId,
    required this.title,
    required this.tier,
    required this.priceUah,
    required this.minutes,
    this.approved = true,
    this.extra = false,
  });

  final String workId;
  final L title;
  final PriceTier tier;
  final int priceUah;
  final int minutes;
  final bool approved;
  final bool extra;

  OrderLine copyWith({bool? approved}) {
    return OrderLine(
      workId: workId,
      title: title,
      tier: tier,
      priceUah: priceUah,
      minutes: minutes,
      approved: approved ?? this.approved,
      extra: extra,
    );
  }
}

/// Live draft line on the lift — visible to client before admin stamp.
class DraftEstimateLine {
  const DraftEstimateLine({
    required this.id,
    required this.title,
    required this.priceUah,
    required this.labor,
    required this.at,
  });

  final String id;
  final String title;
  final int priceUah;
  final bool labor;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priceUah': priceUah,
        'labor': labor,
        'at': at.millisecondsSinceEpoch,
      };

  factory DraftEstimateLine.fromJson(Map<String, dynamic> json) {
    return DraftEstimateLine(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      priceUah: (json['priceUah'] as num?)?.toInt() ?? 0,
      labor: json['labor'] == true,
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
    );
  }
}

enum DefectMarkKind { circle, arrow }

class DefectMark {
  const DefectMark({
    required this.kind,
    required this.x,
    required this.y,
    this.x2 = 0,
    this.y2 = 0,
  });

  final DefectMarkKind kind;
  /// Normalized 0..1
  final double x;
  final double y;
  final double x2;
  final double y2;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'x': x,
        'y': y,
        'x2': x2,
        'y2': y2,
      };

  factory DefectMark.fromJson(Map<String, dynamic> json) {
    DefectMarkKind kind = DefectMarkKind.circle;
    for (final value in DefectMarkKind.values) {
      if (value.name == json['kind']) {
        kind = value;
        break;
      }
    }
    return DefectMark(
      kind: kind,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      x2: (json['x2'] as num?)?.toDouble() ?? 0,
      y2: (json['y2'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MarkedDefectPhoto {
  const MarkedDefectPhoto({
    required this.id,
    required this.bytes,
    required this.at,
    this.caption = '',
    this.marks = const [],
  });

  final String id;
  final List<int> bytes;
  final DateTime at;
  final String caption;
  final List<DefectMark> marks;

  MarkedDefectPhoto copyWith({List<DefectMark>? marks, String? caption}) {
    return MarkedDefectPhoto(
      id: id,
      bytes: bytes,
      at: at,
      caption: caption ?? this.caption,
      marks: marks ?? this.marks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bytes': base64Encode(Uint8List.fromList(bytes)),
        'at': at.millisecondsSinceEpoch,
        'caption': caption,
        'marks': [for (final m in marks) m.toJson()],
      };

  factory MarkedDefectPhoto.fromJson(Map<String, dynamic> json) {
    return MarkedDefectPhoto(
      id: json['id'] as String? ?? '',
      bytes: base64Decode(json['bytes'] as String? ?? ''),
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
      caption: json['caption'] as String? ?? '',
      marks: [
        for (final item in json['marks'] as List<dynamic>? ?? const [])
          DefectMark.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}

class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    this.year = 0,
    required this.mileage,
    required this.vin,
    required this.category,
    required this.lines,
    required this.status,
    required this.createdAt,
    this.boxId,
    this.masterId,
    this.shopId = '',
    this.clientLogin = '',
    this.scheduledAt,
    this.intakeAt,
    this.completedAt,
    this.inspection = const VehicleInspection(),
    this.chat = const [],
    this.draftEstimate = const [],
    this.defectPhotos = const [],
    this.commissionBaseUah = 0,
  });

  final String id;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String vin;
  final RepairCategory category;
  final List<OrderLine> lines;
  final JobStatus status;
  final DateTime createdAt;
  final String? boxId;
  final String? masterId;
  final String shopId;
  final String clientLogin;
  final DateTime? scheduledAt;
  final DateTime? intakeAt;
  final DateTime? completedAt;
  final VehicleInspection inspection;
  final List<ServiceChatMessage> chat;
  final List<DraftEstimateLine> draftEstimate;
  final List<MarkedDefectPhoto> defectPhotos;
  /// Booking total already used for 5% platform fee (avoids double charge).
  final int commissionBaseUah;

  int get intakeMileageKm =>
      inspection.mileageKm ?? (mileage > 0 ? mileage : 0);

  int get totalUah =>
      confirmedLines.fold(0, (sum, line) => sum + line.priceUah);
  int get pendingUah => pendingLines.fold(0, (sum, line) => sum + line.priceUah);
  int get draftEstimateUah =>
      draftEstimate.fold(0, (sum, line) => sum + line.priceUah);
  int get etaMinutes =>
      confirmedLines.fold(0, (sum, line) => sum + line.minutes);
  List<OrderLine> get confirmedLines =>
      [for (final line in lines) if (line.approved) line];
  List<OrderLine> get pendingLines => [
        for (final line in lines)
          if (line.extra && !line.approved) line,
      ];
  bool get hasPendingExtras => pendingLines.isNotEmpty;
  bool get hasLiveDraft => draftEstimate.isNotEmpty;

  WorkOrder copyWith({
    JobStatus? status,
    String? boxId,
    String? masterId,
    String? shopId,
    String? clientLogin,
    String? plate,
    String? vin,
    DateTime? scheduledAt,
    DateTime? intakeAt,
    DateTime? completedAt,
    int? mileage,
    bool clearBox = false,
    bool clearMaster = false,
    VehicleInspection? inspection,
    List<OrderLine>? lines,
    List<ServiceChatMessage>? chat,
    List<DraftEstimateLine>? draftEstimate,
    List<MarkedDefectPhoto>? defectPhotos,
    int? commissionBaseUah,
  }) {
    return WorkOrder(
      id: id,
      plate: plate ?? this.plate,
      brand: brand,
      model: model,
      year: year,
      mileage: mileage ?? this.mileage,
      vin: vin ?? this.vin,
      category: category,
      lines: lines ?? this.lines,
      status: status ?? this.status,
      createdAt: createdAt,
      boxId: clearBox ? null : (boxId ?? this.boxId),
      masterId: clearMaster ? null : (masterId ?? this.masterId),
      shopId: shopId ?? this.shopId,
      clientLogin: clientLogin ?? this.clientLogin,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      intakeAt: intakeAt ?? this.intakeAt,
      completedAt: completedAt ?? this.completedAt,
      inspection: inspection ?? this.inspection,
      chat: chat ?? this.chat,
      draftEstimate: draftEstimate ?? this.draftEstimate,
      defectPhotos: defectPhotos ?? this.defectPhotos,
      commissionBaseUah: commissionBaseUah ?? this.commissionBaseUah,
    );
  }
}

class ServiceChatMessage {
  const ServiceChatMessage({
    required this.id,
    required this.fromShop,
    required this.text,
    required this.at,
    this.withMaster = false,
  });

  final String id;
  /// Shop desk side of the thread (vs client or master).
  final bool fromShop;
  /// When true: shop ↔ technician thread; when false: shop ↔ client.
  final bool withMaster;
  final L text;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromShop': fromShop,
        'withMaster': withMaster,
        'uk': text.uk,
        'en': text.en,
        'ru': text.ru,
        'at': at.millisecondsSinceEpoch,
      };

  factory ServiceChatMessage.fromJson(Map<String, dynamic> json) {
    return ServiceChatMessage(
      id: json['id'] as String? ?? '',
      fromShop: json['fromShop'] == true,
      withMaster: json['withMaster'] == true,
      text: L(
        json['uk'] as String? ?? json['text'] as String? ?? '',
        json['en'] as String? ?? json['text'] as String? ?? '',
        json['ru'] as String? ?? json['text'] as String? ?? '',
      ),
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
    );
  }
}

class Rating {
  const Rating({
    required this.id,
    required this.orderId,
    required this.masterId,
    required this.quality,
    required this.politeness,
    required this.punctuality,
    required this.cleanliness,
    required this.comment,
    required this.createdAt,
  });

  factory Rating.uniform({
    required String id,
    required String orderId,
    required String masterId,
    required int stars,
    required String comment,
    required DateTime createdAt,
  }) {
    return Rating(
      id: id,
      orderId: orderId,
      masterId: masterId,
      quality: stars,
      politeness: stars,
      punctuality: stars,
      cleanliness: stars,
      comment: comment,
      createdAt: createdAt,
    );
  }

  final String id;
  final String orderId;
  final String masterId;
  final int quality;
  final int politeness;
  final int punctuality;
  final int cleanliness;
  final String comment;
  final DateTime createdAt;

  double get average =>
      (quality + politeness + punctuality + cleanliness) / 4;
  int get stars => average.round();
}

class SelectedWork {
  const SelectedWork({required this.work, required this.tier, required this.priceUah});

  final ServiceWork work;
  final PriceTier tier;
  final int priceUah;
}
