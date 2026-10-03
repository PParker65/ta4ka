import 'package:autoservice/app/storage_providers.dart';
import 'package:autoservice/core/l10n/app_lang.dart';
import 'package:autoservice/data/storage_cloud_api.dart';
import 'package:autoservice/data/wheel_storage_seed.dart';
import 'package:autoservice/data/wheel_storage_store.dart';
import 'package:autoservice/domain/models/wheel_storage.dart';
import 'package:autoservice/presentation/storage/storage_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('journal seed has 29 lots and undated rows have no bill', () {
    final lots = journalStorageLots();
    expect(lots, hasLength(29));
    expect(lots.every((lot) => lot.isActive), isTrue);
    final dated = lots.where((lot) => lot.hasIntakeDate).toList();
    final undated = lots.where((lot) => !lot.hasIntakeDate).toList();
    expect(dated, hasLength(20));
    expect(undated, hasLength(9));
    expect(dated.every((lot) => lot.receivedAt!.year == 2026), isTrue);
    expect(
      storageDays(dated.first.receivedAt!, DateTime(2026, 8, 31)),
      178,
    );
    expect(
      storageBillGrosze(
        receivedAt: null,
        until: DateTime(2026, 8, 31),
        pricePerDayGrosze: 500,
      ),
      0,
    );
  });

  test('storage days follow the computer calendar', () {
    final received = DateTime(2026, 3, 6, 10);
    expect(storageDays(received, DateTime(2026, 3, 6, 18)), 0);
    expect(storageDays(received, DateTime(2026, 3, 7, 9)), 1);
    expect(storageDays(received, DateTime(2026, 8, 31)), 178);
    expect(billedStorageDays(received, DateTime(2026, 3, 6)), 1);
  });

  test('bill is days times the per-day rate', () {
    final received = DateTime(2026, 8, 1);
    expect(
      storageBillGrosze(
        receivedAt: received,
        until: DateTime(2026, 8, 31),
        pricePerDayGrosze: 500,
      ),
      15000,
    );
    expect(formatZloty(15000), '150,00 zł');
    expect(parseZlotyToGrosze('5,00'), 500);
  });

  test('search uses any filled field and ignores empty ones', () {
    final lots = journalStorageLots();
    final byPlate = filterLots(
      lots,
      search: const StorageSearch(plate: 'aa8844'),
      activeOnly: true,
    );
    expect(byPlate, hasLength(1));
    expect(byPlate.first.vehicle, contains('W222'));

    final byPhone = filterLots(
      lots,
      search: const StorageSearch(phone: '576071'),
      activeOnly: true,
    );
    expect(byPhone.single.plate, 'KA 2842 PB');

    final byName = filterLots(
      lots,
      search: const StorageSearch(firstName: 'алексей'),
      activeOnly: true,
    );
    expect(byName.single.plate, 'HH 3340 AH');

    final miss = filterLots(
      lots,
      search: const StorageSearch(plate: 'aa8844', phone: '000'),
      activeOnly: true,
    );
    expect(miss, isEmpty);
  });

  test('rack occupancy is per height slot, not the whole cell', () {
    final lower = const WheelLot(
      id: 'a',
      plate: 'AA 8844 OX',
      cargo: StorageCargo.tires,
      sector: 1,
      rackRow: 1,
      wheelCount: 4,
      wheelSlots: 15,
    );
    final upper = const WheelLot(
      id: 'b',
      plate: 'NY-6842',
      cargo: StorageCargo.tiresOnRims,
      sector: 1,
      rackRow: 1,
      wheelCount: 2,
      wheelSlots: 192,
    );
    expect(slotsFromMask(15), {1, 2, 3, 4});
    expect(slotsFromMask(192), {7, 8});
    expect(maskFromSlots({7, 8}), 192);
    expect(lotInSlot([lower], 1, 1, 4)?.id, 'a');
    expect(lotInSlot([lower], 1, 1, 7), isNull);
    expect(takenSlots([lower], 1, 1), {1, 2, 3, 4});
    expect(lotInSlot([lower, upper], 1, 1, 7)?.id, 'b');
    expect(takenSlots([lower, upper], 1, 1), {1, 2, 3, 4, 7, 8});
    expect(rackMarker(3, 1), '3-1');
    expect(kDefaultSectors * kRackCells, 9);
    expect(kRackCells, 3);
    expect(kWheelsPerCell, 8);
    expect(
      const WheelLot(id: 'c', sector: 1, rackRow: 1, wheelCount: 4).shownWheels,
      4,
    );
    expect(
      const WheelLot(id: 'c', sector: 1, rackRow: 1, wheelCount: 4).slots,
      {1, 2, 3, 4},
    );
    final handed = lower.copyWith(returnedAt: DateTime(2026, 8, 31));
    expect(lotInSlot([handed], 1, 1, 1), isNull);
  });

  test('planned days and signature persist in sqlite', () async {
    final store = WheelStorageStore(memory: true);
    await store.init();
    addTearDown(store.dispose);
    const lot = WheelLot(
      id: 'signed-1',
      plate: 'WW 1000',
      firstName: 'Jan',
      plannedDays: 180,
      signaturePng: 'c2lnbg==',
      sector: 1,
      rackRow: 2,
      wheelCount: 4,
      wheelSlots: 15,
      receivedAt: null,
    );
    store.upsert(lot.copyWith(receivedAt: DateTime(2026, 10, 1)));
    final loaded = store.loadLots().firstWhere((item) => item.id == 'signed-1');
    expect(loaded.plannedDays, 180);
    expect(loaded.hasSignature, isTrue);
    expect(loaded.signaturePng, 'c2lnbg==');
    expect(loaded.hasPlannedPeriod, isTrue);
  });

  test('sqlite memory store can grow sector count', () async {
    final store = WheelStorageStore(memory: true);
    await store.init();
    addTearDown(store.dispose);
    expect(store.sectorCount(), kDefaultSectors);
    store.setSectorCount(4);
    expect(store.sectorCount(), 4);
  });

  test('removeSector drops only an empty last sector', () async {
    final store = WheelStorageStore(memory: true);
    final ctrl = WheelStorageController(store: store);
    addTearDown(ctrl.dispose);
    addTearDown(store.dispose);
    for (var i = 0; i < 40 && ctrl.state.loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    expect(ctrl.state.loading, isFalse);
    ctrl.addSector();
    expect(ctrl.state.sectorCount, kDefaultSectors + 1);
    ctrl.save(
      const WheelLot(
        id: 'in-last',
        sector: kDefaultSectors + 1,
        rackRow: 1,
        wheelCount: 2,
        wheelSlots: 3,
      ),
    );
    expect(sectorHasActiveLots(ctrl.state.lots, kDefaultSectors + 1), isTrue);
    expect(ctrl.removeSector(), RemoveSectorResult.occupied);
    expect(ctrl.state.sectorCount, kDefaultSectors + 1);

    ctrl.checkout(ctrl.state.lots.first, at: DateTime(2026, 10, 2));
    expect(sectorHasActiveLots(ctrl.state.lots, kDefaultSectors + 1), isFalse);
    expect(ctrl.removeSector(), RemoveSectorResult.removed);
    expect(ctrl.state.sectorCount, kDefaultSectors);
  });

  test('add/remove sector labels', () {
    final ru = StorageL10n(AppLang.ru);
    expect(ru.addSector, 'Добавить сектор');
    expect(ru.removeSector, 'Убрать сектор');
    expect(ru.deleteLot, 'Удалить');
    expect(ru.editPrice, 'Редактировать цену');
    expect(StorageL10n(AppLang.uk).editPrice, 'Редагувати ціну');
    expect(StorageL10n(AppLang.en).editPrice, 'Edit price');
    expect(StorageL10n(AppLang.pl).editPrice, 'Edytuj cenę');
    expect(ru.personalPrice, 'Личная цена');
    expect(ru.confirmDeleteLot, contains('списка'));
    expect(StorageL10n(AppLang.uk).deleteLot, 'Видалити');
    expect(StorageL10n(AppLang.en).deleteLot, 'Delete');
    expect(StorageL10n(AppLang.pl).deleteLot, 'Usuń');
    expect(ru.sectorOccupiedHint(4), contains('секторе 4'));
  });

  test('legacy 6-cell places fold onto 3 rows without dropping the journal', () {
    final journal = shopJournalLots();
    expect(journal, hasLength(31));
    final legacy = const WheelLot(
      id: 'legacy-high',
      plate: 'OLD 6',
      sector: 1,
      rackRow: 6,
      wheelCount: 2,
      wheelSlots: 3,
    );
    final blocking = const WheelLot(
      id: 'already',
      plate: 'ROW 3',
      sector: 1,
      rackRow: 3,
      wheelCount: 2,
      wheelSlots: 3,
    );
    final fitted = fitLotsOntoRack([...journal, legacy, blocking]);
    expect(fitted, hasLength(33));
    expect(fitted.where((lot) => lot.id.startsWith('journal-')), hasLength(29));
    expect(fitted.firstWhere((lot) => lot.id == 'journal-01').sector, 0);
    final moved = fitted.firstWhere((lot) => lot.id == 'legacy-high');
    expect(moved.rackRow, isNot(6));
    expect(moved.rackRow, inInclusiveRange(1, kRackCells));
    expect(lotInSlot(fitted, moved.sector, moved.rackRow, 1)?.id, 'legacy-high');
    expect(lotInSlot(fitted, 1, 3, 1)?.id, 'already');
    expect(fitted.firstWhere((lot) => lot.id == 'lot-1788262431872').rackRow, lessThanOrEqualTo(kRackCells));
  });

  test('deleteLot removes the customer and frees the wheels', () async {
    final store = WheelStorageStore(memory: true);
    final ctrl = WheelStorageController(store: store);
    addTearDown(ctrl.dispose);
    addTearDown(store.dispose);
    for (var i = 0; i < 40 && ctrl.state.loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    ctrl.save(
      const WheelLot(
        id: 'gone',
        plate: 'XX 1000',
        sector: 1,
        rackRow: 2,
        wheelCount: 4,
        wheelSlots: 15,
      ),
    );
    expect(lotInSlot(ctrl.state.lots, 1, 2, 1)?.id, 'gone');
    ctrl.deleteLot('gone');
    expect(ctrl.state.lots.any((lot) => lot.id == 'gone'), isFalse);
    expect(lotInSlot(ctrl.state.lots, 1, 2, 1), isNull);
    expect(store.loadLots().any((lot) => lot.id == 'gone'), isFalse);
  });

  test('sectorCount never drops below kDefaultSectors', () async {
    final store = WheelStorageStore(memory: true, ownerKey: 'new@kolesasave.com');
    await store.init();
    addTearDown(store.dispose);
    expect(store.sectorCount(), kDefaultSectors);
    store.applyRemoteState(const StorageLotsPayload(sectorCount: 0));
    expect(store.sectorCount(), kDefaultSectors);
    store.setSectorCount(1);
    expect(store.sectorCount(), kDefaultSectors);
    store.setSectorCount(5);
    expect(store.sectorCount(), 5);
    expect(clampSectorCount(0), kDefaultSectors);
    expect(clampSectorCount(null), kDefaultSectors);
  });

  test('registered owner starts empty and stays isolated from another email', () async {
    final alice = WheelStorageStore(memory: true, ownerKey: 'alice@kolesasave.com');
    final bob = WheelStorageStore(memory: true, ownerKey: 'bob@kolesasave.com');
    await alice.init();
    await bob.init();
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    expect(alice.loadLots(), isEmpty);
    expect(bob.loadLots(), isEmpty);

    alice.upsert(
      const WheelLot(id: 'only-alice', plate: 'WW 1111', firstName: 'Ala'),
    );
    expect(alice.loadLots(), hasLength(1));
    expect(alice.loadLots().single.id, 'only-alice');
    expect(bob.loadLots(), isEmpty);
  });

  test('staff owner seeds the 29-lot shop journal', () async {
    final store = WheelStorageStore(memory: true, ownerKey: 'admin');
    await store.init();
    addTearDown(store.dispose);
    expect(store.loadLots(), hasLength(29));
    expect(store.pricePerDayGrosze(), 500);
  });

  test('irinaogiyko gets the AutoShift journal; other emails stay empty', () async {
    expect(shopJournalLots(), hasLength(31));
    final irina = WheelStorageStore(memory: true, ownerKey: 'IrinaOgiyko@gmail.com');
    final other = WheelStorageStore(memory: true, ownerKey: 'new@shop.com');
    await irina.init();
    await other.init();
    addTearDown(irina.dispose);
    addTearDown(other.dispose);
    expect(irina.loadLots(), hasLength(31));
    expect(irina.loadLots().any((lot) => lot.id == 'journal-01'), isTrue);
    expect(irina.loadLots().any((lot) => lot.id == 'lot-1788262431872'), isTrue);
    expect(other.loadLots(), isEmpty);
    expect(isShopJournalRecipient(' irinaogiyko@gmail.com '), isTrue);
    expect(isShopJournalRecipient('admin'), isFalse);
  });

  test('storage contract has seven numbered clauses', () {
    final l10n = StorageL10n(AppLang.ru);
    final clauses = l10n.contractClauses(
      keeper: 'AutoShift Warszawa',
      client: 'Jan Kowalski',
      plate: 'WW 1000',
      vehicle: 'BMW',
      period: l10n.months6,
      dailyFee: '5,00 zł',
      until: '01.04.2027',
      billedDays: 180,
      periodTotal: '900,00 zł',
    );
    expect(clauses, hasLength(7));
    expect(clauses.first.title, contains('1.'));
    expect(clauses[2].body, contains('900,00 zł'));
    expect(clauses[2].body, contains('фактическим'));
    expect(clauses[4].body, contains('14'));
    expect(clauses[5].body, contains('1000'));
  });

  test('preset days survive empty custom field', () {
    expect(resolvePlannedDays(selected: 90, customText: ''), 90);
    expect(resolvePlannedDays(selected: 90, customText: '  '), 90);
    expect(resolvePlannedDays(selected: 90, customText: '0'), 90);
    expect(resolvePlannedDays(selected: 30, customText: '14'), 14);
    expect(resolvePlannedDays(selected: 0, customText: ''), 0);
  });

  test('paid / partial / extend change the lot bill', () {
    final lot = WheelLot(
      id: 'pay-1',
      receivedAt: DateTime(2026, 9, 1),
      plannedDays: 90,
    );
    const price = 500;
    expect(lotBilledDays(lot, DateTime(2026, 9, 10)), 9);
    expect(
      lotDueGrosze(lot: lot, until: DateTime(2026, 9, 10), pricePerDayGrosze: price),
      4500,
    );
    final partial = lotMarkPartial(lot, 1000);
    expect(partial.payStatus, StoragePayStatus.partial);
    expect(
      lotDueGrosze(lot: partial, until: DateTime(2026, 9, 10), pricePerDayGrosze: price),
      3500,
    );
    final paid = lotMarkPaid(lot, DateTime(2026, 9, 10));
    expect(paid.payStatus, StoragePayStatus.paid);
    expect(
      lotDueGrosze(lot: paid, until: DateTime(2026, 9, 10), pricePerDayGrosze: price),
      0,
    );
    expect(lotExtendByDays(lot, 30).plannedDays, 120);
    final personal = lot.copyWith(pricePerDayGrosze: 800, setPricePerDay: true);
    expect(effectiveDailyGrosze(personal, price), 800);
    expect(
      lotDueGrosze(lot: personal, until: DateTime(2026, 9, 10), pricePerDayGrosze: price),
      7200,
    );
    expect(lotExtendByDays(personal, 30).pricePerDayGrosze, 800);
    final restored = WheelLot.fromJson(personal.toJson());
    expect(restored.pricePerDayGrosze, 800);
    expect(WheelLot.fromJson(lot.toJson()).pricePerDayGrosze, isNull);
    expect(lot.toJson().containsKey('pricePerDayGrosze'), isFalse);
  });

  test('ukrainian storage strings are not leftover russian', () {
    final uk = StorageL10n(AppLang.uk);
    expect(uk.accept, 'Прийняти на зберігання');
    expect(uk.search, 'Пошук');
    expect(uk.extendStorage, 'Продовжити зберігання');
    expect(uk.title, isNot(contains('Хранение')));
    expect(uk.needPeriod, contains('строк'));
  });

  test('prefs keys keep staff journal off registered emails', () {
    expect(wheelStoragePrefsKeyFor('admin'), kWheelStoragePrefsKey);
    expect(wheelStoragePrefsKeyFor('Admin'), kWheelStoragePrefsKey);
    expect(
      wheelStoragePrefsKeyFor('new@shop.com'),
      isNot(kWheelStoragePrefsKey),
    );
    expect(
      wheelStoragePrefsKeyFor('a@x.com'),
      isNot(wheelStoragePrefsKeyFor('b@x.com')),
    );
  });

  test('sqlite memory store seeds the journal once and archives on checkout', () async {
    final store = WheelStorageStore(memory: true, seedJournal: true);
    await store.init();
    addTearDown(store.dispose);

    final lots = store.loadLots();
    expect(lots, hasLength(29));
    expect(store.pricePerDayGrosze(), 500);
    expect(lots.every((lot) => lot.pricePerDayGrosze == null), isTrue);

    final first = lots.firstWhere((lot) => lot.plate == 'AA 8844 OX');
    store.upsert(first.copyWith(returnedAt: DateTime(2026, 8, 31)));
    final active = store.loadLots().where((lot) => lot.isActive).toList();
    expect(active, hasLength(28));
    expect(active.any((lot) => lot.plate == 'AA 8844 OX'), isFalse);
  });

  test('saved personal daily price ignores later shop price changes', () async {
    final store = WheelStorageStore(memory: true, seedJournal: false);
    await store.init();
    addTearDown(store.dispose);
    store.setPricePerDayGrosze(500);
    final lot = WheelLot(
      id: 'custom-price',
      receivedAt: DateTime(2026, 9, 1),
      plate: 'WX 1',
      firstName: 'Ada',
    );
    store.upsert(lot);
    expect(store.loadLots().single.pricePerDayGrosze, isNull);
    expect(
      lotDueGrosze(
        lot: store.loadLots().single,
        until: DateTime(2026, 9, 10),
        pricePerDayGrosze: store.pricePerDayGrosze(),
      ),
      4500,
    );
    store.upsert(lot.copyWith(pricePerDayGrosze: 750, setPricePerDay: true));
    store.setPricePerDayGrosze(900);
    final saved = store.loadLots().single;
    expect(store.pricePerDayGrosze(), 900);
    expect(saved.pricePerDayGrosze, 750);
    expect(
      lotDueGrosze(
        lot: saved,
        until: DateTime(2026, 9, 10),
        pricePerDayGrosze: store.pricePerDayGrosze(),
      ),
      6750,
    );
    final payload = store.exportRemoteState();
    expect(payload.toJson()['lots'][0]['pricePerDayGrosze'], 750);
    final roundTrip = StorageLotsPayload.fromJson(payload.toJson());
    expect(roundTrip.lots.single.pricePerDayGrosze, 750);
    expect(roundTrip.pricePerDayGrosze, 900);
  });
}
