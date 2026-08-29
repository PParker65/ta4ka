import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_skin.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import 'language_switcher.dart';
import 'wallet_chip.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    return Tooltip(
      message: theme == AppVisualTheme.guy ? s.themeGirl : s.themeGuy,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(44, 44),
        onPressed: () => ref.read(themeProvider.notifier).toggle(),
        child: Icon(
          // Dark on → sun (tap goes light). Light on → moon (tap goes dark).
          theme == AppVisualTheme.guy
              ? CupertinoIcons.sun_max_fill
              : CupertinoIcons.moon_fill,
          color: palette.accent,
          size: 22,
        ),
      ),
    );
  }
}

class SkinSwitcher extends ConsumerWidget {
  const SkinSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(designSkinProvider);
    final palette = paletteOf(context);
    return Tooltip(
      message: skin.labelUk,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(44, 44),
        onPressed: () {
          final values = DesignSkin.values;
          final i = (values.indexOf(skin) + 1) % values.length;
          ref.read(designSkinProvider.notifier).state = values[i];
        },
        child: Icon(CupertinoIcons.paintbrush_fill, color: palette.accent, size: 20),
      ),
    );
  }
}

class AppBarTools extends ConsumerWidget {
  const AppBarTools({super.key, this.showWallet = false, this.showProfile = true});

  final bool showWallet;
  final bool showProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = paletteOf(context);
    final s = ref.watch(stringsProvider);
    final tokens = tokensOf(context);

    final wallet = showWallet
        ? const Padding(
            padding: EdgeInsets.only(right: 8),
            child: WalletChip(),
          )
        : null;
    const themeBtn = ThemeSwitcher();
    final skinBtn = kIsWeb ? const SkinSwitcher() : null;
    const lang = Padding(
      padding: EdgeInsets.only(right: 4),
      child: LanguageSwitcher(),
    );
    final profile = showProfile
        ? Tooltip(
            message: s.profile,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(44, 44),
              onPressed: () {
                ref.read(sectionSlideDirProvider.notifier).state = 0;
                ref.read(clientTabProvider.notifier).state = ClientTabs.profile;
                GoRouter.of(context).go('/home');
              },
              child: Icon(
                CupertinoIcons.person_crop_circle_fill,
                color: palette.accent,
                size: 24,
              ),
            ),
          )
        : null;

    final items = <Widget>[
      if (wallet != null) wallet,
      themeBtn,
      if (skinBtn != null) skinBtn,
      lang,
      if (profile != null) profile,
    ];

    final ordered = switch (tokens.toolsOrder) {
      AppBarToolsOrder.classic => items,
      AppBarToolsOrder.reverse => items.reversed.toList(),
      AppBarToolsOrder.profileFirst => [
          if (profile != null) profile,
          if (wallet != null) wallet,
          themeBtn,
          if (skinBtn != null) skinBtn,
          lang,
        ],
      AppBarToolsOrder.langFirst => [
          lang,
          themeBtn,
          if (skinBtn != null) skinBtn,
          if (wallet != null) wallet,
          if (profile != null) profile,
        ],
    };

    return Row(mainAxisSize: MainAxisSize.min, children: ordered);
  }
}
