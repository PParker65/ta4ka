class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

const kyivCenter = GeoPoint(50.4501, 30.5234);
const lvivCenter = GeoPoint(49.8397, 24.0297);
const warsawCenter = GeoPoint(52.2297, 21.0122);
const odesaCenter = GeoPoint(46.4825, 30.7233);
const brusselsCenter = GeoPoint(50.8503, 4.3517);
const berlinCenter = GeoPoint(52.5200, 13.4050);
const krakowCenter = GeoPoint(50.0647, 19.9450);

GeoPoint centerForCity(String cityId) {
  return switch (cityId) {
    'lviv' => lvivCenter,
    'warsaw' => warsawCenter,
    'kyiv' => kyivCenter,
    'odesa' => odesaCenter,
    'brussels' || 'antwerp' => brusselsCenter,
    'berlin' => berlinCenter,
    'krakow' => krakowCenter,
    'gdansk' => const GeoPoint(54.3520, 18.6466),
    'kharkiv' => const GeoPoint(49.9935, 36.2304),
    'dnipro' => const GeoPoint(48.4647, 35.0462),
    'vinnytsia' => const GeoPoint(49.2331, 28.4682),
    'prague' => const GeoPoint(50.0755, 14.4378),
    'vienna' => const GeoPoint(48.2082, 16.3738),
    'budapest' => const GeoPoint(47.4979, 19.0402),
    _ => warsawCenter,
  };
}

const _nearestCityIds = [
  'lviv',
  'warsaw',
  'kyiv',
  'odesa',
  'brussels',
  'antwerp',
  'berlin',
  'krakow',
  'gdansk',
  'kharkiv',
  'dnipro',
  'vinnytsia',
  'prague',
  'vienna',
  'budapest',
];

/// Closest Ta4ka city to a GPS point (catalog + feed ranking).
String nearestCityId(double lat, double lng) {
  var bestId = 'warsaw';
  var best = double.infinity;
  for (final id in _nearestCityIds) {
    final c = centerForCity(id);
    final dLat = lat - c.lat;
    final dLng = lng - c.lng;
    final d = dLat * dLat + dLng * dLng;
    if (d < best) {
      best = d;
      bestId = id;
    }
  }
  return bestId;
}

String matchCityId(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 'warsaw';
  if (q.contains('льв') || q.contains('lviv')) return 'lviv';
  if (q.contains('варш') || q.contains('warsaw') || q.contains('warszawa')) {
    return 'warsaw';
  }
  if (q.contains('ки') || q.contains('kyiv') || q.contains('kiev')) return 'kyiv';
  if (q.contains('одес') || q.contains('odesa') || q.contains('odessa')) {
    return 'odesa';
  }
  if (q.contains('харк') || q.contains('khark')) return 'kharkiv';
  if (q.contains('дніп') || q.contains('dnip') || q.contains('dnepr')) {
    return 'dnipro';
  }
  if (q.contains('вінн') || q.contains('vinn')) return 'vinnytsia';
  if (q.contains('крак') || q.contains('krak')) return 'krakow';
  if (q.contains('гдан') || q.contains('gdansk') || q.contains('gdańsk')) {
    return 'gdansk';
  }
  if (q.contains('брюс') || q.contains('brussel') || q.contains('belgium') || q.contains('бельг')) {
    return 'brussels';
  }
  if (q.contains('антвер') || q.contains('antwerp')) return 'antwerp';
  if (q.contains('берл') || q.contains('berlin')) return 'berlin';
  if (q.contains('праг') || q.contains('prague') || q.contains('praha')) {
    return 'prague';
  }
  if (q.contains('віден') || q.contains('vienna') || q.contains('wien')) {
    return 'vienna';
  }
  if (q.contains('буда') || q.contains('budapest')) return 'budapest';
  return 'all';
}
