import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/kolesasave_app.dart';
import 'app/providers.dart';
import 'app/url_strategy_stub.dart'
    if (dart.library.html) 'app/url_strategy_web.dart';
import 'data/create_crm_store.dart';
import 'data/local_accounts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppUrlStrategy();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  ErrorWidget.builder = (details) {
    return const Material(
      color: Color(0xFFF4F1EA),
      child: Center(
        child: Text('KOLESA SAVE', style: TextStyle(letterSpacing: 3)),
      ),
    );
  };
  await LocalAccountStore.instance.init();
  final store = await createCrmStore();
  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
      ],
      child: const KolesaSaveApp(),
    ),
  );
}
