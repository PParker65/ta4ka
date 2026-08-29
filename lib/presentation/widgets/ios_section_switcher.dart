import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/performance.dart';

/// Minimal iOS-style tab switcher. Only slide, no scale/shadows for perf.
class IosSectionSwitcher extends StatefulWidget {
  const IosSectionSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.direction = 0,
    this.onDirectionConsumed,
    this.duration = const Duration(milliseconds: 320),
  });

  final int index;
  final List<Widget> children;
  final int direction;
  final VoidCallback? onDirectionConsumed;
  final Duration duration;

  @override
  State<IosSectionSwitcher> createState() => _IosSectionSwitcherState();
}

class _IosSectionSwitcherState extends State<IosSectionSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;
  late int _current;
  int _leaving = 0;
  int _dir = 1;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
    _leaving = widget.index;
    _play = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {});
        }
      });
  }

  @override
  void didUpdateWidget(covariant IosSectionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) {
      return;
    }
    _leaving = oldWidget.index;
    _current = widget.index;
    _dir = widget.direction == 0
        ? (widget.index > oldWidget.index ? 1 : -1)
        : widget.direction.sign;
    if (_dir == 0) _dir = 1;
    widget.onDirectionConsumed?.call();
    _play
      ..duration = widget.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moving = _play.isAnimating;
    final profile = perfProfileOf(context);
    final saver = profile == PerfProfile.saver;

    // Web: instant tab switch — no slide animation, no extra repaints.
    if (kIsWeb) {
      return IndexedStack(
        index: widget.index,
        sizing: StackFit.expand,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            RepaintBoundary(
              child: TickerMode(
                enabled: i == widget.index,
                child: widget.children[i],
              ),
            ),
        ],
      );
    }

    // Mobile: skip slide animation and only mount tabs the user opened.
    // IndexedStack of all 10 shells keeps feed videos + catalogs alive at launch.
    if (saver || !kIsWeb) {
      return _VisitedTabStack(
        index: widget.index,
        children: widget.children,
      );
    }

    if (!moving) {
      return IndexedStack(
        index: _current,
        sizing: StackFit.expand,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            RepaintBoundary(
              child: TickerMode(
                enabled: i == _current,
                child: widget.children[i],
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _play,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_play.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                if (!saver)
                  Transform.translate(
                    offset: Offset(-_dir * width * 0.3 * t, 0),
                    filterQuality: FilterQuality.none,
                    child: RepaintBoundary(child: widget.children[_leaving]),
                  ),
                Transform.translate(
                  offset: Offset(_dir * width * (1 - t), 0),
                  filterQuality: FilterQuality.none,
                  child: RepaintBoundary(child: widget.children[_current]),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VisitedTabStack extends StatefulWidget {
  const _VisitedTabStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_VisitedTabStack> createState() => _VisitedTabStackState();
}

class _VisitedTabStackState extends State<_VisitedTabStack> {
  late final Set<int> _visited = {widget.index};
  final _keys = <int, GlobalKey>{};

  GlobalKey _keyFor(int i) => _keys.putIfAbsent(i, GlobalKey.new);

  @override
  void didUpdateWidget(covariant _VisitedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    _visited.add(widget.index);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_visited.contains(i))
            Offstage(
              offstage: i != widget.index,
              child: TickerMode(
                enabled: i == widget.index,
                child: KeyedSubtree(
                  key: _keyFor(i),
                  child: RepaintBoundary(child: widget.children[i]),
                ),
              ),
            ),
      ],
    );
  }
}
