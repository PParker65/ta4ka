import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import '../workshop/shop_jobs.dart';
import 'widgets/booking_bits.dart';
import 'widgets/job_status_stage.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final orders = ref
        .watch(ordersProvider)
        .where(
          (order) =>
              order.shopId.isNotEmpty && order.status != JobStatus.cancelled,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabBookings),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: orders.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    s.noBookings,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted, height: 1.4),
                  ),
                ),
              )
            : ListView.separated(
                padding: shellListPadding(context),
                itemCount: orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final shop = shopById(order.shopId);
                  final when = order.scheduledAt;
                  return Dismissible(
                    key: ValueKey(order.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => confirmCancelBooking(
                      context: context,
                      ref: ref,
                      order: order,
                    ),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      decoration: BoxDecoration(
                        color: palette.danger.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        CupertinoIcons.trash,
                        color: palette.danger,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: palette.stroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () =>
                                  context.push('/home/bookings/${order.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shop?.name.of(lang) ?? s.tabShops,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              color: palette.text,
                                            ),
                                          ),
                                        ),
                                        BadgePill(
                                          label: order.hasPendingExtras
                                              ? s.extrasPending
                                              : shopStatusLabel(s, order),
                                        ),
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          tooltip: s.cancelBooking,
                                          onPressed: () =>
                                              confirmCancelBooking(
                                            context: context,
                                            ref: ref,
                                            order: order,
                                          ),
                                          icon: Icon(
                                            CupertinoIcons.trash,
                                            size: 18,
                                            color: palette.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${order.brand} ${order.model} · ${order.plate}',
                                      style: TextStyle(color: palette.muted),
                                    ),
                                    if (when != null)
                                      Text(
                                        DateFormat('d MMM, HH:mm')
                                            .format(when),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: palette.accent,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(formatUah(order.totalUah)),
                                    const SizedBox(height: 12),
                                    JobStatusStage(
                                      order: order,
                                      label: shopStatusLabel(s, order),
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (canBookAgain(order))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: BookAgainButton(
                                compact: true,
                                label: s.bookAgain,
                                onPressed: () => openSameShopBooking(
                                  context: context,
                                  ref: ref,
                                  shopId: order.shopId,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
