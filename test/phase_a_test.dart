import 'package:autoservice/core/l10n/app_lang.dart';
import 'package:autoservice/data/auto_spheres.dart';
import 'package:autoservice/data/catalog_seed.dart';
import 'package:autoservice/data/you_get_steps.dart';
import 'package:autoservice/data/car_brands.dart';
import 'package:autoservice/data/car_hotspots.dart';
import 'package:autoservice/data/car_layout.dart';
import 'package:autoservice/data/car_xray_labels.dart';
import 'package:autoservice/data/category_scenes.dart';
import 'package:autoservice/data/dto/job_dto.dart';
import 'package:autoservice/data/jobs_api.dart';
import 'package:autoservice/domain/models/crm_models.dart';
import 'package:autoservice/domain/models/shop_account.dart';
import 'package:autoservice/domain/work_map.dart';
import 'package:autoservice/presentation/auth/interactive_car.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('car hotspots map wheels to chassis and knocking hint', () {
    final wheel = hotspotById('wheel-fr');
    expect(wheel, isNotNull);
    expect(wheel!.sphereId, 'chassis');
    expect(wheel.hint.ru, contains('стучит'));

    final engine = hotspotById('engine');
    expect(engine!.sphereId, 'engine');
  });

  test('xray aliases map turbo and xDrive to real work points', () {
    expect(xrayHotspotAlias('turbo'), 'engine');
    expect(xrayHotspotAlias('xdrive'), 'undercarriage');
    expect(resolveXrayHotspot('fuel')?.sphereId, 'engine');
  });

  test('BMW layout places a front V8 and cabin controls', () {
    final bmw = resolveCarBrand('бмв');
    expect(bmw.engineKind, EngineKind.v8);
    expect(bmw.kidneys, isTrue);
    expect(bmw.exhaustTips, 4);
    final spots = placedHotspots(bmw);
    final engine = spots.firstWhere((hotspot) => hotspot.id == 'engine');
    expect(engine.pos.x, greaterThan(40));
    final gu = spots.firstWhere((hotspot) => hotspot.id == 'headunit');
    expect(gu.sphereId, 'electronics');
    final wheel = spots.firstWhere((hotspot) => hotspot.id == 'steering');
    expect(wheel.sphereId, 'interior');
  });

  test('hitTestCarHotspot selects engine at projected point', () {
    const size = Size(400, 400);
    const yaw = 0.72;
    const pitch = 0.18;
    const zoom = 1.15;
    final origin = Offset(size.width / 2, size.height * kCarStageOriginY);
    final engine = hotspotById('engine')!;
    final projected = projectCarPoint(
      point: engine.pos,
      yaw: yaw,
      pitch: pitch,
      zoom: zoom,
      origin: origin,
    );
    final hit = hitTestCarHotspot(
      local: projected.offset,
      size: size,
      yaw: yaw,
      pitch: pitch,
      zoom: zoom,
    );
    expect(hit?.id, 'engine');
  });

  test('matchCarBrands understands misspellings from first letters', () {
    expect(resolveCarBrand('вольцваген').id, 'volkswagen');
    expect(resolveCarBrand('фольц').id, 'volkswagen');
    expect(resolveCarBrand('бмв').id, 'bmw');
    expect(matchCarBrands('во').any((brand) => brand.id == 'volkswagen'), isTrue);
  });

  test('searchSpheres matches automotive categories', () {
    final stage = searchSpheres('stage 3 turbo', lang: AppLang.ru);
    expect(stage, isNotEmpty);
    expect(stage.first.id, 'stage3');

    final paint = searchSpheres('малярка', lang: AppLang.uk);
    expect(paint.any((sphere) => sphere.id == 'paint'), isTrue);

    final body = searchSpheres('рихтовка', lang: AppLang.uk);
    expect(body, isNotEmpty);
    expect(body.first.id, 'body');

    final bodyRu = searchSpheres('рихтовка', lang: AppLang.ru);
    expect(bodyRu.any((sphere) => sphere.id == 'body'), isTrue);

    final hydro = searchSpheres('аквапечать', lang: AppLang.ru);
    expect(hydro.any((sphere) => sphere.id == 'hydro'), isTrue);
  });

  test('maps want and symptom to catalog work id', () {
    expect(workIdFor(want: 'diag', symptom: 'brakes'), 'diag-chassis');
    expect(workIdFor(want: 'repair', symptom: 'engine'), 'plugs');
    expect(workIdFor(want: 'to', symptom: 'roadside'), 'oil');
    expect(workIdFor(want: 'coding', symptom: 'unknown'), 'coding');
  });

  test('roadside is emergency', () {
    expect(isEmergencySymptom('roadside'), isTrue);
    expect(isEmergencySymptom('brakes'), isFalse);
  });

  test('rating average uses four factors', () {
    final rating = Rating(
      id: '1',
      orderId: 'o',
      masterId: 'm',
      quality: 5,
      politeness: 3,
      punctuality: 4,
      cleanliness: 4,
      comment: '',
      createdAt: DateTime.utc(2026, 8, 17),
    );
    expect(rating.average, 4);
    expect(rating.stars, 4);
  });

  test('mock jobs api creates booked job and json roundtrip', () async {
    final api = MockJobsApi();
    final created = await api.create(
      const JobCreateRequest(
        shopId: 'shop-1',
        plate: 'AA1234BB',
        brand: 'BMW',
        model: 'M2',
        year: 2018,
        symptomId: 'roadside',
        wantId: 'diag',
        tier: 'standard',
      ),
    );
    expect(created.status, 'booked');
    expect(created.isEmergency, isTrue);
    expect(created.workId, 'diag-comp');
    expect(JobDto.fromJson(created.toJson()).id, created.id);

    final listed = await api.list();
    expect(listed, hasLength(1));
    await api.cancel(created.id);
    expect((await api.getById(created.id)).status, 'cancelled');
  });

  test('every catalog work and sphere has what-you-get steps', () {
    for (final work in catalogWorks) {
      expect(work.youGet, isNotEmpty, reason: work.id);
      expect(work.youGet.length, greaterThanOrEqualTo(3), reason: work.id);
    }
    for (final sphere in autoSpheres) {
      expect(sphere.workIds, isNotEmpty, reason: sphere.id);
      for (final id in sphere.workIds) {
        expect(catalogWorks.any((work) => work.id == id), isTrue, reason: '${sphere.id} -> $id');
      }
    }
  });

  test('category scenes map paint and interior to workshop plates', () {
    expect(categorySceneKey('paint'), 'paint');
    expect(categorySceneKey('bumper'), 'paint');
    expect(categorySceneKey('interior'), 'interior');
    expect(categorySceneKey('soundproof'), 'interior');
    expect(categorySceneKey(null), 'workshop');
    expect(categorySceneAsset('paint'), 'assets/scenes/scene-paint.jpg');
  });

  test('shop account keeps camera live flags and sphere works', () {
    const account = ShopAccount(
      login: 'sto',
      shopName: 'Ta4ka',
      city: 'Warsaw',
      address: 'ul. Waryńskiego, 12',
      phone: '+481111',
      sphereIds: ['diag'],
      cameraConnected: true,
      liveOn: true,
    );
    final copy = ShopAccount.fromJson(account.toJson());
    expect(copy.shopName, 'Ta4ka');
    expect(copy.liveOn, isTrue);
    expect(copy.cameraConnected, isTrue);
    expect(copy.workIds, isNotEmpty);
  });
}
