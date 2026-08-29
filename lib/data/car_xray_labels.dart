import '../core/l10n/app_lang.dart';
import 'car_brands.dart';
import 'car_hotspots.dart';
import 'car_layout.dart';

class XrayLabel {
  const XrayLabel({
    required this.id,
    required this.title,
    required this.anchor,
    this.align = 'auto',
  });

  final String id;
  final String title;
  final Vec3 anchor;
  final String align;

  Map<String, String> toJson() => {'id': id, 'title': title, 'align': align};
}

List<XrayLabel> ghostCallouts(AppLang lang) {
  String t(String uk, String en, String ru) => L(uk, en, ru).of(lang);
  const l = CarLayout.ghost;
  return [
    XrayLabel(
      id: 'engine',
      title: t('V8 Twin-Turbo', 'V8 Twin-Turbo Engine', 'V8 Twin-Turbo'),
      anchor: Vec3(l.engineX, 34, 0),
    ),
    XrayLabel(
      id: 'turbo',
      title: t('Турбокомпресор', 'Turbocharger', 'Турбокомпрессор'),
      anchor: Vec3(l.engineX + 2, 30, 16),
    ),
    XrayLabel(
      id: 'trans',
      title: t('Коробка передач', 'Transmission', 'Коробка передач'),
      anchor: Vec3(l.engineX - 24, 22, 0),
    ),
    XrayLabel(
      id: 'xdrive',
      title: t('Повний привід', 'Active All-Wheel Drive', 'Полный привод'),
      anchor: const Vec3(8, 14, 0),
    ),
    XrayLabel(
      id: 'diff-f',
      title: t('Передній редуктор', 'Front differential', 'Передний редуктор'),
      anchor: Vec3(l.wheelFY - 4, 14, 0),
    ),
    XrayLabel(
      id: 'brake-fr',
      title: t('Карбон-кераміка', 'Carbon-ceramic brake', 'Карбон-керамика'),
      anchor: Vec3(l.wheelFY, l.ride + 2, l.halfW * 0.62),
    ),
    XrayLabel(
      id: 'undercarriage',
      title: t('Адаптивна підвіска', 'Adaptive suspension', 'Адаптивная подвеска'),
      anchor: Vec3(l.wheelFY - 8, 28, l.halfW * 0.55),
    ),
    XrayLabel(
      id: 'seat-l',
      title: t('Спорткрісла', 'Performance seats', 'Спорткресла'),
      anchor: Vec3((l.cabinF + l.cabinR) / 2 + 4, 30, -12),
    ),
    XrayLabel(
      id: 'roof',
      title: t('Карбон дах', 'Carbon roof', 'Карбон крыша'),
      anchor: Vec3((l.cabinF + l.cabinR) / 2, l.roof + 2, 0),
    ),
    XrayLabel(
      id: 'fuel',
      title: t('Паливний бак', 'Fuel cell', 'Топливный бак'),
      anchor: Vec3(l.cabinR - 8, 20, 0),
    ),
    XrayLabel(
      id: 'diff-r',
      title: t('Задній редуктор', 'Rear differential', 'Задний редуктор'),
      anchor: Vec3(l.wheelRY + 4, 14, 0),
    ),
    XrayLabel(
      id: 'exhaust',
      title: t('Вихлопна система', 'Exhaust system', 'Выхлопная система'),
      anchor: Vec3(l.rear + 18, 11, 14),
    ),
  ];
}

List<XrayLabel> xrayLabelsFor(CarBrand _, AppLang lang) => ghostCallouts(lang);

String xrayHotspotAlias(String id) {
  switch (id) {
    case 'turbo':
    case 'trans':
    case 'fuel':
    case 'diff-f':
      return 'engine';
    case 'xdrive':
    case 'diff-r':
      return 'undercarriage';
    default:
      return id;
  }
}

CarHotspot? resolveXrayHotspot(String id) {
  return hotspotById(xrayHotspotAlias(id)) ?? hotspotById(id);
}
