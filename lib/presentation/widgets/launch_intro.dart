import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../data/telegram_webapp.dart';

/// Cold-start clock so bootstrap + first frame share one intro.
final launchStopwatch = Stopwatch();

void markLaunchStart() {
  if (!launchStopwatch.isRunning) {
    launchStopwatch.start();
  }
}

const _kBg = Color(0xFF07070A);
const _kSilver = Color(0xFFE8E8ED);
const _kHold = Duration(milliseconds: 1680);
const _kFade = Duration(milliseconds: 240);

class LaunchIntroStage extends StatelessWidget {
  const LaunchIntroStage({super.key});

  @override
  Widget build(BuildContext context) {
    markLaunchStart();
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: _kBg,
        child: _LaunchCanvas(),
      ),
    );
  }
}

class LaunchIntroGate extends StatefulWidget {
  const LaunchIntroGate({super.key, required this.child});

  final Widget child;

  @override
  State<LaunchIntroGate> createState() => _LaunchIntroGateState();
}

class _LaunchIntroGateState extends State<LaunchIntroGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  bool _cover = true;

  @override
  void initState() {
    super.initState();
    markLaunchStart();
    _fade = AnimationController(vsync: this, duration: _kFade);
    if (TelegramWebApp.instance.active) {
      _cover = false;
      return;
    }
    _arm();
  }

  void _arm() {
    final left = _kHold - launchStopwatch.elapsed;
    if (left <= Duration.zero) {
      _release();
      return;
    }
    Future<void>.delayed(left, _release);
  }

  void _release() {
    if (!mounted || !_cover) return;
    _fade.forward().whenComplete(() {
      if (mounted) setState(() => _cover = false);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_cover)
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(parent: _fade, curve: Curves.easeInCubic),
            ),
            child: const IgnorePointer(
              child: ColoredBox(
                color: _kBg,
                child: _LaunchCanvas(),
              ),
            ),
          ),
      ],
    );
  }
}

class _LaunchCanvas extends StatefulWidget {
  const _LaunchCanvas();

  @override
  State<_LaunchCanvas> createState() => _LaunchCanvasState();
}

class _LaunchCanvasState extends State<_LaunchCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t =
        (launchStopwatch.elapsedMilliseconds / _kHold.inMilliseconds).clamp(0.0, 1.0);
    return ColoredBox(
      color: _kBg,
      child: CustomPaint(
        painter: _Ta4kaPainter(t: t),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Part {
  const _Part({
    required this.ox,
    required this.oy,
    required this.dx,
    required this.dy,
    required this.draw,
    this.spin = 0.18,
    this.heart = false,
  });

  final double ox;
  final double oy;
  final double dx;
  final double dy;
  final double spin;
  final bool heart;
  final void Function(Canvas canvas, Paint paint, double s) draw;
}

double _pulse(double t, double at) {
  final x = (t - at) * 16;
  if (x < -0.2) return 0;
  if (x < 0) return Curves.easeIn.transform((x + 0.2) / 0.2);
  return math.exp(-x * x * 2.4);
}

double _heart(double t) =>
    (_pulse(t, 0.20) + _pulse(t, 0.54)).clamp(0.0, 1.0);

double _burst(double t) {
  if (t < 0.16) return 0;
  if (t < 0.46) {
    return Curves.easeOutExpo.transform(((t - 0.16) / 0.30).clamp(0.0, 1.0));
  }
  if (t < 0.52) return 1;
  if (t < 0.76) {
    return 1 - Curves.easeInCubic.transform(((t - 0.52) / 0.24).clamp(0.0, 1.0));
  }
  return 0;
}

class _Ta4kaPainter extends CustomPainter {
  _Ta4kaPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2 - 18);
    final s = size.shortestSide * 0.38;
    final heart = _heart(t);
    final burst = _burst(t);
    final appear = Curves.easeOut.transform((t / 0.12).clamp(0.0, 1.0));
    final scale = (1.0 - 0.08 * heart + 0.03 * (1 - burst)) * appear;
    final word = Curves.easeOutCubic.transform(((t - 0.62) / 0.20).clamp(0.0, 1.0));

    final bloom = 90.0 + 140.0 * heart + 70.0 * burst;
    canvas.drawCircle(
      origin,
      bloom,
      Paint()
        ..shader = ui.Gradient.radial(
          origin,
          bloom,
          [
            const Color(0xFFFFFFFF).withValues(alpha: 0.10 * appear + 0.16 * heart),
            const Color(0xFFB8C4D4).withValues(alpha: 0.04 * appear),
            _kBg.withValues(alpha: 0),
          ],
          const [0.0, 0.42, 1.0],
        ),
    );

    _splashRings(canvas, origin, s, heart, burst, appear);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);

    final parts = _parts();
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].heart) continue;
      _paintPart(canvas, parts[i], s, burst, heart, appear, i);
    }
    for (var i = 0; i < parts.length; i++) {
      if (!parts[i].heart) continue;
      _paintPart(canvas, parts[i], s, burst, heart, appear, i);
    }
    canvas.restore();

    if (word > 0) {
      _wordmark(canvas, size, origin, word);
    }
  }

  void _splashRings(
    Canvas canvas,
    Offset origin,
    double s,
    double heart,
    double burst,
    double appear,
  ) {
    for (final beatAt in [0.20, 0.54]) {
      final age = ((t - beatAt) / 0.28).clamp(0.0, 1.0);
      if (t < beatAt || age <= 0) continue;
      final r = s * (0.35 + 1.55 * Curves.easeOut.transform(age));
      final a = (1 - age) * 0.55 * appear;
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..color = _kSilver.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * (1 - age),
      );
    }

    final rng = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final ang = i / 18 * math.pi * 2 + 0.2;
      final dist = s * (0.2 + burst * (0.85 + rng.nextDouble() * 0.45));
      final p = origin + Offset(math.cos(ang) * dist, math.sin(ang) * dist * 0.62);
      final a = appear * (0.12 + 0.35 * burst) * (1 - (i % 3) * 0.12);
      canvas.drawCircle(
        p,
        1.1 + heart * 1.4,
        Paint()..color = _kSilver.withValues(alpha: a),
      );
    }
  }

  void _paintPart(
    Canvas canvas,
    _Part part,
    double s,
    double burst,
    double heart,
    double appear,
    int i,
  ) {
    final kick = 0.08 * heart;
    final fly = (burst + kick) * s * 0.92;
    final ox = part.ox * s + part.dx * fly;
    final oy = part.oy * s + part.dy * fly * 0.78;
    final rot = part.heart ? 0.0 : part.spin * burst * (i.isEven ? 1 : -1);

    canvas.save();
    canvas.translate(ox, oy);
    canvas.rotate(rot);

    final alpha = appear * (part.heart ? 0.55 + 0.45 * heart : 0.82);
    final paint = Paint()
      ..color = _kSilver.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = part.heart ? 2.4 + 1.6 * heart : 1.7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (part.heart) {
      canvas.scale(1.0 + 0.22 * heart);
      final fill = Paint()
        ..color = _kSilver.withValues(alpha: 0.10 + 0.28 * heart)
        ..style = PaintingStyle.fill;
      part.draw(canvas, fill, s);
    }
    part.draw(canvas, paint, s);
    canvas.restore();
  }

  void _wordmark(Canvas canvas, Size size, Offset origin, double word) {
    final silver = _kSilver.withValues(alpha: 0.92 * word);
    final red = const Color(0xFFD70200).withValues(alpha: 0.95 * word);
    final base = TextStyle(
      color: silver,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 6,
      height: 1,
    );
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: 'Ta', style: base),
          TextSpan(text: '4', style: base.copyWith(color: red)),
          TextSpan(text: 'ka', style: base),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = Offset(
      origin.dx - tp.width / 2,
      origin.dy + size.shortestSide * 0.28 + 10 * (1 - word),
    );
    tp.paint(canvas, pos);
  }

  List<_Part> _parts() {
    Path body(List<Offset> pts, {bool close = true}) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      if (close) p.close();
      return p;
    }

    return [
      _Part(
        ox: 0,
        oy: -0.02,
        dx: 0,
        dy: 0,
        spin: 0,
        heart: true,
        draw: (c, p, s) {
          final h = s * 0.09;
          final path = Path()
            ..moveTo(0, -h)
            ..cubicTo(h * 0.7, -h * 1.35, h * 1.35, -h * 0.15, 0, h * 0.95)
            ..cubicTo(-h * 1.35, -h * 0.15, -h * 0.7, -h * 1.35, 0, -h);
          c.drawPath(path, p);
        },
      ),
      _Part(
        ox: -0.52,
        oy: 0.30,
        dx: -0.55,
        dy: 0.72,
        draw: (c, p, s) {
          c.drawCircle(Offset.zero, s * 0.13, p);
          c.drawCircle(Offset.zero, s * 0.07, p);
        },
      ),
      _Part(
        ox: 0.50,
        oy: 0.30,
        dx: 0.62,
        dy: 0.70,
        draw: (c, p, s) {
          c.drawCircle(Offset.zero, s * 0.13, p);
          c.drawCircle(Offset.zero, s * 0.07, p);
        },
      ),
      _Part(
        ox: -0.02,
        oy: 0.20,
        dx: 0,
        dy: 0.85,
        draw: (c, p, s) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s * 1.18, height: s * 0.055),
              const Radius.circular(4),
            ),
            p,
          );
        },
      ),
      _Part(
        ox: -0.02,
        oy: -0.22,
        dx: 0,
        dy: -0.95,
        spin: 0.08,
        draw: (c, p, s) {
          c.drawPath(
            body([
              Offset(-s * 0.28, s * 0.06),
              Offset(-s * 0.18, -s * 0.12),
              Offset(s * 0.16, -s * 0.12),
              Offset(s * 0.30, s * 0.06),
            ]),
            p,
          );
        },
      ),
      _Part(
        ox: 0.02,
        oy: -0.16,
        dx: 0.12,
        dy: -0.70,
        draw: (c, p, s) {
          c.drawPath(
            body([
              Offset(-s * 0.22, s * 0.04),
              Offset(-s * 0.14, -s * 0.08),
              Offset(s * 0.12, -s * 0.08),
              Offset(s * 0.22, s * 0.04),
            ]),
            p,
          );
        },
      ),
      _Part(
        ox: 0.42,
        oy: -0.04,
        dx: 0.92,
        dy: -0.28,
        spin: 0.22,
        draw: (c, p, s) {
          c.drawPath(
            body([
              Offset(-s * 0.20, s * 0.08),
              Offset(-s * 0.02, -s * 0.08),
              Offset(s * 0.28, -s * 0.02),
              Offset(s * 0.26, s * 0.10),
            ]),
            p,
          );
        },
      ),
      _Part(
        ox: -0.42,
        oy: -0.02,
        dx: -0.90,
        dy: -0.22,
        spin: 0.16,
        draw: (c, p, s) {
          c.drawPath(
            body([
              Offset(s * 0.18, s * 0.08),
              Offset(s * 0.04, -s * 0.08),
              Offset(-s * 0.24, 0),
              Offset(-s * 0.22, s * 0.10),
            ]),
            p,
          );
        },
      ),
      _Part(
        ox: -0.02,
        oy: 0.02,
        dx: 0.18,
        dy: 0.15,
        spin: 0.12,
        draw: (c, p, s) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s * 0.36, height: s * 0.22),
              const Radius.circular(5),
            ),
            p,
          );
        },
      ),
      _Part(
        ox: 0.72,
        oy: 0.14,
        dx: 1.15,
        dy: 0.18,
        draw: (c, p, s) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s * 0.08, height: s * 0.10),
              const Radius.circular(2),
            ),
            p,
          );
        },
      ),
      _Part(
        ox: -0.72,
        oy: 0.12,
        dx: -1.12,
        dy: 0.16,
        draw: (c, p, s) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s * 0.07, height: s * 0.09),
              const Radius.circular(2),
            ),
            p,
          );
        },
      ),
      _Part(
        ox: 0.22,
        oy: -0.28,
        dx: 0.35,
        dy: -1.05,
        spin: 0.28,
        draw: (c, p, s) {
          c.drawPath(
            body([
              Offset(0, s * 0.04),
              Offset(s * 0.10, -s * 0.01),
              Offset(s * 0.02, -s * 0.05),
            ]),
            p,
          );
        },
      ),
      _Part(
        ox: 0.58,
        oy: 0.08,
        dx: 1.05,
        dy: -0.05,
        draw: (c, p, s) {
          c.drawLine(Offset(-s * 0.08, 0), Offset(s * 0.08, -s * 0.02), p);
        },
      ),
      _Part(
        ox: -0.58,
        oy: 0.08,
        dx: -1.02,
        dy: 0.04,
        draw: (c, p, s) {
          c.drawLine(Offset(s * 0.08, 0), Offset(-s * 0.08, -s * 0.02), p);
        },
      ),
    ];
  }

  @override
  bool shouldRepaint(covariant _Ta4kaPainter old) => old.t != t;
}
