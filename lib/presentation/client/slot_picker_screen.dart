import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/shop_models.dart';
import '../widgets/ui.dart';
import 'booking_format.dart';

class SlotPickerScreen extends ConsumerStatefulWidget {
  const SlotPickerScreen({super.key});

  @override
  ConsumerState<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends ConsumerState<SlotPickerScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool _bookable(DateTime day, DateTime today) {
    if (day.weekday == DateTime.sunday) return false;
    if (day.isBefore(today)) return false;
    return true;
  }

  Future<void> _openWindows({
    required DateTime day,
    required List<DateTime> times,
    required List<ShopTimeSlot> slots,
    required AppStrings s,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _WindowsSheet(
          day: day,
          times: times,
          slots: slots,
          strings: s,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final draft = ref.watch(bookingProvider);
    final shop = shopById(draft.shopId ?? '');
    final taken = ref.watch(takenSlotsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (shop == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(s.noShops)));
    }

    final slots = buildShopSlots(shop: shop, now: now, taken: taken);
    final selectedDay = draft.date ?? today;
    final headers = weekdayHeaders(lang);
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysInMonth;
    final rows = ((cells + 6) ~/ 7);
    final canPrev = _month.year > today.year || _month.month > today.month;
    final lastBookable = today.add(const Duration(days: 44));
    final canNext = DateTime(_month.year, _month.month + 1).isBefore(
      DateTime(lastBookable.year, lastBookable.month + 1),
    );

    bool hasFree(DateTime day) {
      return slots.any((slot) => slot.open && sameDay(slot.start, day));
    }

    List<DateTime> timesFor(DateTime day) {
      final times = <DateTime>[];
      for (final clock in slotClock) {
        final time = DateTime(day.year, day.month, day.day, clock.$1, clock.$2);
        if (time.isAfter(now.add(const Duration(minutes: 15)))) times.add(time);
      }
      return times;
    }

    void onDayTap(DateTime day) {
      if (!_bookable(day, today)) {
        if (day.weekday == DateTime.sunday) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.dayOff)));
        }
        return;
      }
      HapticFeedback.lightImpact();
      ref.read(bookingProvider.notifier).setDate(day);
      _openWindows(day: day, times: timesFor(day), slots: slots, s: s);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: palette.bg.withValues(alpha: palette.isDark ? 0.42 : 0.88),
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        title: Text(s.pickDate),
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context, top: 8, extra: 8),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ShopCoverBanner(shopId: shop.id, height: 88),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.surface,
                    palette.carbon,
                  ],
                ),
                border: Border.all(color: palette.stroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: palette.isDark ? 0.55 : 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: palette.isDark ? 0.06 : 0.8),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: canPrev
                            ? () => setState(() => _month = DateTime(_month.year, _month.month - 1))
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          formatMonthYear(_month, lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: palette.text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canNext
                            ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final name in headers)
                        Expanded(
                          child: Text(
                            name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: palette.muted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var r = 0; r < rows; r++) ...[
                    if (r > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var c = 0; c < 7; c++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: _DayCell(
                                index: r * 7 + c,
                                lead: lead,
                                daysInMonth: daysInMonth,
                                month: _month,
                                today: today,
                                selected: selectedDay,
                                lastBookable: lastBookable,
                                hasFree: hasFree,
                                onTap: onDayTap,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (draft.slot != null) ...[
              const SizedBox(height: 16),
              Text(
                formatWhen(draft.slot!.start, lang),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: palette.text),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/home/confirm'),
                  child: Text(s.next, textAlign: TextAlign.center),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.lead,
    required this.daysInMonth,
    required this.month,
    required this.today,
    required this.selected,
    required this.lastBookable,
    required this.hasFree,
    required this.onTap,
  });

  final int index;
  final int lead;
  final int daysInMonth;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final DateTime lastBookable;
  final bool Function(DateTime day) hasFree;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final dayNum = index - lead + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 48);
    }
    final day = DateTime(month.year, month.month, dayNum);
    final isToday = sameDay(day, today);
    final isSelected = sameDay(day, selected);
    final closed = day.weekday == DateTime.sunday;
    final past = day.isBefore(today);
    final far = day.isAfter(lastBookable);
    final enabled = !closed && !past && !far;
    final free = enabled && hasFree(day);

    final Color bg;
    final Color fg;
    List<BoxShadow>? shadows;
    if (isSelected && enabled) {
      bg = const Color(0xFF1F9D55);
      fg = Colors.white;
      shadows = [
        BoxShadow(
          color: const Color(0xFF1F9D55).withValues(alpha: 0.45),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
    } else if (!enabled) {
      bg = palette.carbon.withValues(alpha: 0.35);
      fg = palette.muted.withValues(alpha: 0.7);
    } else {
      bg = palette.isDark ? const Color(0xFF242428) : Colors.white;
      fg = palette.text;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: palette.isDark ? 0.45 : 0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: palette.isDark ? 0.08 : 1),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onTap(day) : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday && !isSelected ? palette.accent : palette.stroke.withValues(alpha: 0.7),
              width: isToday && !isSelected ? 1.6 : 1,
            ),
            boxShadow: shadows,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: fg,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: free
                      ? (isSelected ? Colors.white : const Color(0xFF1F9D55))
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowsSheet extends ConsumerWidget {
  const _WindowsSheet({
    required this.day,
    required this.times,
    required this.slots,
    required this.strings,
  });

  final DateTime day;
  final List<DateTime> times;
  final List<ShopTimeSlot> slots;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final draft = ref.watch(bookingProvider);
    final picked = draft.slot != null && sameDay(draft.slot!.start, day);
    final bottom = shellClearance(context, extra: 8);

    bool openAt(DateTime time) {
      return slots.any(
        (slot) =>
            slot.open &&
            slot.start.year == time.year &&
            slot.start.month == time.month &&
            slot.start.day == time.day &&
            slot.start.hour == time.hour &&
            slot.start.minute == time.minute,
      );
    }

    ShopTimeSlot? pickSlot(DateTime time) {
      for (final slot in slots) {
        if (slot.open &&
            slot.start.hour == time.hour &&
            slot.start.minute == time.minute &&
            sameDay(slot.start, time)) {
          return slot;
        }
      }
      return null;
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: palette.stroke)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: palette.stroke,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.freeWindows,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: palette.text),
            ),
            const SizedBox(height: 4),
            Text(
              formatSlotDay(day, DateTime.now(), s, lang),
              style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (times.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(s.noFreeWindows, style: TextStyle(color: palette.muted)),
              )
            else
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final time in times)
                      _TimeCell(
                        label: formatClock(time),
                        open: openAt(time),
                        selected: draft.slot != null &&
                            draft.slot!.start.hour == time.hour &&
                            draft.slot!.start.minute == time.minute &&
                            sameDay(draft.slot!.start, time),
                        busyLabel: s.slotBusy,
                        onTap: () {
                          final slot = pickSlot(time);
                          if (slot != null) {
                            HapticFeedback.selectionClick();
                            ref.read(bookingProvider.notifier).setSlot(slot);
                          }
                        },
                      ),
                  ],
                ),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: picked
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final router = GoRouter.of(context);
                            Navigator.of(context).pop();
                            router.push('/home/confirm');
                          },
                          child: Text(s.next, textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.label,
    required this.open,
    required this.selected,
    required this.busyLabel,
    required this.onTap,
  });

  final String label;
  final bool open;
  final bool selected;
  final String busyLabel;
  final VoidCallback onTap;

  static const _free = Color(0xFF1F9D55);
  static const _busy = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    if (!open) {
      bg = _busy.withValues(alpha: 0.18);
      fg = _busy;
      border = _busy;
    } else if (selected) {
      bg = _free;
      fg = Colors.white;
      border = _free;
    } else {
      bg = _free.withValues(alpha: 0.16);
      fg = _free;
      border = _free;
    }
    return InkWell(
      onTap: open ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected ? 2 : 1.4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _free.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: fg)),
            if (!open) Text(busyLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}
