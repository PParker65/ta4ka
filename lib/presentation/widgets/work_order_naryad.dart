import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/live_estimate.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/platform_features.dart';

enum NaryadMode { master, shop, client }

/// Shared live заказ-наряд: works + parts + running total (shop ↔ client).
class WorkOrderNaryadPanel extends ConsumerStatefulWidget {
  const WorkOrderNaryadPanel({
    super.key,
    required this.order,
    required this.mode,
    this.onConfirmDraft,
    this.onDeclineDraft,
    this.showAuctionCta = false,
    this.onAuction,
  });

  final WorkOrder order;
  final NaryadMode mode;
  final VoidCallback? onConfirmDraft;
  final VoidCallback? onDeclineDraft;
  final bool showAuctionCta;
  final VoidCallback? onAuction;

  @override
  ConsumerState<WorkOrderNaryadPanel> createState() =>
      _WorkOrderNaryadPanelState();
}

class _WorkOrderNaryadPanelState extends ConsumerState<WorkOrderNaryadPanel> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  bool _asPart = true;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  WorkOrder get _live {
    for (final o in ref.watch(ordersProvider)) {
      if (o.id == widget.order.id) {
        return o;
      }
    }
    return widget.order;
  }

  void _save(WorkOrder next) {
    ref.read(ordersProvider.notifier).save(next);
  }

  void _addLine({required String title, required int price, required bool labor}) {
    if (title.trim().isEmpty || price <= 0) {
      return;
    }
    _save(
      addDraftEstimateLine(
        _live,
        draftLine(title: title.trim(), priceUah: price, labor: labor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final order = _live;
    final canEdit = widget.mode == NaryadMode.master || widget.mode == NaryadMode.shop;
    final clientLive = widget.mode == NaryadMode.client && order.hasLiveDraft;
    final naryadTotal = order.totalUah + order.draftEstimateUah;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.doc_text_fill, color: palette.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.naryadTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: palette.text,
                  ),
                ),
              ),
              if (order.hasLiveDraft)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.naryadLive,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.mode == NaryadMode.client
                ? s.naryadClientLead
                : s.naryadShopLead,
            style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (order.confirmedLines.isNotEmpty) ...[
            Text(s.naryadConfirmed, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final line in order.confirmedLines)
              _row(
                palette,
                line.title.of(lang),
                formatUah(line.priceUah),
                muted: true,
              ),
            const SizedBox(height: 10),
          ],
          Text(s.naryadInProgress, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (order.draftEstimate.isEmpty)
            Text(s.naryadEmptyDraft, style: TextStyle(color: palette.muted, fontSize: 13))
          else
            for (final line in order.draftEstimate)
              _row(
                palette,
                '${line.title}${line.labor ? ' · ${s.liveEstimateLabor}' : ' · ${s.liveEstimateParts}'}',
                formatUah(line.priceUah),
                onMinus: canEdit || clientLive
                    ? () => _save(removeDraftEstimateLine(order, line.id))
                    : null,
                onPlus: canEdit || clientLive
                    ? () => _addLine(
                          title: line.title,
                          price: line.priceUah,
                          labor: line.labor,
                        )
                    : null,
              ),
          if (canEdit) ...[
            const SizedBox(height: 14),
            Text(s.naryadAddQuick, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in quickEstimatePresets)
                  ActionChip(
                    label: Text('${preset.$1} · ${formatUah(preset.$2)}'),
                    onPressed: () => _addLine(
                      title: preset.$1,
                      price: preset.$2,
                      labor: preset.$3,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(s.naryadPartsHints, style: TextStyle(color: palette.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hint in suggestParts(''))
                  ActionChip(
                    avatar: const Icon(CupertinoIcons.cube_box, size: 14),
                    label: Text(hint.titleOf(lang)),
                    onPressed: () => _addLine(
                      title: hint.titleOf(lang),
                      price: 1200,
                      labor: false,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(s.liveEstimateParts)),
                ButtonSegment(value: false, label: Text(s.liveEstimateLabor)),
              ],
              selected: {_asPart},
              onSelectionChanged: (v) => setState(() => _asPart = v.first),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _title,
                    decoration: InputDecoration(labelText: s.liveEstimateItem),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.naryadPrice),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final price = int.tryParse(_price.text.trim()) ?? 0;
                    _addLine(
                      title: _title.text,
                      price: price,
                      labor: !_asPart,
                    );
                    _title.clear();
                    _price.clear();
                  },
                  icon: Icon(CupertinoIcons.add_circled_solid, color: palette.accent),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.carbon.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${s.naryadTotal}: ${formatUah(naryadTotal)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: palette.text,
                  ),
                ),
                if (order.hasLiveDraft)
                  Text(
                    '${s.naryadDraftPart}: ${formatUah(order.draftEstimateUah)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                if (widget.mode != NaryadMode.client)
                  Text(
                    s.liveEstimateFeeHint(
                      formatUah(platformFeePreview(naryadTotal)),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (clientLive) ...[
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: widget.onConfirmDraft,
                      child: Text(s.naryadClientConfirm, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: widget.onDeclineDraft,
                      child: Text(s.naryadClientDecline, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.showAuctionCta && widget.onAuction != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onAuction,
                icon: const Icon(CupertinoIcons.hammer, size: 18),
                label: Text(s.auctionFromEstimate),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    AppPalette palette,
    String title,
    String price, {
    bool muted = false,
    VoidCallback? onMinus,
    VoidCallback? onPlus,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: muted ? palette.muted : palette.text,
                height: 1.3,
              ),
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (onMinus != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(CupertinoIcons.minus_circle, size: 22, color: palette.danger),
              onPressed: onMinus,
            ),
          if (onPlus != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(CupertinoIcons.plus_circle, size: 22, color: palette.accent),
              onPressed: onPlus,
            ),
        ],
      ),
    );
  }
}

extension on PartsCatalogHint {
  String titleOf(AppLang lang) {
    return switch (lang) {
      AppLang.uk => titleUk,
      AppLang.en => titleEn,
      AppLang.ru => titleRu,
      AppLang.pl => titleEn,
    };
  }
}
