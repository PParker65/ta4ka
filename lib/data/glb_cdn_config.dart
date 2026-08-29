/// Remote GLB hosting — models are not bundled in the mobile APK.
///
/// Deploy `assets/models/` to any static host (Netlify, Cloudflare Pages, VPS)
/// using the same path layout as Flutter web:
/// `{baseUrl}/assets/assets/models/<file>.glb`
///
/// Build APK with:
/// `--dart-define=GLB_CDN_BASE=https://your-domain.com`
class GlbCdnConfig {
  GlbCdnConfig._();

  static const baseUrl = String.fromEnvironment(
    'GLB_CDN_BASE',
    defaultValue: 'https://autoshift-glb.netlify.app',
  );

  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Full HTTPS (or HTTP) URL for a model file.
  static String modelUrl(String assetPath) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/assets/assets/$assetPath';
  }
}
