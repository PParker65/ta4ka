import 'package:autoservice/data/booking_extras.dart';
import 'package:autoservice/data/auto_spheres.dart';
import 'package:autoservice/data/catalog_seed.dart';
import 'package:autoservice/data/service_report.dart';
import 'package:autoservice/data/shop_seed.dart';
import 'package:autoservice/domain/models/crm_models.dart';
import 'package:autoservice/domain/models/shop_models.dart';
import 'package:autoservice/presentation/client/booking_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 17, 8, 0);

  test('catalog has Ta4ka Warsaw shops and filters by category name', () {
    final warsaw = filterShops(
      cityId: 'warsaw',
      query: '',
      sort: ShopSort.rating,
      now: now,
      taken: {},
    );
    expect(warsaw.length, greaterThanOrEqualTo(3));
    expect(warsaw.any((shop) => shop.name.en.startsWith('Ta4ka Warsaw')), isTrue);
    expect(shopById('net-warsaw-0'), isNotNull);
    expect(warsaw.any((shop) => shop.id == 'pitlane'), isTrue);
    expect(shopById('pitlane')!.name.uk, contains('кодинг'));
    expect(shopById('bodyline')!.name.uk, contains('малярка'));

    final engine = filterShops(
      cityId: 'warsaw',
      query: 'грм',
      sort: ShopSort.distance,
      now: now,
      taken: {},
    );
    expect(engine, hasLength(1));
    expect(engine.first.id, 'torque-lviv');
  });

  test('pitlane keeps 14:00 open and nordlift has morning slots', () {
    final pitlane = shopById('pitlane')!;
    final slots = buildShopSlots(shop: pitlane, now: now, taken: {});
    final fourteen = slots.where(
      (slot) => slot.start.hour == 14 && slot.start.minute == 0 && slot.open,
    );
    expect(fourteen, isNotEmpty);

    final nord = shopById('nordlift')!;
    expect(openSlotsToday(nord, now, {}), greaterThan(0));
    final nordTimes = openTimesToday(nord, now, {});
    expect(nordTimes, isNotEmpty);
    expect(nordTimes.first.hour, 9);

    final late = DateTime(2026, 8, 17, 17, 50);
    expect(openTimesToday(nord, late, {}), isEmpty);
  });

  test('category filter shows specialists and matching prices only', () {
    for (final shop in seededShops) {
      for (final id in shop.workIds) {
        expect(catalogWorks.any((work) => work.id == id), isTrue, reason: '${shop.id} -> $id');
      }
    }

    final paint = sphereById('paint')!;
    final paintShops = filterShops(
      cityId: 'warsaw',
      query: '',
      sort: ShopSort.rating,
      now: now,
      taken: {},
      sphereWorkIds: paint.workIds.toSet(),
    );
    expect(paintShops, isNotEmpty);
    expect(paintShops.every((shop) => shop.workIds.any(paint.workIds.contains)), isTrue);
    for (final shop in paintShops) {
      final works = worksFor(shop, sphereWorkIds: paint.workIds.toSet());
      expect(works, isNotEmpty);
      expect(works.any((work) => work.id == 'oil' || work.id == 'tuning'), isFalse);
    }

    final wash = sphereById('wash')!;
    final washShops = filterShops(
      cityId: 'warsaw',
      query: '',
      sort: ShopSort.rating,
      now: now,
      taken: {},
      sphereWorkIds: wash.workIds.toSet(),
    );
    expect(washShops.map((shop) => shop.id), contains('foam-lab'));
    for (final shop in washShops) {
      final works = worksFor(shop, sphereWorkIds: wash.workIds.toSet());
      expect(works.any((work) => work.id == 'oil' || work.id == 'coding'), isFalse);
      expect(works.any((work) => work.id == 'wash' || work.id.startsWith('detail-')), isTrue);
    }

    final hydro = sphereById('hydro')!;
    final hydroShops = filterShops(
      cityId: 'warsaw',
      query: '',
      sort: ShopSort.rating,
      now: now,
      taken: {},
      sphereWorkIds: hydro.workIds.toSet(),
    );
    expect(hydroShops.map((shop) => shop.id), contains('aquaform'));
    for (final shop in hydroShops) {
      final works = worksFor(shop, sphereWorkIds: hydro.workIds.toSet());
      expect(works.every((work) => work.id.startsWith('hydro')), isTrue);
    }
  });

  test('extra works stay pending until the shop approves', () {
    final shop = shopById('pitlane')!;
    final booked = shop.workIds.first;
    final extra = shop.workIds.firstWhere((id) => id != booked);
    final order = WorkOrder(
      id: 'o1',
      plate: 'AA0000AA',
      brand: 'BMW',
      model: 'M5',
      mileage: 0,
      vin: '',
      category: RepairCategory.engine,
      lines: [lineFromWork(workById(booked), extra: false, approved: true)],
      status: JobStatus.created,
      createdAt: DateTime(2026, 8, 19),
      shopId: 'pitlane',
    );
    final requested = requestExtraWorks(order, shop, [extra, 'not-a-work']);
    expect(requested.hasPendingExtras, isTrue);
    expect(requested.pendingLines.single.workId, extra);
    expect(requested.totalUah, workById(booked).priceStandard);
    expect(requested.status, JobStatus.approval);

    final approved = approveExtraWork(requested, extra);
    expect(approved.hasPendingExtras, isFalse);
    expect(
      approved.totalUah,
      workById(booked).priceStandard + workById(extra).priceStandard,
    );
    expect(approved.status, JobStatus.created);
  });

  test('service report seeds live camera, mixed gallery and shop chat', () {
    final order = WorkOrder(
      id: 'ord-live',
      plate: 'WA12345',
      brand: 'BMW',
      model: 'F30',
      mileage: 1,
      vin: '',
      category: RepairCategory.engine,
      lines: const [],
      status: JobStatus.inProgress,
      createdAt: DateTime(2026, 8, 19, 10),
      shopId: 'torque-lviv',
    );
    expect(bayCameraAssets(order), isNotEmpty);
    final report = incomingReport(order);
    expect(report, hasLength(6));
    expect(report.where((item) => item.video), hasLength(2));
    expect(report.where((item) => !item.video), hasLength(4));
    expect(seedServiceChat(order), hasLength(2));
  });
}
