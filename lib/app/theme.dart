import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_skin.dart';

enum AppVisualTheme { guy, girl }

extension AppVisualThemeX on AppVisualTheme {
  String get code => name;

  AppPalette get palette =>
      this == AppVisualTheme.girl ? kChicPalette : kCarbonPalette;

  static AppVisualTheme fromCode(String? code) {
    return code == AppVisualTheme.girl.name || code == 'chic'
        ? AppVisualTheme.girl
        : AppVisualTheme.guy;
  }
}

class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.carbon,
    required this.stroke,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.brightness,
    required this.glow,
    required this.carBody,
    required this.fillDeep,
  });

  final Color bg;
  final Color surface;
  final Color carbon;
  final Color stroke;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Brightness brightness;
  final Color glow;
  final Color carBody;
  final Color fillDeep;

  bool get isDark => brightness == Brightness.dark;
}

/// Guy / Pro: Apple-style charcoal monochrome — silver accents, no chroma UI.
const kCarbonPalette = AppPalette(
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
);

/// Girl / Light: tender blush system — petal canvas, plum ink, rose-wine chrome.
/// Distinct from Lion Trans red (#D70200) and category accents (orange/yellow/pink).
const kChicPalette = AppPalette(
  bg: Color(0xFFF7E6EB),
  surface: Color(0xFFFFF6F8),
  carbon: Color(0xFFF1D5DD),
  stroke: Color(0xFFE3B6C4),
  text: Color(0xFF3A2432),
  muted: Color(0xFF8A6270),
  accent: Color(0xFF9A3F58),
  onAccent: Color(0xFFFFF6F8),
  danger: Color(0xFFD70200),
  brightness: Brightness.light,
  glow: Color(0xFFD4A0AE),
  carBody: Color(0xFFE8C5D0),
  fillDeep: Color(0xFF5C2A3A),
);

const kAppleBlue = Color(0xFFEBEBF5);
const kAppleLink = Color(0xFFAEAEB2);
const kMsjRed = kAppleBlue;
const kMsjBlack = Color(0xFF0A0A0C);
const kMsjHero = Color(0xFF0A0A0C);
const kMsjCard = Color(0xFF141416);
const kMsjLine = Color(0xFF3A3A3E);
const kMsjMuted = Color(0xFF8E8E93);

const kGuyPalette = kCarbonPalette;
const kGirlPalette = kChicPalette;
const kAmber = kAppleBlue;
const kGarageGreen = Color(0xFFEBEBF5);
const kGarageGreenSoft = Color(0xFF636366);
const kSand = Color(0xFF0A0A0C);
const kIvory = Color(0xFF1C1C1E);

class AppThemeExtra extends ThemeExtension<AppThemeExtra> {
  const AppThemeExtra(this.palette, this.visual, this.tokens);

  final AppPalette palette;
  final AppVisualTheme visual;
  final DesignTokens tokens;

  @override
  AppThemeExtra copyWith({
    AppPalette? palette,
    AppVisualTheme? visual,
    DesignTokens? tokens,
  }) {
    return AppThemeExtra(
      palette ?? this.palette,
      visual ?? this.visual,
      tokens ?? this.tokens,
    );
  }

  @override
  AppThemeExtra lerp(ThemeExtension<AppThemeExtra>? other, double t) => this;
}

AppPalette paletteOf(BuildContext context) {
  return Theme.of(context).extension<AppThemeExtra>()?.palette ?? kCarbonPalette;
}

DesignTokens tokensOf(BuildContext context) {
  return Theme.of(context).extension<AppThemeExtra>()?.tokens ?? DesignTokens.fluent;
}

/// Space above the client tab bar and the home indicator.
double shellClearance(BuildContext context, {double extra = 16}) {
  final safe = MediaQuery.viewPaddingOf(context).bottom;
  return extra + tokensOf(context).shellBottomInset + safe;
}

/// Bottom CTA that stays above the tab bar. Must not use Center/Align —
/// those expand to the full screen when used as Scaffold.bottomNavigationBar.
Widget shellPinnedCta(BuildContext context, {required Widget child}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(28, 8, 28, shellClearance(context, extra: 8)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

EdgeInsets shellListPadding(
  BuildContext context, {
  double horizontal = 20,
  double top = 12,
  double extra = 16,
}) {
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    shellClearance(context, extra: extra),
  );
}

List<Shadow>? sceneTextShadow(AppPalette palette, {double blur = 10}) {
  if (!palette.isDark) {
    return null;
  }
  return [Shadow(color: const Color(0x99000000), blurRadius: blur)];
}

Color sceneHairline(AppPalette palette) {
  return palette.isDark ? const Color(0x40FFFFFF) : palette.stroke;
}

bool isPhoneLayout(BuildContext context) => MediaQuery.sizeOf(context).width < 700;

double phoneSize(BuildContext context, {required double phone, required double wide}) {
  return isPhoneLayout(context) ? phone : wide;
}

/// Returns null (system font) on all platforms:
/// iOS/macOS → SF Pro, Android → Roboto/system,
/// Web/Windows → system-ui. All look native.
String? _appleFont() => null;

ThemeData buildAppTheme(AppVisualTheme visual, [DesignSkin skin = DesignSkin.fluent]) {
  final tokens = skin.tokens;
  final palette = visual.palette;
  final girl = palette.brightness == Brightness.light;
  final font = _appleFont();
  final scheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.carbon,
    onSecondary: palette.text,
    error: palette.danger,
    onError: palette.onAccent,
    surface: palette.surface,
    onSurface: palette.text,
  );

  TextStyle sf({
    required double size,
    FontWeight weight = FontWeight.w400,
    double letter = -0.41,
    Color? color,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: font,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letter,
      height: height,
      color: color ?? palette.text,
    );
  }

  final body = girl ? 17.0 : 16.0;
  final cardRadius = tokens.cardRadius;
  final btnH = tokens.buttonHeight;

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    fontFamily: font,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.bg,
    visualDensity: tokens.denseList ? VisualDensity.compact : VisualDensity.standard,
    dividerColor: palette.stroke,
    splashFactory: NoSplash.splashFactory,
    highlightColor: palette.accent.withValues(alpha: 0.08),
    splashColor: Colors.transparent,
    extensions: [AppThemeExtra(palette, visual, tokens)],
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: palette.brightness,
      primaryColor: palette.accent,
      scaffoldBackgroundColor: palette.bg,
      barBackgroundColor: palette.surface.withValues(alpha: 0.72),
      textTheme: CupertinoTextThemeData(
        primaryColor: palette.accent,
        textStyle: sf(size: 17),
        navTitleTextStyle: sf(size: 17, weight: FontWeight.w600),
        navLargeTitleTextStyle: sf(size: 34, weight: FontWeight.w700, letter: 0.37),
        actionTextStyle: sf(size: 17, color: palette.accent),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg.withValues(alpha: girl ? 0.92 : 0.78),
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: tokens.centerAppBarTitle,
      systemOverlayStyle: palette.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: sf(size: girl ? 17 : 16, weight: FontWeight.w600),
      iconTheme: IconThemeData(color: palette.accent, size: 22),
      actionsIconTheme: IconThemeData(color: palette.accent, size: 22),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.accent,
      textColor: palette.text,
      subtitleTextStyle: sf(size: 13, color: palette.muted, letter: -0.08),
      titleTextStyle: sf(size: tokens.denseList ? 15 : 17, weight: FontWeight.w400, letter: -0.41),
      contentPadding: EdgeInsets.symmetric(horizontal: tokens.denseList ? 12 : 16),
      dense: tokens.denseList,
    ),
    dividerTheme: DividerThemeData(
      color: palette.stroke,
      thickness: tokens.borderWidth.clamp(0.5, 2.0),
      space: tokens.borderWidth.clamp(0.5, 2.0),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shadowColor: girl ? const Color(0x229A3F58) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: palette.stroke,
          width: tokens.borderWidth <= 0 ? 0.01 : tokens.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface.withValues(alpha: girl ? 0.94 : 0.86),
      indicatorColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      height: tokens.denseList ? 46 : 52,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return sf(
          size: 10,
          weight: FontWeight.w500,
          letter: 0.12,
          color: selected ? palette.accent : palette.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? palette.accent : palette.muted,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!tokens.filledSolid) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.disabled)) {
            return palette.accent.withValues(alpha: 0.28);
          }
          if (states.contains(WidgetState.pressed)) {
            return palette.accent.withValues(alpha: 0.82);
          }
          return palette.accent;
        }),
        foregroundColor: WidgetStatePropertyAll(
          tokens.filledSolid ? palette.onAccent : palette.accent,
        ),
        side: WidgetStatePropertyAll(
          tokens.filledSolid
              ? BorderSide.none
              : BorderSide(color: palette.accent, width: tokens.borderWidth.clamp(1, 2.5)),
        ),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: WidgetStatePropertyAll(Size(44, btnH)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
        shape: WidgetStatePropertyAll(tokens.buttonShape),
        textStyle: WidgetStatePropertyAll(
          sf(size: 16, weight: FontWeight.w600, letter: -0.3),
        ),
        overlayColor: WidgetStatePropertyAll(
          palette.onAccent.withValues(alpha: 0.10),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.accent,
        side: BorderSide(color: palette.accent, width: tokens.borderWidth.clamp(1, 2.5)),
        minimumSize: Size(44, btnH),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: tokens.buttonShape,
        textStyle: sf(size: 16, weight: FontWeight.w600, letter: -0.3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        minimumSize: const Size(44, 44),
        textStyle: sf(size: 16, weight: FontWeight.w400),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.accent,
        highlightColor: palette.accent.withValues(alpha: 0.12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: girl ? palette.carbon : palette.surface,
      hintStyle: sf(size: 17, color: palette.muted, letter: -0.41),
      labelStyle: sf(size: 17, color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: palette.muted,
      suffixIconColor: palette.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: tokens.borderWidth <= 0
            ? BorderSide.none
            : BorderSide(color: palette.stroke, width: tokens.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: tokens.borderWidth <= 0
            ? BorderSide.none
            : BorderSide(color: palette.stroke, width: tokens.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: BorderSide(color: palette.accent, width: tokens.borderWidth.clamp(1, 2.5)),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: palette.accent,
      backgroundColor: palette.surface,
      disabledColor: palette.carbon,
      labelStyle: sf(size: 13, weight: FontWeight.w600, letter: -0.08),
      secondaryLabelStyle: sf(
        size: 13,
        weight: FontWeight.w600,
        color: palette.onAccent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: tokens.buttonShape,
      side: BorderSide(color: palette.stroke, width: tokens.borderWidth.clamp(0.5, 2)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.isDark ? palette.carbon : const Color(0xFF3A2432),
      contentTextStyle: sf(
        size: 15,
        letter: -0.24,
        color: palette.isDark ? palette.text : const Color(0xFFFFF6F8),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius.clamp(0, 18))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: sf(size: 17, weight: FontWeight.w600),
      contentTextStyle: sf(size: body, height: 1.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius.clamp(0, 22))),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      modalBackgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius.clamp(0, 28))),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.stroke,
      thumbColor: palette.accent,
    ),
    textTheme: TextTheme(
      displayLarge: sf(size: girl ? 32 : 28, weight: FontWeight.w700, letter: 0.37, height: 1.12),
      headlineLarge: sf(size: girl ? 26 : 24, weight: FontWeight.w700, letter: 0.36, height: 1.15),
      headlineMedium: sf(size: 20, weight: FontWeight.w600, letter: -0.28),
      titleLarge: sf(size: 18, weight: FontWeight.w600, letter: -0.28),
      titleMedium: sf(size: 16, weight: FontWeight.w600),
      bodyLarge: sf(size: body, letter: -0.41, height: 1.35),
      bodyMedium: sf(size: girl ? 15 : 14, letter: -0.24, height: 1.35),
      bodySmall: sf(size: girl ? 13 : 12, letter: -0.08, color: palette.muted, height: 1.35),
      labelLarge: sf(size: 16, weight: FontWeight.w600),
    ),
  );
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final tokens = tokensOf(context);
    final r = radius == 16 ? tokens.cardRadius : radius;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: palette.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x229A3F58),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: _maybeBlur(
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: kIsWeb ? 0.97 : (palette.isDark ? 0.72 : 0.94)),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(
                color: palette.stroke,
                width: tokens.borderWidth <= 0 ? 0.5 : tokens.borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _maybeBlur({required Widget child}) {
    if (kIsWeb) {
      return child;
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child,
    );
  }
}
