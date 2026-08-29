import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/autoservice_app.dart';
import 'app/bootstrap_stub.dart' if (dart.library.io) 'app/bootstrap_io.dart' as bootstrap;
import 'app/providers.dart';
import 'data/create_crm_store.dart';
import 'data/crm_store.dart';
import 'presentation/widgets/launch_intro.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  markLaunchStart();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await bootstrap.initPlatformStores();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<CrmStore> _storeFuture = _loadStore();

  Future<CrmStore> _loadStore() async {
    try {
      return await createCrmStore().timeout(const Duration(seconds: 8));
    } catch (_) {
      return createCrmStore(inMemory: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CrmStore>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ProviderScope(
            overrides: [
              storeProvider.overrideWithValue(snapshot.data!),
            ],
            child: const AutoserviceApp(),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFF07070A),
            body: LaunchIntroStage(),
          ),
        );
      },
    );
  }
}
