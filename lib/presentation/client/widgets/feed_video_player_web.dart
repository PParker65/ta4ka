// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final _videos = <String, html.VideoElement>{};
final _registered = <String>{};

void _silence(html.VideoElement video) {
  try {
    video.pause();
    video.muted = true;
    video.volume = 0;
  } catch (_) {}
}

void pauseAllFeedVideos() {
  for (final video in _videos.values) {
    _silence(video);
  }
  for (final node in html.document.querySelectorAll('video[data-apex-feed="1"]')) {
    _silence(node as html.VideoElement);
  }
}

void resumeApexLiveVideos() {
  for (final node in html.document.querySelectorAll('video[data-apex-live="1"]')) {
    final video = node as html.VideoElement;
    try {
      video.muted = true;
      video.volume = 0;
      video.play().then((_) {}, onError: (_) {});
    } catch (_) {}
  }
}

/// HTML5 MP4 with sound. If autoplay-with-audio is blocked, tap the speaker icon.
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
  final String? assetPath;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late final String _viewType;
  bool _needsTapForSound = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'fv-snd-${widget.url.hashCode}';
    if (_registered.add(_viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
        final v = html.VideoElement()
          ..src = widget.url
          ..autoplay = false
          ..muted = false
          ..loop = true
          ..controls = false
          ..setAttribute('playsinline', 'true')
          ..setAttribute('webkit-playsinline', 'true')
          ..setAttribute('data-apex-feed', '1')
          ..poster = widget.posterUrl ?? ''
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        _videos[_viewType] = v;
        return v;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayback();
  }

  html.VideoElement? get _video => _videos[_viewType];

  Future<void> _syncPlayback() async {
    var video = _video;
    if (video == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      video = _video;
    }
    if (video == null) {
      return;
    }
    if (!widget.play || widget.url.isEmpty) {
      _silence(video);
      try {
        video.currentTime = 0;
      } catch (_) {}
      return;
    }
    try {
      video.muted = false;
      await video.play();
      if (mounted) {
        setState(() => _needsTapForSound = false);
      }
    } catch (_) {
      try {
        video.muted = true;
        await video.play();
        if (mounted) {
          setState(() => _needsTapForSound = true);
        }
      } catch (_) {}
    }
  }

  Future<void> _enableSound() async {
    final video = _video;
    if (video == null) {
      return;
    }
    video.muted = false;
    try {
      await video.play();
    } catch (_) {}
    if (mounted) {
      setState(() => _needsTapForSound = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return _Poster(posterUrl: widget.posterUrl);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (!widget.play) _Poster(posterUrl: widget.posterUrl),
        if (widget.play && _needsTapForSound)
          Positioned(
            right: 16,
            bottom: 120,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: _enableSound,
                borderRadius: BorderRadius.circular(28),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    CupertinoIcons.speaker_slash_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
      ],
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
