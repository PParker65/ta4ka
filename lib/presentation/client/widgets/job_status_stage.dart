import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/shop_seed.dart';
import '../../../domain/models/crm_models.dart';
import '../../workshop/shop_jobs.dart';

enum JobWorkCraft {
  general,
  chassis,
  engine,
  electrical,
  wash,
  tires,
  body,
  diagnostics,
}

/// Looping process scene for a booking — same visual language as the USA map.
class JobStatusStage extends ConsumerStatefulWidget {
  const JobStatusStage({
    super.key,
    required this.order,
    required this.label,
    this.compact = false,
  });

  final WorkOrder order;
  final String label;
  final bool compact;

  @override
  ConsumerState<JobStatusStage> createState() => _JobStatusStageState();
}

class _JobStatusStageState extends ConsumerState<JobStatusStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  String _shopTitle() {
    final lang = ref.read(localeProvider);
    return shopById(widget.order.shopId)?.name.of(lang) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final phase = shopJobPhase(widget.order);
    final accent = switch (phase) {
      ShopJobPhase.waiting => const Color(0xFFE67E22),
      ShopJobPhase.working => const Color(0xFF27AE60),
      ShopJobPhase.ready => const Color(0xFF2ECC71),
    };
    final height = widget.compact ? 124.0 : 196.0;
    final craft = craftForOrder(widget.order);
    final shopName = _shopTitle();

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.compact ? 16 : 20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: ColoredBox(
                color: const Color(0xFF061018),
                child: AnimatedBuilder(
                  animation: _play,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _JobStagePainter(
                        t: _play.value,
                        phase: phase,
                        craft: craft,
                        accent: accent,
                        compact: widget.compact,
                        shopName: shopName,
                        waitingTag: s.jobSceneWaiting,
                        workingTag: s.jobSceneInBay,
                        readyTag: s.jobSceneReady,
                        plate: widget.order.plate,
                      ),
                    );
                  },
                ),
              ),
            ),
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
              child: AnimatedBuilder(
                animation: _play,
                builder: (context, _) {
                  final waiting = phase == ShopJobPhase.waiting;
                  final pulse = waiting ? 0.72 + 0.28 * (0.5 + 0.5 * math.sin(_play.value * math.pi * 2)) : 1.0;
                  final dots = waiting ? '.' * (1 + (_play.value * 3).floor() % 3) : '';
                  return Opacity(
                    opacity: pulse,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35 + 0.45 * pulse),
                                blurRadius: 8 + 6 * pulse,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.label.toUpperCase()}$dots',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

JobWorkCraft craftForOrder(WorkOrder order) {
  final ids = [
    for (final line in order.confirmedLines) line.workId,
    if (order.confirmedLines.isEmpty)
      for (final line in order.lines) line.workId,
  ];
  final score = <JobWorkCraft, int>{};
  void hit(JobWorkCraft craft) => score[craft] = (score[craft] ?? 0) + 1;

  bool has(String id, List<String> keys) {
    for (final key in keys) {
      if (id.contains(key)) return true;
    }
    return false;
  }

  for (final id in ids) {
    if (has(id, const ['wash', 'detail', 'ppf'])) {
      hit(JobWorkCraft.wash);
    } else if (has(id, const ['tire', 'rim', 'align'])) {
      hit(JobWorkCraft.tires);
    } else if (has(id, const [
      'coding',
      'battery',
      'wiring',
      'alarm',
      'keys',
      'android',
      'srs',
      'adas',
      'lights',
      'starter',
    ])) {
      hit(JobWorkCraft.electrical);
    } else if (has(id, const [
      'engine',
      'oil',
      'turbo',
      'plugs',
      'coolant',
      'gearbox',
      'clutch',
      'inject',
      'radiator',
      'dpf',
      'lpg',
      'timing',
    ])) {
      hit(JobWorkCraft.engine);
    } else if (has(id, const [
      'pads',
      'disc',
      'brake',
      'chassis',
      'steering',
      'cv-joint',
      'air-suspension',
    ])) {
      hit(JobWorkCraft.chassis);
    } else if (has(id, const ['paint', 'body', 'wrap', 'carbon', 'hydro', 'anticor'])) {
      hit(JobWorkCraft.body);
    } else if (has(id, const ['diag', 'prebuy', 'insurance'])) {
      hit(JobWorkCraft.diagnostics);
    } else {
      hit(JobWorkCraft.general);
    }
  }

  if (score.isEmpty) {
    return switch (order.category) {
      RepairCategory.chassis => JobWorkCraft.chassis,
      RepairCategory.electrical => JobWorkCraft.electrical,
      RepairCategory.engine => JobWorkCraft.engine,
      RepairCategory.diagnostics => JobWorkCraft.diagnostics,
      RepairCategory.maintenance => JobWorkCraft.engine,
    };
  }
  return score.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

class _JobStagePainter extends CustomPainter {
  _JobStagePainter({
    required this.t,
    required this.phase,
    required this.craft,
    required this.accent,
    required this.compact,
    required this.shopName,
    required this.waitingTag,
    required this.workingTag,
    required this.readyTag,
    required this.plate,
  });

  final double t;
  final ShopJobPhase phase;
  final JobWorkCraft craft;
  final Color accent;
  final bool compact;
  final String shopName;
  final String waitingTag;
  final String workingTag;
  final String readyTag;
  final String plate;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          const [Color(0xFF0B2233), Color(0xFF07141F), Color(0xFF040A10)],
          const [0.0, 0.55, 1.0],
        ),
    );
    _grid(canvas, size);
    switch (phase) {
      case ShopJobPhase.waiting:
        _waiting(canvas, size);
      case ShopJobPhase.working:
        _working(canvas, size);
      case ShopJobPhase.ready:
        _ready(canvas, size);
    }
  }

  void _grid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x14A8D4EE)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  void _floor(Canvas canvas, Size size, {double y = 0.78}) {
    final gy = size.height * y;
    canvas.drawLine(
      Offset(0, gy),
      Offset(size.width, gy),
      Paint()
        ..color = const Color(0x3348A0C8)
        ..strokeWidth = 1.2,
    );
    final dash = Paint()
      ..color = const Color(0x22A8D4EE)
      ..strokeWidth = 1;
    for (var x = 8.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, gy + 7), Offset(x + 9, gy + 7), dash);
    }
  }

  void _shop(Canvas canvas, Size size, {required double door}) {
    final w = size.width;
    final h = size.height;
    final building = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.40, h * 0.60),
      const Radius.circular(6),
    );
    canvas.drawRRect(building, Paint()..color = const Color(0xFF15202C));
    canvas.drawRRect(
      building,
      Paint()
        ..color = const Color(0xFF5A7A98)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    if (shopName.isNotEmpty) {
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.60, h * 0.195, w * 0.36, compact ? 15 : 18),
        const Radius.circular(3),
      );
      canvas.drawRRect(bar, Paint()..color = const Color(0xFF0D141C));
      _fitText(
        canvas,
        shopName.toUpperCase(),
        Offset(w * 0.78, h * 0.195 + (compact ? 7.5 : 9)),
        const Color(0xFFE8E8ED),
        maxWidth: w * 0.34,
        size: compact ? 7 : 8,
        weight: FontWeight.w800,
        tracking: 0.4,
        maxLines: 1,
      );
    }
    final open = door.clamp(0.0, 1.0);
    final bay = Rect.fromLTWH(w * 0.64, h * 0.32, w * 0.28, h * 0.46);
    canvas.drawRect(bay, Paint()..color = const Color(0xFF0A1218));
    canvas.drawRect(
      Rect.fromLTWH(bay.left, bay.top, bay.width, bay.height * (1 - open)),
      Paint()..color = const Color(0xFF2A3544),
    );
  }

  void _car(Canvas canvas, Offset p, {double scale = 1, double angle = 0, Color? stroke}) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 11), width: 36, height: 7),
      Paint()..color = const Color(0x66000000),
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 40, height: 13),
      const Radius.circular(3.2),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2F2F6));
    canvas.drawRRect(
      body,
      Paint()
        ..color = stroke ?? accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(2, -8), width: 20, height: 9),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF2A3340),
    );
    canvas.drawCircle(const Offset(-12, 8), 3.4, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(const Offset(12, 8), 3.4, Paint()..color = const Color(0xFF111114));
    canvas.drawCircle(const Offset(18, 0), 1.6, Paint()..color = const Color(0xFFFFD54A));
    canvas.restore();
  }

  void _waiting(Canvas canvas, Size size) {
    _floor(canvas, size);
    _shop(canvas, size, door: 0.22 + 0.06 * math.sin(t * math.pi * 2));
    _queue(canvas, size);
    _cone(canvas, Offset(size.width * 0.42, size.height * 0.72));
    final travel = t < 0.72 ? Curves.easeInOutCubic.transform(t / 0.72) : 1.0;
    final x = size.width * (0.08 + travel * 0.50);
    final idle = travel >= 1;
    final bounce = idle ? math.sin(t * math.pi * 8) * 0.4 : 0.0;
    _car(canvas, Offset(x, size.height * 0.70 + bounce), scale: 1.15);
    if (idle) {
      _exhaust(canvas, Offset(x - 26, size.height * 0.70));
    }
    _waitSign(canvas, Offset(size.width * 0.30, size.height * 0.38));
    if (plate.isNotEmpty) {
      _fitText(canvas, plate.toUpperCase(), Offset(x, size.height * 0.82), const Color(0xFF9BB0C4), size: 8);
    }
  }

  void _queue(Canvas canvas, Size size) {
    final p = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final gy = size.height * 0.78;
    var draw = true;
    for (var x = size.width * 0.06; x < size.width * 0.56; x += 10) {
      if (draw) {
        canvas.drawLine(Offset(x, gy - 10), Offset(x + 6, gy - 10), p);
      }
      draw = !draw;
    }
    final head = size.width * (0.10 + ((t * 0.55) % 0.42));
    canvas.drawLine(
      Offset(head, gy - 14),
      Offset(head + 10, gy - 10),
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _cone(Canvas canvas, Offset p) {
    final path = Path()
      ..moveTo(p.dx, p.dy - 16)
      ..lineTo(p.dx + 7, p.dy + 4)
      ..lineTo(p.dx - 7, p.dy + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = accent);
    canvas.drawRect(
      Rect.fromCenter(center: p + const Offset(0, -4), width: 10, height: 3),
      Paint()..color = const Color(0xFFF2F2F6),
    );
  }

  void _exhaust(Canvas canvas, Offset p) {
    for (var i = 0; i < 4; i++) {
      final u = ((t * 2 + i * 0.18) % 1.0);
      canvas.drawCircle(
        p + Offset(-u * 16, -u * 8 + math.sin(t * 8 + i) * 2),
        2.0 + u * 5,
        Paint()..color = const Color(0x55A8B4C0).withValues(alpha: 0.28 * (1 - u)),
      );
    }
  }

  void _waitSign(Canvas canvas, Offset c) {
    final bob = math.sin(t * math.pi * 2) * 2.4;
    final origin = c + Offset(0, bob);
    canvas.drawRect(
      Rect.fromCenter(center: origin + const Offset(0, 18), width: 3, height: 22),
      Paint()..color = const Color(0xFF8A96A6),
    );
    final glow = 0.5 + 0.5 * math.sin(t * math.pi * 4);
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: origin, width: compact ? 78 : 96, height: compact ? 28 : 34),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      board,
      Paint()..color = accent.withValues(alpha: 0.16 + 0.18 * glow),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      origin + Offset((compact ? 32 : 40), -10),
      2.0,
      Paint()..color = accent,
    );
    final dots = '.' * (1 + (t * 3).floor() % 3);
    _fitText(
      canvas,
      '${waitingTag.toUpperCase()}$dots',
      origin,
      const Color(0xFFF2F2F6),
      maxWidth: compact ? 70 : 88,
      size: compact ? 8 : 10,
    );
  }

  void _working(Canvas canvas, Size size) {
    _floor(canvas, size, y: 0.86);
    switch (craft) {
      case JobWorkCraft.wash:
        _workWash(canvas, size);
      case JobWorkCraft.tires:
        _workTires(canvas, size);
      case JobWorkCraft.electrical:
        _workElectrical(canvas, size);
      case JobWorkCraft.engine:
        _workEngine(canvas, size);
      case JobWorkCraft.chassis:
        _workChassis(canvas, size);
      case JobWorkCraft.body:
        _workBody(canvas, size);
      case JobWorkCraft.diagnostics:
        _workDiag(canvas, size);
      case JobWorkCraft.general:
        _workChassis(canvas, size);
    }
    _fitText(
      canvas,
      workingTag.toUpperCase(),
      Offset(size.width * 0.50, size.height * 0.93),
      accent,
      size: 9,
    );
  }

  void _liftPosts(Canvas canvas, Size size, double top) {
    final w = size.width;
    final h = size.height;
    final post = Paint()..color = const Color(0xFF8A96A6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.22, 7, h * 0.64),
        const Radius.circular(1.5),
      ),
      post,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.22, 7, h * 0.64),
        const Radius.circular(1.5),
      ),
      post,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.22, top, w * 0.54, 4),
      Paint()..color = accent,
    );
  }

  void _workChassis(Canvas canvas, Size size) {
    final bob = math.sin(t * math.pi * 2) * 3;
    final top = size.height * 0.42 + bob;
    _liftPosts(canvas, size, top + 10);
    _car(canvas, Offset(size.width * 0.50, top), scale: 1.2);
    final sparkT = (t * 6) % 1;
    if (sparkT < 0.45) {
      _sparks(canvas, Offset(size.width * 0.38, top + 18), sparkT);
    }
    _wrench(canvas, Offset(size.width * 0.68, top + 16), t * math.pi * 2);
  }

  void _workEngine(Canvas canvas, Size size) {
    _car(canvas, Offset(size.width * 0.48, size.height * 0.62), scale: 1.25);
    final hood = Path()
      ..moveTo(size.width * 0.48 + 8, size.height * 0.62 - 14)
      ..lineTo(size.width * 0.48 + 28, size.height * 0.62 - 14 - 10 * (0.6 + 0.4 * math.sin(t * math.pi)))
      ..lineTo(size.width * 0.48 + 30, size.height * 0.62 - 6);
    canvas.drawPath(
      hood,
      Paint()
        ..color = const Color(0xFFC8CDD4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _heat(canvas, Offset(size.width * 0.58, size.height * 0.48));
    _wrench(canvas, Offset(size.width * 0.66, size.height * 0.52), t * math.pi * 2.4);
  }

  void _workElectrical(Canvas canvas, Size size) {
    _car(canvas, Offset(size.width * 0.58, size.height * 0.62), scale: 1.15);
    final lap = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.28, size.height * 0.62), width: 46, height: 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(lap, Paint()..color = const Color(0xFF1A2430));
    canvas.drawRRect(
      lap,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width * 0.28, size.height * 0.59), width: 34, height: 14),
      Paint()..color = const Color(0xFF0E1A12),
    );
    for (var i = 0; i < 4; i++) {
      final on = ((t * 8 + i).floor() % 2) == 0;
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.28 - 14, size.height * 0.54 + i * 3.2, 8.0 + (i * 5), 2),
        Paint()..color = on ? accent : const Color(0xFF244030),
      );
    }
    final cable = Path()
      ..moveTo(size.width * 0.36, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.72,
        size.width * 0.50,
        size.height * 0.62,
      );
    canvas.drawPath(
      cable,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if ((t * 10).floor() % 2 == 0) {
      _sparks(canvas, Offset(size.width * 0.50, size.height * 0.62), t);
    }
  }

  void _workWash(Canvas canvas, Size size) {
    _car(canvas, Offset(size.width * 0.50, size.height * 0.62), scale: 1.2);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.32 + i * 0.09);
      final drop = ((t + i * 0.17) % 1.0);
      canvas.drawLine(
        Offset(x, size.height * 0.18),
        Offset(x + math.sin(t * 8 + i) * 4, size.height * (0.18 + drop * 0.38)),
        Paint()
          ..color = const Color(0x8848A0C8)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    final shine = (math.sin(t * math.pi * 2) * 0.5 + 0.5);
    canvas.drawLine(
      Offset(size.width * (0.36 + shine * 0.28), size.height * 0.56),
      Offset(size.width * (0.40 + shine * 0.28), size.height * 0.60),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _workTires(Canvas canvas, Size size) {
    _car(canvas, Offset(size.width * 0.46, size.height * 0.58), scale: 1.15);
    final spin = t * math.pi * 4;
    canvas.save();
    canvas.translate(size.width * 0.72, size.height * 0.70);
    canvas.rotate(spin);
    canvas.drawCircle(Offset.zero, 14, Paint()..color = const Color(0xFF1A1A1E));
    canvas.drawCircle(
      Offset.zero,
      14,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(const Offset(-10, 0), const Offset(10, 0), Paint()..color = accent..strokeWidth = 1.2);
    canvas.drawLine(const Offset(0, -10), const Offset(0, 10), Paint()..color = accent..strokeWidth = 1.2);
    canvas.restore();
    _wrench(canvas, Offset(size.width * 0.58, size.height * 0.72), t * math.pi * 2);
  }

  void _workBody(Canvas canvas, Size size) {
    _car(canvas, Offset(size.width * 0.46, size.height * 0.62), scale: 1.2);
    final gun = Offset(size.width * 0.72, size.height * 0.48 + math.sin(t * math.pi * 4) * 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: gun, width: 22, height: 6), const Radius.circular(2)),
      Paint()..color = const Color(0xFF8A96A6),
    );
    for (var i = 0; i < 10; i++) {
      final u = (t * 3 + i * 0.08) % 1;
      canvas.drawCircle(
        gun + Offset(-18 - u * 28, math.sin(i + t * 8) * 8),
        1.6 + (1 - u),
        Paint()..color = accent.withValues(alpha: 0.45 * (1 - u)),
      );
    }
  }

  void _workDiag(Canvas canvas, Size size) {
    _workElectrical(canvas, size);
  }

  void _ready(Canvas canvas, Size size) {
    _floor(canvas, size);
    _shop(canvas, size, door: 0.92);
    final travel = t < 0.72 ? Curves.easeInOutCubic.transform(t / 0.72) : 1.0;
    final x = size.width * (0.38 + travel * 0.36);
    _car(canvas, Offset(x, size.height * 0.70), scale: 1.15);
    _person(canvas, Offset(size.width * 0.88, size.height * 0.62));
    if (travel > 0.85) {
      final pulse = math.sin((t - 0.72) * math.pi * 10) * 0.5 + 0.5;
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.70),
        10 + pulse * 10,
        Paint()..color = accent.withValues(alpha: 0.10 + pulse * 0.12),
      );
      _keys(canvas, Offset(size.width * 0.78, size.height * 0.48 - pulse * 4));
    }
    _fitText(
      canvas,
      readyTag.toUpperCase(),
      Offset(size.width * 0.42, size.height * 0.90),
      accent,
      size: 10,
    );
  }

  void _keys(Canvas canvas, Offset p) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(math.sin(t * math.pi * 4) * 0.25);
    canvas.drawCircle(Offset.zero, 5, Paint()
      ..color = const Color(0xFFFFD54A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    canvas.drawRect(
      const Rect.fromLTWH(4, -1.2, 12, 2.4),
      Paint()..color = const Color(0xFFFFD54A),
    );
    canvas.restore();
  }

  void _person(Canvas canvas, Offset p) {
    canvas.drawCircle(p + const Offset(0, -16), 5, Paint()..color = const Color(0xFFE8E8ED));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 10, height: 18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3A4654),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p + const Offset(8, -4), width: 8, height: 3),
        const Radius.circular(1),
      ),
      Paint()..color = accent,
    );
  }

  void _sparks(Canvas canvas, Offset p, double u) {
    final rnd = math.Random((u * 40).floor());
    for (var i = 0; i < 7; i++) {
      final a = rnd.nextDouble() * math.pi - math.pi / 2;
      final len = 4.0 + rnd.nextDouble() * 8;
      canvas.drawLine(
        p,
        p + Offset(math.cos(a), math.sin(a)) * len,
        Paint()
          ..color = const Color(0xFFFFD54A)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _wrench(Canvas canvas, Offset p, double ang) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(math.sin(ang) * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 4),
        const Radius.circular(1.4),
      ),
      Paint()..color = const Color(0xFFC5CCD4),
    );
    canvas.drawCircle(const Offset(12, 0), 4.2, Paint()
      ..color = const Color(0xFFC5CCD4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    canvas.restore();
  }

  void _heat(Canvas canvas, Offset p) {
    for (var i = 0; i < 3; i++) {
      final y = math.sin(t * math.pi * 2 + i) * 3;
      canvas.drawArc(
        Rect.fromCenter(center: p + Offset(i * 6.0, y), width: 8, height: 10),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0x66E67E22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _fitText(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    double size = 10,
    double maxWidth = 140,
    FontWeight weight = FontWeight.w800,
    double tracking = 0.8,
    int maxLines = 2,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: tracking,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _JobStagePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.phase != phase ||
      oldDelegate.craft != craft ||
      oldDelegate.accent != accent ||
      oldDelegate.shopName != shopName ||
      oldDelegate.waitingTag != waitingTag ||
      oldDelegate.workingTag != workingTag ||
      oldDelegate.readyTag != readyTag ||
      oldDelegate.plate != plate;
}
