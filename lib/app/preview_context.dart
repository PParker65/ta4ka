import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flip to `true` to put the BMW M2 contest back on vrumly.com / Mini App.
const kPublicWebsitePreviewEnabled = true;

bool isKolesaSaveHost([Uri? uri]) {
  try {
    final host = (uri ?? Uri.base).host.toLowerCase();
    return host == 'kolesasave.com' ||
        host == 'www.kolesasave.com' ||
        host.endsWith('.kolesasave.com') ||
        host.contains('kolesasave');
  } catch (_) {
    return false;
  }
}

/// Public shop desk (no contest): `/autoservice`, login, staff shell.
bool isPublicShopDeskUri(Uri uri) {
  bool hit(String raw) {
    final path = raw.split('?').first.split('&').first.toLowerCase();
    return path == '/autoservice' ||
        path.startsWith('/autoservice/') ||
        path == '/auth/shop' ||
        path.startsWith('/auth/shop/') ||
        path == '/staff' ||
        path.startsWith('/staff/');
  }

  if (hit(uri.path)) return true;
  final frag = uri.fragment;
  if (frag.startsWith('/')) return hit(frag);
  return false;
}

/// Public contest (8 cubes / BMW M2) for every Flutter web visitor.
///
/// - Native (`!kIsWeb`): never. Full app, no cubes, no admin.
/// - Website and Telegram Mini App: when [kPublicWebsitePreviewEnabled],
///   until this-tab admin unlock. Mini App is still web — do not treat
///   `tgWebApp*`, initData, or platform as “already in the app”.
/// - `/autoservice` (and shop login / desk): always the real desk, any device.
bool shouldShowPublicWebsitePreview({
  bool? isWeb,
  bool? telegramActive,
  Uri? uri,
  bool? enabled,
}) {
  // telegramActive stays on the API so tests can prove Telegram
  // flags do not hide the contest. Only native and shop-desk URLs skip.
  final _ = telegramActive;
  if (!(enabled ?? kPublicWebsitePreviewEnabled)) return false;
  if (!(isWeb ?? kIsWeb)) return false;
  final resolved = uri ?? (kIsWeb ? Uri.base : Uri());
  if (isPublicShopDeskUri(resolved)) return false;
  if (isKolesaSaveHost(resolved)) return false;
  return true;
}

final showPublicWebsitePreviewProvider = Provider<bool>((ref) {
  return shouldShowPublicWebsitePreview();
});
