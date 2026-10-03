import 'package:autoservice/app/providers.dart';
import 'package:autoservice/app/storage_providers.dart';
import 'package:autoservice/app/theme.dart';
import 'package:autoservice/data/memory_crm_store.dart';
import 'package:autoservice/data/wheel_storage_store.dart';
import 'package:autoservice/domain/models/auth_session.dart';
import 'package:autoservice/domain/models/wheel_storage.dart';
import 'package:autoservice/presentation/storage/storage_desk_screen.dart';
import 'package:autoservice/presentation/storage/storage_rack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone desk fits portrait and landscape without horizontal overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = WheelStorageStore(memory: true, ownerKey: 'desk@test');

    Future<void> pump(Size size) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(MemoryCrmStore()),
            authProvider.overrideWith((ref) {
              return AuthController(ref.watch(repositoryProvider))
                ..signIn(
                  const AuthSession(
                    displayName: 'Тест',
                    login: 'desk@test',
                    role: 'shop_admin',
                    shopName: 'TEST SHOP',
                  ),
                );
            }),
            wheelStorageProvider.overrideWith((ref) {
              return WheelStorageController(store: store);
            }),
          ],
          child: MaterialApp(
            theme: buildAppTheme(AppVisualTheme.guy),
            locale: const Locale('ru'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru'), Locale('en')],
            home: const StorageDeskScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final element = tester.element(find.byType(StorageDeskScreen));
      ProviderScope.containerOf(element).read(wheelStorageProvider.notifier).save(
            WheelLot(
              id: 'lot-1',
              receivedAt: DateTime(2026, 3, 1),
              firstName: 'Иван',
              lastName: 'Петров',
              phone: '500100200',
              plate: 'WX1234',
              vehicle: 'Golf',
              sector: 1,
              rackRow: 1,
              wheelCount: 4,
              pricePerDayGrosze: 700,
            ),
          );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(MediaQuery.sizeOf(tester.element(find.byType(StorageDeskScreen))), size);
      final rack = tester.renderObject<RenderBox>(find.byType(StorageRackView));
      expect(rack.size.width, lessThanOrEqualTo(size.width));
      expect(rack.size.width, greaterThan(size.width * 0.7));
      expect(find.byKey(const Key('storage-profile-corner')), findsOneWidget);
      expect(find.byType(WheelCargoIcon), findsWidgets);
    }

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });
    await pump(const Size(390, 844));
    await pump(const Size(844, 390));
  });
}
