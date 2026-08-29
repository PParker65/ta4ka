/// Platform share: 5% of completed booking total accrues as shop debt.
/// Unpaid debt after the monthly settlement window blocks the shop account.
abstract final class ShopCommission {
  static const rate = 0.05;

  static int feeFromTotalUah(int totalUah) {
    if (totalUah <= 0) {
      return 0;
    }
    return (totalUah * rate).round().clamp(1, totalUah);
  }

  /// Block when there is debt and the shop has not marked settlement this calendar month.
  /// Pay by the 1st (or any day of the new month); until then the desk stays locked.
  static bool shouldBlock({
    required int debtUah,
    required DateTime? lastSettledAt,
    DateTime? now,
  }) {
    if (debtUah <= 0) {
      return false;
    }
    final n = now ?? DateTime.now();
    if (lastSettledAt != null &&
        lastSettledAt.year == n.year &&
        lastSettledAt.month == n.month) {
      return false;
    }
    return true;
  }
}
