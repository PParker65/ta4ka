import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/platform_features.dart';
import '../client/client_auction_screen.dart';
import '../widgets/ui.dart';

class ShopOpenJobsScreen extends ConsumerStatefulWidget {
  const ShopOpenJobsScreen({super.key});

  @override
  ConsumerState<ShopOpenJobsScreen> createState() => _ShopOpenJobsScreenState();
}

class _ShopOpenJobsScreenState extends ConsumerState<ShopOpenJobsScreen> {
  int _segment = 0; // 0 requests · 1 auction

  Future<void> _bid(
    BuildContext context,
    WidgetRef ref,
    OpenJobRequest job,
  ) async {
    final account = ref.read(shopAccountProvider);
    final s = ref.read(stringsProvider);
    final price = TextEditingController(text: '2500');
    final note = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.openJobBidPrice),
                  ),
                  TextField(
                    controller: note,
                    decoration: InputDecoration(labelText: s.openJobBidNote),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        initialDate: when,
                      );
                      if (picked != null) {
                        setModal(() => when = picked);
                      }
                    },
                    child: Text(DateFormat('dd.MM.yyyy').format(when)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.confirm),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true) {
      return;
    }
    final uah = int.tryParse(price.text.trim()) ?? 0;
    if (uah <= 0) {
      return;
    }
    ref.read(openJobsProvider.notifier).addBid(
          job.id,
          OpenJobBid(
            id: '${account.catalogShopId}-${DateTime.now().millisecondsSinceEpoch}',
            shopId: account.catalogShopId.isEmpty ? 'local-shop' : account.catalogShopId,
            shopName: account.shopName.isEmpty ? 'Shop' : account.shopName,
            priceUah: uah,
            proposedAt: when,
            note: note.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final open = [
      for (final job in ref.watch(openJobsProvider))
        if (job.status == OpenJobStatus.open)
          if (job.city.isEmpty ||
              account.city.isEmpty ||
              job.city.toLowerCase().contains(account.city.toLowerCase()) ||
              account.city.toLowerCase().contains(job.city.toLowerCase()))
            job,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.shopTabRequests)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(s.openRequestsTitle)),
                ButtonSegment(value: 1, label: Text(s.tabAuction)),
              ],
              selected: {_segment},
              onSelectionChanged: (v) => setState(() => _segment = v.first),
            ),
            const SizedBox(height: 14),
            if (_segment == 1) ...[
              Text(s.auctionShopLead, style: TextStyle(color: palette.muted, height: 1.4)),
              const SizedBox(height: 12),
              const ShopAuctionPanel(),
            ] else ...[
              Text(s.shopOpenJobsLead, style: TextStyle(color: palette.muted, height: 1.4)),
              const SizedBox(height: 16),
              if (open.isEmpty)
                Text(s.shopTodayEmpty, style: TextStyle(color: palette.muted))
              else
                for (final job in open)
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
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(job.details),
                        if (job.city.isNotEmpty)
                          Text('📍 ${job.city}', style: TextStyle(color: palette.muted, fontSize: 12)),
                        if (job.plate.isNotEmpty || job.vin.isNotEmpty)
                          Text(
                            '${job.plate} ${job.vin}'.trim(),
                            style: TextStyle(color: palette.muted, fontSize: 12),
                          ),
                        if (job.photoNote.isNotEmpty) Text('📎 ${job.photoNote}'),
                        const SizedBox(height: 6),
                        Text(
                          '${job.ownerLabel} · ${job.bids.length} ${s.openJobBidsCount}',
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => _bid(context, ref, job),
                          child: Text(s.openJobPropose),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
