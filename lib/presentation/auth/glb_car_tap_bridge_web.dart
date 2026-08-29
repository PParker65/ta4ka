// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

typedef GlbCarTapHandler = void Function(GlbCarTapEvent event);

class GlbCarTapEvent {
  const GlbCarTapEvent({
    required this.local,
    required this.size,
    required this.theta,
    required this.phi,
    this.zoomed = true,
  });

  final Offset local;
  final Size size;
  final double theta;
  final double phi;
  final bool zoomed;
}

class GlbCarTapBridge {
  GlbCarTapBridge();

  StreamSubscription<html.MessageEvent>? _sub;

  void listen(GlbCarTapHandler onTap, {VoidCallback? onLoaded}) {
    _sub?.cancel();
    _sub = html.window.onMessage.listen((event) {
      final raw = event.data;
      if (raw is! String || !raw.startsWith('{')) {
        return;
      }
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final type = map['type'];
        if (type == 'glb-loaded') {
          onLoaded?.call();
          return;
        }
        if (type != 'autoservice-car-tap') {
          return;
        }
        onTap(
          GlbCarTapEvent(
            local: Offset(
              (map['x'] as num).toDouble(),
              (map['y'] as num).toDouble(),
            ),
            size: Size(
              (map['w'] as num).toDouble(),
              (map['h'] as num).toDouble(),
            ),
            theta: (map['theta'] as num).toDouble(),
            phi: (map['phi'] as num).toDouble(),
            zoomed: map['zoomed'] == true,
          ),
        );
      } catch (_) {}
    });
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
