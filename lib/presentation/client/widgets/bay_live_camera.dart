import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../data/live_cams.dart';
import '../../widgets/live_cam_player.dart';

const double kBayLiveHeight = 114;
const double kBayLiveCompactHeight = 72;

class BayLiveCamera extends StatelessWidget {
  const BayLiveCamera({
    super.key,
    this.assets = const [],
    required this.liveLabel,
    this.compact = false,
    this.seed,
    this.online = true,
    this.soonLead = '',
    this.soonHope = '',
  });

  final List<String> assets;
  final String liveLabel;
  final bool compact;
  final String? seed;
  /// Bound HLS when true. Offline shops get a cheerful placeholder, not an empty player.
  final bool online;
  final String soonLead;
  final String soonHope;

  @override
  Widget build(BuildContext context) {
    final height = compact ? kBayLiveCompactHeight : kBayLiveHeight;
    if (!online) {
      return ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: BayCamSoon(
            lead: soonLead,
            hope: soonHope,
            compact: compact,
          ),
        ),
      );
    }
    final palette = paletteOf(context);
    final cam = liveCamFor(seed ?? (assets.isEmpty ? liveLabel : assets.join()));

    return ClipRRect(
      clipBehavior: kIsWeb ? Clip.none : Clip.hardEdge,
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: kIsWeb ? Clip.none : Clip.hardEdge,
        children: [
          ColoredBox(color: palette.carbon),
          IgnorePointer(child: LiveCamPlayer(cam: cam, compact: compact)),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF453A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      liveLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: IgnorePointer(
                child: Text(
                  '${cam.camCode} · ${cam.hostShort}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (compact)
              const Positioned(
                right: 10,
                bottom: 10,
                child: IgnorePointer(
                  child: Icon(
                    CupertinoIcons.fullscreen,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            if (!compact)
              const Positioned(
                left: 10,
                bottom: 10,
                child: IgnorePointer(child: _ClockLabel()),
              ),
            if (compact)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => openLiveCamPlayer(context, cam, liveLabel),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void openLiveCamPlayer(BuildContext context, LiveCam cam, String liveLabel) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A0A0C),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              BayLiveCamera(
                seed: cam.id,
                liveLabel: liveLabel,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Cheerful stand-in when a demo shop has not plugged a bay camera in yet.
class BayCamSoon extends StatefulWidget {
  const BayCamSoon({
    super.key,
    required this.lead,
    required this.hope,
    this.compact = false,
  });

  final String lead;
  final String hope;
  final bool compact;

  @override
  State<BayCamSoon> createState() => _BayCamSoonState();
}

class _BayCamSoonState extends State<BayCamSoon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final pad = widget.compact ? 10.0 : 14.0;
    final iconBox = widget.compact ? 56.0 : 72.0;
    return ColoredBox(
      color: palette.carbon,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: widget.compact ? 6 : 8),
        child: Row(
          children: [
            SizedBox(
              width: iconBox,
              height: iconBox,
              child: AnimatedBuilder(
                animation: _beat,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SoonPainter(
                      t: _beat.value,
                      ink: palette.text,
                      muted: palette.muted,
                      accent: palette.accent,
                      danger: palette.danger,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: widget.compact ? 8 : 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lead,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.compact ? 12 : 14,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (widget.hope.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.hope,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: widget.compact ? 11 : 13,
                        height: 1.25,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CCTV that looks around, a plug that almost docks, a wink on the lens.
class _SoonPainter extends CustomPainter {
  _SoonPainter({
    required this.t,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.danger,
  });

  final double t;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color danger;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.46;
    final look = math.sin(t * math.pi * 2) * 0.22;
    final bob = math.sin(t * math.pi * 2 + 0.7) * 2.2;
    final wink = (math.sin(t * math.pi * 2 - 0.4) + 1) / 2;
    final plug = (math.sin(t * math.pi * 2 + 1.1) + 1) / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = muted.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final sweep = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(
        Rect.fromCircle(center: c, radius: r * 0.92),
        -math.pi / 2 + look * 3,
        math.pi * 0.42,
        false,
      )
      ..close();
    canvas.drawPath(
      sweep,
      Paint()..color = accent.withValues(alpha: 0.10 + 0.10 * wink),
    );

    canvas.save();
    canvas.translate(c.dx + look * 6, c.dy - 4 + bob);
    canvas.rotate(look);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-16, -10, 26, 18),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, Paint()..color = ink.withValues(alpha: 0.92));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -6, 6, 10),
        const Radius.circular(2),
      ),
      Paint()..color = muted,
    );
    final lensR = 5.2 * (0.35 + 0.65 * wink);
    canvas.drawCircle(const Offset(4, -1), 6.2, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(
      const Offset(4, -1),
      lensR,
      Paint()..color = Color.lerp(muted, accent, wink)!,
    );
    canvas.drawCircle(
      const Offset(2.6, -2.2),
      1.4,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      const Offset(-10, -12),
      2.1,
      Paint()..color = Color.lerp(danger, const Color(0xFFFFD60A), wink)!,
    );
    canvas.restore();

    final plugX = c.dx + 10 + plug * 8;
    final plugY = c.dy + 16 - plug * 4;
    final cable = Path()
      ..moveTo(c.dx - 4, c.dy + 8)
      ..cubicTo(
        c.dx + 4,
        c.dy + 18,
        plugX - 8,
        plugY - 2,
        plugX,
        plugY,
      );
    canvas.drawPath(
      cable,
      Paint()
        ..color = muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(plugX + 5, plugY), width: 10, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = accent.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(plugX + 11, plugY),
      1.6,
      Paint()..color = const Color(0xFFFFD60A).withValues(alpha: 0.4 + 0.6 * plug),
    );
  }

  @override
  bool shouldRepaint(covariant _SoonPainter old) =>
      old.t != t || old.ink != ink || old.muted != muted || old.accent != accent;
}

class _ClockLabel extends StatefulWidget {
  const _ClockLabel();

  @override
  State<_ClockLabel> createState() => _ClockLabelState();
}

class _ClockLabelState extends State<_ClockLabel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('HH:mm:ss').format(DateTime.now()),
      style: const TextStyle(
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
