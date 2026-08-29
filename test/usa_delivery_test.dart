import 'package:autoservice/data/usa_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PKU 215.3.51 petrol 1.8 L 2014 in 2026', () {
    expect(
      usaExciseEur(fuel: 'petrol', engineL: 1.8, year: 2014),
      50 * 1.8 * 12,
    );
  });

  test('PKU 215.3.51 diesel 2.2 L 2016 in 2026', () {
    expect(
      usaExciseEur(fuel: 'diesel', engineL: 2.2, year: 2016),
      75 * 2.2 * 10,
    );
  });

  test('age coefficient clamps to 1 and 15', () {
    expect(usaExciseAgeCoeff(2026), 1);
    expect(usaExciseAgeCoeff(2027), 1);
    expect(usaExciseAgeCoeff(2000), 15);
  });

  test('eight formula terms sum to landed total', () {
    final q = usaLandedQuote(
      bidUsd: 16500,
      engineL: 2.0,
      year: 2019,
      fuel: 'petrol',
    );
    expect(
      q.totalUsd,
      q.bidUsd +
          q.auctionFeeUsd +
          q.inlandUsd +
          q.oceanUsd +
          q.dutyUsd +
          q.exciseUsd +
          q.vatUsd +
          q.brokerUsd,
    );
    expect(q.dutyUsd, (q.customsValueUsd * 0.10).round());
    expect(q.vatUsd, ((q.customsValueUsd + q.dutyUsd + q.exciseUsd) * 0.20).round());
    expect(q.inlandUsd, 625);
    expect(q.oceanUsd, 1690);
    expect(q.brokerUsd, 480);
  });

  test('EV has zero duty and 20% VAT including battery excise', () {
    final q = usaLandedQuote(
      bidUsd: 21400,
      engineL: 0,
      year: 2021,
      fuel: 'ev',
    );
    expect(q.dutyUsd, 0);
    expect(q.exciseEur, kUsaDefaultBatteryKwh);
    expect(q.vatUsd, ((q.customsValueUsd + q.exciseUsd) * 0.20).round());
  });

  test('hybrid uses petrol spark-ignition excise', () {
    expect(
      usaExciseEur(fuel: 'hybrid', engineL: 2.5, year: 2020),
      usaExciseEur(fuel: 'petrol', engineL: 2.5, year: 2020),
    );
  });

  test('wrappers match quote totals', () {
    const bid = 14200;
    const engine = 2.5;
    const year = 2020;
    const fuel = 'petrol';
    final q = usaLandedQuote(bidUsd: bid, engineL: engine, year: year, fuel: fuel);
    expect(usaLandedUsd(bidUsd: bid, engineL: engine, year: year, fuel: fuel), q.totalUsd);
    expect(usaLandedUah(bidUsd: bid, engineL: engine, year: year, fuel: fuel), q.totalUah);
  });
}
