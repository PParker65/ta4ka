import '../../core/l10n/app_lang.dart';

class WarehouseItem {
  const WarehouseItem({
    required this.id,
    required this.oem,
    required this.title,
    required this.bin,
    required this.qty,
    required this.costUah,
    required this.groupId,
    this.reserved = 0,
  });

  final String id;
  final String oem;
  final String title;
  final String bin;
  final int qty;
  final int costUah;
  final String groupId;
  final int reserved;

  int get free => qty - reserved;

  WarehouseItem copyWith({int? qty, int? reserved}) {
    return WarehouseItem(
      id: id,
      oem: oem,
      title: title,
      bin: bin,
      qty: qty ?? this.qty,
      costUah: costUah,
      groupId: groupId,
      reserved: reserved ?? this.reserved,
    );
  }
}

class ChecklistPoint {
  const ChecklistPoint({
    required this.id,
    required this.titleUk,
    required this.titleEn,
    required this.titleRu,
    required this.zone,
  });

  final String id;
  final String titleUk;
  final String titleEn;
  final String titleRu;
  final String zone;

  String title(AppLang lang) => switch (lang) {
        AppLang.uk => titleUk,
        AppLang.en => titleEn,
        AppLang.ru => titleRu,
        AppLang.pl => titleEn,
      };
}

class ChecklistMark {
  const ChecklistMark({required this.pointId, required this.ok, this.note = ''});
  final String pointId;
  final bool ok;
  final String note;
}

class InspectionRun {
  const InspectionRun({
    required this.orderId,
    this.marks = const [],
  });

  final String orderId;
  final List<ChecklistMark> marks;

  InspectionRun upsert(ChecklistMark mark) {
    return InspectionRun(
      orderId: orderId,
      marks: [
        for (final m in marks)
          if (m.pointId != mark.pointId) m,
        mark,
      ],
    );
  }
}

class JobClock {
  const JobClock({
    required this.orderId,
    this.startedAt,
    this.elapsed = Duration.zero,
  });

  final String orderId;
  final DateTime? startedAt;
  final Duration elapsed;

  bool get running => startedAt != null;

  Duration live([DateTime? now]) {
    if (startedAt == null) return elapsed;
    return elapsed + (now ?? DateTime.now()).difference(startedAt!);
  }
}

class ServiceReminder {
  const ServiceReminder({
    required this.id,
    required this.plate,
    required this.vin,
    required this.client,
    required this.dueKm,
    required this.dueAt,
    required this.work,
    this.sent = false,
  });

  final String id;
  final String plate;
  final String vin;
  final String client;
  final int dueKm;
  final DateTime dueAt;
  final String work;
  final bool sent;

  ServiceReminder copyWith({bool? sent}) {
    return ServiceReminder(
      id: id,
      plate: plate,
      vin: vin,
      client: client,
      dueKm: dueKm,
      dueAt: dueAt,
      work: work,
      sent: sent ?? this.sent,
    );
  }
}

class BayPlan {
  const BayPlan({
    required this.bayId,
    required this.label,
    this.orderId,
  });

  final String bayId;
  final String label;
  final String? orderId;

  BayPlan copyWith({String? orderId, bool clear = false}) {
    return BayPlan(
      bayId: bayId,
      label: label,
      orderId: clear ? null : (orderId ?? this.orderId),
    );
  }
}

const kChecklist = <ChecklistPoint>[
  ChecklistPoint(id: 'oil', titleUk: 'Рівень і стан оливи', titleEn: 'Oil level & condition', titleRu: 'Уровень и состояние масла', zone: 'fluids'),
  ChecklistPoint(id: 'coolant', titleUk: 'Охолоджувальна рідина', titleEn: 'Coolant', titleRu: 'Охлаждающая жидкость', zone: 'fluids'),
  ChecklistPoint(id: 'brake_fluid', titleUk: 'Гальмівна рідина', titleEn: 'Brake fluid', titleRu: 'Тормозная жидкость', zone: 'fluids'),
  ChecklistPoint(id: 'washer', titleUk: 'Омивач', titleEn: 'Washer fluid', titleRu: 'Омыватель', zone: 'fluids'),
  ChecklistPoint(id: 'pads_f', titleUk: 'Колодки перед', titleEn: 'Front pads', titleRu: 'Колодки перед', zone: 'brakes'),
  ChecklistPoint(id: 'pads_r', titleUk: 'Колодки зад', titleEn: 'Rear pads', titleRu: 'Колодки зад', zone: 'brakes'),
  ChecklistPoint(id: 'discs', titleUk: 'Диски / борозни', titleEn: 'Discs / grooves', titleRu: 'Диски / борозды', zone: 'brakes'),
  ChecklistPoint(id: 'tires_t', titleUk: 'Протектор шин', titleEn: 'Tire tread', titleRu: 'Протектор шин', zone: 'tires'),
  ChecklistPoint(id: 'tires_p', titleUk: 'Тиск у шинах', titleEn: 'Tire pressure', titleRu: 'Давление в шинах', zone: 'tires'),
  ChecklistPoint(id: 'arms', titleUk: 'Важелі / сайлентблоки', titleEn: 'Arms / bushings', titleRu: 'Рычаги / сайлентблоки', zone: 'chassis'),
  ChecklistPoint(id: 'ball', titleUk: 'Кульові опори', titleEn: 'Ball joints', titleRu: 'Шаровые опоры', zone: 'chassis'),
  ChecklistPoint(id: 'tie', titleUk: 'Наконечники / тяги', titleEn: 'Tie rods', titleRu: 'Наконечники / тяги', zone: 'chassis'),
  ChecklistPoint(id: 'cv', titleUk: 'Пильовики ШРУС', titleEn: 'CV boots', titleRu: 'Пыльники ШРУС', zone: 'chassis'),
  ChecklistPoint(id: 'shocks', titleUk: 'Амортизатори / підтікання', titleEn: 'Shocks / leaks', titleRu: 'Амортизаторы / течи', zone: 'chassis'),
  ChecklistPoint(id: 'lights', titleUk: 'Фари / стопи / повороти', titleEn: 'Lights / stop / turn', titleRu: 'Фары / стопы / повороты', zone: 'elec'),
  ChecklistPoint(id: 'battery', titleUk: 'АКБ / клеми', titleEn: 'Battery / terminals', titleRu: 'АКБ / клеммы', zone: 'elec'),
  ChecklistPoint(id: 'belts', titleUk: 'Ремінь навісного', titleEn: 'Accessory belt', titleRu: 'Ремень навесного', zone: 'engine'),
  ChecklistPoint(id: 'leaks', titleUk: 'Підтікання з двигуна', titleEn: 'Engine leaks', titleRu: 'Течи двигателя', zone: 'engine'),
  ChecklistPoint(id: 'exhaust', titleUk: 'Вихлоп / підвіс', titleEn: 'Exhaust / hangers', titleRu: 'Выхлоп / подвесы', zone: 'engine'),
  ChecklistPoint(id: 'body', titleUk: 'Кузов / сколи / вмʼятини', titleEn: 'Body / chips / dents', titleRu: 'Кузов / сколы / вмятины', zone: 'body'),
  ChecklistPoint(id: 'wipers', titleUk: 'Щітки склоочисника', titleEn: 'Wiper blades', titleRu: 'Щётки стеклоочистителя', zone: 'body'),
  ChecklistPoint(id: 'ac', titleUk: 'Кондиціонер / запах', titleEn: 'A/C / odor', titleRu: 'Кондиционер / запах', zone: 'comfort'),
];
