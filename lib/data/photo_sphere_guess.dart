import 'dart:typed_data';
import 'dart:ui' as ui;

import '../core/l10n/app_lang.dart';

/// Local photo → category guess when the remote AI is offline.
class PhotoSphereGuess {
  const PhotoSphereGuess({
    required this.sphereIds,
    required this.summary,
  });

  final List<String> sphereIds;
  final L summary;
}

Future<PhotoSphereGuess> guessSpheresFromPhoto(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 64,
    targetHeight: 64,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  codec.dispose();
  if (raw == null) {
    return _visualDamage;
  }

  final px = raw.buffer.asUint8List();
  final n = px.length ~/ 4;
  if (n == 0) {
    return _visualDamage;
  }

  var dark = 0;
  var orange = 0;
  var yellow = 0;
  var red = 0;
  var rubber = 0;
  var beige = 0;
  var chrome = 0;
  var glass = 0;
  var satSum = 0.0;
  var lumSum = 0.0;

  for (var i = 0; i < px.length; i += 4) {
    final r = px[i];
    final g = px[i + 1];
    final b = px[i + 2];
    final a = px[i + 3];
    if (a < 24) {
      continue;
    }
    final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final sat = maxc == 0 ? 0.0 : (maxc - minc) / maxc;
    lumSum += lum;
    satSum += sat;
    if (lum < 42) {
      dark++;
    }
    if (r > 160 && g > 70 && g < 185 && b < 85 && sat > 0.38) {
      orange++;
    }
    if (r > 175 && g > 155 && b < 95) {
      yellow++;
    }
    if (r > 150 && g < 85 && b < 85 && sat > 0.4) {
      red++;
    }
    if (lum < 48 && sat < 0.18) {
      rubber++;
    }
    if (lum > 80 && lum < 190 && sat < 0.32 && r > 135 && g > 105 && b > 75) {
      beige++;
    }
    if (sat < 0.16 && lum > 90 && lum < 205) {
      chrome++;
    }
    if (b > r && b > g && lum > 85) {
      glass++;
    }
  }

  final meanLum = lumSum / n;
  final meanSat = satSum / n;
  final dash = (orange + yellow) / n;
  final darkShare = dark / n;
  final rubberShare = rubber / n;
  final beigeShare = beige / n;
  final chromeShare = chrome / n;
  final redShare = red / n;
  final glassShare = glass / n;

  if (dash > 0.06 && darkShare > 0.28) {
    return const PhotoSphereGuess(
      sphereIds: ['diag', 'electronics', 'engine'],
      summary: L(
        'На фото схоже на панель або лампочку — почніть з діагностики.',
        'This looks like a dashboard or warning light — start with diagnostics.',
        'На фото похоже на панель или лампочку — начните с диагностики.',
        'To wygląda na deskę lub kontrolkę — zacznij od diagnostyki.',
      ),
    );
  }
  if (rubberShare > 0.22 && chromeShare > 0.08) {
    return const PhotoSphereGuess(
      sphereIds: ['tires', 'rims', 'brakes', 'align'],
      summary: L(
        'Схоже на колесо або гуму — шини, диски або гальма.',
        'Looks like a wheel or tyre — tyres, rims or brakes.',
        'Похоже на колесо или резину — шины, диски или тормоза.',
        'Wygląda na koło lub oponę — opony, felgi lub hamulce.',
      ),
    );
  }
  if (beigeShare > 0.18 && meanLum > 70) {
    return const PhotoSphereGuess(
      sphereIds: ['interior', 'chem-clean', 'soundproof'],
      summary: L(
        'Схоже на салон — хімчистка або ремонт інтерʼєру.',
        'Looks like the cabin — interior clean or trim repair.',
        'Похоже на салон — химчистка или ремонт интерьера.',
        'Wygląda na wnętrze — czyszczenie lub naprawa tapicerki.',
      ),
    );
  }
  if (redShare > 0.07 && meanSat > 0.28) {
    return const PhotoSphereGuess(
      sphereIds: ['lights', 'brakes', 'electronics'],
      summary: L(
        'Схоже на фару або стоп — світло або електрика.',
        'Looks like a lamp or brake light — lighting or electrics.',
        'Похоже на фару или стоп — свет или электрика.',
        'Wygląda na lampę lub stop — światła albo elektryka.',
      ),
    );
  }
  if (glassShare > 0.12 && meanLum > 90) {
    return const PhotoSphereGuess(
      sphereIds: ['glass', 'adas'],
      summary: L(
        'Схоже на скло — скол, тріщина або заміна.',
        'Looks like glass — a chip, crack or replacement.',
        'Похоже на стекло — скол, трещина или замена.',
        'Wygląda na szybę — odprysk, pęknięcie albo wymiana.',
      ),
    );
  }
  return _visualDamage;
}

const _visualDamage = PhotoSphereGuess(
  sphereIds: ['body', 'paint', 'pdr', 'bumper'],
  summary: L(
    'По фото схоже на кузов — рихтовка, фарба або вмʼятина.',
    'The photo looks like bodywork — dent, paint or bumper.',
    'По фото похоже на кузов — рихтовка, краска или бампер.',
    'Zdjęcie wygląda na karoserię — wgniecenie, lakier lub zderzak.',
  ),
);
