import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/auto_spheres.dart';
import '../auth/brand_part_thumb.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'widgets/category_icon.dart';
import 'widgets/usa_intro.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.sphereId});

  final String sphereId;

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hero;

  @override
  void initState() {
    super.initState();
    _hero = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    if (widget.sphereId == 'usa') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sectionSlideDirProvider.notifier).state = 1;
        ref.read(clientTabProvider.notifier).state = ClientTabs.usa;
        context.go('/home');
      });
    }
  }

  @override
  void dispose() {
    _hero.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final sphere = sphereById(widget.sphereId);
    if (sphere == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tabCategories)),
        body: const Center(child: Text('—')),
      );
    }

    void openShops() {
      ref.read(sceneSphereIdProvider.notifier).state = sphere.id;
      ref.read(bookingProvider.notifier).pickSphere(sphere.id);
      ref.read(sectionSlideDirProvider.notifier).state = 1;
      ref.read(clientTabProvider.notifier).state = ClientTabs.shops;
      context.go('/home');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sphere.title.of(lang)),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        sphereId: sphere.id,
        child: ListView(
          padding: shellListPadding(context),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    sphere.id == 'usa'
                        ? const LTransEnergyArt(
                            wordmark: true,
                            showRoute: true,
                            lionAlign: Alignment.centerRight,
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              1.16, -0.04, -0.04, 0, 10,
                              -0.04, 1.16, -0.04, 0, 10,
                              -0.04, -0.04, 1.16, 0, 10,
                              0, 0, 0, 1, 0,
                            ]),
                            child: Image.asset(
                              sphere.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => ColoredBox(
                                color: sphere.color.withValues(alpha: 0.2),
                                child: Icon(sphere.icon, color: sphere.color, size: 48),
                              ),
                            ),
                          ),
                    if (sphere.id != 'usa')
                      CustomPaint(
                        painter: PartAccentPainter(
                          sphereId: sphere.id,
                          brandColor: sphere.color,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            palette.bg.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: FadeTransition(
                        opacity: CurvedAnimation(parent: _hero, curve: Curves.easeOut),
                        child: CategoryIconBadge(
                          sphere: sphere,
                          size: 56,
                          iconSize: 28,
                          radius: 16,
                          hero: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryIconBadge(
                        sphere: sphere,
                        size: 44,
                        iconSize: 22,
                        radius: 12,
                        hero: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sphere.subtitle.of(lang).trim().isEmpty
                              ? sphere.title.of(lang)
                              : sphere.subtitle.of(lang),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: palette.text,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sphere.detail.of(lang),
                    style: TextStyle(color: palette.muted, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sphere.priceHint.of(lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: openShops,
              icon: const Icon(CupertinoIcons.square_grid_2x2, size: 18),
              label: Text(s.categoryFindShops),
            ),
          ],
        ),
      ),
    );
  }
}
