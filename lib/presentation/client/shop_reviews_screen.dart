import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/shop_models.dart';
import '../widgets/ui.dart';
import 'widgets/booking_bits.dart';

const _kDemoReviews = <ShopReview>[
  ShopReview(
    author: 'Олена',
    stars: 5,
    text: L(
      'Чітко по роботах і по часу. На підйомнику видно з камери.',
      'Clear on the jobs and the time. You can see the lift on camera.',
      'Чётко по работам и по времени. На подъёмнике видно с камеры.',
      'Jasno co do prac i godziny. Podnośnik widać na kamerze.',
    ),
  ),
  ShopReview(
    author: 'Andrii',
    stars: 4,
    text: L(
      'Зробили ходову без нав’язаних послуг. Чекали в зоні, все спокійно.',
      'They did the chassis work without extras. Waited in the lounge, all calm.',
      'Сделали ходовую без навязанных услуг. Ждали в зоне, всё спокойно.',
      'Zrobili zawieszenie bez dopychania usług. Czekałem w poczekalni, spokojnie.',
    ),
  ),
  ShopReview(
    author: 'Марина',
    stars: 5,
    text: L(
      'Пояснили, що міняти, показали деталь. Без сюрпризів у рахунку.',
      'They explained what to replace and showed the part. No bill surprises.',
      'Объяснили, что менять, показали деталь. Без сюрпризов в счёте.',
      'Wyjaśnili, co wymieniać, pokazali część. Bez niespodzianek na rachunku.',
    ),
  ),
];

List<ShopReview> shopReviewsFor(ShopProfile shop) {
  if (shop.reviews.isNotEmpty) return shop.reviews;
  return _kDemoReviews;
}

class ShopReviewsScreen extends ConsumerWidget {
  const ShopReviewsScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = shopById(shopId) ?? shopById(Uri.decodeComponent(shopId));
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    if (shop == null) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(backgroundColor: palette.bg, foregroundColor: palette.text),
        body: Center(
          child: Text(s.noShops, style: TextStyle(color: palette.text)),
        ),
      );
    }

    final reviews = shopReviewsFor(shop);
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg.withValues(alpha: palette.isDark ? 0.42 : 0.88),
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        title: Text(s.shopReviews),
      ),
      body: ScreenCanvas(
        child: ListView(
          clipBehavior: Clip.hardEdge,
          padding: shellListPadding(context, top: 8, extra: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  StarRow(value: shop.rating, count: shop.reviewCount, size: 18),
                  const Spacer(),
                  Text(
                    '${s.avgRating}: ${shop.rating.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  s.noRatings,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted),
                ),
              )
            else
              for (final review in reviews)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.author,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            StarRow(value: review.stars.toDouble()),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(review.text.of(lang), style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
