import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/sto_ops_providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/parts_market.dart';
import '../../data/vin_decode.dart';
import '../../domain/models/platform_features.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class ShopPartsHubScreen extends ConsumerStatefulWidget {
  const ShopPartsHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ShopPartsHubScreen> createState() => _ShopPartsHubScreenState();
}

class _ShopPartsHubScreenState extends ConsumerState<ShopPartsHubScreen> {
  final _vin = TextEditingController();
  final _query = TextEditingController();
  VinDecode? _decoded;

  @override
  void dispose() {
    _vin.dispose();
    _query.dispose();
    super.dispose();
  }

  void _decode() {
    setState(() => _decoded = decodeVin(_vin.text));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final hits = searchPartsMarket(_query.text);
    final decoded = _decoded;

    final body = ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, widget.embedded ? 24 : 108),
      children: [
        Text(s.opsPartsLead, style: TextStyle(color: palette.muted, height: 1.35)),
        const SizedBox(height: 12),
        TextField(
          controller: _vin,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _decode(),
          decoration: InputDecoration(
            labelText: s.opsVinLabel,
            prefixIcon: const Icon(CupertinoIcons.number),
            suffixIcon: IconButton(
              icon: const Icon(CupertinoIcons.search),
              onPressed: _decode,
            ),
          ),
        ),
        if (decoded != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.carbon,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.stroke),
            ),
            child: Text(
              decoded.ok
                  ? '${decoded.make}${decoded.year != null ? ' · ${decoded.year}' : ''} · ${decoded.region}'
                      '${decoded.modelHint.isNotEmpty ? '\n${s.opsVinWmi}: ${decoded.modelHint}' : ''}'
                  : s.opsVinUnknown,
              style: TextStyle(color: palette.text, height: 1.35, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _query,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: s.opsPartsQuery,
            hintText: 'OEM / колодки / ШРУС / MANN',
            prefixIcon: const Icon(CupertinoIcons.search),
          ),
        ),
        const SizedBox(height: 16),
        for (final item in hits)
          _PartCard(item: item, lang: lang),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsPartsTitle),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(child: body),
    );
  }
}

class _PartCard extends ConsumerWidget {
  const _PartCard({required this.item, required this.lang});

  final PartsItem item;
  final AppLang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final best = cheapest(item);
    final markup = item.group.markup;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title(lang),
            style: TextStyle(fontWeight: FontWeight.w800, color: palette.text),
          ),
          const SizedBox(height: 2),
          Text(
            'OEM ${item.oem} · ${s.opsMarkup} ×${markup.toStringAsFixed(2)}',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final offer in item.offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${offer.supplier.name} · ${offer.brand}\n'
                      '${offer.sku} · ${offer.qty} шт · ${offer.days == 0 ? s.opsToday : '${offer.days} д'}',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: offer.sku == best.sku ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatUah(offer.buyUah), style: TextStyle(color: palette.muted, fontSize: 11)),
                      Text(
                        formatUah(offer.sellUah(markup)),
                        style: TextStyle(fontWeight: FontWeight.w800, color: palette.accent),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: s.opsOrderPart,
                    onPressed: () {
                      ref.read(warehouseProvider.notifier).stockIn(item, offer);
                      ref.read(partsRequestsProvider.notifier).upsert(
                            PartsRequest(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              masterId: 'shop',
                              masterName: offer.supplier.name,
                              partName: '${item.title(lang)} · ${offer.brand}',
                              createdAt: DateTime.now(),
                              vin: '',
                              carLabel: item.oem,
                              query: offer.sku,
                              status: PartsRequestStatus.ordered,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${s.opsOrdered} · ${offer.supplier.name}')),
                      );
                    },
                    icon: Icon(CupertinoIcons.cart_badge_plus, color: palette.accent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
