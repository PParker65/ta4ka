import '../../app/providers.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/booking_extras.dart';
import '../../data/catalog_seed.dart';
import '../../domain/models/crm_models.dart';

void seedDeskBookingsIfEmpty(OrdersController orders, List<WorkOrder> current) {
  if (current.any((order) => order.shopId.isNotEmpty)) {
    return;
  }
  final work = catalogWorks.firstWhere((item) => item.id == 'diag-comp');
  final pads = catalogWorks.firstWhere((item) => item.id == 'pads');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final at = today.add(const Duration(hours: 14, minutes: 30));

  orders.save(
    WorkOrder(
      id: 'desk-demo-1',
      plate: 'WX 1842K',
      brand: 'BMW',
      model: 'M5',
      year: 2021,
      mileage: 64200,
      vin: 'WBSDEMO000000001',
      category: RepairCategory.diagnostics,
      shopId: 'pitlane',
      status: JobStatus.created,
      createdAt: today.subtract(const Duration(hours: 6)),
      scheduledAt: today.add(const Duration(hours: 11)),
      lines: [lineFromWork(work, extra: false, approved: true)],
      chat: [
        ServiceChatMessage(
          id: 'desk-demo-1_c0',
          fromShop: true,
          at: today.add(const Duration(hours: 10)),
          text: const L(
            'Чекаємо на вас у боксі.',
            'We are waiting for you in the bay.',
            'Ждём вас в боксе.',
          ),
        ),
        ServiceChatMessage(
          id: 'desk-demo-1_client_new',
          fromShop: false,
          at: now.subtract(const Duration(minutes: 12)),
          text: const L(
            'Чи можна додати заміну фільтра салону?',
            'Can we add a cabin filter replacement?',
            'Можно добавить замену салонного фильтра?',
          ),
        ),
      ],
    ),
  );
  orders.save(
    WorkOrder(
      id: 'desk-demo-2',
      plate: 'WX 9021P',
      brand: 'BMW',
      model: 'X5',
      year: 2019,
      mileage: 98100,
      vin: 'WBSDEMO000000002',
      category: RepairCategory.chassis,
      shopId: 'pitlane',
      status: JobStatus.inProgress,
      boxId: 'box-2',
      createdAt: today.subtract(const Duration(days: 1)),
      scheduledAt: at,
      lines: [lineFromWork(pads, extra: false, approved: true)],
      chat: [
        ServiceChatMessage(
          id: 'desk-demo-2_c0',
          fromShop: true,
          at: at.subtract(const Duration(hours: 1)),
          text: const L(
            'Авто на підйомнику. Фото вже в галереї.',
            'Car is on the lift. Photos are already in the gallery.',
            'Авто на подъёмнике. Фото уже в галерее.',
          ),
        ),
        ServiceChatMessage(
          id: 'desk-demo-2_m0',
          fromShop: true,
          withMaster: true,
          at: at.subtract(const Duration(minutes: 40)),
          text: const L(
            'Почніть з колодок і огляду суппортів.',
            'Start with the pads and caliper check.',
            'Начните с колодок и осмотра суппортов.',
          ),
        ),
        ServiceChatMessage(
          id: 'desk-demo-2_master_new',
          fromShop: false,
          withMaster: true,
          at: now.subtract(const Duration(minutes: 5)),
          text: const L(
            'Потрібне підтвердження: суппорт зліва підклинює.',
            'Need confirmation: left caliper is sticking.',
            'Нужно подтверждение: суппорт слева подклинивает.',
          ),
        ),
      ],
    ),
  );
}
