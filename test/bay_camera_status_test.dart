import 'package:autoservice/data/live_cams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shop bay camera online is stable per id and mixed across shops', () {
    expect(shopBayCameraOnline('pitlane'), shopBayCameraOnline('pitlane'));
    expect(shopBayCameraOnline('net-warsaw-0'), shopBayCameraOnline('net-warsaw-0'));

    var on = 0;
    var off = 0;
    for (var i = 0; i < 40; i++) {
      if (shopBayCameraOnline('net-warsaw-$i')) {
        on++;
      } else {
        off++;
      }
    }
    expect(on, greaterThan(8));
    expect(off, greaterThan(8));
  });
}
