// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

const kSketchfabCamaroModelId = '2cd3999a0f0444e2a57b5f1aad92e890';

final _registered = <String>{};

String sketchfabEmbedUrl(String modelId, {required bool autoSpin}) {
  final params = <String, String>{
    'autostart': '1',
    'preload': '1',
    'transparent': '1',
    'ui_theme': 'dark',
    'ui_hint': '0',
    'ui_infos': '0',
    'ui_inspector': '0',
    'ui_stop': '0',
    'ui_controls': '1',
    'ui_watermark': '1',
    'autospin': autoSpin ? '0.15' : '0',
    'camera': '0',
  };
  final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
  return 'https://sketchfab.com/models/$modelId/embed?$query';
}

Widget buildSketchfabViewer({
  required String modelId,
  required bool autoSpin,
  required Widget fallback,
}) {
  final src = sketchfabEmbedUrl(modelId, autoSpin: autoSpin);
  final viewType = 'sketchfab-$modelId-${autoSpin ? 'spin' : 'static'}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final frame = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'transparent'
        ..allowFullscreen = true
        ..setAttribute(
          'allow',
          'autoplay; fullscreen; xr-spatial-tracking; gyroscope; accelerometer',
        );
      return frame;
    });
  }
  return HtmlElementView(viewType: viewType);
}
