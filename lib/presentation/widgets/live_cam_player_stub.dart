import 'package:flutter/material.dart';

import '../../data/live_cams.dart';

class LiveCamPlayer extends StatelessWidget {
  const LiveCamPlayer({
    super.key,
    required this.cam,
    this.compact = false,
  });

  final LiveCam cam;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final thumb = cam.thumbUrl;
    if (thumb.isEmpty) {
      return const ColoredBox(color: Color(0xFF1C1C1E));
    }
    return Image.network(
      thumb,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1C1C1E)),
    );
  }
}
