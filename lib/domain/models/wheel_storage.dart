enum TireSeason { winter, summer, allSeason }

enum StorageCargo { tires, tiresOnRims, rims }

extension StorageCargoX on StorageCargo {
  String get code => name;

  bool get withRims => this != StorageCargo.tires;

  static StorageCargo fromCode(String? code) {
    return StorageCargo.values.firstWhere(
      (item) => item.name == code,
      orElse: () => StorageCargo.tires,
    );
  }

  static StorageCargo fromLegacy({required bool withRims}) {
    return withRims ? StorageCargo.tiresOnRims : StorageCargo.tires;
  }
}

/// Default stand: 3 sectors side by side. Each sector is 3 rows × 8 wheels.
const kDefaultSectors = 3;
const kMaxSectors = 12;
const kRackSectors = kDefaultSectors;
const kRackCells = 3;
const kWheelsPerCell = 8;
const kRackRows = kRackCells;

/// Previous stand used 6 cells per sector. Lots on cells 4–6 fold onto rows 1–3.
const kLegacyRackCells = 6;

int clampSectorCount(int? n) {
  final v = n ?? kDefaultSectors;
  if (v < kDefaultSectors) return kDefaultSectors;
  if (v > kMaxSectors) return kMaxSectors;
  return v;
}

String rackMarker(int sector, int rackRow) => '$sector-$rackRow';

/// Cells 4–6 of the old 6×8 stand land on rows 1–3 of the 3×8 stand.
int foldRackRow(int rackRow) {
  if (rackRow <= kRackCells) return rackRow;
  if (rackRow <= kLegacyRackCells) return rackRow - kRackCells;
  return ((rackRow - 1) % kRackCells) + 1;
}

bool _sameRackPlace(WheelLot a, WheelLot b) {
  return a.sector == b.sector &&
      a.rackRow == b.rackRow &&
      a.wheelCount == b.wheelCount &&
      a.wheelSlots == b.wheelSlots;
}

/// Keeps every lot. Rows 1–3 stay. Legacy rows 4–6 move onto the 3×8 grid
/// without covering a wheel that is already taken.
List<WheelLot> fitLotsOntoRack(Iterable<WheelLot> lots) {
  final list = lots.toList();
  final taken = <String, Set<int>>{};
  String cellKey(int sector, int row) => '$sector-$row';

  Set<int> wheelsOf(WheelLot lot) {
    return lot.slots.where((slot) => slot >= 1 && slot <= kWheelsPerCell).toSet();
  }

  bool free(int sector, int row, Set<int> slots) {
    final bag = taken[cellKey(sector, row)];
    if (bag == null) return true;
    for (final slot in slots) {
      if (bag.contains(slot)) return false;
    }
    return true;
  }

  void claim(int sector, int row, Set<int> slots) {
    taken.putIfAbsent(cellKey(sector, row), () => <int>{}).addAll(slots);
  }

  final out = List<WheelLot>.from(list);
  final pending = <int>[];
  var maxSector = kDefaultSectors;
  for (final lot in list) {
    if (lot.sector > maxSector && lot.sector <= kMaxSectors) maxSector = lot.sector;
  }

  for (var i = 0; i < list.length; i++) {
    final lot = list[i];
    final slots = wheelsOf(lot);
    final onGrid = lot.isActive &&
        lot.sector >= 1 &&
        lot.sector <= kMaxSectors &&
        slots.isNotEmpty;
    if (!onGrid) {
      if (lot.sector >= 1 && lot.rackRow > kRackCells) {
        final row = foldRackRow(lot.rackRow);
        if (row != lot.rackRow) out[i] = lot.copyWith(rackRow: row);
      }
      continue;
    }
    if (lot.rackRow >= 1 && lot.rackRow <= kRackCells && free(lot.sector, lot.rackRow, slots)) {
      claim(lot.sector, lot.rackRow, slots);
      continue;
    }
    pending.add(i);
  }

  for (final i in pending) {
    final lot = list[i];
    final slots = wheelsOf(lot);
    final preferred = foldRackRow(lot.rackRow < 1 ? 1 : lot.rackRow);
    final startSector = lot.sector < 1 ? 1 : (lot.sector > maxSector ? maxSector : lot.sector);
    WheelLot? placed;

    bool tryPlace(int sector, int row, Set<int> use) {
      if (sector < 1 || sector > kMaxSectors) return false;
      if (!free(sector, row, use)) return false;
      claim(sector, row, use);
      final next = lot.copyWith(
        sector: sector,
        rackRow: row,
        wheelCount: use.length,
        wheelSlots: maskFromSlots(use),
      );
      placed = _sameRackPlace(lot, next) ? lot : next;
      return true;
    }

    if (!tryPlace(startSector, preferred, slots)) {
      for (var row = 1; row <= kRackCells && placed == null; row++) {
        if (row == preferred) continue;
        tryPlace(startSector, row, slots);
      }
    }
    if (placed == null) {
      for (var sector = 1; sector <= maxSector && placed == null; sector++) {
        if (sector == startSector) continue;
        for (var row = 1; row <= kRackCells && placed == null; row++) {
          tryPlace(sector, row, slots);
        }
      }
    }
    if (placed == null) {
      final need = slots.length;
      for (var sector = 1; sector <= kMaxSectors && placed == null; sector++) {
        for (var row = 1; row <= kRackCells && placed == null; row++) {
          final bag = taken[cellKey(sector, row)] ?? const <int>{};
          final open = <int>[
            for (var slot = 1; slot <= kWheelsPerCell; slot++)
              if (!bag.contains(slot)) slot,
          ];
          if (open.length < need) continue;
          tryPlace(sector, row, open.take(need).toSet());
        }
      }
    }
    out[i] = placed ?? lot.copyWith(rackRow: preferred);
  }
  return out;
}

int maskFromSlots(Iterable<int> slots) {
  var mask = 0;
  for (final slot in slots) {
    if (slot >= 1 && slot <= kWheelsPerCell) {
      mask |= 1 << (slot - 1);
    }
  }
  return mask;
}

Set<int> slotsFromMask(int mask) {
  final slots = <int>{};
  for (var slot = 1; slot <= kWheelsPerCell; slot++) {
    if (mask & (1 << (slot - 1)) != 0) slots.add(slot);
  }
  return slots;
}

/// Slots 1..[count] from the floor up (legacy “N wheels”).
int maskFromBottomCount(int count) {
  final safe = count < 0 ? 0 : (count > kWheelsPerCell ? kWheelsPerCell : count);
  return maskFromSlots([for (var slot = 1; slot <= safe; slot++) slot]);
}

extension TireSeasonX on TireSeason {
  String get code => name;

  static TireSeason fromCode(String? code) {
    return TireSeason.values.firstWhere(
      (item) => item.name == code,
      orElse: () => TireSeason.winter,
    );
  }
}

enum StoragePayStatus { accruing, paid, partial }

extension StoragePayStatusX on StoragePayStatus {
  String get code => name;

  static StoragePayStatus fromCode(String? code) {
    return StoragePayStatus.values.firstWhere(
      (item) => item.name == code,
      orElse: () => StoragePayStatus.accruing,
    );
  }
}

const kStoragePeriodPresets = {30, 90, 180, 365};

/// Chip days win unless the custom field has a positive integer.
int resolvePlannedDays({required int selected, required String customText}) {
  final custom = int.tryParse(customText.trim());
  if (custom != null && custom > 0) return custom;
  return selected > 0 ? selected : 0;
}

class WheelLot {
  const WheelLot({
    required this.id,
    this.receivedAt,
    this.returnedAt,
    this.dateUncertain = false,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.plate = '',
    this.vin = '',
    this.vehicle = '',
    this.sizePrimary = '',
    this.sizeSecondary = '',
    this.rimDiameter = '',
    this.tireBrand = '',
    this.season = TireSeason.winter,
    this.cargo = StorageCargo.tires,
    this.sector = 0,
    this.rackRow = 0,
    this.wheelCount = 0,
    this.wheelSlots = 0,
    this.notes = '',
    this.journalNo = 0,
    this.plannedDays = 0,
    this.signaturePng = '',
    this.contractVersion = '',
    this.paidGrosze = 0,
    this.payStatus = StoragePayStatus.accruing,
    this.billingFrom,
    this.pricePerDayGrosze,
  });

  final String id;
  final DateTime? receivedAt;
  final DateTime? returnedAt;
  final bool dateUncertain;
  final String firstName;
  final String lastName;
  final String phone;
  final String plate;
  final String vin;
  final String vehicle;
  final String sizePrimary;
  final String sizeSecondary;
  final String rimDiameter;
  final String tireBrand;
  final TireSeason season;
  final StorageCargo cargo;
  final int sector;
  final int rackRow;
  final int wheelCount;
  final int wheelSlots;
  final String notes;
  final int journalNo;
  final int plannedDays;
  final String signaturePng;
  final String contractVersion;
  final int paidGrosze;
  final StoragePayStatus payStatus;
  final DateTime? billingFrom;

  /// Grosze per day for this lot only. Null follows the shop price.
  final int? pricePerDayGrosze;

  bool get hasPersonalDailyPrice => pricePerDayGrosze != null;

  bool get withRims => cargo.withRims;

  bool get isActive => returnedAt == null;

  bool get hasIntakeDate => receivedAt != null;

  bool get hasPlace =>
      sector >= 1 &&
      sector <= kMaxSectors &&
      rackRow >= 1 &&
      rackRow <= kRackCells;

  Set<int> get slots {
    if (wheelSlots != 0) return slotsFromMask(wheelSlots);
    return slotsFromMask(maskFromBottomCount(wheelCount));
  }

  bool get hasCount => slots.isNotEmpty;

  int get shownWheels => slots.length;

  String get slotsText {
    final list = slots.toList()..sort();
    return list.join(', ');
  }

  bool occupiesSlot(int slot) => slots.contains(slot);

  bool get hasPlannedPeriod => plannedDays > 0;

  bool get hasSignature => signaturePng.trim().isNotEmpty;

  DateTime? get plannedUntil {
    final start = receivedAt;
    if (start == null || plannedDays <= 0) return null;
    return DateTime(start.year, start.month, start.day).add(Duration(days: plannedDays));
  }

  DateTime? get billingStart => billingFrom ?? receivedAt;

  bool get intakeComplete => hasIntakeDate && hasPlace && hasCount;

  String get marker => hasPlace ? rackMarker(sector, rackRow) : '';

  String get ownerName {
    final name = [firstName, lastName].where((part) => part.trim().isNotEmpty).join(' ');
    return name.trim();
  }

  String get sizeLabel {
    final rim = rimDiameter.trim().isEmpty ? '' : ' R$rimDiameter';
    if (sizeSecondary.trim().isNotEmpty) {
      return '${sizePrimary.trim()} – ${sizeSecondary.trim()}$rim';
    }
    return '${sizePrimary.trim()}$rim'.trim();
  }

  WheelLot copyWith({
    String? id,
    DateTime? receivedAt,
    bool clearReceivedAt = false,
    DateTime? returnedAt,
    bool clearReturnedAt = false,
    bool? dateUncertain,
    String? firstName,
    String? lastName,
    String? phone,
    String? plate,
    String? vin,
    String? vehicle,
    String? sizePrimary,
    String? sizeSecondary,
    String? rimDiameter,
    String? tireBrand,
    TireSeason? season,
    StorageCargo? cargo,
    int? sector,
    int? rackRow,
    int? wheelCount,
    int? wheelSlots,
    bool clearPlace = false,
    String? notes,
    int? journalNo,
    int? plannedDays,
    String? signaturePng,
    String? contractVersion,
    int? paidGrosze,
    StoragePayStatus? payStatus,
    DateTime? billingFrom,
    bool clearBillingFrom = false,
    int? pricePerDayGrosze,
    bool setPricePerDay = false,
  }) {
    return WheelLot(
      id: id ?? this.id,
      receivedAt: clearReceivedAt ? null : (receivedAt ?? this.receivedAt),
      returnedAt: clearReturnedAt ? null : (returnedAt ?? this.returnedAt),
      dateUncertain: dateUncertain ?? this.dateUncertain,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      plate: plate ?? this.plate,
      vin: vin ?? this.vin,
      vehicle: vehicle ?? this.vehicle,
      sizePrimary: sizePrimary ?? this.sizePrimary,
      sizeSecondary: sizeSecondary ?? this.sizeSecondary,
      rimDiameter: rimDiameter ?? this.rimDiameter,
      tireBrand: tireBrand ?? this.tireBrand,
      season: season ?? this.season,
      cargo: cargo ?? this.cargo,
      sector: clearPlace ? 0 : (sector ?? this.sector),
      rackRow: clearPlace ? 0 : (rackRow ?? this.rackRow),
      wheelCount: clearPlace ? 0 : (wheelCount ?? this.wheelCount),
      wheelSlots: clearPlace ? 0 : (wheelSlots ?? this.wheelSlots),
      notes: notes ?? this.notes,
      journalNo: journalNo ?? this.journalNo,
      plannedDays: plannedDays ?? this.plannedDays,
      signaturePng: signaturePng ?? this.signaturePng,
      contractVersion: contractVersion ?? this.contractVersion,
      paidGrosze: paidGrosze ?? this.paidGrosze,
      payStatus: payStatus ?? this.payStatus,
      billingFrom: clearBillingFrom ? null : (billingFrom ?? this.billingFrom),
      pricePerDayGrosze:
          setPricePerDay ? pricePerDayGrosze : this.pricePerDayGrosze,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receivedAt': receivedAt?.millisecondsSinceEpoch,
        'returnedAt': returnedAt?.millisecondsSinceEpoch,
        'dateUncertain': dateUncertain,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'plate': plate,
        'vin': vin,
        'vehicle': vehicle,
        'sizePrimary': sizePrimary,
        'sizeSecondary': sizeSecondary,
        'rimDiameter': rimDiameter,
        'tireBrand': tireBrand,
        'season': season.code,
        'cargo': cargo.code,
        'sector': sector,
        'rackRow': rackRow,
        'wheelCount': wheelCount,
        'wheelSlots': wheelSlots,
        'notes': notes,
        'journalNo': journalNo,
        'plannedDays': plannedDays,
        'signaturePng': signaturePng,
        'contractVersion': contractVersion,
        'paidGrosze': paidGrosze,
        'payStatus': payStatus.code,
        'billingFrom': billingFrom?.millisecondsSinceEpoch,
        if (pricePerDayGrosze != null) 'pricePerDayGrosze': pricePerDayGrosze,
      };

  factory WheelLot.fromJson(Map<String, dynamic> json) {
    DateTime? millis(Object? value) {
      if (value is int && value != 0) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    return WheelLot(
      id: json['id'] as String? ?? '',
      receivedAt: millis(json['receivedAt']),
      returnedAt: millis(json['returnedAt']),
      dateUncertain: json['dateUncertain'] == true,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      vehicle: json['vehicle'] as String? ?? '',
      sizePrimary: json['sizePrimary'] as String? ?? '',
      sizeSecondary: json['sizeSecondary'] as String? ?? '',
      rimDiameter: json['rimDiameter'] as String? ?? '',
      tireBrand: json['tireBrand'] as String? ?? '',
      season: TireSeasonX.fromCode(json['season'] as String?),
      cargo: StorageCargoX.fromCode(json['cargo'] as String?),
      sector: (json['sector'] as num?)?.toInt() ?? 0,
      rackRow: (json['rackRow'] as num?)?.toInt() ?? 0,
      wheelCount: (json['wheelCount'] as num?)?.toInt() ?? 0,
      wheelSlots: (json['wheelSlots'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      journalNo: (json['journalNo'] as num?)?.toInt() ?? 0,
      plannedDays: (json['plannedDays'] as num?)?.toInt() ?? 0,
      signaturePng: json['signaturePng'] as String? ?? '',
      contractVersion: json['contractVersion'] as String? ?? '',
      paidGrosze: (json['paidGrosze'] as num?)?.toInt() ?? 0,
      payStatus: StoragePayStatusX.fromCode(json['payStatus'] as String?),
      billingFrom: millis(json['billingFrom']),
      pricePerDayGrosze: _optionalGrosze(json['pricePerDayGrosze']),
    );
  }
}

int? _optionalGrosze(Object? value) {
  if (value is! num) return null;
  final grosze = value.toInt();
  return grosze < 0 ? 0 : grosze;
}

/// Shop rate, unless this lot has its own saved daily price.
int effectiveDailyGrosze(WheelLot lot, int shopPricePerDayGrosze) {
  return lot.pricePerDayGrosze ?? shopPricePerDayGrosze;
}

class StorageSearch {
  const StorageSearch({
    this.phone = '',
    this.plate = '',
    this.vin = '',
    this.firstName = '',
    this.lastName = '',
    this.quick = '',
  });

  final String phone;
  final String plate;
  final String vin;
  final String firstName;
  final String lastName;
  final String quick;

  bool get isEmpty =>
      phone.trim().isEmpty &&
      plate.trim().isEmpty &&
      vin.trim().isEmpty &&
      firstName.trim().isEmpty &&
      lastName.trim().isEmpty &&
      quick.trim().isEmpty;

  StorageSearch copyWith({
    String? phone,
    String? plate,
    String? vin,
    String? firstName,
    String? lastName,
    String? quick,
  }) {
    return StorageSearch(
      phone: phone ?? this.phone,
      plate: plate ?? this.plate,
      vin: vin ?? this.vin,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      quick: quick ?? this.quick,
    );
  }
}

DateTime storageDay(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

/// Calendar days from intake date to [until] (computer clock, or checkout).
int storageDays(DateTime receivedAt, DateTime until) {
  final days = storageDay(until).difference(storageDay(receivedAt)).inDays;
  return days < 0 ? 0 : days;
}

/// Same-day pickup still bills one day of storage.
int billedStorageDays(DateTime receivedAt, DateTime until) {
  final days = storageDays(receivedAt, until);
  return days < 1 ? 1 : days;
}

int storageBillGrosze({
  required DateTime? receivedAt,
  required DateTime until,
  required int pricePerDayGrosze,
}) {
  if (receivedAt == null || pricePerDayGrosze <= 0) return 0;
  return billedStorageDays(receivedAt, until) * pricePerDayGrosze;
}

int lotBilledDays(WheelLot lot, DateTime until) {
  final start = lot.billingStart;
  if (start == null) return 0;
  if (lot.payStatus == StoragePayStatus.paid) {
    final days = storageDays(start, until);
    return days < 1 ? 0 : days;
  }
  return billedStorageDays(start, until);
}

int lotBillGrosze({
  required WheelLot lot,
  required DateTime until,
  required int pricePerDayGrosze,
}) {
  final price = effectiveDailyGrosze(lot, pricePerDayGrosze);
  if (price <= 0) return 0;
  return lotBilledDays(lot, until) * price;
}

int lotDueGrosze({
  required WheelLot lot,
  required DateTime until,
  required int pricePerDayGrosze,
}) {
  final due = lotBillGrosze(
        lot: lot,
        until: until,
        pricePerDayGrosze: pricePerDayGrosze,
      ) -
      lot.paidGrosze;
  return due < 0 ? 0 : due;
}

WheelLot lotMarkPaid(WheelLot lot, DateTime at) {
  return lot.copyWith(
    payStatus: StoragePayStatus.paid,
    paidGrosze: 0,
    billingFrom: at,
  );
}

WheelLot lotMarkAccruing(WheelLot lot) {
  return lot.copyWith(payStatus: StoragePayStatus.accruing);
}

WheelLot lotMarkPartial(WheelLot lot, int extraGrosze) {
  final add = extraGrosze < 0 ? 0 : extraGrosze;
  return lot.copyWith(
    payStatus: StoragePayStatus.partial,
    paidGrosze: lot.paidGrosze + add,
  );
}

WheelLot lotExtendByDays(WheelLot lot, int extraDays) {
  final extra = extraDays < 1 ? 0 : extraDays;
  return lot.copyWith(plannedDays: lot.plannedDays + extra);
}

WheelLot lotExtendUntil(WheelLot lot, DateTime end) {
  final start = lot.receivedAt;
  if (start == null) return lot;
  final days = storageDay(end).difference(storageDay(start)).inDays;
  return lot.copyWith(plannedDays: days < 1 ? 1 : days);
}

class StorageSpan {
  const StorageSpan({
    required this.days,
    required this.years,
    required this.months,
    required this.restDays,
  });

  final int days;
  final int years;
  final int months;
  final int restDays;
}

StorageSpan storageSpan(int days) {
  final safe = days < 0 ? 0 : days;
  final years = safe ~/ 365;
  final afterYears = safe % 365;
  final months = afterYears ~/ 30;
  return StorageSpan(
    days: safe,
    years: years,
    months: months,
    restDays: afterYears % 30,
  );
}

String normalizeStorageQuery(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-./]'), '');
}

bool _fieldMatches(String field, String query) {
  if (query.trim().isEmpty) return true;
  return normalizeStorageQuery(field).contains(normalizeStorageQuery(query));
}

bool lotMatchesSearch(WheelLot lot, StorageSearch search) {
  if (search.isEmpty) return true;
  final fieldsOk = _fieldMatches(lot.phone, search.phone) &&
      _fieldMatches(lot.plate, search.plate) &&
      _fieldMatches(lot.vin, search.vin) &&
      _fieldMatches(lot.firstName, search.firstName) &&
      _fieldMatches(lot.lastName, search.lastName);
  if (!fieldsOk) return false;
  final quick = search.quick.trim();
  if (quick.isEmpty) return true;
  final haystack = [
    lot.phone,
    lot.plate,
    lot.vin,
    lot.firstName,
    lot.lastName,
    lot.ownerName,
    lot.vehicle,
    lot.tireBrand,
    lot.sizeLabel,
    lot.notes,
    lot.marker,
    if (lot.hasCount) '${lot.wheelCount}',
  ].join(' ');
  return normalizeStorageQuery(haystack).contains(normalizeStorageQuery(quick));
}

WheelLot? lotInCell(
  Iterable<WheelLot> lots,
  int sector,
  int rackRow, {
  String? exceptId,
}) {
  for (final lot in lots) {
    if (!lot.isActive) continue;
    if (exceptId != null && lot.id == exceptId) continue;
    if (lot.sector == sector && lot.rackRow == rackRow && lot.hasCount) {
      return lot;
    }
  }
  return null;
}

WheelLot? lotInSlot(
  Iterable<WheelLot> lots,
  int sector,
  int rackRow,
  int slot, {
  String? exceptId,
}) {
  for (final lot in lots) {
    if (!lot.isActive) continue;
    if (exceptId != null && lot.id == exceptId) continue;
    if (lot.sector == sector && lot.rackRow == rackRow && lot.occupiesSlot(slot)) {
      return lot;
    }
  }
  return null;
}

bool sectorHasActiveLots(Iterable<WheelLot> lots, int sector) {
  for (final lot in lots) {
    if (!lot.isActive) continue;
    if (lot.sector == sector) return true;
  }
  return false;
}

Set<int> takenSlots(
  Iterable<WheelLot> lots,
  int sector,
  int rackRow, {
  String? exceptId,
}) {
  final taken = <int>{};
  for (final lot in lots) {
    if (!lot.isActive) continue;
    if (exceptId != null && lot.id == exceptId) continue;
    if (lot.sector == sector && lot.rackRow == rackRow) {
      taken.addAll(lot.slots);
    }
  }
  return taken;
}

int compareLotsByIntake(WheelLot a, WheelLot b) {
  final aDate = a.receivedAt;
  final bDate = b.receivedAt;
  if (aDate == null && bDate == null) {
    return a.journalNo.compareTo(b.journalNo);
  }
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  if (byDate != 0) return byDate;
  return a.journalNo.compareTo(b.journalNo);
}

List<WheelLot> filterLots(
  Iterable<WheelLot> lots, {
  required StorageSearch search,
  required bool activeOnly,
}) {
  return lots
      .where((lot) => activeOnly ? lot.isActive : !lot.isActive)
      .where((lot) => lotMatchesSearch(lot, search))
      .toList()
    ..sort(compareLotsByIntake);
}
