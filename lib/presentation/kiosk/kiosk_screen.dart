import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/catalog_seed.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/language_switcher.dart';
import '../widgets/oleg_card.dart';
import '../widgets/ui.dart';
import '../../app/theme.dart';

class KioskScreen extends ConsumerStatefulWidget {
  const KioskScreen({super.key, this.clientMode = false});

  final bool clientMode;

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plate;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _mileage;
  late final TextEditingController _vin;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(kioskProvider);
    _plate = TextEditingController(text: draft.plate);
    _brand = TextEditingController(text: draft.brand);
    _model = TextEditingController(text: draft.model);
    _mileage = TextEditingController(text: draft.mileage);
    _vin = TextEditingController(text: draft.vin);
  }

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _mileage.dispose();
    _vin.dispose();
    super.dispose();
  }

  void _syncIdentity() {
    ref.read(kioskProvider.notifier).setIdentity(
          plate: _plate.text.trim().toUpperCase(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          mileage: _mileage.text.trim(),
          vin: _vin.text.trim().toUpperCase(),
        );
  }

  bool _goNext(AppStrings s) {
    final draft = ref.read(kioskProvider);
    if (draft.step == 0) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return false;
      }
      _syncIdentity();
    }
    if (draft.step == 1 && draft.category == null) {
      return false;
    }
    if (draft.step == 2 && draft.selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.noWorks)));
      return false;
    }
    if (draft.step < 3) {
      ref.read(kioskProvider.notifier).setStep(draft.step + 1);
      return true;
    }
    return true;
  }

  Future<void> _submit(AppStrings s) async {
    final draft = ref.read(kioskProvider);
    if (draft.selected.isEmpty || draft.category == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.noWorks)));
      return;
    }
    _syncIdentity();
    final latest = ref.read(kioskProvider);
    final order = WorkOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plate: latest.plate,
      brand: latest.brand,
      model: latest.model,
      year: int.tryParse(latest.year) ?? 0,
      mileage: int.tryParse(latest.mileage) ?? 0,
      vin: latest.vin,
      category: latest.category!,
      status: JobStatus.created,
      createdAt: DateTime.now(),
      inspection: latest.inspection,
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
    if (!mounted) {
      return;
    }
    if (widget.clientMode) {
      ref.read(kioskProvider.notifier).reset();
      context.go('/client-kiosk/rate/${order.id}');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.orderCreated),
        content: Text('${order.plate} · ${formatUah(order.totalUah)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    ref.read(kioskProvider.notifier).reset();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final draft = ref.watch(kioskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientMode ? s.clientKiosk : s.kiosk),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSwitcher(),
          ),
        ],
      ),
      body: ScreenCanvas(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.formatStep(draft.step + 1, 4),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kGarageGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StepPills(current: draft.step, total: 4),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    [
                      s.step1Title,
                      s.step2Title,
                      s.step3Title,
                      s.step4Title,
                    ][draft.step],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kGarageGreen,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (draft.step == 0) _identityForm(s),
                  if (draft.step == 1) _categories(s, draft),
                  if (draft.step == 2) _works(s, lang, draft),
                  if (draft.step == 3) _summary(s, lang, draft),
                ],
              ),
            ),
            Material(
              color: kIvory,
              elevation: 12,
              shadowColor: const Color(0x2216382C),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    children: [
                      if (draft.step > 0)
                        OutlinedButton(
                          onPressed: () {
                            _syncIdentity();
                            ref.read(kioskProvider.notifier).setStep(draft.step - 1);
                          },
                          child: Text(s.back),
                        ),
                      const Spacer(),
                      if (draft.step < 3)
                        FilledButton(
                          onPressed: () => _goNext(s),
                          child: Text(s.next),
                        )
                      else
                        FilledButton(
                          onPressed: () => _submit(s),
                          child: Text(s.submitOrder),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityForm(AppStrings s) {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
        children: [
          TextFormField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: s.plate,
              hintText: 'KA1234AB',
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? s.requiredField : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brand,
            decoration: InputDecoration(
              labelText: s.brand,
              hintText: 'Volkswagen',
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? s.requiredField : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _model,
            decoration: InputDecoration(
              labelText: s.model,
              hintText: 'Tiguan',
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? s.requiredField : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mileage,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.mileage,
              suffixText: s.km,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? s.requiredField : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vin,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: s.vin,
              hintText: 'WVGZZZ5NZHW123456',
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().length < 11 ? s.requiredField : null,
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _categories(AppStrings s, KioskDraft draft) {
    final items = <RepairCategory, String>{
      RepairCategory.diagnostics: s.catDiag,
      RepairCategory.chassis: s.catChassis,
      RepairCategory.electrical: s.catElectrical,
      RepairCategory.maintenance: s.catMaintenance,
      RepairCategory.engine: s.catEngine,
    };
    return Column(
      children: [
        for (final entry in items.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: draft.category == entry.key ? kGarageGreen : kIvory,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => ref.read(kioskProvider.notifier).setCategory(entry.key),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: draft.category == entry.key
                            ? kAmber.withValues(alpha: 0.2)
                            : const Color(0x1A16382C),
                        child: Icon(
                          _categoryIcon(entry.key),
                          color: draft.category == entry.key ? kAmber : kGarageGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: draft.category == entry.key
                                ? Colors.white
                                : kGarageGreen,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: draft.category == entry.key
                            ? Colors.white70
                            : kGarageGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _works(AppStrings s, AppLang lang, KioskDraft draft) {
    final works = catalogWorks
        .where((work) => work.category == draft.category)
        .toList();
    final tips = [
      s.olegIntro,
      for (final item in draft.selected.values) item.work.olegTip.of(lang),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.step3Hint),
        const SizedBox(height: 12),
        OlegCard(title: s.olegTitle, tips: tips),
        const SizedBox(height: 16),
        for (final work in works)
          _workCard(s, lang, draft, work),
      ],
    );
  }

  Widget _workCard(AppStrings s, AppLang lang, KioskDraft draft, ServiceWork work) {
    final selected = draft.selected[work.id];
    final theme = Theme.of(context);
    return Card(
      color: selected == null ? kIvory : const Color(0xFFE8F3EC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    work.title.of(lang),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected != null)
                  IconButton(
                    onPressed: () =>
                        ref.read(kioskProvider.notifier).removeWork(work.id),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            Text('${work.minutes} ${s.minutesShort}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tier in PriceTier.values)
                  _tierChip(s, work, tier, selected),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierChip(
    AppStrings s,
    ServiceWork work,
    PriceTier tier,
    SelectedWork? selected,
  ) {
    final remembered = ref.read(kioskProvider.notifier).remembered(work.id, tier);
    final price = remembered ?? work.priceFor(tier);
    final label = switch (tier) {
      PriceTier.basic => s.tierBasic,
      PriceTier.standard => s.tierStandard,
      PriceTier.premium => s.tierPremium,
    };
    final isOn = selected?.tier == tier;
    return ChoiceChip(
      selected: isOn,
      label: Text('$label · ${formatUah(price)}'),
      onSelected: (_) => ref.read(kioskProvider.notifier).selectWork(work, tier),
    );
  }

  Widget _summary(AppStrings s, AppLang lang, KioskDraft draft) {
    final total = draft.selected.values.fold<int>(
      0,
      (sum, item) => sum + item.priceUah,
    );
    final minutes = draft.selected.values.fold<int>(
      0,
      (sum, item) => sum + item.work.minutes,
    );
    final tips = [
      for (final item in draft.selected.values) item.work.olegTip.of(lang),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${draft.brand} ${draft.model} ${draft.year} · ${draft.plate}'),
        const SizedBox(height: 12),
        for (final item in draft.selected.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.work.title.of(lang)),
            subtitle: Text(item.tier.name),
            trailing: Text(formatUah(item.priceUah)),
          ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.total, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: Text(
            formatUah(total),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        Text('${s.eta}: $minutes ${s.minutesShort}'),
        const SizedBox(height: 12),
        OlegCard(title: s.olegTitle, tips: tips),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/kiosk/inspection'),
          icon: const Icon(Icons.car_crash_outlined),
          label: Text(s.inspectBody),
        ),
      ],
    );
  }

  IconData _categoryIcon(RepairCategory category) {
    return switch (category) {
      RepairCategory.diagnostics => Icons.search,
      RepairCategory.chassis => Icons.tire_repair,
      RepairCategory.electrical => Icons.bolt,
      RepairCategory.maintenance => Icons.oil_barrel,
      RepairCategory.engine => Icons.settings,
    };
  }
}
