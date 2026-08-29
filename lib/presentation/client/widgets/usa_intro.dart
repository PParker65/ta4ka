import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kLTransRed = Color(0xFFD70200);
const kLTransBg = Color(0xFF07070A);
const kLTransInk = Color(0xFFF4F4F6);
const kLTransLogoAsset = 'assets/usa/lion_trans.png';
const kLTransLockupAsset = 'assets/usa/lion_trans_lockup.png';
const _kLockupSilver = Color(0xFFE8E8ED);

ui.Image? _lTransLogoImage;
Future<ui.Image>? _lTransLogoFuture;
ui.Image? _lTransLockupImage;
Future<ui.Image>? _lTransLockupFuture;

Future<ui.Image> _decodeAsset(String asset, int targetWidth) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: targetWidth,
  );
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ui.Image> loadLTransLogo() {
  if (_lTransLogoImage != null) return Future<ui.Image>.value(_lTransLogoImage);
  return _lTransLogoFuture ??=
      _decodeAsset(kLTransLogoAsset, 640).then((img) => _lTransLogoImage = img);
}

Future<ui.Image> loadLTransLockup() {
  if (_lTransLockupImage != null) return Future<ui.Image>.value(_lTransLockupImage);
  return _lTransLockupFuture ??=
      _decodeAsset(kLTransLockupAsset, 860).then((img) => _lTransLockupImage = img);
}

void paintLTransLogoMark(
  Canvas canvas,
  ui.Image? logo,
  double r, {
  double appear = 1,
}) {
  if (logo == null || r <= 0) return;
  final src = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
  final dst = Rect.fromCenter(center: Offset.zero, width: r * 2.45, height: r * 2.45);
  final a = appear.clamp(0.0, 1.0);
  canvas.drawImageRect(
    logo,
    src,
    dst,
    Paint()
      ..filterQuality = FilterQuality.high
      ..colorFilter = a >= 0.999
          ? null
          : ColorFilter.mode(Color.fromRGBO(255, 255, 255, a), BlendMode.modulate),
  );
}

const _kMotion = Duration(milliseconds: 2800);
/// Shared loop for lion energy tiles (services sheet uses one clock).
const kLTransEnergyPeriod = _kMotion;
/// One beat: his mark fades in, holds, then the pipeline.
const _kIntroMotion = Duration(milliseconds: 2000);
const _kHold = Duration(milliseconds: 2200);
const _kFade = Duration(milliseconds: 280);

/// Cinematic Lion Trans lockup — his artwork + name, then the USA pipeline.
class UsaIntroGate extends StatefulWidget {
  const UsaIntroGate({super.key, required this.child});

  final Widget child;

  @override
  State<UsaIntroGate> createState() => _UsaIntroGateState();
}

class _UsaIntroGateState extends State<UsaIntroGate>
    with TickerProviderStateMixin {
  late final AnimationController _fade;
  late final AnimationController _play;
  bool _cover = true;
  ui.Image? _logo;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: _kFade);
    _play = AnimationController(vsync: this, duration: _kIntroMotion)..forward();
    Future<void>.delayed(_kHold, _release);
    loadLTransLockup().then((img) {
      if (mounted) setState(() => _logo = img);
    });
  }

  void _release() {
    if (!mounted || !_cover) return;
    _play.stop();
    _fade.forward().whenComplete(() {
      if (mounted) setState(() => _cover = false);
    });
  }

  @override
  void dispose() {
    _play.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cover) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: ReverseAnimation(_fade),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _release,
              child: ColoredBox(
                color: kLTransBg,
                child: AnimatedBuilder(
                  animation: _play,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _UsaLockupPainter(t: _play.value, logo: _logo),
                      child: const SizedBox.expand(),
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

double _pulse(double t, double at) {
  final x = (t - at) * 14;
  if (x < -0.2) return 0;
  if (x < 0) return Curves.easeIn.transform((x + 0.2) / 0.2);
  return math.exp(-x * x * 2.2);
}

const _kBeats = [0.00, 0.30, 0.56];

double _heart(double t) =>
    (_pulse(t, _kBeats[0]) + _pulse(t, _kBeats[1]) + _pulse(t, _kBeats[2])).clamp(0.0, 1.0);

double usaUaTravel(double t, {required bool loop}) {
  if (loop) {
    final u = (t * 2) % 2.0;
    final x = u <= 1 ? u : 2 - u;
    return Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));
  }
  if (t < 0.10) return 0;
  if (t < 0.88) return Curves.easeInOutCubic.transform((t - 0.10) / 0.78);
  return 1;
}

void paintUsaUaCrossing(
  Canvas canvas, {
  required Offset us,
  required Offset ua,
  required double travel,
  required double appear,
  double scale = 1,
  double arcLift = 0.16,
}) {
  if (appear <= 0.04) return;
  final mid = Offset((us.dx + ua.dx) / 2, math.min(us.dy, ua.dy) - (ua.dx - us.dx).abs() * arcLift);
  final route = Path()
    ..moveTo(us.dx, us.dy)
    ..quadraticBezierTo(mid.dx, mid.dy, ua.dx, ua.dy);

  canvas.drawPath(
    route,
    Paint()
      ..color = kLTransRed.withValues(alpha: 0.22 * appear)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * scale
      ..strokeCap = StrokeCap.round,
  );
  for (final metric in route.computeMetrics()) {
    canvas.drawPath(
      metric.extractPath(0, metric.length * travel),
      Paint()
        ..color = kLTransRed.withValues(alpha: appear)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  canvas.save();
  canvas.translate(us.dx, us.dy);
  canvas.scale(scale);
  _usaFlagUs(canvas, Offset.zero);
  canvas.restore();

  canvas.save();
  canvas.translate(ua.dx, ua.dy);
  canvas.scale(scale);
  _usaFlagUa(canvas, Offset.zero);
  canvas.restore();

  Offset carPos = us;
  var ang = 0.0;
  for (final metric in route.computeMetrics()) {
    final tan = metric.getTangentForOffset(metric.length * travel);
    if (tan != null) {
      carPos = tan.position;
      ang = tan.angle;
    }
  }
  canvas.save();
  canvas.translate(carPos.dx, carPos.dy);
  canvas.scale(scale);
  _usaConvoy(canvas, Offset.zero, ang, travel, appear);
  canvas.restore();
}

void _usaFlagUs(Canvas canvas, Offset p) {
  const w = 32.0;
  const h = 22.0;
  final rect = Rect.fromCenter(center: p, width: w, height: h);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(2.2)),
    Paint()..color = const Color(0xFFB22234),
  );
  for (var i = 1; i < 7; i += 2) {
    canvas.drawRect(
      Rect.fromLTWH(p.dx - w / 2, p.dy - h / 2 + h * i / 7, w, h / 7),
      Paint()..color = const Color(0xFFF5F5F5),
    );
  }
  canvas.drawRect(
    Rect.fromLTWH(p.dx - w / 2, p.dy - h / 2, w * 0.42, h * 0.54),
    Paint()..color = const Color(0xFF3C3B6E),
  );
}

void _usaFlagUa(Canvas canvas, Offset p) {
  const w = 32.0;
  const h = 22.0;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: p, width: w, height: h),
      const Radius.circular(2.2),
    ),
    Paint()..color = const Color(0xFF005BBB),
  );
  canvas.drawRect(
    Rect.fromLTWH(p.dx - w / 2, p.dy, w, h / 2),
    Paint()..color = const Color(0xFFFFD500),
  );
}

void _usaConvoy(Canvas canvas, Offset pos, double ang, double travel, double appear) {
  if (appear < 0.2) return;
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  canvas.rotate(ang);
  final overSea = travel > 0.18 && travel < 0.78;
  if (overSea) {
    final wake = Paint()
      ..color = const Color(0x66E8F4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawLine(const Offset(-42, 14), const Offset(-12, 5), wake);
    canvas.drawLine(const Offset(-42, -14), const Offset(-12, -5), wake);
    final hull = Path()
      ..moveTo(-34, 12)
      ..lineTo(32, 9)
      ..lineTo(40, 0)
      ..lineTo(28, -7)
      ..lineTo(-28, -6)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFFE4E4EA));
    canvas.drawPath(
      hull,
      Paint()
        ..color = kLTransRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawRect(const Rect.fromLTWH(-14, -1.5, 32, 3.2), Paint()..color = kLTransRed);
  }
  canvas.rotate(-ang * 0.65);
  _usaCar(canvas, Offset(0, overSea ? -18 : -3));
  canvas.restore();
}

void _usaCar(Canvas canvas, Offset p) {
  canvas.drawOval(
    Rect.fromCenter(center: p + const Offset(0, 11), width: 40, height: 8),
    Paint()..color = const Color(0x66000000),
  );
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: p, width: 42, height: 15),
    const Radius.circular(3.4),
  );
  canvas.drawRRect(body, Paint()..color = const Color(0xFFF2F2F6));
  canvas.drawRRect(
    body,
    Paint()
      ..color = kLTransRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: p + const Offset(2, -9), width: 21, height: 11),
      const Radius.circular(2.4),
    ),
    Paint()..color = const Color(0xFF2A3340),
  );
  canvas.drawCircle(p + const Offset(-13, 8), 4.0, Paint()..color = const Color(0xFF111114));
  canvas.drawCircle(p + const Offset(13, 8), 4.0, Paint()..color = const Color(0xFF111114));
  canvas.drawCircle(p + const Offset(19, 0), 2.0, Paint()..color = const Color(0xFFFFD54A));
}

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

double _lockup(double t, double a, double b) {
  if (b <= a) return t >= a ? 1.0 : 0.0;
  return Curves.easeOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
}

/// His Lion Trans lockup — fade, scale, reveal. No drawn lion.
class _UsaLockupPainter extends CustomPainter {
  _UsaLockupPainter({required this.t, required this.logo});

  final double t;
  final ui.Image? logo;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    final origin = Offset(size.width / 2, size.height / 2 - 8);
    final s = size.shortestSide * 0.42;
    final appear = _lockup(t, 0.00, 0.16);
    final settle = _lockup(t, 0.04, 0.58);
    final reveal = _lockup(t, 0.06, 0.52);
    final note = _lockup(t, 0.58, 0.82);

    canvas.drawCircle(
      origin,
      s * 1.55,
      Paint()
        ..shader = ui.Gradient.radial(
          origin,
          s * 1.55,
          [
            _kLockupSilver.withValues(alpha: 0.045 * appear),
            kLTransBg.withValues(alpha: 0),
          ],
        ),
    );

    if (logo != null && reveal > 0) {
      final src = Rect.fromLTWH(
        0,
        0,
        logo!.width.toDouble(),
        logo!.height.toDouble(),
      );
      final aspect = src.width / src.height;
      final h = s * 1.72;
      final w = h * aspect;
      final dst = Rect.fromCenter(center: origin, width: w, height: h);

      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(0.94 + 0.06 * settle);
      canvas.translate(-origin.dx, -origin.dy);

      final halfH = dst.height / 2 * reveal;
      canvas.clipRect(
        Rect.fromLTRB(dst.left, origin.dy - halfH, dst.right, origin.dy + halfH),
      );
      canvas.drawImageRect(
        logo!,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true
          ..colorFilter = ColorFilter.mode(
            Color.fromRGBO(255, 255, 255, appear),
            BlendMode.modulate,
          ),
      );
      canvas.restore();

      if (note > 0) {
        final y = dst.bottom + 14;
        final half = dst.width * 0.18 * note;
        canvas.drawLine(
          Offset(origin.dx - half, y),
          Offset(origin.dx + half, y),
          Paint()
            ..color = kLTransRed.withValues(alpha: 0.88 * note)
            ..strokeWidth = 1.15
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UsaLockupPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.logo != logo;
}

/// Compact Lion Trans mark for the USA app bar.
class LTransLogoMark extends StatelessWidget {
  const LTransLogoMark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        kLTransLogoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

/// Official lion PNG with inset so the snout (right edge of the file) never clips.
class LTransPaddedMark extends StatelessWidget {
  const LTransPaddedMark({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(10, 12, 20, 12),
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Image.asset(
        kLTransLogoAsset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

void _paintEnergyGlyph(Canvas canvas, IconData icon, double r) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: r * 1.72,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: kLTransRed,
        height: 1,
        shadows: [
          Shadow(color: kLTransRed.withValues(alpha: 0.55), blurRadius: 10),
        ],
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
}

/// Looping lion + energy — replaces the partner photo in categories / services.
class LTransEnergyArt extends StatefulWidget {
  const LTransEnergyArt({
    super.key,
    this.wordmark = false,
    this.showRoute = false,
    this.lionAlign = Alignment.center,
    this.clock,
    this.glyph,
  });

  final bool wordmark;
  final bool showRoute;
  final Alignment lionAlign;
  /// Shared loop. When set, this widget does not own a ticker.
  final Animation<double>? clock;
  /// When set, draw this icon instead of the lion mark.
  final IconData? glyph;

  @override
  State<LTransEnergyArt> createState() => _LTransEnergyArtState();
}

class _LTransEnergyArtState extends State<LTransEnergyArt>
    with SingleTickerProviderStateMixin {
  AnimationController? _play;
  ui.Image? _logo;

  Animation<double> get _tick => widget.clock ?? _play!;

  @override
  void initState() {
    super.initState();
    if (widget.clock == null) {
      _play = AnimationController(vsync: this, duration: kLTransEnergyPeriod)..repeat();
    }
    if (widget.glyph == null) {
      loadLTransLogo().then((img) {
        if (mounted) setState(() => _logo = img);
      });
    }
  }

  @override
  void didUpdateWidget(LTransEnergyArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock) {
      if (widget.clock == null) {
        _play ??= AnimationController(vsync: this, duration: kLTransEnergyPeriod)..repeat();
      } else {
        _play?.dispose();
        _play = null;
      }
    }
  }

  @override
  void dispose() {
    _play?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        return CustomPaint(
          painter: _LTransEnergyPainter(
            t: _tick.value,
            logo: _logo,
            wordmark: widget.wordmark,
            showRoute: widget.showRoute,
            lionAlign: widget.lionAlign,
            glyph: widget.glyph,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LTransEnergyPainter extends CustomPainter {
  _LTransEnergyPainter({
    required this.t,
    required this.logo,
    required this.wordmark,
    required this.showRoute,
    required this.lionAlign,
    this.glyph,
  });

  final double t;
  final ui.Image? logo;
  final bool wordmark;
  final bool showRoute;
  final Alignment lionAlign;
  final IconData? glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(w, h),
          const [Color(0xFF1A080A), Color(0xFF07070A), Color(0xFF12060A)],
          const [0.0, 0.55, 1.0],
        ),
    );

    final heart = _heart(t);
    final burst = _burst(t);
    final tiny = math.min(w, h) < 100;
    final lionC = Offset(
      w * (0.5 + lionAlign.x * 0.38),
      h * ((showRoute && !tiny ? 0.62 : 0.48) + lionAlign.y * 0.10),
    );
    final s = math.min(w, h) * (wordmark || showRoute ? 0.36 : 0.48);
    final bloom = 28.0 + 48.0 * heart + 18.0 * burst;
    canvas.drawCircle(
      lionC,
      bloom,
      Paint()
        ..shader = ui.Gradient.radial(
          lionC,
          bloom,
          [
            kLTransRed.withValues(alpha: 0.34 + 0.38 * heart),
            kLTransRed.withValues(alpha: 0.10),
            const Color(0x0007070A),
          ],
          const [0.0, 0.48, 1.0],
        ),
    );
    for (final beatAt in _kBeats) {
      final age = ((t - beatAt) / 0.22).clamp(0.0, 1.0);
      if (t < beatAt || age <= 0) continue;
      canvas.drawCircle(
        lionC,
        s * (0.42 + 1.05 * Curves.easeOut.transform(age)),
        Paint()
          ..color = kLTransRed.withValues(alpha: (1 - age) * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - age),
      );
    }

    canvas.save();
    canvas.translate(lionC.dx, lionC.dy);
    canvas.scale(1.0 + 0.08 * heart);
    if (glyph != null) {
      _paintEnergyGlyph(canvas, glyph!, s * 0.58);
    } else {
      paintLTransLogoMark(canvas, logo, s * 0.58);
    }
    canvas.restore();

    if (showRoute && !tiny) {
      // Half the old USA→UA span, centered in the tile, below the top edge.
      const span = 0.34;
      final routeY = h * 0.44;
      paintUsaUaCrossing(
        canvas,
        us: Offset(w * (0.5 - span / 2), routeY),
        ua: Offset(w * (0.5 + span / 2), routeY),
        travel: usaUaTravel(t, loop: true),
        appear: 1,
        scale: (math.min(w, h) / 240).clamp(0.42, 0.72),
        arcLift: 0.10,
      );
    }

    if (!wordmark) return;
    final markY = showRoute && !tiny ? h * 0.80 : lionC.dy + s * 0.72;
    final tp = TextPainter(
      text: TextSpan(
        text: 'LION TRANS',
        style: TextStyle(
          color: kLTransRed.withValues(alpha: 0.98),
          fontSize: (h * 0.11).clamp(12.0, 18.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 16);
    final markX = showRoute
        ? (w - tp.width) / 2
        : lionC.dx - tp.width / 2;
    tp.paint(canvas, Offset(markX, markY));
  }

  @override
  bool shouldRepaint(covariant _LTransEnergyPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.logo != logo ||
      oldDelegate.wordmark != wordmark ||
      oldDelegate.showRoute != showRoute ||
      oldDelegate.lionAlign != lionAlign ||
      oldDelegate.glyph != glyph;
}
