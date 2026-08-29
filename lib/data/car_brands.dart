import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/l10n/app_lang.dart';

enum CarShape { sportSedan, hatch, luxurySedan, wagon, coupe, suv, ev }

enum EngineKind { v8, i4, i6, boxer, electric }

class CarBrand {
  const CarBrand({
    required this.id,
    required this.name,
    required this.flagship,
    required this.aliases,
    required this.bodyColor,
    required this.shape,
    this.kidneys = false,
    this.engineRear = false,
    required this.exterior,
    required this.interior,
    required this.engine,
    required this.wheel,
  });

  final String id;
  final L name;
  final L flagship;
  final List<String> aliases;
  final Color bodyColor;
  final CarShape shape;
  final bool kidneys;
  final bool engineRear;
  final String exterior;
  final String interior;
  final String engine;
  final String wheel;

  EngineKind get engineKind {
    if (shape == CarShape.ev) {
      return EngineKind.electric;
    }
    if (engineRear) {
      return EngineKind.boxer;
    }
    if (id == 'bmw' || id == 'audi' || id == 'ford' || id == 'mercedes') {
      return EngineKind.v8;
    }
    if (shape == CarShape.suv || shape == CarShape.luxurySedan) {
      return EngineKind.i6;
    }
    return EngineKind.i4;
  }

  int get wheelSpokes {
    if (id == 'bmw' || id == 'audi') {
      return 5;
    }
    if (id == 'mercedes') {
      return 10;
    }
    if (id == 'porsche') {
      return 10;
    }
    return 8;
  }

  int get exhaustTips {
    if (shape == CarShape.ev) {
      return 0;
    }
    if (id == 'bmw' || id == 'audi') {
      return 4;
    }
    return 2;
  }

  CarBrand copyWith({Color? bodyColor}) {
    return CarBrand(
      id: id,
      name: name,
      flagship: flagship,
      aliases: aliases,
      bodyColor: bodyColor ?? this.bodyColor,
      shape: shape,
      kidneys: kidneys,
      engineRear: engineRear,
      exterior: exterior,
      interior: interior,
      engine: engine,
      wheel: wheel,
    );
  }

  String imageForSphere(String sphereId) {
    switch (sphereId) {
      case 'interior':
      case 'ac':
      case 'hydro':
      case 'electronics':
      case 'coding':
      case 'diag':
        return interior;
      case 'engine':
      case 'stage3':
      case 'tuning':
      case 'service':
      case 'exhaust':
        return engine;
      case 'tires':
      case 'align':
      case 'brakes':
      case 'chassis':
        return wheel;
      default:
        return exterior;
    }
  }
}

/// Contrasting label/icon on a filled [CarBrand.bodyColor] button.
Color onCarBodyColor(Color body) {
  return body.computeLuminance() > 0.52 ? const Color(0xFF111111) : Colors.white;
}

const carBrands = <CarBrand>[
  CarBrand(
    id: 'bmw',
    name: L('BMW', 'BMW', 'BMW'),
    flagship: L('M5', 'M5', 'M5'),
    aliases: [
      'bmw', 'бмв', 'бээмвэ', 'бмвшка', 'beemer', 'bimmer', 'm5', 'м5', 'бм',
    ],
    bodyColor: Color(0xFF1A8F5B),
    shape: CarShape.sportSedan,
    kidneys: true,
    exterior: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'mini',
    name: L('MINI', 'MINI', 'MINI'),
    flagship: L('Cooper S', 'Cooper S', 'Cooper S'),
    aliases: ['mini', 'мини', 'minicooper', 'cooper', 'купер', 'cooper s'],
    bodyColor: Color(0xFF1C3254),
    shape: CarShape.hatch,
    exterior: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'volkswagen',
    name: L('Volkswagen', 'Volkswagen', 'Volkswagen'),
    flagship: L('Golf R Black Edition', 'Golf R Black Edition', 'Golf R Black Edition'),
    aliases: [
      'volkswagen', 'volksvagen', 'wolkswagen', 'volcvagen', 'vw',
      'фольксваген', 'фольцваген', 'вольцваген', 'вольксваген', 'фолцваген',
      'фольц', 'вольц', 'фолькс', 'волькс', 'гольф', 'golf', 'фольксваґен',
    ],
    bodyColor: Color(0xFFD7DCE1),
    shape: CarShape.hatch,
    exterior: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'opel',
    name: L('Opel', 'Opel', 'Opel'),
    flagship: L('Astra L', 'Astra L', 'Astra L'),
    aliases: ['opel', 'опель', 'astra', 'астра', 'corsa', 'корса'],
    bodyColor: Color(0xFF1E3A5F),
    shape: CarShape.hatch,
    exterior: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'mercedes',
    name: L('Mercedes-Benz', 'Mercedes-Benz', 'Mercedes-Benz'),
    flagship: L('G 63 AMG', 'G 63 AMG', 'G 63 AMG'),
    aliases: [
      'mercedes', 'mersedes', 'мерседес', 'мерс', 'benz', 'бенц', 'mb', 'amg', 'g63', 'g-class',
    ],
    bodyColor: Color(0xFFC5C5C5),
    shape: CarShape.suv,
    exterior: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1617531653520-bd4660a70986?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1487754180451-c7f7d85a62ef?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  ),
  CarBrand(
    id: 'audi',
    name: L('Audi', 'Audi', 'Audi'),
    flagship: L('RS3 Sportback', 'RS3 Sportback', 'RS3 Sportback'),
    aliases: ['audi', 'ауди', 'ауді', 'rs3', 'рс3', 'rs6', 'рс6'],
    bodyColor: Color(0xFF4A4E52),
    shape: CarShape.hatch,
    exterior: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e762?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'toyota',
    name: L('Toyota', 'Toyota', 'Toyota'),
    flagship: L('GR Supra', 'GR Supra', 'GR Supra'),
    aliases: ['toyota', 'тойота', 'supra', 'супра', 'gr supra', 'camry', 'камрі', 'камри', 'lc', 'крузер'],
    bodyColor: Color(0xFF8B0000),
    shape: CarShape.coupe,
    exterior: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'porsche',
    name: L('Porsche', 'Porsche', 'Porsche'),
    flagship: L('Cayenne Turbo GT', 'Cayenne Turbo GT', 'Cayenne Turbo GT'),
    aliases: ['porsche', 'порше', 'порш', '911', 'porshe', 'cayenne', 'кайен', 'каен'],
    bodyColor: Color(0xFFC4A35A),
    shape: CarShape.suv,
    engineRear: false,
    exterior: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1494976388531-d1058494a1e?w=900&q=80',
  ),
  CarBrand(
    id: 'tesla',
    name: L('Tesla', 'Tesla', 'Tesla'),
    flagship: L('Model 3', 'Model 3', 'Model 3'),
    aliases: ['tesla', 'тесла', 'model s', 'model 3', 'модел 3', 'модель 3'],
    bodyColor: Color(0xFFE10600),
    shape: CarShape.ev,
    exterior: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  ),
  CarBrand(
    id: 'skoda',
    name: L('Škoda', 'Skoda', 'Skoda'),
    flagship: L('Fabia RS WRC', 'Fabia RS WRC', 'Fabia RS WRC'),
    aliases: ['skoda', 'škoda', 'шкода', 'octavia', 'октавія', 'октавия', 'fabia', 'фабia', 'фабия'],
    bodyColor: Color(0xFF1A472A),
    shape: CarShape.hatch,
    exterior: 'https://images.unsplash.com/photo-1610647752706-3bb12232b3ab?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1487754180451-c7f7d85a62ef?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'hyundai',
    name: L('Hyundai', 'Hyundai', 'Hyundai'),
    flagship: L('Ioniq 5', 'Ioniq 5', 'Ioniq 5'),
    aliases: ['hyundai', 'хюндай', 'хундай', 'хюндаї', 'ioniq'],
    bodyColor: Color(0xFF2E6B8A),
    shape: CarShape.ev,
    exterior: 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  ),
  CarBrand(
    id: 'kia',
    name: L('Kia', 'Kia', 'Kia'),
    flagship: L('Sportage GT-Line', 'Sportage GT-Line', 'Sportage GT-Line'),
    aliases: ['kia', 'киа', 'кіа', 'ev6', 'sportage', 'спортейдж', 'gt-line'],
    bodyColor: Color(0xFF1C1C1E),
    shape: CarShape.suv,
    exterior: 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'renault',
    name: L('Renault', 'Renault', 'Renault'),
    flagship: L('Twingo GT', 'Twingo GT', 'Twingo GT'),
    aliases: ['renault', 'рено', 'megane', 'меган', 'twingo', 'твинго'],
    bodyColor: Color(0xFF1A1A1A),
    shape: CarShape.hatch,
    exterior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'ford',
    name: L('Ford', 'Ford', 'Ford'),
    flagship: L('F-150 Raptor R', 'F-150 Raptor R', 'F-150 Raptor R'),
    aliases: [
      'ford', 'форд', 'mustang', 'мустанг', 'focus', 'фокус',
      'raptor', 'раптор', 'f150', 'f-150', 'f 150', 'пикап',
    ],
    bodyColor: Color(0xFF1E3A5F),
    shape: CarShape.suv,
    exterior: 'https://images.unsplash.com/photo-1494976388531-d1058494a1e?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'jeep',
    name: L('Jeep', 'Jeep', 'Jeep'),
    flagship: L('Wrangler Rubicon', 'Wrangler Rubicon', 'Wrangler Rubicon'),
    aliases: [
      'jeep', 'джип', 'джeep', 'wrangler', 'ранглер', 'rubicon', 'рубикон',
      'cherokee', 'шероки', 'grand cherokee',
    ],
    bodyColor: Color(0xFF2D5016),
    shape: CarShape.suv,
    exterior: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58dd?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'mitsubishi',
    name: L('Mitsubishi', 'Mitsubishi', 'Mitsubishi'),
    flagship: L('Lancer Evolution IX', 'Lancer Evolution IX', 'Lancer Evolution IX'),
    aliases: [
      'mitsubishi', 'митсубиси', 'мitsubishi', 'lancer', 'лансер', 'evo', 'эво', 'evolution',
    ],
    bodyColor: Color(0xFFE8ECEF),
    shape: CarShape.sportSedan,
    exterior: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'mazda',
    name: L('Mazda', 'Mazda', 'Mazda'),
    flagship: L('RX-7', 'RX-7', 'RX-7'),
    aliases: ['mazda', 'мазда', 'mx5', 'mx-5', 'rx7', 'rx-7', 'рх7'],
    bodyColor: Color(0xFF8B1E1E),
    shape: CarShape.coupe,
    exterior: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'honda',
    name: L('Honda', 'Honda', 'Honda'),
    flagship: L('Accord', 'Accord', 'Accord'),
    aliases: ['honda', 'хонда', 'civic', 'сівик', 'сивик', 'accord', 'аккорд', 'акорд'],
    bodyColor: Color(0xFF8B0000),
    shape: CarShape.sportSedan,
    exterior: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'volvo',
    name: L('Volvo', 'Volvo', 'Volvo'),
    flagship: L('S90 Recharge', 'S90 Recharge', 'S90 Recharge'),
    aliases: ['volvo', 'вольво', 'xc90', 's90', 'recharge'],
    bodyColor: Color(0xFF4B5D6B),
    shape: CarShape.luxurySedan,
    exterior: 'https://images.unsplash.com/photo-1610647752706-3bb12232b3ab?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'lexus',
    name: L('Lexus', 'Lexus', 'Lexus'),
    flagship: L('LC', 'LC', 'LC'),
    aliases: ['lexus', 'лексус', 'lx', 'lc', 'lc500', 'лс'],
    bodyColor: Color(0xFF1C1C1E),
    shape: CarShape.coupe,
    exterior: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1487754180451-c7f7d85a62ef?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  ),
  CarBrand(
    id: 'infiniti',
    name: L('Infiniti', 'Infiniti', 'Infiniti'),
    flagship: L('Q60 Project Black S', 'Q60 Project Black S', 'Q60 Project Black S'),
    aliases: ['infiniti', 'инфiniti', 'инфинити', 'финик', 'q60', 'qx'],
    bodyColor: Color(0xFF0D0D0D),
    shape: CarShape.coupe,
    exterior: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
  CarBrand(
    id: 'nissan',
    name: L('Nissan', 'Nissan', 'Nissan'),
    flagship: L('Terra', 'Terra', 'Terra'),
    aliases: ['nissan', 'нissan', 'нисан', 'terra', 'тerra', 'patrol', 'патруль', 'x-trail'],
    bodyColor: Color(0xFF1A1A1A),
    shape: CarShape.suv,
    exterior: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1625047509168-a7026f0de883?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
  ),
  CarBrand(
    id: 'xiaomi',
    name: L('Xiaomi', 'Xiaomi', 'Xiaomi'),
    flagship: L('YU7', 'YU7', 'YU7'),
    aliases: ['xiaomi', 'сяоми', 'ксиаоми', 'шaomi', 'yu7', 'ю7', 'su7'],
    bodyColor: Color(0xFF2B2B2B),
    shape: CarShape.ev,
    exterior: 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  ),
  CarBrand(
    id: 'zeekr',
    name: L('Zeekr', 'Zeekr', 'Zeekr'),
    flagship: L('7X', '7X', '7X'),
    aliases: ['zeekr', 'зикр', 'зикер', 'zeeker', '7x', '001', '009'],
    bodyColor: Color(0xFF1A1A1A),
    shape: CarShape.suv,
    exterior: 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  ),
  CarBrand(
    id: 'polestar',
    name: L('Polestar', 'Polestar', 'Polestar'),
    flagship: L('1', '1', '1'),
    aliases: ['polestar', 'полстар', 'полестар', 'pole star', 'ps1', 'polestar 1'],
    bodyColor: Color(0xFFBFC5C9),
    shape: CarShape.coupe,
    exterior: 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=900&q=80',
    interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
    engine: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900&q=80',
    wheel: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=900&q=80',
  ),
];

const genericBrand = CarBrand(
  id: 'other',
  name: L('Camaro SS', 'Camaro SS', 'Camaro SS'),
  flagship: L('1967', '1967', '1967'),
  aliases: ['camaro', 'chevy', 'chevrolet', 'шевроле', 'камаро'],
  bodyColor: Color(0xFF1E3A5F),
  shape: CarShape.coupe,
  exterior: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=900&q=80',
  interior: 'https://images.unsplash.com/photo-1542362567-b07e54358753?w=900&q=80',
  engine: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=900&q=80',
  wheel: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900&q=80',
);

String _latinize(String input) {
  const map = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'ґ': 'g', 'д': 'd', 'е': 'e',
    'є': 'e', 'ж': 'zh', 'з': 'z', 'и': 'y', 'і': 'i', 'ї': 'i', 'й': 'i',
    'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r',
    'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c', 'ч': 'ch',
    'ш': 'sh', 'щ': 'sch', 'ь': '', 'ю': 'yu', 'я': 'ya', 'ы': 'y', 'э': 'e',
    'ъ': '', 'ё': 'e',
  };
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

int _levenshtein(String a, String b) {
  if (a == b) {
    return 0;
  }
  if (a.isEmpty) {
    return b.length;
  }
  if (b.isEmpty) {
    return a.length;
  }
  final rows = List.generate(a.length + 1, (i) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    rows[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    rows[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      rows[i][j] = math.min(
        math.min(rows[i - 1][j] + 1, rows[i][j - 1] + 1),
        rows[i - 1][j - 1] + cost,
      );
    }
  }
  return rows[a.length][b.length];
}

int _brandScore(CarBrand brand, String raw) {
  final q = _latinize(raw);
  if (q.isEmpty) {
    return 0;
  }
  var best = 0;
  for (final alias in [...brand.aliases, brand.id, brand.name.uk, brand.name.en, brand.name.ru]) {
    final a = _latinize(alias);
    if (a.isEmpty) {
      continue;
    }
    if (a == q) {
      best = math.max(best, 100);
    } else if (a.startsWith(q) || q.startsWith(a)) {
      best = math.max(best, 80 + math.min(q.length, 10));
    } else if (a.contains(q) && q.length >= 3) {
      best = math.max(best, 60);
    } else if (q.length >= 5) {
      final d = _levenshtein(a, q);
      if (d <= 2) {
        best = math.max(best, 70 - d * 10);
      }
    }
  }
  return best;
}

List<CarBrand> matchCarBrands(String query, {int limit = 6}) {
  final q = query.trim();
  if (q.isEmpty) {
    return carBrands.take(limit).toList();
  }
  final scored = [
    for (final brand in carBrands)
      (brand: brand, score: _brandScore(brand, q)),
  ]..sort((a, b) => b.score.compareTo(a.score));
  return [
    for (final item in scored)
      if (item.score > 0) item.brand,
  ].take(limit).toList();
}

CarBrand resolveCarBrand(String query) {
  final matches = matchCarBrands(query, limit: 1);
  if (matches.isEmpty) {
    return genericBrand;
  }
  return matches.first;
}
