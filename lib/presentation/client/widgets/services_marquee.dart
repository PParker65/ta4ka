import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One-line looping ticker of shop services. Scrolls in whole pixels so
/// type stays sharp — no scale / blur transforms on the glyphs.
class ServicesMarquee extends StatefulWidget {
  const ServicesMarquee({
    super.key,
    required this.items,
    required this.style,
  });

  final List<String> items;
  final TextStyle style;

  @override
  State<ServicesMarquee> createState() => _ServicesMarqueeState();
}

class _ServicesMarqueeState extends State<ServicesMarquee>
    with SingleTickerProviderStateMixin {
  /// Target ~3.8 s per item, then clamp into a readable 42–58 px/s band.
  static const _secPerItem = 3.8;
  static const _minPxPerSec = 42.0;
  static const _maxPxPerSec = 58.0;
  static const _sep = '  ·  ';

  late final AnimationController _play;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ServicesMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.join('\u0001') != widget.items.join('\u0001')) {
      _play.value = 0;
    }
  }

  void _arm(double loopWidth, int count) {
    if (loopWidth <= 0 || count <= 0) return;
    var pxPerSec = loopWidth / (count * _secPerItem);
    pxPerSec = pxPerSec.clamp(_minPxPerSec, _maxPxPerSec);
    final ms = (loopWidth / pxPerSec * 1000).round().clamp(4000, 180000);
    final next = Duration(milliseconds: ms);
    if (_play.duration != next) {
      _play.duration = next;
    }
    if (!_play.isAnimating) {
      _play.repeat();
    }
  }

  double _stripWidth(TextDirection direction) {
    final style = widget.style;
    var width = 0.0;
    for (final item in widget.items) {
      width += _paint(item, style, direction);
      width += _paint(_sep, style, direction);
    }
    return width;
  }

  double _paint(String text, TextStyle style, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  Widget _strip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in widget.items) ...[
          Text(item, style: widget.style, maxLines: 1, softWrap: false),
          Text(_sep, style: widget.style, maxLines: 1, softWrap: false),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final fontSize = widget.style.fontSize ?? 12;
    final lineHeight = fontSize * (widget.style.height ?? 1.3);
    final boxH = lineHeight + 2;
    final direction = Directionality.of(context);

    return SizedBox(
      height: boxH,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
          final contentW = _stripWidth(direction);
          if (contentW <= 0 || viewport <= 0) {
            return const SizedBox.shrink();
          }
          final loopW = math.max(contentW, viewport) + 24;
          final pad = loopW - contentW;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _arm(loopW, widget.items.length);
          });

          return RepaintBoundary(
            child: ExcludeSemantics(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) {
                  return const LinearGradient(
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0xFFFFFFFF),
                      Color(0xFFFFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.0, 0.06, 0.94, 1.0],
                  ).createShader(rect);
                },
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _play,
                    builder: (context, child) {
                      final dx = (loopW * _play.value).floorToDouble();
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: -dx,
                            top: 0,
                            height: boxH,
                            child: child!,
                          ),
                        ],
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _strip(),
                        SizedBox(width: pad),
                        _strip(),
                        SizedBox(width: pad),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
