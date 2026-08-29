import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/feed_clips.dart';
import '../../data/geo_location.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/shop_models.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'widgets/booking_bits.dart';
import 'widgets/feed_video_player.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _page = PageController();
  int _active = 0;
  Listenable? _routeListenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GoRouter.of(context).routerDelegate;
    if (_routeListenable != next) {
      _routeListenable?.removeListener(_onRoute);
      _routeListenable = next;
      _routeListenable!.addListener(_onRoute);
    }
  }

  void _onRoute() {
    if (!mounted) return;
    if (_feedCovered) {
      pauseAllFeedVideos();
    }
    setState(() {});
  }

  bool get _feedCovered {
    final path = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return path != '/home';
  }

  Future<void> _refreshCityFromGeo() async {
    final point = await detectLocation();
    if (!mounted || !point.isOk) return;
    final city = nearestCityId(point.lat!, point.lng!);
    if (ref.read(clientCityIdProvider) == city) return;
    ref.read(clientCityIdProvider.notifier).state = city;
  }

  void _rewindToFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_active != 0) setState(() => _active = 0);
      if (_page.hasClients) _page.jumpToPage(0);
    });
  }

  Future<void> _openShop(ShopProfile shop) async {
    pauseAllFeedVideos();
    ref.read(bookingProvider.notifier).openShop(shop.id, fullMenu: true);
    if (!mounted) return;
    await context.push('/home/shops/${shop.id}');
    pauseAllFeedVideos();
  }

  @override
  void dispose() {
    _routeListenable?.removeListener(_onRoute);
    _page.dispose();
    super.dispose();
  }

  String _formatViews(int count, AppStrings s) {
    String label;
    if (count >= 1000000) {
      final m = count / 1000000;
      label = m >= 10 ? '${m.round()}M' : '${m.toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (count >= 1000) {
      label = '${(count / 1000).round()}K';
    } else {
      label = '$count';
    }
    return s.feedViews(label);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final filter = ref.watch(bookingProvider).feedShopId;
    final onFeedTab = ref.watch(clientTabProvider) == ClientTabs.feed;
    final tick = ref.watch(feedShuffleTickProvider);
    final cityId = ref.watch(clientCityIdProvider);
    final covering = _feedCovered;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom + 56;
    final clips = rotateFeedClips(seed: tick, cityId: cityId, shopFilter: filter);

    ref.listen<int>(feedShuffleTickProvider, (previous, next) {
      if (previous == next) return;
      unawaited(_refreshCityFromGeo());
      _rewindToFirst();
    });
    ref.listen<String>(clientCityIdProvider, (previous, next) {
      if (previous == next) return;
      _rewindToFirst();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.tabFeed),
        actions: [
          if (filter != null)
            TextButton(
              onPressed: () => ref.read(bookingProvider.notifier).clearFeedFilter(),
              child: Text(s.allFeed),
            ),
          const AppBarTools(),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: clips.isEmpty
          ? ScreenCanvas(
              child: Center(
                child: Text(s.feedEmpty, style: TextStyle(color: palette.muted)),
              ),
            )
          : Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: PageView.builder(
                controller: _page,
                scrollDirection: Axis.vertical,
                itemCount: clips.length,
                onPageChanged: (i) => setState(() => _active = i),
                itemBuilder: (context, index) => _FeedReel(
                  key: ValueKey('${tick}_${clips[index].id}'),
                  clip: clips[index],
                  playVideo: onFeedTab && index == _active && !covering,
                  lang: lang,
                  strings: s,
                  viewLabel: _formatViews(clips[index].viewCount, s),
                  onBook: _openShop,
                  takenSlots: ref.watch(takenSlotsProvider),
                ),
              ),
            ),
    );
  }
}

class _FeedReel extends StatelessWidget {
  const _FeedReel({
    super.key,
    required this.clip,
    required this.playVideo,
    required this.lang,
    required this.strings,
    required this.viewLabel,
    required this.onBook,
    required this.takenSlots,
  });

  final FeedClip clip;
  final bool playVideo;
  final AppLang lang;
  final AppStrings strings;
  final String viewLabel;
  final void Function(ShopProfile shop) onBook;
  final Set<String> takenSlots;

  @override
  Widget build(BuildContext context) {
    final shop = shopById(clip.shopId);
    final palette = paletteOf(context);
    final videoUrl = clip.playbackUrl;
    final assetPath = clip.videoAsset == null || clip.videoAsset!.isEmpty
        ? null
        : 'assets/feed/${clip.videoAsset}';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (videoUrl.isNotEmpty || assetPath != null)
          FeedVideoPlayer(
            url: videoUrl,
            assetPath: assetPath,
            play: playVideo,
            posterUrl: clip.youtubeThumbnail.isEmpty ? null : clip.youtubeThumbnail,
          )
        else
          ColoredBox(color: palette.surface),

        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.88),
              ],
              stops: const [0, 0.25, 0.55, 1],
            ),
          ),
        ),

        if (shop != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onBook(shop),
              child: const ColoredBox(color: Color(0x01000000)),
            ),
          ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (clip.live) BadgePill(label: strings.badgeLive, live: true),
                    if (clip.live) const SizedBox(width: 8),
                    if (clip.viewCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.eye, color: Colors.white70, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              viewLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      clip.video ? CupertinoIcons.play_circle : CupertinoIcons.photo,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ],
                ),
                const Spacer(),
                if (clip.channel != null)
                  Text(
                    clip.channel!.of(lang),
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  clip.title.of(lang),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  clip.caption.of(lang),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                ),
                if (shop != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    shop.name.of(lang),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TodaySlotStatus(
                    times: openTimesToday(shop, DateTime.now(), takenSlots),
                    strings: strings,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => onBook(shop),
                      child: Text(strings.bookHere),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
