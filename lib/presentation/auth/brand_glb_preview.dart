import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../data/car_brands.dart';
import '../../data/car_glb_models.dart';
import 'glb_car_config.dart';
import 'glb_car_viewer.dart' as glb_view;

/// Spinning zoomable 3D car for one brand (picker showroom + Auto tab).
class BrandGlbPreview extends StatelessWidget {
  const BrandGlbPreview({
    super.key,
    required this.brand,
    this.autoRotate = true,
  });

  final CarBrand brand;
  final bool autoRotate;

  @override
  Widget build(BuildContext context) {
    final glb = carGlbModelFor(brand);
    if (kIsWeb) {
      return glb_view.buildGlbCarViewer(
        key: ValueKey('pick-${glb.assetPath}'),
        modelUrl: glb.viewerSrc,
        modelLabel: glb.label,
        cameraOrbit: glb.cameraOrbit,
        autoRotate: autoRotate,
        rotationPerSecond: 'pi/28 radians',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 48 || constraints.maxHeight < 48) {
          return const SizedBox.expand();
        }
        return ModelViewer(
          key: ValueKey(glb.viewerSrc),
          src: glb.viewerSrc,
          alt: glb.label,
          loading: Loading.eager,
          reveal: Reveal.manual,
          backgroundColor: Colors.transparent,
          cameraControls: true,
          disableTap: true,
          disablePan: true,
          disableZoom: false,
          touchAction: TouchAction.none,
          interactionPrompt: InteractionPrompt.none,
          autoRotate: autoRotate,
          autoRotateDelay: 0,
          rotationPerSecond: 'pi/28 radians',
          cameraOrbit: glb.cameraOrbit,
          minCameraOrbit: GlbCarConfig.minCameraOrbit,
          maxCameraOrbit: GlbCarConfig.maxCameraOrbit,
          minFieldOfView: GlbCarConfig.minFieldOfView,
          maxFieldOfView: GlbCarConfig.maxFieldOfView,
          interpolationDecay: 120,
          shadowIntensity: 0.16,
          exposure: 1.28,
          environmentImage: 'neutral',
          relatedCss: '$glbNoSelectCss$glbPaintHideCss',
          relatedJs:
              '${glbNoSelectJs}\n$glbBlackGlossPaintJs\n${glbMobilePerfJs(minRenderScale: 0.62, highPerformance: true)}',
        );
      },
    );
  }
}
