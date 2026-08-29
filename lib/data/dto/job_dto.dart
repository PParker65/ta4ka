class JobCreateRequest {
  const JobCreateRequest({
    required this.shopId,
    this.slotId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.symptomId,
    required this.wantId,
    required this.tier,
    this.note = '',
  });

  final String shopId;
  final String? slotId;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String symptomId;
  final String wantId;
  final String tier;
  final String note;

  Map<String, dynamic> toJson() => {
        'shop_id': shopId,
        if (slotId != null) 'slot_id': slotId,
        'plate': plate,
        'brand': brand,
        'model': model,
        'year': year,
        'symptom_id': symptomId,
        'want_id': wantId,
        'tier': tier,
        'note': note,
      };

  factory JobCreateRequest.fromJson(Map<String, dynamic> json) {
    return JobCreateRequest(
      shopId: json['shop_id'] as String? ?? 'local-shop',
      slotId: json['slot_id'] as String?,
      plate: json['plate'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      symptomId: json['symptom_id'] as String,
      wantId: json['want_id'] as String,
      tier: json['tier'] as String? ?? 'standard',
      note: json['note'] as String? ?? '',
    );
  }
}

class JobDto {
  const JobDto({
    required this.id,
    required this.shopId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.symptomId,
    required this.wantId,
    required this.workId,
    required this.tier,
    required this.priceUah,
    required this.minutes,
    required this.status,
    required this.isEmergency,
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String symptomId;
  final String wantId;
  final String workId;
  final String tier;
  final int priceUah;
  final int minutes;
  final String status;
  final bool isEmergency;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'plate': plate,
        'brand': brand,
        'model': model,
        'year': year,
        'symptom_id': symptomId,
        'want_id': wantId,
        'work_id': workId,
        'tier': tier,
        'price_uah': priceUah,
        'minutes': minutes,
        'status': status,
        'is_emergency': isEmergency,
        'created_at': createdAt.toIso8601String(),
      };

  factory JobDto.fromJson(Map<String, dynamic> json) {
    return JobDto(
      id: json['id'] as String,
      shopId: json['shop_id'] as String? ?? 'local-shop',
      plate: json['plate'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int? ?? 0,
      symptomId: json['symptom_id'] as String? ?? 'unknown',
      wantId: json['want_id'] as String? ?? 'diag',
      workId: json['work_id'] as String? ?? 'diag-comp',
      tier: json['tier'] as String? ?? 'standard',
      priceUah: json['price_uah'] as int? ?? 0,
      minutes: json['minutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'booked',
      isEmergency: json['is_emergency'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ApiError {
  const ApiError({required this.code, required this.message});

  final String code;
  final String message;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>? ?? json;
    return ApiError(
      code: error['code'] as String? ?? 'UNKNOWN',
      message: error['message'] as String? ?? 'Request failed',
    );
  }
}
