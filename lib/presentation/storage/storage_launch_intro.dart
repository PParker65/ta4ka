import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kolesa_boot_stub.dart'
    if (dart.library.html) 'kolesa_boot_web.dart';

const _kBg = Color(0xFF0B0D11);
const _kSteel = Color(0xFFC5CDD6);
const _kBead = Color(0xFF8C877E);
const _kRim = Color(0xFFE7E1D6);
const _kAccent = Color(0xFFE8A23A);
const _kCream = Color(0xFFF4EFE6);

const kStorageLaunchHold = Duration(milliseconds: 1600);
const kStorageLaunchFade = Duration(milliseconds: 220);

/// Native fallback when the HTML mark is absent. Rim, then tread,
/// then the word cuts in. No audio, no 3D.
class StorageLaunchIntroGate extends ConsumerStatefulWidget {
  const StorageLaunchIntroGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StorageLaunchIntroGate> createState() =>
      _StorageLaunchIntroGateState();
}

class _StorageLaunchIntroGateState extends ConsumerState<StorageLaunchIntroGate>
    with TickerProviderStateMixin {
  late final AnimationController _hold;
  late final AnimationController _fade;
  bool _cover = true;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: kStorageLaunchFade);
    _hold = AnimationController(vsync: this, duration: kStorageLaunchHold);
    if (kolesaHtmlBootVisible()) {
      _cover = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        signalKolesaBootReady();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() => _cover = false);
        return;
      }
      _hold.forward().whenComplete(_release);
    });
  }

  void _release() {
    if (!mounted || !_cover) return;
    _fade.forward().whenComplete(() {
      if (mounted) setState(() => _cover = false);
    });
  }

  @override
  void dispose() {
    _hold.dispose();
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
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(
                  CurvedAnimation(parent: _fade, curve: Curves.linear),
                ),
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.light,
                  child: ColoredBox(
                    color: _kBg,
                    child: AnimatedBuilder(
                      animation: _hold,
                      builder: (context, _) => StorageLaunchStage(t: _hold.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StorageLaunchStage extends StatelessWidget {
  const StorageLaunchStage({super.key, required this.t});

  final double t;

  double _u(double start, double dur) => ((t - start) / dur).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cut = _u(0.66, 0.14);
    final size = MediaQuery.sizeOf(context);
    final mark = math.min(size.shortestSide * 0.58, 228.0);
    return ColoredBox(
      color: _kBg,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: mark,
              height: mark,
              child: CustomPaint(
                painter: _MarkPainter(t: t >= 0.64 ? 1 : t / 0.64),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: ClipRect(
                clipper: _CutClipper(cut),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'KOLESA',
                            style: TextStyle(color: _kCream.withValues(alpha: 0.96)),
                          ),
                          TextSpan(
                            text: ' SAVE',
                            style: TextStyle(color: _kAccent),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontSize: 28,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 3, width: 168, color: _kAccent),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _CutClipper extends CustomClipper<Rect> {
  const _CutClipper(this.cut);

  final double cut;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * cut, size.height);

  @override
  bool shouldReclip(covariant _CutClipper oldDelegate) => oldDelegate.cut != cut;
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.t});

  final double t;

  double _u(double start, double dur) => ((t - start) / dur).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide / 200;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [_kAccent.withValues(alpha: 0.1), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c, radius: 90 * s));
    canvas.drawCircle(c, 90 * s, glow);

    void ring(double r, double u, Color color, double width) {
      if (u <= 0) return;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * s),
        -math.pi / 2,
        u * math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = width * s
          ..color = color,
      );
    }

    ring(52, _u(0.0, 0.22), _kAccent, 5.5);
    ring(44, _u(0.1, 0.14), _kAccent, 1.7);
    ring(30, _u(0.12, 0.16), _kRim, 2.6);

    final spokes = _u(0.2, 0.14);
    final spoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4 * s
      ..color = _kSteel;
    for (var i = 0; i < 5; i++) {
      final local = (spokes * 5 - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      final dir = Offset(math.cos(a), math.sin(a));
      final p0 = c + dir * 12 * s;
      final p1 = c + dir * 28 * s;
      canvas.drawLine(p0, Offset.lerp(p0, p1, local)!, spoke);
    }

    final hub = _u(0.32, 0.06);
    if (hub > 0) {
      canvas.drawCircle(c, 8 * s * hub, Paint()..color = _kAccent);
      canvas.drawCircle(c, 3 * s * hub, Paint()..color = _kBg);
    }

    ring(78, _u(0.34, 0.16), const Color(0xFF3F3832), 18);

    final tread = _u(0.36, 0.2);
    final lug = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 13 * s
      ..color = _kRim;
    const n = 10;
    for (var i = 0; i < n; i++) {
      final local = (tread * n - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final a0 = -math.pi / 2 + i * math.pi * 2 / n;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 78 * s),
        a0,
        0.34 * local,
        false,
        lug,
      );
    }
    ring(88, _u(0.36, 0.2), _kBead, 2.4);
    ring(68, _u(0.36, 0.2), _kBead, 2.4);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => oldDelegate.t != t;
}
