import 'package:flutter/material.dart';

import 'theme.dart';

/// Five products · one skeleton — as if five different designers shipped it.
enum DesignSkin {
  fluent,
  brutal,
  soft,
  neon,
  forge,
}

extension DesignSkinX on DesignSkin {
  String get code => name;

  String get labelUk => switch (this) {
        DesignSkin.fluent => 'A · Fluent (низ · авто зверху)',
        DesignSkin.brutal => 'B · Brutal (навігація ЗВЕРХУ · пошук зверху)',
        DesignSkin.soft => 'C · Soft (плаваючий док · авто в кутку)',
        DesignSkin.neon => 'D · Neon (рейка ЗЛІВА · таблиця СТО)',
        DesignSkin.forge => 'E · Forge (товстий низ · дашборд 50/50)',
      };

  String get labelEn => switch (this) {
        DesignSkin.fluent => 'A · Fluent (bottom nav · car top)',
        DesignSkin.brutal => 'B · Brutal (TOP nav · search first)',
        DesignSkin.soft => 'C · Soft (floating dock · car corner)',
        DesignSkin.neon => 'D · Neon (LEFT rail · dense shop table)',
        DesignSkin.forge => 'E · Forge (fat bottom · 50/50 dash)',
      };

  static DesignSkin fromCode(String? raw) {
    final q = (raw ?? '').trim().toLowerCase();
    if (q == '0' || q == 'a' || q == 'fluent') return DesignSkin.fluent;
    if (q == '1' || q == 'b' || q == 'brutal') return DesignSkin.brutal;
    if (q == '2' || q == 'c' || q == 'soft') return DesignSkin.soft;
    if (q == '3' || q == 'd' || q == 'neon') return DesignSkin.neon;
    if (q == '4' || q == 'e' || q == 'forge') return DesignSkin.forge;
    for (final s in DesignSkin.values) {
      if (s.name == q) return s;
    }
    return DesignSkin.fluent;
  }

  DesignTokens get tokens => switch (this) {
        DesignSkin.fluent => DesignTokens.fluent,
        DesignSkin.brutal => DesignTokens.brutal,
        DesignSkin.soft => DesignTokens.soft,
        DesignSkin.neon => DesignTokens.neon,
        DesignSkin.forge => DesignTokens.forge,
      };
}

enum ButtonGeom { stadium, sharp, softBlob, pillTall, cutCorner }

enum AppBarToolsOrder { classic, reverse, profileFirst, langFirst }

enum ComposerActionsLayout { rowPhotoThenAnalyze, rowAnalyzeThenPhoto, stackedAnalyzeTop }

/// Where primary client navigation lives.
enum NavChrome {
  bottomClassic,
  topStrip,
  floatingCapsule,
  leftRail,
  bottomFat,
}

/// Car home composition.
enum CarStageLayout {
  carTopSearchBottom,
  searchTopCarBottom,
  searchFullCarCorner,
  alwaysSideBySide,
  dashboardHalf,
}

enum CatalogLayout {
  cardsVertical,
  mapThenList,
  twoColumnGrid,
  denseRows,
  magazineHero,
}

enum ServicesMenuLayout {
  iconRows,
  fullBleedBlocks,
  iconGrid,
  numberedList,
  chipCloud,
}

enum ProfileHeaderLayout {
  centerStack,
  leftBanner,
  topStatsRow,
  splitHero,
  minimalInline,
}

enum ReferralChipAnchor {
  bottomLeft,
  bottomRight,
  topLeft,
  topRight,
  underBrand,
}

class DesignTokens {
  const DesignTokens({
    required this.id,
    required this.palette,
    required this.buttonGeom,
    required this.buttonHeight,
    required this.cardRadius,
    required this.fieldRadius,
    required this.borderWidth,
    required this.toolsOrder,
    required this.composerLayout,
    required this.centerAppBarTitle,
    required this.denseList,
    required this.filledSolid,
    required this.navChrome,
    required this.carLayout,
    required this.catalogLayout,
    required this.servicesLayout,
    required this.profileLayout,
    required this.referralAnchor,
    this.shellBottomInset = 56,
  });

  final DesignSkin id;
  final AppPalette palette;
  final ButtonGeom buttonGeom;
  final double buttonHeight;
  final double cardRadius;
  final double fieldRadius;
  final double borderWidth;
  final AppBarToolsOrder toolsOrder;
  final ComposerActionsLayout composerLayout;
  final bool centerAppBarTitle;
  final bool denseList;
  final bool filledSolid;
  final NavChrome navChrome;
  final CarStageLayout carLayout;
  final CatalogLayout catalogLayout;
  final ServicesMenuLayout servicesLayout;
  final ProfileHeaderLayout profileLayout;
  final ReferralChipAnchor referralAnchor;
  final double shellBottomInset;

  OutlinedBorder get buttonShape => switch (buttonGeom) {
        ButtonGeom.stadium => const StadiumBorder(),
        ButtonGeom.sharp => const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ButtonGeom.softBlob => RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ButtonGeom.pillTall => RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ButtonGeom.cutCorner => const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
      };

  static const fluent = DesignTokens(
    id: DesignSkin.fluent,
    palette: AppPalette(
      bg: Color(0xFF0A0A0C),
      surface: Color(0xFF141416),
      carbon: Color(0xFF1C1C1F),
      stroke: Color(0xFF3A3A3E),
      text: Color(0xFFF2F2F7),
      muted: Color(0xFF8E8E93),
      accent: Color(0xFFEBEBF5),
      onAccent: Color(0xFF0A0A0C),
      danger: Color(0xFFFF453A),
      brightness: Brightness.dark,
      glow: Color(0xFF636366),
      carBody: Color(0xFFC5CCD4),
      fillDeep: Color(0xFF2C2C2E),
    ),
    buttonGeom: ButtonGeom.stadium,
    buttonHeight: 50,
    cardRadius: 16,
    fieldRadius: 12,
    borderWidth: 0.8,
    toolsOrder: AppBarToolsOrder.classic,
    composerLayout: ComposerActionsLayout.rowPhotoThenAnalyze,
    centerAppBarTitle: true,
    denseList: false,
    filledSolid: true,
    navChrome: NavChrome.bottomClassic,
    carLayout: CarStageLayout.carTopSearchBottom,
    catalogLayout: CatalogLayout.cardsVertical,
    servicesLayout: ServicesMenuLayout.iconRows,
    profileLayout: ProfileHeaderLayout.centerStack,
    referralAnchor: ReferralChipAnchor.bottomLeft,
    shellBottomInset: 88,
  );

  static const brutal = DesignTokens(
    id: DesignSkin.brutal,
    palette: AppPalette(
      bg: Color(0xFFFAFAF8),
      surface: Color(0xFFFFFFFF),
      carbon: Color(0xFFF0EDE6),
      stroke: Color(0xFF111111),
      text: Color(0xFF111111),
      muted: Color(0xFF444444),
      accent: Color(0xFFFF3B00),
      onAccent: Color(0xFFFFFFFF),
      danger: Color(0xFFB00020),
      brightness: Brightness.light,
      glow: Color(0xFFFF6A3D),
      carBody: Color(0xFFE8E4DC),
      fillDeep: Color(0xFF111111),
    ),
    buttonGeom: ButtonGeom.sharp,
    buttonHeight: 52,
    cardRadius: 0,
    fieldRadius: 0,
    borderWidth: 2.4,
    toolsOrder: AppBarToolsOrder.reverse,
    composerLayout: ComposerActionsLayout.rowAnalyzeThenPhoto,
    centerAppBarTitle: false,
    denseList: true,
    filledSolid: true,
    navChrome: NavChrome.topStrip,
    carLayout: CarStageLayout.searchTopCarBottom,
    catalogLayout: CatalogLayout.mapThenList,
    servicesLayout: ServicesMenuLayout.fullBleedBlocks,
    profileLayout: ProfileHeaderLayout.leftBanner,
    referralAnchor: ReferralChipAnchor.topRight,
    shellBottomInset: 8,
  );

  static const soft = DesignTokens(
    id: DesignSkin.soft,
    palette: AppPalette(
      bg: Color(0xFFF7F2EC),
      surface: Color(0xFFFFFBF7),
      carbon: Color(0xFFEFE6DC),
      stroke: Color(0xFFD9CBBA),
      text: Color(0xFF2A2420),
      muted: Color(0xFF7A6E64),
      accent: Color(0xFF6B4EFF),
      onAccent: Color(0xFFFFFFFF),
      danger: Color(0xFFC43C4A),
      brightness: Brightness.light,
      glow: Color(0xFFA894FF),
      carBody: Color(0xFFE8DFD4),
      fillDeep: Color(0xFF4A35B8),
    ),
    buttonGeom: ButtonGeom.softBlob,
    buttonHeight: 54,
    cardRadius: 26,
    fieldRadius: 22,
    borderWidth: 0,
    toolsOrder: AppBarToolsOrder.langFirst,
    composerLayout: ComposerActionsLayout.stackedAnalyzeTop,
    centerAppBarTitle: true,
    denseList: false,
    filledSolid: true,
    navChrome: NavChrome.floatingCapsule,
    carLayout: CarStageLayout.searchFullCarCorner,
    catalogLayout: CatalogLayout.magazineHero,
    servicesLayout: ServicesMenuLayout.iconGrid,
    profileLayout: ProfileHeaderLayout.splitHero,
    referralAnchor: ReferralChipAnchor.underBrand,
    shellBottomInset: 88,
  );

  static const neon = DesignTokens(
    id: DesignSkin.neon,
    palette: AppPalette(
      bg: Color(0xFF050808),
      surface: Color(0xFF0C1212),
      carbon: Color(0xFF101818),
      stroke: Color(0xFF1CFFB0),
      text: Color(0xFFE8FFF6),
      muted: Color(0xFF7AA896),
      accent: Color(0xFF1CFFB0),
      onAccent: Color(0xFF04110C),
      danger: Color(0xFFFF2E63),
      brightness: Brightness.dark,
      glow: Color(0xFF7DFFD1),
      carBody: Color(0xFF9BB5AB),
      fillDeep: Color(0xFF0A3D32),
    ),
    buttonGeom: ButtonGeom.pillTall,
    buttonHeight: 48,
    cardRadius: 8,
    fieldRadius: 6,
    borderWidth: 1.4,
    toolsOrder: AppBarToolsOrder.profileFirst,
    composerLayout: ComposerActionsLayout.rowAnalyzeThenPhoto,
    centerAppBarTitle: true,
    denseList: true,
    filledSolid: false,
    navChrome: NavChrome.leftRail,
    carLayout: CarStageLayout.alwaysSideBySide,
    catalogLayout: CatalogLayout.denseRows,
    servicesLayout: ServicesMenuLayout.numberedList,
    profileLayout: ProfileHeaderLayout.topStatsRow,
    referralAnchor: ReferralChipAnchor.bottomRight,
    shellBottomInset: 8,
  );

  static const forge = DesignTokens(
    id: DesignSkin.forge,
    palette: AppPalette(
      bg: Color(0xFF16130F),
      surface: Color(0xFF1F1A14),
      carbon: Color(0xFF2A231B),
      stroke: Color(0xFF5A4A36),
      text: Color(0xFFF4EDE2),
      muted: Color(0xFFA8947A),
      accent: Color(0xFFE8A317),
      onAccent: Color(0xFF1A140A),
      danger: Color(0xFFE85D4C),
      brightness: Brightness.dark,
      glow: Color(0xFFFFC857),
      carBody: Color(0xFFC4B59A),
      fillDeep: Color(0xFF5C3D08),
    ),
    buttonGeom: ButtonGeom.cutCorner,
    buttonHeight: 50,
    cardRadius: 10,
    fieldRadius: 8,
    borderWidth: 1.6,
    toolsOrder: AppBarToolsOrder.classic,
    composerLayout: ComposerActionsLayout.rowPhotoThenAnalyze,
    centerAppBarTitle: false,
    denseList: false,
    filledSolid: false,
    navChrome: NavChrome.bottomFat,
    carLayout: CarStageLayout.dashboardHalf,
    catalogLayout: CatalogLayout.twoColumnGrid,
    servicesLayout: ServicesMenuLayout.chipCloud,
    profileLayout: ProfileHeaderLayout.minimalInline,
    referralAnchor: ReferralChipAnchor.topLeft,
    shellBottomInset: 78,
  );
}
