import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/open_link.dart';
import '../../data/usa_delivery.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'widgets/usa_intro.dart';
import 'widgets/usa_pipeline_art.dart';
import 'widgets/usa_route_map.dart';

/// Turnkey USA import — mini-app inside Ta4ka (not a shop booking).
class UsaDeliveryScreen extends ConsumerStatefulWidget {
  const UsaDeliveryScreen({super.key});

  @override
  ConsumerState<UsaDeliveryScreen> createState() => _UsaDeliveryScreenState();
}

class _UsaDeliveryScreenState extends ConsumerState<UsaDeliveryScreen> {
  int _step = 0;
  int _bid = 16500;
  double _engine = 2.0;
  int _year = 2019;
  String _fuel = 'petrol';
  final _phone = TextEditingController();
  final _vehicle = TextEditingController();
  final _bidText = TextEditingController(text: '16500');
  final _engineText = TextEditingController(text: '2.0');
  final _scroll = ScrollController();
  final _aboutKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _catalogKey = GlobalKey();
  final _dealersKey = GlobalKey();
  final _contactsKey = GlobalKey();
  bool _sent = false;

  @override
  void dispose() {
    _phone.dispose();
    _vehicle.dispose();
    _bidText.dispose();
    _engineText.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _openSite([String path = '']) {
    openLink('$kUsaSiteUrl$path');
  }

  void _to(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openCatalog({
    required String title,
    required List<UsaLot> lots,
    required AppLang lang,
    required AppPalette palette,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _UsaCatalogPage(
          title: title,
          lots: lots,
          lang: lang,
          palette: palette,
          onUse: (lot) {
            setState(() {
              _bid = lot.bidUsd;
              _engine = lot.engineL == 0 ? 2.0 : lot.engineL;
              _year = lot.year;
              _fuel = lot.fuel;
              _vehicle.text = lot.title.of(lang);
              _bidText.text = '${lot.bidUsd}';
              _engineText.text = lot.fuel == 'ev' ? '' : _engine.toStringAsFixed(1);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final quote = usaLandedQuote(
      bidUsd: _bid,
      engineL: _engine,
      year: _year,
      fuel: _fuel,
    );

    final onUsa = ref.watch(clientTabProvider) == ClientTabs.usa;

    final scaffold = GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
      backgroundColor: kLTransBg,
      appBar: AppBar(
        backgroundColor: kLTransBg,
        foregroundColor: kLTransInk,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            LTransLogoMark(size: 28),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'LION TRANS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kLTransRed,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.usaSiteCta,
            onPressed: _openSite,
            icon: const Icon(CupertinoIcons.globe, color: kLTransInk),
          ),
          const AppBarTools(),
        ],
      ),
      body: ListView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: shellListPadding(
            context,
            extra: 20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            _RouteBanner(
              active: onUsa,
              exclusive: s.usaExclusiveBadge,
              daysShort: s.usaRouteDaysShort,
              usa: s.usaRouteUsa,
              ocean: s.usaRouteOcean,
              europe: s.usaRouteEu,
              ukraine: s.usaRouteUa,
            ),
            const SizedBox(height: 12),
            _SiteMenu(
              strings: s,
              onCatalog: () => _to(_catalogKey),
              onAbout: () => _to(_aboutKey),
              onServices: () => _to(_servicesKey),
              onDealers: () => _to(_dealersKey),
              onContacts: () => _to(_contactsKey),
              onConsult: () => _to(_contactsKey),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _catalogKey,
              child: _SectionTitle(s.usaLotsTitle),
            ),
            const SizedBox(height: 10),
            _CatalogGate(
              title: s.usaStockTitle,
              subtitle: s.usaStockLead,
              icon: CupertinoIcons.car_fill,
              onTap: () => _openCatalog(
                title: s.usaStockTitle,
                lots: usaStockLots(),
                lang: lang,
                palette: palette,
              ),
            ),
            const SizedBox(height: 10),
            _CatalogGate(
              title: s.usaPickedTitle,
              subtitle: s.usaPickedLead,
              icon: CupertinoIcons.star_fill,
              onTap: () => _openCatalog(
                title: s.usaPickedTitle,
                lots: usaPickedLots(),
                lang: lang,
                palette: palette,
              ),
            ),
            const SizedBox(height: 18),
            KeyedSubtree(
              key: _servicesKey,
              child: _SectionTitle(s.usaPipelineTitle),
            ),
            const SizedBox(height: 10),
            _Pipeline(
              lang: lang,
              active: _step,
              play: true,
              onPick: (i) => setState(() => _step = i),
            ),
            const SizedBox(height: 18),
            _HeroCard(
              turnkey: s.usaTurnkey,
              days: s.usaRouteDays,
              lead: s.usaRouteLead,
              consultLabel: s.usaRequestCta,
              onConsult: () => _to(_contactsKey),
            ),
            const SizedBox(height: 18),
            KeyedSubtree(
              key: _aboutKey,
              child: _SectionTitle(s.usaNavAbout),
            ),
            const SizedBox(height: 8),
            Text(s.usaAboutLead, style: const TextStyle(color: Color(0xFFB8B8BE), height: 1.4, fontSize: 13.5)),
            const SizedBox(height: 14),
            _TrustStrip(lang: lang),
            const SizedBox(height: 22),
            _SectionTitle(s.usaCalcTitle),
            const SizedBox(height: 4),
            Text(s.usaCalcLead, style: const TextStyle(color: Color(0xFFB8B8BE), fontSize: 13, height: 1.35)),
            const SizedBox(height: 12),
            _CalcCard(
              lang: lang,
              vehicle: _vehicle,
              bidText: _bidText,
              engineText: _engineText,
              bid: _bid,
              engine: _engine,
              year: _year,
              fuel: _fuel,
              quote: quote,
              onBid: (v) => setState(() => _bid = v),
              onEngine: (v) => setState(() => _engine = v),
              onYear: (v) => setState(() => _year = v),
              onFuel: (v) => setState(() => _fuel = v),
            ),
            const SizedBox(height: 22),
            KeyedSubtree(
              key: _dealersKey,
              child: _SectionTitle(s.usaIncludeTitle),
            ),
            const SizedBox(height: 10),
            for (final item in kUsaIncludes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.ok ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
                      size: 18,
                      color: item.ok ? kLTransRed : const Color(0xFF6E6E76),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title.of(lang),
                        style: TextStyle(
                          color: item.ok ? kLTransInk : const Color(0xFF8E8E96),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            KeyedSubtree(
              key: _contactsKey,
              child: _SectionTitle(s.usaRequestTitle),
            ),
            const SizedBox(height: 4),
            Text(s.usaRequestLead, style: const TextStyle(color: Color(0xFFB8B8BE), fontSize: 13, height: 1.35)),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onTapOutside: (_) => _dismissKeyboard(),
              onEditingComplete: _dismissKeyboard,
              style: const TextStyle(color: kLTransInk),
              decoration: InputDecoration(
                labelText: s.usaPhone,
                labelStyle: const TextStyle(color: Color(0xFFB8B8BE)),
                filled: true,
                fillColor: const Color(0xFF1A1A1E),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kLTransRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF5A1212),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  overlayColor: Colors.white.withValues(alpha: 0.22),
                ),
                onPressed: _sent
                    ? null
                    : () {
                        setState(() => _sent = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.usaRequestDone)),
                        );
                      },
                child: Text(
                  _sent ? s.usaRequestQueued : s.usaRequestCta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  Text(
                    s.usaOurSite,
                    style: const TextStyle(
                      color: Color(0xFFB8B8BE),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _openSite,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        s.usaSiteCta,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kLTransInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.6,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0x88FFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.usaExclusiveNote,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E96), fontSize: 12, height: 1.35),
            ),
          ],
        ),
      ),
    );
    if (!onUsa) return scaffold;
    return UsaIntroGate(child: scaffold);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: kLTransInk,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 2.4,
      ),
    );
  }
}

class _SiteMenu extends StatelessWidget {
  const _SiteMenu({
    required this.strings,
    required this.onCatalog,
    required this.onAbout,
    required this.onServices,
    required this.onDealers,
    required this.onContacts,
    required this.onConsult,
  });

  final AppStrings strings;
  final VoidCallback onCatalog;
  final VoidCallback onAbout;
  final VoidCallback onServices;
  final VoidCallback onDealers;
  final VoidCallback onContacts;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    final items = <(String, VoidCallback)>[
      (strings.usaNavCatalog, onCatalog),
      (strings.usaNavAbout, onAbout),
      (strings.usaNavServices, onServices),
      (strings.usaNavDealers, onDealers),
      (strings.usaNavContacts, onContacts),
      (strings.usaRequestTitle, onConsult),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: items[i].$2,
            child: Center(
              child: Text(
                items[i].$1.toUpperCase(),
                style: const TextStyle(
                  color: kLTransInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RouteBanner extends StatelessWidget {
  const _RouteBanner({
    required this.active,
    required this.exclusive,
    required this.daysShort,
    required this.usa,
    required this.ocean,
    required this.europe,
    required this.ukraine,
  });

  final bool active;
  final String exclusive;
  final String daysShort;
  final String usa;
  final String ocean;
  final String europe;
  final String ukraine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 156,
        child: Stack(
          fit: StackFit.expand,
          children: [
            UsaAtlanticCrossing(
              active: active,
              usa: usa,
              ocean: ocean,
              europe: europe,
              ukraine: ukraine,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _MapChip(text: exclusive, accent: true),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _MapChip(text: daysShort),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.turnkey,
    required this.days,
    required this.lead,
    required this.consultLabel,
    required this.onConsult,
  });

  final String turnkey;
  final String days;
  final String lead;
  final String consultLabel;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xFF061018),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                turnkey,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days,
                style: const TextStyle(
                  color: kLTransRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lead,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kLTransRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    overlayColor: Colors.white.withValues(alpha: 0.22),
                  ),
                  onPressed: onConsult,
                  child: Text(
                    consultLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.15,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE0101820),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent ? kLTransRed.withValues(alpha: 0.7) : const Color(0x44FFFFFF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: accent ? kLTransRed : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({required this.lang});

  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    final chips = [
      const L('Copart', 'Copart', 'Copart'),
      const L('IAAI', 'IAAI', 'IAAI'),
      const L('Manheim', 'Manheim', 'Manheim'),
      const L('Митниця UA', 'UA customs', 'Таможня UA'),
      const L('Двері до дверей', 'Door to door', 'Дверь к двери'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Text(
              c.of(lang),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kLTransInk),
            ),
          ),
      ],
    );
  }
}

class _Pipeline extends StatefulWidget {
  const _Pipeline({
    required this.lang,
    required this.active,
    required this.play,
    required this.onPick,
  });

  final AppLang lang;
  final int active;
  final bool play;
  final ValueChanged<int> onPick;

  @override
  State<_Pipeline> createState() => _PipelineState();
}

class _PipelineState extends State<_Pipeline> with SingleTickerProviderStateMixin {
  late final AnimationController _run;
  int _last = -1;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000));
    _run.addListener(_tick);
    if (widget.play) _start();
  }

  @override
  void didUpdateWidget(covariant _Pipeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !_started) _start();
  }

  void _start() {
    _started = true;
    _run.repeat();
  }

  void _tick() {
    final i = (_run.value * 3.99).floor().clamp(0, 3);
    if (i == _last) return;
    _last = i;
    widget.onPick(i);
  }

  @override
  void dispose() {
    _run.removeListener(_tick);
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _run,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final colW = constraints.maxWidth / kUsaSteps.length;
            final disc = (colW - 10).clamp(52.0, 70.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: disc,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: disc * 0.5,
                        right: disc * 0.5,
                        top: disc * 0.5 - 1.5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _run.value,
                            minHeight: 3,
                            color: kLTransRed,
                            backgroundColor: const Color(0x33FFFFFF),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < kUsaSteps.length; i++)
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: disc,
                                  height: disc,
                                  child: GestureDetector(
                                    onTap: () => widget.onPick(i),
                                    child: RepaintBoundary(
                                      child: UsaPipelineNode(
                                        scene: kUsaSteps[i].scene,
                                        on: i == widget.active,
                                        done: i < widget.active,
                                        loop: _run.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < kUsaSteps.length; i++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onPick(i),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: SizedBox(
                                height: 32,
                                child: Text(
                                  kUsaSteps[i].title.of(widget.lang),
                                  maxLines: 2,
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10.5,
                                    height: 1.2,
                                    letterSpacing: 0,
                                    color: i == widget.active ? kLTransInk : const Color(0xFF8E8E96),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CatalogGate extends StatelessWidget {
  const _CatalogGate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1E),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.all(kLTransRed.withValues(alpha: 0.16)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kLTransRed.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kLTransRed, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kLTransInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB8B8BE), fontSize: 12.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF8E8E96)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsaCatalogPage extends StatelessWidget {
  const _UsaCatalogPage({
    required this.title,
    required this.lots,
    required this.lang,
    required this.palette,
    required this.onUse,
  });

  final String title;
  final List<UsaLot> lots;
  final AppLang lang;
  final AppPalette palette;
  final ValueChanged<UsaLot> onUse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLTransBg,
      appBar: AppBar(
        backgroundColor: kLTransBg,
        foregroundColor: kLTransInk,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.15),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: lots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final lot = lots[i];
          return SizedBox(
            height: 268,
            child: _LotCard(
              lot: lot,
              lang: lang,
              palette: palette,
              onUse: () {
                onUse(lot);
                Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({
    required this.lot,
    required this.lang,
    required this.palette,
    required this.onUse,
  });

  final UsaLot lot;
  final AppLang lang;
  final AppPalette palette;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final uah = usaLandedUah(
      bidUsd: lot.bidUsd,
      engineL: lot.engineL == 0 ? 0 : lot.engineL,
      year: lot.year,
      fuel: lot.fuel,
    );
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onUse,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 122,
                width: double.infinity,
                child: ShopColorPhoto(url: lot.photo, cacheWidth: 560),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lot.year} ${lot.title.of(lang)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(lot.yard.of(lang), style: TextStyle(color: palette.muted, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text(
                      '${formatUah(uah)} ${const L('під ключ', 'turnkey', 'под ключ').of(lang)}',
                      style: TextStyle(color: palette.accent, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lot.status.of(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatUsd(int amount) {
  final formatted = NumberFormat.decimalPattern('en_US').format(amount);
  return '\$$formatted';
}

String _fuelLabel(String id, AppLang lang) => switch (id) {
      'diesel' => const L('Дизель', 'Diesel', 'Дизель').of(lang),
      'hybrid' => const L('Гібрид', 'Hybrid', 'Гибрид').of(lang),
      'ev' => const L('EV', 'EV', 'EV').of(lang),
      _ => const L('Бензин', 'Petrol', 'Бензин').of(lang),
    };

class _CalcCard extends StatefulWidget {
  const _CalcCard({
    required this.lang,
    required this.vehicle,
    required this.bidText,
    required this.engineText,
    required this.bid,
    required this.engine,
    required this.year,
    required this.fuel,
    required this.quote,
    required this.onBid,
    required this.onEngine,
    required this.onYear,
    required this.onFuel,
  });

  final AppLang lang;
  final TextEditingController vehicle;
  final TextEditingController bidText;
  final TextEditingController engineText;
  final int bid;
  final double engine;
  final int year;
  final String fuel;
  final UsaLandedQuote quote;
  final ValueChanged<int> onBid;
  final ValueChanged<double> onEngine;
  final ValueChanged<int> onYear;
  final ValueChanged<String> onFuel;

  @override
  State<_CalcCard> createState() => _CalcCardState();
}

class _CalcCardState extends State<_CalcCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 16000))
      ..repeat();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFB8B8BE), fontSize: 13),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Color(0xFF8E8E96), fontWeight: FontWeight.w700),
      filled: true,
      fillColor: const Color(0xFF111114),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: kLTransRed.withValues(alpha: 0.75)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final quote = widget.quote;
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: kLTransRed,
      thumbColor: kLTransRed,
      inactiveTrackColor: const Color(0x33FFFFFF),
      overlayColor: kLTransRed.withValues(alpha: 0.12),
      trackHeight: 2,
    );

    final terms = <(String, String, int)>[
      ('', const L('Ставка на аукціоні', 'Auction bid', 'Ставка на аукционе').of(lang), quote.bidUsd),
      ('+', const L('збір аукціону', 'auction fee', 'сбор аукциона').of(lang), quote.auctionFeeUsd),
      ('+', const L('доставка по Америці', 'US inland delivery', 'доставка по Америке').of(lang), quote.inlandUsd),
      ('+', const L('доставка по океану', 'ocean freight', 'доставка по океану').of(lang), quote.oceanUsd),
      ('+', const L('мито', 'duty', 'пошлина').of(lang), quote.dutyUsd),
      ('+', const L('акциз', 'excise', 'акциз').of(lang), quote.exciseUsd),
      ('+', const L('ПДВ', 'VAT', 'НДС').of(lang), quote.vatUsd),
      ('+', const L('брокер', 'broker', 'брокер').of(lang), quote.brokerUsd),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kLTransRed.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.vehicle,
            style: const TextStyle(color: kLTransInk, fontWeight: FontWeight.w600),
            textCapitalization: TextCapitalization.words,
            decoration: _deco(
              const L('Авто (марка, модель або лот)', 'Vehicle (make, model or lot)', 'Авто (марка, модель или лот)').of(lang),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.bidText,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: kLTransInk, fontWeight: FontWeight.w800, fontSize: 16),
            decoration: _deco(
              const L('Ставка на аукціоні', 'Auction bid', 'Ставка на аукционе').of(lang),
              suffix: 'USD',
            ),
            onChanged: (raw) {
              final n = int.tryParse(raw);
              widget.onBid(n == null ? 0 : n.clamp(0, 250000));
            },
          ),
          SliderTheme(
            data: sliderTheme,
            child: Slider(
              value: widget.bid.toDouble().clamp(3000.0, 50000.0),
              min: 3000,
              max: 50000,
              divisions: 94,
              onChanged: (v) {
                final n = v.round();
                widget.bidText.value = TextEditingValue(
                  text: '$n',
                  selection: TextSelection.collapsed(offset: '$n'.length),
                );
                widget.onBid(n);
              },
            ),
          ),
          if (widget.fuel != 'ev') ...[
            TextField(
              controller: widget.engineText,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              style: const TextStyle(color: kLTransInk, fontWeight: FontWeight.w800),
              decoration: _deco(
                const L('Обʼєм двигуна', 'Engine volume', 'Объём двигателя').of(lang),
                suffix: 'L',
              ),
              onChanged: (raw) {
                final n = double.tryParse(raw.replaceAll(',', '.'));
                if (n != null && n > 0) widget.onEngine(n.clamp(0.6, 8.0));
              },
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text(
                const L('Рік випуску', 'Year of manufacture', 'Год выпуска').of(lang),
                style: const TextStyle(color: Color(0xFFB8B8BE), fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${widget.year}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kLTransInk),
              ),
            ],
          ),
          SliderTheme(
            data: sliderTheme,
            child: Slider(
              value: widget.year.toDouble().clamp(2008.0, kUsaRatesYear.toDouble()),
              min: 2008,
              max: kUsaRatesYear.toDouble(),
              divisions: kUsaRatesYear - 2008,
              onChanged: (v) => widget.onYear(v.round()),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in const ['petrol', 'diesel', 'hybrid', 'ev'])
                ChoiceChip(
                  selected: widget.fuel == f,
                  label: Text(_fuelLabel(f, lang)),
                  selectedColor: kLTransRed,
                  labelStyle: TextStyle(
                    color: widget.fuel == f ? Colors.white : kLTransInk,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: const Color(0xFF111114),
                  onSelected: (_) => widget.onFuel(f),
                ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final lit = (_glow.value * 9).floor().clamp(0, 8);
              return Column(
                children: [
                  for (var i = 0; i < terms.length; i++)
                    _FormulaTerm(
                      op: terms[i].$1,
                      label: terms[i].$2,
                      amount: _formatUsd(terms[i].$3),
                      lit: lit == i,
                    ),
                  _FormulaTerm(
                    op: '=',
                    label: const L('авто в Україні', 'the car in Ukraine', 'авто в Украине').of(lang),
                    amount: _formatUsd(quote.totalUsd),
                    lit: lit == 8,
                    total: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            formatUah(quote.totalUah),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              color: kLTransRed,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            const L(
              'Орієнтир на вересень 2026 · Схід США → Одеса / Констанца · точна цифра після VIN',
              'Sept 2026 estimate · US East Coast → Odesa / Constanța · exact after VIN',
              'Ориентир на сентябрь 2026 · Восток США → Одесса / Констанца · точная цифра после VIN',
            ).of(lang),
            style: const TextStyle(color: Color(0xFF8E8E96), fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _FormulaTerm extends StatelessWidget {
  const _FormulaTerm({
    required this.op,
    required this.label,
    required this.amount,
    required this.lit,
    this.total = false,
  });

  final String op;
  final String label;
  final String amount;
  final bool lit;
  final bool total;

  @override
  Widget build(BuildContext context) {
    final color = total
        ? (lit ? kLTransRed : kLTransInk)
        : (lit ? kLTransInk : const Color(0xFF9A9AA2));
    final opColor = lit ? kLTransRed : const Color(0xFF6E6E76);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: lit ? kLTransRed.withValues(alpha: 0.55) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              op,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: op.isEmpty ? Colors.transparent : opColor,
                fontWeight: FontWeight.w800,
                fontSize: total ? 15 : 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: total ? 14.5 : 13,
                fontWeight: total || lit ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.15,
                height: 1.15,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: total ? kLTransRed : color,
              fontSize: total ? 16 : 13,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

