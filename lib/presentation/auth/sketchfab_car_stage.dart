import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/car_brands.dart';
import '../../data/car_hotspots.dart';
import '../../data/car_layout.dart';
import 'sketchfab_car_stub.dart' if (dart.library.html) 'sketchfab_car_web.dart' as sf;

const kSketchfabCamaroModelId = '2cd3999a0f0444e2a57b5f1aad92e890';

/// Camaro SS — normalized positions for Sketchfab default camera (3/4 front-left).
const _camaroParts = <String, Offset>{
  'engine': Offset(0.54, 0.34),
  'battery': Offset(0.48, 0.36),
  'headlight-r': Offset(0.70, 0.40),
  'headlight-l': Offset(0.64, 0.38),
  'windshield': Offset(0.46, 0.28),
  'roof': Offset(0.40, 0.22),
  'door-r': Offset(0.36, 0.38),
  'door-l': Offset(0.32, 0.40),
  'interior': Offset(0.42, 0.32),
  'wheel-fr': Offset(0.60, 0.56),
  'wheel-fl': Offset(0.55, 0.54),
  'wheel-rr': Offset(0.26, 0.56),
  'wheel-rl': Offset(0.22, 0.54),
  'brake-fr': Offset(0.58, 0.50),
  'exhaust': Offset(0.10, 0.50),
  'rear': Offset(0.16, 0.36),
  'undercarriage': Offset(0.44, 0.60),
  'ac': Offset(0.44, 0.30),
  'steering': Offset(0.41, 0.33),
  'headunit': Offset(0.45, 0.35),
  'seat-l': Offset(0.38, 0.36),
};

Offset _camaroPartAt(String id, Size size) {
  final n = _camaroParts[id];
  if (n == null) return Offset(size.width * 0.5, size.height * 0.5);
  return Offset(n.dx * size.width, n.dy * size.height);
}

/// Sketchfab WebGL viewer — same engine as sketchfab.com, smooth on mobile Safari.
class SketchfabCarStage extends StatelessWidget {
  const SketchfabCarStage({
    super.key,
    required this.lang,
    required this.onSelect,
    required this.hint,
    this.selectedHotspotId,
    this.embedded = false,
    this.accentColor,
    this.brand,
    this.uniquePluses = false,
    this.autoRotate = true,
    this.onCarTap,
    this.modelId = kSketchfabCamaroModelId,
  });

  final AppLang lang;
  final String? selectedHotspotId;
  final String hint;
  final ValueChanged<CarHotspot> onSelect;
  final bool embedded;
  final Color? accentColor;
  final CarBrand? brand;
  final bool uniquePluses;
  final bool autoRotate;
  final VoidCallback? onCarTap;
  final String modelId;

  CarBrand get _brand => brand ?? genericBrand;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final accent = accentColor ?? palette.accent;
    final placed = placedHotspots(_brand);
    // Show every part dot — not collapsed to one per repair sphere.
    final spots = placed;
    CarHotspot? selected;
    for (final h in spots) {
      if (h.id == selectedHotspotId) {
        selected = h;
        break;
      }
    }

    final stage = _SketchfabStageBody(
      lang: lang,
      accent: accent,
      spots: spots,
      selected: selected,
      selectedId: selectedHotspotId,
      onSelect: onSelect,
      onCarTap: onCarTap,
      autoRotate: autoRotate,
      modelId: modelId,
    );

    if (embedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: stage),
          Positioned(
            right: 4,
            bottom: 4,
            child: _MiniIcon(
              icon: CupertinoIcons.arrow_up_left_arrow_down_right,
              onTap: () {},
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
                    Icon(Icons.view_in_ar, color: accent, size: 18),
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

class _SketchfabStageBody extends StatefulWidget {
  const _SketchfabStageBody({
    required this.lang,
    required this.accent,
    required this.spots,
    required this.selected,
    required this.selectedId,
    required this.onSelect,
    this.onCarTap,
    required this.autoRotate,
    required this.modelId,
  });

  final AppLang lang;
  final Color accent;
  final List<CarHotspot> spots;
  final CarHotspot? selected;
  final String? selectedId;
  final ValueChanged<CarHotspot> onSelect;
  final VoidCallback? onCarTap;
  final bool autoRotate;
  final String modelId;

  @override
  State<_SketchfabStageBody> createState() => _SketchfabStageBodyState();
}

class _SketchfabStageBodyState extends State<_SketchfabStageBody> {
  String? _hoveredId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: sf.buildSketchfabViewer(
                modelId: widget.modelId,
                autoSpin: widget.autoRotate,
                fallback: const ColoredBox(
                  color: Color(0xFF08080A),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.2),
                      radius: 1.1,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (final spot in widget.spots)
              _HotspotDot(
                center: _camaroPartAt(spot.id, size),
                accent: widget.accent,
                active: spot.id == widget.selectedId || spot.id == _hoveredId,
                onTap: () {
                  widget.onCarTap?.call();
                  widget.onSelect(spot);
                },
                onHover: (hover) {
                  if (_hoveredId != (hover ? spot.id : null)) {
                    setState(() => _hoveredId = hover ? spot.id : null);
                  }
                },
              ),
            if (widget.selected != null)
              _HintBubble(
                lang: widget.lang,
                size: size,
                target: _camaroPartAt(widget.selected!.id, size),
                hotspot: widget.selected!,
                accent: widget.accent,
              ),
          ],
        );
      },
    );
  }
}

class _HotspotDot extends StatelessWidget {
  const _HotspotDot({
    required this.center,
    required this.accent,
    required this.active,
    required this.onTap,
    required this.onHover,
  });

  final Offset center;
  final Color accent;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final r = active ? 14.0 : 10.0;
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
              child: Icon(Icons.add, size: active ? 14 : 11, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({
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
