import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'device_perf_stub.dart' if (dart.library.io) 'device_perf_io.dart' as device_perf;

enum PerfProfile { smooth, balanced, saver }

class PerfProfileScope extends StatefulWidget {
  const PerfProfileScope({super.key, required this.child});

  final Widget child;

  static ValueNotifier<PerfProfile>? maybeListenableOf(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_PerfInherited>();
    return inherited?.notifier;
  }

  static PerfProfile of(BuildContext context) {
    return maybeListenableOf(context)?.value ?? PerfProfile.balanced;
  }

  @override
  State<PerfProfileScope> createState() => _PerfProfileScopeState();
}

class _PerfProfileScopeState extends State<PerfProfileScope> {
  final ValueNotifier<PerfProfile> _profile = ValueNotifier<PerfProfile>(
    kIsWeb ? PerfProfile.saver : device_perf.bootstrapPerfProfile(),
  );
  final Queue<bool> _slowFrames = Queue<bool>();
  VoidCallback? _removeTimings;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    }
    void callback(List<FrameTiming> timings) {
      final fps = _refreshRate();
      final budgetMs = (1000.0 / fps).clamp(8.0, 20.0);
      for (final t in timings) {
        final buildMs = t.buildDuration.inMicroseconds / 1000.0;
        final rasterMs = t.rasterDuration.inMicroseconds / 1000.0;
        final slow = buildMs + rasterMs > budgetMs * 1.1;
        _slowFrames.addLast(slow);
        if (_slowFrames.length > 120) {
          _slowFrames.removeFirst();
        }
      }
      _recomputeProfile();
    }
    SchedulerBinding.instance.addTimingsCallback(callback);
    _removeTimings = () => SchedulerBinding.instance.removeTimingsCallback(callback);
  }

  @override
  void dispose() {
    _removeTimings?.call();
    _profile.dispose();
    super.dispose();
  }

  double _refreshRate() {
    final view = PlatformDispatcher.instance.implicitView;
    final rate = view?.display.refreshRate ?? 60.0;
    if (rate <= 0) {
      return 60.0;
    }
    return rate;
  }

  void _recomputeProfile() {
    if (_slowFrames.length < 24) {
      return;
    }
    final slowCount = _slowFrames.where((e) => e).length;
    final ratio = slowCount / _slowFrames.length;
    var next = ratio > 0.34
        ? PerfProfile.saver
        : (ratio > 0.16 ? PerfProfile.balanced : PerfProfile.smooth);
    // Mobile: never escalate above balanced — WebGL + GLB already heavy.
    if (!kIsWeb && next == PerfProfile.smooth) {
      next = PerfProfile.balanced;
    }
    if (_profile.value != next) {
      _profile.value = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PerfInherited(notifier: _profile, child: widget.child);
  }
}

class _PerfInherited extends InheritedNotifier<ValueNotifier<PerfProfile>> {
  const _PerfInherited({
    required super.notifier,
    required super.child,
  });
}

PerfProfile perfProfileOf(BuildContext context) => PerfProfileScope.of(context);
