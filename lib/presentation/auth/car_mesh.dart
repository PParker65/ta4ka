import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/car_brands.dart';
import '../../data/car_hotspots.dart';
import '../../data/car_layout.dart';

/// 0 = metal guts / cabin, 1 = ghost body, 2 = lamps.
class CarFace {
  const CarFace(
    this.points,
    this.fill, {
    this.stroke,
    this.emissive = false,
    this.strokeWidth = 1.0,
    this.layer = 0,
  });

  final List<Vec3> points;
  final Color fill;
  final Color? stroke;
  final bool emissive;
  final double strokeWidth;
  final int layer;
}

List<CarFace> buildCarScene({
  required CarBrand brand,
  required double doorL,
  required double doorR,
}) {
  final l = CarLayout.of(brand);
  final faces = <CarFace>[];
  final bodyTint = Color.lerp(const Color(0xFFE4EEF4), brand.bodyColor, 0.42)!;
  _shell(faces, l, bodyTint);
  if (l.muscleFastback) {
    _camaroFascia(faces, l);
    _camaroSsStripes(faces, l, brand.bodyColor);
  } else {
    _fascia(faces, l);
  }
  final _ = doorL + doorR;
  return faces;
}

double _smooth(double k) {
  final t = k.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _len(CarLayout l) => l.front - l.rear;

double _tOf(CarLayout l, double x) => (x - l.rear) / _len(l);

const _glassA = 0.18;
const _glassB = 0.58;

bool _inGlass(double t) => t > _glassA && t < _glassB;

double _arch(double x, double wheelX) {
  const radius = 24.0;
  final d = (x - wheelX).abs();
  if (d >= radius) {
    return 10;
  }
  return 10 + math.sqrt(radius * radius - d * d) * 0.78;
}

double _rockerY(CarLayout l, double t, double x) {
  var y = math.max(_arch(x, l.wheelFY), _arch(x, l.wheelRY));
  if (t < 0.05) {
    y = math.max(y, 10 + (0.05 - t) / 0.05 * 7);
  }
  if (t > 0.95) {
    y = math.max(y, 10 + (t - 0.95) / 0.05 * 6);
  }
  return y;
}

double _beltY(CarLayout l, double t) {
  final trunk = l.belt + 4;
  final cabin = l.belt.toDouble();
  if (l.muscleFastback) {
    if (t < 0.06) {
      return 16 + _smooth(t / 0.06) * 10;
    }
    if (t < 0.22) {
      return 26 + _smooth((t - 0.06) / 0.16) * (cabin - 26);
    }
    if (t < 0.58) {
      return cabin;
    }
    if (t < 0.88) {
      return cabin - _smooth((t - 0.58) / 0.30) * (cabin - 24);
    }
    return 24 - _smooth((t - 0.88) / 0.12) * 4;
  }
  if (t < 0.07) {
    return 18 + _smooth(t / 0.07) * 12;
  }
  if (t < 0.18) {
    return 30 + _smooth((t - 0.07) / 0.11) * (trunk - 30);
  }
  if (t < 0.58) {
    return trunk + _smooth((t - 0.18) / 0.40) * (cabin - trunk);
  }
  if (t < 0.78) {
    return cabin - _smooth((t - 0.58) / 0.20) * (cabin - 28);
  }
  if (t < 0.92) {
    return 28 - _smooth((t - 0.78) / 0.14) * 6;
  }
  return 22 - _smooth((t - 0.92) / 0.08) * 5;
}

double _roofY(CarLayout l, double t) {
  final belt = _beltY(l, t);
  final peak = l.roof.toDouble();
  if (l.muscleFastback) {
    if (t < 0.14) {
      return belt;
    }
    if (t < 0.30) {
      return belt + _smooth((t - 0.14) / 0.16) * (peak - belt);
    }
    if (t < 0.52) {
      return peak;
    }
    if (t < 0.78) {
      return peak - _smooth((t - 0.52) / 0.26) * (peak - belt - 2);
    }
    return belt + 2;
  }
  if (t < 0.16) {
    return belt;
  }
  if (t < 0.28) {
    return belt + _smooth((t - 0.16) / 0.12) * (peak - 4 - belt);
  }
  if (t < 0.48) {
    return peak - 4 + _smooth((t - 0.28) / 0.20) * 4;
  }
  if (t < _glassB) {
    return peak - _smooth((t - 0.48) / (_glassB - 0.48)) * (peak - belt);
  }
  return belt;
}

double _halfW(CarLayout l, double t) {
  final w = l.halfW.toDouble();
  if (t < 0.08) {
    return w * (0.70 + _smooth(t / 0.08) * 0.30);
  }
  if (t > 0.90) {
    return w * (1.0 - _smooth((t - 0.90) / 0.10) * 0.28);
  }
  return w;
}

double _cabinW(CarLayout l, double t) {
  final w = _halfW(l, t);
  if (_inGlass(t)) {
    return w * 0.78;
  }
  return w * 0.96;
}

void _quad(
  List<CarFace> out,
  List<Vec3> pts,
  Color fill, {
  Color? stroke,
  bool emissive = false,
  double strokeWidth = 1.0,
  int layer = 0,
}) {
  out.add(CarFace(
    pts,
    fill,
    stroke: stroke,
    emissive: emissive,
    strokeWidth: strokeWidth,
    layer: layer,
  ));
}

void _box(
  List<CarFace> out,
  Vec3 c,
  double dx,
  double dy,
  double dz,
  Color color, {
  Color? stroke,
  int layer = 0,
}) {
  final x0 = c.x - dx, x1 = c.x + dx;
  final y0 = c.y - dy, y1 = c.y + dy;
  final z0 = c.z - dz, z1 = c.z + dz;
  _quad(out, [Vec3(x0, y0, z0), Vec3(x1, y0, z0), Vec3(x1, y1, z0), Vec3(x0, y1, z0)], color, stroke: stroke, layer: layer);
  _quad(out, [Vec3(x0, y0, z1), Vec3(x0, y1, z1), Vec3(x1, y1, z1), Vec3(x1, y0, z1)], color, stroke: stroke, layer: layer);
  _quad(out, [Vec3(x0, y0, z0), Vec3(x0, y1, z0), Vec3(x0, y1, z1), Vec3(x0, y0, z1)], color, stroke: stroke, layer: layer);
  _quad(out, [Vec3(x1, y0, z0), Vec3(x1, y0, z1), Vec3(x1, y1, z1), Vec3(x1, y1, z0)], color, stroke: stroke, layer: layer);
  _quad(out, [Vec3(x0, y1, z0), Vec3(x1, y1, z0), Vec3(x1, y1, z1), Vec3(x0, y1, z1)], color, stroke: stroke, layer: layer);
}

void _chamfer(
  List<CarFace> out,
  Vec3 c,
  double dx,
  double dy,
  double dz,
  Color color, {
  Color? stroke,
  int layer = 0,
}) {
  const k = 0.88;
  final p = [
    Vec3(c.x - dx, c.y - dy * k, c.z - dz * k),
    Vec3(c.x + dx, c.y - dy * k, c.z - dz * k),
    Vec3(c.x + dx, c.y - dy * k, c.z + dz * k),
    Vec3(c.x - dx, c.y - dy * k, c.z + dz * k),
    Vec3(c.x - dx * k, c.y + dy, c.z - dz * k),
    Vec3(c.x + dx * k, c.y + dy, c.z - dz * k),
    Vec3(c.x + dx * k, c.y + dy, c.z + dz * k),
    Vec3(c.x - dx * k, c.y + dy, c.z + dz * k),
  ];
  _quad(out, [p[0], p[1], p[5], p[4]], color, stroke: stroke, layer: layer);
  _quad(out, [p[2], p[3], p[7], p[6]], color, stroke: stroke, layer: layer);
  _quad(out, [p[0], p[4], p[7], p[3]], color, stroke: stroke, layer: layer);
  _quad(out, [p[1], p[2], p[6], p[5]], color, stroke: stroke, layer: layer);
  _quad(out, [p[4], p[5], p[6], p[7]], color, stroke: stroke, layer: layer);
}

void _tube(List<CarFace> out, Vec3 a, Vec3 b, double r, Color color, {int layer = 0}) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final dz = b.z - a.z;
  final n = math.sqrt(dx * dx + dy * dy + dz * dz);
  if (n < 1) {
    return;
  }
  final steps = math.max(3, (n / 14).round());
  for (var i = 0; i < steps; i++) {
    final t = (i + 0.5) / steps;
    _chamfer(
      out,
      Vec3(a.x + dx * t, a.y + dy * t, a.z + dz * t),
      r,
      r * 0.85,
      r,
      color,
      layer: layer,
    );
  }
}

void _coil(List<CarFace> out, Vec3 a, Vec3 b, Color color) {
  const n = 8;
  final dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
  for (var i = 0; i < n; i++) {
    final t = i / (n - 1);
    final spin = i * 1.15;
    _chamfer(
      out,
      Vec3(
        a.x + dx * t + math.cos(spin) * 2.2,
        a.y + dy * t,
        a.z + dz * t + math.sin(spin) * 2.2,
      ),
      1.35,
      1.1,
      1.35,
      color,
    );
  }
}

void _chassis(List<CarFace> out, CarLayout l) {
  const rail = Color(0xFF3E6A96);
  const railHi = Color(0xFF5A88B0);
  const cage = Color(0xFFC4843A);
  const floor = Color(0xFF4A4E54);

  _tube(out, Vec3(l.rear + 16, 11, -18), Vec3(l.front - 18, 11, -18), 2.1, rail);
  _tube(out, Vec3(l.rear + 16, 11, 18), Vec3(l.front - 18, 11, 18), 2.1, rail);
  _tube(out, Vec3(l.rear + 16, 11, -18), Vec3(l.rear + 16, 11, 18), 1.8, railHi);
  _tube(out, Vec3(l.front - 18, 11, -18), Vec3(l.front - 18, 11, 18), 1.8, railHi);
  _tube(out, Vec3(l.cabinF - 6, 11, -18), Vec3(l.cabinF - 6, 11, 18), 1.7, railHi);
  _tube(out, Vec3(l.cabinR + 8, 11, -18), Vec3(l.cabinR + 8, 11, 18), 1.7, railHi);
  _box(out, Vec3((l.cabinF + l.cabinR) / 2, 10, 0), 34, 1.6, 20, floor);

  void steelPillar(double t, {double lean = 0}) {
    final x = l.rear + _len(l) * t;
    final w = _cabinW(l, t);
    _tube(out, Vec3(x, _beltY(l, t) + 1, -w), Vec3(x + lean, _roofY(l, t), -w * 0.9), 1.45, cage);
    _tube(out, Vec3(x, _beltY(l, t) + 1, w), Vec3(x + lean, _roofY(l, t), w * 0.9), 1.45, cage);
  }

  steelPillar(0.22, lean: 8);
  steelPillar(0.38);
  steelPillar(0.52, lean: -6);
  _tube(
    out,
    Vec3(l.rear + _len(l) * 0.24, l.roof - 1, -_cabinW(l, 0.24) * 0.9),
    Vec3(l.rear + _len(l) * 0.52, l.roof - 1, -_cabinW(l, 0.52) * 0.9),
    1.2,
    cage,
  );
  _tube(
    out,
    Vec3(l.rear + _len(l) * 0.24, l.roof - 1, _cabinW(l, 0.24) * 0.9),
    Vec3(l.rear + _len(l) * 0.52, l.roof - 1, _cabinW(l, 0.52) * 0.9),
    1.2,
    cage,
  );
}

void _engine(List<CarFace> out, CarLayout l) {
  const iron = Color(0xFF2F3034);
  const ironHi = Color(0xFF4A4C52);
  const alum = Color(0xFFB8BEC6);
  const cover = Color(0xFF1A1C20);
  const plastic = Color(0xFF2A2E34);
  const hose = Color(0xFF6A3A32);
  const belt = Color(0xFF1C1C1C);

  final ex = l.engineX;
  _chamfer(out, Vec3(ex, 20, 0), 18, 8, 11, iron, stroke: const Color(0xFF6A6C72));
  _chamfer(out, Vec3(ex, 28, 0), 16, 4.5, 9.5, ironHi);
  _box(out, Vec3(ex - 1, 34, 0), 15, 3.2, 8.5, cover, stroke: const Color(0xFF8A8E94));
  for (var i = 0; i < 4; i++) {
    final x = ex - 11 + i * 7.2;
    _chamfer(out, Vec3(x, 38, 0), 2.4, 2.2, 5.5, alum);
    _tube(out, Vec3(x, 40, 0), Vec3(x - 2, 44, 0), 1.5, alum);
  }
  _chamfer(out, Vec3(ex - 4, 45, 0), 12, 2.4, 5.5, alum, stroke: const Color(0xFFD0D4DA));
  _chamfer(out, Vec3(ex + 10, 42, 0), 4, 3, 3.5, plastic);

  _chamfer(out, Vec3(ex + 20, 22, 0), 2.6, 6, 6, const Color(0xFF3A3A3E));
  _chamfer(out, Vec3(ex + 20, 22, 0), 1.2, 7.2, 7.2, belt);
  _chamfer(out, Vec3(ex + 20, 30, -10), 3.2, 3.6, 3.2, alum);
  _chamfer(out, Vec3(ex + 20, 16, 10), 3.4, 3.2, 3.2, ironHi);
  _tube(out, Vec3(ex + 20, 28, -8), Vec3(ex + 20, 18, 8), 0.9, belt);

  for (var i = 0; i < 4; i++) {
    final x = ex - 11 + i * 7.2;
    _tube(out, Vec3(x, 24, -11), Vec3(ex + 6, 16, -16), 1.35, hose);
  }
  _chamfer(out, Vec3(ex + 8, 16, -16), 5, 3, 3.2, const Color(0xFF5A5048));

  _box(out, Vec3(l.front - 14, 24, 0), 2.4, 11, 18, const Color(0xFF3E4A54), stroke: const Color(0xFF6A7A88));
  _chamfer(out, Vec3(l.front - 18, 24, -8), 1.6, 7, 7, const Color(0xFF2A3036));
  _chamfer(out, Vec3(l.front - 18, 24, 8), 1.6, 7, 7, const Color(0xFF2A3036));
  _tube(out, Vec3(l.front - 16, 32, -10), Vec3(ex + 8, 36, -6), 1.5, const Color(0xFFC45A3A));
  _tube(out, Vec3(l.front - 16, 32, 10), Vec3(ex + 8, 36, 6), 1.5, const Color(0xFFC45A3A));

  _box(out, Vec3(ex + 6, 26, 18), 7, 5, 4.5, const Color(0xFF1E3A28), stroke: const Color(0xFF4A8A5A));
  _box(out, Vec3(ex + 4, 32, -18), 8, 6, 5, plastic, stroke: const Color(0xFF4A5058));
  _chamfer(out, Vec3(l.front - 22, 18, 14), 3, 4, 3, const Color(0xFFD8D2C4));
}

void _drivetrain(List<CarFace> out, CarLayout l) {
  const caseCol = Color(0xFF3A6A92);
  const shaft = Color(0xFF9AA4AE);
  const iron = Color(0xFF3A3C42);
  final ex = l.engineX;

  _chamfer(out, Vec3(ex - 24, 18, 0), 10, 7, 8, iron, stroke: const Color(0xFF6A6E74));
  _chamfer(out, Vec3(ex - 38, 16, 0), 8, 6, 7, caseCol, stroke: const Color(0xFF7AA0C4));
  _tube(out, Vec3(ex - 46, 14, 0), Vec3(l.wheelRY + 14, 14, 0), 2.4, shaft);
  _chamfer(out, Vec3(l.wheelRY + 8, 14, 0), 8, 5.5, 9, caseCol, stroke: const Color(0xFF7AA0C4));
  _chamfer(out, Vec3(l.wheelFY - 4, 14, 0), 7, 5, 8, iron);
  _tube(out, Vec3(l.wheelFY - 4, 14, -7), Vec3(l.wheelFY, l.ride, -l.halfW + 10), 1.7, shaft);
  _tube(out, Vec3(l.wheelFY - 4, 14, 7), Vec3(l.wheelFY, l.ride, l.halfW - 10), 1.7, shaft);
  _tube(out, Vec3(l.wheelRY + 8, 14, -8), Vec3(l.wheelRY, l.ride, -l.halfW + 10), 1.7, shaft);
  _tube(out, Vec3(l.wheelRY + 8, 14, 8), Vec3(l.wheelRY, l.ride, l.halfW - 10), 1.7, shaft);
  _box(out, Vec3(l.cabinR - 2, 15, 0), 11, 4.5, 16, const Color(0xFF3A4248));
}

void _suspension(List<CarFace> out, CarLayout l) {
  const arm = Color(0xFF8A9098);
  const disc = Color(0xFFC8CCD2);
  const caliper = Color(0xFFB01828);
  for (final w in sedanWheelCenters(l)) {
    final inner = Vec3(w.x, w.y, w.z * 0.78);
    _chamfer(out, inner, 6.5, 6.5, 1.5, disc, stroke: const Color(0xFFE8EAE0));
    _chamfer(out, Vec3(w.x, w.y + 1.5, w.z * 0.86), 3.4, 2.6, 2.2, caliper);
    _tube(out, Vec3(w.x - 10, 14, w.z * 0.42), inner, 1.5, arm);
    _tube(out, Vec3(w.x + 8, 14, w.z * 0.42), inner, 1.5, arm);
    final top = Vec3(w.x - 3, 34, w.z * 0.55);
    _coil(out, Vec3(inner.x - 2, inner.y + 8, inner.z * 0.92), top, arm);
    _tube(out, Vec3(inner.x - 2, inner.y + 6, inner.z * 0.9), top, 1.2, const Color(0xFF5A6068));
  }
}

void _exhaust(List<CarFace> out, CarLayout l) {
  const pipe = Color(0xFF6A6258);
  final ex = l.engineX;
  _tube(out, Vec3(ex + 8, 16, -16), Vec3(ex - 20, 11, -12), 2.0, pipe);
  _tube(out, Vec3(ex - 20, 11, -12), Vec3(l.rear + 22, 11, -14), 2.2, pipe);
  _chamfer(out, Vec3(l.rear + 28, 11, -14), 10, 3.4, 4.2, pipe);
  _chamfer(out, Vec3(l.rear + 6, 11, -14), 3.2, 2.8, 2.8, const Color(0xFFC8C8C8));
  _chamfer(out, Vec3(l.rear + 6, 11, 10), 3.2, 2.8, 2.8, const Color(0xFFC8C8C8));
  _tube(out, Vec3(l.rear + 22, 11, -14), Vec3(l.rear + 22, 11, 10), 1.8, pipe);
}

void _cabin(List<CarFace> out, CarLayout l) {
  const leather = Color(0xFF1A1614);
  const stitch = Color(0xFF4A4038);
  const dash = Color(0xFF242228);
  const glass = Color(0xFF1A2228);
  final mid = (l.cabinF + l.cabinR) / 2;

  _box(out, Vec3(mid, 13, 0), 30, 1.8, 18, const Color(0xFF2A2A30));
  _box(out, Vec3(mid - 2, 17, 0), 24, 3.6, 5, const Color(0xFF323238));
  _seat(out, Vec3(mid + 8, 20, -13), leather, stitch);
  _seat(out, Vec3(mid + 8, 20, 13), leather, stitch);
  _box(out, Vec3(mid - 14, 22, 0), 9, 6, 16, leather, stroke: stitch);
  _box(out, Vec3(l.cabinF - 7, 30, 0), 6, 7, 19, dash, stroke: stitch);
  _box(out, Vec3(l.cabinF - 5, 34, -9), 2.2, 3.2, 6, glass);
  _box(out, Vec3(l.cabinF - 5, 33, 6), 2, 4, 6.5, glass);
  _box(out, Vec3(l.cabinF - 8, 24, 0), 4, 2, 3, const Color(0xFF3A3A40));
  _steering(out, Vec3(l.cabinF - 1, 36, -12));
}

void _seat(List<CarFace> out, Vec3 base, Color leather, Color stitch) {
  _chamfer(out, base, 9, 3.4, 7, leather, stroke: stitch);
  _chamfer(out, Vec3(base.x - 4, base.y + 12, base.z), 4, 11, 6.4, leather, stroke: stitch);
  _chamfer(out, Vec3(base.x - 4, base.y + 24, base.z), 2.2, 3, 4, leather);
  _chamfer(out, Vec3(base.x + 1, base.y + 5, base.z - 6.2), 7, 3.6, 1.4, leather);
  _chamfer(out, Vec3(base.x + 1, base.y + 5, base.z + 6.2), 7, 3.6, 1.4, leather);
}

void _steering(List<CarFace> out, Vec3 c) {
  const col = Color(0xFF141414);
  const n = 8;
  const r = 7.4;
  for (var i = 0; i < n; i++) {
    final a0 = i / n * math.pi * 2;
    final a1 = (i + 1) / n * math.pi * 2;
    _quad(
      out,
      [
        Vec3(c.x, c.y + math.sin(a0) * r, c.z + math.cos(a0) * r),
        Vec3(c.x, c.y + math.sin(a1) * r, c.z + math.cos(a1) * r),
        Vec3(c.x + 1.6, c.y + math.sin(a1) * (r - 1.4), c.z + math.cos(a1) * (r - 1.4)),
        Vec3(c.x + 1.6, c.y + math.sin(a0) * (r - 1.4), c.z + math.cos(a0) * (r - 1.4)),
      ],
      col,
    );
  }
  _chamfer(out, c, 1.8, 1.8, 1.5, const Color(0xFF2A2A2E));
  _box(out, Vec3(c.x, c.y - 1, c.z), 0.7, 0.7, 5.5, col);
  _box(out, Vec3(c.x, c.y + 2.5, c.z), 0.7, 3.2, 0.7, col);
}

void _shell(List<CarFace> out, CarLayout l, Color tint) {
  final paint = tint.withValues(alpha: 0.20);
  final hood = Color.lerp(tint, const Color(0xFFF4F7FA), 0.35)!.withValues(alpha: 0.10);
  final edge = Color.lerp(tint, const Color(0xFF5A90B8), 0.45)!.withValues(alpha: 0.72);
  const glass = Color(0x2A6AA0C0);
  const glassEdge = Color(0xAA8EC4E0);
  const steps = 10;
  final rockerL = <Vec3>[];
  final rockerR = <Vec3>[];
  final beltL = <Vec3>[];
  final beltR = <Vec3>[];
  final roofL = <Vec3>[];
  final roofR = <Vec3>[];

  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = l.rear + _len(l) * t;
    final w = _halfW(l, t);
    final cw = _cabinW(l, t);
    rockerL.add(Vec3(x, _rockerY(l, t, x), -w));
    rockerR.add(Vec3(x, _rockerY(l, t, x), w));
    beltL.add(Vec3(x, _beltY(l, t), -w + 0.8));
    beltR.add(Vec3(x, _beltY(l, t), w - 0.8));
    roofL.add(Vec3(x, _roofY(l, t), -cw));
    roofR.add(Vec3(x, _roofY(l, t), cw));
  }

  for (var i = 0; i < steps; i++) {
    final t = (i + 0.5) / steps;
    final cabin = _inGlass(t);
    final onHood = t > 0.62 && t < 0.94;
    _quad(out, [rockerL[i], rockerL[i + 1], beltL[i + 1], beltL[i]], paint, stroke: edge, strokeWidth: 0.45, layer: 1);
    _quad(out, [rockerR[i], beltR[i], beltR[i + 1], rockerR[i + 1]], paint, stroke: edge, strokeWidth: 0.45, layer: 1);
    _quad(
      out,
      [beltL[i], beltL[i + 1], roofL[i + 1], roofL[i]],
      cabin ? glass : (onHood ? hood : paint),
      stroke: cabin ? glassEdge : edge,
      strokeWidth: cabin ? 0.85 : 0.45,
      layer: 1,
    );
    _quad(
      out,
      [beltR[i], roofR[i], roofR[i + 1], beltR[i + 1]],
      cabin ? glass : (onHood ? hood : paint),
      stroke: cabin ? glassEdge : edge,
      strokeWidth: cabin ? 0.85 : 0.45,
      layer: 1,
    );
    _quad(
      out,
      [roofL[i], roofL[i + 1], roofR[i + 1], roofR[i]],
      cabin ? glass : (onHood ? hood : paint),
      stroke: edge,
      strokeWidth: 0.5,
      layer: 1,
    );
  }

  _quad(out, [rockerL.first, beltL.first, beltR.first, rockerR.first], paint, stroke: edge, layer: 1);
  _quad(out, [rockerL.last, rockerR.last, beltR.last, beltL.last], hood, stroke: edge, layer: 1);

  _outline(out, [...rockerL, ...beltL.reversed], edge.withValues(alpha: 0.9), width: 1.05, layer: 1);
  _outline(out, [...rockerR, ...beltR.reversed], edge.withValues(alpha: 0.9), width: 1.05, layer: 1);

  final doorXs = [(l.cabinF + l.cabinR) / 2 + 8, (l.cabinF + l.cabinR) / 2 - 14];
  for (final x in doorXs) {
    final t = _tOf(l, x);
    final w = _halfW(l, t);
    _quad(
      out,
      [Vec3(x, _rockerY(l, t, x) + 2, -w), Vec3(x, _beltY(l, t) - 1, -w + 1)],
      Colors.transparent,
      stroke: edge.withValues(alpha: 0.45),
      strokeWidth: 0.7,
      layer: 1,
    );
    _quad(
      out,
      [Vec3(x, _rockerY(l, t, x) + 2, w), Vec3(x, _beltY(l, t) - 1, w - 1)],
      Colors.transparent,
      stroke: edge.withValues(alpha: 0.45),
      strokeWidth: 0.7,
      layer: 1,
    );
  }

  final mt = _tOf(l, l.cabinF + 2);
  final mw = _halfW(l, mt);
  final my = _beltY(l, mt) + 2;
  _chamfer(out, Vec3(l.cabinF + 2, my, -mw - 3), 3.6, 1.5, 2.8, paint, stroke: edge, layer: 1);
  _chamfer(out, Vec3(l.cabinF + 2, my, mw + 3), 3.6, 1.5, 2.8, paint, stroke: edge, layer: 1);
}

void _outline(List<CarFace> out, List<Vec3> pts, Color stroke, {double width = 1.1, int layer = 1}) {
  if (pts.length < 2) {
    return;
  }
  out.add(CarFace(pts, Colors.transparent, stroke: stroke, strokeWidth: width, layer: layer));
}

void _camaroFascia(List<CarFace> out, CarLayout l) {
  const chrome = Color(0xCCE0E0E4);
  const mesh = Color(0xCC0A0A0C);
  const lamp = Color(0xD0F8FAFC);
  final w = l.halfW * 0.82;

  // Split grille
  _quad(
    out,
    [
      Vec3(l.front + 1.0, 12, -16),
      Vec3(l.front + 1.0, 12, 16),
      Vec3(l.front + 1.0, 26, 14),
      Vec3(l.front + 1.0, 26, -14),
    ],
    mesh,
    stroke: chrome,
    strokeWidth: 1.2,
    layer: 1,
  );
  for (var i = 0; i < 4; i++) {
    final y = 14.5 + i * 2.8;
    _quad(
      out,
      [
        Vec3(l.front + 1.4, y, -12),
        Vec3(l.front + 1.4, y, 12),
        Vec3(l.front + 1.4, y + 0.6, 12),
        Vec3(l.front + 1.4, y + 0.6, -12),
      ],
      chrome,
      layer: 1,
    );
  }

  // Round headlamps (Camaro SS)
  for (final z in [w - 10.0, -w + 10.0]) {
    _chamfer(out, Vec3(l.front - 2, 24, z), 5.5, 4.5, 5.5, lamp, stroke: chrome, layer: 2);
    _chamfer(out, Vec3(l.front - 2, 24, z), 2.8, 2.2, 2.8, const Color(0xAAFFFFFF), layer: 2);
  }

  // Rear taillights
  _quad(
    out,
    [
      Vec3(l.rear - 0.5, 24, -w + 4),
      Vec3(l.rear - 0.5, 24, w - 4),
      Vec3(l.rear - 0.5, 30, w - 4),
      Vec3(l.rear - 0.5, 30, -w + 4),
    ],
    const Color(0xD0C01820),
    stroke: const Color(0xAAE06060),
    layer: 2,
  );
}

void _camaroSsStripes(List<CarFace> out, CarLayout l, Color body) {
  final stripe = Color.lerp(body, Colors.white, 0.72)!.withValues(alpha: 0.35);
  for (final z in [-7.5, 7.5]) {
    _quad(
      out,
      [
        Vec3(l.front - 8, l.roof - 2, z),
        Vec3(l.rear + 18, l.belt + 6, z),
        Vec3(l.rear + 18, l.belt + 8, z),
        Vec3(l.front - 8, l.roof, z),
      ],
      stripe,
      layer: 1,
    );
  }
}

void _fascia(List<CarFace> out, CarLayout l) {
  const chrome = Color(0xCCE8E8EC);
  const mesh = Color(0xCC121214);
  _quad(
    out,
    [
      Vec3(l.front + 1.2, 14, -18),
      Vec3(l.front + 1.2, 14, 18),
      Vec3(l.front + 1.2, 30, 16),
      Vec3(l.front + 1.2, 30, -16),
    ],
    mesh,
    stroke: chrome,
    strokeWidth: 1.3,
    layer: 1,
  );
  for (var i = 0; i < 5; i++) {
    final y = 16.5 + i * 2.6;
    _quad(
      out,
      [
        Vec3(l.front + 1.6, y, -15),
        Vec3(l.front + 1.6, y, 15),
        Vec3(l.front + 1.6, y + 0.7, 15),
        Vec3(l.front + 1.6, y + 0.7, -15),
      ],
      chrome,
      layer: 1,
    );
  }

  final w = l.halfW * 0.80;
  const lamp = Color(0xD0F4F7FA);
  const lampEdge = Color(0xAA8A9AAA);
  _quad(
    out,
    [
      Vec3(l.front - 1, 24, w + 2),
      Vec3(l.front + 2, 25, w - 16),
      Vec3(l.front + 2, 29, w - 16),
      Vec3(l.front - 1, 28, w + 2),
    ],
    lamp,
    stroke: lampEdge,
    layer: 2,
  );
  _quad(
    out,
    [
      Vec3(l.front - 1, 24, -w - 2),
      Vec3(l.front - 1, 28, -w - 2),
      Vec3(l.front + 2, 29, -w + 16),
      Vec3(l.front + 2, 25, -w + 16),
    ],
    lamp,
    stroke: lampEdge,
    layer: 2,
  );
  _quad(
    out,
    [
      Vec3(l.rear - 0.6, 26, -w),
      Vec3(l.rear - 0.6, 26, w),
      Vec3(l.rear - 0.6, 32, w),
      Vec3(l.rear - 0.6, 32, -w),
    ],
    const Color(0xD0B01018),
    stroke: const Color(0xAAE06060),
    layer: 2,
  );
}

List<Vec3> sedanWheelCenters(CarLayout l) {
  return [
    Vec3(l.wheelFY, l.ride, l.halfW),
    Vec3(l.wheelFY, l.ride, -l.halfW),
    Vec3(l.wheelRY, l.ride, l.halfW),
    Vec3(l.wheelRY, l.ride, -l.halfW),
  ];
}
