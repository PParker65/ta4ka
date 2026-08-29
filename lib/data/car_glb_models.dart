import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'car_brands.dart';
import 'glb_cdn_config.dart';
import 'glb_remote_urls.dart';

/// Online GLB per brand (brand pick at entry drives the 3D model).
class CarGlbModel {
  const CarGlbModel({
    required this.assetPath,
    required this.label,
    this.cameraOrbit = '32deg 85deg 61%',
    this.modelColor,
  });

  final String assetPath;
  final String label;
  final String cameraOrbit;
  /// Paint color of the bundled GLB — drives buttons/borders in the Auto tab.
  final Color? modelColor;

  String get fileName => assetPath.split('/').last;

  /// Flutter web serves assets at /assets/assets/… (GLBs are not in the web build).
  String get webUrl => '/assets/assets/$assetPath';

  /// Native asset path (JPEG + optional quantization, no Draco — never CDN).
  String get flutterAsset => 'assets/$assetPath';

  /// Web Mini App: same-origin models. Phone: bundled Flutter asset.
  String get viewerSrc => kIsWeb ? webUrl : flutterAsset;

  /// HTTPS URL — fallback / web CDN.
  String get remoteUrl {
    final file = assetPath.split('/').last;
    return glbRemoteUrlForFile(file) ?? GlbCdnConfig.modelUrl(assetPath);
  }
}

const _bmw = CarGlbModel(
  assetPath: 'models/2023_bmw_m2_m-performance_parts_g87.glb',
  label: 'BMW M2 M Performance',
  modelColor: Color(0xFFD70200),
);

const _porsche = CarGlbModel(
  assetPath: 'models/2022_porsche_cayenne_turbo_gt.glb',
  label: 'Porsche Cayenne Turbo GT',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _mercedes = CarGlbModel(
  assetPath: 'models/2025_mercedes_g_class_amg_g63.glb',
  label: 'Mercedes-AMG G 63',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _volkswagen = CarGlbModel(
  assetPath: 'models/2025_volkswagen_golf_r_black_edition.glb',
  label: 'Volkswagen Golf R Black Edition',
  modelColor: Color(0xFF0D0D0D),
);

const _audi = CarGlbModel(
  assetPath: 'models/2018_audi_rs3_sportback.glb',
  label: 'Audi RS3 Sportback',
  modelColor: Color(0xFF0D0D0D),
);

const _mitsubishi = CarGlbModel(
  assetPath: 'models/mitsubishi_lancer_evolution_ix.glb',
  label: 'Mitsubishi Lancer Evolution IX',
  modelColor: Color(0xFF0D0D0D),
);

const _mini = CarGlbModel(
  assetPath: 'models/mini_cooper_s_facelift.glb',
  label: 'MINI Cooper S',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _ford = CarGlbModel(
  assetPath: 'models/1969_ford_mustang_mach-1_428_cobra_jet.glb',
  label: 'Ford Mustang Mach 1 428 Cobra Jet',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _jeep = CarGlbModel(
  assetPath: 'models/jeep_wrangler_rubicon.glb',
  label: 'Jeep Wrangler Rubicon',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _honda = CarGlbModel(
  assetPath: 'models/2021_honda_accord.glb',
  label: 'Honda Accord',
  modelColor: Color(0xFF0D0D0D),
);

const _tesla = CarGlbModel(
  assetPath: 'models/tesla_model_3.glb',
  label: 'Tesla Model 3',
  modelColor: Color(0xFF0D0D0D),
);

const _kia = CarGlbModel(
  assetPath: 'models/2023_kia_sportage_gt_line.glb',
  label: 'Kia Sportage GT-Line',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _lexus = CarGlbModel(
  assetPath: 'models/2020_lexus_lc.glb',
  label: 'Lexus LC',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _xiaomi = CarGlbModel(
  assetPath: 'models/2025_xiaomi_yu7.glb',
  label: 'Xiaomi YU7',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _toyota = CarGlbModel(
  assetPath: 'models/toyota_gr_supra.glb',
  label: 'Toyota GR Supra',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _zeekr = CarGlbModel(
  assetPath: 'models/zeekr_7x_2025.glb',
  label: 'Zeekr 7X',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _polestar = CarGlbModel(
  assetPath: 'models/polestar_1.glb',
  label: 'Polestar 1',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _opel = CarGlbModel(
  assetPath: 'models/opel_astra_l.glb',
  label: 'Opel Astra L',
  modelColor: Color(0xFF0D0D0D),
);

const _volvo = CarGlbModel(
  assetPath: 'models/2020_volvo_v60_t8_polestar_engineered.glb',
  label: 'Volvo V60 T8 Polestar Engineered',
  modelColor: Color(0xFF0D0D0D),
);

const _skoda = CarGlbModel(
  assetPath: 'models/2020_skoda_superb_tsi_380.glb',
  label: 'Škoda Superb TSI 380',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _mazda = CarGlbModel(
  assetPath: 'models/mazda_rx7.glb',
  label: 'Mazda RX-7',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _infiniti = CarGlbModel(
  assetPath: 'models/infiniti_q60_project_black_s.glb',
  label: 'Infiniti Q60 Project Black S',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _renault = CarGlbModel(
  assetPath: 'models/2006_renault_symbol_-_clio_sedan_-_thalia.glb',
  label: 'Renault Symbol',
  cameraOrbit: '32deg 85deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _nissan = CarGlbModel(
  assetPath: 'models/nissan_terra_2020.glb',
  label: 'Nissan Terra',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _hyundai = CarGlbModel(
  assetPath: 'models/2024_hyundai_ioniq_5_n.glb',
  label: 'Hyundai Ioniq 5 N',
  cameraOrbit: '32deg 82deg 57%',
  modelColor: Color(0xFF0D0D0D),
);

const _byBrandId = <String, CarGlbModel>{
  'bmw': _bmw,
  'porsche': _porsche,
  'mercedes': _mercedes,
  'volkswagen': _volkswagen,
  'audi': _audi,
  'mitsubishi': _mitsubishi,
  'mini': _mini,
  'ford': _ford,
  'jeep': _jeep,
  'honda': _honda,
  'tesla': _tesla,
  'kia': _kia,
  'lexus': _lexus,
  'xiaomi': _xiaomi,
  'toyota': _toyota,
  'zeekr': _zeekr,
  'polestar': _polestar,
  'opel': _opel,
  'volvo': _volvo,
  'skoda': _skoda,
  'mazda': _mazda,
  'infiniti': _infiniti,
  'renault': _renault,
  'nissan': _nissan,
  'hyundai': _hyundai,
};

/// Brands with a bundled GLB — shown first on the brand picker (main menu).
const glbBrandPickerOrder = [
  'bmw',
  'mercedes',
  'audi',
  'porsche',
  'volkswagen',
  'volvo',
  'opel',
  'skoda',
  'mazda',
  'infiniti',
  'renault',
  'nissan',
  'tesla',
  'polestar',
  'toyota',
  'xiaomi',
  'zeekr',
  'lexus',
  'ford',
  'jeep',
  'honda',
  'kia',
  'hyundai',
  'mitsubishi',
  'mini',
];

List<CarBrand> carBrandsWithGlbModels() {
  final seen = <String>{};
  final result = <CarBrand>[];
  for (final id in glbBrandPickerOrder) {
    if (!_byBrandId.containsKey(id) || !seen.add(id)) {
      continue;
    }
    result.add(carBrands.firstWhere((b) => b.id == id));
  }
  for (final id in _byBrandId.keys) {
    if (!seen.add(id)) {
      continue;
    }
    result.add(carBrands.firstWhere((b) => b.id == id));
  }
  return result;
}

CarGlbModel carGlbModelFor(CarBrand brand) => _byBrandId[brand.id] ?? _bmw;

CarGlbModel? carGlbModelForId(String id) => _byBrandId[id];

CarGlbModel? carGlbModelForAssetPath(String assetPath) {
  final needle = assetPath.startsWith('assets/')
      ? assetPath.substring(7)
      : assetPath;
  for (final model in _byBrandId.values) {
    if (model.assetPath == needle || model.flutterAsset == assetPath) {
      return model;
    }
  }
  return null;
}

/// UI accent for the Auto tab — matches the 3D model paint color.
Color carUiAccent(CarBrand brand) =>
    carGlbModelFor(brand).modelColor ?? brand.bodyColor;

/// Issue block under the car: chrome silver glow, on every brand.
const kAutoBlockAccent = Color(0xFFC4CAD2);

bool carBrandHasGlb(CarBrand brand) => _byBrandId.containsKey(brand.id);

String carGlbAssetFor(CarBrand brand) => carGlbModelFor(brand).flutterAsset;

String carGlbWebUrlFor(CarBrand brand) => carGlbModelFor(brand).remoteUrl;

String carGlbRemoteUrlFor(CarBrand brand) => carGlbModelFor(brand).remoteUrl;
