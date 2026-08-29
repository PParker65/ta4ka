/// Client loyalty: 10 levels → rising cashback. XP from sharing & using Ta4ka.
library;

class ClientLoyalty {
  const ClientLoyalty({
    this.xp = 0,
    this.shareCount = 0,
    this.bookingCount = 0,
    this.inviteCount = 0,
    this.referralShopCount = 0,
  });

  final int xp;
  final int shareCount;
  final int bookingCount;
  final int inviteCount;
  final int referralShopCount;

  /// XP needed to reach each level (index 0 = level 1).
  static const thresholds = <int>[
    0, // L1
    80, // L2
    200, // L3
    400, // L4
    700, // L5
    1100, // L6
    1600, // L7
    2300, // L8
    3200, // L9
    4500, // L10
  ];

  /// Cashback % of paid jobs by level 1..10.
  static const cashbackPct = <double>[
    1, 1.5, 2, 2.5, 3, 4, 5, 6.5, 8, 10,
  ];

  int get level {
    var lvl = 1;
    for (var i = 0; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) lvl = i + 1;
    }
    return lvl.clamp(1, 10);
  }

  double get cashbackPercent => cashbackPct[level - 1];

  int get xpIntoLevel {
    final start = thresholds[level - 1];
    return xp - start;
  }

  int get xpForNext {
    if (level >= 10) return 0;
    return thresholds[level] - thresholds[level - 1];
  }

  double get progressToNext {
    if (level >= 10) return 1;
    final span = xpForNext;
    if (span <= 0) return 1;
    return (xpIntoLevel / span).clamp(0.0, 1.0);
  }

  String get titleUk => switch (level) {
        1 => 'Новачок',
        2 => 'Гість СТО',
        3 => 'Активний',
        4 => 'Амбасадор',
        5 => 'Провідник',
        6 => 'Промоутер',
        7 => 'Партнер',
        8 => 'Еліта',
        9 => 'Легенда',
        _ => 'Ta4ka VIP',
      };

  String get titleEn => switch (level) {
        1 => 'Newcomer',
        2 => 'Shop guest',
        3 => 'Active',
        4 => 'Ambassador',
        5 => 'Guide',
        6 => 'Promoter',
        7 => 'Partner',
        8 => 'Elite',
        9 => 'Legend',
        _ => 'Ta4ka VIP',
      };

  String title(bool uk) => uk ? titleUk : titleEn;

  ClientLoyalty copyWith({
    int? xp,
    int? shareCount,
    int? bookingCount,
    int? inviteCount,
    int? referralShopCount,
  }) {
    return ClientLoyalty(
      xp: xp ?? this.xp,
      shareCount: shareCount ?? this.shareCount,
      bookingCount: bookingCount ?? this.bookingCount,
      inviteCount: inviteCount ?? this.inviteCount,
      referralShopCount: referralShopCount ?? this.referralShopCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'shareCount': shareCount,
        'bookingCount': bookingCount,
        'inviteCount': inviteCount,
        'referralShopCount': referralShopCount,
      };

  factory ClientLoyalty.fromJson(Map<String, dynamic> json) {
    return ClientLoyalty(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
      inviteCount: (json['inviteCount'] as num?)?.toInt() ?? 0,
      referralShopCount: (json['referralShopCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// How to earn XP (shown in profile).
class LoyaltyAction {
  const LoyaltyAction({
    required this.xp,
    required this.titleUk,
    required this.titleEn,
    required this.titleRu,
  });

  final int xp;
  final String titleUk;
  final String titleEn;
  final String titleRu;
}

const loyaltyActions = <LoyaltyAction>[
  LoyaltyAction(
    xp: 40,
    titleUk: 'Поділитись додатком у соцмережах / чаті',
    titleEn: 'Share the app on social / chat',
    titleRu: 'Поделиться приложением в соцсетях / чате',
  ),
  LoyaltyAction(
    xp: 60,
    titleUk: 'Запросити друга зареєструватись',
    titleEn: 'Invite a friend to register',
    titleRu: 'Пригласить друга зарегистрироваться',
  ),
  LoyaltyAction(
    xp: 25,
    titleUk: 'Завершити запис на СТО',
    titleEn: 'Complete a shop booking',
    titleRu: 'Завершить запись на СТО',
  ),
  LoyaltyAction(
    xp: 120,
    titleUk: 'Підключити СТО через рефералку (рівень 1)',
    titleEn: 'Connect a shop via referral (level 1)',
    titleRu: 'Подключить СТО через рефералку (уровень 1)',
  ),
  LoyaltyAction(
    xp: 30,
    titleUk: 'Залишити відгук після візиту',
    titleEn: 'Leave a review after a visit',
    titleRu: 'Оставить отзыв после визита',
  ),
];
