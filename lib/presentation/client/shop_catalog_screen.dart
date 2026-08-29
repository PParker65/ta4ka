import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_skin.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/booking_extras.dart';
import '../../data/geo_location.dart';
import '../../data/live_cams.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/shop_brand.dart';
import '../../domain/models/shop_models.dart';
import '../widgets/shop_mark.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'google_mini_map.dart';
import 'widgets/booking_bits.dart';
import 'widgets/feed_video_player.dart';
import 'widgets/services_marquee.dart';

class ShopCatalogScreen extends ConsumerStatefulWidget {
  const ShopCatalogScreen({super.key});

  @override
  ConsumerState<ShopCatalogScreen> createState() => _ShopCatalogScreenState();
}

class _ShopCatalogScreenState extends ConsumerState<ShopCatalogScreen> {
  final _cityQuery = TextEditingController();
  String _city = 'warsaw';
  ShopSort _sort = ShopSort.distance;
  double _mapLat = warsawCenter.lat;
  double _mapLng = warsawCenter.lng;
  double? _fromLat;
  double? _fromLng;
  String _mapLabel = 'Warsaw';
  bool _locating = false;

  @override
  void dispose() {
    _cityQuery.dispose();
    super.dispose();
  }

  List<ShopProfile> _shops(DateTime now, Set<String> taken) {
    return filterShops(
      cityId: _city,
      query: '',
      sort: _sort,
      now: now,
      taken: taken,
      lang: ref.read(localeProvider),
      fromLat: _fromLat,
      fromLng: _fromLng,
    );
  }

  void _applyCity(String raw) {
    final city = matchCityId(raw);
    final center = centerForCity(city == 'all' ? 'warsaw' : city);
    setState(() {
      _city = city == 'all' ? 'all' : city;
      _fromLat = null;
      _fromLng = null;
      _mapLat = center.lat;
      _mapLng = center.lng;
      _mapLabel = raw.trim().isEmpty ? 'Warsaw' : raw.trim();
      _sort = ShopSort.rating;
    });
    if (city != 'all') {
      ref.read(clientCityIdProvider.notifier).state = city;
    }
  }

  Future<void> _nearMe() async {
    final s = ref.read(stringsProvider);
    setState(() => _locating = true);
    final point = await detectLocation();
    if (!mounted) {
      return;
    }
    if (!point.isOk) {
      setState(() => _locating = false);
      final msg = switch (point.fail) {
        LocateFail.servicesOff => s.locateOff,
        LocateFail.denied || LocateFail.deniedForever => s.locateDenied,
        _ => s.locateError,
      };
      final openSettings = point.fail == LocateFail.deniedForever ||
          point.fail == LocateFail.servicesOff;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          action: openSettings
              ? SnackBarAction(
                  label: s.locateOpenSettings,
                  onPressed: () => openLocateSettings(
                    appSettings: point.fail == LocateFail.deniedForever,
                  ),
                )
              : null,
        ),
      );
      return;
    }
    final lat = point.lat!;
    final lng = point.lng!;
    final shops = filterShops(
      cityId: 'all',
      query: '',
      sort: ShopSort.distance,
      now: DateTime.now(),
      taken: ref.read(takenSlotsProvider),
      fromLat: lat,
      fromLng: lng,
    );
    final nearest = shops.isEmpty ? null : shops.first;
    setState(() {
      _locating = false;
      _city = 'all';
      _fromLat = lat;
      _fromLng = lng;
      _mapLat = lat;
      _mapLng = lng;
      _mapLabel = nearest == null
          ? s.locateYouAreHere
          : '${s.locateYouAreHere} · ${nearest.name.en}';
      _sort = ShopSort.distance;
    });
    ref.read(clientCityIdProvider.notifier).state = nearestCityId(lat, lng);
  }

  Widget _map(List<ShopProfile> shops) {
    final lang = ref.read(localeProvider);
    return GoogleMiniMap(
      lat: _mapLat,
      lng: _mapLng,
      label: _mapLabel,
      pins: [
        ShopMapPin(lat: _mapLat, lng: _mapLng, here: true, label: _mapLabel),
        for (final shop in shops.take(14))
          ShopMapPin(
            lat: shop.lat,
            lng: shop.lng,
            label: shop.name.of(lang),
          ),
      ],
    );
  }

  Widget _searchRow(AppStrings s) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityQuery,
            textInputAction: TextInputAction.search,
            onSubmitted: _applyCity,
            decoration: InputDecoration(
              hintText: s.cityFieldHint,
              prefixIcon: const Icon(CupertinoIcons.search),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: _locating ? null : _nearMe,
          icon: _locating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(CupertinoIcons.location_solid, size: 18),
          label: Text(s.findNearMe),
        ),
      ],
    );
  }

  void _openShop(ShopProfile shop) {
    pauseAllFeedVideos();
    resumeApexLiveVideos();
    ref.read(bookingProvider.notifier).openShop(shop.id, fullMenu: true);
    context.push('/home/shops/${shop.id}');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final tokens = tokensOf(context);
    final taken = ref.watch(takenSlotsProvider);
    final now = DateTime.now();
    final shops = _shops(now, taken);
    final heading = s.nearestShops;
    final bottomPad = shellClearance(context, extra: 20);
    final account = ref.watch(shopAccountProvider);

    Widget shopTile(ShopProfile shop, {bool compact = false}) {
      final times = openTimesToday(shop, now, taken);
      final displayName = shopClientName(shop, account, lang);
      final brand = brandForShop(shop: shop, account: account, displayName: displayName);
      if (compact) {
        final camOn = shopBayCameraOnline(shop.id);
        return ListTile(
          dense: true,
          isThreeLine: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: ShopMark(brand: brand, t: 1, size: 40),
          title: Text(displayName, style: shopTitleStyle(brand, size: 13, color: palette.text)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${shop.distanceKm.toStringAsFixed(1)} km · ★ ${shop.rating.toStringAsFixed(1)}',
                style: TextStyle(fontFamily: 'monospace', color: palette.muted, fontSize: 11),
              ),
              Text(
                camOn ? s.badgeLive : s.badgeOffline,
                style: TextStyle(
                  color: camOn ? kTodayFreeGreen : kTodayBusyRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          trailing: Icon(CupertinoIcons.chevron_right, size: 14, color: palette.accent),
          onTap: () => _openShop(shop),
        );
      }
      return _ShopCard(
        shop: shop,
        todayTimes: times,
        onTap: () => _openShop(shop),
        radius: tokens.cardRadius,
        borderWidth: tokens.borderWidth,
      );
    }

    final children = <Widget>[];
    switch (tokens.catalogLayout) {
      case CatalogLayout.cardsVertical:
        children.addAll([
          _searchRow(s),
          const SizedBox(height: 14),
          _map(shops),
          const SizedBox(height: 16),
          Text(heading, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (shops.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 40), child: Text(s.noShops, style: TextStyle(color: palette.muted)))
          else
            for (final shop in shops) ...[shopTile(shop), const SizedBox(height: 12)],
        ]);
      case CatalogLayout.mapThenList:
        children.addAll([
          _map(shops),
          const SizedBox(height: 10),
          _searchRow(s),
          const SizedBox(height: 12),
          Text(heading.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: palette.text)),
          const SizedBox(height: 8),
          for (final shop in shops) ...[shopTile(shop), const SizedBox(height: 0)],
        ]);
      case CatalogLayout.twoColumnGrid:
        children.addAll([
          _searchRow(s),
          const SizedBox(height: 14),
          _map(shops),
          const SizedBox(height: 14),
          Text(heading, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (var i = 0; i < shops.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: shopTile(shops[i])),
                  const SizedBox(width: 10),
                  Expanded(child: i + 1 < shops.length ? shopTile(shops[i + 1]) : const SizedBox.shrink()),
                ],
              ),
            ),
        ]);
      case CatalogLayout.denseRows:
        children.addAll([
          Text('> $heading', style: TextStyle(fontFamily: 'monospace', color: palette.accent, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _searchRow(s),
          const SizedBox(height: 8),
          _map(shops),
          const SizedBox(height: 8),
          Container(height: 1, color: palette.stroke),
          for (final shop in shops) ...[
            shopTile(shop, compact: true),
            Divider(height: 1, color: palette.stroke.withValues(alpha: 0.5)),
          ],
        ]);
      case CatalogLayout.magazineHero:
        children.addAll([
          if (shops.isNotEmpty) ...[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Material(
                color: palette.carbon,
                borderRadius: BorderRadius.circular(tokens.cardRadius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openShop(shops.first),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ShopCoverBanner(shopId: shops.first.id, height: 220, showName: false),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x33000000), Color(0xCC000000)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nearestShops, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(shopClientName(shops.first, account, lang), style: shopTitleStyle(brandForShop(shop: shops.first, account: account, displayName: shopClientName(shops.first, account, lang)), size: 26, color: Colors.white)),
                            const SizedBox(height: 6),
                            Text(shops.first.address.of(lang), style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _searchRow(s),
          const SizedBox(height: 14),
          _map(shops),
          const SizedBox(height: 14),
          for (final shop in shops.skip(shops.isEmpty ? 0 : 1)) ...[shopTile(shop), const SizedBox(height: 12)],
        ]);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: palette.bg.withValues(alpha: palette.isDark ? 0.42 : 0.88),
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        titleSpacing: 16,
        centerTitle: false,
        toolbarHeight: 62,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            s.shopsTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.08,
              letterSpacing: -0.42,
            ),
          ),
        ),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
          children: children,
        ),
      ),
    );
  }
}

class _ShopCard extends ConsumerWidget {
  const _ShopCard({
    required this.shop,
    required this.todayTimes,
    required this.onTap,
    this.radius = 16,
    this.borderWidth = 0.8,
  });

  final ShopProfile shop;
  final List<DateTime> todayTimes;
  final VoidCallback onTap;
  final double radius;
  final double borderWidth;

  bool _mapaActive(WidgetRef ref, ShopProfile shop) {
    final banned = ref.watch(mapaReportsProvider).bannedShopIds;
    if (banned.contains(shop.id)) {
      return false;
    }
    final account = ref.watch(shopAccountProvider);
    if (shop.id == account.catalogShopId) {
      return account.mapaHelpActive;
    }
    return shop.mapaHelp;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final isManagedShop = shop.id == 'pitlane' || shop.id == account.catalogShopId;
    final liveWorkIds = isManagedShop && account.offeredWorkIds.isNotEmpty
        ? account.offeredWorkIds
        : shop.workIds;
    final liveCustom = isManagedShop ? account.customServices : const <String>[];
    final shownWorkNames = <String>[
      for (final id in liveWorkIds)
        if (catalogWorkById(id) case final work?) work.title.of(lang),
      for (final item in liveCustom)
        if (item.trim().isNotEmpty) item.trim(),
    ];
    final displayName = shopClientName(shop, account, lang);
    final brand = brandForShop(shop: shop, account: account, displayName: displayName);

    final mapa = _mapaActive(ref, shop);

    final shell = BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: palette.stroke,
        width: borderWidth,
      ),
    );

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: shell,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 128,
                    child: ShopCoverBanner(shopId: shop.id, height: 128),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: shopTitleStyle(brand, size: 17, color: palette.text),
                                    ),
                                  ),
                                  if (mapa) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      CupertinoIcons.star_fill,
                                      size: 15,
                                      color: Color(0xFFFFD60A),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${shop.address.of(lang)} · ${shop.distanceKm.toStringAsFixed(1)} ${s.kmAway}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 18,
                          color: palette.muted,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StarRow(value: shop.rating, count: shop.reviewCount),
                        BayCamStatus(online: shopBayCameraOnline(shop.id), strings: s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TodaySlotStatus(
                    times: todayTimes,
                    strings: s,
                  ),
                  if (shownWorkNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          s.services,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            label: '${s.services}: ${shownWorkNames.join(', ')}',
                            child: ServicesMarquee(
                              items: shownWorkNames,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
