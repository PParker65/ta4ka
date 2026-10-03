import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/storage_cloud_api.dart';
import '../data/wheel_storage_store.dart';
import '../domain/models/wheel_storage.dart';
import 'providers.dart';

enum RemoveSectorResult { removed, occupied, minReached }

class WheelStorageState {
  const WheelStorageState({
    this.loading = true,
    this.lots = const [],
    this.pricePerDayGrosze = 0,
    this.sectorCount = kDefaultSectors,
    this.error,
  });

  final bool loading;
  final List<WheelLot> lots;
  final int pricePerDayGrosze;
  final int sectorCount;
  final String? error;

  WheelStorageState copyWith({
    bool? loading,
    List<WheelLot>? lots,
    int? pricePerDayGrosze,
    int? sectorCount,
    String? error,
    bool clearError = false,
  }) {
    return WheelStorageState(
      loading: loading ?? this.loading,
      lots: lots ?? this.lots,
      pricePerDayGrosze: pricePerDayGrosze ?? this.pricePerDayGrosze,
      sectorCount: sectorCount ?? this.sectorCount,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WheelStorageController extends StateNotifier<WheelStorageState> {
  WheelStorageController({
    String ownerLogin = '',
    String token = '',
    WheelStorageStore? store,
  })  : _owned = store == null,
        _token = token.trim(),
        _store = store ??
            WheelStorageStore(
              memory: ownerLogin.trim().isEmpty,
              ownerKey: ownerLogin,
              seedJournal: isStaffStorageOwner(ownerLogin),
            ),
        super(const WheelStorageState()) {
    _boot();
  }

  final bool _owned;
  final String _token;
  final WheelStorageStore _store;
  Timer? _pushTimer;

  Future<void> _boot() async {
    try {
      await _store.init();
      var persistSectors = false;
      var placesChanged = false;
      if (_token.isNotEmpty) {
        try {
          final remote = await StorageCloudApi.instance.loadLots(_token);
          persistSectors = remote.sectorCount < kDefaultSectors;
          _store.applyRemoteState(remote);
        } catch (error, stack) {
          debugPrint('Wheel storage cloud load failed: $error\n$stack');
        }
        placesChanged = _store.remapRackPlaces();
      }
      if (_store.sectorCount() < kDefaultSectors) {
        _store.setSectorCount(kDefaultSectors);
        persistSectors = _token.isNotEmpty;
      }
      _reload();
      if (persistSectors || placesChanged) _schedulePush();
      if (_token.isNotEmpty &&
          isShopJournalRecipient(_store.ownerKey) &&
          _store.loadLots().isNotEmpty) {
        _schedulePush();
      }
    } catch (error, stack) {
      debugPrint('Wheel storage init failed: $error\n$stack');
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  void _reload() {
    state = WheelStorageState(
      loading: false,
      lots: _store.loadLots(),
      pricePerDayGrosze: _store.pricePerDayGrosze(),
      sectorCount: _store.sectorCount(),
    );
  }

  void _schedulePush() {
    if (_token.isEmpty) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_push());
    });
  }

  Future<void> _push() async {
    if (_token.isEmpty) return;
    try {
      await StorageCloudApi.instance.saveLots(_token, _store.exportRemoteState());
    } catch (error) {
      debugPrint('Wheel storage cloud save failed: $error');
    }
  }

  void save(WheelLot lot) {
    _store.upsert(lot);
    _reload();
    _schedulePush();
  }

  void deleteLot(String id) {
    _store.delete(id);
    _reload();
    _schedulePush();
  }

  WheelLot checkout(WheelLot lot, {DateTime? at}) {
    final closed = lot.copyWith(returnedAt: at ?? DateTime.now());
    _store.upsert(closed);
    _reload();
    _schedulePush();
    return closed;
  }

  void setPricePerDayGrosze(int value) {
    _store.setPricePerDayGrosze(value < 0 ? 0 : value);
    _reload();
    _schedulePush();
  }

  void addSector() {
    _store.setSectorCount(state.sectorCount + 1);
    _reload();
    _schedulePush();
  }

  /// Drops only the highest sector index, and only if it has no active lots.
  RemoveSectorResult removeSector() {
    final last = state.sectorCount;
    if (last <= kDefaultSectors) return RemoveSectorResult.minReached;
    if (sectorHasActiveLots(state.lots, last)) {
      return RemoveSectorResult.occupied;
    }
    _store.setSectorCount(last - 1);
    _reload();
    _schedulePush();
    return RemoveSectorResult.removed;
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    if (_owned) {
      _store.dispose();
    }
    super.dispose();
  }
}

final wheelStorageProvider =
    StateNotifierProvider<WheelStorageController, WheelStorageState>((ref) {
  final session = ref.watch(authProvider);
  return WheelStorageController(
    ownerLogin: session?.login ?? '',
    token: session?.token ?? '',
  );
});
