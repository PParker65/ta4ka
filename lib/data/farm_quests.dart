import 'car_hotspots.dart';

List<String> farmRepairSphereIds() {
  final ids = <String>[];
  for (final hotspot in carHotspots) {
    if (!ids.contains(hotspot.sphereId)) {
      ids.add(hotspot.sphereId);
    }
  }
  return ids;
}

List<CarHotspot> uniqueFarmHotspots(List<CarHotspot> placed) {
  final seen = <String>{};
  return [
    for (final hotspot in placed)
      if (seen.add(hotspot.sphereId)) hotspot,
  ];
}
