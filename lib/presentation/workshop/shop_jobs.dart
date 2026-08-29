import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/live_estimate.dart';
import '../../data/service_book.dart';
import '../../data/service_report.dart';
import '../../domain/models/crm_models.dart';
List<WorkOrder> shopJobs(List<WorkOrder> orders) {
  final items = [
    for (final order in orders)
      if (order.shopId.isNotEmpty && order.status != JobStatus.cancelled) order,
  ]..sort((a, b) {
      final at = a.scheduledAt ?? a.createdAt;
      final bt = b.scheduledAt ?? b.createdAt;
      return at.compareTo(bt);
    });
  return items;
}

bool sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<WorkOrder> jobsToday(List<WorkOrder> orders, DateTime now) {
  return [
    for (final order in shopJobs(orders))
      if (sameCalendarDay(order.scheduledAt ?? order.createdAt, now)) order,
  ];
}

WorkOrder? nextArrivalInQueue(List<WorkOrder> today) {
  final waiting = [
    for (final order in today)
      if (order.status == JobStatus.created) order,
  ];
  if (waiting.isNotEmpty) {
    return waiting.first;
  }
  return null;
}

List<WorkOrder> jobsWithPendingExtras(List<WorkOrder> orders) {
  return [
    for (final order in shopJobs(orders))
      if (order.hasPendingExtras || order.hasLiveDraft) order,
  ];
}

List<WorkOrder> jobsWithUnreadChat(List<WorkOrder> orders) {
  return [
    for (final order in shopJobs(orders))
      if (shopUnread(order)) order,
  ];
}

List<ServiceChatMessage> _channel(
  List<ServiceChatMessage> all, {
  required bool withMaster,
}) {
  return [for (final m in all) if (m.withMaster == withMaster) m];
}

List<ServiceChatMessage> shopThread(WorkOrder order) {
  final raw = order.chat.isNotEmpty ? order.chat : seedServiceChat(order);
  return _channel(raw, withMaster: false);
}

List<ServiceChatMessage> masterThread(WorkOrder order) {
  final fromOrder = _channel(order.chat, withMaster: true);
  if (fromOrder.isNotEmpty) {
    return fromOrder;
  }
  return seedMasterChat(order);
}

bool shopUnread(WorkOrder order) {
  final chat = shopThread(order);
  return chat.isNotEmpty && !chat.last.fromShop;
}

bool masterUnread(WorkOrder order) {
  final chat = masterThread(order);
  return chat.isNotEmpty && !chat.last.fromShop;
}

int shopUnreadCount(List<WorkOrder> orders) {
  return shopJobs(orders).where((o) => shopUnread(o) || masterUnread(o)).length;
}

/// Waiting / in bay / ready — three visible states on booking cards.
enum ShopJobPhase { waiting, working, ready }

ShopJobPhase shopJobPhase(WorkOrder order) {
  return switch (order.status) {
    JobStatus.ready => ShopJobPhase.ready,
    JobStatus.inProgress => ShopJobPhase.working,
    JobStatus.created || JobStatus.approval => ShopJobPhase.waiting,
    JobStatus.cancelled => ShopJobPhase.waiting,
  };
}

String shopStatusLabel(AppStrings s, WorkOrder order) {
  if (order.hasLiveDraft || order.hasPendingExtras) {
    return s.naryadLive;
  }
  return switch (shopJobPhase(order)) {
    ShopJobPhase.waiting => s.shopWaitingClient,
    ShopJobPhase.working => s.statusWork,
    ShopJobPhase.ready => s.statusReady,
  };
}

L _intakeChatText(int km) {
  final formatted = NumberFormat('#,###').format(km);
  return L(
    'Прийом на СТО. Пробіг за одометром: $formatted km. Огляд кузова та рівень палива зафіксовано в сервісній книжці.',
    'Intake complete. Odometer reading: $formatted km. Body check and fuel level logged in the service book.',
    'Приём на СТО. Пробег по одометру: $formatted km. Осмотр кузова и уровень топлива зафиксированы в сервисной книжке.',
  );
}

L _readyChatText(WorkOrder order) {
  final works = [
    for (final line in order.confirmedLines) line.title.uk,
  ].join(', ');
  return L(
    'Роботи виконано: $works. Звіт із фото та відео — у сервісній книжці.',
    'Work completed: $works. Photo and video report is in the service book.',
    'Работы выполнены: $works. Отчёт с фото и видео — в сервисной книжке.',
  );
}

void applyJobPhase(
  OrdersController orders,
  WorkOrder order,
  ShopJobPhase phase, {
  ShopAccountController? shop,
}) {
  switch (phase) {
    case ShopJobPhase.waiting:
      orders.save(
        order.copyWith(
          status: JobStatus.created,
          clearBox: true,
        ),
      );
    case ShopJobPhase.working:
      if (order.status == JobStatus.inProgress) {
        return;
      }
      takeIntoBay(orders, order);
    case ShopJobPhase.ready:
      if (order.status == JobStatus.ready) {
        return;
      }
      markReady(orders, order, shop: shop);
  }
}

void takeIntoBay(OrdersController orders, WorkOrder order) {
  final now = DateTime.now();
  final km = resolveIntakeMileageKm(order);
  final baseChat = order.chat.isNotEmpty ? order.chat : seedServiceChat(order);
  orders.save(
    order.copyWith(
      status: JobStatus.inProgress,
      boxId: order.boxId ?? 'box-2',
      mileage: km,
      intakeAt: now,
      inspection: order.inspection.copyWith(mileageKm: km),
      chat: [
        ...baseChat,
        ServiceChatMessage(
          id: '${order.id}_intake_${now.millisecondsSinceEpoch}',
          fromShop: true,
          at: now,
          text: _intakeChatText(km),
        ),
      ],
    ),
  );
}

void markReady(
  OrdersController orders,
  WorkOrder order, {
  ShopAccountController? shop,
}) {
  final now = DateTime.now();
  final baseChat = order.chat.isNotEmpty ? order.chat : seedServiceChat(order);
  var next = order.copyWith(
    status: JobStatus.ready,
    completedAt: now,
    chat: [
      ...baseChat,
      ServiceChatMessage(
        id: '${order.id}_done_${now.millisecondsSinceEpoch}',
        fromShop: true,
        at: now,
        text: _readyChatText(order),
      ),
    ],
  );
  if (shop != null) {
    next = applyCommissionDelta(
      next,
      accrue: shop.accrueCommission,
    );
  }
  orders.save(next);
}
