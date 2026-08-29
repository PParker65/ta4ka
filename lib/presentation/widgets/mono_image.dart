import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Luminance grayscale + slight lift — editorial B&W, not flat posterize.
const kMonoPhotoFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 8,
  0.2126, 0.7152, 0.0722, 0, 8,
  0.2126, 0.7152, 0.0722, 0, 8,
  0, 0, 0, 1, 0,
]);

/// Wrap any raster/photo widget — 3D GLB stages must NOT use this.
Widget monoPhoto(Widget child) {
  return ColorFiltered(colorFilter: kMonoPhotoFilter, child: child);
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return monoPhoto(
      Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      ),
    );
  }
}

class AppAssetImage extends StatelessWidget {
  const AppAssetImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.cacheWidth,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return monoPhoto(
      Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        cacheWidth: cacheWidth,
        errorBuilder: errorBuilder,
      ),
    );
  }
}

class AppMemoryImage extends StatelessWidget {
  const AppMemoryImage({
    super.key,
    required this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final Uint8List bytes;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return monoPhoto(
      Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
