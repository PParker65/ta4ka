import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// True when the device has Wi‑Fi, mobile data, or another routed network.
Future<bool> deviceHasNetworkLink() async {
  try {
    final results = await Connectivity().checkConnectivity();
    return _linked(results);
  } catch (_) {
    // Plugin failure — still try to load models (WebView will fail if truly offline).
    return true;
  }
}

bool _linked(List<ConnectivityResult> results) {
  if (results.isEmpty) {
    return true;
  }
  if (results.every((r) => r == ConnectivityResult.none)) {
    return false;
  }
  return results.any(
    (r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other,
  );
}

/// Online = any active link (Wi‑Fi / mobile / VPN). Do not probe remote hosts —
/// Android often blocks HEAD to CDNs and that falsely shows “no internet”.
Future<bool> hasInternetForGlbModels() async {
  if (kIsWeb) {
    return true;
  }
  return deviceHasNetworkLink();
}

Stream<bool> watchInternetForGlbModels() async* {
  if (kIsWeb) {
    yield true;
    return;
  }
  yield await hasInternetForGlbModels();
  await for (final results in Connectivity().onConnectivityChanged) {
    yield _linked(results);
  }
}
