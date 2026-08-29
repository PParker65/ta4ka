import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ShopMapPin {
  const ShopMapPin({
    required this.lat,
    required this.lng,
    this.label = '',
    this.here = false,
  });

  final double lat;
  final double lng;
  final String label;
  final bool here;
}

class GoogleMiniMap extends StatelessWidget {
  const GoogleMiniMap({
    super.key,
    required this.lat,
    required this.lng,
    this.label = '',
    this.height = 240,
    this.pins = const [],
  });

  final double lat;
  final double lng;
  final String label;
  final double height;
  final List<ShopMapPin> pins;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: const Color(0xFF0A0A0C),
          child: _CartoTileMap(
            lat: lat,
            lng: lng,
            pins: pins.isEmpty
                ? [ShopMapPin(lat: lat, lng: lng, here: true, label: label)]
                : pins,
            fallbackColor: palette.accent,
          ),
        ),
      ),
    );
  }
}

class _CartoTileMap extends StatelessWidget {
  const _CartoTileMap({
    required this.lat,
    required this.lng,
    required this.pins,
    required this.fallbackColor,
  });

  final double lat;
  final double lng;
  final List<ShopMapPin> pins;
  final Color fallbackColor;

  static const _z = 14;
  static const _tile = 256.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0 || !w.isFinite || !h.isFinite) {
          return const SizedBox.shrink();
        }
        final n = 1 << _z;
        final cx = _lngToX(lng, _z);
        final cy = _latToY(lat, _z);
        final originX = cx * _tile - w / 2;
        final originY = cy * _tile - h / 2;
        final x0 = (originX / _tile).floor();
        final y0 = (originY / _tile).floor();
        final x1 = ((originX + w) / _tile).ceil();
        final y1 = ((originY + h) / _tile).ceil();
        final subs = ['a', 'b', 'c', 'd'];

        return IgnorePointer(
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (var x = x0; x <= x1; x++)
                  for (var y = y0; y <= y1; y++)
                    if (y >= 0 && y < n)
                      Positioned(
                        left: x * _tile - originX,
                        top: y * _tile - originY,
                        width: _tile,
                        height: _tile,
                        child: Image.network(
                          'https://${subs[(x.abs() + y.abs()) % 4]}.basemaps.cartocdn.com/dark_all/$_z/${_wrap(x, n)}/$y.png',
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFF141416),
                          ),
                        ),
                      ),
                for (final pin in pins)
                  Positioned(
                    left: _lngToX(pin.lng, _z) * _tile - originX - (pin.here ? 8 : 5),
                    top: _latToY(pin.lat, _z) * _tile - originY - (pin.here ? 8 : 5),
                    child: Container(
                      width: pin.here ? 16 : 10,
                      height: pin.here ? 16 : 10,
                      decoration: BoxDecoration(
                        color: pin.here ? const Color(0xFFFF453A) : fallbackColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8E8ED), width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _lngToX(double lng, int z) => (lng + 180.0) / 360.0 * (1 << z);

  static double _latToY(double lat, int z) {
    final clamped = lat.clamp(-85.0511, 85.0511);
    final s = math.sin(clamped * math.pi / 180);
    return (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * (1 << z);
  }

  static int _wrap(int v, int n) {
    final m = v % n;
    return m < 0 ? m + n : m;
  }
}
