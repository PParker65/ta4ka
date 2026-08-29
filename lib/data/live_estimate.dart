import '../core/l10n/app_lang.dart';
import '../domain/models/crm_models.dart';
import '../domain/shop_commission.dart';

DraftEstimateLine draftLine({
  required String title,
  required int priceUah,
  required bool labor,
}) {
  return DraftEstimateLine(
    id: 'd_${DateTime.now().microsecondsSinceEpoch}',
    title: title,
    priceUah: priceUah,
    labor: labor,
    at: DateTime.now(),
  );
}

WorkOrder addDraftEstimateLine(WorkOrder order, DraftEstimateLine line) {
  return order.copyWith(draftEstimate: [...order.draftEstimate, line]);
}

WorkOrder removeDraftEstimateLine(WorkOrder order, String lineId) {
  return order.copyWith(
    draftEstimate: [
      for (final line in order.draftEstimate)
        if (line.id != lineId) line,
    ],
  );
}

/// Client confirms live draft → approved extras on the order + clear draft.
WorkOrder confirmDraftEstimate(WorkOrder order) {
  if (order.draftEstimate.isEmpty) {
    return order;
  }
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final add = <OrderLine>[
    for (var i = 0; i < order.draftEstimate.length; i++)
      OrderLine(
        workId: 'draft_${stamp}_$i',
        title: L(
          order.draftEstimate[i].title,
          order.draftEstimate[i].title,
          order.draftEstimate[i].title,
        ),
        tier: PriceTier.standard,
        priceUah: order.draftEstimate[i].priceUah,
        minutes: order.draftEstimate[i].labor ? 60 : 0,
        approved: true,
        extra: true,
      ),
  ];
  return order.copyWith(
    lines: [...order.lines, ...add],
    draftEstimate: const [],
    status: order.boxId != null ? JobStatus.inProgress : JobStatus.approval,
  );
}

WorkOrder rejectDraftEstimate(WorkOrder order) {
  return order.copyWith(draftEstimate: const []);
}

/// Accrue 5% only on the uncharged portion of the confirmed total.
WorkOrder applyCommissionDelta(
  WorkOrder order, {
  required void Function(int deltaUah) accrue,
}) {
  final total = order.totalUah;
  final delta = total - order.commissionBaseUah;
  if (delta <= 0) {
    return order;
  }
  accrue(delta);
  return order.copyWith(commissionBaseUah: total);
}

int platformFeePreview(int uah) => ShopCommission.feeFromTotalUah(uah);

const quickEstimatePresets = <(String, int, bool)>[
  ('Колодки', 1800, false),
  ('Робота', 1000, true),
  ('Диски', 3200, false),
  ('Олія + фільтр', 1500, false),
  ('Діагностика', 800, true),
  ('ШРУС', 4500, false),
  ('Кульова', 1200, false),
];
