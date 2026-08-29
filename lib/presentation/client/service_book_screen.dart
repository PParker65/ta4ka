import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'booking_format.dart';
import 'widgets/booking_bits.dart';

class ServiceBookScreen extends ConsumerWidget {
  const ServiceBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final draft = ref.watch(bookingProvider);
    final orders = ref
        .watch(ordersProvider)
        .where((order) => order.shopId.isNotEmpty)
        .toList()
      ..sort((a, b) {
        final aAt = a.scheduledAt ?? a.createdAt;
        final bAt = b.scheduledAt ?? b.createdAt;
        return bAt.compareTo(aAt);
      });

    final latest = orders.isNotEmpty ? orders.first : null;
    final brand = latest?.brand ?? draft.brand;
    final model = latest?.model ?? draft.model;
    final plate = latest?.plate ?? draft.plate;
    final mileage = latest?.mileage ?? latest?.inspection.mileageKm;
    final vin = latest?.vin ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabServiceBook),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context),
          children: [
            _ServiceBookCover(
              strings: s,
              brand: brand,
              model: model,
              plate: plate,
              mileage: mileage,
              vin: vin,
              entries: orders.length,
            ),
            const SizedBox(height: 22),
            _SectionTitle(s.serviceBookApps),
            const SizedBox(height: 10),
            _AppsGrid(strings: s, lang: lang),
            const SizedBox(height: 22),
            _SectionTitle(s.serviceBookHistory),
            const SizedBox(height: 10),
            if (orders.isEmpty)
              _EmptyHistory(message: s.serviceBookEmpty)
            else
              ...[
                for (var i = 0; i < orders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _HistoryEntry(
                    order: orders[i],
                    strings: s,
                    lang: lang,
                    onTap: () => context.push('/home/bookings/${orders[i].id}'),
                    onBookAgain: canBookAgain(orders[i])
                        ? () => openSameShopBooking(
                              context: context,
                              ref: ref,
                              shopId: orders[i].shopId,
                            )
                        : null,
                  ),
                ],
              ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 0.6,
        color: palette.muted,
      ),
    );
  }
}

class _ServiceBookCover extends StatelessWidget {
  const _ServiceBookCover({
    required this.strings,
    required this.brand,
    required this.model,
    required this.plate,
    required this.mileage,
    required this.vin,
    required this.entries,
  });

  final AppStrings strings;

  final String brand;
  final String model;
  final String plate;
  final int? mileage;
  final String vin;
  final int entries;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final vehicle = [brand, model].where((part) => part.trim().isNotEmpty).join(' ');
    final subtitle = vehicle.isEmpty ? strings.serviceBookCoverLead : vehicle;

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Icon(CupertinoIcons.book_fill, color: palette.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.serviceBookTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: palette.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: palette.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              _DealerStamp(label: strings.serviceBookStamp),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (plate.trim().isNotEmpty) _MetaChip(icon: CupertinoIcons.number, label: plate),
              if (mileage != null && mileage! > 0)
                _MetaChip(
                  icon: CupertinoIcons.speedometer,
                  label: '${NumberFormat('#,###').format(mileage)} km',
                ),
              if (vin.trim().isNotEmpty) _MetaChip(icon: CupertinoIcons.barcode, label: vin),
              _MetaChip(
                icon: CupertinoIcons.list_bullet,
                label: strings.serviceBookEntries(entries),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealerStamp extends StatelessWidget {
  const _DealerStamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: palette.accent,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.carbon,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppsGrid extends StatelessWidget {
  const _AppsGrid({required this.strings, required this.lang});

  final AppStrings strings;
  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final tiles = [
      _AppTileData(
        icon: CupertinoIcons.gauge_badge_plus,
        title: strings.serviceBookTuning,
        subtitle: strings.serviceBookSoon,
        accent: const Color(0xFF7C5CFF),
      ),
      _AppTileData(
        icon: CupertinoIcons.wrench,
        title: strings.serviceBookParts,
        subtitle: strings.serviceBookSoon,
        accent: const Color(0xFF1B9E4B),
      ),
      _AppTileData(
        icon: CupertinoIcons.doc_text,
        title: strings.serviceBookDocs,
        subtitle: strings.serviceBookSoon,
        accent: const Color(0xFF2F80ED),
      ),
      _AppTileData(
        icon: CupertinoIcons.chart_bar,
        title: strings.serviceBookStats,
        subtitle: strings.serviceBookSoon,
        accent: const Color(0xFFE67E22),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return Opacity(
          opacity: 0.72,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tile.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tile.icon, color: tile.accent, size: 20),
                ),
                const Spacer(),
                Text(
                  tile.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tile.subtitle,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppTileData {
  const _AppTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Text(
        message,
        style: TextStyle(color: palette.muted, height: 1.45),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    required this.order,
    required this.strings,
    required this.lang,
    required this.onTap,
    this.onBookAgain,
  });

  final WorkOrder order;
  final AppStrings strings;
  final AppLang lang;
  final VoidCallback onTap;
  final VoidCallback? onBookAgain;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final shop = shopById(order.shopId);
    final when = order.scheduledAt ?? order.createdAt;
    final works = order.confirmedLines;
    final status = _historyStatus(strings, order.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(order.status, palette),
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface, width: 2),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: palette.stroke,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.stroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('d MMM yyyy · HH:mm').format(when),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            BadgePill(label: status),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(
                          shop?.name.of(lang) ?? strings.tabShops,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: palette.text,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Text(
                          '${order.brand} ${order.model} · ${order.plate}',
                          style: TextStyle(color: palette.muted),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Text(
                          categoryLabel(strings, order.category),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                      ),
                      if (works.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final line in works.take(4))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 14,
                                        color: palette.accent.withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          line.title.of(lang),
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.35,
                                            color: palette.text,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (works.length > 4)
                                Text(
                                  strings.serviceBookMoreWorks(works.length - 4),
                                  style: TextStyle(fontSize: 12, color: palette.muted),
                                ),
                            ],
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  formatUah(order.totalUah),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.text,
                                  ),
                                ),
                                if (order.mileage > 0 ||
                                    order.inspection.mileageKm != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '· ${NumberFormat('#,###').format(order.inspection.mileageKm ?? order.mileage)} km',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (onBookAgain != null) ...[
                              const SizedBox(height: 12),
                              BookAgainButton(
                                compact: true,
                                label: strings.bookAgain,
                                onPressed: onBookAgain!,
                              ),
                            ],
                          ],
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
    );
  }
}

Color _statusColor(JobStatus status, AppPalette palette) {
  return switch (status) {
    JobStatus.ready => const Color(0xFF1B9E4B),
    JobStatus.inProgress => palette.accent,
    JobStatus.approval => const Color(0xFFE67E22),
    JobStatus.created => palette.muted,
    JobStatus.cancelled => palette.muted,
  };
}

String _historyStatus(AppStrings s, JobStatus status) {
  return switch (status) {
    JobStatus.ready => s.serviceBookDone,
    JobStatus.inProgress => s.statusWork,
    JobStatus.approval => s.extrasPending,
    JobStatus.created => s.awaitingVisit,
    JobStatus.cancelled => s.orderCancelled,
  };
}
