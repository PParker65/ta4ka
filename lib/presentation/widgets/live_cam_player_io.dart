import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/live_cams.dart';

class LiveCamPlayer extends StatefulWidget {
  const LiveCamPlayer({
    super.key,
    required this.cam,
    this.compact = false,
  });

  final LiveCam cam;
  final bool compact;

  @override
  State<LiveCamPlayer> createState() => _LiveCamPlayerState();
}

class _LiveCamPlayerState extends State<LiveCamPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(covariant LiveCamPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cam.hlsUrl != widget.cam.hlsUrl) {
      _boot();
    }
  }

  Future<void> _boot() async {
    _disposeController();
    final next = VideoPlayerController.networkUrl(
      Uri.parse(widget.cam.hlsUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = next;
    _failed = false;
    _ready = false;
    next.addListener(_onTick);
    try {
      await next.initialize();
      await next.setVolume(0);
      await next.setLooping(true);
      if (!mounted || _controller != next) {
        await next.dispose();
        return;
      }
      await next.play();
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (_) {
      if (mounted && _controller == next) {
        setState(() => _failed = true);
      }
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) {
      return;
    }
    if (c.value.hasError && !_failed) {
      setState(() => _failed = true);
    }
  }

  void _disposeController() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _controller = null;
    _ready = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _Offline(host: widget.cam.host);
    }
    final c = _controller;
    if (c == null || !_ready || !c.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _Snap(url: widget.cam.thumbUrl),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }
    final size = c.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return _Snap(url: widget.cam.thumbUrl);
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: IgnorePointer(child: VideoPlayer(c)),
        ),
      ),
    );
  }
}

class _Snap extends StatelessWidget {
  const _Snap({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xFF1C1C1E));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1C1C1E)),
    );
  }
}

class _Offline extends StatelessWidget {
  const _Offline({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1C1C1E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            host.isEmpty ? 'CAM offline' : '$host\noffline',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB0B0B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
