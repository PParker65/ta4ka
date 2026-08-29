import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/catalog_seed.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/factor_rating.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  String? _orderId;
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final orders = ref.watch(ordersProvider);
    final ratings = ref.watch(ratingsProvider);
    final ratedIds = ratings.map((item) => item.orderId).toSet();
    final ready = orders
        .where((order) => order.status == JobStatus.ready && !ratedIds.contains(order.id))
        .toList();
    final theme = Theme.of(context);
    final avg = ratings.isEmpty
        ? 0.0
        : ratings.fold<double>(0, (sum, item) => sum + item.average) /
            ratings.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.ratings),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.all(24),
        children: [
          Text(s.rateTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(s.rateHint),
          const SizedBox(height: 16),
          if (ready.isEmpty)
            Text(s.noCompleted)
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _orderId ?? ready.first.id,
              decoration: InputDecoration(
                labelText: s.completedJobs,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final order in ready)
                  DropdownMenuItem(
                    value: order.id,
                    child: Text('${order.plate} · ${order.brand} ${order.model}'),
                  ),
              ],
              onChanged: (value) => setState(() => _orderId = value),
            ),
            const SizedBox(height: 16),
            FactorRating(
              label: s.rateQuality,
              value: _quality,
              onChanged: (value) => setState(() => _quality = value),
            ),
            FactorRating(
              label: s.ratePoliteness,
              value: _politeness,
              onChanged: (value) => setState(() => _politeness = value),
            ),
            FactorRating(
              label: s.ratePunctuality,
              value: _punctuality,
              onChanged: (value) => setState(() => _punctuality = value),
            ),
            FactorRating(
              label: s.rateCleanliness,
              value: _cleanliness,
              onChanged: (value) => setState(() => _cleanliness = value),
            ),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.comment,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _submit(s, ready),
              child: Text(s.sendRating),
            ),
          ],
          const SizedBox(height: 32),
          Text(s.qualityControl, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${s.avgRating}: ${avg.toStringAsFixed(1)} / 5'),
          const SizedBox(height: 12),
          if (ratings.isEmpty)
            Text(s.noRatings)
          else
            for (final rating in ratings) _ratingTile(s, lang, orders, rating),
        ],
        ),
      ),
    );
  }

  Widget _ratingTile(
    AppStrings s,
    AppLang lang,
    List<WorkOrder> orders,
    Rating rating,
  ) {
    final order = _byId(orders, rating.orderId);
    final master = _masterById(rating.masterId);
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(child: Text('${rating.stars}')),
        title: Text(order == null ? rating.orderId : '${order.plate} · ${order.brand}'),
        subtitle: Text(
          '${master?.name.of(lang) ?? ''} · ${rating.comment}',
        ),
      ),
    );
  }

  WorkOrder? _byId(List<WorkOrder> orders, String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  Master? _masterById(String id) {
    for (final master in workshopMasters) {
      if (master.id == id) return master;
    }
    return null;
  }

  void _submit(AppStrings s, List<WorkOrder> ready) {
    final id = _orderId ?? ready.first.id;
    final order = ready.firstWhere((item) => item.id == id);
    ref.read(ratingsProvider.notifier).add(
            Rating(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            orderId: order.id,
            masterId: order.masterId ?? 'unassigned',
            quality: _quality,
            politeness: _politeness,
            punctuality: _punctuality,
            cleanliness: _cleanliness,
            comment: _comment.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
    _comment.clear();
    setState(() {
      _orderId = null;
      _quality = 5;
      _politeness = 5;
      _punctuality = 5;
      _cleanliness = 5;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.thankYou)));
  }
}
