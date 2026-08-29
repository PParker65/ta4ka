// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'geo_locate_result.dart';

Future<LocateResult> detectLocation() async {
  try {
    final pos = await html.window.navigator.geolocation.getCurrentPosition();
    final lat = pos.coords?.latitude;
    final lng = pos.coords?.longitude;
    if (lat == null || lng == null) {
      return const LocateResult.fail(LocateFail.unavailable);
    }
    return LocateResult.ok(lat.toDouble(), lng.toDouble());
  } catch (_) {
    return const LocateResult.fail(LocateFail.denied);
  }
}

Future<void> openLocateSettings({required bool appSettings}) async {}
