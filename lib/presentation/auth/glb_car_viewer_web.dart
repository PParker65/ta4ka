// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js_util' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'glb_car_config.dart';

final _registered = <String>{};
final _warmed = <String>{};

bool _inTelegram() {
  try {
    final tg = js.getProperty(html.window, 'Telegram');
    if (tg == null) return false;
    final wa = js.getProperty(tg, 'WebApp');
    return wa != null;
  } catch (_) {
    return html.window.navigator.userAgent.contains('Telegram');
  }
}

String absoluteGlbUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final origin = html.window.location.origin;
  if (url.startsWith('/')) return '$origin$url';
  return '$origin/$url';
}

bool _skipBootPrefetch(String url) {
  final lower = url.toLowerCase();
  return lower.contains('volvo_v60') || lower.contains('opel_astra');
}

void prefetchGlb(String url) {
  final abs = absoluteGlbUrl(url);
  if (abs.isEmpty || _skipBootPrefetch(abs) || !_warmed.add(abs)) return;
  try {
    final link = html.LinkElement()
      ..rel = 'preload'
      ..as = 'fetch'
      ..href = abs
      ..crossOrigin = 'anonymous';
    html.document.head?.append(link);
  } catch (_) {}
  try {
    html.window.fetch(abs, {
      'mode': 'cors',
      'credentials': 'omit',
      'cache': 'force-cache',
    });
  } catch (_) {}
}

String _modelViewerSrc() {
  final origin = html.window.location.origin;
  return '$origin/assets/packages/model_viewer_plus/assets/model-viewer.min.js';
}

String _srcDoc({
  required String modelUrl,
  required String modelLabel,
  required String cameraOrbit,
  required bool autoRotate,
  required bool telegram,
  String rotationPerSecond = 'pi/36 radians',
}) {
  final tapJs = glbCarTapBridgeJs();
  final paintJs = glbBlackGlossPaintJs;
  final scale = telegram ? 0.40 : 0.55;
  final perfJs = glbMobilePerfJs(
    minRenderScale: scale,
    highPerformance: !telegram,
  );
  final power = telegram ? 'low-power' : 'high-performance';
  final exposure = telegram ? '1.65' : '1.32';
  final shadow = telegram ? '0.28' : '0.16';
  final mvSrc = _modelViewerSrc();
  final spinJs = autoRotate ? 'true' : 'false';
  final spinAttr = autoRotate
      ? 'auto-rotate auto-rotate-delay="0"'
      : '';
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<link rel="preload" as="fetch" href="$modelUrl" crossorigin="anonymous">
<script>
self.ModelViewerElement = self.ModelViewerElement || {};
self.ModelViewerElement.powerPreference = '$power';
</script>
<script type="module" src="$mvSrc"></script>
<style>
  html,body,model-viewer,canvas,img,*{margin:0;-webkit-touch-callout:none!important;-webkit-user-select:none!important;user-select:none!important;-webkit-user-drag:none!important}
  html,body{width:100%;height:100%;background:#0A0A0C;overflow:hidden}
  model-viewer{width:100%;height:100%;background:transparent;--progress-bar-color:#C4CAD2;--progress-bar-height:2px;touch-action:none}
  $glbPaintHideCss
</style>
</head>
<body>
<model-viewer
  id="car"
  src="$modelUrl"
  alt="$modelLabel"
  loading="eager"
  reveal="manual"
  style="opacity:0"
  camera-controls
  touch-action="none"
  disable-tap
  disable-pan
  interaction-prompt="none"
  shadow-intensity="$shadow"
  shadow-softness="0.8"
  exposure="$exposure"
  tone-mapping="commerce"
  environment-image="neutral"
  interpolation-decay="90"
  camera-orbit="$cameraOrbit"
  camera-target="auto auto auto"
  min-camera-orbit="${GlbCarConfig.minCameraOrbit}"
  max-camera-orbit="${GlbCarConfig.maxCameraOrbit}"
  min-field-of-view="${GlbCarConfig.minFieldOfView}"
  max-field-of-view="${GlbCarConfig.maxFieldOfView}"
  rotation-per-second="$rotationPerSecond"
  $spinAttr
></model-viewer>
<script>
$glbNoSelectJs
$paintJs
$perfJs
$tapJs
(function () {
  var mv = document.getElementById('car');
  if (!mv) return;
  var done = false;
  function spin() {
    if (done) return;
    done = true;
    try { mv.style.setProperty('--progress-bar-height', '0px'); } catch (e) {}
    if ($spinJs) {
      try { mv.autoRotate = true; mv.autoRotateDelay = 0; } catch (e) {}
    }
  }
  mv.addEventListener('load', spin);
  mv.addEventListener('progress', function (ev) {
    try {
      if (ev.detail && ev.detail.totalProgress >= 0.98) spin();
    } catch (e) {}
  });
  try { if (mv.loaded) spin(); } catch (e) {}
})();
</script>
</body>
</html>
''';
}

Widget buildGlbCarViewer({
  Key? key,
  required String modelUrl,
  required String modelLabel,
  required String cameraOrbit,
  required bool autoRotate,
  String rotationPerSecond = 'pi/36 radians',
}) {
  final abs = absoluteGlbUrl(modelUrl);
  prefetchGlb(abs);
  final telegram = _inTelegram();
  final viewType =
      'glb-car-v18-$abs-${autoRotate ? 'spin' : 'static'}-$rotationPerSecond';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final doc = _srcDoc(
        modelUrl: abs,
        modelLabel: modelLabel,
        cameraOrbit: cameraOrbit,
        autoRotate: autoRotate,
        telegram: telegram,
        rotationPerSecond: rotationPerSecond,
      );
      // blob: keeps the Mini App origin (srcdoc is null-origin and breaks CORS).
      final blob = html.Blob([doc], 'text/html;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      return html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'transparent'
        ..allowFullscreen = true
        ..setAttribute('allow', 'webgl; xr-spatial-tracking')
        ..setAttribute('allowtransparency', 'true')
        ..setAttribute('loading', 'eager');
    });
  }
  return HtmlElementView(key: key, viewType: viewType);
}
