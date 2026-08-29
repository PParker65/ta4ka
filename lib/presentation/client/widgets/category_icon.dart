import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/auto_spheres.dart';
import '../../auth/brand_part_thumb.dart';

/// Scroll focus 0…1 — icon grows up to [maxFocusScale] near viewport center.
class CategoryIconBadge extends StatefulWidget {
  const CategoryIconBadge({
    super.key,
    required this.sphere,
    this.size = 34,
    this.iconSize = 18,
    this.radius = 10,
    this.animate = true,
    this.hero = false,
    this.focus = 0,
    this.maxFocusScale = 3,
  });

  final AutoSphere sphere;
  final double size;
  final double iconSize;
  final double radius;
  final bool animate;
  final bool hero;
  final double focus;
  final double maxFocusScale;

  @override
  State<CategoryIconBadge> createState() => _CategoryIconBadgeState();
}

class _CategoryIconBadgeState extends State<CategoryIconBadge>
    with TickerProviderStateMixin {
  late final AnimationController _play;
  late final AnimationController _heart;
  late Animation<double> _scale;
  late Animation<double> _glow;
  late Animation<double> _tilt;
  double _lastFocus = 0;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.hero ? 900 : 2200),
    );
    _heart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _bindIdleMotion();
    if (widget.animate) {
      _heart.repeat();
      if (widget.hero) {
        _play.forward();
      } else if (widget.focus <= 0.02) {
        _play.repeat(reverse: true);
      }
    } else {
      _play.value = 1;
    }
  }

  void _bindIdleMotion() {
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.06), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 65),
    ]).animate(CurvedAnimation(parent: _play, curve: Curves.easeOutCubic));
    _glow = Tween<double>(begin: 0.18, end: 0.55).animate(
      CurvedAnimation(parent: _play, curve: Curves.easeInOut),
    );
    _tilt = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _play, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant CategoryIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focus.clamp(0.0, 1.0);
    if (focus > _lastFocus + 0.04) {
      _heart.stop();
      _heart.value = 0;
      if (!widget.hero && widget.animate && focus > 0.08) {
        _play.stop();
      }
    } else if (focus < _lastFocus - 0.03 && focus < 0.5) {
      if (!_heart.isAnimating) {
        _heart.repeat();
      }
    } else if (focus > 0.48) {
      _heart.stop();
      _heart.value = 0;
    }
    if (focus <= 0.02 && oldWidget.focus > 0.05 && !widget.hero && widget.animate) {
      _play.repeat(reverse: true);
    }
    _lastFocus = focus;

    if (widget.hero != oldWidget.hero || widget.animate != oldWidget.animate) {
      _play
        ..duration = Duration(milliseconds: widget.hero ? 900 : 2200)
        ..reset();
      if (widget.animate) {
        widget.hero ? _play.forward() : _play.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _play.dispose();
    _heart.dispose();
    super.dispose();
  }

  double _heartPulse() {
    if (widget.focus >= 0.42) {
      return 1;
    }
    final t = _heart.value;
    // Lub-dub: strong first beat, softer second — fades as focus grows.
    final fade = (1 - widget.focus / 0.42).clamp(0.0, 1.0);
    final lub = math.pow(math.sin(t * math.pi * 2).abs(), 0.65).toDouble();
    final dub = math.pow(math.sin(t * math.pi * 2 + 1.1).abs(), 1.4).toDouble();
    return 1 + (lub * 0.22 + dub * 0.12) * fade;
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final focus = widget.focus.clamp(0.0, 1.0);
    final focusT = Curves.easeOutBack.transform(focus);
    final focusScale = 1 + focusT * (widget.maxFocusScale - 1);
    final idleScale = widget.animate && !widget.hero && focus < 0.06 ? _scale.value : 1.0;
    final heroScale = widget.hero && widget.animate ? _scale.value : 1.0;
    final pulse = _heartPulse();
    final totalScale = focusScale * idleScale * heroScale * pulse;
    final alignX = -1 + focus * 1.15;
    final alignY = -1 + focus * 0.85;
    final glowAlpha = 0.22 + focus * 0.55 + (widget.animate ? _glow.value * 0.25 : 0);

    return AnimatedBuilder(
      animation: Listenable.merge([_play, _heart]),
      builder: (context, child) {
        return Transform.scale(
          scale: totalScale,
          alignment: Alignment(alignX.clamp(-1.0, 1.0), alignY.clamp(-1.0, 1.0)),
          child: Transform.rotate(
            angle: widget.hero || focus > 0.2 ? 0 : _tilt.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius + focus * 6),
                color: widget.sphere.color.withValues(alpha: 0.92),
                boxShadow: [
                  BoxShadow(
                    color: widget.sphere.color.withValues(alpha: glowAlpha),
                    blurRadius: 12 + focus * 28,
                    spreadRadius: focus * 4,
                  ),
                  if (focus > 0.15)
                    BoxShadow(
                      color: widget.sphere.color.withValues(alpha: focus * 0.35),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  if (palette.isDark)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05 + focus * 0.08),
                      blurRadius: 8,
                    ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Icon(
        widget.sphere.icon,
        color: Colors.white,
        size: widget.iconSize * (1 + focus * 0.35),
      ),
    );
  }
}

/// Staggered fade/slide for category grid cards.
class CategoryGridEntrance extends StatelessWidget {
  const CategoryGridEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + (index % 6) * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: Transform.scale(
              scale: 0.94 + value * 0.06,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Category grid card — colored icon stays put, no scroll-zoom (that washed icons white).
class CategoryFocusCard extends StatelessWidget {
  const CategoryFocusCard({
    super.key,
    required this.sphere,
    required this.lang,
    required this.onTap,
    this.suggested = false,
    this.suggestedLabel = '',
  });

  final AutoSphere sphere;
  final AppLang lang;
  final VoidCallback onTap;
  final bool suggested;
  final String suggestedLabel;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: suggested ? palette.accent : palette.stroke,
              width: suggested ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          1.16, -0.04, -0.04, 0, 10,
                          -0.04, 1.16, -0.04, 0, 10,
                          -0.04, -0.04, 1.16, 0, 10,
                          0, 0, 0, 1, 0,
                        ]),
                        child: Image.asset(
                          sphere.imageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          cacheWidth: 480,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: sphere.color.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: PartAccentPainter(
                          sphereId: sphere.id,
                          brandColor: sphere.color,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              palette.bg.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      if (suggested && suggestedLabel.isNotEmpty)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: palette.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              suggestedLabel,
                              style: TextStyle(
                                color: palette.onAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sphere.title.of(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: palette.text,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sphere.priceHint.of(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
