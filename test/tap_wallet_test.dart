import 'package:autoservice/data/farm_quests.dart';
import 'package:autoservice/domain/models/tap_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

TapWalletState tapPluses(TapWalletState start, int count) {
  final ids = farmRepairSphereIds();
  final need = ids.length;
  var wallet = start;
  for (var i = 0; i < count; i++) {
    final remaining = [
      for (final id in ids)
        if (!wallet.isCleared(id)) id,
    ];
    final id = remaining.isEmpty ? ids.first : remaining.first;
    wallet = wallet.clearSphere(id, need).wallet;
  }
  return wallet;
}

void main() {
  test('each plus fills the wave and lifetime count', () {
    final ids = farmRepairSphereIds();
    final need = ids.length;
    expect(need, greaterThan(5));

    var wallet = const TapWalletState().smash();
    expect(wallet.wreckAmount(need), 1);

    final first = wallet.clearSphere(ids.first, need);
    wallet = first.wallet;
    expect(first.paidCents, 0);
    expect(wallet.pluses, 1);
    expect(wallet.waveProgress(need), closeTo(1 / need, 0.001));
    expect(wallet.goalProgress, closeTo(1 / 100, 0.001));
  });

  test('pluses come back after every plus on the car is pressed', () {
    final ids = farmRepairSphereIds();
    final need = ids.length;
    var wallet = const TapWalletState().smash();
    var reset = false;
    for (final id in ids) {
      final result = wallet.clearSphere(id, need);
      wallet = result.wallet;
      reset = result.waveReset;
    }
    expect(reset, isTrue);
    expect(wallet.clearedSphereIds, isEmpty);
    expect(wallet.pluses, need);
    expect(wallet.wreckAmount(need), 1);
    expect(wallet.balanceUsdCents, 0);

    final again = wallet.clearSphere(ids.first, need);
    expect(again.wallet.pluses, need + 1);
    expect(again.wallet.clearedSphereIds, [ids.first]);
  });

  test('100 pluses pay five dollars, 1000 pluses pay ten more', () {
    var wallet = tapPluses(const TapWalletState().smash(), 99);
    expect(wallet.balanceUsdCents, 0);
    expect(wallet.nextPayout, (100, 500));

    wallet = tapPluses(wallet, 1);
    expect(wallet.pluses, 100);
    expect(wallet.balanceUsdCents, 500);
    expect(wallet.balanceLabel, '\$5.00');
    expect(wallet.nextPayout, (1000, 1000));

    wallet = tapPluses(wallet, 900);
    expect(wallet.pluses, 1000);
    expect(wallet.balanceUsdCents, 1500);
    expect(wallet.balanceLabel, '\$15.00');
    expect(wallet.nextPayout, (10000, 2000));
  });

  test('wallet pays service in UAH and keeps leftover dollars', () {
    const wallet = TapWalletState(balanceUsdCents: 700, pluses: 100);
    final paid = wallet.spendUah(1400);
    expect(paid.appliedUah, 280);
    expect(paid.wallet.balanceUsdCents, 0);
    expect(paid.wallet.pluses, 100);

    const five = TapWalletState(balanceUsdCents: 500);
    final part = five.spendUah(80);
    expect(part.appliedUah, 80);
    expect(part.wallet.balanceUsdCents, 300);
  });
}
