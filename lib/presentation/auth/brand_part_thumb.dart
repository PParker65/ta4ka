import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/auto_spheres.dart';
import '../../data/car_brands.dart';

class BrandPartThumb extends StatelessWidget {
  const BrandPartThumb({
    super.key,
    required this.brand,
    required this.sphere,
    this.compact = false,
    this.radius,
  });

  final CarBrand brand;
  final AutoSphere sphere;
  final bool compact;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final clip = radius ?? (compact ? 12.0 : 16.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(clip),
      child: ColoredBox(
        color: const Color(0xFF111111),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.16, -0.04, -0.04, 0, 10,
                -0.04, 1.16, -0.04, 0, 10,
                -0.04, -0.04, 1.16, 0, 10,
                0, 0, 0, 1, 0,
              ]),
              child: Image.asset(
                sphere.imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                cacheWidth: compact ? 160 : 480,
                errorBuilder: (_, __, ___) => CustomPaint(
                  painter: _AutoPartPainter(brand: brand, sphereId: sphere.id),
                ),
              ),
            ),
            CustomPaint(
              painter: PartAccentPainter(
                sphereId: sphere.id,
                brandColor: brand.bodyColor,
              ),
              child: const SizedBox.expand(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.18, -0.72),
                  radius: 1.15,
                  colors: [
                    Color(0x38FFF4E4),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selective-color accents on dark shop photos — one or two vivid parts.
/// Tiles that already ship with baked-in color (engine oil, red calipers,
/// cyan coding, USA flags) stay untouched.
class PartAccentPainter extends CustomPainter {
  const PartAccentPainter({
    required this.sphereId,
    this.brandColor = const Color(0xFF8E8E93),
  });

  final String sphereId;
  final Color brandColor;

  static const _amber = Color(0xFFFF9F0A);
  static const _red = Color(0xFFFF3B30);
  static const _cyan = Color(0xFF64D2FF);
  static const _green = Color(0xFF34C759);
  static const _purple = Color(0xFFAF52DE);
  static const _blue = Color(0xFF007AFF);
  static const _yellow = Color(0xFFFFCC00);
  static const _teal = Color(0xFF5AC8FA);

  /// Photos that already have a cinematic accent baked in.
  static const _bakedColor = {
    'engine',
    'brakes',
    'coding',
    'electronics',
    'service',
    'diag',
    'interior',
    'tow',
    'ceramic',
    'lights',
    'glass',
    'mobile',
    'ac',
    'radiator',
    'usa',
    'stage3',
    'adas',
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || _bakedColor.contains(sphereId)) {
      return;
    }
    switch (_partKind(sphereId)) {
      case _Kind.engine:
        _oil(canvas, size);
      case _Kind.gauges:
        _cyanGlow(canvas, size);
      case _Kind.chassis:
        sphereId == 'steering' ? _hydraulics(canvas, size) : _coil(canvas, size);
      case _Kind.brakes:
        _caliper(canvas, size);
      case _Kind.wheel:
        sphereId == 'align' ? _hunter(canvas, size) : _rimLip(canvas, size);
      case _Kind.body:
        _bodyAccent(canvas, size);
      case _Kind.glass:
        _glassTint(canvas, size);
      case _Kind.seat:
        _leather(canvas, size);
      case _Kind.exhaust:
        _heatTint(canvas, size);
      case _Kind.wash:
        _foam(canvas, size);
      case _Kind.ac:
        _gaugesPair(canvas, size);
      case _Kind.tow:
        _strap(canvas, size);
      case _Kind.insurance:
        _shield(canvas, size);
      case _Kind.carbon:
        _film(canvas, size);
      case _Kind.usa:
        break;
    }
  }

  Paint _fill(Color color, {double alpha = 0.82, double blur = 1.4}) {
    return Paint()
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  }

  Paint _stroke(Color color, double width, {double alpha = 0.9, double blur = 0.8}) {
    return Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  }

  void _oil(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drip = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..quadraticBezierTo(w * 0.34, h * 0.38, w * 0.30, h * 0.52)
      ..quadraticBezierTo(w * 0.26, h * 0.40, w * 0.28, h * 0.18);
    canvas.drawPath(drip, _fill(_amber, alpha: 0.88, blur: 2));
    canvas.drawCircle(Offset(w * 0.62, h * 0.42), size.shortestSide * 0.09, _fill(_amber, alpha: 0.55));
  }

  void _cyanGlow(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.68, size.height * 0.42),
          width: size.width * 0.34,
          height: size.height * 0.28,
        ),
        const Radius.circular(6),
      ),
      _fill(_cyan, alpha: 0.55, blur: 3),
    );
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.58),
      size.shortestSide * 0.07,
      _fill(_teal, alpha: 0.7),
    );
  }

  void _coil(Canvas canvas, Size size) {
    final x = size.width * 0.50;
    final top = size.height * 0.20;
    final bot = size.height * 0.70;
    final coil = _stroke(_amber, size.shortestSide * 0.048, alpha: 0.92, blur: 1.1);
    for (var i = 0; i < 6; i++) {
      final y = top + i * ((bot - top) / 6);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, y), width: size.width * 0.28, height: size.height * 0.10),
        0,
        math.pi,
        false,
        coil,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, (top + bot) / 2),
          width: size.width * 0.08,
          height: bot - top,
        ),
        const Radius.circular(5),
      ),
      _fill(_green, alpha: 0.42, blur: 2),
    );
  }

  void _hydraulics(Canvas canvas, Size size) {
    final y = size.height * 0.38;
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * 0.18, y + i * size.height * 0.055),
        Offset(size.width * 0.78, y + i * size.height * 0.04),
        _stroke(_red, size.shortestSide * 0.028, alpha: 0.8, blur: 1.2),
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.shortestSide * 0.055,
      _fill(_amber, alpha: 0.75),
    );
  }

  void _caliper(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.62, size.height * 0.50);
    final r = size.shortestSide * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx + r * 0.55, c.dy), width: r * 0.7, height: r * 1.15),
        const Radius.circular(7),
      ),
      _fill(_red, alpha: 0.82, blur: 1.6),
    );
  }

  void _hunter(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.58, size.height * 0.36);
    final gap = size.shortestSide * 0.085;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(origin.dx + col * gap, origin.dy + row * gap),
          size.shortestSide * 0.028,
          _fill(_cyan, alpha: 0.88, blur: 1.2),
        );
      }
    }
  }

  void _rimLip(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.42, size.height * 0.58);
    final r = size.shortestSide * 0.28;
    canvas.drawCircle(c, r, _stroke(_amber, r * 0.16, alpha: 0.85, blur: 1.4));
    canvas.drawCircle(c, r * 0.22, _fill(_yellow, alpha: 0.55));
  }

  void _bodyAccent(Canvas canvas, Size size) {
    final color = sphereId == 'welding' || sphereId == 'anticor'
        ? _amber
        : (brandColor.computeLuminance() > 0.12 ? brandColor : _purple);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.28, size.height * 0.32, size.width * 0.38, size.height * 0.28),
        const Radius.circular(8),
      ),
      _fill(color, alpha: 0.55, blur: 3),
    );
    if (sphereId == 'welding') {
      for (var i = 0; i < 5; i++) {
        final a = -0.8 + i * 0.35;
        canvas.drawLine(
          Offset(size.width * 0.55, size.height * 0.40),
          Offset(size.width * 0.55 + math.cos(a) * size.width * 0.18, size.height * 0.40 + math.sin(a) * size.height * 0.16),
          _stroke(_yellow, 2.2, alpha: 0.8),
        );
      }
    }
  }

  void _glassTint(Canvas canvas, Size size) {
    final glass = Path()
      ..moveTo(size.width * 0.22, size.height * 0.28)
      ..lineTo(size.width * 0.78, size.height * 0.24)
      ..lineTo(size.width * 0.86, size.height * 0.62)
      ..lineTo(size.width * 0.16, size.height * 0.66)
      ..close();
    canvas.drawPath(glass, _fill(_cyan, alpha: 0.42, blur: 2.5));
  }

  void _leather(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.22, size.height * 0.38, size.width * 0.46, size.height * 0.28),
        const Radius.circular(10),
      ),
      _fill(const Color(0xFFD4A574), alpha: 0.7, blur: 2),
    );
  }

  void _heatTint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, size.height * 0.58),
        width: size.width * 0.42,
        height: size.height * 0.22,
      ),
      _fill(_amber, alpha: 0.55, blur: 3),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.52),
        width: size.width * 0.22,
        height: size.height * 0.14,
      ),
      _fill(_teal, alpha: 0.45, blur: 2),
    );
  }

  void _foam(Canvas canvas, Size size) {
    final drop = _fill(_cyan, alpha: 0.8, blur: 1.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.72, size.height * 0.28), width: 14, height: 20), drop);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.58, size.height * 0.22), width: 11, height: 16), drop);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.80, size.height * 0.44), width: 10, height: 14), drop);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.52), size.shortestSide * 0.08, _fill(_teal, alpha: 0.4, blur: 3));
  }

  void _gaugesPair(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.42), size.shortestSide * 0.12, _stroke(_cyan, 5, alpha: 0.85));
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.42), size.shortestSide * 0.12, _stroke(_red, 5, alpha: 0.85));
  }

  void _strap(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.28),
      Offset(size.width * 0.18, size.height * 0.72),
      _stroke(_yellow, 4.2, alpha: 0.9),
    );
  }

  void _shield(Canvas canvas, Size size) {
    final shield = Path()
      ..moveTo(size.width * 0.78, size.height * 0.18)
      ..lineTo(size.width * 0.90, size.height * 0.24)
      ..lineTo(size.width * 0.90, size.height * 0.42)
      ..lineTo(size.width * 0.78, size.height * 0.54)
      ..lineTo(size.width * 0.66, size.height * 0.42)
      ..lineTo(size.width * 0.66, size.height * 0.24)
      ..close();
    canvas.drawPath(shield, _fill(_blue, alpha: 0.78, blur: 1.4));
  }

  void _film(Canvas canvas, Size size) {
    final color = sphereId == 'hydro' ? _cyan : (sphereId == 'wrap' ? _purple : _teal);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.18, size.width * 0.22, size.height * 0.62),
        const Radius.circular(4),
      ),
      _fill(color, alpha: 0.55, blur: 2.2),
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.22),
      _stroke(color, 3.4, alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant PartAccentPainter oldDelegate) {
    return oldDelegate.sphereId != sphereId || oldDelegate.brandColor != brandColor;
  }
}

enum _Kind {
  engine,
  gauges,
  chassis,
  brakes,
  wheel,
  body,
  glass,
  seat,
  exhaust,
  wash,
  ac,
  tow,
  insurance,
  carbon,
  usa,
}

_Kind _partKind(String sphereId) {
  switch (sphereId) {
    case 'engine':
    case 'stage3':
    case 'tuning':
    case 'service':
    case 'turbo':
    case 'injectors':
    case 'radiator':
    case 'dpf':
    case 'gearbox':
    case 'clutch':
    case 'starter':
    case 'lpg':
      return _Kind.engine;
    case 'electronics':
    case 'coding':
    case 'diag':
    case 'adas':
    case 'android':
    case 'keys':
    case 'alarm':
    case 'srs':
    case 'mobile':
      return _Kind.gauges;
    case 'chassis':
    case 'steering':
    case 'cvjoint':
      return _Kind.chassis;
    case 'brakes':
      return _Kind.brakes;
    case 'tires':
    case 'align':
    case 'rims':
      return _Kind.wheel;
    case 'glass':
    case 'lights':
      return _Kind.glass;
    case 'interior':
    case 'sound':
    case 'soundproof':
    case 'chem-clean':
      return _Kind.seat;
    case 'exhaust':
      return _Kind.exhaust;
    case 'wash':
    case 'ceramic':
    case 'ppf':
      return _Kind.wash;
    case 'ac':
      return _Kind.ac;
    case 'tow':
      return _Kind.tow;
    case 'insurance':
    case 'prebuy':
      return _Kind.insurance;
    case 'carbon':
    case 'wrap':
    case 'hydro':
      return _Kind.carbon;
    case 'usa':
      return _Kind.usa;
    default:
      return _Kind.body;
  }
}

class _AutoPartPainter extends CustomPainter {
  _AutoPartPainter({required this.brand, required this.sphereId});

  final CarBrand brand;
  final String sphereId;

  _Kind get _kind => _partKind(sphereId);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF111111));
    switch (_kind) {
      case _Kind.engine:
        _engine(canvas, size);
      case _Kind.gauges:
        _gauges(canvas, size);
      case _Kind.chassis:
        _chassis(canvas, size);
      case _Kind.brakes:
        _brakes(canvas, size);
      case _Kind.wheel:
        _wheel(canvas, size, focus: true);
      case _Kind.body:
        _body(canvas, size, brand.bodyColor);
      case _Kind.glass:
        _glass(canvas, size);
      case _Kind.seat:
        _seat(canvas, size);
      case _Kind.exhaust:
        _exhaust(canvas, size);
      case _Kind.wash:
        _wash(canvas, size);
      case _Kind.ac:
        _ac(canvas, size);
      case _Kind.tow:
        _tow(canvas, size);
      case _Kind.insurance:
        _insurance(canvas, size);
      case _Kind.carbon:
        _carbon(canvas, size);
      case _Kind.usa:
        _usa(canvas, size);
    }
  }

  void _engine(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.54;
    final w = size.width * 0.72;
    final h = size.height * 0.42;
    final block = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(6),
    );
    canvas.drawRRect(block, Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - h * 0.22), width: w * 0.86, height: h * 0.28),
        const Radius.circular(4),
      ),
      Paint()..color = brand.bodyColor,
    );
    final cyl = Paint()..color = const Color(0xFF1C1C1C);
    final n = brand.engineKind == EngineKind.v8 ? 4 : 3;
    for (var i = 0; i < n; i++) {
      final x = cx - w * 0.32 + i * (w * 0.64 / math.max(1, n - 1));
      canvas.drawCircle(Offset(x, cy - h * 0.48), size.shortestSide * 0.055, cyl);
      canvas.drawCircle(Offset(x, cy - h * 0.48), size.shortestSide * 0.028, Paint()..color = const Color(0xFF8E8E93));
    }
    canvas.drawCircle(
      Offset(cx + w * 0.42, cy + h * 0.08),
      size.shortestSide * 0.11,
      Paint()..color = const Color(0xFF2C2C2E),
    );
    canvas.drawCircle(
      Offset(cx + w * 0.42, cy + h * 0.08),
      size.shortestSide * 0.06,
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _gauges(Canvas canvas, Size size) {
    final y = size.height * 0.46;
    _gauge(canvas, Offset(size.width * 0.32, y), size.shortestSide * 0.28, 0.72);
    _gauge(canvas, Offset(size.width * 0.68, y), size.shortestSide * 0.28, 0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.78), width: size.width * 0.34, height: size.height * 0.12),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF1C4B73),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.78), width: size.width * 0.26, height: size.height * 0.05),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF64D2FF),
    );
  }

  void _gauge(Canvas canvas, Offset c, double r, double needle) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final tick = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 11; i++) {
      final a = -2.4 + i * 4.8 / 10;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.72, c.dy + math.sin(a) * r * 0.72),
        Offset(c.dx + math.cos(a) * r * 0.88, c.dy + math.sin(a) * r * 0.88),
        tick,
      );
    }
    final a = -2.4 + needle * 4.8;
    canvas.drawLine(
      c,
      Offset(c.dx + math.cos(a) * r * 0.7, c.dy + math.sin(a) * r * 0.7),
      Paint()
        ..color = brand.bodyColor
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, r * 0.1, Paint()..color = Colors.white);
  }

  void _chassis(Canvas canvas, Size size) {
    _wheelAt(canvas, Offset(size.width * 0.28, size.height * 0.62), size.shortestSide * 0.22, false);
    final x = size.width * 0.62;
    final top = size.height * 0.18;
    final bot = size.height * 0.62;
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bot),
      Paint()
        ..color = const Color(0xFF8E8E93)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final coil = Paint()
      ..color = const Color(0xFFFF9F0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    for (var i = 0; i < 5; i++) {
      final y = top + 12 + i * ((bot - top - 28) / 5);
      canvas.drawArc(Rect.fromCenter(center: Offset(x, y), width: 22, height: 14), 0, math.pi, false, coil);
    }
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.62),
      Offset(x, bot),
      Paint()
        ..color = const Color(0xFFC7C7CC)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _brakes(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.46, size.height * 0.52);
    final r = size.shortestSide * 0.36;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2C2C2E));
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..color = const Color(0xFF8E8E93)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r * 0.52, c.dy + math.sin(a) * r * 0.52),
        r * 0.07,
        Paint()..color = const Color(0xFF111111),
      );
    }
    canvas.drawCircle(c, r * 0.18, Paint()..color = const Color(0xFFD1D1D6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx + r * 0.72, c.dy), width: r * 0.42, height: r * 0.7),
        const Radius.circular(6),
      ),
      Paint()..color = brand.bodyColor,
    );
  }

  void _wheel(Canvas canvas, Size size, {required bool focus}) {
    _wheelAt(canvas, Offset(size.width * 0.5, size.height * 0.54), size.shortestSide * 0.38, focus);
  }

  void _wheelAt(Canvas canvas, Offset c, double r, bool focus) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(
      c,
      r * 0.78,
      Paint()
        ..color = focus ? brand.bodyColor : const Color(0xFF8E8E93)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12,
    );
    final spokes = brand.wheelSpokes.clamp(5, 10);
    final spoke = Paint()
      ..color = const Color(0xFFD1D1D6)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < spokes; i++) {
      final a = i * math.pi * 2 / spokes;
      canvas.drawLine(c, Offset(c.dx + math.cos(a) * r * 0.58, c.dy + math.sin(a) * r * 0.58), spoke);
    }
    canvas.drawCircle(c, r * 0.14, Paint()..color = const Color(0xFF3A3A3C));
  }

  void _body(Canvas canvas, Size size, Color color) {
    canvas.drawPath(_sedan(size), Paint()..color = color);
    canvas.drawPath(
      _sedan(size),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _wheelAt(canvas, Offset(size.width * 0.28, size.height * 0.74), size.height * 0.13, false);
    _wheelAt(canvas, Offset(size.width * 0.72, size.height * 0.74), size.height * 0.13, false);
  }

  Path _sedan(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.05, h * 0.74)
      ..lineTo(w * 0.09, h * 0.56)
      ..lineTo(w * 0.20, h * 0.48)
      ..lineTo(w * 0.38, h * 0.27)
      ..lineTo(w * 0.56, h * 0.25)
      ..lineTo(w * 0.78, h * 0.46)
      ..lineTo(w * 0.95, h * 0.54)
      ..lineTo(w * 0.97, h * 0.74)
      ..close();
  }

  void _glass(Canvas canvas, Size size) {
    _body(canvas, size, brand.bodyColor.withValues(alpha: 0.35));
    final glass = Path()
      ..moveTo(size.width * 0.38, size.height * 0.29)
      ..lineTo(size.width * 0.56, size.height * 0.27)
      ..lineTo(size.width * 0.74, size.height * 0.45)
      ..lineTo(size.width * 0.32, size.height * 0.46)
      ..close();
    canvas.drawPath(glass, Paint()..color = const Color(0xAA64D2FF));
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.40),
      Offset(size.width * 0.58, size.height * 0.28),
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _seat(Canvas canvas, Size size) {
    final x = size.width * 0.42;
    final seat = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, size.height * 0.48, size.width * 0.38, size.height * 0.22),
      const Radius.circular(8),
    );
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + size.width * 0.22, size.height * 0.16, size.width * 0.16, size.height * 0.40),
      const Radius.circular(8),
    );
    canvas.drawRRect(back, Paint()..color = const Color(0xFF2C2C2E));
    canvas.drawRRect(seat, Paint()..color = const Color(0xFF3A3A3C));
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.42),
      size.shortestSide * 0.16,
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.42), 5, Paint()..color = brand.bodyColor);
  }

  void _exhaust(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.38, size.width * 0.55, size.height * 0.28),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF3A3A3C),
    );
    final tips = brand.exhaustTips == 0 ? 0 : brand.exhaustTips.clamp(2, 4);
    for (var i = 0; i < (tips == 0 ? 0 : tips); i++) {
      final y = size.height * 0.42 + i * (size.height * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.62, y, size.width * 0.26, size.height * 0.10),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFC7C7CC),
      );
      canvas.drawCircle(Offset(size.width * 0.84, y + size.height * 0.05), size.height * 0.035, Paint()..color = const Color(0xFF1C1C1C));
    }
    if (tips == 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.62, size.height * 0.44, size.width * 0.22, size.height * 0.16),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF64D2FF).withValues(alpha: 0.5),
      );
    }
  }

  void _wash(Canvas canvas, Size size) {
    _body(canvas, size, brand.bodyColor);
    final drop = Paint()..color = const Color(0xAA64D2FF);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.22, size.height * 0.22), width: 8, height: 12), drop);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.48, size.height * 0.14), width: 10, height: 14), drop);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.78, size.height * 0.24), width: 8, height: 12), drop);
  }

  void _ac(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      Paint()..color = const Color(0xFF1C1C1E),
    );
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(size.width * 0.12 + i * size.width * 0.28, size.height * 0.28, size.width * 0.22, size.height * 0.44);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = const Color(0xFF2C2C2E));
      for (var k = 0; k < 4; k++) {
        canvas.drawLine(
          Offset(rect.left + 4, rect.top + 8 + k * rect.height * 0.22),
          Offset(rect.right - 4, rect.top + 8 + k * rect.height * 0.22),
          Paint()
            ..color = const Color(0xFF64D2FF)
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _tow(Canvas canvas, Size size) {
    _body(canvas, size, brand.bodyColor);
    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.30),
      Offset(size.width * 0.08, size.height * 0.72),
      Paint()
        ..color = const Color(0xFFFFCC00)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.28), 5, Paint()..color = const Color(0xFFFFCC00));
  }

  void _insurance(Canvas canvas, Size size) {
    _body(canvas, size, brand.bodyColor);
    final shield = Path()
      ..moveTo(size.width * 0.78, size.height * 0.16)
      ..lineTo(size.width * 0.92, size.height * 0.22)
      ..lineTo(size.width * 0.92, size.height * 0.40)
      ..lineTo(size.width * 0.78, size.height * 0.52)
      ..lineTo(size.width * 0.64, size.height * 0.40)
      ..lineTo(size.width * 0.64, size.height * 0.22)
      ..close();
    canvas.drawPath(shield, Paint()..color = const Color(0xFF007AFF).withValues(alpha: 0.92));
  }

  void _carbon(Canvas canvas, Size size) {
    _body(canvas, size, const Color(0xFF2C2C2E));
    final weave = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 10; i++) {
      canvas.drawLine(Offset(size.width * 0.1 + i * 8, size.height * 0.2), Offset(size.width * 0.2 + i * 8, size.height * 0.7), weave);
    }
  }

  /// Turnkey US→UA delivery still-life: dock, container ship, sedan, enamel flags, keys.
  void _usa(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = size.shortestSide;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1C), Color(0xFF0E0E10), Color(0xFF161820)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.42, h * 0.18), width: w * 0.7, height: h * 0.28),
      Paint()..color = const Color(0x28FFF4E4),
    );

    final water = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.28, h * 0.56, w * 0.52, h * 0.60)
      ..quadraticBezierTo(w * 0.78, h * 0.65, w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(water, Paint()..color = const Color(0xFF1A3048));
    final ripple = Paint()
      ..color = const Color(0x668EAECC)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.08, h * 0.72), Offset(w * 0.38, h * 0.70), ripple);
    canvas.drawLine(Offset(w * 0.48, h * 0.78), Offset(w * 0.86, h * 0.74), ripple);

    final hull = Path()
      ..moveTo(w * 0.14, h * 0.54)
      ..lineTo(w * 0.22, h * 0.46)
      ..lineTo(w * 0.72, h * 0.46)
      ..lineTo(w * 0.82, h * 0.52)
      ..lineTo(w * 0.76, h * 0.60)
      ..lineTo(w * 0.18, h * 0.60)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF3A3A3C));
    canvas.drawPath(
      hull,
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.38, w * 0.12, h * 0.10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF2C2C2E),
    );
    const boxes = [
      Color(0xFF8B1E1E),
      Color(0xFF1C3D8A),
      Color(0xFF3A3A3C),
      Color(0xFFC7C7CC),
      Color(0xFF1C4B73),
      Color(0xFF8E8E93),
    ];
    for (var i = 0; i < 6; i++) {
      final col = i % 3;
      final row = i ~/ 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * 0.40 + col * w * 0.11,
            h * 0.30 + row * h * 0.08,
            w * 0.10,
            h * 0.075,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = boxes[i],
      );
    }

    canvas.save();
    canvas.translate(w * 0.08, h * 0.08);
    canvas.scale(0.62, 0.62);
    _body(canvas, size, brand.bodyColor);
    canvas.restore();

    _flagPlate(
      canvas,
      Rect.fromLTWH(w * 0.68, h * 0.16, s * 0.22, s * 0.14),
      us: true,
    );
    _flagPlate(
      canvas,
      Rect.fromLTWH(w * 0.78, h * 0.28, s * 0.22, s * 0.14),
      us: false,
    );

    final keyC = Offset(w * 0.78, h * 0.78);
    canvas.drawOval(
      Rect.fromCenter(center: keyC, width: s * 0.16, height: s * 0.11),
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(keyC.dx + s * 0.14, keyC.dy), width: s * 0.18, height: s * 0.07),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFC7C7CC),
    );
    canvas.drawCircle(keyC, 3.2, Paint()..color = brand.bodyColor);
  }

  void _flagPlate(Canvas canvas, Rect rect, {required bool us}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF2C2C2E),
    );
    final inner = rect.deflate(2.2);
    if (us) {
      canvas.drawRect(inner, Paint()..color = const Color(0xFFB22234));
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(inner.left, inner.top + inner.height * (0.18 + i * 0.28), inner.width, inner.height * 0.10),
          Paint()..color = const Color(0xFFF2F2F7),
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.top, inner.width * 0.42, inner.height * 0.52),
        Paint()..color = const Color(0xFF1C3D8A),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.5),
        Paint()..color = const Color(0xFF005BBB),
      );
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.center.dy, inner.width, inner.height * 0.5),
        Paint()..color = const Color(0xFFFFD500),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _AutoPartPainter oldDelegate) {
    return oldDelegate.brand.id != brand.id || oldDelegate.sphereId != sphereId;
  }
}
