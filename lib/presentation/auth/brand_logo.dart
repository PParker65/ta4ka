import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';
import '../../data/car_brands.dart';

/// Asset path for a real brand logo SVG.
String? brandLogoAsset(String brandId) {
  const known = {
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
    'mitsubishi',
    'mini',
    'hyundai',
  };
  if (!known.contains(brandId)) {
    return null;
  }
  return 'assets/brands/$brandId.svg';
}

/// Brand emblem in factory colours. Black silhouettes are already chrome in the SVG.
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    required this.brand,
    this.color,
    this.size = 22,
    this.forceTint = false,
  });

  final CarBrand brand;
  /// Optional fallback letter colour / forced tint when [forceTint] is true.
  final Color? color;
  final double size;
  /// Force a specific tint even in light theme.
  final bool forceTint;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final ink = color ?? palette.text;
    final asset = brandLogoAsset(brand.id);
    if (asset == null) {
      return Text(
        brand.id.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.7,
        ),
      );
    }
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: forceTint ? ColorFilter.mode(ink, BlendMode.srcIn) : null,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Text(
        brand.id.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.7,
        ),
      ),
    );
  }
}

/// Logo + brand name — factory emblem colours.
class BrandChipLabel extends StatelessWidget {
  const BrandChipLabel({
    super.key,
    required this.brand,
    required this.name,
    this.compact = false,
    this.selected = false,
    this.monoColor,
  });

  final CarBrand brand;
  final String name;
  final bool compact;
  final bool selected;
  final Color? monoColor;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final logoSize = compact ? 20.0 : 26.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize + 10,
          height: logoSize + 8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.55)
                  : palette.stroke.withValues(alpha: 0.7),
              width: selected ? 1.2 : 0.8,
            ),
            color: palette.surface.withValues(alpha: selected ? 0.95 : 0.72),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: BrandLogoMark(
            brand: brand,
            color: monoColor,
            size: logoSize,
            forceTint: monoColor != null,
          ),
        ),
        SizedBox(width: compact ? 7 : 9),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13.5 : 15,
              letterSpacing: -0.25,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}
