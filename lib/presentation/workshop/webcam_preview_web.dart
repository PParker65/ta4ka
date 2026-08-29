// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

const _viewType = 'shop-webcam';
html.MediaStream? _stream;
bool _registered = false;

Future<bool> attachShopWebcam() async {
  final devices = html.window.navigator.mediaDevices;
  if (devices == null) {
    return false;
  }
  try {
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = await devices.getUserMedia({
      'video': {'facingMode': 'user'},
      'audio': false,
    });
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        return html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..srcObject = _stream
          ..style.border = 'none'
          ..style.objectFit = 'cover'
          ..style.width = '100%'
          ..style.height = '100%';
      });
      _registered = true;
    }
    return true;
  } catch (_) {
    _stream = null;
    return false;
  }
}

void detachShopWebcam() {
  _stream?.getTracks().forEach((track) => track.stop());
  _stream = null;
}

Widget? shopWebcamView() {
  if (_stream == null) {
    return null;
  }
  return const HtmlElementView(viewType: _viewType);
}
