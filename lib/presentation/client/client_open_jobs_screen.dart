import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/booking_extras.dart';
import '../../data/open_link.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/platform_features.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class ClientOpenJobsScreen extends ConsumerStatefulWidget {
  const ClientOpenJobsScreen({super.key});

  @override
  ConsumerState<ClientOpenJobsScreen> createState() =>
      _ClientOpenJobsScreenState();
}

class _ClientOpenJobsScreenState extends ConsumerState<ClientOpenJobsScreen> {
  Future<void> _createRequest() async {
    final session = ref.read(authProvider);
    final s = ref.read(stringsProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.signIn)),
      );
      return;
    }
    final title = TextEditingController();
    final details = TextEditingController();
    final plate = TextEditingController();
    final vin = TextEditingController();
    final city = TextEditingController(
      text: ref.read(shopAccountProvider).city.isEmpty
          ? 'Warsaw'
          : ref.read(shopAccountProvider).city,
    );
    final media = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.openRequestsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: title,
                  decoration: InputDecoration(labelText: s.openJobFieldTitle),
                ),
                TextField(
                  controller: details,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: s.openJobFieldDetails),
                ),
                TextField(
                  controller: city,
                  decoration: InputDecoration(labelText: s.openJobFieldCity),
                ),
                TextField(
                  controller: plate,
                  decoration: InputDecoration(labelText: s.plate),
                ),
                TextField(
                  controller: vin,
                  decoration: InputDecoration(labelText: s.vin),
                ),
                TextField(
                  controller: media,
                  decoration: InputDecoration(labelText: s.openJobFieldMedia),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(s.confirm),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true || title.text.trim().isEmpty) {
      return;
    }
    ref.read(openJobsProvider.notifier).upsert(
          OpenJobRequest(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            ownerLogin: session.login,
            ownerLabel: session.displayName.isEmpty
                ? session.login
                : session.displayName,
            title: title.text.trim(),
            details: details.text.trim(),
            createdAt: DateTime.now(),
            plate: plate.text.trim(),
            vin: vin.text.trim(),
            photoNote: media.text.trim(),
            city: city.text.trim(),
          ),
        );
  }

  Future<void> _acceptBid(OpenJobRequest job, OpenJobBid bid) async {
    final order = WorkOrder(
      id: 'oj-${DateTime.now().millisecondsSinceEpoch}',
      plate: job.plate,
      brand: job.brand.isEmpty ? '—' : job.brand,
      model: job.model.isEmpty ? job.title : job.model,
      mileage: 0,
      vin: job.vin,
      category: RepairCategory.diagnostics,
      lines: [
        OrderLine(
          workId: 'open-job',
          title: L(job.title, job.title, job.title),
          tier: PriceTier.standard,
          priceUah: bid.priceUah,
          minutes: 60,
        ),
      ],
      status: JobStatus.created,
      createdAt: DateTime.now(),
      shopId: bid.shopId,
      clientLogin: job.ownerLogin,
      scheduledAt: bid.proposedAt,
    );
    ref.read(ordersProvider.notifier).save(order);
    ref.read(openJobsProvider.notifier).award(job.id, bid.id, order.id);
  }

  String _statusLabel(AppStrings s, OpenJobRequest job) {
    return switch (job.status) {
      OpenJobStatus.open => s.openJobStatusOpen,
      OpenJobStatus.awarded => s.openJobStatusAwarded,
      OpenJobStatus.closed => s.openJobStatusClosed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final session = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider);
    ref.listen<List<WorkOrder>>(ordersProvider, (_, next) {
      ref.read(openJobsProvider.notifier).syncWithOrders(next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(openJobsProvider.notifier).syncWithOrders(orders);
    });

    final active = <OpenJobRequest>[];
    final done = <OpenJobRequest>[];
    for (final job in ref.watch(openJobsProvider)) {
      if (session == null || job.ownerLogin != session.login) {
        continue;
      }
      if (job.status == OpenJobStatus.closed) {
        done.add(job);
      } else {
        active.add(job);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.openRequestsTitle),
        actions: [
          IconButton(
            onPressed: _createRequest,
            icon: const Icon(CupertinoIcons.add),
          ),
          const AppBarTools(),
        ],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context, extra: 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.carbon.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.openRequestsInfoTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.openRequestsInfoBody,
                    style: TextStyle(color: palette.muted, height: 1.45, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _createRequest,
              icon: const Icon(CupertinoIcons.doc_on_clipboard),
              label: Text(s.openRequestsCreate),
            ),
            const SizedBox(height: 22),
            Text(s.openRequestsActiveTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (active.isEmpty)
              Text(s.openRequestsEmpty, style: TextStyle(color: palette.muted))
            else
              for (final job in active) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.stroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(job.details, style: TextStyle(color: palette.muted)),
                      if (job.city.isNotEmpty)
                        Text(
                          '📍 ${job.city}',
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                      if (job.photoNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('📎 ${job.photoNote}'),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${_statusLabel(s, job)} · ${DateFormat('dd.MM HH:mm').format(job.createdAt)}',
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                      if (job.status == OpenJobStatus.open) ...[
                        const SizedBox(height: 10),
                        for (final bid in job.bids)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bid.shopName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  '${formatUah(bid.priceUah)} · ${DateFormat('dd.MM HH:mm').format(bid.proposedAt)}'
                                  '${bid.note.isEmpty ? '' : '\n${bid.note}'}',
                                  style: TextStyle(color: palette.muted, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                _ShopReachRow(shopId: bid.shopId, strings: s),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _acceptBid(job, bid),
                                    child: Text(s.openJobAcceptDeal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (job.bids.isEmpty)
                          Text(
                            s.openJobWaiting,
                            style: TextStyle(color: palette.muted),
                          ),
                      ],
                      if (job.status == OpenJobStatus.awarded) ...[
                        Text(
                          s.openJobInProgress,
                          style: TextStyle(color: palette.accent, fontWeight: FontWeight.w600),
                        ),
                        if (job.awardedShopId != null && job.awardedShopId!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ShopReachRow(shopId: job.awardedShopId!, strings: s),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            if (done.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(s.openRequestsDoneTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(s.openRequestsDoneLead, style: TextStyle(color: palette.muted, fontSize: 13)),
              const SizedBox(height: 8),
              for (final job in done)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(job.title),
                  subtitle: Text(_statusLabel(s, job)),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(clientTabProvider.notifier).state = ClientTabs.serviceBook,
                    child: Text(s.tabServiceBook),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopReachRow extends StatelessWidget {
  const _ShopReachRow({required this.shopId, required this.strings});

  final String shopId;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final shop = shopById(shopId);
    if (shop == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => openLink(
              directionsUrl(shop.lat, shop.lng, apple: prefersAppleMaps),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(CupertinoIcons.location_solid, size: 16),
            label: Text(strings.getThere, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => openLink(telUrl(shop.phone)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(CupertinoIcons.phone_fill, size: 16),
            label: Text(strings.callShop, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
