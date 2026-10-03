import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/models/wheel_storage.dart';
import 'storage_cloud_api.dart';
import 'wheel_storage_owner.dart';
import 'wheel_storage_seed.dart';

export 'wheel_storage_owner.dart';

class WheelStorageStore {
  WheelStorageStore({
    this.memory = false,
    String ownerKey = '',
    bool? seedJournal,
  })  : ownerKey = normalizeStorageOwner(ownerKey),
        seedJournal = seedJournal ?? isStaffStorageOwner(ownerKey);

  final bool memory;
  final String ownerKey;
  final bool seedJournal;
  Database? _db;

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('Wheel storage database is not initialized');
    }
    return database;
  }

  Future<void> init() async {
    if (memory || ownerKey.isEmpty) {
      _db = sqlite3.openInMemory();
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _db = sqlite3.open(p.join(dir.path, wheelStorageDbFileName(ownerKey)));
      } catch (_) {
        _db = sqlite3.openInMemory();
      }
    }
    db.execute('''
      CREATE TABLE IF NOT EXISTS lots (
        id TEXT PRIMARY KEY,
        received_at INTEGER NOT NULL,
        returned_at INTEGER,
        date_uncertain INTEGER NOT NULL DEFAULT 0,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        plate TEXT NOT NULL,
        vin TEXT NOT NULL,
        vehicle TEXT NOT NULL,
        size_primary TEXT NOT NULL,
        size_secondary TEXT NOT NULL,
        rim_diameter TEXT NOT NULL,
        tire_brand TEXT NOT NULL,
        season TEXT NOT NULL,
        with_rims INTEGER NOT NULL DEFAULT 0,
        cargo TEXT NOT NULL DEFAULT 'tires',
        sector INTEGER NOT NULL DEFAULT 0,
        rack_row INTEGER NOT NULL DEFAULT 0,
        wheel_count INTEGER NOT NULL DEFAULT 0,
        wheel_slots INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL,
        journal_no INTEGER NOT NULL DEFAULT 0,
        planned_days INTEGER NOT NULL DEFAULT 0,
        signature_png TEXT NOT NULL DEFAULT ''
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    _migrateLots();
    if (seedJournal) {
      _seedJournalIfNeeded();
    }
    _hydrateShopJournalIfNeeded();
    remapRackPlaces();
  }

  void _hydrateShopJournalIfNeeded() {
    if (!isShopJournalRecipient(ownerKey)) return;
    final flag = db.select(
      'SELECT value FROM settings WHERE key = ?',
      ['shop_journal_hydrated'],
    );
    final version = flag.isEmpty ? '' : flag.first['value'] as String;
    final hasJournal = db
        .select("SELECT 1 FROM lots WHERE id LIKE 'journal-%' LIMIT 1")
        .isNotEmpty;
    if (version == kShopJournalHydrateVersion && hasJournal) return;

    final source = _tryImportLiveMacLots() ?? shopJournalLots();
    for (final lot in source) {
      final exists = db.select('SELECT 1 FROM lots WHERE id = ?', [lot.id]);
      if (exists.isEmpty) upsert(lot);
    }
    if (pricePerDayGrosze() == 0) setPricePerDayGrosze(500);
    if (sectorCount() < 5) setSectorCount(5);
    db.execute(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      ['shop_journal_hydrated', kShopJournalHydrateVersion],
    );
  }

  List<WheelLot>? _tryImportLiveMacLots() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    final paths = [
      p.join(home, 'Documents', kStorageDbName),
      p.join(home, 'Library', 'Application Support', 'AutoShift', kStorageDbName),
    ];
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() == 0) continue;
      try {
        final src = sqlite3.open(path);
        try {
          final lots = src.select('SELECT * FROM lots').map(_fromRow).toList();
          if (lots.isNotEmpty) return lots;
        } finally {
          src.dispose();
        }
      } catch (_) {}
    }
    return null;
  }

  void _migrateLots() {
    const extras = {
      'cargo': "TEXT NOT NULL DEFAULT 'tires'",
      'sector': 'INTEGER NOT NULL DEFAULT 0',
      'rack_row': 'INTEGER NOT NULL DEFAULT 0',
      'wheel_count': 'INTEGER NOT NULL DEFAULT 0',
      'wheel_slots': 'INTEGER NOT NULL DEFAULT 0',
      'planned_days': 'INTEGER NOT NULL DEFAULT 0',
      'signature_png': "TEXT NOT NULL DEFAULT ''",
      'contract_version': "TEXT NOT NULL DEFAULT ''",
      'paid_grosze': 'INTEGER NOT NULL DEFAULT 0',
      'pay_status': "TEXT NOT NULL DEFAULT 'accruing'",
      'billing_from': 'INTEGER NOT NULL DEFAULT 0',
      'price_per_day_grosze': 'INTEGER',
    };
    for (final entry in extras.entries) {
      try {
        db.execute('ALTER TABLE lots ADD COLUMN ${entry.key} ${entry.value}');
      } catch (_) {}
    }
  }

  void _seedJournalIfNeeded() {
    final seeded = db.select(
      'SELECT value FROM settings WHERE key = ?',
      ['journal_seeded'],
    );
    final version = seeded.isEmpty ? '' : seeded.first['value'] as String;
    if (version == kJournalSeedVersion) return;
    final insert = db.prepare('''
      INSERT OR REPLACE INTO lots (
        id, received_at, returned_at, date_uncertain,
        first_name, last_name, phone, plate, vin, vehicle,
        size_primary, size_secondary, rim_diameter, tire_brand,
        season, with_rims, cargo, sector, rack_row, wheel_count, wheel_slots, notes, journal_no,
        planned_days, signature_png, contract_version,
        paid_grosze, pay_status, billing_from, price_per_day_grosze
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    try {
      for (final lot in journalStorageLots()) {
        insert.execute(_row(lot));
      }
    } finally {
      insert.dispose();
    }
    db.execute(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      ['journal_seeded', kJournalSeedVersion],
    );
    if (pricePerDayGrosze() == 0) {
      setPricePerDayGrosze(500);
    }
  }

  List<Object?> _row(WheelLot lot) {
    return [
      lot.id,
      lot.receivedAt?.millisecondsSinceEpoch ?? 0,
      lot.returnedAt?.millisecondsSinceEpoch,
      lot.dateUncertain || lot.receivedAt == null ? 1 : 0,
      lot.firstName,
      lot.lastName,
      lot.phone,
      lot.plate,
      lot.vin,
      lot.vehicle,
      lot.sizePrimary,
      lot.sizeSecondary,
      lot.rimDiameter,
      lot.tireBrand,
      lot.season.code,
      lot.withRims ? 1 : 0,
      lot.cargo.code,
      lot.sector,
      lot.rackRow,
      lot.wheelCount,
      lot.wheelSlots != 0 ? lot.wheelSlots : maskFromSlots(lot.slots),
      lot.notes,
      lot.journalNo,
      lot.plannedDays,
      lot.signaturePng,
      lot.contractVersion,
      lot.paidGrosze,
      lot.payStatus.code,
      lot.billingFrom?.millisecondsSinceEpoch ?? 0,
      lot.pricePerDayGrosze,
    ];
  }

  WheelLot _fromRow(Row row) {
    final returned = row['returned_at'] as int?;
    final receivedMs = row['received_at'] as int;
    return WheelLot(
      id: row['id'] as String,
      receivedAt: receivedMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(receivedMs),
      returnedAt: returned == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(returned),
      dateUncertain: (row['date_uncertain'] as int) == 1,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      phone: row['phone'] as String,
      plate: row['plate'] as String,
      vin: row['vin'] as String,
      vehicle: row['vehicle'] as String,
      sizePrimary: row['size_primary'] as String,
      sizeSecondary: row['size_secondary'] as String,
      rimDiameter: row['rim_diameter'] as String,
      tireBrand: row['tire_brand'] as String,
      season: TireSeasonX.fromCode(row['season'] as String?),
      cargo: _cargoFromRow(row),
      sector: _intCol(row, 'sector'),
      rackRow: _intCol(row, 'rack_row'),
      wheelCount: _intCol(row, 'wheel_count'),
      wheelSlots: _intCol(row, 'wheel_slots'),
      notes: row['notes'] as String,
      journalNo: row['journal_no'] as int,
      plannedDays: _intCol(row, 'planned_days'),
      signaturePng: _strCol(row, 'signature_png'),
      contractVersion: _strCol(row, 'contract_version'),
      paidGrosze: _intCol(row, 'paid_grosze'),
      payStatus: StoragePayStatusX.fromCode(_strCol(row, 'pay_status')),
      billingFrom: () {
        final ms = _intCol(row, 'billing_from');
        return ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      }(),
      pricePerDayGrosze: _nullableIntCol(row, 'price_per_day_grosze'),
    );
  }

  String _strCol(Row row, String key) {
    try {
      return (row[key] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  StorageCargo _cargoFromRow(Row row) {
    try {
      final code = row['cargo'] as String?;
      if (code != null && code.isNotEmpty) {
        return StorageCargoX.fromCode(code);
      }
    } catch (_) {}
    return StorageCargoX.fromLegacy(withRims: (row['with_rims'] as int) == 1);
  }

  int? _nullableIntCol(Row row, String key) {
    try {
      final value = row[key];
      if (value == null) return null;
      if (value is int) return value < 0 ? 0 : value;
      if (value is num) return value.toInt() < 0 ? 0 : value.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  int _intCol(Row row, String key) {
    try {
      return (row[key] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  List<WheelLot> loadLots() {
    return db
        .select('SELECT * FROM lots ORDER BY received_at DESC, journal_no ASC')
        .map(_fromRow)
        .toList();
  }

  void upsert(WheelLot lot) {
    db.execute(
      '''
      INSERT OR REPLACE INTO lots (
        id, received_at, returned_at, date_uncertain,
        first_name, last_name, phone, plate, vin, vehicle,
        size_primary, size_secondary, rim_diameter, tire_brand,
        season, with_rims, cargo, sector, rack_row, wheel_count, wheel_slots, notes, journal_no,
        planned_days, signature_png, contract_version,
        paid_grosze, pay_status, billing_from, price_per_day_grosze
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      _row(lot),
    );
  }

  void delete(String id) {
    db.execute('DELETE FROM lots WHERE id = ?', [id]);
  }

  /// Folds legacy 6-cell places onto the 3×8 stand. Journal rows stay.
  bool remapRackPlaces() {
    final current = loadLots();
    final next = fitLotsOntoRack(current);
    var changed = false;
    for (var i = 0; i < current.length && i < next.length; i++) {
      final prev = current[i];
      final lot = next[i];
      if (prev.id != lot.id) continue;
      if (prev.sector == lot.sector &&
          prev.rackRow == lot.rackRow &&
          prev.wheelCount == lot.wheelCount &&
          prev.wheelSlots == lot.wheelSlots) {
        continue;
      }
      upsert(lot);
      changed = true;
    }
    return changed;
  }

  int pricePerDayGrosze() {
    final rows = db.select(
      'SELECT value FROM settings WHERE key = ?',
      ['price_per_day_grosze'],
    );
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['value'] as String) ?? 0;
  }

  void setPricePerDayGrosze(int value) {
    db.execute(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      ['price_per_day_grosze', '$value'],
    );
  }

  int sectorCount() {
    final rows = db.select(
      'SELECT value FROM settings WHERE key = ?',
      ['sector_count'],
    );
    if (rows.isEmpty) return kDefaultSectors;
    return clampSectorCount(int.tryParse(rows.first['value'] as String));
  }

  void setSectorCount(int value) {
    final n = clampSectorCount(value);
    db.execute(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      ['sector_count', '$n'],
    );
  }

  StorageLotsPayload exportRemoteState() {
    return StorageLotsPayload(
      lots: loadLots(),
      pricePerDayGrosze: pricePerDayGrosze(),
      sectorCount: sectorCount(),
    );
  }

  void applyRemoteState(StorageLotsPayload payload) {
    db.execute('DELETE FROM lots');
    for (final lot in payload.lots) {
      if (lot.id.isEmpty) continue;
      upsert(lot);
    }
    setPricePerDayGrosze(payload.pricePerDayGrosze);
    setSectorCount(payload.sectorCount);
    if (isShopJournalRecipient(ownerKey)) {
      _hydrateShopJournalIfNeeded();
    }
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }
}
