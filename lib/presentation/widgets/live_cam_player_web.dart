// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../data/live_cams.dart';

final _registered = <String>{};
final _liveVideos = <String, html.VideoElement>{};

void _kickPlay(html.VideoElement video) {
  try {
    video.muted = true;
    video.defaultMuted = true;
    video.volume = 0;
    video.play().then((_) {}, onError: (_) {});
  } catch (_) {}
}

void _attachStream(html.VideoElement video, String url) {
  final native = video.canPlayType('application/vnd.apple.mpegurl');
  if (native.isNotEmpty) {
    video.src = url;
    _kickPlay(video);
    return;
  }
  final id = 'apex-hls-${identityHashCode(video)}';
  video.id = id;
  final escaped = url.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  html.document.head!.append(
    html.ScriptElement()
      ..text = '''
(function(){
  var v=document.getElementById("$id");
  if(!v) return;
  if(window.apexAttachHls){window.apexAttachHls(v,'$escaped');return;}
  v.src='$escaped';
  try{v.muted=true;v.play();}catch(e){}
})();
''',
  );
}

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
  late String _viewType;
  Timer? _kick;
  StreamSubscription<html.Event>? _vis;

  @override
  void initState() {
    super.initState();
    _viewType = 'live-hls-${widget.cam.id}-${identityHashCode(this)}';
    _register();
    _kick = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final video = _liveVideos[_viewType];
      if (video != null) _kickPlay(video);
    });
    _vis = html.document.onVisibilityChange.listen((_) {
      final video = _liveVideos[_viewType];
      if (html.document.hidden != true && video != null) {
        _kickPlay(video);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final video = _liveVideos[_viewType];
      if (video != null) _kickPlay(video);
    });
  }

  @override
  void didUpdateWidget(covariant LiveCamPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cam.hlsUrl != widget.cam.hlsUrl) {
      _viewType = 'live-hls-${widget.cam.id}-${identityHashCode(this)}';
      _register();
    }
  }

  void _register() {
    if (!_registered.add(_viewType)) {
      return;
    }
    final url = widget.cam.hlsUrl;
    final radius = widget.compact ? '16px' : '20px';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..defaultMuted = true
        ..loop = true
        ..controls = false
        ..preload = 'auto'
        ..setAttribute('muted', '')
        ..setAttribute('autoplay', '')
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('data-apex-live', '1')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = radius;
      video.onCanPlay.listen((_) => _kickPlay(video));
      video.onLoadedData.listen((_) => _kickPlay(video));
      video.onPause.listen((_) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          _kickPlay(video);
        });
      });
      _attachStream(video, url);
      _liveVideos[_viewType] = video;
      final wrap = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.borderRadius = radius
        ..style.pointerEvents = 'none';
      wrap.append(video);
      return wrap;
    });
  }

  @override
  void dispose() {
    _kick?.cancel();
    _vis?.cancel();
    _liveVideos.remove(_viewType);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
