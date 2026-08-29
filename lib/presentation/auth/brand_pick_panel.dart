import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/car_brands.dart';
import '../../data/car_glb_models.dart';
import 'brand_logo.dart';

class BrandPickPanel extends StatefulWidget {
  const BrandPickPanel({
    super.key,
    required this.query,
    required this.lang,
    required this.strings,
    required this.onConfirm,
  });

  final TextEditingController query;
  final AppLang lang;
  final AppStrings strings;
  final ValueChanged<CarBrand> onConfirm;

  @override
  State<BrandPickPanel> createState() => _BrandPickPanelState();
}

class _BrandPickPanelState extends State<BrandPickPanel>
    with SingleTickerProviderStateMixin {
  /// Shared 1s inhale / 1s exhale clock — every mark beats together.
  late final AnimationController _heartbeat;

  @override
  void initState() {
    super.initState();
    widget.query.addListener(_onQuery);
    _heartbeat = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    widget.query.removeListener(_onQuery);
    _heartbeat.dispose();
    super.dispose();
  }

  void _onQuery() => setState(() {});

  List<CarBrand> get _matches {
    final q = widget.query.text.trim();
    if (q.isEmpty) {
      return carBrandsWithGlbModels();
    }
    return matchCarBrands(widget.query.text, limit: 50).where(carBrandHasGlb).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final palette = paletteOf(context);
    final phone = isPhoneLayout(context);
    final s = widget.strings;
    final columns = phone ? 3 : 4;

    return Padding(
      padding: EdgeInsets.fromLTRB(phone ? 14 : 22, 0, phone ? 14 : 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.aiBrandTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.text,
              fontSize: phone ? 22 : 26,
              fontWeight: FontWeight.w600,
              height: 1.08,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.query,
            style: TextStyle(
              color: palette.text,
              fontSize: phone ? 16 : 17,
              letterSpacing: -0.41,
            ),
            cursorColor: palette.accent,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              if (value.trim().isEmpty) return;
              widget.onConfirm(resolveCarBrand(value));
            },
            decoration: InputDecoration(
              hintText: s.aiBrandHint,
              fillColor: palette.surface,
              filled: true,
              isDense: true,
              prefixIcon: Icon(CupertinoIcons.search, color: palette.muted),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text(s.aiBrandHint, style: TextStyle(color: palette.muted)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: matches.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, i) {
                      final brand = matches[i];
                      return _BrandLogoTile(
                        brand: brand,
                        name: brand.name.of(widget.lang),
                        beat: _heartbeat,
                        onTap: () => widget.onConfirm(brand),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoTile extends StatelessWidget {
  const _BrandLogoTile({
    required this.brand,
    required this.name,
    required this.beat,
    required this.onTap,
  });

  final CarBrand brand;
  final String name;
  final Animation<double> beat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.none,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke.withValues(alpha: 0.95), width: 1.2),
            color: palette.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: _BreathingBrandMark(brand: brand, beat: beat),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo heartbeat: scale 1.0↔1.05, 1s inhale / 1s exhale, centered white backlight.
class _BreathingBrandMark extends StatelessWidget {
  const _BreathingBrandMark({
    required this.brand,
    required this.beat,
  });

  final CarBrand brand;
  final Animation<double> beat;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: beat,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(beat.value);
        final scale = 1.0 + 0.05 * t;
        final glow = 0.16 + 0.34 * t;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        radius: 0.78,
                        colors: [
                          Colors.white.withValues(alpha: glow),
                          Colors.white.withValues(alpha: glow * 0.45),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                    child: const SizedBox(width: 52, height: 52),
                  ),
                ),
                child!,
              ],
            ),
          ),
        );
      },
      child: BrandLogoMark(brand: brand, size: 44),
    );
  }
}
