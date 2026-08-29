import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../domain/models/platform_features.dart';
import '../widgets/ui.dart';

class ClientBusinessScreen extends ConsumerStatefulWidget {
  const ClientBusinessScreen({super.key});

  @override
  ConsumerState<ClientBusinessScreen> createState() =>
      _ClientBusinessScreenState();
}

class _ClientBusinessScreenState extends ConsumerState<ClientBusinessScreen> {
  Future<void> _addCar() async {
    final plate = TextEditingController();
    final brand = TextEditingController();
    final model = TextEditingController();
    final vin = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand')),
            TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
            TextField(controller: plate, decoration: const InputDecoration(labelText: 'Plate')),
            TextField(controller: vin, decoration: const InputDecoration(labelText: 'VIN')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || brand.text.trim().isEmpty) {
      return;
    }
    ref.read(garageCarsProvider.notifier).add(
          GarageCar(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            plate: plate.text.trim(),
            brand: brand.text.trim(),
            model: model.text.trim(),
            vin: vin.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final cars = ref.watch(garageCarsProvider);
    final invoices = ref.watch(businessInvoicesProvider);
    final business = cars.length > 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.businessAccountTitle),
        actions: [
          IconButton(onPressed: _addCar, icon: const Icon(CupertinoIcons.add)),
        ],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context, extra: 20),
          children: [
            Text(s.businessAccountLead, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 12),
            Text(
              '${cars.length} cars',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (!business) ...[
              const SizedBox(height: 8),
              Text(s.businessNeedCars, style: TextStyle(color: palette.muted)),
            ],
            const SizedBox(height: 12),
            for (final car in cars)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${car.brand} ${car.model}'),
                subtitle: Text('${car.plate} ${car.vin}'.trim()),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () =>
                      ref.read(garageCarsProvider.notifier).remove(car.id),
                ),
              ),
            const SizedBox(height: 16),
            if (business)
              FilledButton(
                onPressed: () {
                  final total = cars.length * 1500;
                  ref.read(businessInvoicesProvider.notifier).createBundle(cars, total);
                },
                child: const Text('One invoice for all cars'),
              ),
            const SizedBox(height: 20),
            for (final inv in invoices)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.stroke),
                  color: palette.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice · ${formatUah(inv.totalUah)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(DateFormat('dd.MM.yyyy HH:mm').format(inv.createdAt)),
                    for (final line in inv.lineLabels) Text('· $line'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
