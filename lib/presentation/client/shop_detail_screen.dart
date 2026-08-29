import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../data/catalog_seed.dart';
import '../../data/live_cams.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/shop_brand.dart';
import '../widgets/shop_mark.dart';
import '../widgets/ui.dart';
import 'booking_format.dart';
import 'widgets/bay_live_camera.dart';
import 'widgets/booking_bits.dart';
import 'widgets/shop_intro.dart';
import 'widgets/what_you_get.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  @override
  void initState() {
    super.initState();
    final id = widget.shopId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(bookingProvider).shopId != id) {
        ref.read(bookingProvider.notifier).openShop(id, fullMenu: true);
      }
    });
  }

  void _next({required bool hasWorks}) {
    final s = ref.read(stringsProvider);
    if (!hasWorks) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.needService)));
      return;
    }
    context.push('/home/slots');
  }

  @override
  Widget build(BuildContext context) {
    final shop = shopById(widget.shopId) ?? shopById(Uri.decodeComponent(widget.shopId));
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final draft = ref.watch(bookingProvider);
    if (shop == null) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(backgroundColor: palette.bg, foregroundColor: palette.text),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(s.noShops, textAlign: TextAlign.center, style: TextStyle(color: palette.text)),
          ),
        ),
      );
    }

    final isManagedShop = shop.id == account.catalogShopId || shop.id == 'pitlane';
    final displayName = shopClientName(shop, account, lang);
    final brand = brandForShop(shop: shop, account: account, displayName: displayName);
    final effectiveWorkIds = isManagedShop && account.offeredWorkIds.isNotEmpty
        ? account.offeredWorkIds
        : shop.workIds;
    final customServices = isManagedShop ? account.customServices : const <String>[];
    final allEffective = [
      for (final id in effectiveWorkIds)
        if (catalogWorks.any((w) => w.id == id)) workById(id),
    ];
    final grouped = <RepairCategory, List<ServiceWork>>{};
    for (final work in allEffective) {
      grouped.putIfAbsent(work.category, () => []).add(work);
    }
    final offered = allEffective.map((work) => work.id).toSet();
    final selected = draft.workIds.intersection(offered);
    final total = selected.fold<int>(0, (sum, id) => sum + workById(id).priceStandard);
    final minutes = selected.fold<int>(0, (sum, id) => sum + workById(id).minutes);
    final hasWorks = selected.isNotEmpty;

    return ShopIntroGate(
      key: ValueKey('intro-${shop.id}'),
      brand: brand,
      name: displayName,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: palette.bg.withValues(alpha: palette.isDark ? 0.42 : 0.88),
          foregroundColor: palette.text,
          surfaceTintColor: Colors.transparent,
          title: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: shopTitleStyle(brand, size: 17, color: palette.text),
          ),
        ),
        body: ScreenCanvas(
          child: ListView(
            clipBehavior: Clip.hardEdge,
            padding: shellListPadding(context, top: 8, extra: 8),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ShopCoverBanner(shopId: shop.id, height: 188),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ShopMark(brand: brand, t: 1, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: shopTitleStyle(brand, size: 22, color: palette.text),
                                  ),
                                ),
                                if (shop.mapaHelp ||
                                    (shop.id == account.catalogShopId && account.mapaHelpActive))
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.star, size: 20, color: Color(0xFFFFD60A)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(shop.address.of(lang), style: TextStyle(color: palette.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      ShopRatingTap(
                        value: shop.rating,
                        count: shop.reviewCount,
                        hint: s.shopReviews,
                        onOpen: () => context.push(
                          '/home/shops/${Uri.encodeComponent(shop.id)}/reviews',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: BayCamStatus(
                          online: shopBayCameraOnline(shop.id),
                          strings: s,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              BayLiveCamera(
                seed: shop.id,
                liveLabel: s.bayLive,
                online: shopBayCameraOnline(shop.id),
                soonLead: s.bayCamSoonLead,
                soonHope: s.bayCamSoonHope,
              ),
              const SizedBox(height: 18),
              Text(
                s.services,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: palette.text),
              ),
              const SizedBox(height: 12),
              for (final entry in grouped.entries) ...[
                Text(
                  categoryLabel(s, entry.key),
                  style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent),
                ),
                const SizedBox(height: 8),
                for (final work in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WorkPickTile(
                      work: work,
                      selected: selected.contains(work.id),
                      lang: lang,
                      strings: s,
                      onToggle: () => ref.read(bookingProvider.notifier).toggleWork(work.id),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              if (customServices.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final item in customServices) Chip(label: Text(item))],
                ),
              ],
              if (selected.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    '${s.preTotal}: ${formatUah(total)} · ${formatEta(minutes, s)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: palette.text),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _next(hasWorks: hasWorks),
                    child: Text(
                      '${s.next} · ${selected.length} · ${formatUah(total)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
