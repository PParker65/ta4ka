import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/platform_features.dart';
import '../widgets/ui.dart';

class ShopTaxReportScreen extends ConsumerWidget {
  const ShopTaxReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final shopId = account.catalogShopId;
    final orders = [
      for (final order in ref.watch(ordersProvider))
        if (order.status == JobStatus.ready &&
            (shopId.isEmpty || order.shopId == shopId || order.shopId.isEmpty))
          order,
    ];
    final total = orders.fold<int>(0, (sum, o) => sum + o.totalUah);

    return Scaffold(
      appBar: AppBar(title: Text(s.taxReportTitle)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(s.taxReportLead, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 16),
            Container(
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
                    account.shopName.isEmpty ? 'Shop' : account.shopName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(DateFormat('dd.MM.yyyy').format(DateTime.now())),
                  const SizedBox(height: 8),
                  Text(
                    '${orders.length} jobs · ${formatUah(total)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final order in orders)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${order.brand} ${order.model} · ${order.plate}'),
                subtitle: Text(
                  '${order.vin.isEmpty ? '—' : order.vin} · '
                  '${DateFormat('dd.MM.yyyy').format(order.completedAt ?? order.createdAt)}',
                ),
                trailing: Text(formatUah(order.totalUah)),
              ),
          ],
        ),
      ),
    );
  }
}

class ShopVinHistoryScreen extends ConsumerStatefulWidget {
  const ShopVinHistoryScreen({super.key});

  @override
  ConsumerState<ShopVinHistoryScreen> createState() =>
      _ShopVinHistoryScreenState();
}

class _ShopVinHistoryScreenState extends ConsumerState<ShopVinHistoryScreen> {
  final _vin = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _vin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final hits = ordersForVin(ref.watch(ordersProvider), _query);

    return Scaffold(
      appBar: AppBar(title: Text(s.vinHistoryTitle)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(s.vinHistoryLead, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: _vin,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'VIN',
                suffixIcon: IconButton(
                  icon: const Icon(CupertinoIcons.search),
                  onPressed: () => setState(() => _query = _vin.text),
                ),
              ),
              onSubmitted: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            if (_query.isNotEmpty && hits.isEmpty)
              Text('—', style: TextStyle(color: palette.muted))
            else
              for (final order in hits)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.stroke),
                    color: palette.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.brand} ${order.model} · ${order.plate}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'СТО: ${order.shopId.isEmpty ? '—' : order.shopId}',
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt),
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                      for (final line in order.lines)
                        Text('· ${line.title.uk} · ${formatUah(line.priceUah)}'),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class ShopBlacklistScreen extends ConsumerStatefulWidget {
  const ShopBlacklistScreen({super.key});

  @override
  ConsumerState<ShopBlacklistScreen> createState() =>
      _ShopBlacklistScreenState();
}

class _ShopBlacklistScreenState extends ConsumerState<ShopBlacklistScreen> {
  Future<void> _add() async {
    final account = ref.read(shopAccountProvider);
    final key = TextEditingController();
    final label = TextEditingController();
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.read(stringsProvider).blacklistTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: key,
              decoration: const InputDecoration(labelText: 'Phone / login'),
            ),
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: reason,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || key.text.trim().isEmpty || reason.text.trim().isEmpty) {
      return;
    }
    ref.read(blacklistProvider.notifier).add(
          BlacklistEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            clientKey: normalizeClientKey(key.text),
            clientLabel: label.text.trim().isEmpty ? key.text.trim() : label.text.trim(),
            reason: reason.text.trim(),
            shopId: account.catalogShopId,
            shopName: account.shopName.isEmpty ? 'Shop' : account.shopName,
            at: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final items = ref.watch(blacklistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.blacklistTitle),
        actions: [
          IconButton(onPressed: _add, icon: const Icon(CupertinoIcons.add)),
        ],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(s.blacklistLead, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text('—', style: TextStyle(color: palette.muted))
            else
              for (final e in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.clientLabel),
                  subtitle: Text(
                    '${e.reason}\n${e.shopName} · ${DateFormat('dd.MM.yyyy').format(e.at)}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(CupertinoIcons.trash),
                    onPressed: () =>
                        ref.read(blacklistProvider.notifier).remove(e.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
