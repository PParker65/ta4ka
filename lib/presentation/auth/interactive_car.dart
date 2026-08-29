import 'dart:math' as math;

// The car mesh is built from many Vec3 faces; const noise here hides brand tint logic.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/platform_web.dart';
import '../../app/theme.dart';
import '../../app/performance.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/car_brands.dart';
import '../../data/car_hotspots.dart';
import '../../data/car_layout.dart';
import '../../data/farm_quests.dart';
import 'car_mesh.dart';

class ProjectedPoint {
  const ProjectedPoint(this.offset, this.depth);

  final Offset offset;
  final double depth;
}

ProjectedPoint projectCarPoint({
  required Vec3 point,
  required double yaw,
  required double pitch,
  required double zoom,
  required Offset origin,
}) {
  final rotated = rotateVec3(point, yaw: yaw, pitch: pitch);
  const focal = 320.0;
  final persp = focal / (focal + rotated.z);
  return ProjectedPoint(
    Offset(
      origin.dx + rotated.x * zoom * persp,
      origin.dy - rotated.y * zoom * persp,
    ),
    rotated.z,
  );
}

Vec3 rotateVec3(Vec3 p, {required double yaw, required double pitch}) {
  final cy = math.cos(yaw);
  final sy = math.sin(yaw);
  final cp = math.cos(pitch);
  final sp = math.sin(pitch);
  final x1 = p.x * cy - p.z * sy;
  final z1 = p.x * sy + p.z * cy;
  final y1 = p.y * cp - z1 * sp;
  final z2 = p.y * sp + z1 * cp;
  return Vec3(x1, y1, z2);
}

const kCarStageOriginY = 0.66;

CarHotspot? hitTestCarHotspot({
  required Offset local,
  required Size size,
  required double yaw,
  required double pitch,
  required double zoom,
  List<CarHotspot>? hotspots,
  double hitScale = 1.0,
}) {
  final origin = Offset(size.width / 2, size.height * kCarStageOriginY);
  CarHotspot? best;
  var bestScore = double.infinity;
  for (final hotspot in hotspots ?? carHotspots) {
    final projected = projectCarPoint(
      point: hotspot.pos,
      yaw: yaw,
      pitch: pitch,
      zoom: zoom,
      origin: origin,
    );
    if (projected.depth > 48) {
      continue;
    }
    final dist = (projected.offset - local).distance;
    final radius = (28.0 * zoom * hitScale).clamp(18.0 * hitScale, 42.0 * hitScale);
    if (dist > radius) {
      continue;
    }
    final score = dist + projected.depth * 0.12;
    if (score < bestScore) {
      bestScore = score;
      best = hotspot;
    }
  }
  return best;
}

class InteractiveCar extends StatefulWidget {
  const InteractiveCar({
    super.key,
    required this.lang,
    required this.onSelect,
    required this.hint,
    this.selectedHotspotId,
    this.embedded = false,
    this.accentColor,
    this.bodyColor,
    this.autoRotate = false,
    this.shape = CarShape.sportSedan,
    this.kidneys = false,
    this.engineRear = false,
    this.watermark = '',
    this.brand,
    this.onCarTap,
    this.onSmash,
    this.wreck,
    this.clearedSphereIds = const {},
    this.showSmash = false,
    this.uniquePluses = false,
  });

  final AppLang lang;
  final String? selectedHotspotId;
  final String hint;
  final ValueChanged<CarHotspot> onSelect;
  final bool embedded;
  final Color? accentColor;
  final Color? bodyColor;
  final bool autoRotate;
  final CarShape shape;
  final bool kidneys;
  final bool engineRear;
  final String watermark;
  final CarBrand? brand;
  final VoidCallback? onCarTap;
  final VoidCallback? onSmash;
  final double? wreck;
  final Set<String> clearedSphereIds;
  final bool showSmash;
  final bool uniquePluses;

  @override
  State<InteractiveCar> createState() => _InteractiveCarState();
}

class _InteractiveCarState extends State<InteractiveCar>
    with TickerProviderStateMixin {
  static const _openZoom = 1.445; // 1.7 minus 15% on first appearance / reset
  static const _openPitch = 0.40; // slight low angle, car leans toward the viewer
  static const _openYaw = 2.35;

  double _yaw = _openYaw;
  double _pitch = _openPitch;
  double _zoom = _openZoom;
  double _baseZoom = _openZoom;
  String? _hoveredId;
  late final AnimationController _pulse;
  late final AnimationController _spin;
  late final AnimationController _doorL;
  late final AnimationController _doorR;
  late final AnimationController _wreck;
  int _smashSeed = 1;
  bool _wasWrecked = false;
  List<CarFace> _guts = const [];
  List<CarFace> _body = const [];
  List<CarFace> _lamps = const [];
  int _sceneStamp = 0;
  bool _dragging = false;
  bool _liteMode(BuildContext context) =>
      isMobileWeb(context) || perfProfileOf(context) == PerfProfile.saver;

  CarBrand get _brand {
    final brand = widget.brand ?? genericBrand;
    if (widget.bodyColor == null) {
      return brand;
    }
    return brand.copyWith(bodyColor: widget.bodyColor);
  }

  bool get _doorOpen => _doorL.value > 0.08 || _doorR.value > 0.08;

  double get _viewYaw =>
      _yaw + (widget.autoRotate && !_doorOpen ? -_spin.value * math.pi * 2 : 0);

  double _paintYawFor(bool lite) {
    final y = _viewYaw;
    if (_dragging || !widget.autoRotate || _doorOpen) {
      return y;
    }
    final q = lite ? 70.0 : 110.0;
    return (y * q).round() / q;
  }

  void _ensureScene() {
    final stamp = Object.hash(_brand.id, _brand.bodyColor.toARGB32());
    if (stamp != _sceneStamp) {
      final scene = buildCarScene(brand: _brand, doorL: 0, doorR: 0);
      _guts = [for (final face in scene) if (face.layer <= 0) face];
      _body = [for (final face in scene) if (face.layer == 1) face];
      _lamps = [for (final face in scene) if (face.layer >= 2) face];
      _sceneStamp = stamp;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 40000),
    );
    if (widget.autoRotate) {
      _spin.repeat();
    }
    _doorL = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _doorR = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _doorL.addListener(_onDoorTick);
    _doorR.addListener(_onDoorTick);
    _wreck = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.wreck != null) {
      _wreck.value = widget.wreck!.clamp(0.0, 1.0);
    }
  }

  void _onDoorTick() {
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant InteractiveCar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brand?.id != widget.brand?.id) {
      _doorL.value = 0;
      _doorR.value = 0;
    }
    final target = widget.wreck;
    if (target != null && (oldWidget.wreck != target)) {
      _wreck.animateTo(target.clamp(0.0, 1.0), duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
    _syncSpin();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    _doorL.dispose();
    _doorR.dispose();
    _wreck.dispose();
    super.dispose();
  }

  void _syncSpin() {
    final should = widget.autoRotate && !_doorOpen;
    if (should && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!should && _spin.isAnimating) {
      _spin.stop();
    }
  }

  void _reset() {
    setState(() {
      _yaw = _openYaw;
      _pitch = _openPitch;
      _zoom = _openZoom;
      _baseZoom = _openZoom;
      _hoveredId = null;
    });
    _doorL.reverse();
    _doorR.reverse();
  }

  void _setZoom(double value) {
    setState(() => _zoom = value.clamp(0.7, 3.2));
  }

  void _onTapHotspot(CarHotspot hit) {
    widget.onSelect(hit);
  }

  void _smashCar() {
    HapticFeedback.heavyImpact();
    if (widget.onSmash != null) {
      widget.onSmash!();
      return;
    }
    setState(() {
      _smashSeed += 1;
      _wasWrecked = true;
    });
    _wreck.animateTo(1, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _healFromTap() {
    if (widget.wreck != null) {
      return;
    }
    if (_wreck.value <= 0) {
      return;
    }
    final next = (_wreck.value - 0.034).clamp(0.0, 1.0);
    _wreck.animateTo(next, duration: const Duration(milliseconds: 130), curve: Curves.easeOut);
    if (next > 0 || !_wasWrecked || !mounted) {
      return;
    }
    _wasWrecked = false;
    final s = AppStrings(widget.lang);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(s.smashFixed), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = perfProfileOf(context);
    final saver = profile == PerfProfile.saver;
    final lite = _liteMode(context);
    final palette = paletteOf(context);
    final accent = widget.accentColor ?? palette.accent;
    final placed = placedHotspots(_brand);
    final unique = widget.uniquePluses ? uniqueFarmHotspots(placed) : placed;
    final spots = unique;
    CarHotspot? selected;
    for (final hotspot in unique) {
      if (hotspot.id == widget.selectedHotspotId) {
        selected = hotspot;
        break;
      }
    }
    final stage = _buildStage(
      accent: accent,
      selected: selected,
      spots: spots,
      hitSpots: spots,
      saver: saver,
      liteMode: lite,
    );

    if (widget.embedded) {
      return Stack(
        children: [
          Positioned.fill(child: stage),
          if (widget.showSmash)
            Positioned(
              left: 10,
              bottom: 10,
              child: AnimatedBuilder(
                animation: _wreck,
                builder: (_, __) => _SmashButton(
                  wreck: _wreck.value,
                  lang: widget.lang,
                  onSmash: _smashCar,
                ),
              ),
            ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Row(
              children: [
                _MiniIcon(icon: CupertinoIcons.minus, onTap: () => _setZoom(_zoom - 0.15)),
                _MiniIcon(icon: CupertinoIcons.plus, onTap: () => _setZoom(_zoom + 0.15)),
                _MiniIcon(icon: CupertinoIcons.refresh, onTap: _reset),
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
                    Icon(Icons.threed_rotation, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.hint,
                        style: TextStyle(color: palette.muted, fontSize: 12, height: 1.25),
                      ),
                    ),
                    IconButton(
                      tooltip: '-',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _setZoom(_zoom - 0.15),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    IconButton(
                      tooltip: '+',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _setZoom(_zoom + 0.15),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                    IconButton(
                      tooltip: 'reset',
                      visualDensity: VisualDensity.compact,
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh, size: 18),
                    ),
                  ],
                ),
              ),
              Expanded(child: stage),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _yaw += 0.35),
                      icon: const Icon(Icons.rotate_left, size: 20),
                    ),
                    Expanded(
                      child: Slider(
                        value: _zoom,
                        min: 0.7,
                        max: 3.2,
                        onChanged: _setZoom,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _yaw -= 0.35),
                      icon: const Icon(Icons.rotate_right, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage({
    required Color accent,
    required CarHotspot? selected,
    required List<CarHotspot> spots,
    required List<CarHotspot> hitSpots,
    required bool saver,
    required bool liteMode,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: (event) {
            final hit = hitTestCarHotspot(
              local: event.localPosition,
              size: size,
              yaw: _viewYaw,
              pitch: _pitch,
              zoom: _zoom,
              hotspots: hitSpots,
            );
            final id = hit?.id;
            if (id != _hoveredId) {
              setState(() => _hoveredId = id);
            }
          },
          onExit: (_) {
            if (_hoveredId != null) {
              setState(() => _hoveredId = null);
            }
          },
          child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _setZoom(_zoom + (event.scrollDelta.dy > 0 ? -0.08 : 0.08));
            }
          },
          child: GestureDetector(
            onScaleStart: (_) {
              _dragging = true;
              _baseZoom = _zoom;
            },
            onScaleUpdate: (details) {
              setState(() {
                _yaw -= details.focalPointDelta.dx * 0.012;
                _pitch = (_pitch + details.focalPointDelta.dy * 0.006).clamp(-0.28, 0.55);
                if (details.pointerCount >= 2) {
                  _zoom = (_baseZoom * details.scale).clamp(0.7, 3.2);
                }
              });
            },
            onScaleEnd: (_) => _dragging = false,
            onTapUp: (details) {
              widget.onCarTap?.call();
              _healFromTap();
              final hit = hitTestCarHotspot(
                local: details.localPosition,
                size: size,
                yaw: _viewYaw,
                pitch: _pitch,
                zoom: _zoom,
                hotspots: hitSpots,
              );
              if (hit != null) {
                _onTapHotspot(hit);
              }
            },
            onDoubleTap: _reset,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_spin, _doorL, _doorR, _wreck]),
                    builder: (_, __) {
                      _ensureScene();
                      return CustomPaint(
                        size: size,
                        isComplex: !saver,
                        willChange: widget.autoRotate && !saver,
                        painter: _CarPainter(
                          yaw: _paintYawFor(liteMode),
                          pitch: _pitch,
                          zoom: _zoom,
                          brand: _brand,
                          guts: _guts,
                          body: _body,
                          lamps: _lamps,
                          watermark: widget.watermark,
                          wreck: _wreck.value,
                          smashSeed: _smashSeed,
                          liteMode: saver || liteMode,
                        ),
                      );
                    },
                  ),
                ),
                AnimatedBuilder(
                  animation: saver ? _spin : Listenable.merge([_pulse, _spin]),
                  builder: (_, __) => CustomPaint(
                    size: size,
                    painter: _HotspotPainter(
                      yaw: _viewYaw,
                      pitch: _pitch,
                      zoom: _zoom,
                      pulse: _pulse.value,
                      selectedId: widget.selectedHotspotId,
                      hoveredId: _hoveredId,
                      accent: accent,
                      hotspots: spots,
                      liteMode: saver || liteMode,
                    ),
                  ),
                ),
                if (selected != null)
                  AnimatedBuilder(
                    animation: _spin,
                    builder: (_, __) {
                      final bubbleAt = projectCarPoint(
                        point: selected.pos,
                        yaw: _viewYaw,
                        pitch: _pitch,
                        zoom: _zoom,
                        origin: Offset(size.width / 2, size.height * kCarStageOriginY),
                      ).offset;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: _anchoredHint(
                          size: size,
                          target: bubbleAt,
                          selected: selected,
                          accent: accent,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
  List<Widget> _anchoredHint({
    required Size size,
    required Offset target,
    required CarHotspot selected,
    required Color accent,
  }) {
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
    final roomBelow = size.height - pad - pinned.dy >= bubbleH + gap;
    final below = !roomAbove && roomBelow;
    var left = pinned.dx - bubbleW / 2;
    var top = below ? pinned.dy + gap : pinned.dy - bubbleH - gap;
    left = left.clamp(pad, math.max(pad, size.width - bubbleW - pad));
    top = top.clamp(pad, math.max(pad, size.height - bubbleH - pad));
    final onBubbleX = pinned.dx.clamp(left + 18, left + bubbleW - 18);
    final anchor = Offset(onBubbleX, below ? top : top + bubbleH);
    return [
      CustomPaint(
        size: size,
        painter: _HintLeaderPainter(from: anchor, to: pinned, color: accent),
      ),
      Positioned(
        left: left,
        top: top,
        width: bubbleW,
        child: IgnorePointer(
          child: _HintBubble(
            title: selected.label.of(widget.lang),
            hint: selected.hint.of(widget.lang),
            accent: accent,
            compact: phone,
          ),
        ),
      ),
    ];
  }
}

class _SmashButton extends StatelessWidget {
  const _SmashButton({
    required this.wreck,
    required this.lang,
    required this.onSmash,
  });

  final double wreck;
  final AppLang lang;
  final VoidCallback onSmash;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(lang);
    final palette = paletteOf(context);
    final wrecked = wreck > 0.04;
    final label = wrecked
        ? s.smashRepair(((1 - wreck) * 100).round().clamp(0, 99))
        : s.smashCar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSmash,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: wrecked ? palette.danger : palette.stroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                wrecked ? CupertinoIcons.hammer : CupertinoIcons.burst,
                size: 18,
                color: wrecked ? palette.danger : palette.text,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.2,
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
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFF86868B)),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.title,
    required this.hint,
    required this.accent,
    this.compact = false,
  });

  final String title;
  final String hint;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 12, compact ? 8 : 10, compact ? 10 : 12, compact ? 8 : 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 16,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            hint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w500,
              fontSize: compact ? 12 : 15,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintLeaderPainter extends CustomPainter {
  _HintLeaderPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if ((from - to).distance < 6) {
      return;
    }
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(to, 3.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HintLeaderPainter oldDelegate) {
    return oldDelegate.from != from || oldDelegate.to != to || oldDelegate.color != color;
  }
}

class _HotspotPainter extends CustomPainter {
  _HotspotPainter({
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.pulse,
    required this.selectedId,
    required this.hoveredId,
    required this.accent,
    required this.hotspots,
    required this.liteMode,
  });

  final double yaw;
  final double pitch;
  final double zoom;
  final double pulse;
  final String? selectedId;
  final String? hoveredId;
  final Color accent;
  final List<CarHotspot> hotspots;
  final bool liteMode;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * kCarStageOriginY);
    for (final hotspot in hotspots) {
      final projected = projectCarPoint(
        point: hotspot.pos,
        yaw: yaw,
        pitch: pitch,
        zoom: zoom,
        origin: origin,
      );
      if (projected.depth > 58) {
        continue;
      }
      final selected = hotspot.id == selectedId;
      final hovered = hotspot.id == hoveredId;
      final active = selected || hovered;
      final r = (active ? (liteMode ? 10.0 : 12.0 + pulse * 2.2) : 7.0) * zoom.clamp(0.85, 1.3);
      canvas.drawCircle(projected.offset, r, Paint()..color = accent);
      final plus = Paint()
        ..color = Colors.white
        ..strokeWidth = active ? 2.2 : 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        projected.offset.translate(-r * 0.35, 0),
        projected.offset.translate(r * 0.35, 0),
        plus,
      );
      canvas.drawLine(
        projected.offset.translate(0, -r * 0.35),
        projected.offset.translate(0, r * 0.35),
        plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HotspotPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pulse != pulse ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.hoveredId != hoveredId ||
        oldDelegate.accent != accent ||
        oldDelegate.liteMode != liteMode;
  }
}

class _Cam {
  _Cam({
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.origin,
  })  : cy = math.cos(yaw),
        sy = math.sin(yaw),
        cp = math.cos(pitch),
        sp = math.sin(pitch);

  final double yaw;
  final double pitch;
  final double zoom;
  final Offset origin;
  final double cy;
  final double sy;
  final double cp;
  final double sp;

  Vec3 rot(Vec3 p) {
    final x1 = p.x * cy - p.z * sy;
    final z1 = p.x * sy + p.z * cy;
    final y1 = p.y * cp - z1 * sp;
    return Vec3(x1, y1, p.y * sp + z1 * cp);
  }

  double zOf(Vec3 p) {
    final z1 = p.x * sy + p.z * cy;
    return p.y * sp + z1 * cp;
  }

  Offset map(Vec3 p) {
    final r = rot(p);
    final persp = 320.0 / (320.0 + r.z);
    return Offset(origin.dx + r.x * zoom * persp, origin.dy - r.y * zoom * persp);
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter({
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.brand,
    required this.guts,
    required this.body,
    required this.lamps,
    required this.watermark,
    this.wreck = 0,
    this.smashSeed = 1,
    this.liteMode = false,
  });

  final double yaw;
  final double pitch;
  final double zoom;
  final CarBrand brand;
  final List<CarFace> guts;
  final List<CarFace> body;
  final List<CarFace> lamps;
  final String watermark;
  final double wreck;
  final int smashSeed;
  final bool liteMode;

  @override
  void paint(Canvas canvas, Size size) {
    final cam = _Cam(
      yaw: yaw,
      pitch: pitch,
      zoom: zoom,
      origin: Offset(size.width / 2, size.height * kCarStageOriginY),
    );
    Offset map(Vec3 p) => cam.map(_dent(p));

    final layout = CarLayout.of(brand);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(map(const Vec3(0, 0, 0)).dx, cam.origin.dy + 36 * zoom),
        width: (layout.front - layout.rear) * 0.92 * zoom,
        height: 28 * zoom,
      ),
      Paint()..color = const Color(0x14000000),
    );

    void paintLayer(List<CarFace> faces) {
      faces.sort((a, b) => cam.zOf(b.points.first).compareTo(cam.zOf(a.points.first)));
      for (final face in faces) {
        _drawFace(canvas, face, map);
      }
    }

    paintLayer(guts);
    paintLayer(body);
    paintLayer(lamps);

    final wheels = sedanWheelCenters(layout)
      ..sort((a, b) => cam.zOf(b).compareTo(cam.zOf(a)));
    for (var i = 0; i < wheels.length; i++) {
      final flat = wreck > 0.22 && i == 0;
      _drawWheel(canvas, map(wheels[i]), yaw, zoom, flat: flat, liteMode: liteMode);
    }

    if (wreck > 0.08) {
      _drawDamage(canvas, layout, map);
    }
  }

  Vec3 _dent(Vec3 p) {
    if (wreck < 0.02) {
      return p;
    }
    final s = smashSeed.toDouble();
    final n = math.sin(p.x * 0.31 + p.z * 0.17 + s) * math.cos(p.y * 0.13 + s * 0.4);
    final crush = wreck * wreck;
    return Vec3(
      p.x + n * 2.6 * wreck,
      p.y - (n.abs() * 3.1 + (p.y > 28 ? 1.8 : 0)) * crush,
      p.z + math.sin(p.x * 0.09 + s) * 4.4 * wreck,
    );
  }

  void _drawFace(Canvas canvas, CarFace face, Offset Function(Vec3) map) {
    if (face.points.length < 2) {
      return;
    }
    if (face.points.length == 2) {
      if (face.stroke != null) {
        canvas.drawLine(
          map(face.points[0]),
          map(face.points[1]),
          Paint()
            ..color = face.stroke!
            ..strokeWidth = face.strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }
    final path = Path();
    for (var i = 0; i < face.points.length; i++) {
      final p = map(face.points[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final fill = _weathered(face.fill, emissive: face.emissive);
    if (fill.a > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
    }
    if (face.stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(face.stroke!, const Color(0xFF4A3A30), wreck * 0.45)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = face.emissive ? 1.6 : face.strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  Color _weathered(Color color, {required bool emissive}) {
    if (wreck < 0.02 || color.a == 0) {
      return color;
    }
    if (emissive) {
      return Color.lerp(color, const Color(0xFF1A140E), (wreck - 0.15).clamp(0.0, 1.0))!;
    }
    return Color.lerp(color, const Color(0xFF3B3228), wreck * 0.62)!;
  }

  void _drawDamage(Canvas canvas, CarLayout layout, Offset Function(Vec3) map) {
    final scratch = Paint()
      ..color = const Color(0xAA1A1A1A).withValues(alpha: 0.35 + wreck * 0.45)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rust = Paint()
      ..color = const Color(0x886B3A1F).withValues(alpha: wreck * 0.55)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 7; i++) {
      final t = 0.18 + i * 0.09;
      final x = layout.rear + (layout.front - layout.rear) * t;
      final y = 22.0 + (i.isEven ? 6 : 0);
      final z = layout.halfW * (i.isOdd ? 0.92 : -0.92);
      final a = map(Vec3(x - 4, y + 2, z));
      final b = map(Vec3(x + 8, y - 3 - wreck * 4, z * 0.98));
      final c = map(Vec3(x + 2, y + 5, z));
      canvas.drawLine(a, b, scratch);
      if (wreck > 0.35) {
        canvas.drawCircle(c, 3.4 * zoom * wreck, rust);
      }
    }

    final crack = Paint()
      ..color = const Color(0xCCE8F6FF).withValues(alpha: 0.25 + wreck * 0.5)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final midX = (layout.cabinF + layout.cabinR) / 2;
    final glass = [
      map(Vec3(midX, layout.roof - 2, 0)),
      map(Vec3(midX + 10, layout.belt + 4, layout.halfW * 0.4)),
      map(Vec3(midX - 8, layout.belt + 6, -layout.halfW * 0.2)),
      map(Vec3(midX + 4, layout.roof - 6, -layout.halfW * 0.35)),
    ];
    if (wreck > 0.18) {
      canvas.drawLine(glass[0], glass[1], crack);
      canvas.drawLine(glass[0], glass[2], crack);
      canvas.drawLine(glass[1], glass[3], crack);
    }

    if (wreck > 0.4) {
      final engine = map(Vec3(layout.engineX, 34, 0));
      for (var i = 0; i < 5; i++) {
        final drift = (wreck * 12 + i * 7) % 18;
        canvas.drawOval(
          Rect.fromCenter(
            center: engine.translate((i - 2) * 6.0 * zoom, -drift * zoom),
            width: (10 - i) * zoom * wreck,
            height: (14 - i) * zoom * wreck,
          ),
          Paint()..color = Color(0x55AAAAAA).withValues(alpha: 0.12 + wreck * 0.18 - i * 0.02),
        );
      }
    }
  }

  void _drawWheel(Canvas canvas, Offset c, double yaw, double zoom, {required bool flat, required bool liteMode}) {
    final squeeze = (0.32 + 0.68 * math.cos(yaw).abs()).clamp(0.36, 1.0);
    final drop = flat ? wreck * 7 * zoom : 0.0;
    final rx = 23.0 * zoom * squeeze;
    final ry = 24.0 * zoom * (flat ? 1 - wreck * 0.52 : 1);
    final center = c.translate(0, drop);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2.08, height: ry * 2.08),
      Paint()..color = const Color(0xFF0A0A0A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.72, height: ry * 1.72),
      Paint()..color = const Color(0xFF1C1C1E),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.22, height: ry * 1.22),
      Paint()..color = const Color(0xFF9AA0A6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 0.52, height: ry * 0.52),
      Paint()..color = const Color(0xFF6A7076),
    );
    final spoke = Paint()
      ..color = const Color(0xFFD8DCE2)
      ..strokeWidth = 3.1 * zoom.clamp(0.8, 1.4)
      ..strokeCap = StrokeCap.round;
    final spokes = liteMode ? 4 : 5;
    for (var i = 0; i < spokes; i++) {
      final a = yaw + i * math.pi * 2 / spokes;
      canvas.drawLine(
        Offset(center.dx + math.cos(a) * rx * 0.16, center.dy + math.sin(a) * ry * 0.16),
        Offset(center.dx + math.cos(a) * rx * 0.82, center.dy + math.sin(a) * ry * 0.82),
        spoke,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.58, height: ry * 1.58),
      Paint()
        ..color = const Color(0xFFC8CCD2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(center, 3.2 * zoom, Paint()..color = const Color(0xFF2A2A2E));
    final cal = Offset(
      center.dx + math.cos(yaw + 0.9) * rx * 0.55,
      center.dy + math.sin(yaw + 0.9) * ry * 0.55,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: cal, width: 7.5 * zoom, height: 11 * zoom),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFB01828),
    );
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.brand.id != brand.id ||
        oldDelegate.watermark != watermark ||
        oldDelegate.wreck != wreck ||
        oldDelegate.smashSeed != smashSeed ||
        oldDelegate.liteMode != liteMode ||
        !identical(oldDelegate.guts, guts) ||
        !identical(oldDelegate.body, body) ||
        !identical(oldDelegate.lamps, lamps);
  }
}
