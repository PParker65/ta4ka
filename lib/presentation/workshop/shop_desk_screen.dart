import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/auto_spheres.dart';
import '../../data/catalog_seed.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/desk_master.dart';
import '../client/booking_format.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class ShopDeskScreen extends ConsumerStatefulWidget {
  const ShopDeskScreen({super.key});

  @override
  ConsumerState<ShopDeskScreen> createState() => _ShopDeskScreenState();
}

class _ShopDeskScreenState extends ConsumerState<ShopDeskScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _about;
  late final TextEditingController _staff;
  late final TextEditingController _workPrompt;
  late final TextEditingController _customService;
  late final TextEditingController _requisites;
  late String _positioning;
  late String _priceGrade;
  late double _dailyLoad;
  late bool _partsDelivery;
  late Set<String> _offeredWorkIds;
  late List<String> _customServices;

  late List<DeskMaster> _deskMasters;

  @override
  void initState() {
    super.initState();
    final account = ref.read(shopAccountProvider);
    _name = TextEditingController(text: account.shopName);
    _city = TextEditingController(text: account.city);
    _address = TextEditingController(text: account.address);
    _phone = TextEditingController(text: account.phone);
    _about = TextEditingController(text: account.about);
    _staff = TextEditingController(text: account.staffCount.toString());
    _workPrompt = TextEditingController();
    _customService = TextEditingController();
    _requisites = TextEditingController(
      text: account.paymentRequisites.isEmpty
          ? 'PL61 ACCT-000032 1981 2874 · Ta4ka Sp. z o.o.'
          : account.paymentRequisites,
    );
    _positioning = account.positioning;
    _priceGrade = account.priceGrade;
    _dailyLoad = account.dailyLoadPercent.toDouble();
    _partsDelivery = account.partsDelivery;
    _offeredWorkIds = account.offeredWorkIds.isEmpty
        ? {
            for (final sphere in spheresFromIds(account.sphereIds))
              ...sphere.workIds,
          }
        : account.offeredWorkIds.toSet();
    _customServices = [...account.customServices];
    _deskMasters = account.deskMasters.isEmpty
        ? resizeDeskMasters(const [], account.staffCount)
        : [...account.deskMasters];
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    _about.dispose();
    _staff.dispose();
    _workPrompt.dispose();
    _customService.dispose();
    _requisites.dispose();
    super.dispose();
  }

  void _save() {
    final s = ref.read(stringsProvider);
    ref.read(shopAccountProvider.notifier).patch(
          shopName: _name.text.trim(),
          city: _city.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          about: _about.text.trim(),
          positioning: _positioning,
          priceGrade: _priceGrade,
          dailyLoadPercent: _dailyLoad.round(),
          partsDelivery: _partsDelivery,
          offeredWorkIds: _offeredWorkIds.toList(),
          customServices: _customServices,
          deskMasters: _deskMasters,
          staffCount: int.tryParse(_staff.text.trim()) ?? _deskMasters.length,
        );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.shopSaved)));
  }

  String _fold(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll('ґ', 'г')
        .replaceAll("'", '')
        .replaceAll('ʼ', '')
        .replaceAll('’', '');
  }

  List<ServiceWork> _smartSuggestedWorks({
    required String query,
    required List<String> sphereIds,
  }) {
    final q = _fold(query.trim());
    final sphereWorkIds = <String>{
      for (final sphere in spheresFromIds(sphereIds)) ...sphere.workIds,
    };
    final inScope = [
      for (final work in catalogWorks)
        if (sphereWorkIds.isEmpty || sphereWorkIds.contains(work.id)) work,
    ];
    if (q.isEmpty) {
      return inScope.take(16).toList();
    }
    final tokens = q.split(RegExp(r'\s+')).where((e) => e.length > 2).toList();
    final ranked = <({ServiceWork work, int score})>[];
    for (final work in inScope) {
      final title = _fold('${work.title.uk} ${work.title.ru} ${work.title.en}');
      var score = 0;
      if (title.contains(q)) {
        score += 8;
      }
      for (final t in tokens) {
        if (title.contains(t)) {
          score += 4;
        }
      }
      if (score > 0) {
        ranked.add((work: work, score: score));
      }
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return [for (final item in ranked.take(16)) item.work];
  }

  void _toggleWork(String workId, bool on) {
    setState(() {
      if (on) {
        _offeredWorkIds.add(workId);
      } else {
        _offeredWorkIds.remove(workId);
      }
    });
  }

  void _addCustomService() {
    final value = _customService.text.trim();
    if (value.isEmpty) {
      return;
    }
    if (_customServices.contains(value)) {
      return;
    }
    setState(() {
      _customServices.add(value);
      _customService.clear();
    });
  }

  String _loadLabel(int value) {
    if (value < 35) {
      return 'Низкая';
    }
    if (value < 70) {
      return 'Средняя';
    }
    return 'Высокая';
  }

  String _positioningLabel(String value) {
    switch (value) {
      case 'garage':
        return 'Гараж';
      case 'dealer':
        return 'Дилер';
      default:
        return 'Сервис';
    }
  }

  String _intakeEtaLabel(int load) {
    if (load < 25) {
      return 'Приемка: ~10–15 мин';
    }
    if (load < 50) {
      return 'Приемка: ~15–25 мин';
    }
    if (load < 75) {
      return 'Приемка: ~25–40 мин';
    }
    return 'Приемка: ~40–60+ мин';
  }

  String _intakeLoadHint(int load) {
    if (load >= 75) {
      return 'Высокая загрузка: предупреждаем клиента о возможной дополнительной задержке.';
    }
    if (load >= 50) {
      return 'Средняя загрузка: возможна небольшая задержка в часы пик.';
    }
    return 'Низкая загрузка: прием обычно без дополнительного ожидания.';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final session = ref.watch(authProvider);
    final suggested = _smartSuggestedWorks(
      query: _workPrompt.text.isEmpty ? _about.text : _workPrompt.text,
      sphereIds: account.sphereIds,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shopTabDesk),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.shopCommissionTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.3,
                      color: account.isBlocked
                          ? const Color(0xFFE74C3C)
                          : palette.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.shopCommissionHint,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.shopCommissionDebt(formatUah(account.commissionDebtUah)),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _requisites,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: s.shopCommissionRequisites,
                      hintText: 'IBAN / account · Ta4ka',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: account.commissionDebtUah <= 0
                          ? null
                          : () {
                              ref.read(shopAccountProvider.notifier).patch(
                                    paymentRequisites: _requisites.text.trim(),
                                  );
                              ref
                                  .read(shopAccountProvider.notifier)
                                  .markCommissionPaid();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.shopSaved)),
                              );
                            },
                      child: Text(s.shopCommissionPay),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.mapaShopTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.mapaShopLead,
                    style: TextStyle(color: palette.muted, fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.mapaShopUseMap,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: account.mapaHelpOptIn && !account.mapaHelpPaused,
                    title: Text(s.mapaShopAgree),
                    subtitle: account.mapaHelpPaused
                        ? Text(
                            s.mapaReportDone,
                            style: TextStyle(color: palette.danger, fontSize: 12),
                          )
                        : null,
                    onChanged: (on) {
                      ref.read(shopAccountProvider.notifier).save(
                            account.copyWith(
                              mapaHelpOptIn: on,
                              mapaHelpPaused: false,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.ownerDashTitle,
              style: TextStyle(fontWeight: FontWeight.w800, color: palette.text),
            ),
            const SizedBox(height: 6),
            Text(
              '${s.shopCommissionTitle}: ${formatUah(account.commissionDebtUah)} · '
              '${ref.watch(ordersProvider).where((o) => o.status == JobStatus.ready).length} closed',
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: account.isOpenNow
                    ? const Color(0xFF27AE60).withValues(alpha: 0.12)
                    : palette.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: account.isOpenNow
                      ? const Color(0xFF27AE60).withValues(alpha: 0.55)
                      : palette.stroke,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.hours.of(lang),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: account.isOpenNow
                                ? const Color(0xFF1E8449)
                                : palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.isOpenNow ? s.shopHoursOpenNow : s.shopHoursClosedNow,
                          style: TextStyle(
                            color: account.isOpenNow
                                ? const Color(0xFF1E8449)
                                : palette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _editHours(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: Text(s.shopChangeTime),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              session?.displayName ?? account.shopName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: s.shopName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: InputDecoration(labelText: s.shopCity),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: InputDecoration(labelText: s.shopAddress),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: s.shopPhone),
            ),
            const SizedBox(height: 18),
            Text(
              'Опрос автосервиса',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: palette.text),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _staff,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Количество персонала'),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final n = int.tryParse(_staff.text.trim()) ?? 0;
                    setState(() {
                      _deskMasters = resizeDeskMasters(_deskMasters, n);
                      _staff.text = '${_deskMasters.length}';
                    });
                  },
                  child: Text(s.shopStaffApply),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _deskMasters.length; i++) ...[
              _MasterEditorCard(
                index: i,
                master: _deskMasters[i],
                strings: s,
                shopLogin: account.login,
                onChanged: (next) {
                  setState(() => _deskMasters[i] = next);
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            Text(
              s.shopPositioningTitle,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: palette.text),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'garage', label: Text('Гараж')),
                ButtonSegment(value: 'service', label: Text('Сервис')),
                ButtonSegment(value: 'dealer', label: Text('Дилер')),
              ],
              selected: {_positioning},
              onSelectionChanged: (value) {
                setState(() => _positioning = value.first);
              },
            ),
            const SizedBox(height: 16),
            Text(
              s.shopPricePositionTitle,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: palette.text),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'economy', label: Text('Эконом')),
                ButtonSegment(value: 'standard', label: Text('Стандарт')),
                ButtonSegment(value: 'premium', label: Text('Премиум')),
              ],
              selected: {_priceGrade},
              onSelectionChanged: (value) {
                setState(() => _priceGrade = value.first);
              },
            ),
            const SizedBox(height: 16),
            Text(
              '${s.shopLoadTodayTitle}: ${_dailyLoad.round()}% · ${_loadLabel(_dailyLoad.round())}',
              style: TextStyle(fontWeight: FontWeight.w600, color: palette.text),
            ),
            Slider(
              value: _dailyLoad,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => _dailyLoad = v),
            ),
            const SizedBox(height: 4),
            Text(
              _intakeEtaLabel(_dailyLoad.round()),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _intakeLoadHint(_dailyLoad.round()),
              style: TextStyle(
                color: _dailyLoad.round() >= 75 ? palette.danger : palette.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(s.shopPartsDelivery),
              subtitle: Text(
                s.shopPartsDeliveryHint,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              value: _partsDelivery,
              onChanged: (v) => setState(() => _partsDelivery = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.paintbrush_fill),
              title: Text(s.shopDesignTitle),
              subtitle: Text(s.shopLogoPick),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/design'),
            ),
            const SizedBox(height: 16),
            Text(
              s.shopToolsHub,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.hammer_fill),
              title: Text(s.opsHubTitle),
              subtitle: Text(s.opsHubLeadShop),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/ops/parts'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.search),
              title: Text(s.opsPartsTitle),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/ops/parts'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.cube_box_fill),
              title: Text(s.opsStockTitle),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/ops/stock'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.doc_text),
              title: Text(s.taxReportTitle),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/tax-report'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.search),
              title: Text(s.vinHistoryTitle),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/vin-history'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.hand_raised),
              title: Text(s.blacklistTitle),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/blacklist'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.cube_box),
              title: Text(s.shopPartsApprove),
              trailing: const Icon(CupertinoIcons.chevron_right),
              onTap: () => context.push('/staff/parts-requests'),
            ),
            const SizedBox(height: 16),
            Text(
              s.shopDeskReadyTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: palette.text,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.shopDeskReadyLead,
              style: TextStyle(color: palette.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text('${s.shopSaveDesk} · ${s.shopPublish}')),
            const SizedBox(height: 6),
            Text(
              '${s.shopClientSees}: ${_positioningLabel(_positioning)} · ${_dailyLoad.round()}% · '
              '${_partsDelivery ? s.shopPartsYes : s.shopPartsNo}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Text(
              s.shopWorksAiTitle,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: palette.text),
            ),
            const SizedBox(height: 4),
            Text(
              s.shopWorksAiHint,
              style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _workPrompt,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.shopWorksAiPrompt,
                hintText: s.shopWorksAiPromptHint,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              s.shopWorksAiTips,
              style: TextStyle(fontWeight: FontWeight.w600, color: palette.text),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final work in suggested)
                  FilterChip(
                    label: Text(work.title.of(lang)),
                    selected: _offeredWorkIds.contains(work.id),
                    onSelected: (on) => _toggleWork(work.id, on),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${s.shopWorksSelected}: ${_offeredWorkIds.length}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              s.shopCustomServices,
              style: TextStyle(fontWeight: FontWeight.w600, color: palette.text),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customService,
                    onSubmitted: (_) => _addCustomService(),
                    decoration: InputDecoration(
                      labelText: s.shopAddService,
                      hintText: s.shopAddServiceHint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addCustomService,
                  child: Text(s.shopAdd),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_customServices.isEmpty)
              Text(
                s.shopCustomServicesEmpty,
                style: TextStyle(color: palette.muted, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _customServices)
                    InputChip(
                      label: Text(item),
                      onDeleted: () {
                        setState(() => _customServices.remove(item));
                      },
                    ),
                ],
              ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(CupertinoIcons.square_arrow_left, color: palette.danger),
              title: Text(s.logout),
              onTap: () {
                ref.read(authProvider.notifier).signOut();
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editHours(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final account = ref.read(shopAccountProvider);
    final controller = TextEditingController(
      text: account.hoursText.isEmpty
          ? account.hours.of(ref.read(localeProvider))
          : account.hoursText,
    );
    var open = account.openHour;
    var close = account.closeHour;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = paletteOf(ctx);
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: GlassPanel(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.shopHoursEdit,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: s.shopHoursLabel),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: open,
                            decoration: InputDecoration(labelText: s.shopHoursOpen),
                            items: [
                              for (var h = 6; h <= 12; h++)
                                DropdownMenuItem(value: h, child: Text('$h:00')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModal(() => open = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: close,
                            decoration: InputDecoration(labelText: s.shopHoursClose),
                            items: [
                              for (var h = 14; h <= 22; h++)
                                DropdownMenuItem(value: h, child: Text('$h:00')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModal(() => close = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.shopSaveDesk),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (ok == true) {
      ref.read(shopAccountProvider.notifier).patch(
            hoursText: controller.text.trim(),
            openHour: open,
            closeHour: close,
          );
    }
    controller.dispose();
  }
}

class _MasterEditorCard extends StatelessWidget {
  const _MasterEditorCard({
    required this.index,
    required this.master,
    required this.strings,
    required this.shopLogin,
    required this.onChanged,
  });

  final int index;
  final DeskMaster master;
  final AppStrings strings;
  final String shopLogin;
  final ValueChanged<DeskMaster> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${strings.masters} ${index + 1}',
            style: TextStyle(fontWeight: FontWeight.w800, color: palette.text),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: master.name,
            decoration: InputDecoration(labelText: strings.shopMasterName),
            onChanged: (v) => onChanged(master.copyWith(name: v)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<MasterSpecialty>(
            initialValue: master.specialty,
            decoration: InputDecoration(labelText: strings.status),
            items: [
              for (final spec in MasterSpecialty.values)
                DropdownMenuItem(
                  value: spec,
                  child: Text(specialtyLabel(strings, spec)),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(master.copyWith(specialty: v));
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: '${master.yearsExperience}',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.shopMasterYears),
            onChanged: (v) {
              onChanged(
                master.copyWith(yearsExperience: int.tryParse(v.trim()) ?? 0),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(strings.shopMasterPace, style: TextStyle(color: palette.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pace in MasterPace.values)
                ChoiceChip(
                  selected: master.pace == pace,
                  label: Text(switch (pace) {
                    MasterPace.intern => strings.shopMasterPaceIntern,
                    MasterPace.normal => strings.shopMasterPaceNormal,
                    MasterPace.fast => strings.shopMasterPaceFast,
                    MasterPace.careful => strings.shopMasterPaceCareful,
                  }),
                  onSelected: (_) => onChanged(master.copyWith(pace: pace)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: master.note,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: strings.extraWorks,
              hintText: 'BMW coding, pads, diagnostics…',
            ),
            onChanged: (v) => onChanged(master.copyWith(note: v)),
          ),
          const SizedBox(height: 12),
          Text(
            strings.shopRoleMaster,
            style: TextStyle(fontWeight: FontWeight.w700, color: palette.text),
          ),
          const SizedBox(height: 4),
          Text(
            strings.shopRoleMasterHint,
            style: TextStyle(color: palette.muted, fontSize: 12, height: 1.3),
          ),
          if (master.hasCredentials) ...[
            const SizedBox(height: 8),
            SelectableText(
              '${strings.login}: ${master.login}\n${strings.password}: ${master.password}',
              style: TextStyle(
                fontFamily: 'monospace',
                color: palette.text,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              onChanged(
                master.copyWith(
                  login: issueMasterLogin(
                    shopLogin.isEmpty ? 'sto' : shopLogin,
                    master.id,
                  ),
                  password: issueMasterPassword(),
                ),
              );
            },
            icon: const Icon(CupertinoIcons.lock_rotation, size: 18),
            label: Text(strings.masterIssueLogin),
          ),
        ],
      ),
    );
  }
}
