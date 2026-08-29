import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/shop_photos.dart';
import '../../data/shop_seed.dart';
import '../../data/telegram_webapp.dart';
import '../../domain/models/shop_brand.dart';
import '../client/widgets/client_nav_map.dart';
import '../client/widgets/client_services_sheet.dart';
import 'category_scene.dart';
import 'living_icon.dart';

class ScreenCanvas extends ConsumerWidget {
  const ScreenCanvas({super.key, required this.child, this.sphereId});

  final Widget child;
  final String? sphereId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = sphereId ?? ref.watch(sceneSphereIdProvider) ?? ref.watch(bookingProvider).sphereId;
    final dark = paletteOf(context).isDark;
    return Stack(
      fit: StackFit.expand,
      children: [
        CategorySceneBackdrop(sphereId: id, dim: dark ? (id == null ? 0.58 : 0.5) : 0.18),
        child,
      ],
    );
  }
}

class LargeTitle extends StatelessWidget {
  const LargeTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.displayLarge,
    );
  }
}

/// Red notification dot on a nav icon when there are open bookings.
class NavBadgeIcon extends StatefulWidget {
  const NavBadgeIcon({
    super.key,
    required this.icon,
    required this.showBadge,
    this.pulse = false,
    this.face,
  });

  final IconData icon;
  final bool showBadge;
  final bool pulse;
  /// Animated glyph; falls back to a static [icon].
  final Widget? face;

  @override
  State<NavBadgeIcon> createState() => _NavBadgeIconState();
}

class _NavBadgeIconState extends State<NavBadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (widget.pulse) {
      _beat.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NavBadgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_beat.isAnimating) {
      _beat.repeat(reverse: true);
    } else if (!widget.pulse && _beat.isAnimating) {
      _beat
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return AnimatedBuilder(
      animation: _beat,
      builder: (context, child) {
        final t = widget.pulse ? Curves.easeInOut.transform(_beat.value) : 0.0;
        final color = Color.lerp(palette.accent, palette.danger, t)!;
        return Transform.scale(
          scale: 1.0 + 0.22 * t,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.face ??
                  Icon(widget.icon, color: widget.pulse ? color : null, size: widget.pulse ? 26 : null),
              if (widget.showBadge || widget.pulse)
                Positioned(
                  right: -3,
                  top: -2,
                  child: Container(
                    width: widget.pulse ? 10 : 8,
                    height: widget.pulse ? 10 : 8,
                    decoration: BoxDecoration(
                      color: widget.pulse ? color : palette.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: palette.accent, size: 26),
        ),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.displayLarge),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.muted,
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

/// Color workshop photo (not grayscale). Each shop gets its own shots.
class ShopColorPhoto extends StatefulWidget {
  const ShopColorPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth = 900,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int cacheWidth;

  @override
  State<ShopColorPhoto> createState() => _ShopColorPhotoState();
}

class _ShopColorPhotoState extends State<ShopColorPhoto> {
  late String _url;
  var _tries = 0;

  @override
  void initState() {
    super.initState();
    _url = widget.url;
  }

  @override
  void didUpdateWidget(covariant ShopColorPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _url = widget.url;
      _tries = 0;
    }
  }

  void _fallback() {
    if (!mounted || _tries >= 5) return;
    setState(() {
      _tries += 1;
      _url = kShopPhotoPool[(_tries * 7) % kShopPhotoPool.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Image.network(
        _url,
        width: double.infinity,
        height: double.infinity,
        fit: widget.fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        cacheWidth: widget.cacheWidth,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(color: palette.carbon);
        },
        errorBuilder: (_, __, ___) {
          if (_tries >= 5) {
            return Image.asset(
              'assets/shops/pitlane.jpg',
              fit: widget.fit,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => _fallback());
          return ColoredBox(color: palette.carbon);
        },
      ),
    );
  }
}

class ShopCoverBanner extends ConsumerWidget {
  const ShopCoverBanner({
    super.key,
    required this.shopId,
    this.height = 132,
    this.showName = true,
  });

  final String shopId;
  final double height;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = shopById(shopId);
    final account = ref.watch(shopAccountProvider);
    final lang = ref.watch(localeProvider);
    final label = shop == null
        ? shopId
        : shopClientName(shop, account, lang);
    final named = showName && height >= 72;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShopColorPhoto(
            url: shopCoverPhoto(shopId),
            height: height,
            cacheWidth: height >= 160 ? 900 : 640,
          ),
          if (named)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x99000000)],
                ),
              ),
            ),
          if (named)
            Positioned(
              left: 12,
              right: 12,
              bottom: 9,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: (height * 0.105).clamp(11.0, 15.0),
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Real workshop photo for a shop, stable by [shopId].
class ShopAutoAvatar extends StatelessWidget {
  const ShopAutoAvatar({
    super.key,
    required this.shopId,
    required this.initials,
    this.size = 56,
    this.radius = 16,
  });

  final String shopId;
  final String initials;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShopCoverBanner(shopId: shopId, height: size),
            if (size >= 56)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x66000000)],
                  ),
                ),
              ),
            if (size >= 56)
              Positioned(
                left: 8,
                bottom: 6,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.22,
                    color: Colors.white.withValues(alpha: 0.96),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final bg = accent ? palette.accent : palette.surface;
    final fg = accent ? palette.onAccent : palette.text;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: accent ? palette.onAccent : palette.accent,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  letterSpacing: -0.08,
                  color: accent
                      ? palette.onAccent.withValues(alpha: 0.78)
                      : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepPills extends StatelessWidget {
  const StepPills({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? palette.accent : palette.carbon,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (i != total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Bottom navigation bar for screens outside `ClientShell`
/// (shop detail, slot picker, booking summary, etc.).
/// Tapping the current-tab icon goes back to `/home` on that tab.
class ClientNavBar extends ConsumerWidget {
  const ClientNavBar({super.key, this.activeTab});

  /// Which tab to highlight. If null, nothing is highlighted.
  final int? activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);

    void goTab(int index) {
      TelegramWebApp.instance.hapticLight();
      if (index == 5) {
        showClientServicesSheet(context, ref);
        return;
      }
      ref.read(sectionSlideDirProvider.notifier).state = 0;
      ref.selectClientTab(clientTabForBarIndex(index));
      context.go('/home');
    }

    final highlight = activeTab == null ? 2 : clientBarIndexForTab(activeTab!);
    final hasBookings = ref.watch(ordersProvider).any((order) => order.shopId.isNotEmpty);
    final pulseBookings = ref.watch(bookingsPulseProvider);

    return RepaintBoundary(
      child: CupertinoTabBar(
        currentIndex: highlight.clamp(0, 5),
        backgroundColor: palette.surface.withValues(alpha: kIsWeb ? 0.96 : (palette.isDark ? 0.72 : 0.94)),
        activeColor: palette.accent,
        inactiveColor: palette.muted,
        border: Border(top: BorderSide(color: palette.stroke, width: 0.5)),
        onTap: goTab,
        items: [
          BottomNavigationBarItem(
            icon: LivingIcon(icon: CupertinoIcons.play_circle, phase: 0, color: palette.muted),
            activeIcon: LivingIcon(icon: CupertinoIcons.play_circle_fill, phase: 0, active: true, color: palette.accent),
            label: s.tabFeed,
          ),
          BottomNavigationBarItem(
            icon: LivingIcon(icon: CupertinoIcons.square_grid_2x2, phase: 1, color: palette.muted),
            activeIcon: LivingIcon(icon: CupertinoIcons.square_grid_2x2_fill, phase: 1, active: true, color: palette.accent),
            label: s.tabShops,
          ),
          BottomNavigationBarItem(
            icon: LivingIcon(icon: CupertinoIcons.car_detailed, phase: 2, size: 28, color: palette.muted),
            activeIcon: LivingIcon(icon: CupertinoIcons.car_detailed, phase: 2, size: 28, active: true, color: palette.accent),
            label: s.tabCar,
          ),
          BottomNavigationBarItem(
            icon: LivingIcon(icon: CupertinoIcons.square_list, phase: 3, color: palette.muted),
            activeIcon: LivingIcon(icon: CupertinoIcons.square_list_fill, phase: 3, active: true, color: palette.accent),
            label: s.tabCategories,
          ),
          BottomNavigationBarItem(
            icon: NavBadgeIcon(
              icon: CupertinoIcons.calendar,
              showBadge: hasBookings,
              pulse: pulseBookings,
              face: LivingIcon(icon: CupertinoIcons.calendar, phase: 4, color: palette.muted),
            ),
            activeIcon: NavBadgeIcon(
              icon: CupertinoIcons.calendar_today,
              showBadge: hasBookings,
              pulse: pulseBookings,
              face: LivingIcon(icon: CupertinoIcons.calendar_today, phase: 4, active: true, color: palette.accent),
            ),
            label: s.tabBookings,
          ),
          BottomNavigationBarItem(
            icon: LivingIcon(icon: CupertinoIcons.chevron_up_circle, phase: 5, color: palette.muted),
            activeIcon: LivingIcon(icon: CupertinoIcons.chevron_up_circle_fill, phase: 5, active: true, color: palette.accent),
            label: s.tabServices,
          ),
        ],
      ),
    );
  }
}

class AppleSegmented extends StatelessWidget {
  const AppleSegmented({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
  });

  final Map<String, Widget> children;
  final String groupValue;
  final ValueChanged<String> onValueChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: groupValue,
        backgroundColor: paletteOf(context).surface,
        thumbColor: paletteOf(context).carbon,
        children: children,
        onValueChanged: (value) {
          if (value != null) {
            onValueChanged(value);
          }
        },
      ),
    );
  }
}
