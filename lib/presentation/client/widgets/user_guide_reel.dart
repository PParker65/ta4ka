import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

const _kBg = Color(0xFF061018);
const _kInk = Color(0xFFE8E8ED);
const _kAccent = Color(0xFF48A0C8);
const _kHold = Duration(seconds: 14);

class UserGuideLabels {
  const UserGuideLabels({
    required this.title,
    required this.skip,
    required this.brand,
    required this.issue,
    required this.shop,
    required this.services,
    required this.slot,
  });

  final String title;
  final String skip;
  final String brand;
  final String issue;
  final String shop;
  final String services;
  final String slot;
}

/// Film slideshow of Ta4ka — five function marks, same language as the L-TRANS logo.
class UserGuideReel extends StatefulWidget {
  const UserGuideReel({
    super.key,
    required this.labels,
    this.onDone,
    this.play = true,
  });

  final UserGuideLabels labels;
  final VoidCallback? onDone;
  final bool play;

  @override
  State<UserGuideReel> createState() => _UserGuideReelState();
}

class _UserGuideReelState extends State<UserGuideReel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(vsync: this, duration: _kHold);
    if (widget.play) {
      _play.forward().whenComplete(() {
        if (mounted) widget.onDone?.call();
      });
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDone,
      child: ColoredBox(
        color: _kBg,
        child: AnimatedBuilder(
          animation: _play,
          builder: (context, _) {
            return CustomPaint(
              painter: _GuidePainter(t: _play.value, labels: widget.labels),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class UserGuideScreen extends ConsumerWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      backgroundColor: _kBg,
      body: UserGuideReel(
        labels: UserGuideLabels(
          title: s.guideTitle,
          skip: s.guideSkip,
          brand: s.guideBrand,
          issue: s.guideIssue,
          shop: s.guideShop,
          services: s.guideServices,
          slot: s.guideSlot,
        ),
        onDone: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.t, required this.labels});

  final double t;
  final UserGuideLabels labels;

  static const _slides = 5;
  static const _beats = [0.16, 0.42, 0.68];

  String _name(int i) {
    switch (i) {
      case 0:
        return labels.brand;
      case 1:
        return labels.issue;
      case 2:
        return labels.shop;
      case 3:
        return labels.services;
      default:
        return labels.slot;
    }
  }

  double _pulseAt(double u, double at) {
    final x = (u - at) * 14;
    if (x < -0.2) return 0;
    if (x < 0) return Curves.easeIn.transform((x + 0.2) / 0.2);
    return math.exp(-x * x * 2.2);
  }

  double _heart(double u) =>
      (_pulseAt(u, _beats[0]) + _pulseAt(u, _beats[1]) + _pulseAt(u, _beats[2])).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color(0xFF0A1824), Color(0xFF060E14), Color(0xFF03070A)],
          const [0.0, 0.52, 1.0],
        ),
    );
    _vignette(canvas, size);

    final raw = (t * _slides).clamp(0.0, _slides - 0.0001);
    final i = raw.floor();
    final u = raw - i;
    final appear = Curves.easeOutBack.transform((u / 0.18).clamp(0.0, 1.0));
    final hold = ((u - 0.14) / 0.68).clamp(0.0, 1.0);
    final fadeOut = u < 0.84
        ? 1.0
        : 1 - Curves.easeInCubic.transform(((u - 0.84) / 0.16).clamp(0.0, 1.0));
    final heart = _heart(u);
    final grow = (0.72 + 0.28 * appear) * (1.0 + 0.12 * heart);
    final alpha = (appear.clamp(0.0, 1.0) * fadeOut).clamp(0.0, 1.0);
    final c = Offset(w * 0.50, h * 0.40);
    final s = size.shortestSide * 0.34;

    final bloom = (s * 0.55 + s * 1.15 * heart) * grow;
    canvas.drawCircle(
      c,
      bloom,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          bloom,
          [
            _kAccent.withValues(alpha: 0.26 * alpha + 0.38 * heart * alpha),
            _kAccent.withValues(alpha: 0.08 * alpha),
            _kBg.withValues(alpha: 0),
          ],
          const [0.0, 0.42, 1.0],
        ),
    );

    for (final beatAt in _beats) {
      final age = ((u - beatAt) / 0.22).clamp(0.0, 1.0);
      if (u < beatAt || age <= 0) continue;
      final r = s * grow * (0.42 + 1.35 * Curves.easeOut.transform(age));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = _kAccent.withValues(alpha: (1 - age) * 0.55 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - age),
      );
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(grow * (1.0 + 0.08 * heart));
    canvas.saveLayer(
      Rect.fromCircle(center: Offset.zero, radius: s * 1.35),
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    _seal(canvas, s, heart);
    switch (i) {
      case 0:
        _markBrand(canvas, s);
      case 1:
        _markIssue(canvas, s, hold);
      case 2:
        _markShop(canvas, s, hold);
      case 3:
        _markServices(canvas, s, hold);
      default:
        _markSlot(canvas, s, hold);
    }
    canvas.restore();
    canvas.restore();

    final under = s * grow * 1.55;
    _tag(
      canvas,
      'Ta4ka',
      c + Offset(0, under),
      _kAccent.withValues(alpha: 0.95 * alpha),
      size: 11,
      tracking: 6.2,
    );
    _tag(
      canvas,
      _name(i).toUpperCase(),
      c + Offset(0, under + 26),
      _kInk.withValues(alpha: alpha),
      size: 18,
      tracking: 2.8,
    );
    _tag(
      canvas,
      '${(i + 1).toString().padLeft(2, '0')}  /  0$_slides',
      c + Offset(0, under + 50),
      _kAccent.withValues(alpha: 0.55 * alpha),
      size: 10,
      tracking: 3.4,
    );

    _tag(
      canvas,
      labels.title.toUpperCase(),
      Offset(w * 0.50, h * 0.10),
      _kInk.withValues(alpha: 0.42 + 0.38 * alpha),
      size: 11,
      tracking: 4.0,
    );
    _dots(canvas, Offset(w * 0.50, h * 0.86), i, alpha);
    _tag(
      canvas,
      labels.skip.toUpperCase(),
      Offset(w * 0.50, h * 0.93),
      const Color(0xFF8E9AA8).withValues(alpha: 0.72),
      size: 9,
      tracking: 1.8,
    );
  }

  void _vignette(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height * 0.40),
          size.longestSide * 0.72,
          [
            const Color(0x00000000),
            const Color(0x99000000),
          ],
          const [0.55, 1.0],
        ),
    );
  }

  void _seal(Canvas canvas, double s, double heart) {
    final r = s * 0.92;
    canvas.drawCircle(Offset.zero, r, Paint()..color = _kAccent.withValues(alpha: 0.07 + 0.10 * heart));
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 + 1.4 * heart,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.86,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.58,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    final tick = Paint()
      ..color = _kAccent.withValues(alpha: 0.55)
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 24; k++) {
      final a = k * math.pi / 12 - math.pi / 2;
      final major = k % 6 == 0;
      final inner = r * (major ? 0.90 : 0.935);
      canvas.drawLine(
        Offset(math.cos(a) * inner, math.sin(a) * inner),
        Offset(math.cos(a) * r * 0.98, math.sin(a) * r * 0.98),
        tick..strokeWidth = major ? 1.8 : 0.9,
      );
    }
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2 - math.pi / 2;
      final p = Offset(math.cos(a) * r * 1.08, math.sin(a) * r * 1.08);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a);
      canvas.drawPath(
        Path()
          ..moveTo(0, -4.2)
          ..lineTo(3.2, 0)
          ..lineTo(0, 4.2)
          ..lineTo(-3.2, 0)
          ..close(),
        Paint()..color = _kAccent.withValues(alpha: 0.85),
      );
      canvas.restore();
    }
  }

  void _dots(Canvas canvas, Offset c, int active, double a) {
    const n = _slides;
    const gap = 22.0;
    final start = c.dx - (n - 1) * gap / 2;
    for (var i = 0; i < n; i++) {
      final on = i == active;
      canvas.drawCircle(
        Offset(start + i * gap, c.dy),
        on ? 4.4 : 2.6,
        Paint()
          ..color = (on ? _kAccent : const Color(0xFF5A7A98)).withValues(alpha: 0.40 + 0.55 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        Offset(start + i * gap, c.dy),
        on ? 2.2 : 1.4,
        Paint()..color = (on ? _kAccent : const Color(0xFF5A7A98)).withValues(alpha: 0.45 + 0.55 * a),
      );
    }
  }

  Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _markBrand(Canvas canvas, double s) {
    final u = s / 110;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 18 * u), width: 54 * u, height: 10 * u),
      Paint()..color = const Color(0x66000000),
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 78 * u, height: 24 * u),
      Radius.circular(6 * u),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2F2F6));
    canvas.drawRRect(body, _line(_kAccent, 1.7 * u));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(8 * u, -16 * u), width: 38 * u, height: 18 * u),
        Radius.circular(3.2 * u),
      ),
      Paint()..color = const Color(0xFF1A2430),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(8 * u, -16 * u), width: 30 * u, height: 11 * u),
        Radius.circular(2 * u),
      ),
      Paint()..color = _kAccent.withValues(alpha: 0.38),
    );
    canvas.drawCircle(Offset(-24 * u, 13 * u), 7.0 * u, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(Offset(24 * u, 13 * u), 7.0 * u, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(Offset(-24 * u, 13 * u), 2.6 * u, Paint()..color = const Color(0xFF7AA8C4));
    canvas.drawCircle(Offset(24 * u, 13 * u), 2.6 * u, Paint()..color = const Color(0xFF7AA8C4));
    canvas.drawCircle(Offset(38 * u, 0), 2.6 * u, Paint()..color = const Color(0xFFFFD54A));
    canvas.drawCircle(Offset(-38 * u, 2 * u), 1.8 * u, Paint()..color = const Color(0xFFFF6B6B));
  }

  void _markIssue(Canvas canvas, double s, double hold) {
    final u = s / 110;
    final car = Path()
      ..moveTo(-32 * u, 8 * u)
      ..lineTo(-24 * u, -6 * u)
      ..lineTo(-8 * u, -12 * u)
      ..lineTo(12 * u, -12 * u)
      ..lineTo(30 * u, -2 * u)
      ..lineTo(34 * u, 8 * u)
      ..close();
    canvas.drawPath(car, Paint()..color = const Color(0xFF15202C));
    canvas.drawPath(car, _line(_kInk, 1.7 * u));
    canvas.drawCircle(Offset(-16 * u, 12 * u), 5 * u, _line(_kInk, 1.5 * u));
    canvas.drawCircle(Offset(16 * u, 12 * u), 5 * u, _line(_kInk, 1.5 * u));
    final spots = [
      Offset(-8 * u, -22 * u),
      Offset(20 * u, 2 * u),
      Offset(-22 * u, 0),
    ];
    for (var k = 0; k < spots.length; k++) {
      final beat = 0.5 + 0.5 * math.sin((hold * 7 + k) * math.pi);
      canvas.drawCircle(
        spots[k],
        (7 + beat * 5) * u,
        Paint()..color = _kAccent.withValues(alpha: 0.16 + 0.32 * beat),
      );
      canvas.drawCircle(spots[k], 3.0 * u, Paint()..color = _kAccent);
    }
    canvas.drawCircle(Offset.zero, 22 * u, _line(_kAccent.withValues(alpha: 0.45), 1.0 * u));
    canvas.drawLine(Offset(0, -10 * u), Offset(0, 10 * u), _line(_kAccent, 1.0 * u));
    canvas.drawLine(Offset(-10 * u, 0), Offset(10 * u, 0), _line(_kAccent, 1.0 * u));
  }

  void _markShop(Canvas canvas, double s, double hold) {
    final u = s / 110;
    final building = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 8 * u), width: 64 * u, height: 56 * u),
      Radius.circular(4 * u),
    );
    canvas.drawRRect(building, Paint()..color = const Color(0xFF121C26));
    canvas.drawRRect(building, _line(_kAccent, 1.6 * u));
    final roof = Path()
      ..moveTo(-36 * u, -20 * u)
      ..lineTo(0, -42 * u)
      ..lineTo(36 * u, -20 * u);
    canvas.drawPath(roof, Paint()..color = const Color(0xFF1A2834));
    canvas.drawPath(roof, _line(_kAccent, 1.8 * u));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, 18 * u), width: 22 * u, height: 36 * u),
      Paint()..color = const Color(0xFF070C10),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, 18 * u), width: 22 * u, height: 36 * u),
      _line(_kAccent.withValues(alpha: 0.7), 1.1 * u),
    );
    final glow = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(hold * math.pi * 4));
    canvas.drawCircle(Offset(-18 * u, -8 * u), 2.4 * u, Paint()..color = const Color(0xFFFFD54A).withValues(alpha: glow));
    canvas.drawCircle(Offset(18 * u, -8 * u), 2.4 * u, Paint()..color = const Color(0xFFFFD54A).withValues(alpha: glow));
    canvas.drawRect(Rect.fromLTWH(-22 * u, -6 * u, 10 * u, 8 * u), Paint()..color = _kAccent.withValues(alpha: 0.28));
    canvas.drawRect(Rect.fromLTWH(12 * u, -6 * u, 10 * u, 8 * u), Paint()..color = _kAccent.withValues(alpha: 0.28));
  }

  void _markServices(Canvas canvas, double s, double hold) {
    final u = s / 110;
    for (var k = 0; k < 3; k++) {
      final y = (-20 + k * 20) * u;
      final lit = ((hold * 3).floor() % 3) == k;
      final plate = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(6 * u, y), width: 58 * u, height: 15 * u),
        Radius.circular(3.2 * u),
      );
      canvas.drawRRect(
        plate,
        Paint()..color = lit ? _kAccent.withValues(alpha: 0.28) : const Color(0xFF121C26),
      );
      canvas.drawRRect(plate, _line(_kAccent, 1.2 * u));
      canvas.drawLine(Offset(-16 * u, y), Offset(14 * u, y), _line(_kInk.withValues(alpha: 0.85), 1.3 * u));
      canvas.drawCircle(Offset(26 * u, y), 2.2 * u, Paint()..color = lit ? _kAccent : const Color(0xFF5A7A98));
    }
    canvas.save();
    canvas.translate(-34 * u, 30 * u);
    canvas.rotate(-0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 7 * u, height: 26 * u),
        Radius.circular(2 * u),
      ),
      _line(_kAccent, 1.6 * u),
    );
    canvas.drawCircle(Offset(0, -12 * u), 6 * u, _line(_kAccent, 1.6 * u));
    canvas.restore();
  }

  void _markSlot(Canvas canvas, double s, double hold) {
    final u = s / 110;
    final r = 34 * u;
    canvas.drawCircle(Offset.zero, r, _line(_kAccent, 1.8 * u));
    canvas.drawCircle(Offset.zero, r * 0.08, Paint()..color = _kAccent);
    final hour = -math.pi / 2 + hold * math.pi * 0.55;
    final minute = -math.pi / 2 + hold * math.pi * 2.2;
    canvas.drawLine(
      Offset.zero,
      Offset(math.cos(hour) * r * 0.42, math.sin(hour) * r * 0.42),
      _line(_kInk, 2.4 * u),
    );
    canvas.drawLine(
      Offset.zero,
      Offset(math.cos(minute) * r * 0.62, math.sin(minute) * r * 0.62),
      _line(_kAccent, 1.8 * u),
    );
    for (var k = 0; k < 12; k++) {
      final a = k * math.pi / 6 - math.pi / 2;
      final inner = r * (k % 3 == 0 ? 0.72 : 0.80);
      canvas.drawLine(
        Offset(math.cos(a) * inner, math.sin(a) * inner),
        Offset(math.cos(a) * r * 0.92, math.sin(a) * r * 0.92),
        _line(_kAccent.withValues(alpha: 0.75), k % 3 == 0 ? 1.7 * u : 0.9 * u),
      );
    }
    final wedge = Path()
      ..moveTo(0, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.55),
        -math.pi / 2,
        hold * math.pi * 1.15,
        false,
      )
      ..close();
    canvas.drawPath(wedge, Paint()..color = _kAccent.withValues(alpha: 0.16));
  }

  void _tag(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    double size = 10,
    double tracking = 1.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: tracking,
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 320);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.labels != labels;
}
