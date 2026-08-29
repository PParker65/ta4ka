import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

void openLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool get prefersAppleMaps => Platform.isIOS || Platform.isMacOS;
