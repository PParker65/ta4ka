import 'package:flutter/painting.dart';

import 'shop_account.dart';
import 'shop_models.dart';
import '../../core/l10n/app_lang.dart';

/// Glyph language — from the works the shop actually offers.
enum ShopCraft { wrench, engine, chip, paint, chassis, bolt, wheel, drop }

/// Five title faces the owner can pick (iOS system families, no extra fonts).
enum ShopTitleFont { classic, avenir, serif, tech, futura }

class ShopBrand {
  const ShopBrand({
    required this.name,
    required this.initials,
    required this.word,
    required this.variant,
    required this.ornament,
    required this.font,
    required this.craft,
    required this.accent,
  });

  final String name;
  final String initials;
  /// 1–4 letters on the mark; owner can type this in the desk.
  final String word;
  final int variant; // 0..11
  final int ornament; // 0..5
  final ShopTitleFont font;
  final ShopCraft craft;
  final Color accent;

  static const canvas = Color(0xFF07070A);
  static const ink = Color(0xFFF4F4F6);
  static const variantCount = 12;

  static const accents = <Color>[
    Color(0xFFE8E8ED),
    Color(0xFF0A84FF),
    Color(0xFFFF9F0A),
    Color(0xFF30D158),
    Color(0xFFBF5AF2),
    Color(0xFFFF375F),
    Color(0xFF64D2FF),
    Color(0xFFFFD60A),
    Color(0xFFD4AF37),
    Color(0xFFAC8E68),
    Color(0xFFE85D4C),
    Color(0xFF5AC8FA),
    Color(0xFF7A9E9F),
    Color(0xFFAF52DE),
    Color(0xFF32ADE6),
    Color(0xFFC7C7CC),
  ];

  static ShopBrand resolve({
    required String name,
    required String seed,
    List<String> sphereIds = const [],
    List<String> workIds = const [],
    int? variant,
    int? font,
    String? word,
  }) {
    final trimmed = name.trim().isEmpty ? 'СТО' : name.trim();
    final h = Object.hash(seed, trimmed);
    final abs = h & 0x7fffffff;
    final rawWord = (word ?? '').trim().toUpperCase();
    final letters = _initials(trimmed);
    return ShopBrand(
      name: trimmed,
      initials: letters,
      word: rawWord.isEmpty
          ? letters
          : (rawWord.length <= 4 ? rawWord : rawWord.substring(0, 4)),
      variant: (variant ?? abs % variantCount).clamp(0, variantCount - 1),
      ornament: (abs ~/ 19) % 6,
      font: ShopTitleFont.values[((font ?? (abs ~/ 7)) % 5).clamp(0, 4)],
      craft: craftFrom(sphereIds: sphereIds, workIds: workIds),
      accent: accents[(abs ~/ 3) % accents.length],
    );
  }

  static ShopCraft craftFrom({
    List<String> sphereIds = const [],
    List<String> workIds = const [],
  }) {
    bool has(String key) {
      for (final id in sphereIds) {
        if (id.contains(key)) return true;
      }
      for (final id in workIds) {
        if (id.contains(key)) return true;
      }
      return false;
    }

    if (has('paint') || has('wrap') || has('carbon') || has('glass')) {
      return ShopCraft.paint;
    }
    if (has('coding') || has('diag') || has('electron')) return ShopCraft.chip;
    if (has('engine') || has('tuning') || has('exhaust') || has('stage')) {
      return ShopCraft.engine;
    }
    if (has('tire')) return ShopCraft.wheel;
    if (has('chassis') || has('brake') || has('align') || has('hydro')) {
      return ShopCraft.chassis;
    }
    if (has('tow')) return ShopCraft.wrench;
    if (has('battery') || has('electric')) return ShopCraft.bolt;
    if (has('service') || has('wash') || has('ac') || has('interior')) {
      return ShopCraft.drop;
    }
    return ShopCraft.wrench;
  }

  static String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'СТО';
    if (parts.length == 1) {
      final w = parts.first;
      return w.substring(0, w.length.clamp(1, 2)).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

String shopClientName(ShopProfile shop, ShopAccount account, AppLang lang) {
  if (shop.id == account.catalogShopId && account.shopName.trim().isNotEmpty) {
    return account.shopName.trim();
  }
  return shop.name.of(lang);
}

/// Owned desk uses the shop's own positioning setting; demo cards mix types.
ShopPositioning clientShopPositioning(ShopProfile shop, ShopAccount account) {
  if (shop.id == account.catalogShopId) {
    return ShopPositioning.resolve(account.positioning, seed: shop.id);
  }
  return shop.kind;
}

ShopBrand brandForShop({
  required ShopProfile shop,
  required ShopAccount account,
  required String displayName,
}) {
  final owned = shop.id == account.catalogShopId;
  return ShopBrand.resolve(
    name: displayName,
    seed: shop.id,
    sphereIds: owned ? account.sphereIds : const [],
    workIds: owned && account.offeredWorkIds.isNotEmpty
        ? account.offeredWorkIds
        : shop.workIds,
    variant: owned ? account.logoVariant : null,
    font: owned ? account.titleFont : null,
    word: owned && account.logoWord.trim().isNotEmpty ? account.logoWord : null,
  );
}

TextStyle shopTitleStyle(
  ShopBrand brand, {
  required double size,
  Color? color,
  FontWeight? weight,
}) {
  final c = color ?? ShopBrand.ink;
  final w = weight ?? FontWeight.w800;
  return switch (brand.font) {
    ShopTitleFont.classic => TextStyle(
        fontWeight: w,
        fontSize: size,
        color: c,
        letterSpacing: -0.35,
        height: 1.1,
      ),
    ShopTitleFont.avenir => TextStyle(
        fontFamily: 'Avenir Next',
        fontWeight: w,
        fontSize: size,
        color: c,
        letterSpacing: 0.2,
        height: 1.1,
      ),
    ShopTitleFont.serif => TextStyle(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: c,
        letterSpacing: -0.2,
        height: 1.12,
      ),
    ShopTitleFont.tech => TextStyle(
        fontFamily: 'Menlo',
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: c,
        letterSpacing: 0.4,
        height: 1.1,
      ),
    ShopTitleFont.futura => TextStyle(
        fontFamily: 'Futura',
        fontWeight: w,
        fontSize: size,
        color: c,
        letterSpacing: 1.1,
        height: 1.1,
      ),
  };
}
