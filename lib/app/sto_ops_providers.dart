import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parts_market.dart';
import '../domain/models/crm_models.dart';
import '../domain/models/sto_ops.dart';

List<WarehouseItem> seedWarehouse() {
  return [
    for (final item in kPartsCatalog.take(10))
      WarehouseItem(
        id: item.id,
        oem: item.oem,
        title: item.titleUk,
        bin: 'A-${item.id.hashCode.abs() % 12 + 1}',
        qty: 2 + item.id.length % 8,
        costUah: cheapest(item).buyUah,
        groupId: item.group.id,
      ),
  ];
}

List<BayPlan> seedBays() => const [
      BayPlan(bayId: 'lift-1', label: 'Підйомник 1'),
      BayPlan(bayId: 'lift-2', label: 'Підйомник 2'),
      BayPlan(bayId: 'pit-1', label: 'Яма'),
      BayPlan(bayId: 'align', label: 'Розвал'),
    ];

final warehouseProvider =
    StateNotifierProvider<WarehouseController, List<WarehouseItem>>((ref) {
  return WarehouseController();
});

class WarehouseController extends StateNotifier<List<WarehouseItem>> {
  WarehouseController() : super(seedWarehouse());

  void receive(String id, int qty) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(qty: item.qty + qty) else item,
    ];
  }

  void reserve(String id, int qty) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(reserved: (item.reserved + qty).clamp(0, item.qty))
        else
          item,
    ];
  }

  void stockIn(PartsItem part, PartsOffer offer) {
    final existing = [
      for (final item in state)
        if (item.id == part.id) item,
    ];
    if (existing.isEmpty) {
      state = [
        ...state,
        WarehouseItem(
          id: part.id,
          oem: part.oem,
          title: part.titleUk,
          bin: 'IN',
          qty: 1,
          costUah: offer.buyUah,
          groupId: part.group.id,
        ),
      ];
      return;
    }
    receive(part.id, 1);
  }
}

final inspectionsProvider =
    StateNotifierProvider<InspectionsController, Map<String, InspectionRun>>(
        (ref) {
  return InspectionsController();
});

class InspectionsController extends StateNotifier<Map<String, InspectionRun>> {
  InspectionsController() : super(const {});

  InspectionRun forOrder(String orderId) =>
      state[orderId] ?? InspectionRun(orderId: orderId);

  void mark(String orderId, ChecklistMark mark) {
    final run = forOrder(orderId).upsert(mark);
    state = {...state, orderId: run};
  }
}

final jobClocksProvider =
    StateNotifierProvider<JobClocksController, Map<String, JobClock>>((ref) {
  return JobClocksController();
});

class JobClocksController extends StateNotifier<Map<String, JobClock>> {
  JobClocksController() : super(const {});

  JobClock forOrder(String orderId) =>
      state[orderId] ?? JobClock(orderId: orderId);

  void toggle(String orderId) {
    final now = DateTime.now();
    final cur = forOrder(orderId);
    if (cur.running) {
      state = {
        ...state,
        orderId: JobClock(
          orderId: orderId,
          elapsed: cur.live(now),
        ),
      };
    } else {
      state = {
        ...state,
        orderId: JobClock(
          orderId: orderId,
          startedAt: now,
          elapsed: cur.elapsed,
        ),
      };
    }
  }
}

final baysProvider =
    StateNotifierProvider<BaysController, List<BayPlan>>((ref) {
  return BaysController();
});

class BaysController extends StateNotifier<List<BayPlan>> {
  BaysController() : super(seedBays());

  void assign(String bayId, String? orderId) {
    state = [
      for (final bay in state)
        if (bay.bayId == bayId)
          bay.copyWith(orderId: orderId, clear: orderId == null)
        else if (orderId != null && bay.orderId == orderId)
          bay.copyWith(clear: true)
        else
          bay,
    ];
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersController, List<ServiceReminder>>((ref) {
  return RemindersController();
});

class RemindersController extends StateNotifier<List<ServiceReminder>> {
  RemindersController() : super(_seed());

  static List<ServiceReminder> _seed() {
    final now = DateTime.now();
    return [
      ServiceReminder(
        id: 'r1',
        plate: 'AA1234BB',
        vin: 'WVWZZZ3CZWE123456',
        client: 'Олег К.',
        dueKm: 145000,
        dueAt: now.add(const Duration(days: 12)),
        work: 'Олива + фільтри',
      ),
      ServiceReminder(
        id: 'r2',
        plate: 'KA9088CE',
        vin: 'WBA3A5C50DF123456',
        client: 'Марина С.',
        dueKm: 82000,
        dueAt: now.add(const Duration(days: 4)),
        work: 'Колодки / диски',
      ),
    ];
  }

  void markSent(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(sent: true) else r,
    ];
  }

  void addFromOrder(WorkOrder order) {
    final due = (order.mileage > 0 ? order.mileage : 80000) + 10000;
    state = [
      ServiceReminder(
        id: '${order.id}_to',
        plate: order.plate,
        vin: order.vin,
        client: '${order.brand} ${order.model}',
        dueKm: due,
        dueAt: DateTime.now().add(const Duration(days: 180)),
        work: order.confirmedLines.isEmpty
            ? 'ТО'
            : order.confirmedLines.first.title.uk,
      ),
      ...state,
    ];
  }
}

int laborUah(int minutes, {int rate = 650}) {
  if (minutes <= 0) return 0;
  return ((minutes / 60) * rate).round();
}
