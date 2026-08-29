/// Public DOT traffic cameras over HLS — same protocol a real IP cam/NVR
/// exposes on iPhone. Unique stream per shop so we can compare load times.
class LiveCam {
  const LiveCam({
    required this.id,
    required this.titleUk,
    required this.titleEn,
    required this.titleRu,
    required this.place,
    required this.hlsUrl,
    required this.thumbUrl,
    this.quality = 'HLS',
  });

  final String id;
  final String titleUk;
  final String titleEn;
  final String titleRu;
  final String place;
  final String hlsUrl;
  final String thumbUrl;
  final String quality;

  String get host {
    final uri = Uri.tryParse(hlsUrl);
    return uri?.host ?? '';
  }

  String get hostShort {
    final h = host;
    const suffix = '.vdotcameras.com';
    if (h.endsWith(suffix)) {
      return h.substring(0, h.length - suffix.length);
    }
    return h;
  }

  String get camCode {
    final i = kLiveCams.indexWhere((c) => c.id == id);
    final n = i < 0 ? 1 : i + 1;
    return 'CAM-${n.toString().padLeft(2, '0')}';
  }
}

LiveCam _dot({
  required String id,
  required String cam,
  required String hostN,
  required String title,
  required String place,
}) {
  return LiveCam(
    id: id,
    titleUk: title,
    titleEn: title,
    titleRu: title,
    place: place,
    hlsUrl:
        'https://media-sfs$hostN.vdotcameras.com/rtplive/$cam/playlist.m3u8',
    thumbUrl: 'https://snapshot.vdotcameras.com/thumbs/$cam.flv.png',
    quality: 'HLS',
  );
}

final kLiveCams = <LiveCam>[
  const LiveCam(
    id: 'i66-mm50',
    titleUk: 'I-66 · MM 50.1',
    titleEn: 'I-66 · MM 50.1',
    titleRu: 'I-66 · MM 50.1',
    place: 'Fairfax',
    hlsUrl:
        'https://media-sfs8.vdotcameras.com/rtplive/NROCCTVI66E00501/playlist.m3u8',
    thumbUrl:
        'https://snapshot.vdotcameras.com/thumbs/NROCCTVI66E00501.flv.png',
  ),
  const LiveCam(
    id: 'i66-sycamore',
    titleUk: 'I-66 · Sycamore',
    titleEn: 'I-66 · Sycamore',
    titleRu: 'I-66 · Sycamore',
    place: 'Arlington',
    hlsUrl:
        'https://media-sfs3.vdotcameras.com/rtplive/4gha444cy6j4d8t7hoe63n5k7vme2r46/playlist.m3u8',
    thumbUrl:
        'https://snapshot.vdotcameras.com/thumbs/4gha444cy6j4d8t7hoe63n5k7vme2r46.flv.png',
  ),
  _dot(
    id: 'fairfax-univ',
    cam: '0i6a7bfbs60yq2lbgivq0b8xk3scij3c',
    hostN: '7',
    title: 'University Dr',
    place: 'Fairfax',
  ),
  _dot(
    id: 'arlington-sager',
    cam: '0wyvj6n16r826rz758qn5mf48ogpj1fp',
    hostN: '1',
    title: 'Sager Avenue',
    place: 'Arlington',
  ),
  _dot(
    id: 'rt50-patrick',
    cam: '0xeNZWRQ41OTW1NFGPzNz4o5W7aW9McR',
    hostN: '5',
    title: 'RT 50 · Patrick Henry',
    place: 'Fairfax',
  ),
  _dot(
    id: 'chain-bridge',
    cam: '1xs4a5sge2479r8f849r41mi62hgytl6',
    hostN: '2',
    title: 'Chain Bridge Rd',
    place: 'Fairfax',
  ),
  _dot(
    id: 'arlington-lee',
    cam: '7CUdhdU8754p6GUJZB8b4kbw1QMcqOW9',
    hostN: '4',
    title: 'Lee Hwy',
    place: 'Arlington',
  ),
  _dot(
    id: 'norfolk-tunnel',
    cam: 'ERCTV10',
    hostN: '6',
    title: 'Downtown Tunnel',
    place: 'Norfolk',
  ),
  _dot(
    id: 'lee-scott',
    cam: '248i6tdv9tp65068hlhrvhftfbv3bd50',
    hostN: '8',
    title: 'Lee Hwy · Scott',
    place: 'Arlington',
  ),
  _dot(
    id: 'us50-glebe',
    cam: '2umf2vg4agfmbgwwxyumoknf46ypx2pt',
    hostN: '3',
    title: 'US-50 · Glebe',
    place: 'Arlington',
  ),
  _dot(
    id: 'arlington-wb',
    cam: '4w5twz5gwff474y2o934g33t4z74uzzt',
    hostN: '2',
    title: 'Arlington CCTV',
    place: 'Arlington',
  ),
  _dot(
    id: 'fairfax-245',
    cam: 'FairfaxCCTV245',
    hostN: '8',
    title: 'Fairfax CCTV 245',
    place: 'Fairfax',
  ),
];

/// Same seed always maps to the same cam. Different seeds spread across the list.
LiveCam liveCamFor(String seed) {
  if (kLiveCams.isEmpty) {
    throw StateError('no live cams');
  }
  for (final cam in kLiveCams) {
    if (cam.id == seed) {
      return cam;
    }
  }
  return kLiveCams[_stableIndex(seed, kLiveCams.length)];
}

/// Demo mix: hash of shop id, never random per frame. Online shops keep a bound HLS URL.
bool shopBayCameraOnline(String shopId) {
  return _stableIndex(shopId, 2) == 0;
}

int _stableIndex(String seed, int n) {
  var h = 2166136261;
  for (final u in seed.codeUnits) {
    h ^= u;
    h = (h * 16777619) & 0x7fffffff;
  }
  h ^= h >> 16;
  h *= 0x7feb352d;
  h ^= h >> 15;
  return h.abs() % n;
}
