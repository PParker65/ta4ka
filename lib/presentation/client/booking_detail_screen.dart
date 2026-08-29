import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../data/booking_extras.dart';
import '../../data/live_estimate.dart';
import '../../data/open_link.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/marked_defect_photo.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import '../widgets/work_order_naryad.dart';
import '../workshop/shop_jobs.dart';
import 'booking_format.dart';
import 'widgets/booking_bits.dart';
import 'widgets/service_report_panel.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  WorkOrder? _find(List<WorkOrder> orders) {
    for (final order in orders) {
      if (order.id == widget.orderId) {
        return order;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final order = _find(ref.watch(ordersProvider));
    final shop = shopById(order?.shopId ?? '');
    if (order == null || shop == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tabBookings)),
        body: const Center(child: Text('—')),
      );
    }

    final when = order.scheduledAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name.of(lang)),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context, extra: 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.bookingLocked,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: palette.text,
                          ),
                        ),
                      ),
                      BadgePill(
                        label: shopStatusLabel(s, order),
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
                      formatWhen(when, lang),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    shop.address.of(lang),
                    style: TextStyle(color: palette.muted, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.phone,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (canBookAgain(order)) ...[
              BookAgainButton(
                label: s.bookAgain,
                onPressed: () => openSameShopBooking(
                  context: context,
                  ref: ref,
                  shopId: order.shopId,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      openLink(
                        directionsUrl(
                          shop.lat,
                          shop.lng,
                          apple: prefersAppleMaps,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    icon: const Icon(CupertinoIcons.location_solid, size: 16),
                    label: Text(s.getThere,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openLink(telUrl(shop.phone)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    icon: const Icon(CupertinoIcons.phone_fill, size: 16),
                    label: Text(s.callShop,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ServiceReportPanel(order: order),
            const SizedBox(height: 22),
            WorkOrderNaryadPanel(
              order: order,
              mode: NaryadMode.client,
              showAuctionCta: order.hasLiveDraft || order.draftEstimateUah > 0,
              onConfirmDraft: () {
                var next = confirmDraftEstimate(order);
                next = applyCommissionDelta(
                  next,
                  accrue:
                      ref.read(shopAccountProvider.notifier).accrueCommission,
                );
                ref.read(ordersProvider.notifier).save(next);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.naryadClientConfirm)),
                );
              },
              onDeclineDraft: () {
                ref
                    .read(ordersProvider.notifier)
                    .save(rejectDraftEstimate(order));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.naryadClientDecline)),
                );
              },
              onAuction: () {
                ref.read(auctionDraftProvider.notifier).state = AuctionDraft(
                  orderId: order.id,
                  plate: order.plate,
                  vin: order.vin,
                  brand: order.brand,
                  model: order.model,
                  estimateUah: order.totalUah + order.draftEstimateUah,
                  shopId: order.shopId,
                );
                ref.read(clientTabProvider.notifier).state = ClientTabs.auction;
                context.go('/home');
              },
            ),
            if (order.defectPhotos.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                s.defectPhotoTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 10),
              for (final photo in order.defectPhotos) ...[
                MarkedDefectPhotoView(photo: photo),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 22),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  children: [
                    Text(
                      s.confirmedWorks,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final line in order.confirmedLines)
                      _lineTile(palette, line.title.of(lang),
                          formatUah(line.priceUah)),
                    const SizedBox(height: 8),
                    Text(
                      formatUah(order.totalUah),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextButton.icon(
                      onPressed: () async {
                        final gone = await confirmCancelBooking(
                          context: context,
                          ref: ref,
                          order: order,
                        );
                        if (!gone || !context.mounted) return;
                        Navigator.of(context).maybePop();
                      },
                      icon: Icon(
                        CupertinoIcons.trash,
                        size: 16,
                        color: palette.danger.withValues(alpha: 0.85),
                      ),
                      label: Text(
                        s.cancelBooking,
                        style: TextStyle(
                          color: palette.danger.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineTile(AppPalette palette, String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                Text(title, style: TextStyle(color: palette.text, height: 1.3)),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
