import 'car_brands.dart';
import 'car_hotspots.dart';

class CarLayout {
  const CarLayout({
    required this.front,
    required this.rear,
    required this.roof,
    required this.belt,
    required this.halfW,
    required this.cabinF,
    required this.cabinR,
    required this.wheelFY,
    required this.wheelRY,
    required this.engineX,
    required this.ride,
    this.muscleFastback = false,
  });

  final double front;
  final double rear;
  final double roof;
  final double belt;
  final double halfW;
  final double cabinF;
  final double cabinR;
  final double wheelFY;
  final double wheelRY;
  final double engineX;
  final double ride;
  final bool muscleFastback;

  factory CarLayout.of(CarBrand brand) {
    switch (brand.shape) {
      case CarShape.sportSedan:
      case CarShape.luxurySedan:
      case CarShape.wagon:
        return ghost;
      case CarShape.suv:
        return suv;
      default:
        return camaro;
    }
  }

  /// 1967 Camaro SS proportions — long hood, fastback, short deck.
  static const camaro = CarLayout(
    front: 132,
    rear: -94,
    roof: 56,
    belt: 32,
    halfW: 49,
    cabinF: 14,
    cabinR: -52,
    wheelFY: 76,
    wheelRY: -64,
    engineX: 92,
    ride: 11,
    muscleFastback: true,
  );

  /// Universal 4-door sedan (ghost / x-ray). Ordinary car, not a wedge.
  static const ghost = CarLayout(
    front: 128,
    rear: -118,
    roof: 64,
    belt: 38,
    halfW: 47,
    cabinF: 22,
    cabinR: -52,
    wheelFY: 78,
    wheelRY: -80,
    engineX: 86,
    ride: 14,
  );

  /// Box SUV — G-Class and similar.
  static const suv = CarLayout(
    front: 112,
    rear: -102,
    roof: 76,
    belt: 50,
    halfW: 52,
    cabinF: 18,
    cabinR: -58,
    wheelFY: 82,
    wheelRY: -72,
    engineX: 78,
    ride: 24,
  );
}

List<CarHotspot> placedHotspots(CarBrand brand) {
  final l = CarLayout.of(brand);
  Vec3 at(String id, Vec3 fallback) {
    switch (id) {
      case 'engine':
        return Vec3(l.engineX, 32, 0);
      case 'battery':
        return Vec3(l.engineX + 8, 28, 18);
      case 'headlight-r':
        return Vec3(l.front - 4, 26, l.halfW * 0.78);
      case 'headlight-l':
        return Vec3(l.front - 4, 26, -l.halfW * 0.78);
      case 'windshield':
        return Vec3(l.cabinF + 10, l.roof - 10, 0);
      case 'roof':
        return Vec3((l.cabinF + l.cabinR) / 2, l.roof + 4, 0);
      case 'door-r':
        return Vec3((l.cabinF + l.cabinR) / 2, l.belt - 4, l.halfW + 2);
      case 'door-l':
        return Vec3((l.cabinF + l.cabinR) / 2, l.belt - 4, -l.halfW - 2);
      case 'interior':
        return Vec3((l.cabinF + l.cabinR) / 2, 48, 6);
      case 'wheel-fr':
        return Vec3(l.wheelFY, l.ride, l.halfW);
      case 'wheel-fl':
        return Vec3(l.wheelFY, l.ride, -l.halfW);
      case 'wheel-rr':
        return Vec3(l.wheelRY, l.ride, l.halfW);
      case 'wheel-rl':
        return Vec3(l.wheelRY, l.ride, -l.halfW);
      case 'brake-fr':
        return Vec3(l.wheelFY, l.ride, l.halfW * 0.55);
      case 'exhaust':
        return Vec3(l.rear + 4, 12, 16);
      case 'rear':
        return Vec3(l.rear + 8, 32, 0);
      case 'undercarriage':
        return const Vec3(0, 8, 0);
      case 'ac':
        return Vec3(l.cabinF - 4, 46, 0);
      case 'steering':
        return Vec3(l.cabinF - 6, 42, -14);
      case 'headunit':
        return Vec3(l.cabinF - 10, 40, 0);
      case 'seat-l':
        return Vec3((l.cabinF + l.cabinR) / 2 + 6, 32, -14);
      default:
        return fallback;
    }
  }

  return [
    for (final hotspot in carHotspots) hotspot.copyWith(pos: at(hotspot.id, hotspot.pos)),
  ];
}
