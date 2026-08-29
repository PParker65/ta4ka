import 'car_glb_models.dart';

/// Web / stub: models are same-origin URLs, no disk cache.
class GlbModelCache {
  GlbModelCache._();

  static Future<String> resolveSrc(CarGlbModel glb) async => glb.viewerSrc;

  static void precacheNeighbors(String brandId) {}

  static void precacheUrl(String url) {}
}
