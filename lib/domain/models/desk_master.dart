import '../../core/l10n/app_lang.dart';
import '../models/crm_models.dart';
import 'shop_models.dart';

/// Pace / seniority shown to clients when picking a technician.
enum MasterPace { intern, normal, fast, careful }

/// Who this staff login is for — issued only by the shop.
enum StaffKind { mechanic, receptionist }

class DeskMaster {
  const DeskMaster({
    required this.id,
    required this.name,
    this.specialty = MasterSpecialty.maintenance,
    this.pace = MasterPace.normal,
    this.yearsExperience = 1,
    this.workIds = const [],
    this.note = '',
    this.login = '',
    this.password = '',
    this.kind = StaffKind.mechanic,
  });

  final String id;
  final String name;
  final MasterSpecialty specialty;
  final MasterPace pace;
  final int yearsExperience;
  final List<String> workIds;
  final String note;
  /// Issued only from the shop desk — staff cannot self-register.
  final String login;
  final String password;
  final StaffKind kind;

  bool get hasCredentials => login.trim().isNotEmpty && password.trim().isNotEmpty;
  bool get isMechanic => kind == StaffKind.mechanic;
  bool get isReceptionist => kind == StaffKind.receptionist;

  DeskMaster copyWith({
    String? name,
    MasterSpecialty? specialty,
    MasterPace? pace,
    int? yearsExperience,
    List<String>? workIds,
    String? note,
    String? login,
    String? password,
    StaffKind? kind,
  }) {
    return DeskMaster(
      id: id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      pace: pace ?? this.pace,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      workIds: workIds ?? this.workIds,
      note: note ?? this.note,
      login: login ?? this.login,
      password: password ?? this.password,
      kind: kind ?? this.kind,
    );
  }

  ShopMaster toShopMaster() {
    final n = name.trim().isEmpty ? 'Master' : name.trim();
    final paceUk = switch (pace) {
      MasterPace.intern => 'стажер',
      MasterPace.normal => 'працює стабільно',
      MasterPace.fast => 'швидкий',
      MasterPace.careful => 'ретельний',
    };
    final paceEn = switch (pace) {
      MasterPace.intern => 'intern',
      MasterPace.normal => 'steady',
      MasterPace.fast => 'fast',
      MasterPace.careful => 'careful',
    };
    final paceRu = switch (pace) {
      MasterPace.intern => 'стажёр',
      MasterPace.normal => 'работает стабильно',
      MasterPace.fast => 'быстрый',
      MasterPace.careful => 'аккуратный',
    };
    final bioUk = note.trim().isNotEmpty
        ? note.trim()
        : '$yearsExperience р. досвіду · $paceUk';
    final bioEn = note.trim().isNotEmpty
        ? note.trim()
        : '$yearsExperience yrs experience · $paceEn';
    final bioRu = note.trim().isNotEmpty
        ? note.trim()
        : '$yearsExperience лет опыта · $paceRu';
    return ShopMaster(
      id: id,
      name: L(n, n, n, n),
      specialty: specialty,
      bio: L(bioUk, bioEn, bioRu, bioEn),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty.name,
        'pace': pace.name,
        'yearsExperience': yearsExperience,
        'workIds': workIds,
        'note': note,
        'login': login,
        'password': password,
        'kind': kind.name,
      };

  factory DeskMaster.fromJson(Map<String, dynamic> json) {
    MasterSpecialty spec = MasterSpecialty.maintenance;
    for (final value in MasterSpecialty.values) {
      if (value.name == json['specialty']) {
        spec = value;
        break;
      }
    }
    MasterPace pace = MasterPace.normal;
    for (final value in MasterPace.values) {
      if (value.name == json['pace']) {
        pace = value;
        break;
      }
    }
    StaffKind kind = StaffKind.mechanic;
    for (final value in StaffKind.values) {
      if (value.name == json['kind']) {
        kind = value;
        break;
      }
    }
    return DeskMaster(
      id: json['id'] as String? ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '',
      specialty: spec,
      pace: pace,
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 1,
      workIds: [
        for (final id in json['workIds'] as List<dynamic>? ?? const [])
          id as String,
      ],
      note: json['note'] as String? ?? '',
      login: json['login'] as String? ?? '',
      password: json['password'] as String? ?? '',
      kind: kind,
    );
  }
}

List<DeskMaster> resizeDeskMasters(List<DeskMaster> current, int count) {
  final n = count.clamp(0, 20);
  if (current.length == n) {
    return current;
  }
  if (current.length > n) {
    return current.take(n).toList();
  }
  final next = [...current];
  while (next.length < n) {
    final i = next.length + 1;
    next.add(
      DeskMaster(
        id: 'desk_m_$i',
        name: '',
        yearsExperience: i == 1 ? 9 : (i == 2 ? 0 : 3),
        pace: i == 2 ? MasterPace.intern : MasterPace.normal,
      ),
    );
  }
  return next;
}

String issueMasterLogin(String shopLogin, String masterId) {
  final base = shopLogin.trim().isEmpty ? 'shop' : shopLogin.trim().toLowerCase();
  final short = masterId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  return '${base}_m${short.length > 4 ? short.substring(short.length - 4) : short}';
}

String issueMasterPassword() {
  final n = DateTime.now().millisecondsSinceEpoch % 100000;
  return 'Mst$n';
}
