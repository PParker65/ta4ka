// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// True while the kolesasave.com CSS boot seal is still on screen.
bool kolesaHtmlBootVisible() {
  final el = html.document.getElementById('ks-boot');
  if (el == null) return false;
  return !el.classes.contains('ks-out');
}

/// Asks index.html to fade the boot seal once its minimum beat has played.
void signalKolesaBootReady() {
  html.window.dispatchEvent(html.Event('ks-app-ready'));
}
