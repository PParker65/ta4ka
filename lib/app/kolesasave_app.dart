import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_lang.dart';
import '../presentation/storage/storage_desk_screen.dart';
import '../presentation/storage/storage_launch_intro.dart';
import 'providers.dart';
import 'storage_app_router.dart';
import 'theme.dart';

/// Light shell for kolesasave.com: login + storage desk only.
class KolesaSaveApp extends ConsumerWidget {
  const KolesaSaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'KOLESA SAVE',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ref.watch(themeProvider), ref.watch(designSkinProvider)),
      locale: lang.locale,
      supportedLocales: AppLang.values.map((item) => item.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => StorageLaunchIntroGate(
        child: SizedBox.expand(child: child ?? const StorageDeskScreen()),
      ),
      routerConfig: storageAppRouter,
    );
  }
}
