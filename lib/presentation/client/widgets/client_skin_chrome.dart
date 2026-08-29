import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_skin.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/telegram_webapp.dart';
import '../../widgets/living_icon.dart';
import '../../widgets/ui.dart';
import 'client_nav_map.dart';
import 'client_services_sheet.dart';

const _kNavPair = <(IconData, IconData)>[
  (CupertinoIcons.play_circle, CupertinoIcons.play_circle_fill),
  (CupertinoIcons.square_grid_2x2, CupertinoIcons.square_grid_2x2_fill),
  (CupertinoIcons.car_detailed, CupertinoIcons.car_detailed),
  (CupertinoIcons.square_list, CupertinoIcons.square_list_fill),
  (CupertinoIcons.calendar, CupertinoIcons.calendar_today),
  (CupertinoIcons.chevron_up_circle, CupertinoIcons.chevron_up_circle_fill),
];

Widget _livingNavIcon({
  required int index,
  required bool selected,
  required Color color,
  bool badge = false,
  bool badgePulse = false,
}) {
  final pair = _kNavPair[index];
  final face = LivingIcon(
    icon: selected ? pair.$2 : pair.$1,
    color: color,
    size: index == 2 ? 28 : 24,
    phase: index,
    active: selected,
  );
  if (!badge && !badgePulse) return face;
  return NavBadgeIcon(
    icon: selected ? pair.$2 : pair.$1,
    showBadge: badge,
    pulse: badgePulse,
    face: face,
  );
}

/// Shell chrome that changes placement of navigation per DesignSkin.
class ClientSkinChrome extends ConsumerWidget {
  const ClientSkinChrome({super.key, required this.child});

  final Widget child;

  void _onNav(BuildContext context, WidgetRef ref, int index) {
    TelegramWebApp.instance.hapticLight();
    if (index == 5) {
      showClientServicesSheet(context, ref);
      return;
    }
    ref.read(sectionSlideDirProvider.notifier).state = 0;
    ref.selectClientTab(clientTabForBarIndex(index));
    context.go('/home');
  }

  List<BottomNavigationBarItem> _items(
    AppStrings s,
    bool hasBookings,
    bool pulseBookings,
  ) =>
      [
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.play_circle),
          activeIcon: const Icon(CupertinoIcons.play_circle_fill),
          label: s.tabFeed,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.square_grid_2x2),
          activeIcon: const Icon(CupertinoIcons.square_grid_2x2_fill),
          label: s.tabShops,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.car_detailed, size: 28),
          activeIcon: const Icon(CupertinoIcons.car_detailed, size: 28),
          label: s.tabCar,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.square_list),
          activeIcon: const Icon(CupertinoIcons.square_list_fill),
          label: s.tabCategories,
        ),
        BottomNavigationBarItem(
          icon: NavBadgeIcon(
            icon: CupertinoIcons.calendar,
            showBadge: hasBookings,
            pulse: pulseBookings,
          ),
          activeIcon: NavBadgeIcon(
            icon: CupertinoIcons.calendar_today,
            showBadge: hasBookings,
            pulse: pulseBookings,
          ),
          label: s.tabBookings,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.chevron_up_circle),
          activeIcon: const Icon(CupertinoIcons.chevron_up_circle_fill),
          label: s.tabServices,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final tokens = tokensOf(context);
    final tab = ref.watch(clientTabProvider);
    final hasBookings = ref.watch(ordersProvider).any((o) => o.shopId.isNotEmpty);
    final pulseBookings = ref.watch(bookingsPulseProvider);
    final barIndex = clientBarIndexForTab(tab).clamp(0, 5);
    final items = _items(s, hasBookings, pulseBookings);

    switch (tokens.navChrome) {
      case NavChrome.bottomClassic:
        return Scaffold(
          body: child,
          extendBody: true,
          bottomNavigationBar: _cupertinoBar(
            context,
            palette,
            barIndex,
            items,
            hasBookings,
            pulseBookings,
            (i) => _onNav(context, ref, i),
          ),
        );
      case NavChrome.topStrip:
        return Scaffold(
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Material(
                  color: palette.surface,
                  child: Column(
                    children: [
                      Container(height: tokens.borderWidth, color: palette.stroke),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: 6,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (ctx, i) {
                            final selected = i == barIndex;
                            final label = [
                              s.tabFeed,
                              s.tabShops,
                              s.tabCar,
                              s.tabCategories,
                              s.tabBookings,
                              s.tabServices,
                            ][i];
                            return TextButton(
                              onPressed: () => _onNav(context, ref, i),
                              style: TextButton.styleFrom(
                                foregroundColor: selected ? palette.onAccent : palette.text,
                                backgroundColor: selected ? palette.accent : Colors.transparent,
                                shape: const RoundedRectangleBorder(),
                                side: BorderSide(color: palette.stroke, width: tokens.borderWidth),
                              ),
                              child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                            );
                          },
                        ),
                      ),
                      Container(height: tokens.borderWidth, color: palette.stroke),
                    ],
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      case NavChrome.floatingCapsule:
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                left: 18,
                right: 18,
                bottom: 22 + MediaQuery.viewPaddingOf(context).bottom,
                child: Material(
                  elevation: 10,
                  shadowColor: Colors.black38,
                  borderRadius: BorderRadius.circular(28),
                  color: palette.surface.withValues(alpha: 0.97),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        for (var i = 0; i < 6; i++)
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => _onNav(context, ref, i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: i == barIndex
                                      ? palette.accent.withValues(alpha: 0.16)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: _livingNavIcon(
                                  index: i,
                                  selected: i == barIndex,
                                  color: i == barIndex ? palette.accent : palette.muted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case NavChrome.leftRail:
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                right: false,
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(right: BorderSide(color: palette.stroke, width: tokens.borderWidth)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      for (var i = 0; i < 6; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: IconButton(
                            onPressed: () => _onNav(context, ref, i),
                            icon: _livingNavIcon(
                              index: i,
                              selected: i == barIndex,
                              color: i == barIndex ? palette.accent : palette.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      case NavChrome.bottomFat:
        return Scaffold(
          body: child,
          bottomNavigationBar: Material(
            color: palette.surface,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.stroke, width: tokens.borderWidth)),
                ),
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                child: Row(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Expanded(
                        child: InkWell(
                          onTap: () => _onNav(context, ref, i),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                [
                                  s.tabFeed,
                                  s.tabShops,
                                  s.tabCar,
                                  s.tabCategories,
                                  s.tabBookings,
                                  s.tabServices,
                                ][i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: i == barIndex ? palette.accent : palette.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _livingNavIcon(
                                index: i,
                                selected: i == barIndex,
                                color: i == barIndex ? palette.accent : palette.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _cupertinoBar(
    BuildContext context,
    AppPalette palette,
    int barIndex,
    List<BottomNavigationBarItem> items,
    bool hasBookings,
    bool pulseBookings,
    ValueChanged<int> onTap,
  ) {
    final bg = palette.surface.withValues(alpha: kIsWeb ? 0.96 : (palette.isDark ? 0.55 : 0.78));
    final panel = ColoredBox(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColoredBox(
            color: palette.stroke.withValues(alpha: 0.55),
            child: const SizedBox(height: 0.5, width: double.infinity),
          ),
          const SizedBox(height: 10),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _livingNavIcon(
                              index: i,
                              selected: i == barIndex,
                              color: i == barIndex ? palette.accent : palette.muted,
                              badge: i == 4 && hasBookings,
                              badgePulse: i == 4 && pulseBookings,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].label ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: i == barIndex ? palette.accent : palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (kIsWeb) return panel;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: panel,
      ),
    );
  }
}
