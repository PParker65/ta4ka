import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/shop_brand.dart';
import '../../widgets/shop_mark.dart';
import 'feed_video_player.dart';

const _kHold = Duration(milliseconds: 1000);
const _kFade = Duration(milliseconds: 260);

/// Full-screen brand beat — same language as the Ta4ka launch logo, then the shop menu.
class ShopIntroGate extends StatefulWidget {
  const ShopIntroGate({
    super.key,
    required this.brand,
    required this.name,
    required this.child,
  });

  final ShopBrand brand;
  final String name;
  final Widget child;

  @override
  State<ShopIntroGate> createState() => _ShopIntroGateState();
}

class _ShopIntroGateState extends State<ShopIntroGate>
    with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _fade;
  bool _cover = true;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: _kHold)..forward();
    _fade = AnimationController(vsync: this, duration: _kFade);
    pauseAllFeedVideos();
    resumeApexLiveVideos();
    Future<void>.delayed(_kHold, _release);
  }

  void _release() {
    if (!mounted || !_cover) return;
    pauseAllFeedVideos();
    resumeApexLiveVideos();
    _fade.forward().whenComplete(() {
      if (mounted) setState(() => _cover = false);
    });
  }

  @override
  void dispose() {
    _motion.dispose();
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
            opacity: ReverseAnimation(_fade),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _release,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: ColoredBox(
                  color: ShopBrand.canvas,
                  child: AnimatedBuilder(
                    animation: _motion,
                    builder: (context, _) {
                      final t = _motion.value;
                      return CustomPaint(
                        painter: _ShopIntroBloom(brand: widget.brand, t: t),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: CustomPaint(
                                    painter: ShopMarkPainter(
                                      brand: widget.brand,
                                      t: t,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  widget.name,
                                  textAlign: TextAlign.center,
                                  style: shopTitleStyle(widget.brand, size: 28),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopIntroBloom extends CustomPainter {
  _ShopIntroBloom({required this.brand, required this.t});

  final ShopBrand brand;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2 - 28);
    final appear = Curves.easeOut.transform((t / 0.12).clamp(0.0, 1.0));
    double pulse(double at) {
      final x = (t - at) * 16;
      if (x < -0.2) return 0;
      if (x < 0) return Curves.easeIn.transform((x + 0.2) / 0.2);
      return math.exp(-x * x * 2.4);
    }

    final heart = (pulse(0.20) + pulse(0.54)).clamp(0.0, 1.0);
    final bloom = 90.0 + 140.0 * heart;
    canvas.drawCircle(
      origin,
      bloom,
      Paint()
        ..shader = ui.Gradient.radial(
          origin,
          bloom,
          [
            brand.accent.withValues(alpha: 0.16 * appear + 0.28 * heart),
            brand.accent.withValues(alpha: 0.05 * appear),
            ShopBrand.canvas.withValues(alpha: 0),
          ],
          const [0.0, 0.42, 1.0],
        ),
    );
    for (final beatAt in [0.20, 0.54]) {
      final age = ((t - beatAt) / 0.28).clamp(0.0, 1.0);
      if (t < beatAt || age <= 0) continue;
      canvas.drawCircle(
        origin,
        size.shortestSide * 0.22 * (0.35 + 1.55 * Curves.easeOut.transform(age)),
        Paint()
          ..color = brand.accent.withValues(alpha: (1 - age) * 0.55 * appear)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * (1 - age),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShopIntroBloom old) => old.t != t;
}
