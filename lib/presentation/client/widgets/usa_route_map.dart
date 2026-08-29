import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'usa_intro.dart';

/// USA → Atlantic → Ukraine. One looping ticker, no blur, pauses off-tab.
class UsaAtlanticCrossing extends StatefulWidget {
  const UsaAtlanticCrossing({
    super.key,
    required this.usa,
    required this.ocean,
    required this.europe,
    required this.ukraine,
    this.active = true,
  });

  final String usa;
  final String ocean;
  final String europe;
  final String ukraine;
  final bool active;

  @override
  State<UsaAtlanticCrossing> createState() => _UsaAtlanticCrossingState();
}

class _UsaAtlanticCrossingState extends State<UsaAtlanticCrossing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.active) _play.repeat();
  }

  @override
  void didUpdateWidget(covariant UsaAtlanticCrossing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_play.isAnimating) {
      _play.repeat();
    } else if (!widget.active && _play.isAnimating) {
      _play.stop();
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ColoredBox(
        color: const Color(0xFF061018),
        child: AnimatedBuilder(
          animation: _play,
          builder: (context, _) {
            return CustomPaint(
              painter: _CrossingPainter(
                t: _play.value,
                usa: widget.usa,
                ocean: widget.ocean,
                europe: widget.europe,
                ukraine: widget.ukraine,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _CrossingPainter extends CustomPainter {
  _CrossingPainter({
    required this.t,
    required this.usa,
    required this.ocean,
    required this.europe,
    required this.ukraine,
  });

  final double t;
  final String usa;
  final String ocean;
  final String europe;
  final String ukraine;

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
          const [Color(0xFF0B2233), Color(0xFF07141F), Color(0xFF040A10)],
          const [0.0, 0.55, 1.0],
        ),
    );

    _grid(canvas, size);
    _waves(canvas, size);

    final usaLand = _usaPath(w, h);
    final euLand = _europePath(w, h);
    final uaLand = _ukrainePath(w, h);

    canvas.drawPath(usaLand, Paint()..color = const Color(0xFF163628));
    canvas.drawPath(
      usaLand,
      Paint()
        ..color = const Color(0xFF3F8A5A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );
    canvas.drawPath(euLand, Paint()..color = const Color(0xFF1A2A3C));
    canvas.drawPath(
      euLand,
      Paint()
        ..color = const Color(0xFF5A7A98)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );
    canvas.drawPath(uaLand, Paint()..color = const Color(0xFF2A3A22));
    canvas.drawPath(
      uaLand,
      Paint()
        ..color = const Color(0xFFFFD500)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final origin = Offset(w * 0.27, h * 0.50);
    final dest = Offset(w * 0.84, h * 0.40);
    final ctrl = Offset(w * 0.52, h * 0.10);

    _flagUs(canvas, Offset(w * 0.16, h * 0.38));
    _flagUa(canvas, Offset(w * 0.84, h * 0.28));

    final route = Path()..moveTo(origin.dx, origin.dy);
    route.quadraticBezierTo(ctrl.dx, ctrl.dy, dest.dx, dest.dy);

    canvas.drawPath(
      route,
      Paint()
        ..color = kLTransRed.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    _dash(canvas, route, Paint()
      ..color = kLTransRed.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round, 6, 5);

    late final double travel;
    late final double opacity;
    if (t < 0.07) {
      travel = 0;
      opacity = t / 0.07;
    } else if (t < 0.80) {
      travel = Curves.easeInOutCubic.transform((t - 0.07) / 0.73);
      opacity = 1;
    } else if (t < 0.90) {
      travel = 1;
      opacity = 1;
    } else {
      travel = 1;
      opacity = (1 - (t - 0.90) / 0.10).clamp(0.0, 1.0);
    }

    _progress(canvas, origin, ctrl, dest, travel);

    canvas.drawCircle(origin, 4.2, Paint()..color = kLTransRed);
    canvas.drawCircle(origin, 7.5, Paint()
      ..color = kLTransRed.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    canvas.drawCircle(dest, 4.2, Paint()..color = const Color(0xFFFFD500));
    canvas.drawCircle(dest, 7.5, Paint()
      ..color = const Color(0x88FFD500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    _labels(canvas, size, origin, dest);

    if (opacity > 0.08) {
      final pos = _quad(origin, ctrl, dest, travel);
      final next = _quad(origin, ctrl, dest, (travel + 0.018).clamp(0.0, 1.0));
      final ang = math.atan2(next.dy - pos.dy, next.dx - pos.dx);
      _convoy(canvas, pos, ang, travel);
    }

    if (travel > 0.97 && opacity > 0.6) {
      final pulse = (math.sin((t - 0.80) * math.pi * 10) * 0.5 + 0.5);
      canvas.drawCircle(
        dest,
        10 + pulse * 8,
        Paint()..color = kLTransRed.withValues(alpha: 0.12 + pulse * 0.12),
      );
    }
  }

  Path _usaPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.015, h * 0.46)
      ..lineTo(w * 0.04, h * 0.30)
      ..lineTo(w * 0.07, h * 0.18)
      ..lineTo(w * 0.18, h * 0.16)
      ..lineTo(w * 0.24, h * 0.22)
      ..lineTo(w * 0.30, h * 0.28)
      ..lineTo(w * 0.29, h * 0.40)
      ..lineTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.285, h * 0.64)
      ..lineTo(w * 0.24, h * 0.66)
      ..lineTo(w * 0.20, h * 0.54)
      ..lineTo(w * 0.12, h * 0.52)
      ..lineTo(w * 0.06, h * 0.56)
      ..close();
  }

  Path _europePath(double w, double h) {
    return Path()
      ..moveTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.57, h * 0.38)
      ..lineTo(w * 0.545, h * 0.52)
      ..lineTo(w * 0.60, h * 0.55)
      ..lineTo(w * 0.67, h * 0.50)
      ..lineTo(w * 0.72, h * 0.46)
      ..lineTo(w * 0.76, h * 0.42)
      ..lineTo(w * 0.78, h * 0.36)
      ..lineTo(w * 0.74, h * 0.28)
      ..lineTo(w * 0.66, h * 0.26)
      ..close();
  }

  Path _ukrainePath(double w, double h) {
    return Path()
      ..moveTo(w * 0.78, h * 0.34)
      ..lineTo(w * 0.82, h * 0.30)
      ..lineTo(w * 0.90, h * 0.32)
      ..lineTo(w * 0.92, h * 0.40)
      ..lineTo(w * 0.88, h * 0.48)
      ..lineTo(w * 0.80, h * 0.50)
      ..lineTo(w * 0.76, h * 0.42)
      ..close();
  }

  Offset _quad(Offset a, Offset b, Offset c, double u) {
    final s = 1 - u;
    return Offset(
      s * s * a.dx + 2 * s * u * b.dx + u * u * c.dx,
      s * s * a.dy + 2 * s * u * b.dy + u * u * c.dy,
    );
  }

  void _grid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x14A8D4EE)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  void _waves(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x3348A0C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.30 + i * 0.10);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 16) {
        final wave = math.sin((x / 38) + t * math.pi * 2 + i * 0.7) * 2.8;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, p);
    }
  }

  void _flagUs(Canvas canvas, Offset p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 18, height: 12),
        const Radius.circular(1.4),
      ),
      Paint()..color = const Color(0xFFB22234),
    );
    canvas.drawRect(
      Rect.fromLTWH(p.dx - 9, p.dy - 6, 8, 7),
      Paint()..color = const Color(0xFF3C3B6E),
    );
  }

  void _flagUa(Canvas canvas, Offset p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 16, height: 12),
        const Radius.circular(1.4),
      ),
      Paint()..color = const Color(0xFF005BBB),
    );
    canvas.drawRect(
      Rect.fromLTWH(p.dx - 8, p.dy, 16, 6),
      Paint()..color = const Color(0xFFFFD500),
    );
  }

  void _progress(Canvas canvas, Offset a, Offset b, Offset c, double travel) {
    final path = Path()..moveTo(a.dx, a.dy);
    path.quadraticBezierTo(b.dx, b.dy, c.dx, c.dy);
    for (final metric in path.computeMetrics()) {
      final drawn = metric.extractPath(0, metric.length * travel);
      canvas.drawPath(
        drawn,
        Paint()
          ..color = kLTransRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _dash(Canvas canvas, Path path, Paint paint, double on, double off) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      var draw = true;
      while (d < metric.length) {
        final next = (d + (draw ? on : off)).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(d, next), paint);
        }
        d = next;
        draw = !draw;
      }
    }
  }

  void _convoy(Canvas canvas, Offset pos, double ang, double travel) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(ang);

    final overSea = travel > 0.08 && travel < 0.92;
    if (overSea) {
      final wake = Paint()
        ..color = const Color(0x66E8F4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      canvas.drawLine(const Offset(-30, 9), const Offset(-8, 3), wake);
      canvas.drawLine(const Offset(-30, -9), const Offset(-8, -3), wake);
      final hull = Path()
        ..moveTo(-24, 8)
        ..lineTo(22, 6)
        ..lineTo(28, 0)
        ..lineTo(20, -5)
        ..lineTo(-20, -4)
        ..close();
      canvas.drawPath(hull, Paint()..color = const Color(0xFFE4E4EA));
      canvas.drawPath(
        hull,
        Paint()
          ..color = kLTransRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      canvas.drawRect(const Rect.fromLTWH(-10, -1, 22, 2.2), Paint()..color = kLTransRed);
    }

    canvas.rotate(-ang * 0.65);
    _car(canvas, Offset(0, overSea ? -13 : -2));
    canvas.restore();
  }

  void _car(Canvas canvas, Offset p) {
    final shadow = Paint()..color = const Color(0x66000000);
    canvas.drawOval(Rect.fromCenter(center: p + const Offset(0, 7), width: 24, height: 5), shadow);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: p, width: 26, height: 9),
      const Radius.circular(2.4),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2F2F6));
    canvas.drawRRect(
      body,
      Paint()
        ..color = kLTransRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p + const Offset(1, -5.5), width: 13, height: 6.5),
        const Radius.circular(1.6),
      ),
      Paint()..color = const Color(0xFF2A3340),
    );
    canvas.drawCircle(p + const Offset(-8, 5), 2.5, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(p + const Offset(8, 5), 2.5, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(p + const Offset(12, 0), 1.3, Paint()..color = const Color(0xFFFFD54A));
  }

  void _labels(Canvas canvas, Size size, Offset origin, Offset dest) {
    _tag(canvas, usa.toUpperCase(), Offset(origin.dx - 8, origin.dy + 28), const Color(0xFFE8E8ED));
    _tag(canvas, ocean.toUpperCase(), Offset(size.width * 0.50, size.height * 0.22), kLTransRed);
    _tag(
      canvas,
      europe.toUpperCase(),
      Offset(size.width * 0.66, size.height * 0.60),
      const Color(0xFF9BB0C4),
    );
    _tag(canvas, ukraine.toUpperCase(), Offset(dest.dx, dest.dy + 26), const Color(0xFFFFD500));
  }

  void _tag(Canvas canvas, String text, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.7,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CrossingPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.usa != usa ||
      oldDelegate.ocean != ocean ||
      oldDelegate.europe != europe ||
      oldDelegate.ukraine != ukraine;
}
