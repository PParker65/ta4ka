import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/car_brands.dart';
import '../../data/car_glb_models.dart';
import '../../data/glb_model_cache.dart';
import '../../data/car_hotspots.dart';
import '../../data/car_layout.dart';
import 'brand_logo.dart';
import 'glb_car_config.dart';
import 'glb_car_tap_bridge.dart';
import 'glb_car_viewer.dart' as glb_view;
import 'interactive_car.dart';

/// GLB viewer — brand at entry picks the 3D model (BMW / Porsche / Mercedes).
class GlbCarStage extends StatefulWidget {
  const GlbCarStage({
    super.key,
    required this.lang,
    required this.onSelect,
    required this.hint,
    this.selectedHotspotId,
    this.embedded = false,
    this.accentColor,
    this.brand,
    this.autoRotate = true,
    /// When false, rotation pauses but the WebView stays mounted (no reload).
    this.active = true,
    this.rotatePaused,
    this.onCarTap,
  });

  final AppLang lang;
  final String? selectedHotspotId;
  final String hint;
  final ValueChanged<CarHotspot> onSelect;
  final bool embedded;
  final Color? accentColor;
  final CarBrand? brand;
  final bool autoRotate;
  final bool active;
  final ValueListenable<bool>? rotatePaused;
  final VoidCallback? onCarTap;

  @override
  State<GlbCarStage> createState() => _GlbCarStageState();
}

class _GlbCarStageState extends State<GlbCarStage> {
  static const _yawOffset = 0.35;

  final _tapBridge = GlbCarTapBridge();
  final _webLoaded = ValueNotifier(false);
  Size _stageSize = Size.zero;
  double _bubbleYaw = 2.35;
  double _bubblePitch = 0.40;
  DateTime? _lastZoomHintAt;

  CarBrand get _brand => widget.brand ?? genericBrand;

  CarGlbModel get _glb => carGlbModelFor(_brand);

  @override
  void initState() {
    super.initState();
    _tapBridge.listen(
      _onExternalTap,
      onLoaded: () {
        if (!_webLoaded.value) _webLoaded.value = true;
      },
    );
  }

  @override
  void dispose() {
    _tapBridge.dispose();
    _webLoaded.dispose();
    super.dispose();
  }

  double _yawFromCamera(double theta) => -theta + math.pi + _yawOffset;

  double _pitchFromCamera(double phi) => (math.pi / 2 - phi).clamp(-0.28, 0.55);

  void _onExternalTap(GlbCarTapEvent event) {
    if (!mounted || _stageSize == Size.zero) {
      return;
    }
    final scaleX = _stageSize.width / event.size.width;
    final scaleY = _stageSize.height / event.size.height;
    _handleTap(
      local: Offset(event.local.dx * scaleX, event.local.dy * scaleY),
      size: _stageSize,
      theta: event.theta,
      phi: event.phi,
      zoomed: event.zoomed,
    );
  }

  void _showZoomHint() {
    final now = DateTime.now();
    if (_lastZoomHintAt != null && now.difference(_lastZoomHintAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastZoomHintAt = now;
    final s = AppStrings(widget.lang);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(s.aiCarZoomHint),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleTap({
    required Offset local,
    required Size size,
    required double theta,
    required double phi,
    required bool zoomed,
  }) {
    if (!zoomed) {
      _showZoomHint();
      return;
    }
    final yaw = _yawFromCamera(theta);
    final pitch = _pitchFromCamera(phi);
    final hit = hitTestCarHotspot(
      local: local,
      size: size,
      yaw: yaw,
      pitch: pitch,
      zoom: GlbCarConfig.projectionZoom,
      hotspots: placedHotspots(_brand),
      hitScale: GlbCarConfig.hitScale,
    );
    if (hit != null) {
      setState(() {
        _bubbleYaw = yaw;
        _bubblePitch = pitch;
      });
      widget.onSelect(hit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final accent = widget.accentColor ?? palette.accent;
    final placed = placedHotspots(_brand);
    CarHotspot? selected;
    for (final hotspot in placed) {
      if (hotspot.id == widget.selectedHotspotId) {
        selected = hotspot;
        break;
      }
    }

    final stage = _GlbStageBody(
      lang: widget.lang,
      accent: accent,
      brand: _brand,
      glb: _glb,
      selected: selected,
      selectedId: widget.selectedHotspotId,
      autoRotate: widget.autoRotate,
      active: widget.active,
      rotatePaused: widget.rotatePaused,
      bubbleYaw: _bubbleYaw,
      bubblePitch: _bubblePitch,
      webLoaded: _webLoaded,
            onLayout: (size) {
              if (_stageSize != size) {
                _stageSize = size;
              }
            },
      onMobileTap: kIsWeb ? null : _onExternalTap,
    );

    if (widget.embedded) {
      return stage;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      child: SizedBox.expand(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 0),
                child: Row(
                  children: [
                    Icon(Icons.view_in_ar, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.hint,
                        style: TextStyle(color: palette.muted, fontSize: 12, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: stage),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _MobileTapHandler = void Function(GlbCarTapEvent event);

class _GlbStageBody extends StatefulWidget {
  const _GlbStageBody({
    required this.lang,
    required this.accent,
    required this.brand,
    required this.glb,
    required this.selected,
    required this.selectedId,
    required this.autoRotate,
    required this.active,
    this.rotatePaused,
    required this.bubbleYaw,
    required this.bubblePitch,
    required this.onLayout,
    this.onMobileTap,
    this.webLoaded,
  });

  final AppLang lang;
  final Color accent;
  final CarBrand brand;
  final CarGlbModel glb;
  final CarHotspot? selected;
  final String? selectedId;
  final bool autoRotate;
  final bool active;
  final ValueListenable<bool>? rotatePaused;
  final double bubbleYaw;
  final double bubblePitch;
  final ValueChanged<Size> onLayout;
  final _MobileTapHandler? onMobileTap;
  final ValueListenable<bool>? webLoaded;

  @override
  State<_GlbStageBody> createState() => _GlbStageBodyState();
}

class _GlbStageBodyState extends State<_GlbStageBody> {
  Size? _laidOut;
  WebViewController? _webView;
  bool _modelReady = false;
  bool _viewerBooted = false;
  String? _modelSrc;
  int _loadGen = 0;
  Timer? _readyFallback;

  bool get _shouldRotate =>
      widget.autoRotate &&
      widget.active &&
      _modelReady &&
      !(widget.rotatePaused?.value ?? false);

  @override
  void initState() {
    super.initState();
    widget.rotatePaused?.addListener(_syncRotate);
    widget.webLoaded?.addListener(_onWebLoaded);
    if (widget.webLoaded?.value == true) {
      _modelReady = true;
    }
    _beginLoad();
    _readyFallback = Timer(const Duration(seconds: 8), () {
      if (!mounted || _modelReady) return;
      setState(() => _modelReady = true);
      _syncRotate();
    });
  }

  @override
  void didUpdateWidget(covariant _GlbStageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotatePaused != widget.rotatePaused) {
      oldWidget.rotatePaused?.removeListener(_syncRotate);
      widget.rotatePaused?.addListener(_syncRotate);
    }
    if (oldWidget.webLoaded != widget.webLoaded) {
      oldWidget.webLoaded?.removeListener(_onWebLoaded);
      widget.webLoaded?.addListener(_onWebLoaded);
      if (widget.webLoaded?.value == true) {
        _onModelLoaded();
      }
    }
    if (oldWidget.glb.assetPath != widget.glb.assetPath) {
      _modelReady = false;
      _webView = null;
      _viewerBooted = false;
      _modelSrc = null;
      _beginLoad();
    }
    _syncRotate();
  }

  void _beginLoad() {
    final glb = widget.glb;
    if (kIsWeb) {
      _modelSrc = glb.viewerSrc;
      _viewerBooted = true;
      return;
    }
    // Flutter asset key — model_viewer_plus serves it over http://127.0.0.1.
    // Do not wait on a file:// Application Support copy (WKWebView blocks that).
    _modelSrc = glb.flutterAsset;
    _viewerBooted = true;
    final gen = ++_loadGen;
    GlbModelCache.resolveSrc(glb).then((src) {
      if (!mounted || gen != _loadGen) return;
      if (src == _modelSrc) {
        GlbModelCache.precacheNeighbors(widget.brand.id);
        return;
      }
      setState(() => _modelSrc = src);
      GlbModelCache.precacheNeighbors(widget.brand.id);
    });
  }

  @override
  void dispose() {
    widget.rotatePaused?.removeListener(_syncRotate);
    widget.webLoaded?.removeListener(_onWebLoaded);
    _readyFallback?.cancel();
    super.dispose();
  }

  void _onWebLoaded() {
    if (widget.webLoaded?.value == true) {
      _onModelLoaded();
    }
  }

  void _syncRotate() {
    final on = _shouldRotate;
    _webView?.runJavaScript(
      'var mv=document.querySelector("model-viewer");if(mv)mv.autoRotate=$on;',
    );
  }

  void _onModelLoaded() {
    if (!mounted || _modelReady) return;
    _readyFallback?.cancel();
    setState(() => _modelReady = true);
    _syncRotate();
  }

  Set<JavascriptChannel> get _jsChannels => {
        JavascriptChannel(
          'CarTap',
          onMessageReceived: (msg) {
            try {
              final map = jsonDecode(msg.message) as Map<String, dynamic>;
              final type = map['type'];
              if (type == 'glb-loaded') {
                _onModelLoaded();
                return;
              }
              if (type != 'autoservice-car-tap' || widget.onMobileTap == null) {
                return;
              }
              widget.onMobileTap!(
                GlbCarTapEvent(
                  local: Offset(
                    (map['x'] as num).toDouble(),
                    (map['y'] as num).toDouble(),
                  ),
                  size: Size(
                    (map['w'] as num).toDouble(),
                    (map['h'] as num).toDouble(),
                  ),
                  theta: (map['theta'] as num).toDouble(),
                  phi: (map['phi'] as num).toDouble(),
                  zoomed: map['zoomed'] == true,
                ),
              );
            } catch (_) {}
          },
        ),
      };

  @override
  Widget build(BuildContext context) {
    const minScale = 0.5;
    final relatedJs = kIsWeb
        ? '${glbNoSelectJs}\n$glbBlackGlossPaintJs\n${glbCarTapBridgeJs()}'
        : '${glbNoSelectJs}\n$glbBlackGlossPaintJs\n${glbMobilePerfJs(minRenderScale: minScale, highPerformance: false)}\n${glbCarTapBridgeJs()}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_laidOut != size) {
          _laidOut = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onLayout(size);
          });
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            if (kIsWeb)
              glb_view.buildGlbCarViewer(
                key: ValueKey('${widget.glb.assetPath}-spin'),
                modelUrl: widget.glb.viewerSrc,
                modelLabel: widget.glb.label,
                cameraOrbit: widget.glb.cameraOrbit,
                autoRotate: widget.autoRotate,
                rotationPerSecond: 'pi/36 radians',
              )
            else if (_viewerBooted && _modelSrc != null)
              ModelViewer(
                key: ValueKey(_modelSrc),
                src: _modelSrc!,
                alt: widget.glb.label,
                loading: Loading.eager,
                reveal: Reveal.manual,
                backgroundColor: Colors.transparent,
                cameraControls: true,
                disableTap: true,
                disablePan: true,
                disableZoom: false,
                touchAction: TouchAction.none,
                interactionPrompt: InteractionPrompt.none,
                autoRotate: widget.autoRotate,
                autoRotateDelay: 0,
                rotationPerSecond: 'pi/36 radians',
                cameraOrbit: widget.glb.cameraOrbit,
                minCameraOrbit: GlbCarConfig.minCameraOrbit,
                maxCameraOrbit: GlbCarConfig.maxCameraOrbit,
                minFieldOfView: GlbCarConfig.minFieldOfView,
                maxFieldOfView: GlbCarConfig.maxFieldOfView,
                cameraTarget: 'auto auto auto',
                interpolationDecay: 120,
                shadowIntensity: 0.18,
                shadowSoftness: 0.9,
                exposure: 1.28,
                environmentImage: 'neutral',
                relatedCss: '$glbNoSelectCss$glbPaintHideCss',
                relatedJs: relatedJs,
                javascriptChannels: _jsChannels,
                onWebViewCreated: (controller) {
                  _webView = controller;
                  controller.runJavaScript(glbNoSelectJs);
                },
                debugLogging: false,
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.18),
                      radius: 1.05,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_modelReady)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: paletteOf(context).bg,
                  ),
                ),
              ),
            IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _BrandStageEmblem(
                    brand: widget.brand,
                    ready: _modelReady,
                    parkCorner: kIsWeb,
                  ),
                  if (!_modelReady)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 118),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.selected != null)
              _GlbHintBubble(
                lang: widget.lang,
                size: size,
                hotspot: widget.selected!,
                accent: widget.accent,
                yaw: widget.bubbleYaw,
                pitch: widget.bubblePitch,
                zoom: GlbCarConfig.projectionZoom,
              ),
          ],
        );
      },
    );
  }
}

class _BrandStageEmblem extends StatefulWidget {
  const _BrandStageEmblem({
    required this.brand,
    required this.ready,
    this.parkCorner = false,
  });

  final CarBrand brand;
  final bool ready;
  final bool parkCorner;

  @override
  State<_BrandStageEmblem> createState() => _BrandStageEmblemState();
}

class _BrandStageEmblemState extends State<_BrandStageEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fly;

  static const _fromSize = 92.0;
  /// A bit larger than Cupertino tab icons (~25–28).
  static const _toSize = 34.0;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    if (widget.ready) _fly.value = 1;
  }

  @override
  void didUpdateWidget(covariant _BrandStageEmblem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !_fly.isCompleted) {
      _fly.forward();
    } else if (!widget.ready && _fly.value != 0) {
      _fly.value = 0;
    }
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parkCorner) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 0, 0),
          child: AnimatedOpacity(
            opacity: widget.ready ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: BrandLogoMark(brand: widget.brand, size: _toSize),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _fly,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_fly.value);
        final size = _fromSize + (_toSize - _fromSize) * t;
        final align = Alignment.lerp(
          Alignment.center,
          Alignment.topLeft,
          t,
        )!;
        final pad = EdgeInsets.lerp(
          EdgeInsets.zero,
          const EdgeInsets.fromLTRB(14, 12, 0, 0),
          t,
        )!;
        return Align(
          alignment: align,
          child: Padding(
            padding: pad,
            child: BrandLogoMark(brand: widget.brand, size: size),
          ),
        );
      },
    );
  }
}

class _GlbHintBubble extends StatelessWidget {
  const _GlbHintBubble({
    required this.lang,
    required this.size,
    required this.hotspot,
    required this.accent,
    required this.yaw,
    required this.pitch,
    required this.zoom,
  });

  final AppLang lang;
  final Size size;
  final CarHotspot hotspot;
  final Color accent;
  final double yaw;
  final double pitch;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final target = projectCarPoint(
      point: hotspot.pos,
      yaw: yaw,
      pitch: pitch,
      zoom: zoom,
      origin: Offset(size.width / 2, size.height * kCarStageOriginY),
    ).offset;

    const pad = 8.0;
    final phone = size.width < 700;
    final bubbleW = math.min(phone ? 200.0 : 228.0, math.max(132.0, size.width - pad * 2));
    final bubbleH = phone ? 86.0 : 96.0;
    const gap = 14.0;
    final pinned = Offset(
      target.dx.clamp(pad, math.max(pad, size.width - pad)),
      target.dy.clamp(pad, math.max(pad, size.height - pad)),
    );
    final roomAbove = pinned.dy - pad >= bubbleH + gap;
    final below = !roomAbove;
    var left = pinned.dx - bubbleW / 2;
    var top = below ? pinned.dy + gap : pinned.dy - bubbleH - gap;
    left = left.clamp(pad, math.max(pad, size.width - bubbleW - pad));
    top = top.clamp(pad, math.max(pad, size.height - bubbleH - pad));
    final onBubbleX = pinned.dx.clamp(left + 18, left + bubbleW - 18);
    final anchor = Offset(onBubbleX, below ? top : top + bubbleH);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: size,
          painter: _GlbHintLeaderPainter(from: anchor, to: pinned, color: accent),
        ),
        Positioned(
          left: left,
          top: top,
          width: bubbleW,
          child: IgnorePointer(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                phone ? 10 : 12,
                phone ? 8 : 10,
                phone ? 10 : 12,
                phone ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.75)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hotspot.label.of(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: phone ? 13 : 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: phone ? 3 : 4),
                  Text(
                    hotspot.hint.of(lang),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w500,
                      fontSize: phone ? 12 : 15,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlbHintLeaderPainter extends CustomPainter {
  _GlbHintLeaderPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if ((from - to).distance < 6) {
      return;
    }
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(to, 3.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GlbHintLeaderPainter oldDelegate) {
    return oldDelegate.from != from || oldDelegate.to != to || oldDelegate.color != color;
  }
}
