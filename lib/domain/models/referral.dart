/// Three-level referral: connect STO → lifelong % of shop turnover.
library;

enum ReferralShopStatus { pending, approved, rejected }

class ReferralShopLink {
  const ReferralShopLink({
    required this.id,
    required this.shopName,
    required this.city,
    required this.level,
    required this.status,
    required this.connectedAt,
    this.photoUrl = '',
    this.managerName = '',
    this.monthTurnoverUah = 0,
    this.note = '',
  });

  final String id;
  final String shopName;
  final String city;
  /// 1 = you connected · 2 = your partner · 3 = partner's partner
  final int level;
  final ReferralShopStatus status;
  final DateTime connectedAt;
  final String photoUrl;
  final String managerName;
  final int monthTurnoverUah;
  final String note;

  double get rate => switch (level) {
        1 => 0.03,
        2 => 0.01,
        _ => 0.005,
      };

  int get monthEarnedUah =>
      status == ReferralShopStatus.approved
          ? (monthTurnoverUah * rate).round()
          : 0;

  ReferralShopLink copyWith({
    ReferralShopStatus? status,
    int? monthTurnoverUah,
    String? photoUrl,
    String? managerName,
    String? note,
  }) {
    return ReferralShopLink(
      id: id,
      shopName: shopName,
      city: city,
      level: level,
      status: status ?? this.status,
      connectedAt: connectedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      managerName: managerName ?? this.managerName,
      monthTurnoverUah: monthTurnoverUah ?? this.monthTurnoverUah,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopName': shopName,
        'city': city,
        'level': level,
        'status': status.name,
        'connectedAt': connectedAt.millisecondsSinceEpoch,
        'photoUrl': photoUrl,
        'managerName': managerName,
        'monthTurnoverUah': monthTurnoverUah,
        'note': note,
      };

  factory ReferralShopLink.fromJson(Map<String, dynamic> json) {
    ReferralShopStatus status = ReferralShopStatus.pending;
    for (final v in ReferralShopStatus.values) {
      if (v.name == json['status']) {
        status = v;
        break;
      }
    }
    return ReferralShopLink(
      id: json['id'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      status: status,
      connectedAt: DateTime.fromMillisecondsSinceEpoch(
        json['connectedAt'] as int? ?? 0,
      ),
      photoUrl: json['photoUrl'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      monthTurnoverUah: (json['monthTurnoverUah'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
    );
  }
}

class ReferralAccount {
  const ReferralAccount({
    required this.ownerLogin,
    required this.inviteCode,
    this.displayName = '',
    this.payoutRequisites = '',
    this.iban = '',
    this.fullName = '',
    this.phone = '',
    this.shops = const [],
    this.invitedLogins = const [],
  });

  final String ownerLogin;
  final String inviteCode;
  final String displayName;
  final String payoutRequisites;
  final String iban;
  final String fullName;
  final String phone;
  final List<ReferralShopLink> shops;
  /// People who joined the program under your code (L2 roots).
  final List<String> invitedLogins;

  List<ReferralShopLink> get approved => [
        for (final s in shops)
          if (s.status == ReferralShopStatus.approved) s,
      ];

  List<ReferralShopLink> get pending => [
        for (final s in shops)
          if (s.status == ReferralShopStatus.pending) s,
      ];

  int get shopsBrought => approved.length;

  int get monthShopTurnoverUah =>
      approved.fold(0, (sum, s) => sum + s.monthTurnoverUah);

  int get monthEarnedUah =>
      approved.fold(0, (sum, s) => sum + s.monthEarnedUah);

  int get level1Count => approved.where((s) => s.level == 1).length;
  int get level2Count => approved.where((s) => s.level == 2).length;
  int get level3Count => approved.where((s) => s.level == 3).length;

  ReferralAccount copyWith({
    String? displayName,
    String? payoutRequisites,
    String? iban,
    String? fullName,
    String? phone,
    List<ReferralShopLink>? shops,
    List<String>? invitedLogins,
  }) {
    return ReferralAccount(
      ownerLogin: ownerLogin,
      inviteCode: inviteCode,
      displayName: displayName ?? this.displayName,
      payoutRequisites: payoutRequisites ?? this.payoutRequisites,
      iban: iban ?? this.iban,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      shops: shops ?? this.shops,
      invitedLogins: invitedLogins ?? this.invitedLogins,
    );
  }

  Map<String, dynamic> toJson() => {
        'ownerLogin': ownerLogin,
        'inviteCode': inviteCode,
        'displayName': displayName,
        'payoutRequisites': payoutRequisites,
        'iban': iban,
        'fullName': fullName,
        'phone': phone,
        'shops': [for (final s in shops) s.toJson()],
        'invitedLogins': invitedLogins,
      };

  factory ReferralAccount.fromJson(Map<String, dynamic> json) {
    return ReferralAccount(
      ownerLogin: json['ownerLogin'] as String? ?? '',
      inviteCode: json['inviteCode'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      payoutRequisites: json['payoutRequisites'] as String? ?? '',
      iban: json['iban'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      shops: [
        for (final item in json['shops'] as List<dynamic>? ?? const [])
          ReferralShopLink.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      invitedLogins: [
        for (final x in json['invitedLogins'] as List<dynamic>? ?? const [])
          '$x',
      ],
    );
  }
}

class ReferralHub {
  const ReferralHub({this.accounts = const {}});

  final Map<String, ReferralAccount> accounts;

  ReferralAccount? of(String login) => accounts[login];

  ReferralHub upsert(ReferralAccount account) {
    return ReferralHub(
      accounts: {
        ...accounts,
        account.ownerLogin: account,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'accounts': {
          for (final e in accounts.entries) e.key: e.value.toJson(),
        },
      };

  factory ReferralHub.fromJson(Map<String, dynamic> json) {
    final raw = json['accounts'];
    if (raw is! Map) {
      return const ReferralHub();
    }
    return ReferralHub(
      accounts: {
        for (final e in raw.entries)
          '${e.key}': ReferralAccount.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
    );
  }

  static String codeFor(String login) {
    final clean = login.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final base = clean.length >= 4 ? clean.substring(0, 4) : clean.padRight(4, 'X');
    final hash = login.hashCode.abs() % 10000;
    return 'AS-$base-${hash.toString().padLeft(4, '0')}';
  }
}
