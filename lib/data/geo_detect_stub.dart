import 'geo_locate_result.dart';

Future<LocateResult> detectLocation() async =>
    const LocateResult.fail(LocateFail.unavailable);

Future<void> openLocateSettings({required bool appSettings}) async {}
