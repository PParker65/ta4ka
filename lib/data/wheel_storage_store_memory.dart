import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/wheel_storage.dart';
import 'storage_cloud_api.dart';
import 'wheel_storage_owner.dart';
import 'wheel_storage_seed.dart';

export 'wheel_storage_owner.dart';

class WheelStorageStore {
  WheelStorageStore({
    this.memory = true,
    String ownerKey = '',
    bool? seedJournal,
  })  : ownerKey = normalizeStorageOwner(ownerKey),
        seedJournal = seedJournal ?? isStaffStorageOwner(ownerKey);

  final bool memory;
  final String ownerKey;
  final bool seedJournal;
  final _lots = <String, WheelLot>{};
  var _pricePerDayGrosze = 0;
  var _sectorCount = kDefaultSectors;
  var _shopJournalHydrated = '';
  var _ready = false;

  bool get _persistable => !memory && ownerKey.isNotEmpty;

  String get _prefsKey => wheelStoragePrefsKeyFor(ownerKey);

  Future<void> init() async {
    if (_ready) return;
    if (_persistable) {
      final restored = await _restore();
      if (restored) {
        final hydrated = _hydrateShopJournalIfNeeded();
        final moved = remapRackPlaces();
        if (hydrated && !moved) await _persist();
        _ready = true;
        return;
      }
    }
    if (seedJournal) {
      for (final lot in journalStorageLots()) {
        _lots[lot.id] = lot;
      }
      _pricePerDayGrosze = 500;
    }
    _hydrateShopJournalIfNeeded();
    remapRackPlaces();
    _ready = true;
    await _persist();
  }

  bool _hydrateShopJournalIfNeeded() {
    if (!isShopJournalRecipient(ownerKey)) return false;
    final hasJournal = _lots.values.any((lot) => lot.id.startsWith('journal-'));
    if (_shopJournalHydrated == kShopJournalHydrateVersion && hasJournal) {
      return false;
    }
    var changed = false;
    for (final lot in shopJournalLots()) {
      if (_lots.containsKey(lot.id)) continue;
      _lots[lot.id] = lot;
      changed = true;
    }
    if (_pricePerDayGrosze == 0) {
      _pricePerDayGrosze = 500;
      changed = true;
    }
    if (_sectorCount < 5) {
      _sectorCount = 5;
      changed = true;
    }
    if (_shopJournalHydrated != kShopJournalHydrateVersion) {
      _shopJournalHydrated = kShopJournalHydrateVersion;
      changed = true;
    }
    return changed;
  }

  Future<bool> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return false;
      final map = jsonDecode(raw);
      if (map is! Map) return false;
      final lots = map['lots'];
      if (lots is! List) return false;
      _lots.clear();
      for (final item in lots) {
        if (item is! Map) continue;
        final lot = WheelLot.fromJson(Map<String, dynamic>.from(item));
        if (lot.id.isEmpty) continue;
        _lots[lot.id] = lot;
      }
      _pricePerDayGrosze = (map['pricePerDayGrosze'] as num?)?.toInt() ?? 0;
      _sectorCount = clampSectorCount((map['sectorCount'] as num?)?.toInt());
      _shopJournalHydrated = map['shopJournalHydrated'] as String? ?? '';
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    if (!_persistable) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'owner': ownerKey,
          'lots': _lots.values.map((lot) => lot.toJson()).toList(),
          'pricePerDayGrosze': _pricePerDayGrosze,
          'sectorCount': _sectorCount,
          'shopJournalHydrated': _shopJournalHydrated,
        }),
      );
    } catch (_) {}
  }

  List<WheelLot> loadLots() {
    final lots = _lots.values.toList()..sort(compareLotsByIntake);
    return lots;
  }

  void upsert(WheelLot lot) {
    _lots[lot.id] = lot;
    _persist();
  }

  void delete(String id) {
    _lots.remove(id);
    _persist();
  }

  /// Folds legacy 6-cell places onto the 3×8 stand. Journal rows stay.
  bool remapRackPlaces() {
    final next = fitLotsOntoRack(_lots.values);
    var changed = false;
    for (final lot in next) {
      final prev = _lots[lot.id];
      if (prev == null) continue;
      if (prev.sector == lot.sector &&
          prev.rackRow == lot.rackRow &&
          prev.wheelCount == lot.wheelCount &&
          prev.wheelSlots == lot.wheelSlots) {
        continue;
      }
      _lots[lot.id] = lot;
      changed = true;
    }
    if (changed) _persist();
    return changed;
  }

  int pricePerDayGrosze() => _pricePerDayGrosze;

  void setPricePerDayGrosze(int value) {
    _pricePerDayGrosze = value < 0 ? 0 : value;
    _persist();
  }

  int sectorCount() => _sectorCount;

  void setSectorCount(int value) {
    _sectorCount = clampSectorCount(value);
    _persist();
  }

  StorageLotsPayload exportRemoteState() {
    return StorageLotsPayload(
      lots: loadLots(),
      pricePerDayGrosze: _pricePerDayGrosze,
      sectorCount: _sectorCount,
      shopJournalHydrated: _shopJournalHydrated,
    );
  }

  void applyRemoteState(StorageLotsPayload payload) {
    _lots
      ..clear()
      ..addEntries(payload.lots.where((lot) => lot.id.isNotEmpty).map(
            (lot) => MapEntry(lot.id, lot),
          ));
    _pricePerDayGrosze = payload.pricePerDayGrosze;
    _sectorCount = clampSectorCount(payload.sectorCount);
    _shopJournalHydrated = payload.shopJournalHydrated;
    if (isShopJournalRecipient(ownerKey) &&
        !_lots.values.any((lot) => lot.id.startsWith('journal-'))) {
      _hydrateShopJournalIfNeeded();
    }
    _persist();
  }

  void dispose() {
    _lots.clear();
  }
}
