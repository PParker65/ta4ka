import 'package:flutter/widgets.dart';

import '../../data/glb_model_cache.dart';

void prefetchGlb(String url) {
  GlbModelCache.precacheUrl(url);
}

String absoluteGlbUrl(String url) => url;

Widget buildGlbCarViewer({
  Key? key,
  required String modelUrl,
  required String modelLabel,
  required String cameraOrbit,
  required bool autoRotate,
  String rotationPerSecond = 'pi/20 radians',
}) {
  return SizedBox(key: key);
}
