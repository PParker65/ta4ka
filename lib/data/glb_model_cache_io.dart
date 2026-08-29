import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'car_glb_models.dart';

/// Resolves a ModelViewer `src` that WKWebView can actually load.
///
/// model_viewer_plus binds a loopback HTTP proxy and maps `/model` to either
/// a Flutter asset key (`assets/models/foo.glb`) or a local file. The WebView
/// itself only ever fetches `http://127.0.0.1:port/model` — never a raw
/// `file://` URL.
///
/// We therefore return the Flutter asset key. A previous `file://` copy into
/// Application Support broke iOS: the path contains a space, and WKWebView /
/// ATS will not load those URLs even when the proxy tries to open the file.
class GlbModelCache {
  GlbModelCache._();

  static const _cacheFolder = 'glb_cache_v14';
  static final _inflight = <String, Future<String>>{};
  static Directory? _dir;

  static Future<Directory> _cacheDir() async {
    final existing = _dir;
    if (existing != null) return existing;
    // tmp has no space in the path (unlike "Application Support").
    final root = await getTemporaryDirectory();
    final dir = Directory(p.join(root.path, _cacheFolder));
    await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  /// ModelViewer `src`: Flutter asset key on success, `file://` tmp copy only
  /// if the asset bundle is missing the GLB.
  static Future<String> resolveSrc(CarGlbModel glb) {
    return _inflight.putIfAbsent(glb.assetPath, () => _resolve(glb));
  }

  static Future<String> _resolve(CarGlbModel glb) async {
    try {
      final data = await rootBundle.load(glb.flutterAsset);
      if (data.lengthInBytes > 64) {
        unawaited(_mirrorToTmp(glb, data));
        return glb.flutterAsset;
      }
    } catch (_) {}

    try {
      final file = File(p.join((await _cacheDir()).path, glb.fileName));
      if (await file.exists() && await file.length() > 64) {
        return Uri.file(file.path).toString();
      }
    } catch (_) {}

    return glb.flutterAsset;
  }

  static Future<void> _mirrorToTmp(CarGlbModel glb, ByteData data) async {
    try {
      final file = File(p.join((await _cacheDir()).path, glb.fileName));
      if (await file.exists() && await file.length() == data.lengthInBytes) {
        return;
      }
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    } catch (_) {}
  }

  static void precacheUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return;
    final assetPath = url.startsWith('assets/') ? url.substring(7) : url;
    final glb = carGlbModelForAssetPath(assetPath);
    if (glb != null) {
      unawaited(resolveSrc(glb));
    }
  }

  /// Warm the previous + next brands in picker order after the selected car.
  static void precacheNeighbors(String brandId) {
    final order = glbBrandPickerOrder;
    final i = order.indexOf(brandId);
    if (i < 0) return;
    final ids = <String>[];
    if (i + 1 < order.length) ids.add(order[i + 1]);
    if (i > 0) ids.add(order[i - 1]);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 500), () async {
        for (final id in ids) {
          if (id == brandId) continue;
          final glb = carGlbModelForId(id);
          if (glb != null) {
            await resolveSrc(glb);
          }
        }
      }),
    );
  }
}
