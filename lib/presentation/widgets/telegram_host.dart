import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/telegram_webapp.dart';
import '../../domain/models/auth_session.dart';

void signInFromTelegram(WidgetRef ref) {
  final user = TelegramWebApp.instance.user;
  if (user == null) return;
  ref.read(authProvider.notifier).signIn(
        AuthSession(
          displayName: user.displayName,
          login: 'tg_${user.id}',
          role: 'client',
          password: 'telegram_${user.id}',
        ),
      );
}

void applyTelegramLanguage(WidgetRef ref) {
  final code = TelegramWebApp.instance.user?.languageCode?.toLowerCase() ?? '';
  if (code.isEmpty) return;
  final short = code.length >= 2 ? code.substring(0, 2) : code;
  if (short != 'uk' && short != 'ru' && short != 'en' && short != 'pl') {
    return;
  }
  ref.read(localeProvider.notifier).setLang(AppLangX.fromCode(short));
}

class TelegramHost extends ConsumerStatefulWidget {
  const TelegramHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TelegramHost> createState() => _TelegramHostState();
}

class _TelegramHostState extends ConsumerState<TelegramHost> {
  TelegramInsets _insets = TelegramInsets.zero;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    final tg = TelegramWebApp.instance;
    if (!tg.active) return;
    tg.ready();
    tg.expand();
    tg.onInsets((next) {
      if (!mounted) return;
      setState(() => _insets = next);
    });
    tg.onBack(() {
      if (appRouter.canPop()) {
        appRouter.pop();
        return;
      }
      final tab = ref.read(clientTabProvider);
      if (tab != ClientTabs.car) {
        ref.read(sectionSlideDirProvider.notifier).state = -1;
        ref.read(clientTabProvider.notifier).state = ClientTabs.car;
        return;
      }
      if (ref.read(carBrandPickedProvider)) {
        ref.read(carBrandClearTickProvider.notifier).state++;
      }
    });
    _insets = tg.insets;
    appRouter.routerDelegate.addListener(_syncBack);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!mounted || _bootstrapped) return;
    _bootstrapped = true;
    final tg = TelegramWebApp.instance;
    if (!tg.active) return;
    _insets = tg.insets;
    final hadSession = ref.read(authProvider) != null;
    if (!hadSession && tg.user != null) {
      signInFromTelegram(ref);
      applyTelegramLanguage(ref);
    }
    final tab = _tabForStart(tg.startParam);
    if (tab != null) {
      ref.read(sectionSlideDirProvider.notifier).state = 0;
      ref.selectClientTab(tab);
    }
    _syncBack();
    if (mounted) setState(() {});
  }

  void _syncBack() {
    if (!TelegramWebApp.instance.active) return;
    final nested = appRouter.canPop();
    final offCar = ref.read(clientTabProvider) != ClientTabs.car;
    final brandPicked = ref.read(carBrandPickedProvider);
    TelegramWebApp.instance.setBackVisible(nested || offCar || brandPicked);
  }

  @override
  void dispose() {
    if (TelegramWebApp.instance.active) {
      appRouter.routerDelegate.removeListener(_syncBack);
    }
    super.dispose();
  }

  int? _tabForStart(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    return switch (key) {
      'usa' || 'usa_cars' || 'ltrans' || 'l-trans' || 'america' => ClientTabs.usa,
      'shops' || 'sto' || 'shop' => ClientTabs.shops,
      'book' || 'bookings' || 'slot' || 'calendar' => ClientTabs.bookings,
      'feed' || 'clips' || 'video' => ClientTabs.feed,
      'help' || 'mapa' || 'sos' => ClientTabs.help,
      'auction' => ClientTabs.auction,
      'requests' || 'jobs' || 'naryad' || 'open' => ClientTabs.requests,
      'car' || 'home' || 'auto' => ClientTabs.car,
      'categories' || 'works' || 'catalog' => ClientTabs.categories,
      'profile' || 'me' || 'account' => ClientTabs.profile,
      'book_service' || 'servicebook' || 'service' => ClientTabs.serviceBook,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (TelegramWebApp.instance.active) {
      ref.listen<int>(clientTabProvider, (_, __) => _syncBack());
      ref.listen<bool>(carBrandPickedProvider, (_, __) => _syncBack());
    }
    if (!TelegramWebApp.instance.active) return widget.child;
    final mq = MediaQuery.of(context);
    final inset = _insets;
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(
          top: math.max(mq.padding.top, inset.top),
          bottom: math.max(mq.padding.bottom, inset.bottom),
          left: math.max(mq.padding.left, inset.left),
          right: math.max(mq.padding.right, inset.right),
        ),
        viewPadding: mq.viewPadding.copyWith(
          top: math.max(mq.viewPadding.top, inset.top),
          bottom: math.max(mq.viewPadding.bottom, inset.bottom),
          left: math.max(mq.viewPadding.left, inset.left),
          right: math.max(mq.viewPadding.right, inset.right),
        ),
      ),
      child: widget.child,
    );
  }
}
