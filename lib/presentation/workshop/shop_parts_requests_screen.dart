import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/platform_features.dart';
import '../widgets/ui.dart';

/// Shop manager inbox: approve master parts requests → supplier → ready.
class ShopPartsRequestsScreen extends ConsumerWidget {
  const ShopPartsRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final items = ref.watch(partsRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.shopPartsApprove)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(
              'Master → approve → supplier → hand out to bay',
              style: TextStyle(color: palette.muted),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Text('—', style: TextStyle(color: palette.muted))
            else
              for (final r in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.partName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${r.carLabel} · VIN ${r.vin.isEmpty ? '—' : r.vin}',
                          style: TextStyle(color: palette.muted),
                        ),
                        Text(
                          '${r.masterName} · ${DateFormat('dd.MM HH:mm').format(r.createdAt)} · ${r.status.name}',
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                        if (r.query.isNotEmpty) Text('«${r.query}»'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (r.status == PartsRequestStatus.pendingShop)
                              FilledButton(
                                onPressed: () => ref
                                    .read(partsRequestsProvider.notifier)
                                    .setStatus(r.id, PartsRequestStatus.ordered),
                                child: Text(s.shopPartsOrder),
                              ),
                            if (r.status == PartsRequestStatus.ordered)
                              FilledButton(
                                onPressed: () => ref
                                    .read(partsRequestsProvider.notifier)
                                    .setStatus(r.id, PartsRequestStatus.ready),
                                child: Text(s.shopPartsReady),
                              ),
                            if (r.status == PartsRequestStatus.pendingShop)
                              TextButton(
                                onPressed: () => ref
                                    .read(partsRequestsProvider.notifier)
                                    .setStatus(
                                      r.id,
                                      PartsRequestStatus.rejected,
                                    ),
                                child: Text(s.orderCancelled),
                              ),
                          ],
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
}
