import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/shop_seed.dart';
import '../../../domain/models/crm_models.dart';
import '../booking_format.dart';

const kTodayFreeGreen = Color(0xFF1B9E4B);
const kTodayBusyRed = Color(0xFFC23B3B);

/// Job is done / ready for a return visit — not while the car is still in-bay.
bool canBookAgain(WorkOrder order) {
  if (order.shopId.isEmpty || order.status == JobStatus.cancelled) {
    return false;
  }
  return order.status == JobStatus.ready || order.completedAt != null;
}

void openSameShopBooking({
  required BuildContext context,
  required WidgetRef ref,
  required String shopId,
}) {
  if (shopId.isEmpty) return;
  ref.read(bookingProvider.notifier).openShop(shopId, fullMenu: true);
  context.push('/home/shops/${Uri.encodeComponent(shopId)}');
}

class BookAgainButton extends StatelessWidget {
  const BookAgainButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, compact ? 40 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        icon: Icon(CupertinoIcons.calendar_badge_plus, size: compact ? 15 : 16),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class TodaySlotStatus extends StatelessWidget {
  const TodaySlotStatus({
    super.key,
    required this.times,
    required this.strings,
    this.large = false,
    this.onOpen,
  });

  final List<DateTime> times;
  final AppStrings strings;
  final bool large;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final free = times.isNotEmpty;
    final clocks = times.map(formatClock).join(' · ');
    final child = Text(
      free ? strings.todayFreeAt(clocks) : strings.todayBusy,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: free ? kTodayFreeGreen : kTodayBusyRed,
        fontWeight: FontWeight.w700,
        fontSize: large ? 15 : 13,
        height: 1.3,
        letterSpacing: -0.15,
      ),
    );
    if (!free || onOpen == null) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: child,
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.value,
    this.size = 15,
    this.count,
  });

  final double value;
  final double size;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    const yellow = Color(0xFFFFD60A);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= value.round() ? CupertinoIcons.star_fill : CupertinoIcons.star,
            size: size,
            color: yellow,
          ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '${value.toStringAsFixed(1)} · $count',
            style: TextStyle(
              color: palette.muted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: -0.08,
            ),
          ),
        ],
      ],
    );
  }
}

/// Stars plus a quiet “reviews” hint — whole block opens the shop reviews screen.
class ShopRatingTap extends StatelessWidget {
  const ShopRatingTap({
    super.key,
    required this.value,
    required this.count,
    required this.hint,
    required this.onOpen,
  });

  final double value;
  final int count;
  final String hint;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          button: true,
          label: '$hint · ${value.toStringAsFixed(1)}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 14, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRow(value: value, count: count, size: 18),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hint,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 11,
                        color: palette.muted.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.label,
    this.live = false,
    this.active = false,
    this.color,
    this.foreground,
  });

  final String label;
  final bool live;
  final bool active;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final tone = color ?? (live ? palette.danger : null);
    final bg = live
        ? palette.danger.withValues(alpha: 0.16)
        : active && tone != null
            ? tone.withValues(alpha: 0.16)
            : palette.carbon.withValues(alpha: active ? 0.95 : 0.55);
    final fg = foreground ??
        (live
            ? palette.danger
            : active && tone != null
                ? tone
                : palette.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: active && tone != null
            ? Border.all(color: tone.withValues(alpha: 0.65))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
          color: fg,
        ),
      ),
    );
  }
}

class BayCamStatus extends StatelessWidget {
  const BayCamStatus({super.key, required this.online, required this.strings});

  final bool online;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = online ? kTodayFreeGreen : kTodayBusyRed;
    return Text(
      online ? strings.badgeLive : strings.badgeOffline,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1.3,
        letterSpacing: -0.15,
      ),
    );
  }
}

Future<bool> confirmCancelBooking({
  required BuildContext context,
  required WidgetRef ref,
  required WorkOrder order,
}) async {
  final s = ref.read(stringsProvider);
  final lang = ref.read(localeProvider);
  final palette = paletteOf(context);
  final shop = shopById(order.shopId);
  final when = order.scheduledAt;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          s.cancelBooking,
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.cancelBookingLead,
              style: TextStyle(color: palette.muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            Text(
              shop?.name.of(lang) ?? s.tabShops,
              style:
                  TextStyle(color: palette.text, fontWeight: FontWeight.w700),
            ),
            Text(
              '${order.brand} ${order.model} · ${order.plate}',
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
            if (when != null)
              Text(
                formatWhen(when, lang),
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel, style: TextStyle(color: palette.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.cancelBookingAction,
              style: TextStyle(
                color: palette.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    },
  );
  if (ok != true) return false;
  ref.read(ordersProvider.notifier).remove(order.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.bookingCancelled)),
    );
  }
  return true;
}
