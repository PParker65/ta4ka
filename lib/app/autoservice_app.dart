import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_lang.dart';
import '../presentation/widgets/launch_intro.dart';
import '../presentation/widgets/telegram_host.dart';
import 'performance.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class AutoserviceApp extends ConsumerWidget {
  const AutoserviceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final s = ref.watch(stringsProvider);
    return MaterialApp.router(
      title: s.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ref.watch(themeProvider), ref.watch(designSkinProvider)),
      locale: lang.locale,
      supportedLocales: AppLang.values.map((item) => item.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return PerfProfileScope(
          child: TelegramHost(
            child: LaunchIntroGate(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      routerConfig: appRouter,
    );
  }
}
