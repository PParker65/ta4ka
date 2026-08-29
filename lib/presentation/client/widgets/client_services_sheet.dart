import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_skin.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../data/telegram_links.dart';
import '../../../data/telegram_webapp.dart';
import 'usa_intro.dart';

typedef _ServiceEntry = ({
  IconData icon,
  Color tint,
  String title,
  String subtitle,
  int target,
});

double _sheetBottomInset(BuildContext context) {
  return math.max(
    MediaQuery.viewPaddingOf(context).bottom,
    TelegramWebApp.instance.insets.bottom,
  );
}

/// Bottom «Сервіси» flyout — layout depends on DesignSkin.
Future<void> showClientServicesSheet(BuildContext context, WidgetRef ref) {
  final s = ref.read(stringsProvider);
  final palette = paletteOf(context);
  final tokens = tokensOf(context);
  final tab = ref.read(clientTabProvider);
  final hi = palette.accent;

  void go(int next) {
    TelegramWebApp.instance.hapticLight();
    Navigator.of(context).pop();
    ref.read(sectionSlideDirProvider.notifier).state = 0;
    ref.selectClientTab(next);
    context.go('/home');
  }

  Widget? telegramRow({EdgeInsets padding = const EdgeInsets.fromLTRB(12, 0, 12, 10)}) {
    if (TelegramWebApp.instance.active || !hasTelegramBot) return null;
    return Padding(
      padding: padding,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: palette.carbon.withValues(alpha: 0.35),
        leading: Icon(CupertinoIcons.paperplane_fill, color: hi),
        title: Text(s.telegramOpen, style: TextStyle(fontWeight: FontWeight.w800, color: palette.text)),
        subtitle: Text(s.telegramOpenLead, style: TextStyle(color: palette.muted, fontSize: 12.5)),
        trailing: Icon(CupertinoIcons.chevron_right, size: 16, color: palette.muted),
        onTap: () {
          Navigator.of(context).pop();
          openTelegramMiniApp();
        },
      ),
    );
  }

  final tgRow = telegramRow();

  const lionRed = kLTransRed;
  final entries = <_ServiceEntry>[
    (
      icon: CupertinoIcons.flag_fill,
      tint: lionRed,
      title: s.tabUsa,
      subtitle: s.usaServicesLead,
      target: ClientTabs.usa,
    ),
    (
      icon: CupertinoIcons.briefcase_fill,
      tint: lionRed,
      title: s.tabRequests,
      subtitle: s.servicesRequestsLead,
      target: ClientTabs.requests,
    ),
    (
      icon: CupertinoIcons.hammer_fill,
      tint: lionRed,
      title: s.tabAuction,
      subtitle: s.auctionHeroTitle,
      target: ClientTabs.auction,
    ),
    (
      icon: CupertinoIcons.checkmark_alt,
      tint: lionRed,
      title: s.tabHelp,
      subtitle: s.servicesHelpLead,
      target: ClientTabs.help,
    ),
  ];

  Widget sheetShell({required Widget child, EdgeInsets? pad, BuildContext? sheetContext}) {
    final insetCtx = sheetContext ?? context;
    return _SyncEnergyScope(
      child: Padding(
        padding: pad ??
            EdgeInsets.fromLTRB(
              16,
              0,
              16,
              14 + _sheetBottomInset(insetCtx),
            ),
        child: Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(tokens.cardRadius == 0 ? 0 : 22),
          child: child,
        ),
      ),
    );
  }

  switch (tokens.servicesLayout) {
    case ServicesMenuLayout.iconRows:
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          final short = MediaQuery.sizeOf(ctx).height < 620;
          return sheetShell(
            sheetContext: ctx,
            pad: EdgeInsets.fromLTRB(16, 0, 16, 14 + _sheetBottomInset(ctx)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, short ? 14 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: palette.stroke, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.tabServices,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: palette.text),
                  ),
                  SizedBox(height: short ? 12 : 16),
                  _ServicesQuadGrid(
                    entries: entries,
                    currentTab: tab,
                    onPick: go,
                    iconSize: short ? 40 : 48,
                    compact: short,
                  ),
                  if (tgRow != null) ...[
                    const SizedBox(height: 10),
                    tgRow,
                  ],
                ],
              ),
            ),
          );
        },
      );

    case ServicesMenuLayout.fullBleedBlocks:
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return sheetShell(
            pad: EdgeInsets.zero,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in entries)
                    InkWell(
                      onTap: () => go(e.target),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                        decoration: BoxDecoration(
                          color: tab == e.target ? e.tint : palette.surface,
                          border: Border(bottom: BorderSide(color: palette.stroke, width: tokens.borderWidth)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: tab == e.target ? Colors.white : palette.text)),
                            const SizedBox(height: 6),
                            Text(e.subtitle, style: TextStyle(color: tab == e.target ? Colors.white70 : palette.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  if (tgRow != null) tgRow,
                ],
              ),
            ),
          );
        },
      );

    case ServicesMenuLayout.iconGrid:
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          final short = MediaQuery.sizeOf(ctx).height < 620;
          return sheetShell(
            sheetContext: ctx,
            pad: EdgeInsets.fromLTRB(16, 0, 16, 14 + _sheetBottomInset(ctx)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, short ? 14 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.tabServices,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: palette.text),
                  ),
                  SizedBox(height: short ? 12 : 16),
                  _ServicesQuadGrid(
                    entries: entries,
                    currentTab: tab,
                    onPick: go,
                    iconSize: short ? 40 : 48,
                    compact: short,
                    radius: 22,
                  ),
                  if (tgRow != null) ...[
                    const SizedBox(height: 10),
                    tgRow,
                  ],
                ],
              ),
            ),
          );
        },
      );

    case ServicesMenuLayout.numberedList:
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return sheetShell(
            sheetContext: ctx,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text('// ${s.tabServices}'.toUpperCase(), style: TextStyle(fontFamily: 'monospace', color: palette.accent, fontWeight: FontWeight.w800)),
                ),
                for (var i = 0; i < entries.length; i++)
                  ListTile(
                    leading: Text('${i + 1}'.padLeft(2, '0'), style: TextStyle(fontFamily: 'monospace', color: palette.accent, fontWeight: FontWeight.w900)),
                    title: Text(entries[i].title, style: TextStyle(fontFamily: 'monospace', color: palette.text, fontWeight: FontWeight.w700)),
                    subtitle: Text(entries[i].subtitle, style: TextStyle(fontFamily: 'monospace', color: palette.muted, fontSize: 11)),
                    selected: tab == entries[i].target,
                    onTap: () => go(entries[i].target),
                  ),
                if (tgRow != null) tgRow,
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

    case ServicesMenuLayout.chipCloud:
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return sheetShell(
            sheetContext: ctx,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in entries)
                    ActionChip(
                      avatar: _ServiceEnergyTile(
                        size: 28,
                        glyph: e.target == ClientTabs.usa ? null : e.icon,
                      ),
                      label: Text(e.title),
                      backgroundColor: tab == e.target ? palette.accent : palette.carbon,
                      labelStyle: TextStyle(color: tab == e.target ? palette.onAccent : palette.text, fontWeight: FontWeight.w700),
                      side: BorderSide(color: palette.stroke, width: tokens.borderWidth),
                      onPressed: () => go(e.target),
                    ),
                  if (tgRow != null)
                    ActionChip(
                      avatar: Icon(CupertinoIcons.paperplane_fill, size: 18, color: palette.accent),
                      label: Text(s.telegramOpen),
                      backgroundColor: palette.carbon,
                      labelStyle: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
                      side: BorderSide(color: palette.stroke, width: tokens.borderWidth),
                      onPressed: () {
                        Navigator.of(context).pop();
                        openTelegramMiniApp();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
  }
}

bool isServicesTab(int tab) =>
    tab == ClientTabs.help ||
    tab == ClientTabs.requests ||
    tab == ClientTabs.auction ||
    tab == ClientTabs.usa;

/// Compact 2×2 (or 4-across on wide) cluster — stays fully on screen.
class _ServicesQuadGrid extends StatelessWidget {
  const _ServicesQuadGrid({
    required this.entries,
    required this.currentTab,
    required this.onPick,
    required this.iconSize,
    this.compact = false,
    this.radius = 20,
  });

  final List<_ServiceEntry> entries;
  final int currentTab;
  final void Function(int target) onPick;
  final double iconSize;
  final bool compact;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final gap = compact ? 8.0 : 12.0;
    final fourAcross = MediaQuery.sizeOf(context).width >= 520;
    final vPad = compact ? 10.0 : 14.0;

    Widget cell(int i) {
      final e = entries[i];
      final selected = currentTab == e.target;
      return Expanded(
        child: Material(
          color: selected ? e.tint.withValues(alpha: 0.16) : palette.carbon.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: () => onPick(e.target),
            borderRadius: BorderRadius.circular(radius),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: selected ? e.tint : palette.stroke,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ServiceEnergyTile(
                      size: iconSize,
                      glyph: e.target == ClientTabs.usa ? null : e.icon,
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Text(
                      e.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 12 : 13,
                        height: 1.15,
                        color: selected ? e.tint : palette.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (fourAcross) {
      return Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            cell(i),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [cell(0), SizedBox(width: gap), cell(1)]),
        SizedBox(height: gap),
        Row(children: [cell(2), SizedBox(width: gap), cell(3)]),
      ],
    );
  }
}

/// One loop for every service energy tile — same phase, not staggered.
class _SyncEnergyScope extends StatefulWidget {
  const _SyncEnergyScope({required this.child});

  final Widget child;

  @override
  State<_SyncEnergyScope> createState() => _SyncEnergyScopeState();
}

class _SyncEnergyScopeState extends State<_SyncEnergyScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: kLTransEnergyPeriod)..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SyncEnergyClock(animation: _clock, child: widget.child);
  }
}

class _SyncEnergyClock extends InheritedWidget {
  const _SyncEnergyClock({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SyncEnergyClock>();
    assert(scope != null, 'Service energy tiles need _SyncEnergyScope');
    return scope!.animation;
  }

  @override
  bool updateShouldNotify(_SyncEnergyClock oldWidget) => animation != oldWidget.animation;
}

class _ServiceEnergyTile extends StatelessWidget {
  const _ServiceEnergyTile({this.glyph, this.size = 52});

  final IconData? glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 14 / 52),
      child: SizedBox(
        width: size,
        height: size,
        child: LTransEnergyArt(
          clock: _SyncEnergyClock.of(context),
          glyph: glyph,
        ),
      ),
    );
  }
}
