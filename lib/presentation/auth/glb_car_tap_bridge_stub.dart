import 'dart:async';

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

  StreamSubscription<GlbCarTapEvent>? _sub;

  void listen(GlbCarTapHandler onTap, {VoidCallback? onLoaded}) {}

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
