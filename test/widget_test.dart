import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autoservice/app/autoservice_app.dart';
import 'package:autoservice/app/providers.dart';
import 'package:autoservice/data/memory_crm_store.dart';

void main() {
  testWidgets('shows login screen first', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryCrmStore();
    await store.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
        ],
        child: const AutoserviceApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ласкаво просимо'), findsOneWidget);
    expect(find.text('Логін'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
    expect(find.text('Реєстрація'), findsOneWidget);
    await tester.ensureVisible(
      find.text('Вхід / Реєстрація для автосервісів'),
    );
    expect(find.text('Вхід / Реєстрація для автосервісів'), findsOneWidget);
  });
}
