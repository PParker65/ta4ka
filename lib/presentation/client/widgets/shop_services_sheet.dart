import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/currency/uah.dart';
import '../../../data/auto_spheres.dart';
import '../../../domain/models/shop_models.dart';
import '../booking_format.dart';

Future<void> showShopServicesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ShopProfile shop,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _ShopServicesSheet(shop: shop);
    },
  );
}

class _ShopServicesSheet extends ConsumerWidget {
  const _ShopServicesSheet({required this.shop});

  final ShopProfile shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final draft = ref.watch(bookingProvider);
    final sphereWorks = sphereById(draft.sphereId ?? '')?.workIds.toSet();
    final listed = worksFor(shop, sphereWorkIds: sphereWorks);
    final works = listed.isEmpty ? worksFor(shop) : listed;
    final offered = {for (final work in works) work.id};
    final selected = draft.workIds.intersection(offered);
    final total = selected.fold<int>(
      0,
      (sum, id) => sum + workById(id).priceStandard,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop.name.of(lang),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(s.pickServices, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.48,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: works.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final work = works[index];
                  final on = selected.contains(work.id);
                  return Material(
                    color: on ? palette.carbon : palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ref.read(bookingProvider.notifier).openShop(shop.id);
                        ref.read(bookingProvider.notifier).toggleWork(work.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Icon(
                              on ? Icons.check_circle : Icons.circle_outlined,
                              color: on ? palette.accent : palette.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                work.title.of(lang),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: palette.text,
                                ),
                              ),
                            ),
                            Text(
                              formatUah(work.priceStandard),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: palette.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selected.isEmpty
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.needService)),
                        );
                      }
                    : () {
                        ref.read(bookingProvider.notifier).openShop(shop.id);
                        Navigator.of(context).pop();
                        context.push('/home/shops/${Uri.encodeComponent(shop.id)}');
                      },
                child: Text(
                  selected.isEmpty
                      ? s.pickServices
                      : '${s.continueBooking} · ${selected.length} · ${formatUah(total)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
