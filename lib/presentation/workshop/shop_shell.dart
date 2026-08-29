import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../widgets/ios_section_switcher.dart';
import 'shop_desk_screen.dart';
import 'shop_inbox_screen.dart';
import 'shop_jobs.dart';
import 'shop_jobs_screen.dart';
import 'shop_masters_register_screen.dart';
import 'shop_open_jobs_screen.dart';
import 'shop_ops_hub_screen.dart';
import 'shop_today_screen.dart';

/// Staff shell: bottom nav always stays; [child] is tab host or nested chat/order.
class ShopShell extends ConsumerWidget {
  const ShopShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final tab = ref.watch(shopTabProvider);
    final unread = shopUnreadCount(ref.watch(ordersProvider));
    final account = ref.watch(shopAccountProvider);
    final blocked = account.isBlocked;
    final session = ref.watch(authProvider);
    final isReception = session?.isReceptionist == true;
    final loc = GoRouterState.of(context).uri.path;
    final onRoot = loc == '/staff' || loc == '/staff/';
    final barIndex = isReception
        ? switch (tab) {
            ShopTabs.today => 0,
            ShopTabs.bookings => 1,
            ShopTabs.chat => 2,
            ShopTabs.ops => 3,
            ShopTabs.requests => 4,
            _ => 0,
          }
        : tab;

    return PopScope(
      canPop: onRoot && tab == ShopTabs.today,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (!onRoot) {
          context.go('/staff');
          return;
        }
        ref.read(sectionSlideDirProvider.notifier).state = -1;
        ref.read(shopTabProvider.notifier).state = ShopTabs.today;
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (blocked && tab != ShopTabs.desk && tab != ShopTabs.masters && onRoot)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.72),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.lock_fill, size: 44, color: palette.accent),
                            const SizedBox(height: 16),
                            Text(
                              s.shopBlockedTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              s.shopBlockedBody,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.muted, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.shopCommissionDebt(formatUah(account.commissionDebtUah)),
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: () {
                                ref.read(shopTabProvider.notifier).state = ShopTabs.desk;
                                context.go('/staff');
                              },
                              child: Text(s.shopTabDesk),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: RepaintBoundary(
          child: CupertinoTabBar(
            currentIndex: barIndex,
            backgroundColor: palette.surface.withValues(alpha: kIsWeb ? 0.96 : (palette.isDark ? 0.72 : 0.94)),
            activeColor: palette.accent,
            inactiveColor: palette.muted,
            border: Border(
              top: BorderSide(color: palette.stroke, width: 0.5),
            ),
            onTap: (index) {
              // Receptionist: remap compact bar (0..4) → real ShopTabs.
              final mapped = isReception
                  ? switch (index) {
                      0 => ShopTabs.today,
                      1 => ShopTabs.bookings,
                      2 => ShopTabs.chat,
                      3 => ShopTabs.ops,
                      4 => ShopTabs.requests,
                      _ => ShopTabs.today,
                    }
                  : index;
              ref.read(sectionSlideDirProvider.notifier).state = 0;
              ref.read(shopTabProvider.notifier).state = mapped;
              if (!onRoot) {
                context.go('/staff');
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.clock),
                activeIcon: const Icon(CupertinoIcons.clock_fill),
                label: s.shopTabToday,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.calendar),
                activeIcon: const Icon(CupertinoIcons.calendar_today),
                label: s.tabBookings,
              ),
              BottomNavigationBarItem(
                icon: _ChatIcon(unread: unread, filled: false),
                activeIcon: _ChatIcon(unread: unread, filled: true),
                label: s.shopTabChat,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.hammer),
                activeIcon: const Icon(CupertinoIcons.hammer_fill),
                label: s.opsHubTitle,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.briefcase),
                activeIcon: const Icon(CupertinoIcons.briefcase_fill),
                label: s.shopTabRequests,
              ),
              if (!isReception) ...[
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.person_badge_plus),
                  activeIcon: const Icon(CupertinoIcons.person_badge_plus_fill),
                  label: s.shopTabMasters,
                ),
                BottomNavigationBarItem(
                  icon: Icon(blocked ? CupertinoIcons.lock_fill : CupertinoIcons.building_2_fill),
                  activeIcon: Icon(blocked ? CupertinoIcons.lock_fill : CupertinoIcons.building_2_fill),
                  label: s.shopTabDesk,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ShopTabsHost extends ConsumerWidget {
  const ShopTabsHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shopTabProvider);
    return IosSectionSwitcher(
      index: tab,
      direction: ref.watch(sectionSlideDirProvider),
      onDirectionConsumed: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ref.read(sectionSlideDirProvider) != 0) {
            ref.read(sectionSlideDirProvider.notifier).state = 0;
          }
        });
      },
      children: const [
        ShopTodayScreen(),
        ShopJobsScreen(),
        ShopInboxScreen(),
        ShopOpsHubScreen(),
        ShopOpenJobsScreen(),
        ShopMastersRegisterScreen(),
        ShopDeskScreen(),
      ],
    );
  }
}

class _ChatIcon extends StatelessWidget {
  const _ChatIcon({required this.unread, required this.filled});

  final int unread;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(filled ? CupertinoIcons.chat_bubble_2_fill : CupertinoIcons.chat_bubble_2),
        if (unread > 0)
          Positioned(
            right: -3,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: paletteOf(context).danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
