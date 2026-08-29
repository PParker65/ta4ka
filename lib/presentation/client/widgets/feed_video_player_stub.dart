import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

final _pauseHooks = <VoidCallback>{};

void pauseAllFeedVideos() {
  for (final hook in List<VoidCallback>.from(_pauseHooks)) {
    hook();
  }
}

void resumeApexLiveVideos() {}

/// Native (Android / iOS) feed player — asset or network MP4.
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({
    super.key,
    required this.url,
    required this.play,
    this.posterUrl,
    this.assetPath,
  });

  final String url;
  final bool play;
  final String? posterUrl;
  /// e.g. `assets/feed/bay_walkin.mp4`
  final String? assetPath;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  String? _boundKey;

  String get _key =>
      (widget.assetPath != null && widget.assetPath!.isNotEmpty)
          ? 'a:${widget.assetPath}'
          : 'u:${widget.url}';

  @override
  void initState() {
    super.initState();
    _pauseHooks.add(_hardPause);
    if (widget.play) {
      _ensureController();
    }
  }

  void _hardPause() {
    final c = _controller;
    if (c == null) return;
    c.pause();
    c.setVolume(0);
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.play) {
      _controller?.pause();
      _controller?.setVolume(0);
      return;
    }
    if (_boundKey != _key) {
      _disposeController();
      _ensureController();
    } else {
      _controller?.setVolume(1);
      _controller?.play();
    }
  }

  Future<void> _ensureController() async {
    final asset = widget.assetPath;
    final VideoPlayerController next;
    if (asset != null && asset.isNotEmpty) {
      next = VideoPlayerController.asset(asset);
    } else if (widget.url.isNotEmpty) {
      next = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    } else {
      return;
    }
    _boundKey = _key;
    _controller = next;
    try {
      await next.initialize();
      await next.setLooping(true);
      await next.setVolume(1);
      if (mounted && widget.play) {
        await next.play();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _boundKey = null;
  }

  @override
  void dispose() {
    _pauseHooks.remove(_hardPause);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (!widget.play || c == null || !c.value.isInitialized) {
      return _Poster(posterUrl: widget.posterUrl);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({this.posterUrl});

  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    final url = posterUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(color: Color(0xFF1C1C1E));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1C1C1E)),
    );
  }
}
