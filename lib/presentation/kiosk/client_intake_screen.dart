import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/catalog_seed.dart';
import '../../data/dto/job_dto.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/work_map.dart';
import '../widgets/oleg_card.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class ClientIntakeScreen extends ConsumerStatefulWidget {
  const ClientIntakeScreen({super.key});

  @override
  ConsumerState<ClientIntakeScreen> createState() => _ClientIntakeScreenState();
}

class _ClientIntakeScreenState extends ConsumerState<ClientIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plate;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;

  static const _symptoms = <String, RepairCategory>{
    'noise': RepairCategory.chassis,
    'brakes': RepairCategory.chassis,
    'electrics': RepairCategory.electrical,
    'engine': RepairCategory.engine,
    'to': RepairCategory.maintenance,
    'headlight_pair': RepairCategory.electrical,
    'ecu_flash': RepairCategory.electrical,
    'roadside': RepairCategory.diagnostics,
    'unknown': RepairCategory.diagnostics,
  };

  static const _wantIds = ['diag', 'repair', 'to', 'coding'];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(kioskProvider);
    _plate = TextEditingController(text: draft.plate);
    _brand = TextEditingController(text: draft.brand);
    _model = TextEditingController(text: draft.model);
    _year = TextEditingController(text: draft.year);
  }

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    super.dispose();
  }

  String _symptomLabel(AppStrings s, String id) {
    return switch (id) {
      'noise' => s.symptomNoise,
      'brakes' => s.symptomBrakes,
      'electrics' => s.symptomElectrics,
      'engine' => s.symptomEngine,
      'to' => s.symptomTo,
      'headlight_pair' => s.symptomHeadlight,
      'ecu_flash' => s.symptomEcu,
      'roadside' => s.symptomRoadside,
      _ => s.symptomUnknown,
    };
  }

  String _wantLabel(AppStrings s, String id) {
    return switch (id) {
      'diag' => s.wantDiag,
      'repair' => s.wantRepair,
      'to' => s.wantTo,
      _ => s.wantCoding,
    };
  }

  void _syncCar() {
    ref.read(kioskProvider.notifier).setIdentity(
          plate: _plate.text.trim().toUpperCase(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          year: _year.text.trim(),
          mileage: '0',
          vin: '',
        );
  }

  void _applyWant(String wantId) {
    final draft = ref.read(kioskProvider);
    final workId = workIdFor(want: wantId, symptom: draft.symptom);
    final work = catalogWorks.where((item) => item.id == workId);
    if (work.isEmpty) {
      return;
    }
    final tier = draft.selected.values.isEmpty
        ? PriceTier.standard
        : draft.selected.values.first.tier;
    ref.read(kioskProvider.notifier).setWant(wantId);
    ref.read(kioskProvider.notifier).selectOnlyWork(work.first, tier);
  }

  Future<void> _submit(AppStrings s) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final draft = ref.read(kioskProvider);
    if (draft.symptom == null || draft.want == null || draft.selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pickOptions)),
      );
      return;
    }
    _syncCar();
    final latest = ref.read(kioskProvider);
    final order = WorkOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plate: latest.plate,
      brand: latest.brand,
      model: latest.model,
      year: int.tryParse(latest.year) ?? 0,
      mileage: 0,
      vin: '',
      category: latest.category ?? RepairCategory.diagnostics,
      status: JobStatus.created,
      createdAt: DateTime.now(),
      lines: [
        for (final item in latest.selected.values)
          OrderLine(
            workId: item.work.id,
            title: item.work.title,
            tier: item.tier,
            priceUah: item.priceUah,
            minutes: item.work.minutes,
          ),
      ],
    );
    ref.read(ordersProvider.notifier).save(order);
    try {
      await ref.read(jobsApiProvider).create(
            JobCreateRequest(
              shopId: 'local-shop',
              plate: order.plate,
              brand: order.brand,
              model: order.model,
              year: order.year,
              symptomId: latest.symptom ?? 'unknown',
              wantId: latest.want ?? 'diag',
              tier: latest.selected.values.first.tier.name,
            ),
          );
    } catch (_) {}
    ref.read(kioskProvider.notifier).reset();
    if (mounted) {
      context.go('/client-kiosk/rate/${order.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final draft = ref.watch(kioskProvider);
    final selected = draft.selected.values.isEmpty ? null : draft.selected.values.first;
    final palette = paletteOf(context);
    final tips = [
      s.olegIntro,
      if (selected != null) selected.work.olegTip.of(lang),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.clientKiosk),
        leading: IconButton(
          onPressed: () {
            ref.read(authProvider.notifier).signOut();
            context.go('/');
          },
          icon: const Icon(Icons.logout),
          tooltip: s.logout,
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/home/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: s.profile,
          ),
          const AppBarTools(),
        ],
      ),
      body: ScreenCanvas(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Text(
                  s.whatsWrong,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _symptoms.entries)
                      ChoiceChip(
                        selected: draft.symptom == entry.key,
                        label: Text(_symptomLabel(s, entry.key)),
                        onSelected: (_) {
                          ref
                              .read(kioskProvider.notifier)
                              .setSymptom(entry.key, entry.value);
                          final want = ref.read(kioskProvider).want;
                          if (want != null) {
                            _applyWant(want);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  s.whatWant,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in _wantIds)
                      ChoiceChip(
                        selected: draft.want == id,
                        label: Text(_wantLabel(s, id)),
                        onSelected: (_) => _applyWant(id),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  s.carShort,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _plate,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(labelText: s.plate),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? s.requiredField
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _brand,
                            decoration: InputDecoration(labelText: s.brand),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? s.requiredField
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _model,
                            decoration: InputDecoration(labelText: s.model),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? s.requiredField
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _year,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: InputDecoration(
                              labelText: s.year,
                              hintText: '2018',
                            ),
                            validator: (value) =>
                                value == null || value.trim().length != 4
                                    ? s.requiredField
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 20),
                  OlegCard(title: s.olegTitle, tips: tips),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.work.title.of(lang),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final tier in PriceTier.values)
                                ChoiceChip(
                                  selected: selected.tier == tier,
                                  label: Text(
                                    '${_tierLabel(s, tier)} · ${formatUah(selected.work.priceFor(tier))}',
                                  ),
                                  onSelected: (_) => ref
                                      .read(kioskProvider.notifier)
                                      .selectWork(selected.work, tier),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${s.total}: ${formatUah(selected.priceUah)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: palette.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _submit(s),
                  child: Text(s.submitOrder),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tierLabel(AppStrings s, PriceTier tier) {
    return switch (tier) {
      PriceTier.basic => s.tierBasic,
      PriceTier.standard => s.tierStandard,
      PriceTier.premium => s.tierPremium,
    };
  }
}
