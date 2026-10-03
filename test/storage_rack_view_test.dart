import 'package:autoservice/core/l10n/app_lang.dart';
import 'package:autoservice/domain/models/wheel_storage.dart';
import 'package:autoservice/presentation/storage/storage_l10n.dart';
import 'package:autoservice/presentation/storage/storage_rack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expanded rack is a large stand with three sector grids', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var sectors = 3;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return StorageRackView(
                lots: const [],
                l10n: const StorageL10n(AppLang.ru),
                shopName: 'TEST SHOP',
                sectorCount: sectors,
                initiallyExpanded: true,
                maxHeight: 520,
                lite: true,
                onTapSlot: (_, __, ___) {},
                onAddSector: () => setState(() => sectors += 1),
                onRemoveSector: () => setState(() => sectors -= 1),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TEST SHOP'), findsOneWidget);
    expect(find.text('Сектор 1'), findsOneWidget);
    expect(find.text('Сектор 2'), findsOneWidget);
    expect(find.text('Сектор 3'), findsOneWidget);
    expect(find.byType(WheelCargoIcon), findsNWidgets(kDefaultSectors * kRackCells * kWheelsPerCell));

    final box = tester.renderObject<RenderBox>(find.byType(StorageRackView));
    expect(box.size.height, greaterThan(280));
    expect(box.size.height, lessThanOrEqualTo(520));

    await tester.tap(find.text('Добавить сектор'));
    await tester.pumpAndSettle();
    expect(find.text('Сектор 4'), findsOneWidget);
    expect(find.byType(WheelCargoIcon), findsNWidgets(4 * kRackCells * kWheelsPerCell));
  });

  testWidgets('phone widths keep the rack inside the screen', (tester) async {
    Future<void> pump(Size size, double rackH) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: StorageRackView(
                lots: const [],
                l10n: const StorageL10n(AppLang.ru),
                shopName: 'TEST SHOP',
                sectorCount: 3,
                initiallyExpanded: true,
                maxHeight: rackH,
                fitWidth: true,
                compactChrome: true,
                onTapSlot: (_, __, ___) {},
                onAddSector: () {},
                onRemoveSector: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final box = tester.renderObject<RenderBox>(find.byType(StorageRackView));
      expect(box.size.width, lessThanOrEqualTo(size.width));
      expect(box.size.height, lessThanOrEqualTo(size.height));
    }

    await pump(const Size(390, 844), 280);
    expect(find.text('Сектор 1'), findsWidgets);
    expect(find.text('Сектор 2'), findsWidgets);
    expect(find.text('Сектор 3'), findsWidgets);
    expect(find.byType(WheelCargoIcon), findsNWidgets(kRackCells * kWheelsPerCell));

    await pump(const Size(844, 390), 150);
    expect(find.byType(WheelCargoIcon), findsNWidgets(kDefaultSectors * kRackCells * kWheelsPerCell));
  });
}
