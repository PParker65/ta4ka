import 'package:geolocator/geolocator.dart';

import 'geo_locate_result.dart';

Future<LocateResult> detectLocation() async {
  try {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return const LocateResult.fail(LocateFail.servicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocateResult.fail(LocateFail.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocateResult.fail(LocateFail.deniedForever);
    }

    Position? last;
    try {
      last = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocateResult.ok(pos.latitude, pos.longitude);
    } catch (_) {
      if (last != null) {
        return LocateResult.ok(last.latitude, last.longitude);
      }
      return const LocateResult.fail(LocateFail.unavailable);
    }
  } catch (_) {
    return const LocateResult.fail(LocateFail.unavailable);
  }
}

Future<void> openLocateSettings({required bool appSettings}) async {
  if (appSettings) {
    await Geolocator.openAppSettings();
  } else {
    await Geolocator.openLocationSettings();
  }
}
