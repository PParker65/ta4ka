import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/shop_brand.dart';

enum ShopMarkPlay { still, once, loop }

/// Generated mark: unique frame × craft × letters from the shop.
class ShopMark extends StatelessWidget {
  const ShopMark({
    super.key,
    required this.brand,
    required this.t,
    this.size = 56,
  });

  final ShopBrand brand;
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ShopBrand.canvas,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: brand.accent.withValues(alpha: 0.45), width: 1),
        ),
        child: CustomPaint(
          painter: ShopMarkPainter(brand: brand, t: t),
        ),
      ),
    );
  }
}

class ShopMarkLive extends StatefulWidget {
  const ShopMarkLive({
    super.key,
    required this.brand,
    this.size = 56,
    this.play = ShopMarkPlay.once,
  });

  final ShopBrand brand;
  final double size;
  final ShopMarkPlay play;

  @override
  State<ShopMarkLive> createState() => _ShopMarkLiveState();
}

class _ShopMarkLiveState extends State<ShopMarkLive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;
  bool _armed = false;
  ScrollPosition? _pos;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1480),
    );
    if (widget.play == ShopMarkPlay.still) {
      _play.value = 1;
    } else if (widget.play == ShopMarkPlay.loop) {
      _play.repeat();
    } else {
      WidgetsBinding.instance.addPostFrameCallback(_tryShow);
    }
  }

  @override
  void didUpdateWidget(covariant ShopMarkLive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brand.variant != widget.brand.variant ||
        oldWidget.brand.craft != widget.brand.craft ||
        oldWidget.brand.word != widget.brand.word ||
        oldWidget.brand.ornament != widget.brand.ornament ||
        oldWidget.brand.accent != widget.brand.accent ||
        oldWidget.brand.name != widget.brand.name) {
      if (widget.play == ShopMarkPlay.loop) {
        _play
          ..reset()
          ..repeat();
      } else if (widget.play == ShopMarkPlay.still) {
        _play.value = 1;
      } else {
        _armed = false;
        _play.reset();
        WidgetsBinding.instance.addPostFrameCallback(_tryShow);
      }
    }
  }

  void _tryShow([Duration _ = Duration.zero]) {
    if (!mounted || _armed || widget.play != ShopMarkPlay.once) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback(_tryShow);
      return;
    }
    if (_visible()) {
      _armed = true;
      _play.forward();
      return;
    }
    _pos ??= Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_onScroll);
  }

  void _onScroll() {
    if (_visible()) {
      _pos?.removeListener(_onScroll);
      if (!_armed && mounted) {
        _armed = true;
        _play.forward();
      }
    }
  }

  bool _visible() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return true;
    final parent = scrollable.context.findRenderObject();
    if (parent is! RenderBox) return true;
    final origin = box.localToGlobal(Offset.zero, ancestor: parent);
    return (origin & box.size).overlaps(Offset.zero & parent.size);
  }

  @override
  void dispose() {
    _pos?.removeListener(_onScroll);
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.play == ShopMarkPlay.still) {
      return ShopMark(brand: widget.brand, t: 1, size: widget.size);
    }
    return AnimatedBuilder(
      animation: _play,
      builder: (context, _) => ShopMark(
        brand: widget.brand,
        t: _play.value,
        size: widget.size,
      ),
    );
  }
}

class ShopLogoPicker extends StatelessWidget {
  const ShopLogoPicker({
    super.key,
    required this.selected,
    required this.brandAt,
    required this.onSelect,
    this.labels = const [],
  });

  final int selected;
  final ShopBrand Function(int variant) brandAt;
  final ValueChanged<int> onSelect;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: labels.isEmpty ? 84 : 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.isEmpty ? 8 : labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final on = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: on ? brandAt(i).accent : const Color(0x33FFFFFF),
                      width: on ? 2 : 1,
                    ),
                  ),
                  child: ShopMark(brand: brandAt(i), t: 1, size: 64),
                ),
                if (labels.length > i) ...[
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                      color: on ? Colors.white : const Color(0xFF8E8E96),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ShopMarkPainter extends CustomPainter {
  ShopMarkPainter({required this.brand, required this.t});

  final ShopBrand brand;
  final double t;

  String get _word {
    final w = brand.word.trim().toUpperCase();
    if (w.isNotEmpty) return w.length <= 4 ? w : w.substring(0, 4);
    return brand.initials.isEmpty ? 'A' : brand.initials;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    final s = math.min(size.width, size.height);
    if (s < 8) return;
    final c = Offset(size.width / 2, size.height / 2);
    final appear = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final heart = _pulse(t, 0.18, 0.36);
    final burst = _pulse(t, 0.50, 0.72);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.84 + 0.08 * heart + 0.10 * burst);
    switch (brand.variant) {
      case 0:
        _crest(canvas, s, appear);
      case 1:
        _stamp(canvas, s, appear);
      case 2:
        _letter(canvas, s, appear);
      case 3:
        _sign(canvas, s, appear);
      case 4:
        _pulseRing(canvas, s, appear, heart, burst);
      case 5:
        _hex(canvas, s, appear);
      case 6:
        _diamond(canvas, s, appear);
      case 7:
        _wings(canvas, s, appear);
      case 8:
        _bars(canvas, s, appear);
      case 9:
        _chevron(canvas, s, appear);
      case 10:
        _bracket(canvas, s, appear);
      default:
        _split(canvas, s, appear);
    }
    _ornament(canvas, s, appear);
    if (brand.variant != 2 && brand.variant != 3) {
      _glyph(canvas, s * 0.20, appear);
    }
    canvas.restore();
  }

  double _pulse(double t, double a, double b) {
    if (t < a || t > b) return 0;
    final u = (t - a) / (b - a);
    return math.sin(u * math.pi);
  }

  Paint get _fill => Paint()..color = brand.accent.withValues(alpha: 0.95);
  Paint get _stroke => Paint()
    ..color = brand.accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round;

  void _drawWord(Canvas canvas, double s, double a, {double k = 0.28, Offset o = Offset.zero}) {
    if (a < 0.25) return;
    final tp = TextPainter(
      text: TextSpan(
        text: _word,
        style: TextStyle(
          color: ShopBrand.ink.withValues(alpha: 0.96 * a),
          fontSize: s * k / math.max(1, _word.length * 0.42),
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: _word.length > 2 ? 0.6 : 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(o.dx - tp.width / 2, o.dy - tp.height / 2));
  }

  void _crest(Canvas canvas, double s, double a) {
    final h = s * 0.42 * a;
    final path = Path()
      ..moveTo(0, -h)
      ..lineTo(h * 0.78, -h * 0.55)
      ..lineTo(h * 0.72, h * 0.15)
      ..quadraticBezierTo(0, h * 1.15, -h * 0.72, h * 0.15)
      ..lineTo(-h * 0.78, -h * 0.55)
      ..close();
    canvas.drawPath(path, Paint()..color = brand.accent.withValues(alpha: 0.14 * a));
    canvas.drawPath(path, _stroke..strokeWidth = 1.9);
    _drawWord(canvas, s, a, k: 0.22, o: Offset(0, -h * 0.18));
  }

  void _stamp(Canvas canvas, double s, double a) {
    final r = s * 0.40 * a;
    canvas.drawCircle(Offset.zero, r, Paint()..color = brand.accent.withValues(alpha: 0.12));
    canvas.drawCircle(Offset.zero, r, _stroke..strokeWidth = 2.0);
    canvas.drawCircle(Offset.zero, r * 0.78, _stroke..strokeWidth = 1.05);
    _drawWord(canvas, s, a, k: 0.24);
  }

  void _letter(Canvas canvas, double s, double a) {
    _drawWord(canvas, s, a, k: 0.52);
  }

  void _sign(Canvas canvas, double s, double a) {
    final w = (s * 0.82 * a).clamp(1.0, s);
    final h = (s * 0.42 * a).clamp(1.0, s);
    final rad = math.min(w, h) / 5;
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(rad),
    );
    canvas.drawRRect(r, Paint()..color = brand.accent.withValues(alpha: 0.14));
    canvas.drawRRect(r, _stroke..strokeWidth = 1.7);
    _drawWord(canvas, s, a, k: 0.26);
  }

  void _pulseRing(Canvas canvas, double s, double a, double heart, double burst) {
    final r = s * 0.38 * a;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = brand.accent.withValues(alpha: 0.12 + 0.16 * heart)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    for (var i = 0; i < 8; i++) {
      final ang = -math.pi / 2 + i * math.pi / 4;
      final p = Offset(math.cos(ang) * r, math.sin(ang) * r);
      canvas.drawCircle(p, 2.0 + burst * 1.4, _fill);
    }
    _drawWord(canvas, s, a, k: 0.22);
  }

  void _hex(Canvas canvas, double s, double a) {
    final r = s * 0.40 * a;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final ang = -math.pi / 2 + i * math.pi / 3;
      final p = Offset(math.cos(ang) * r, math.sin(ang) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = brand.accent.withValues(alpha: 0.12 * a));
    canvas.drawPath(path, _stroke..strokeWidth = 1.8);
    _drawWord(canvas, s, a, k: 0.22);
  }

  void _diamond(Canvas canvas, double s, double a) {
    final r = s * 0.40 * a;
    final path = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.78, 0)
      ..lineTo(0, r)
      ..lineTo(-r * 0.78, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = brand.accent.withValues(alpha: 0.12 * a));
    canvas.drawPath(path, _stroke..strokeWidth = 1.8);
    _drawWord(canvas, s, a, k: 0.20);
  }

  void _wings(Canvas canvas, double s, double a) {
    final r = s * 0.38 * a;
    Path wing(double dir) {
      return Path()
        ..moveTo(0, -r * 0.15)
        ..quadraticBezierTo(dir * r * 0.55, -r * 0.85, dir * r, -r * 0.1)
        ..quadraticBezierTo(dir * r * 0.55, r * 0.2, 0, r * 0.2)
        ..close();
    }
    canvas.drawPath(wing(-1), Paint()..color = brand.accent.withValues(alpha: 0.16 * a));
    canvas.drawPath(wing(1), Paint()..color = brand.accent.withValues(alpha: 0.16 * a));
    canvas.drawPath(wing(-1), _stroke..strokeWidth = 1.4);
    canvas.drawPath(wing(1), _stroke..strokeWidth = 1.4);
    canvas.drawCircle(Offset.zero, r * 0.28, Paint()..color = brand.accent.withValues(alpha: 0.2));
    _drawWord(canvas, s, a, k: 0.18);
  }

  void _bars(Canvas canvas, double s, double a) {
    final w = s * 0.12 * a;
    for (var i = -2; i <= 2; i++) {
      final h = s * (0.18 + (2 - i.abs()) * 0.08) * a;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(i * s * 0.14, 0), width: w, height: h * 2),
          const Radius.circular(1.4),
        ),
        Paint()..color = brand.accent.withValues(alpha: 0.18 + 0.12 * (2 - i.abs()) / 2),
      );
    }
    _drawWord(canvas, s, a, k: 0.20, o: Offset(0, s * 0.28 * a));
  }

  void _chevron(Canvas canvas, double s, double a) {
    final r = s * 0.36 * a;
    for (var i = 0; i < 3; i++) {
      final o = -r * 0.15 + i * r * 0.22;
      final path = Path()
        ..moveTo(-r, o)
        ..lineTo(0, o - r * 0.42)
        ..lineTo(r, o);
      canvas.drawPath(
        path,
        Paint()
          ..color = brand.accent.withValues(alpha: (0.35 + i * 0.2) * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _bracket(Canvas canvas, double s, double a) {
    final r = s * 0.34 * a;
    final p = _stroke..strokeWidth = 2.0..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(-r, -r), Offset(-r * 0.35, -r), p);
    canvas.drawLine(Offset(-r, -r), Offset(-r, -r * 0.35), p);
    canvas.drawLine(Offset(r, -r), Offset(r * 0.35, -r), p);
    canvas.drawLine(Offset(r, -r), Offset(r, -r * 0.35), p);
    canvas.drawLine(Offset(-r, r), Offset(-r * 0.35, r), p);
    canvas.drawLine(Offset(-r, r), Offset(-r, r * 0.35), p);
    canvas.drawLine(Offset(r, r), Offset(r * 0.35, r), p);
    canvas.drawLine(Offset(r, r), Offset(r, r * 0.35), p);
    _drawWord(canvas, s, a, k: 0.28);
  }

  void _split(Canvas canvas, double s, double a) {
    final r = s * 0.40 * a;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), math.pi * 0.15, math.pi * 0.7, false, _stroke..strokeWidth = 2.1);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), math.pi * 1.15, math.pi * 0.7, false, _stroke..strokeWidth = 2.1);
    canvas.drawCircle(Offset.zero, r * 0.55, Paint()..color = brand.accent.withValues(alpha: 0.12 * a));
    _drawWord(canvas, s, a, k: 0.24);
  }

  void _ornament(Canvas canvas, double s, double a) {
    if (a < 0.5) return;
    final p = Paint()
      ..color = brand.accent.withValues(alpha: 0.85)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final r = s * 0.44;
    switch (brand.ornament) {
      case 1:
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(Offset(i * 6.0, -r), 1.5, _fill);
        }
      case 2:
        canvas.drawLine(Offset(-r * 0.35, r * 0.72), Offset(r * 0.35, r * 0.72), p);
      case 3:
        canvas.drawCircle(Offset.zero, r * 0.92, p..strokeWidth = 0.8);
      case 4:
        canvas.drawLine(Offset(-r * 0.55, -r * 0.55), Offset(-r * 0.28, -r * 0.28), p);
        canvas.drawLine(Offset(r * 0.55, r * 0.55), Offset(r * 0.28, r * 0.28), p);
      case 5:
        canvas.drawCircle(Offset(0, r * 0.78), 2.0, _fill);
    }
  }

  void _glyph(Canvas canvas, double r, double a) {
    if (a < 0.2) return;
    canvas.save();
    canvas.translate(0, r * 1.35);
    canvas.scale(a * 0.72);
    final p = Paint()
      ..color = ShopBrand.ink.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final f = Paint()..color = ShopBrand.ink.withValues(alpha: 0.88);
    switch (brand.craft) {
      case ShopCraft.engine:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 1.1), const Radius.circular(2)),
          p,
        );
        canvas.drawRect(Rect.fromCenter(center: Offset(0, -r * 0.85), width: r * 0.45, height: r * 0.55), p);
      case ShopCraft.chip:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 1.2, height: r * 1.2), const Radius.circular(2)),
          p,
        );
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(Offset(-r * 1.05, i * r * 0.35), Offset(-r * 0.6, i * r * 0.35), p);
          canvas.drawLine(Offset(r * 0.6, i * r * 0.35), Offset(r * 1.05, i * r * 0.35), p);
        }
      case ShopCraft.paint:
        final drop = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(r * 0.85, -r * 0.1, 0, r)
          ..quadraticBezierTo(-r * 0.85, -r * 0.1, 0, -r);
        canvas.drawPath(drop, p);
      case ShopCraft.chassis:
        canvas.drawCircle(Offset(-r * 0.7, 0), r * 0.38, p);
        canvas.drawCircle(Offset(r * 0.7, 0), r * 0.38, p);
        canvas.drawLine(Offset(-r * 0.32, 0), Offset(r * 0.32, 0), p);
      case ShopCraft.bolt:
        final bolt = Path()
          ..moveTo(r * 0.15, -r)
          ..lineTo(-r * 0.35, 0.05)
          ..lineTo(0.05, 0.05)
          ..lineTo(-r * 0.15, r)
          ..lineTo(r * 0.4, -0.08)
          ..lineTo(0, -0.08)
          ..close();
        canvas.drawPath(bolt, f);
      case ShopCraft.wheel:
        canvas.drawCircle(Offset.zero, r, p);
        canvas.drawCircle(Offset.zero, r * 0.28, f);
        for (var i = 0; i < 5; i++) {
          final ang = i * math.pi * 2 / 5;
          canvas.drawLine(Offset.zero, Offset(math.cos(ang) * r, math.sin(ang) * r), p);
        }
      case ShopCraft.drop:
        final oil = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(r * 0.9, r * 0.2, 0, r)
          ..quadraticBezierTo(-r * 0.9, r * 0.2, 0, -r);
        canvas.drawPath(oil, p);
      case ShopCraft.wrench:
        canvas.rotate(-0.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 0.42, height: r * 2.1), const Radius.circular(3)),
          p,
        );
        canvas.drawCircle(Offset(0, -r * 0.85), r * 0.42, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ShopMarkPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.brand.variant != brand.variant ||
      oldDelegate.brand.ornament != brand.ornament ||
      oldDelegate.brand.craft != brand.craft ||
      oldDelegate.brand.accent != brand.accent ||
      oldDelegate.brand.word != brand.word ||
      oldDelegate.brand.initials != brand.initials;
}

