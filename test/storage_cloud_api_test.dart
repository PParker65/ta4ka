import 'package:autoservice/data/storage_cloud_api.dart';
import 'package:autoservice/data/wheel_storage_store.dart';
import 'package:autoservice/domain/models/wheel_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('409 is already registered, 401 is login fail', () {
    const exists = StorageCloudException('exists', status: 409);
    const bad = StorageCloudException('unauthorized', status: 401);
    expect(exists.exists, isTrue);
    expect(exists.unauthorized, isFalse);
    expect(bad.unauthorized, isTrue);
    expect(bad.exists, isFalse);
  });

  test('apply remote lots stay on that store only', () async {
    final alice = WheelStorageStore(memory: true, ownerKey: 'a@kolesasave.com');
    final bob = WheelStorageStore(memory: true, ownerKey: 'b@kolesasave.com');
    await alice.init();
    await bob.init();
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);
    alice.applyRemoteState(
      const StorageLotsPayload(
        lots: [WheelLot(id: 'only-a', plate: 'WW 1')],
        pricePerDayGrosze: 500,
        sectorCount: 4,
      ),
    );
    expect(alice.loadLots().single.id, 'only-a');
    expect(bob.loadLots(), isEmpty);
    expect(alice.exportRemoteState().sectorCount, 4);
  });

  test('missing or zero sectorCount becomes kDefaultSectors', () {
    expect(StorageLotsPayload.fromJson({}).sectorCount, kDefaultSectors);
    expect(StorageLotsPayload.fromJson({'sectorCount': 0}).sectorCount, kDefaultSectors);
    expect(StorageLotsPayload.fromJson({'sectorCount': '2'}).sectorCount, kDefaultSectors);
    expect(StorageLotsPayload.fromJson({'sectorCount': 5}).sectorCount, 5);
  });
}
