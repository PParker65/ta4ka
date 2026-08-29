import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Apple-style charcoal gradient — no chroma, no photos.
class CategorySceneBackdrop extends StatelessWidget {
  const CategorySceneBackdrop({
    super.key,
    this.sphereId,
    this.dim = 0.48,
  });

  final String? sphereId;
  final double dim;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final top = palette.isDark
        ? const Color(0xFF1A1A1D)
        : const Color(0xFFECECEF);
    final mid = palette.bg;
    final bottom = palette.isDark
        ? const Color(0xFF050506)
        : const Color(0xFFD8D8DC);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            top,
            mid,
            Color.lerp(mid, palette.carbon, 0.45)!,
            bottom,
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.72, -0.65),
            radius: 1.2,
            colors: [
              palette.text.withValues(alpha: palette.isDark ? 0.06 : 0.04),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
