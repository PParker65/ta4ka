/// Shared camera + interaction tuning for the BMW GLB stage.
abstract final class GlbCarConfig {
  /// Front-left, slightly lowered — car «leaning» toward the viewer.
  static const cameraOrbit = '32deg 85deg 61%';
  /// Close zoom (pinch / wheel) + full yaw spin. Tight phi keeps the car upright.
  static const minCameraOrbit = 'auto 55deg 22%';
  static const maxCameraOrbit = 'Infinity 105deg 220%';
  static const minFieldOfView = '8deg';
  static const maxFieldOfView = '45deg';

  /// Projection zoom for hotspot hit-test / hint bubble anchoring.
  static const projectionZoom = 2.01;

  /// Hotspot radius multiplier — lower = must tap closer to the part center.
  static const hitScale = 0.68;

  /// Camera must be this much closer than the default framing to allow hints.
  static const zoomRatioForHint = 0.76;
}

/// WebGL cost: Fold / flagship can use high-performance + higher scale.
String glbMobilePerfJs({
  double minRenderScale = 0.55,
  bool highPerformance = true,
}) => '''
(function () {
  self.ModelViewerElement = self.ModelViewerElement || {};
  self.ModelViewerElement.powerPreference = '${highPerformance ? 'high-performance' : 'low-power'}';
  function applyScale() {
    try {
      var MV = customElements.get('model-viewer');
      if (MV) {
        MV.minimumRenderScale = $minRenderScale;
      }
    } catch (e) {}
  }
  if (window.customElements) {
    customElements.whenDefined('model-viewer').then(applyScale);
  }
  applyScale();
  setTimeout(applyScale, 400);
  setTimeout(applyScale, 1200);
})();
''';

/// Hide the canvas until body paint is applied — kills the original-color flash.
const glbPaintHideCss = '''
html,body{background:#0A0A0C!important}
model-viewer{opacity:0!important;transition:opacity .18s ease}
model-viewer.apex-painted{opacity:1!important}
''';

/// Body paint after load — black gloss for every brand except BMW M2.
/// M2 is Lion red #D70200; Ta4ka? vinyl wrap stays baked. Kidney / bumper kit stay black.
/// model_viewer_plus has no color API; textures ignore CSS/exposure tint,
/// so we set PBR factors via the model-viewer scene graph after load.
/// Viewer stays opacity 0 until paint finishes, then fades in.
const glbBlackGlossPaintJs = r'''
(function () {
  var PAINT = /paint|pintura|carpaint|car_paint|car_body|kuzov|new_color|astral_paint|coloured|smallspecmap|\bprimary\b|paintsecondary|car_paint_bai|gaolianghei|gloss_black|default1/;
  var SKIP = /glass|window|windo|vidro|light|lamp|lens|tire|tyre|pneu|rubber|interior|leather|seat|chrome|mirror|wheel|\brim\b|caliper|calliper|grille|grill|carbon|engine|badge|plate|chassis|fabric|carpet|wood|display|speaker|brake|cabin|dash|int_|neishi|luntai|reflector|indicator|signal|glow|emiss|deng|plastic|plas_|fabric|carpet/;
  var shown = false;
  function nameOf(m) {
    try { return String(m.name || '').toLowerCase(); } catch (e) { return ''; }
  }
  function skipName(n) {
    return SKIP.test(n) && !/paint/.test(n);
  }
  function isM2(mv) {
    try {
      var s = String((mv.src || '') + ' ' + (mv.getAttribute ? (mv.getAttribute('src') || '') : '') + ' ' + (mv.alt || ''));
      return /bmw_m2|m2_m-performance|m-performance_parts_g87|m2 m performance/i.test(s);
    } catch (e) { return false; }
  }
  function chromatic(m) {
    try {
      var f = m.pbrMetallicRoughness.baseColorFactor;
      if (!f || f.length < 3) return false;
      var a = f.length > 3 ? f[3] : 1;
      if (a < 0.95) return false;
      var r = f[0], g = f[1], b = f[2];
      var mx = Math.max(r, g, b), mn = Math.min(r, g, b);
      return mx > 0.08 && (mx - mn) > 0.08;
    } catch (e) { return false; }
  }
  function paintOne(m, rgb) {
    try {
      var pbr = m.pbrMetallicRoughness;
      pbr.setBaseColorFactor([rgb[0], rgb[1], rgb[2], 1]);
      pbr.setMetallicFactor(0.95);
      pbr.setRoughnessFactor(0.22);
      try {
        if (pbr.baseColorTexture && pbr.baseColorTexture.setTexture) {
          pbr.baseColorTexture.setTexture(null);
        }
      } catch (e) {}
      try {
        if (pbr.metallicRoughnessTexture && pbr.metallicRoughnessTexture.setTexture) {
          pbr.metallicRoughnessTexture.setTexture(null);
        }
      } catch (e) {}
    } catch (e) {}
  }
  function apply(mv) {
    try {
      var model = mv.model;
      if (!model || !model.materials) return false;
      var m2 = isM2(mv);
      var rgbBlack = [0.039, 0.039, 0.039];
      var rgbRed = [215/255, 2/255, 0];
      var mats = model.materials;
      for (var i = 0; i < mats.length; i++) {
        var m = mats[i];
        var n = nameOf(m);
        if (/apex_wrap_film|apex_wrap_door|apex_wrap_hood|apex_door_badge/.test(n)) continue;
        try { if (m.alphaMode === 'BLEND') continue; } catch (e) {}
        if (m2) {
          if (/grille|grill|coloured/.test(n)) {
            paintOne(m, rgbBlack);
          } else if (/paint|apex_wrap_carbon|apex_wrap_roof/.test(n)) {
            paintOne(m, rgbRed);
          }
          continue;
        }
        if (skipName(n)) continue;
        if (PAINT.test(n) || chromatic(m)) paintOne(m, rgbBlack);
      }
      return true;
    } catch (e) { return false; }
  }
  function hide(mv) {
    try {
      mv.style.opacity = '0';
      mv.classList.remove('apex-painted');
    } catch (e) {}
  }
  function reveal(mv) {
    if (shown) return;
    shown = true;
    try { if (mv.dismissPoster) mv.dismissPoster(); } catch (e) {}
    try {
      mv.classList.add('apex-painted');
      mv.style.opacity = '1';
    } catch (e) {}
    try {
      if (typeof CarTap !== 'undefined') {
        CarTap.postMessage(JSON.stringify({type: 'glb-loaded'}));
      }
    } catch (e) {}
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(JSON.stringify({type: 'glb-loaded'}), '*');
      }
    } catch (e) {}
  }
  function finish(mv) {
    apply(mv);
    requestAnimationFrame(function () {
      requestAnimationFrame(function () { reveal(mv); });
    });
  }
  function hook() {
    var mv = document.querySelector('model-viewer');
    if (!mv) { setTimeout(hook, 80); return; }
    hide(mv);
    try { mv.setAttribute('reveal', 'manual'); } catch (e) {}
    function go() { finish(mv); }
    mv.addEventListener('load', go);
    try { if (mv.loaded) go(); } catch (e) {}
    setTimeout(function () { apply(mv); }, 400);
    setTimeout(function () { if (!shown) finish(mv); }, 3500);
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', hook);
  } else {
    hook();
  }
})();
''';

/// Kill iOS long-press Copy / Look Up overlay on the 3D canvas.
const glbNoSelectCss = '''
html,body,model-viewer,canvas,img,*{
  -webkit-touch-callout:none!important;
  -webkit-user-select:none!important;
  user-select:none!important;
  -webkit-user-drag:none!important;
  -webkit-tap-highlight-color:transparent!important;
}
''';

const glbNoSelectJs = r'''
(function () {
  function block(e) { e.preventDefault(); e.stopPropagation(); }
  document.addEventListener('contextmenu', block, true);
  document.addEventListener('selectstart', block, true);
  document.addEventListener('dragstart', block, true);
  function paint(root) {
    try {
      var s = document.createElement('style');
      s.textContent = '*{-webkit-touch-callout:none!important;-webkit-user-select:none!important;user-select:none!important;-webkit-user-drag:none!important}';
      (root.head || root).appendChild(s);
    } catch (e) {}
    try {
      var nodes = root.querySelectorAll ? root.querySelectorAll('canvas,img') : [];
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].style.webkitTouchCallout = 'none';
        nodes[i].style.webkitUserSelect = 'none';
        nodes[i].setAttribute('draggable', 'false');
      }
    } catch (e) {}
  }
  function patch() {
    paint(document);
    var mv = document.querySelector('model-viewer');
    if (mv && mv.shadowRoot) paint(mv.shadowRoot);
  }
  patch();
  setTimeout(patch, 200);
  setTimeout(patch, 800);
  setTimeout(patch, 2000);
})();
''';

/// JS snippet: forwards taps with zoom flag (used in iframe + native WebView).
String glbCarTapBridgeJs({double zoomRatio = GlbCarConfig.zoomRatioForHint}) => '''
(function () {
  function send(payload) {
    var json = JSON.stringify(payload);
    if (typeof CarTap !== 'undefined') {
      CarTap.postMessage(json);
    }
    try { if (window.parent && window.parent !== window) window.parent.postMessage(json, '*'); } catch (e) {}
    try { window.postMessage(json, '*'); } catch (e) {}
  }
  function hook() {
    var mv = document.querySelector('model-viewer');
    if (!mv) {
      setTimeout(hook, 180);
      return;
    }
    var baseRadius = null;
    function onLoaded() {
      try { baseRadius = mv.getCameraOrbit().radius; } catch (e) {}
    }
    mv.addEventListener('load', onLoaded);
    try { if (mv.loaded) onLoaded(); } catch (e) {}
    setTimeout(function () {
      if (!baseRadius) baseRadius = mv.getCameraOrbit().radius;
    }, 800);
    mv.addEventListener('click', function (event) {
      var rect = mv.getBoundingClientRect();
      var orbit = mv.getCameraOrbit();
      var zoomed = baseRadius && orbit.radius < baseRadius * $zoomRatio;
      send({
        type: 'autoservice-car-tap',
        x: event.clientX - rect.left,
        y: event.clientY - rect.top,
        w: rect.width,
        h: rect.height,
        theta: orbit.theta,
        phi: orbit.phi,
        radius: orbit.radius,
        zoomed: !!zoomed
      });
    });
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', hook);
  } else {
    hook();
  }
})();
''';
