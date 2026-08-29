import 'package:intl/intl.dart';

import '../core/l10n/app_lang.dart';
import '../domain/models/crm_models.dart';
import 'booking_extras.dart';
import 'catalog_seed.dart';
import 'service_report.dart';

class ServiceWorkLog {
  const ServiceWorkLog({
    required this.line,
    required this.category,
    required this.report,
    required this.performedAt,
    required this.specialty,
  });

  final OrderLine line;
  final RepairCategory category;
  final L report;
  final DateTime performedAt;
  final MasterSpecialty specialty;
}

class ServiceBookVisit {
  const ServiceBookVisit({
    required this.order,
    required this.intakeAt,
    required this.completedAt,
    required this.intakeMileageKm,
    required this.works,
    required this.reportItems,
    required this.notes,
  });

  final WorkOrder order;
  final DateTime intakeAt;
  final DateTime? completedAt;
  final int intakeMileageKm;
  final List<ServiceWorkLog> works;
  final List<ServiceReportItem> reportItems;
  final List<ServiceChatMessage> notes;
}

int resolveIntakeMileageKm(WorkOrder order) {
  final fromInspection = order.inspection.mileageKm;
  if (fromInspection != null && fromInspection > 0) {
    return fromInspection;
  }
  if (order.mileage > 0) {
    return order.mileage;
  }
  final year = order.year > 0 ? order.year : 2018;
  final age = (DateTime.now().year - year).clamp(1, 25);
  final base = age * 14500;
  final tail = order.id.hashCode.abs() % 9000;
  return base + tail;
}

String formatMileageKm(int km) => '${NumberFormat('#,###').format(km)} km';

ServiceWork? _workMeta(String workId) {
  return catalogWorkById(workId) ??
      catalogWorks.cast<ServiceWork?>().firstWhere(
            (work) => work?.id == workId,
            orElse: () => null,
          );
}

DateTime _visitIntakeAt(WorkOrder order) {
  return order.intakeAt ??
      order.scheduledAt ??
      order.createdAt;
}

DateTime? _visitCompletedAt(WorkOrder order) {
  if (order.completedAt != null) {
    return order.completedAt;
  }
  if (order.status == JobStatus.ready) {
    final base = _visitIntakeAt(order);
    return base.add(Duration(minutes: order.etaMinutes + 25));
  }
  return null;
}

List<ServiceWorkLog> buildWorkLogs(WorkOrder order) {
  final intake = _visitIntakeAt(order);
  var offset = 18;
  final logs = <ServiceWorkLog>[];
  for (final line in order.confirmedLines) {
    final meta = _workMeta(line.workId);
    logs.add(
      ServiceWorkLog(
        line: line,
        category: meta?.category ?? order.category,
        report: meta?.olegTip ??
            L(
              'Роботу виконано згідно регламенту СТО. Контроль якості пройдено.',
              'Work completed per shop procedure. Quality check passed.',
              'Работа выполнена по регламенту СТО. Контроль качества пройден.',
            ),
        performedAt: intake.add(Duration(minutes: offset)),
        specialty: meta?.specialty ?? MasterSpecialty.maintenance,
      ),
    );
    offset += line.minutes + 12;
  }
  return logs;
}

ServiceBookVisit buildServiceBookVisit(WorkOrder order) {
  final intakeAt = _visitIntakeAt(order);
  final intakeMileage = order.intakeMileageKm > 0
      ? order.intakeMileageKm
      : resolveIntakeMileageKm(order);
  final chat = order.chat.isNotEmpty ? order.chat : seedServiceChat(order);
  return ServiceBookVisit(
    order: order,
    intakeAt: intakeAt,
    completedAt: _visitCompletedAt(order),
    intakeMileageKm: intakeMileage,
    works: buildWorkLogs(order),
    reportItems: incomingReport(order),
    notes: chat,
  );
}

List<ServiceBookVisit> serviceBookVisits(List<WorkOrder> orders) {
  final visits = [
    for (final order in orders)
      if (order.shopId.isNotEmpty) buildServiceBookVisit(order),
  ];
  visits.sort((a, b) => b.intakeAt.compareTo(a.intakeAt));
  return visits;
}

String tierLabel(AppLang lang, PriceTier tier) {
  return switch (tier) {
    PriceTier.basic => switch (lang) {
        AppLang.uk => 'Базовий',
        AppLang.en => 'Basic',
        AppLang.ru => 'Базовый',
        AppLang.pl => 'Podstawowy',
      },
    PriceTier.standard => switch (lang) {
        AppLang.uk => 'Стандарт',
        AppLang.en => 'Standard',
        AppLang.ru => 'Стандарт',
        AppLang.pl => 'Standard',
      },
    PriceTier.premium => switch (lang) {
        AppLang.uk => 'Преміум',
        AppLang.en => 'Premium',
        AppLang.ru => 'Премиум',
        AppLang.pl => 'Premium',
      },
  };
}
