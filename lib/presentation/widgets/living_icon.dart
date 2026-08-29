import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Idle heartbeat + float for nav / menu icons. Phase staggers the pack.
class LivingIcon extends StatefulWidget {
  const LivingIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24,
    this.phase = 0,
    this.active = false,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final int phase;
  final bool active;

  @override
  State<LivingIcon> createState() => _LivingIconState();
}

class _LivingIconState extends State<LivingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 920 + widget.phase * 70),
    )..repeat();
    _beat.value = (widget.phase * 0.16) % 1.0;
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _beat,
      builder: (context, child) {
        final t = _beat.value;
        final lub = math.pow(math.sin(t * math.pi * 2).abs(), 0.62).toDouble();
        final dub = math.pow(math.sin(t * math.pi * 2 + 1.08).abs(), 1.42).toDouble();
        final amp = widget.active ? 1.0 : 0.78;
        final scale = 1 + (lub * 0.14 + dub * 0.07) * amp;
        final lift = math.sin(t * math.pi * 2 + widget.phase * 0.85) * (widget.active ? 1.7 : 1.15);
        final tilt = math.sin(t * math.pi * 2 + 0.35) * (widget.active ? 0.06 : 0.04);
        return Transform.translate(
          offset: Offset(0, -lift),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
