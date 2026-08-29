import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/models/crm_models.dart';
import '../client/widgets/booking_bits.dart';
import '../client/widgets/job_status_stage.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'shop_jobs.dart';

class ShopJobsScreen extends ConsumerWidget {
  const ShopJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final jobs = shopJobs(ref.watch(ordersProvider)).reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabBookings),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: jobs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    s.shopNoJobs,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted, height: 1.4),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = jobs[index];
                  final when = order.scheduledAt;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => context.push('/staff/orders/${order.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: palette.stroke),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            JobStatusStage(
                              order: order,
                              label: shopStatusLabel(s, order),
                              compact: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${order.brand} ${order.model} · ${order.plate}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Status taps must not open the order card.
                            GestureDetector(
                              onTap: () {},
                              child: JobPhaseStrip(order: order, strings: s),
                            ),
                            const SizedBox(height: 8),
                            if (when != null)
                              Text(
                                DateFormat('d MMM, HH:mm').format(when),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                ),
                              ),
                            Text(
                              formatUah(order.totalUah),
                              style: TextStyle(color: palette.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class JobPhaseStrip extends ConsumerWidget {
  const JobPhaseStrip({
    super.key,
    required this.order,
    required this.strings,
    this.clickable = true,
  });

  final WorkOrder order;
  final AppStrings strings;
  final bool clickable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = shopJobPhase(order);

    Widget chip({
      required String label,
      required bool active,
      required Color color,
      Color? foreground,
      required ShopJobPhase target,
    }) {
      final pill = BadgePill(
        label: label,
        active: active,
        color: color,
        foreground: foreground,
      );
      if (!clickable) {
        return pill;
      }
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () {
            applyJobPhase(
              ref.read(ordersProvider.notifier),
              order,
              target,
              shop: ref.read(shopAccountProvider.notifier),
            );
          },
          child: pill,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip(
          label: strings.shopWaitingClient,
          active: phase == ShopJobPhase.waiting,
          color: const Color(0xFFE67E22),
          target: ShopJobPhase.waiting,
        ),
        chip(
          label: strings.statusWork,
          active: phase == ShopJobPhase.working,
          color: const Color(0xFF27AE60),
          target: ShopJobPhase.working,
        ),
        chip(
          label: strings.statusReady,
          active: phase == ShopJobPhase.ready,
          color: const Color(0xFF1B1B1B),
          foreground:
              phase == ShopJobPhase.ready ? const Color(0xFF2ECC71) : null,
          target: ShopJobPhase.ready,
        ),
      ],
    );
  }
}
