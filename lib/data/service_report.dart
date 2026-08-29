import '../core/l10n/app_lang.dart';
import '../domain/models/crm_models.dart';
import 'category_scenes.dart';

class ServiceReportItem {
  const ServiceReportItem({
    required this.id,
    required this.asset,
    required this.title,
    required this.at,
    required this.video,
  });

  final String id;
  final String asset;
  final L title;
  final DateTime at;
  final bool video;
}

String sceneKeyForCategory(RepairCategory category) {
  return switch (category) {
    RepairCategory.engine => 'engine',
    RepairCategory.chassis => 'chassis',
    RepairCategory.electrical => 'electronics',
    RepairCategory.maintenance => 'service',
    RepairCategory.diagnostics => 'electronics',
  };
}

List<String> bayCameraAssets(WorkOrder order) {
  final primary = sceneKeyForCategory(order.category);
  const extras = ['workshop', 'service', 'chassis', 'engine', 'electronics'];
  final keys = <String>[primary];
  for (final key in extras) {
    if (!keys.contains(key)) {
      keys.add(key);
    }
  }
  return [for (final key in keys.take(3)) 'assets/scenes/scene-$key.jpg'];
}

List<ServiceReportItem> incomingReport(WorkOrder order) {
  final start = order.scheduledAt ?? order.createdAt;
  final primary = sceneKeyForCategory(order.category);
  final keys = <String>[
    primary,
    'workshop',
    'engine',
    'chassis',
    'brakes',
    'service',
    'interior',
    'tires',
  ];
  final seen = <String>{};
  final unique = <String>[];
  for (final key in keys) {
    if (seen.add(key)) {
      unique.add(key);
    }
  }
  const titles = <L>[
    L('Прийом: загальний вид', 'Intake: overall view', 'Приём: общий вид'),
    L('Відео з підйомника', 'Lift video', 'Видео с подъёмника'),
    L('Фото вузла до робіт', 'Part before work', 'Фото узла до работ'),
    L('Відео дефекту', 'Defect clip', 'Видео дефекта'),
    L('Проміжний контроль', 'Mid-job check', 'Промежуточный контроль'),
    L('Готово до видачі', 'Ready for handover', 'Готово к выдаче'),
  ];
  return [
    for (var i = 0; i < 6; i++)
      ServiceReportItem(
        id: '${order.id}_r$i',
        asset: categorySceneAsset(unique[i % unique.length]),
        title: titles[i],
        at: start.add(Duration(minutes: 12 * i + 8)),
        video: i == 1 || i == 3,
      ),
  ];
}

List<ServiceChatMessage> seedServiceChat(WorkOrder order) {
  final at = order.scheduledAt ?? order.createdAt;
  return [
    ServiceChatMessage(
      id: '${order.id}_c0',
      fromShop: true,
      at: at.add(const Duration(minutes: 4)),
      text: const L(
        'Авто прийняли. Камера боксу 2 онлайн — дивіться трансляцію вище.',
        'Car is in. Bay 2 camera is live — watch the stream above.',
        'Авто приняли. Камера бокса 2 онлайн — смотрите трансляцию выше.',
      ),
    ),
    ServiceChatMessage(
      id: '${order.id}_c1',
      fromShop: true,
      at: at.add(const Duration(minutes: 18)),
      text: const L(
        'Фото і відео звіту вже в галереї. Якщо треба крупніше — напишіть.',
        'Photo and video report is in the gallery. Ask if you need a closer look.',
        'Фото и видео отчёта уже в галерее. Если нужно крупнее — напишите.',
      ),
    ),
  ];
}

List<ServiceChatMessage> seedMasterChat(WorkOrder order) {
  final at = order.scheduledAt ?? order.createdAt;
  return [
    ServiceChatMessage(
      id: '${order.id}_m0',
      fromShop: true,
      withMaster: true,
      at: at.add(const Duration(minutes: 6)),
      text: const L(
        'Клієнт на боксі. Почніть з огляду та фото в галерею.',
        'Client is in the bay. Start with inspection and photos in the gallery.',
        'Клиент на боксе. Начните с осмотра и фото в галерею.',
      ),
    ),
  ];
}

L shopChatReply(int index) {
  const replies = <L>[
    L(
      'Прийняли. Майстер перевірить і додасть фото в галерею.',
      'Got it. The technician will check and add a photo to the gallery.',
      'Приняли. Мастер проверит и добавит фото в галерею.',
    ),
    L(
      'Камера боксу 2 онлайн. Зараз піднімаємо авто.',
      'Bay 2 camera is live. We are putting the car on the lift now.',
      'Камера бокса 2 онлайн. Сейчас поднимаем авто.',
    ),
    L(
      'Ок. Надішлемо ще один короткий відеозвіт після вузла.',
      'Ok. We will send another short video report after this job.',
      'Ок. Пришлём ещё один короткий видеоотчёт после узла.',
    ),
  ];
  return replies[index % replies.length];
}
