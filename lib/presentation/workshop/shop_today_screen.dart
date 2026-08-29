import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/models/crm_models.dart';
import '../client/widgets/booking_bits.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'shop_jobs.dart';

class ShopTodayScreen extends ConsumerWidget {
  const ShopTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final all = ref.watch(ordersProvider);
    final now = DateTime.now();
    final today = jobsToday(all, now);
    final next = nextArrivalInQueue(today);
    final extrasJobs = jobsWithPendingExtras(all);
    final unreadJobs = jobsWithUnreadChat(all);
    final extras = extrasJobs.length;
    final unread = unreadJobs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.shopName.isEmpty ? s.shopDeskTitle : account.shopName),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
          children: [
            Text(
              s.shopDeskLead,
              style: TextStyle(color: palette.muted, height: 1.35),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: s.shopStatVisits,
                    value: '${today.length}',
                    alert: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: s.shopStatExtras,
                    value: '$extras',
                    alert: extras > 0,
                    alertColor: const Color(0xFFE67E22),
                    onTap: () => _openExtrasSheet(context, ref, s, lang, extrasJobs),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: s.shopStatChat,
                    value: '$unread',
                    alert: unread > 0,
                    alertColor: palette.accent,
                    onTap: () => _openMessagesSheet(context, ref, s, lang, unreadJobs),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (today.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  s.shopTodayEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
              )
            else ...[
              if (next != null) ...[
                Text(
                  s.shopNextVisit,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 8),
                _JobCard(order: next, strings: s, featured: true),
                const SizedBox(height: 22),
              ],
              Text(
                s.shopAllToday,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 8),
              for (final order in today) ...[
                _JobCard(
                  order: order,
                  strings: s,
                  featured: false,
                  highlight: order.id == next?.id,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

void _openExtrasSheet(
  BuildContext context,
  WidgetRef ref,
  AppStrings s,
  AppLang lang,
  List<WorkOrder> jobs,
) {
  final palette = paletteOf(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final live = jobsWithPendingExtras(ref.watch(ordersProvider));
          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: GlassPanel(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: palette.stroke,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    s.naryadSheetTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (live.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        s.naryadSheetNone,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: live.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = live[index];
                          final draft = order.draftEstimate;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.carbon.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.accent.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order.brand} ${order.model} · ${order.plate}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${s.naryadTotal}: ${formatUah(order.totalUah + order.draftEstimateUah)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                for (final line in draft.take(4))
                                  Text(
                                    '· ${line.title} · ${formatUah(line.priceUah)}',
                                    style: TextStyle(color: palette.muted, height: 1.3),
                                  ),
                                if (draft.isEmpty)
                                  for (final line in order.pendingLines.take(4))
                                    Text(
                                      '· ${line.title.of(lang)} · ${formatUah(line.priceUah)}',
                                      style: TextStyle(color: palette.muted, height: 1.3),
                                    ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push('/staff/orders/${order.id}');
                                  },
                                  child: Text(s.naryadOpen),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _openMessagesSheet(
  BuildContext context,
  WidgetRef ref,
  AppStrings s,
  AppLang lang,
  List<WorkOrder> jobs,
) {
  final palette = paletteOf(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final live = jobsWithUnreadChat(ref.watch(ordersProvider));
          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: GlassPanel(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: palette.stroke,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    s.shopMessagesSheetTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (live.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        s.shopMessagesNone,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: live.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = live[index];
                          final last = shopThread(order).last;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context.push(
                                  '/staff/chat/${order.id}?side=client',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: palette.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: palette.accent.withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${order.brand} ${order.model} · ${order.plate}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: palette.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      last.text.of(lang),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: palette.muted, height: 1.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      s.shopOpenChat,
                                      style: TextStyle(
                                        color: palette.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.alert = false,
    this.alertColor,
    this.onTap,
  });

  final String label;
  final String value;
  final bool alert;
  final Color? alertColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final tone = alertColor ?? const Color(0xFFE67E22);
    final border = alert ? tone : palette.stroke;
    final bg = alert
        ? tone.withValues(alpha: palette.isDark ? 0.18 : 0.12)
        : palette.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: alert ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: alert ? tone : palette.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: alert ? tone : palette.muted,
                  fontSize: 12,
                  fontWeight: alert ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopJobCard extends StatelessWidget {
  const ShopJobCard({super.key, required this.order, required this.strings, this.featured = false});

  final WorkOrder order;
  final AppStrings strings;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return _JobCard(order: order, strings: strings, featured: featured);
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({
    required this.order,
    required this.strings,
    this.featured = false,
    this.highlight = false,
  });

  final WorkOrder order;
  final AppStrings strings;
  final bool featured;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = paletteOf(context);
    final s = strings;
    final when = order.scheduledAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/staff/orders/${order.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlight || featured
                  ? palette.accent.withValues(alpha: 0.55)
                  : palette.stroke,
              width: featured ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.brand} ${order.model} · ${order.plate}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: featured ? 18 : 16,
                        color: palette.text,
                      ),
                    ),
                  ),
                  BadgePill(label: shopStatusLabel(s, order)),
                ],
              ),
              if (when != null) ...[
                const SizedBox(height: 6),
                Text(
                  DateFormat('d MMM, HH:mm').format(when),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(formatUah(order.totalUah), style: TextStyle(color: palette.muted)),
              if (order.status == JobStatus.created ||
                  order.status == JobStatus.inProgress) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (order.status == JobStatus.created)
                      Expanded(
                        child: FilledButton(
                          onPressed: () => takeIntoBay(ref.read(ordersProvider.notifier), order),
                          child: Text(s.shopTakeInBay),
                        ),
                      )
                    else if (order.status == JobStatus.inProgress)
                      Expanded(
                        child: FilledButton(
                          onPressed: () => markReady(
                            ref.read(ordersProvider.notifier),
                            order,
                            shop: ref.read(shopAccountProvider.notifier),
                          ),
                          child: Text(s.shopMarkReady),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(
                              '/staff/chat/${order.id}?side=client',
                            ),
                        child: Text(s.shopOpenChat),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
