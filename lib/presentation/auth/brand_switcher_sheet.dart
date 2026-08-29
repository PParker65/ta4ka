import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/car_glb_models.dart';
import '../../data/car_brands.dart';
import 'brand_logo.dart';

Future<void> showBrandSwitcherSheet({
  required BuildContext context,
  required AppLang lang,
  required AppStrings strings,
  required CarBrand? current,
  required ValueChanged<CarBrand> onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BrandSwitcherSheet(
      lang: lang,
      strings: strings,
      current: current,
      onPick: (brand) {
        Navigator.of(ctx).pop();
        onPick(brand);
      },
    ),
  );
}

class _BrandSwitcherSheet extends StatefulWidget {
  const _BrandSwitcherSheet({
    required this.lang,
    required this.strings,
    required this.current,
    required this.onPick,
  });

  final AppLang lang;
  final AppStrings strings;
  final CarBrand? current;
  final ValueChanged<CarBrand> onPick;

  @override
  State<_BrandSwitcherSheet> createState() => _BrandSwitcherSheetState();
}

class _BrandSwitcherSheetState extends State<_BrandSwitcherSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phone = isPhoneLayout(context);
    final sheetAccent = widget.current != null ? carUiAccent(widget.current!) : palette.accent;
    final q = _query.text.trim();
    final matches = q.isEmpty
        ? [
            ...carBrandsWithGlbModels(),
            ...carBrands.where((b) => !carBrandHasGlb(b)),
          ]
        : matchCarBrands(_query.text, limit: 50);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: GlassPanel(
          radius: 20,
          padding: EdgeInsets.fromLTRB(phone ? 16 : 20, phone ? 16 : 20, phone ? 16 : 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: palette.stroke,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              widget.strings.aiSwitchBrand,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w600,
                fontSize: phone ? 17 : 19,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.strings.aiSwitchBrandHint,
              style: TextStyle(
                color: palette.muted,
                fontSize: phone ? 13 : 14,
                letterSpacing: -0.2,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: palette.text, fontSize: 16, letterSpacing: -0.35),
              cursorColor: sheetAccent,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.strings.aiBrandHint,
                prefixIcon: Icon(CupertinoIcons.search, color: palette.muted, size: 20),
                filled: true,
                fillColor: palette.carbon.withValues(alpha: palette.isDark ? 0.45 : 0.3),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final brand = matches[index];
                  final selected = widget.current?.id == brand.id;
                  final has3d = carBrandHasGlb(brand);
                  final accent = carUiAccent(brand);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onPick(brand),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: selected
                              ? accent.withValues(alpha: palette.isDark ? 0.16 : 0.1)
                              : palette.surface.withValues(alpha: 0.5),
                          border: Border.all(
                            color: selected ? accent : palette.stroke.withValues(alpha: 0.55),
                            width: selected ? 1.2 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: palette.stroke.withValues(alpha: 0.75),
                                ),
                                color: palette.surface,
                              ),
                              child: BrandLogoMark(brand: brand, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                brand.name.of(widget.lang),
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (has3d)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  CupertinoIcons.view_3d,
                                  size: 16,
                                  color: accent.withValues(alpha: 0.75),
                                ),
                              ),
                            if (selected)
                              Icon(CupertinoIcons.checkmark_alt, color: accent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Tappable app-bar title — opens brand switcher.
class BrandAppBarTitle extends StatelessWidget {
  const BrandAppBarTitle({
    super.key,
    required this.brand,
    required this.lang,
    required this.onTap,
    this.compact = false,
  });

  final CarBrand brand;
  final AppLang lang;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final accent = carUiAccent(brand);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.car_detailed,
                color: accent,
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  brand.name.of(lang),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 16 : 17,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: compact ? 13 : 14,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
