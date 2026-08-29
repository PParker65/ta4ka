import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/car_brands.dart';
import '../../data/car_hotspots.dart';
import '../../data/car_layout.dart';
import '../../data/farm_quests.dart';
import 'interactive_car.dart';

const _kWebYaw = 2.35;
const _kWebPitch = 0.40;
const _kWebZoom = 1.445;

/// Lightweight 2D car stage for Flutter Web.
class WebCarStage extends StatelessWidget {
  const WebCarStage({
    super.key,
    required this.lang,
    required this.onSelect,
    required this.hint,
    this.selectedHotspotId,
    this.embedded = false,
    this.accentColor,
    this.bodyColor,
    this.brand,
    this.uniquePluses = false,
    this.showSmash = false,
    this.onCarTap,
    this.onSmash,
    this.autoRotate = true,
  });

  final AppLang lang;
  final String? selectedHotspotId;
  final String hint;
  final ValueChanged<CarHotspot> onSelect;
  final bool embedded;
  final Color? accentColor;
  final Color? bodyColor;
  final CarBrand? brand;
  final bool uniquePluses;
  final bool showSmash;
  final VoidCallback? onCarTap;
  final VoidCallback? onSmash;
  final bool autoRotate;

  CarBrand get _brand {
    final b = brand ?? genericBrand;
    if (bodyColor == null) {
      return b;
    }
    return b.copyWith(bodyColor: bodyColor);
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final accent = accentColor ?? palette.accent;
    final placed = placedHotspots(_brand);
    final spots = uniquePluses ? uniqueFarmHotspots(placed) : placed;
    CarHotspot? selected;
    for (final h in spots) {
      if (h.id == selectedHotspotId) {
        selected = h;
        break;
      }
    }

    final stage = _WebStageBody(
      lang: lang,
      accent: accent,
      brand: _brand,
      spots: spots,
      selected: selected,
      selectedId: selectedHotspotId,
      onSelect: onSelect,
      onCarTap: onCarTap,
      autoRotate: autoRotate,
    );

    if (embedded) {
      return Stack(
        children: [
          Positioned.fill(child: stage),
          Positioned(
            right: 4,
            bottom: 4,
            child: Row(
              children: [
                _MiniIcon(icon: CupertinoIcons.refresh, onTap: () {}),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      child: SizedBox.expand(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 0),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(color: palette.muted, fontSize: 12, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: stage),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebStageBody extends StatefulWidget {
  const _WebStageBody({
    required this.lang,
    required this.accent,
    required this.brand,
    required this.spots,
    required this.selected,
    required this.selectedId,
    required this.onSelect,
    this.onCarTap,
    this.autoRotate = true,
  });

  final AppLang lang;
  final Color accent;
  final CarBrand brand;
  final List<CarHotspot> spots;
  final CarHotspot? selected;
  final String? selectedId;
  final ValueChanged<CarHotspot> onSelect;
  final VoidCallback? onCarTap;
  final bool autoRotate;

  @override
  State<_WebStageBody> createState() => _WebStageBodyState();
}

class _WebStageBodyState extends State<_WebStageBody> with SingleTickerProviderStateMixin {
  String? _hoveredId;
  late final AnimationController _spin;
  late final Timer _pulseTimer;
  bool _pulseUp = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 36000),
    );
    if (widget.autoRotate) {
      _spin.repeat();
    }
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => _pulseUp = !_pulseUp);
    });
  }

  @override
  void didUpdateWidget(covariant _WebStageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoRotate != widget.autoRotate) {
      if (widget.autoRotate) {
        _spin.repeat();
      } else {
        _spin.stop();
      }
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulseTimer.cancel();
    super.dispose();
  }

  double get _yaw =>
      _kWebYaw - (widget.autoRotate ? _spin.value * math.pi * 2 : 0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final origin = Offset(size.width / 2, size.height * kCarStageOriginY);

        Offset project(Vec3 p) => projectCarPoint(
              point: p,
              yaw: _yaw,
              pitch: _kWebPitch,
              zoom: _kWebZoom,
              origin: origin,
            ).offset;

        return AnimatedBuilder(
          animation: _spin,
          builder: (context, _) {
            return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            widget.onCarTap?.call();
            final hit = hitTestCarHotspot(
              local: details.localPosition,
              size: size,
              yaw: _yaw,
              pitch: _kWebPitch,
              zoom: _kWebZoom,
              hotspots: widget.spots,
            );
            if (hit != null) {
              widget.onSelect(hit);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 860),
                  curve: Curves.easeInOut,
                  offset: Offset(_pulseUp ? 0.0 : 0.006, _pulseUp ? -0.007 : 0.0),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _WebSilhouettePainter(
                        bodyColor: widget.brand.bodyColor,
                        spin: widget.autoRotate ? _spin.value : 0,
                      ),
                    ),
                  ),
                ),
              ),
              for (final spot in widget.spots)
                _WebHotspotDot(
                  center: project(spot.pos),
                  accent: widget.accent,
                  active: spot.id == widget.selectedId || spot.id == _hoveredId,
                  pulseUp: _pulseUp,
                  onTap: () => widget.onSelect(spot),
                  onHover: (hover) {
                    if (_hoveredId != (hover ? spot.id : null)) {
                      setState(() => _hoveredId = hover ? spot.id : null);
                    }
                  },
                ),
              if (widget.selected != null)
                _WebHintBubble(
                  lang: widget.lang,
                  size: size,
                  target: project(widget.selected!.pos),
                  hotspot: widget.selected!,
                  accent: widget.accent,
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }
}

class _WebSilhouettePainter extends CustomPainter {
  const _WebSilhouettePainter({required this.bodyColor, this.spin = 0});

  final Color bodyColor;
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final cx = size.width * 0.5;
    final cy = size.height * 0.62;
    canvas.translate(cx, cy);
    final sway = math.sin(spin * math.pi * 2) * 0.08;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(sway)
      ..scaleByDouble(1.0 - spin.abs() * 0.04, 1.0, 1.0, 1.0);
    canvas.transform(matrix.storage);
    canvas.translate(-cx, -cy);
    final w = size.width * 0.72;
    final h = size.height * 0.22;

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final roof = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - w * 0.04, cy - h * 0.55),
        width: w * 0.48,
        height: h * 0.72,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      roof,
      Paint()..color = bodyColor.withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      roof,
      Paint()
        ..color = const Color(0xFF1A2535).withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );

    for (final dx in [-w * 0.28, w * 0.28]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, cy + h * 0.42), width: h * 0.95, height: h * 0.95),
        Paint()..color = const Color(0xFF111318),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, cy + h * 0.42), width: h * 0.55, height: h * 0.55),
        Paint()..color = const Color(0xFF2A3038),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.44, cy), width: h * 0.35, height: h * 0.35),
      Paint()..color = const Color(0xFF8EC8FF).withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WebSilhouettePainter oldDelegate) =>
      oldDelegate.bodyColor != bodyColor || oldDelegate.spin != spin;
}

class _WebHotspotDot extends StatelessWidget {
  const _WebHotspotDot({
    required this.center,
    required this.accent,
    required this.active,
    required this.pulseUp,
    required this.onTap,
    required this.onHover,
  });

  final Offset center;
  final Color accent;
  final bool active;
  final bool pulseUp;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final baseR = active ? 14.0 : 10.0;
    final r = baseR * (pulseUp ? 1.05 : 0.98);
    return Positioned(
      left: center.dx - r,
      top: center.dy - r,
      width: r * 2,
      height: r * 2,
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 260),
            scale: pulseUp ? 1.04 : 0.98,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                boxShadow: active
                    ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 10)]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: active ? 14 : 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebHintBubble extends StatelessWidget {
  const _WebHintBubble({
    required this.lang,
    required this.size,
    required this.target,
    required this.hotspot,
    required this.accent,
  });

  final AppLang lang;
  final Size size;
  final Offset target;
  final CarHotspot hotspot;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const pad = 8.0;
    final phone = size.width < 700;
    final bubbleW = math.min(phone ? 200.0 : 228.0, math.max(132.0, size.width - pad * 2));
    final bubbleH = phone ? 86.0 : 96.0;
    const gap = 14.0;
    final pinned = Offset(
      target.dx.clamp(pad, math.max(pad, size.width - pad)),
      target.dy.clamp(pad, math.max(pad, size.height - pad)),
    );
    final roomAbove = pinned.dy - pad >= bubbleH + gap;
    final below = !roomAbove;
    var left = pinned.dx - bubbleW / 2;
    var top = below ? pinned.dy + gap : pinned.dy - bubbleH - gap;
    left = left.clamp(pad, math.max(pad, size.width - bubbleW - pad));
    top = top.clamp(pad, math.max(pad, size.height - bubbleH - pad));

    return Positioned(
      left: left,
      top: top,
      width: bubbleW,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: phone ? 10 : 12, vertical: phone ? 8 : 10),
          decoration: BoxDecoration(
            color: const Color(0xEE0C0E14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hotspot.label.of(lang),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: phone ? 12 : 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hotspot.hint.of(lang),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: phone ? 11 : 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: paletteOf(context).muted),
        ),
      ),
    );
  }
}
