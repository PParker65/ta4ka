import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/factor_rating.dart';
import '../widgets/oleg_card.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class ClientKioskView extends ConsumerWidget {
  const ClientKioskView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.clientKiosk),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                HeroPanel(
                  icon: Icons.touch_app,
                  title: s.clientKioskWelcome,
                  subtitle: s.clientKioskLead,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, color: palette.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.pricesInUah,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OlegCard(title: s.olegTitle, tips: [s.olegIntro]),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(kioskProvider.notifier).reset();
                    context.push('/client-kiosk/flow');
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(s.startBooking),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KioskRatingScreen extends ConsumerStatefulWidget {
  const KioskRatingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<KioskRatingScreen> createState() => _KioskRatingScreenState();
}

class _KioskRatingScreenState extends ConsumerState<KioskRatingScreen> {
  int _quality = 5;
  int _politeness = 5;
  int _punctuality = 5;
  int _cleanliness = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  WorkOrder? _findOrder(List<WorkOrder> orders) {
    for (final order in orders) {
      if (order.id == widget.orderId) return order;
    }
    return null;
  }

  void _submit(AppStrings s, WorkOrder? order, {required bool skip}) {
    if (order != null && !skip) {
      ref.read(ratingsProvider.notifier).add(
            Rating(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              orderId: order.id,
              masterId: order.masterId ?? 'kiosk',
              quality: _quality,
              politeness: _politeness,
              punctuality: _punctuality,
              cleanliness: _cleanliness,
              comment: _comment.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
    }
    ref.read(kioskProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(skip ? s.orderCreated : s.thankYou)),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final order = _findOrder(ref.watch(ordersProvider));
    final palette = paletteOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.rateTitle),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Text(
                          s.howWasVisit,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(s.rateHint, textAlign: TextAlign.center),
                        if (order != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.carbon,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${s.yourOrder}\n${order.brand} ${order.model} · ${order.plate}\n${formatUah(order.totalUah)}\n${order.lines.map((line) => line.title.of(lang)).take(2).join(', ')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        FactorRating(
                          label: s.rateQuality,
                          value: _quality,
                          onChanged: (value) => setState(() => _quality = value),
                        ),
                        FactorRating(
                          label: s.ratePoliteness,
                          value: _politeness,
                          onChanged: (value) =>
                              setState(() => _politeness = value),
                        ),
                        FactorRating(
                          label: s.ratePunctuality,
                          value: _punctuality,
                          onChanged: (value) =>
                              setState(() => _punctuality = value),
                        ),
                        FactorRating(
                          label: s.rateCleanliness,
                          value: _cleanliness,
                          onChanged: (value) =>
                              setState(() => _cleanliness = value),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _comment,
                          maxLines: 4,
                          decoration: InputDecoration(labelText: s.writeReview),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _submit(s, order, skip: false),
                            child: Text(s.sendRating),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _submit(s, order, skip: true),
                          child: Text(s.skipRating),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
