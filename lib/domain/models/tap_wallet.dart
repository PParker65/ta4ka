class TapWalletState {
  const TapWalletState({
    this.balanceUsdCents = 0,
    this.smashed = false,
    this.clearedSphereIds = const [],
    this.pluses = 0,
  });

  static const int usdToUah = 40; // $1 → 40 ₴

  final int balanceUsdCents;
  final bool smashed;
  final List<String> clearedSphereIds;
  final int pluses;

  int get balanceUah => (balanceUsdCents * usdToUah) ~/ 100;

  String get balanceLabel {
    final dollars = balanceUsdCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// 100 pluses → $5, 1000 → $10, then 10× pluses and 2× dollars.
  static (int pluses, int cents) payoutAtIndex(int index) {
    if (index <= 0) {
      return (100, 500);
    }
    var need = 1000;
    var cents = 1000;
    for (var i = 1; i < index; i++) {
      need *= 10;
      cents *= 2;
    }
    return (need, cents);
  }

  static int centsUnlocked(int fromPluses, int toPluses) {
    var cents = 0;
    for (var i = 0; i < 16; i++) {
      final row = payoutAtIndex(i);
      if (fromPluses < row.$1 && toPluses >= row.$1) {
        cents += row.$2;
      }
    }
    return cents;
  }

  (int pluses, int cents) get nextPayout {
    for (var i = 0; i < 16; i++) {
      final row = payoutAtIndex(i);
      if (pluses < row.$1) {
        return row;
      }
    }
    return payoutAtIndex(16);
  }

  String get nextPayoutLabel {
    final dollars = nextPayout.$2 / 100;
    if (dollars == dollars.roundToDouble()) {
      return '\$${dollars.toStringAsFixed(0)}';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }

  double get goalProgress {
    final need = nextPayout.$1;
    if (need <= 0) {
      return 0;
    }
    return (pluses / need).clamp(0.0, 1.0);
  }

  int get plusesLeft {
    final need = nextPayout.$1;
    return (need - pluses).clamp(0, need);
  }

  bool isCleared(String sphereId) => clearedSphereIds.contains(sphereId);

  double waveProgress(int need) {
    if (need <= 0) {
      return 0;
    }
    return (clearedSphereIds.length / need).clamp(0.0, 1.0);
  }

  double wreckAmount(int need) {
    if (!smashed) {
      return 0;
    }
    return (1 - waveProgress(need)).clamp(0.0, 1.0);
  }

  TapWalletState smash() {
    return TapWalletState(
      balanceUsdCents: balanceUsdCents,
      smashed: true,
      clearedSphereIds: const [],
      pluses: pluses,
    );
  }

  ({TapWalletState wallet, int paidCents, bool waveReset}) clearSphere(
    String sphereId,
    int need,
  ) {
    if (sphereId.isEmpty) {
      return (wallet: this, paidCents: 0, waveReset: false);
    }
    if (clearedSphereIds.contains(sphereId)) {
      return (wallet: this, paidCents: 0, waveReset: false);
    }
    final nextCleared = [...clearedSphereIds, sphereId];
    final total = pluses + 1;
    final paid = centsUnlocked(pluses, total);
    final waveReset = need > 0 && nextCleared.length >= need;
    return (
      wallet: TapWalletState(
        balanceUsdCents: balanceUsdCents + paid,
        smashed: true,
        clearedSphereIds: waveReset ? const [] : nextCleared,
        pluses: total,
      ),
      paidCents: paid,
      waveReset: waveReset,
    );
  }

  ({TapWalletState wallet, int appliedUah}) spendUah(int uah) {
    if (uah <= 0 || balanceUsdCents <= 0) {
      return (wallet: this, appliedUah: 0);
    }
    final wantCents = ((uah * 100) / usdToUah).ceil();
    final spendCents = wantCents > balanceUsdCents ? balanceUsdCents : wantCents;
    final applied = (spendCents * usdToUah) ~/ 100;
    return (
      wallet: TapWalletState(
        balanceUsdCents: balanceUsdCents - spendCents,
        smashed: smashed,
        clearedSphereIds: clearedSphereIds,
        pluses: pluses,
      ),
      appliedUah: applied > uah ? uah : applied,
    );
  }

  Map<String, dynamic> toJson() => {
        'cents': balanceUsdCents,
        'smashed': smashed,
        'cleared': clearedSphereIds,
        'pluses': pluses,
      };

  factory TapWalletState.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TapWalletState();
    }
    final rawCleared = json['cleared'];
    return TapWalletState(
      balanceUsdCents: (json['cents'] as num?)?.toInt() ?? 0,
      smashed: json['smashed'] == true,
      clearedSphereIds: rawCleared is List
          ? [for (final id in rawCleared) id.toString()]
          : const [],
      pluses: (json['pluses'] as num?)?.toInt() ?? 0,
    );
  }
}
