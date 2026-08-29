import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/design_skin.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/auto_spheres.dart';
import '../../data/car_brands.dart';
import '../../data/car_glb_models.dart';
import '../../data/glb_model_cache.dart';
import '../../data/car_hotspots.dart';
import '../widgets/category_scene.dart';
import '../widgets/theme_switcher.dart';
import 'brand_switcher_sheet.dart';
import 'brand_part_thumb.dart';
import 'glb_car_stage.dart';
import 'glb_car_viewer.dart' as glb_view;
import 'issue_composer.dart';
import 'brand_pick_panel.dart';

class PostLoginAiScreen extends ConsumerStatefulWidget {
  const PostLoginAiScreen({super.key, this.inShell = false});

  final bool inShell;

  @override
  ConsumerState<PostLoginAiScreen> createState() => _PostLoginAiScreenState();
}

class _PostLoginAiScreenState extends ConsumerState<PostLoginAiScreen> {
  final _brandQuery = TextEditingController();
  final _query = TextEditingController();
  final _picker = ImagePicker();
  bool _photoAttached = false;
  String? _photoBase64;
  String? _photoMime;
  Uint8List? _photoBytes;
  bool _loading = false;
  String _aiSummary = '';
  List<AutoSphere> _listSpheres = autoSpheres;
  List<AutoSphere> _highlightSpheres = const [];
  String? _selectedSphereId;
  String? _selectedHotspotId;
  CarBrand? _brand;
  final _listEpoch = ValueNotifier<int>(0);
  final _listScrolling = ValueNotifier<bool>(false);
  final _carPaused = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
    _listScrolling.addListener(_syncCarPause);
    _listSpheres = autoSpheres;
    // First open: logos + search. 3D car mounts only after a brand is picked.
  }

  @override
  void dispose() {
    _query.removeListener(_onQueryChanged);
    _listScrolling.removeListener(_syncCarPause);
    _listEpoch.dispose();
    _listScrolling.dispose();
    _carPaused.dispose();
    _query.dispose();
    _brandQuery.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    _refreshLocalMatches();
    _syncCarPause();
  }

  void _syncCarPause() {
    _carPaused.value = _listScrolling.value;
  }

  bool _onCarScroll(ScrollNotification n) {
    if (n is UserScrollNotification) {
      _listScrolling.value = n.direction != ScrollDirection.idle;
      return false;
    }
    if (n is ScrollStartNotification) {
      _listScrolling.value = true;
    } else if (n is ScrollEndNotification) {
      _listScrolling.value = false;
    }
    return false;
  }

  void _refreshLocalMatches() {
    final lang = ref.read(localeProvider);
    final query = _query.text;
    final results = searchSpheres(query, lang: lang);
    _listSpheres = query.trim().isEmpty ? autoSpheres : results;
    _highlightSpheres = query.trim().isEmpty ? const [] : results.take(5).toList();
    _listEpoch.value++;
  }

  void _openBrandSwitcher(AppStrings s, AppLang lang) {
    showBrandSwitcherSheet(
      context: context,
      lang: lang,
      strings: s,
      current: _brand,
      onPick: _confirmBrand,
    );
  }

  void _confirmBrand(CarBrand brand) {
    final glb = carGlbModelFor(brand);
    glb_view.prefetchGlb(glb.flutterAsset);
    unawaited(GlbModelCache.resolveSrc(glb));
    GlbModelCache.precacheNeighbors(brand.id);
    ref.read(bookingProvider.notifier).setCar(brand: brand.name.en);
    ref.read(carBrandPickedProvider.notifier).state = true;
    setState(() {
      _brand = brand;
      _selectedHotspotId = null;
      _selectedSphereId = null;
    });
  }

  void _backToBrandPicker() {
    _brandQuery.clear();
    ref.read(carBrandPickedProvider.notifier).state = false;
    setState(() {
      _brand = null;
      _selectedHotspotId = null;
      _selectedSphereId = null;
    });
  }

  Future<void> _attachPhoto() async {
    final s = ref.read(stringsProvider);
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _photoAttached = true;
        _photoBytes = bytes;
        _photoBase64 = base64Encode(bytes);
        _photoMime = _detectMime(file.name);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.aiPhotoAttached)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.photoError)),
      );
    }
  }

  Future<void> _analyze() async {
    if (_loading) {
      return;
    }
    final lang = ref.read(localeProvider);
    final s = ref.read(stringsProvider);
    final query = _query.text.trim();
    if (query.isEmpty && !_photoAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.aiQuickHint)),
      );
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(aiTriageApiProvider).analyze(
          query: query.isEmpty ? 'check engine' : query,
          lang: lang,
          photoBase64: _photoBase64,
          photoMime: _photoMime,
        );

    final merged = <String, AutoSphere>{};
    for (final sphere in searchSpheres(query, lang: lang)) {
      merged[sphere.id] = sphere;
    }
    for (final sphere in spheresFromIds(result.sphereIds)) {
      merged[sphere.id] = sphere;
    }

    final ranked = merged.values.toList();
    if (result.sphereIds.isNotEmpty) {
      ranked.sort((a, b) {
        final ai = result.sphereIds.indexOf(a.id);
        final bi = result.sphereIds.indexOf(b.id);
        if (ai == -1 && bi == -1) {
          return 0;
        }
        if (ai == -1) {
          return 1;
        }
        if (bi == -1) {
          return -1;
        }
        return ai.compareTo(bi);
      });
    }

    setState(() {
      _aiSummary = result.summary.of(lang);
      _listSpheres = ranked.isEmpty ? autoSpheres : ranked;
      _highlightSpheres = ranked.take(5).toList();
      _selectedSphereId = ranked.isNotEmpty ? ranked.first.id : null;
      _loading = false;
    });
    _listEpoch.value++;
  }

  void _clearCarFilter() {
    setState(() {
      _selectedHotspotId = null;
      _selectedSphereId = null;
    });
    _query.clear();
    _refreshLocalMatches();
  }

  void _onCarHotspot(CarHotspot hotspot) {
    setState(() {
      _selectedHotspotId = hotspot.id;
      _selectedSphereId = hotspot.sphereId;
    });
    ref.read(sceneSphereIdProvider.notifier).state = hotspot.sphereId;
  }

  void _onSphereTile(String sphereId) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedSphereId = sphereId);
    _goWithSphere(sphereId);
  }

  void _goWithSphere(String sphereId) {
    ref.read(sceneSphereIdProvider.notifier).state = sphereId;
    ref.read(bookingProvider.notifier).pickSphere(sphereId);
    if (sphereId == 'usa') {
      ref.read(sectionSlideDirProvider.notifier).state = 1;
      ref.read(clientTabProvider.notifier).state = ClientTabs.usa;
      if (!widget.inShell) {
        context.go('/home');
      }
      return;
    }
    context.push('/home/categories/$sphereId');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final brand = _brand;

    final phone = isPhoneLayout(context);
    final palette = paletteOf(context);
    final tokens = tokensOf(context);
    ref.listen<int>(carSearchClearTickProvider, (previous, next) {
      if (previous == next) return;
      _query.clear();
      _aiSummary = '';
      _refreshLocalMatches();
      if (mounted) setState(() {});
    });
    ref.listen<int>(carBrandClearTickProvider, (previous, next) {
      if (previous == next) return;
      if (_brand != null) _backToBrandPicker();
    });
    final shellBottom = widget.inShell
        ? MediaQuery.viewPaddingOf(context).bottom + tokens.shellBottomInset
        : 0.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: brand == null
            ? Colors.transparent
            : palette.bg.withValues(alpha: palette.isDark ? 0.42 : 0.82),
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: tokens.centerAppBarTitle,
        leading: brand == null
            ? null
            : IconButton(
                tooltip: s.back,
                onPressed: _backToBrandPicker,
                icon: const Icon(CupertinoIcons.chevron_back),
              ),
        title: brand == null
            ? null
            : BrandAppBarTitle(
                brand: brand,
                lang: lang,
                compact: phone,
                onTap: () => _openBrandSwitcher(s, lang),
              ),
        actions: const [AppBarTools(showWallet: false)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CategorySceneBackdrop(sphereId: _selectedSphereId),
          SafeArea(
            bottom: !widget.inShell,
            child: Padding(
              padding: EdgeInsets.only(bottom: shellBottom),
              child: Column(
                children: [
                  Expanded(
                    child: brand == null
                        ? BrandPickPanel(
                            query: _brandQuery,
                            lang: lang,
                            strings: s,
                            onConfirm: _confirmBrand,
                          )
                        : _buildSplit(s, lang, brand),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplit(AppStrings s, AppLang lang, CarBrand brand) {
    final carAccent = carUiAccent(brand);
    const blockAccent = kAutoBlockAccent;
    final search = _buildSearchPane(s, lang, brand, blockAccent);
    final car = _buildCarPane(s, lang, brand, carAccent);
    final layout = tokensOf(context).carLayout;
    return LayoutBuilder(
      builder: (context, constraints) {
        final phoneStack = constraints.maxWidth < 780;
        if (phoneStack) {
          return _phoneCarThenList(s, lang, brand, blockAccent, constraints, car);
        }
        switch (layout) {
          case CarStageLayout.carTopSearchBottom:
            return Row(
              children: [
                Expanded(flex: 69, child: search),
                Container(width: 0.5, color: paletteOf(context).stroke),
                Expanded(flex: 31, child: car),
              ],
            );
          case CarStageLayout.searchTopCarBottom:
            return Column(
              children: [
                Expanded(flex: 68, child: search),
                Container(height: 1, color: paletteOf(context).stroke),
                Expanded(flex: 32, child: car),
              ],
            );
          case CarStageLayout.searchFullCarCorner:
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: search),
                Positioned(
                  right: 8,
                  bottom: 8,
                  width: constraints.maxWidth * 0.315,
                  height: constraints.maxHeight * 0.27,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(tokensOf(context).cardRadius),
                    clipBehavior: Clip.antiAlias,
                    child: car,
                  ),
                ),
              ],
            );
          case CarStageLayout.alwaysSideBySide:
            return Row(
              children: [
                Expanded(flex: 33, child: car),
                Container(width: 1, color: paletteOf(context).stroke),
                Expanded(flex: 67, child: search),
              ],
            );
          case CarStageLayout.dashboardHalf:
            final p = paletteOf(context);
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: p.carbon,
                  child: Text(
                    s.aiCarHint,
                    style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: car),
                      Container(width: 1, color: p.stroke),
                      Expanded(flex: 7, child: search),
                    ],
                  ),
                ),
              ],
            );
        }
      },
    );
  }

  Widget _phoneCarThenList(
    AppStrings s,
    AppLang lang,
    CarBrand brand,
    Color accent,
    BoxConstraints constraints,
    Widget car,
  ) {
    final phone = isPhoneLayout(context);
    final pad = phone ? 14.0 : 20.0;
    final carH = (constraints.maxHeight * 0.30).clamp(188.0, 248.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: carH,
          child: car,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: carH),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
              child: IssueComposer(
                key: const ValueKey('car-issue-composer'),
                strings: s,
                query: _query,
                loading: _loading,
                photoAttached: _photoAttached,
                photoBytes: _photoBytes,
                onPhoto: _attachPhoto,
                onAnalyze: _analyze,
                onClear: _clearCarFilter,
                accentColor: accent,
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onCarScroll,
                child: ValueListenableBuilder<int>(
                valueListenable: _listEpoch,
                builder: (context, _, __) {
                  final overlay = _query.text.trim().isNotEmpty;
                  return overlay
                      ? _SearchMatchOverlay(
                          strings: s,
                          lang: lang,
                          brand: brand,
                          accent: accent,
                          query: _query,
                          matches: _listSpheres,
                          selectedId: _selectedSphereId,
                          onPick: _onSphereTile,
                        )
                      : _buildSpheresList(s, lang, brand, accent);
                },
              ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarPane(AppStrings s, AppLang lang, CarBrand brand, Color accent) {
    final carTabActive =
        !widget.inShell || ref.watch(clientTabProvider) == ClientTabs.car;
    return RepaintBoundary(
      child: GlbCarStage(
        key: ValueKey(brand.id),
        lang: lang,
        hint: s.aiCarHint,
        selectedHotspotId: _selectedHotspotId,
        onSelect: _onCarHotspot,
        embedded: true,
        accentColor: accent,
        brand: brand,
        autoRotate: true,
        active: carTabActive,
        rotatePaused: _carPaused,
      ),
    );
  }

  Widget _buildSearchPane(AppStrings s, AppLang lang, CarBrand brand, Color accent) {
    final phone = isPhoneLayout(context);
    final pad = phone ? 14.0 : 20.0;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, phone ? 6 : 12, pad, 0),
          child: IssueComposer(
            strings: s,
            query: _query,
            loading: _loading,
            photoAttached: _photoAttached,
            photoBytes: _photoBytes,
            onPhoto: _attachPhoto,
            onAnalyze: _analyze,
            onClear: _clearCarFilter,
            accentColor: accent,
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onCarScroll,
            child: _buildSpheresList(s, lang, brand, accent),
          ),
        ),
      ],
    );
  }

  Widget _buildSpheresList(AppStrings s, AppLang lang, CarBrand brand, Color accent) {
    final phone = isPhoneLayout(context);
    return ValueListenableBuilder<int>(
      valueListenable: _listEpoch,
      builder: (context, _, __) {
        final query = _query.text.trim();
        final list = _listSpheres;
        final highlights = _highlightSpheres;
        final listTitle = query.isEmpty ? s.aiSpheresList : s.aiSpheresResults;
        final palette = paletteOf(context);
        return CustomScrollView(
            slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(phone ? 14 : 20, 10, phone ? 14 : 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (query.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: palette.muted),
                          onPressed: _clearCarFilter,
                          icon: const Icon(CupertinoIcons.chevron_back, size: 18),
                          label: Text(s.aiBackToAll),
                        ),
                      ),
                    if (_aiSummary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _aiSummary,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 15,
                          height: 1.4,
                          shadows: sceneTextShadow(palette, blur: 8),
                        ),
                      ),
                    ],
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        s.aiSpheresHighlight,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                          fontSize: phone ? 17 : 21,
                          letterSpacing: 0.2,
                          shadows: sceneTextShadow(palette),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: phone ? 168 : 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: highlights.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final sphere = highlights[index];
                            return _SphereImageCard(
                              sphere: sphere,
                              brand: brand,
                              accent: accent,
                              lang: lang,
                              query: query,
                              selected: sphere.id == _selectedSphereId,
                              onTap: () => _onSphereTile(sphere.id),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      listTitle,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: phone ? 17 : 21,
                        letterSpacing: 0.2,
                        shadows: sceneTextShadow(palette),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(phone ? 14 : 20, 0, phone ? 14 : 20, 28),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  return RepaintBoundary(
                    child: _OlxSphereTile(
                      sphere: list[i],
                      brand: brand,
                      accent: accent,
                      lang: lang,
                      query: query,
                      selected: list[i].id == _selectedSphereId,
                      onTap: () => _onSphereTile(list[i].id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SphereImageCard extends StatelessWidget {
  const _SphereImageCard({
    required this.sphere,
    required this.brand,
    required this.accent,
    required this.lang,
    required this.query,
    required this.selected,
    required this.onTap,
  });

  final AutoSphere sphere;
  final CarBrand brand;
  final Color accent;
  final AppLang lang;
  final String query;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phone = isPhoneLayout(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: phone ? 148 : 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : sceneHairline(palette),
            width: selected ? 2 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BrandPartThumb(brand: brand, sphere: sphere, radius: 0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.isDark
                      ? const [Color(0x00000000), Color(0xCC000000)]
                      : [
                          const Color(0x00FFFFFF),
                          palette.surface.withValues(alpha: 0.94),
                        ],
                ),
              ),
            ),
            Positioned(
              left: phone ? 8 : 12,
              right: phone ? 8 : 12,
              bottom: phone ? 8 : 10,
              child: HighlightText(
                text: sphere.title.of(lang),
                query: query,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                  fontSize: phone ? 13 : 16,
                  letterSpacing: -0.24,
                  height: 1.25,
                  shadows: sceneTextShadow(palette, blur: 8),
                ),
                highlightStyle: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: phone ? 13 : 16,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OlxSphereTile extends StatelessWidget {
  const _OlxSphereTile({
    required this.sphere,
    required this.brand,
    required this.accent,
    required this.lang,
    required this.query,
    required this.selected,
    required this.onTap,
  });

  final AutoSphere sphere;
  final CarBrand brand;
  final Color accent;
  final AppLang lang;
  final String query;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phone = isPhoneLayout(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: phone ? 96 : 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : sceneHairline(palette),
              width: selected ? 2 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BrandPartThumb(brand: brand, sphere: sphere, radius: 0),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: palette.isDark
                        ? const [
                            Color(0xE6000000),
                            Color(0x66000000),
                            Color(0x33000000),
                          ]
                        : [
                            palette.surface.withValues(alpha: 0.96),
                            palette.surface.withValues(alpha: 0.72),
                            palette.surface.withValues(alpha: 0.18),
                          ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(phone ? 12 : 16, phone ? 10 : 14, phone ? 10 : 14, phone ? 10 : 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HighlightText(
                            text: sphere.title.of(lang),
                            query: query,
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: phone ? 15 : 18,
                              letterSpacing: -0.24,
                              height: 1.25,
                            ),
                            highlightStyle: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                              fontSize: phone ? 15 : 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (sphere.subtitle.of(lang).trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              sphere.subtitle.of(lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: phone ? 12 : 14,
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            sphere.priceHint.of(lang),
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: phone ? 13 : 16,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 16,
                      color: selected ? accent : palette.muted,
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

class _SearchMatchOverlay extends StatelessWidget {
  const _SearchMatchOverlay({
    required this.strings,
    required this.lang,
    required this.brand,
    required this.accent,
    required this.query,
    required this.matches,
    required this.selectedId,
    required this.onPick,
  });

  final AppStrings strings;
  final AppLang lang;
  final CarBrand brand;
  final Color accent;
  final TextEditingController query;
  final List<AutoSphere> matches;
  final String? selectedId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phone = isPhoneLayout(context);
    final pad = phone ? 14.0 : 20.0;
    return ColoredBox(
          color: palette.bg.withValues(alpha: palette.isDark ? 0.94 : 0.96),
          child: matches.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Text(
                      strings.aiSpheresResults,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.muted),
                    ),
                  ),
                )
              : ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                  padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final sphere = matches[i];
                    final on = sphere.id == selectedId;
                    return Material(
                      color: palette.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onPick(sphere.id),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: BrandPartThumb(brand: brand, sphere: sphere, radius: 0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HighlightText(
                                      text: sphere.title.of(lang),
                                      query: query.text,
                                      style: TextStyle(
                                        color: on ? accent : palette.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        height: 1.2,
                                      ),
                                      highlightStyle: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (sphere.subtitle.of(lang).trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        sphere.subtitle.of(lang),
                                        style: TextStyle(
                                          color: palette.text,
                                          fontSize: 13,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      sphere.detail.of(lang),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.muted,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: on ? accent : palette.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class HighlightText extends StatelessWidget {
  const HighlightText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
    super.key,
  });

  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final start = lower.indexOf(q);
    if (start == -1) {
      return Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final end = start + q.length;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: highlightStyle),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

String _detectMime(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

