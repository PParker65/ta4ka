import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/usa_delivery.dart';
import 'usa_intro.dart';

/// Round enamel scene for one USA pipeline step — Copart-yard / pay / ship / keys.
class UsaPipelineNode extends StatelessWidget {
  const UsaPipelineNode({
    super.key,
    required this.scene,
    required this.on,
    required this.done,
    required this.loop,
  });

  final UsaPipelineScene scene;
  final bool on;
  final bool done;
  final double loop;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: UsaPipelineNodePainter(
        scene: scene,
        on: on,
        done: done,
        loop: loop,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class UsaPipelineNodePainter extends CustomPainter {
  UsaPipelineNodePainter({
    required this.scene,
    required this.on,
    required this.done,
    required this.loop,
  });

  final UsaPipelineScene scene;
  final bool on;
  final bool done;
  final double loop;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final disc = r * (on ? 0.86 : 0.80);

    if (on) {
      canvas.drawCircle(
        c,
        disc + 9,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            disc + 9,
            [
              kLTransRed.withValues(alpha: 0.55),
              kLTransRed.withValues(alpha: 0.12),
              const Color(0x00D70200),
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: disc)));
    canvas.translate(c.dx - disc, c.dy - disc);
    final box = Size(disc * 2, disc * 2);
    switch (scene) {
      case UsaPipelineScene.auction:
        _auction(canvas, box);
      case UsaPipelineScene.pay:
        _pay(canvas, box);
      case UsaPipelineScene.ship:
        _ship(canvas, box);
      case UsaPipelineScene.keys:
        _keys(canvas, box);
    }
    if (!on && !done) {
      canvas.drawRect(
        Offset.zero & box,
        Paint()..color = const Color(0x72000000),
      );
    } else if (done && !on) {
      canvas.drawRect(
        Offset.zero & box,
        Paint()..color = const Color(0x28000000),
      );
    }
    canvas.restore();

    canvas.drawCircle(
      c,
      disc,
      Paint()
        ..color = on ? Colors.white : const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = on ? 2.2 : 1.15,
    );

    final fill = _nodeFill;
    if (fill > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: disc + 1.2),
        -math.pi / 2,
        fill * math.pi * 2,
        false,
        Paint()
          ..color = kLTransRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 2.6 : 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// 0–1 how far this node is filled on the looping bar.
  double get _nodeFill {
    final i = scene.index;
    return ((loop * 4) - i).clamp(0.0, 1.0);
  }

  double get _local => _nodeFill;

  void _auction(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strike = Curves.easeInOutCubic.transform((_local * 1.15).clamp(0.0, 1.0));
    final gavelA = -0.78 + 0.92 * strike;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h),
          const [Color(0xFF2A2418), Color(0xFF14120E), Color(0xFF0C0C0E)],
          const [0.0, 0.42, 1.0],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.42, h * 0.06), width: w * 1.05, height: h * 0.48),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.42, h * 0.08),
          w * 0.58,
          const [Color(0x88FFE7B0), Color(0x33C9A227), Color(0x00000000)],
          const [0.0, 0.42, 1.0],
        ),
    );

    canvas.drawRect(Rect.fromLTWH(0, h * 0.56, w, h * 0.44), Paint()..color = const Color(0xFF1A1A1C));
    final bay = Paint()
      ..color = const Color(0x44E8D090)
      ..strokeWidth = math.max(1.1, w * 0.016);
    canvas.drawLine(Offset(w * 0.04, h * 0.78), Offset(w * 0.96, h * 0.70), bay);

    _sedanThreeQuarter(
      canvas,
      Offset(w * 0.44, h * 0.58),
      w * 0.62,
      const Color(0xFF9A9AA2),
      lamp: const Color(0xFFFFE082),
    );

    // Yellow hang-tag — salvage-lot sticker, not a trademark wordmark.
    final tag = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..lineTo(w * 0.30, h * 0.16)
      ..lineTo(w * 0.36, h * 0.38)
      ..lineTo(w * 0.14, h * 0.44)
      ..close();
    canvas.drawPath(tag, Paint()..color = const Color(0xFFF5D000));
    canvas.drawPath(
      tag,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(Offset(w * 0.14, h * 0.24), w * 0.028, Paint()..color = const Color(0xFF111111));
    final bar = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = math.max(1.6, w * 0.028)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.18, h * 0.30), Offset(w * 0.30, h * 0.26), bar);
    canvas.drawLine(Offset(w * 0.17, h * 0.36), Offset(w * 0.31, h * 0.32), bar);

    final block = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.58, h * 0.88), width: w * 0.42, height: h * 0.12),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(block, Paint()..color = const Color(0xFF4A2E1A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.58, h * 0.85), width: w * 0.36, height: h * 0.04),
        Radius.circular(w * 0.014),
      ),
      Paint()..color = const Color(0xFF7A4A28),
    );

    canvas.save();
    canvas.translate(w * 0.68, h * 0.76);
    canvas.rotate(gavelA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.38, height: h * 0.14),
        Radius.circular(w * 0.04),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -h * 0.08),
          Offset(0, h * 0.08),
          const [Color(0xFFC4894A), Color(0xFF8B5A2B), Color(0xFF5C3A1E)],
          const [0.0, 0.45, 1.0],
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.28, height: h * 0.05),
        Radius.circular(w * 0.014),
      ),
      Paint()..color = const Color(0x66FFD27A),
    );
    canvas.drawLine(
      Offset(0, h * 0.05),
      Offset(0, h * 0.34),
      Paint()
        ..color = const Color(0xFF5C3A1E)
        ..strokeWidth = w * 0.055
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    if (strike > 0.72) {
      final spark = (strike - 0.72) / 0.28;
      canvas.drawCircle(
        Offset(w * 0.58, h * 0.80),
        w * 0.055 * spark,
        Paint()..color = const Color(0xCCFFE082),
      );
    }
  }

  void _pay(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final slide = Curves.easeOutCubic.transform(_local.clamp(0.0, 1.0));

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h),
          const [Color(0xFF121A24), Color(0xFF0A1016), Color(0xFF07080A)],
          const [0.0, 0.42, 1.0],
        ),
    );

    final ped = Path()
      ..moveTo(w * 0.14, h * 0.30)
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.86, h * 0.30)
      ..close();
    canvas.drawPath(
      ped,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, h * 0.08),
          Offset(w * 0.5, h * 0.30),
          const [Color(0xFF4A5564), Color(0xFF2A3340)],
        ),
    );
    canvas.drawPath(
      ped,
      Paint()
        ..color = const Color(0x88D4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    for (final x in [0.28, 0.42, 0.58, 0.72]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * x, h * 0.42), width: w * 0.085, height: h * 0.24),
          Radius.circular(w * 0.014),
        ),
        Paint()..color = const Color(0xFF3A4452),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(w * 0.16, h * 0.52, w * 0.68, h * 0.055),
      Paint()..color = const Color(0xFFD4AF37),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.62), width: w * 0.70, height: h * 0.08),
        Radius.circular(w * 0.025),
      ),
      Paint()..color = const Color(0xFF050508),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.62), width: w * 0.62, height: h * 0.022),
        Radius.circular(w * 0.012),
      ),
      Paint()..color = Color.lerp(const Color(0xFF1C4B73), const Color(0xFF64D2FF), 0.25 + 0.55 * slide)!,
    );

    final nearY = h * (0.72 + 0.16 * slide);
    final farY = h * 0.64;
    final card = Path()
      ..moveTo(w * 0.24, farY)
      ..lineTo(w * 0.76, farY)
      ..lineTo(w * 0.92, nearY)
      ..lineTo(w * 0.08, nearY)
      ..close();
    canvas.drawShadow(card, Colors.black, 8, false);
    canvas.drawPath(
      card,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, farY),
          Offset(w * 0.5, nearY),
          const [Color(0xFF1A2744), Color(0xFF243656), Color(0xFF1C3D8A)],
          const [0.0, 0.4, 1.0],
        ),
    );
    canvas.drawPath(
      card,
      Paint()
        ..color = const Color(0xCCD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, farY + h * 0.045)
        ..lineTo(w * 0.72, farY + h * 0.045)
        ..lineTo(w * 0.84, nearY - h * 0.09)
        ..lineTo(w * 0.16, nearY - h * 0.09)
        ..close(),
      Paint()..color = kLTransRed,
    );
    final chip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.28, nearY - h * 0.035), width: w * 0.16, height: h * 0.10),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(
      chip,
      Paint()
        ..shader = ui.Gradient.linear(
          chip.outerRect.topLeft,
          chip.outerRect.bottomRight,
          const [Color(0xFFF0D78C), Color(0xFFC9A227), Color(0xFF8B6914)],
        ),
    );
    canvas.drawLine(
      Offset(chip.center.dx - w * 0.04, chip.center.dy),
      Offset(chip.center.dx + w * 0.04, chip.center.dy),
      Paint()
        ..color = const Color(0xFF5C3A1E)
        ..strokeWidth = 0.9,
    );
    canvas.drawLine(
      Offset(w * 0.12, nearY),
      Offset(w * 0.88, nearY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.50 + 0.40 * slide)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _ship(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bob = math.sin(loop * math.pi * 2) * h * 0.022;
    final travel = Curves.easeInOut.transform(_local);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h),
          const [Color(0xFF243048), Color(0xFF101828), Color(0xFF081018)],
          const [0.0, 0.4, 1.0],
        ),
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.20),
      w * 0.16,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.78, h * 0.20),
          w * 0.16,
          const [Color(0xFFFFE082), Color(0x88FFCC80), Color(0x00FFCC80)],
          const [0.0, 0.4, 1.0],
        ),
    );
    canvas.drawCircle(Offset(w * 0.78, h * 0.20), w * 0.07, Paint()..color = const Color(0xFFFFE082));

    canvas.save();
    canvas.translate(0, bob);

    final waterTop = h * 0.58;
    canvas.drawPath(
      Path()
        ..moveTo(0, waterTop)
        ..quadraticBezierTo(w * 0.22, waterTop - h * 0.05, w * 0.48, waterTop)
        ..quadraticBezierTo(w * 0.74, waterTop + h * 0.055, w, waterTop - h * 0.02)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, waterTop),
          Offset(0, h),
          const [Color(0xFF2A6A96), Color(0xFF123048), Color(0xFF0A1A28)],
          const [0.0, 0.42, 1.0],
        ),
    );
    final ripple = Paint()
      ..color = const Color(0x88B8D4E8)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.04, h * 0.70), Offset(w * 0.42, h * 0.67), ripple);
    canvas.drawLine(Offset(w * 0.46, h * 0.80), Offset(w * 0.94, h * 0.75), ripple);

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, h * 0.66)
        ..quadraticBezierTo(w * 0.30, h * 0.80, w * 0.06, h * 0.94)
        ..quadraticBezierTo(w * 0.44, h * 0.78, w * 0.22, h * 0.64)
        ..close(),
      Paint()..color = const Color(0x55F2F2F7),
    );

    final hullY = h * 0.50;
    final hull = Path()
      ..moveTo(w * 0.04, hullY + h * 0.10)
      ..lineTo(w * 0.14, hullY)
      ..lineTo(w * 0.78, hullY)
      ..lineTo(w * 0.96, hullY + h * 0.07)
      ..lineTo(w * 0.88, hullY + h * 0.16)
      ..lineTo(w * 0.08, hullY + h * 0.16)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFF3A3A3C));
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.06, hullY + h * 0.11)
        ..lineTo(w * 0.90, hullY + h * 0.11)
        ..lineTo(w * 0.88, hullY + h * 0.16)
        ..lineTo(w * 0.08, hullY + h * 0.16)
        ..close(),
      Paint()..color = const Color(0xFF8B1E1E),
    );
    canvas.drawPath(
      hull,
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, hullY - h * 0.16, w * 0.18, h * 0.16),
        Radius.circular(w * 0.025),
      ),
      Paint()..color = const Color(0xFF2C2C2E),
    );
    canvas.drawCircle(Offset(w * 0.27, hullY - h * 0.20), w * 0.022, Paint()..color = const Color(0xFFFFE082));

    const boxes = [Color(0xFF1C3D8A), Color(0xFF8E8E93), Color(0xFF1C4B73)];
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.40 + i * w * 0.10, hullY - h * 0.11, w * 0.095, h * 0.10),
          Radius.circular(w * 0.014),
        ),
        Paint()..color = boxes[i],
      );
    }

    final carX = w * (0.30 + 0.18 * travel);
    _sedanSide(canvas, Offset(carX, hullY - h * 0.04), w * 0.46, const Color(0xFFD8D8DE));
    _usCanton(canvas, Rect.fromLTWH(w * 0.80, hullY - h * 0.18, w * 0.14, h * 0.09));

    canvas.restore();
  }

  void _keys(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);
    final swing = math.sin(loop * math.pi * 2) * 0.10;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.42, h * 0.32),
          s * 0.72,
          const [Color(0xFF4A3420), Color(0xFF1C1610), Color(0xFF0A0A0C)],
          const [0.0, 0.48, 1.0],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.40, h * 0.28), width: s * 0.70, height: s * 0.42),
      Paint()..color = const Color(0x44FFE7B0),
    );

    // Whole bunch stays inside the disc: key length ≈ 0.78s, centered on the circle.
    canvas.save();
    canvas.translate(w * 0.50, h * 0.52);
    canvas.rotate(-0.32 + swing);

    _metalKey(canvas, Offset(s * 0.02, s * 0.07), s * 0.70, s * 0.17, 0.38, brass: true);
    _metalKey(canvas, Offset(s * 0.04, 0), s * 0.76, s * 0.20, 0);

    final ringC = Offset(s * -0.20, s * -0.02);
    final ringStroke = math.max(2.4, s * 0.055);
    canvas.drawCircle(
      ringC,
      s * 0.145,
      Paint()
        ..shader = ui.Gradient.linear(
          ringC + Offset(0, -s * 0.16),
          ringC + Offset(0, s * 0.16),
          const [Color(0xFFFFF8E7), Color(0xFFC9A227), Color(0xFFE8D090)],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStroke,
    );
    canvas.drawCircle(
      ringC + Offset(-s * 0.03, -s * 0.04),
      s * 0.145 - ringStroke * 0.35,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, s * 0.018),
    );

    canvas.restore();
  }

  void _metalKey(Canvas canvas, Offset origin, double len, double thick, double tilt, {bool brass = false}) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(tilt);

    const chrome = [Color(0xFFF8F8FC), Color(0xFFB8B8BE), Color(0xFFE8E8ED)];
    const gold = [Color(0xFFF0D78C), Color(0xFFC9A227), Color(0xFFE8D090)];
    final metal = brass ? gold : chrome;
    final outline = brass ? const Color(0xFF8B6914) : const Color(0xFF3A3A3C);

    final bow = Offset(-len * 0.28, 0);
    final bowR = thick * 0.92;
    canvas.drawCircle(
      bow,
      bowR,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(bow.dx, bow.dy - bowR),
          Offset(bow.dx, bow.dy + bowR),
          metal,
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      bow,
      bowR,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.15, thick * 0.08),
    );
    canvas.drawCircle(
      bow + Offset(-bowR * 0.18, -bowR * 0.22),
      bowR * 0.28,
      Paint()..color = const Color(0x66FFFFFF),
    );
    canvas.drawCircle(bow, bowR * 0.38, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(
      bow,
      bowR * 0.38,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, thick * 0.06),
    );

    final blade = RRect.fromRectAndRadius(
      Rect.fromLTWH(-len * 0.08, -thick * 0.28, len * 0.62, thick * 0.56),
      Radius.circular(thick * 0.10),
    );
    canvas.drawRRect(
      blade,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -thick * 0.28),
          Offset(0, thick * 0.28),
          metal,
        ),
    );
    canvas.drawRRect(
      blade,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, thick * 0.06),
    );
    canvas.drawLine(
      Offset(-len * 0.02, -thick * 0.10),
      Offset(len * 0.46, -thick * 0.10),
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = math.max(1.0, thick * 0.07)
        ..strokeCap = StrokeCap.round,
    );

    final tooth = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, thick * 0.42), metal);
    final toothStroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, thick * 0.05);
    const heights = [0.42, 0.26, 0.50, 0.32];
    for (var i = 0; i < heights.length; i++) {
      final x = len * (0.06 + i * 0.11);
      final th = thick * heights[i];
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, thick * 0.22, thick * 0.22, th),
        const Radius.circular(1.1),
      );
      canvas.drawRRect(r, tooth);
      canvas.drawRRect(r, toothStroke);
    }

    canvas.restore();
  }

  void _sedanThreeQuarter(Canvas canvas, Offset c, double span, Color body, {required Color lamp}) {
    final w = span;
    final h = span * 0.55;
    final shadow = Paint()..color = const Color(0x66000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx, c.dy + h * 0.42), width: w * 0.92, height: h * 0.22), shadow);

    final hull = Path()
      ..moveTo(c.dx - w * 0.46, c.dy + h * 0.18)
      ..lineTo(c.dx - w * 0.40, c.dy - h * 0.02)
      ..lineTo(c.dx - w * 0.12, c.dy - h * 0.38)
      ..lineTo(c.dx + w * 0.18, c.dy - h * 0.40)
      ..lineTo(c.dx + w * 0.42, c.dy - h * 0.08)
      ..lineTo(c.dx + w * 0.48, c.dy + h * 0.16)
      ..close();
    canvas.drawPath(
      hull,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx, c.dy - h * 0.4),
          Offset(c.dx, c.dy + h * 0.2),
          [body.withValues(alpha: 0.95), const Color(0xFF2C2C2E)],
          const [0.0, 1.0],
        ),
    );
    canvas.drawPath(
      hull,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );
    final glass = Path()
      ..moveTo(c.dx - w * 0.10, c.dy - h * 0.34)
      ..lineTo(c.dx + w * 0.16, c.dy - h * 0.36)
      ..lineTo(c.dx + w * 0.32, c.dy - h * 0.10)
      ..lineTo(c.dx - w * 0.22, c.dy - h * 0.08)
      ..close();
    canvas.drawPath(glass, Paint()..color = const Color(0xAA64D2FF));
    canvas.drawCircle(Offset(c.dx + w * 0.40, c.dy + h * 0.02), span * 0.045, Paint()..color = lamp);
    _wheelDot(canvas, Offset(c.dx - w * 0.22, c.dy + h * 0.22), span * 0.11);
    _wheelDot(canvas, Offset(c.dx + w * 0.24, c.dy + h * 0.22), span * 0.11);
  }

  void _sedanSide(Canvas canvas, Offset c, double span, Color body) {
    final w = span;
    final h = span * 0.42;
    final hull = Path()
      ..moveTo(c.dx - w * 0.48, c.dy + h * 0.18)
      ..lineTo(c.dx - w * 0.42, c.dy - h * 0.05)
      ..lineTo(c.dx - w * 0.18, c.dy - h * 0.42)
      ..lineTo(c.dx + w * 0.12, c.dy - h * 0.44)
      ..lineTo(c.dx + w * 0.38, c.dy - h * 0.08)
      ..lineTo(c.dx + w * 0.48, c.dy + h * 0.16)
      ..close();
    canvas.drawPath(hull, Paint()..color = body);
    canvas.drawPath(
      hull,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - w * 0.16, c.dy - h * 0.38)
        ..lineTo(c.dx + w * 0.10, c.dy - h * 0.40)
        ..lineTo(c.dx + w * 0.28, c.dy - h * 0.10)
        ..lineTo(c.dx - w * 0.28, c.dy - h * 0.08)
        ..close(),
      Paint()..color = const Color(0xAA1A3048),
    );
    canvas.drawCircle(Offset(c.dx + w * 0.40, c.dy), span * 0.035, Paint()..color = const Color(0xFFFFE082));
    _wheelDot(canvas, Offset(c.dx - w * 0.26, c.dy + h * 0.22), span * 0.10);
    _wheelDot(canvas, Offset(c.dx + w * 0.22, c.dy + h * 0.22), span * 0.10);
  }

  void _wheelDot(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..color = const Color(0xFF8E8E93)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * 0.18),
    );
    canvas.drawCircle(c, r * 0.22, Paint()..color = const Color(0xFFD1D1D6));
  }

  void _usCanton(Canvas canvas, Rect rect) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = const Color(0xFFB22234));
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top + rect.height * (0.18 + i * 0.28), rect.width, rect.height * 0.10),
        Paint()..color = const Color(0xFFF2F2F7),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width * 0.42, rect.height * 0.52),
      Paint()..color = const Color(0xFF1C3D8A),
    );
  }

  @override
  bool shouldRepaint(covariant UsaPipelineNodePainter old) =>
      old.scene != scene || old.on != on || old.done != done || old.loop != loop;
}
