import '../domain/models/crm_models.dart';
import '../domain/models/shop_models.dart';
import 'catalog_seed.dart';

ServiceWork? catalogWorkById(String id) {
  for (final work in catalogWorks) {
    if (work.id == id) {
      return work;
    }
  }
  return null;
}

OrderLine lineFromWork(ServiceWork work, {required bool extra, required bool approved}) {
  return OrderLine(
    workId: work.id,
    title: work.title,
    tier: PriceTier.standard,
    priceUah: work.priceStandard,
    minutes: work.minutes,
    extra: extra,
    approved: approved,
  );
}

WorkOrder requestExtraWorks(WorkOrder order, ShopProfile shop, Iterable<String> workIds) {
  final have = {for (final line in order.lines) line.workId};
  final offer = shop.workIds.toSet();
  final add = <OrderLine>[];
  for (final id in workIds) {
    if (have.contains(id) || !offer.contains(id)) {
      continue;
    }
    final work = catalogWorkById(id);
    if (work == null) {
      continue;
    }
    add.add(lineFromWork(work, extra: true, approved: false));
    have.add(id);
  }
  if (add.isEmpty) {
    return order;
  }
  return order.copyWith(
    lines: [...order.lines, ...add],
    status: JobStatus.approval,
  );
}

WorkOrder approveExtraWork(WorkOrder order, String workId) {
  final lines = [
    for (final line in order.lines)
      line.workId == workId ? line.copyWith(approved: true) : line,
  ];
  return order.copyWith(
    lines: lines,
    status: lines.any((line) => !line.approved)
        ? JobStatus.approval
        : (order.boxId != null ? JobStatus.inProgress : JobStatus.created),
  );
}

WorkOrder rejectExtraWork(WorkOrder order, String workId) {
  final lines = [
    for (final line in order.lines)
      if (!(line.workId == workId && !line.approved)) line,
  ];
  return order.copyWith(
    lines: lines,
    status: lines.any((line) => !line.approved)
        ? JobStatus.approval
        : (order.boxId != null ? JobStatus.inProgress : JobStatus.created),
  );
}

String directionsUrl(double lat, double lng, {required bool apple}) {
  if (apple) {
    return 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
  }
  return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
}

String telUrl(String phone) => 'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}';
