import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/storage_providers.dart';
import '../../app/theme.dart';
import '../../data/storage_contract.dart';
import '../../domain/models/wheel_storage.dart';
import '../widgets/language_switcher.dart';
import '../widgets/theme_switcher.dart';
import 'storage_contract.dart';
import 'storage_l10n.dart';
import 'storage_login.dart';
import 'storage_profile.dart';
import 'storage_rack.dart';
import 'storage_receipt.dart';
import 'storage_signature.dart';

class StorageDeskScreen extends ConsumerStatefulWidget {
  const StorageDeskScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<StorageDeskScreen> createState() => _StorageDeskScreenState();
}

class _StorageDeskScreenState extends ConsumerState<StorageDeskScreen> {
  final _quick = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  final _vin = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _price = TextEditingController();
  var _search = const StorageSearch();
  var _activeOnly = true;
  String? _selectedId;
  var _priceSynced = false;

  @override
  void dispose() {
    _quick.dispose();
    _phone.dispose();
    _plate.dispose();
    _vin.dispose();
    _first.dispose();
    _last.dispose();
    _price.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {
      _search = StorageSearch(
        quick: _quick.text,
        phone: _phone.text,
        plate: _plate.text,
        vin: _vin.text,
        firstName: _first.text,
        lastName: _last.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final lang = ref.watch(localeProvider);
    final l10n = StorageL10n(lang);
    final session = ref.watch(authProvider);
    if (session == null) {
      return StorageLoginPanel(embedded: widget.embedded);
    }
    final shopName = resolveStorageShopName(
      displayName: session.displayName,
      login: session.login,
      shopName: session.shopName,
    );
    final state = ref.watch(wheelStorageProvider);
    if (!_priceSynced && !state.loading) {
      _priceSynced = true;
      _price.text = (state.pricePerDayGrosze / 100).toStringAsFixed(2).replaceAll('.', ',');
    }
    final lots = filterLots(
      state.lots,
      search: _search,
      activeOnly: _activeOnly,
    );
    final selected = lots.cast<WheelLot?>().firstWhere(
          (lot) => lot?.id == _selectedId,
          orElse: () => lots.isEmpty ? null : lots.first,
        );
    final screen = MediaQuery.sizeOf(context);
    final phone = screen.shortestSide < 600;
    final wide = screen.width >= 980;
    final activeLots = state.lots.where((lot) => lot.isActive).toList();

    Widget desk() {
      return LayoutBuilder(
        builder: (context, box) {
          final screenH = MediaQuery.sizeOf(context).height;
          final bodyH = box.maxHeight.isFinite && box.maxHeight > 0
              ? box.maxHeight
              : screenH;
          final bodyW = box.maxWidth.isFinite && box.maxWidth > 0
              ? box.maxWidth
              : screen.width;
          final handset = phone || math.min(bodyW, bodyH) < 600;
          if (handset) {
            return _phoneDesk(
              maxWidth: bodyW,
              maxHeight: bodyH > 0 ? bodyH : (screenH > 0 ? screenH : 720),
              l10n: l10n,
              shopName: shopName,
              state: state,
              lots: lots,
              activeLots: activeLots,
              selected: selected,
            );
          }
          final tall = bodyH > 0 ? bodyH : (screenH > 0 ? screenH : 720);
          final wanted = tall * (wide ? 0.54 : 0.64);
          final lo = tall < 360 ? tall * 0.48 : 280.0;
          final hi = tall * 0.82;
          final rackMax = wanted < lo ? lo : (wanted > hi ? hi : wanted);
          return _deskBody(
            rackMax: rackMax,
            wide: wide,
            l10n: l10n,
            shopName: shopName,
            state: state,
            lots: lots,
            activeLots: activeLots,
            selected: selected,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: palette.bg,
      resizeToAvoidBottomInset: !(phone && screen.width > screen.height),
      appBar: widget.embedded
          ? AppBar(
              title: Text(l10n.title),
              actions: const [LanguageSwitcher(), AppBarTools(showWallet: false, showProfile: false)],
            )
          : null,
      body: state.loading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 22 : (phone ? 4 : 14),
                  wide ? 16 : (phone ? 2 : 8),
                  wide ? 22 : (phone ? 4 : 14),
                  phone ? 4 : 16,
                ),
                child: desk(),
              ),
            ),
    );
  }

  Widget _deskBody({
    required double rackMax,
    required bool wide,
    required StorageL10n l10n,
    required String shopName,
    required WheelStorageState state,
    required List<WheelLot> lots,
    required List<WheelLot> activeLots,
    required WheelLot? selected,
  }) {
    final corner = Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _ProfileCornerButton(
          label: l10n.profile,
          onPressed: () => openStorageProfile(context),
        ),
      ),
    );
    final sectors = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SectorControls(
        l10n: l10n,
        showAdd: state.sectorCount < kMaxSectors,
        showRemove: state.sectorCount > kDefaultSectors,
        onAdd: _addSector,
        onRemove: () => _removeSector(l10n),
      ),
    );
    final rack = StorageRackView(
      lots: activeLots,
      l10n: l10n,
      shopName: shopName,
      sectorCount: clampSectorCount(state.sectorCount),
      selectedId: selected?.id,
      initiallyExpanded: true,
      maxHeight: rackMax,
      showSectorButtons: false,
      onAddSector: _addSector,
      onRemoveSector: () => _removeSector(l10n),
      onTapSlot: (sector, rackRow, slot) => _onRackTap(
        l10n: l10n,
        lots: activeLots,
        sector: sector,
        rackRow: rackRow,
        slot: slot,
      ),
    );
    final actions = _actionBar(
      l10n: l10n,
      state: state,
      activeLots: activeLots,
      selected: selected,
    );
    if (wide) {
      return Column(
        children: [
          corner,
          sectors,
          rack,
          const SizedBox(height: 8),
          actions,
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 312,
                  child: _Rail(
                    l10n: l10n,
                    shopName: shopName,
                    quick: _quick,
                    phone: _phone,
                    plate: _plate,
                    vin: _vin,
                    first: _first,
                    last: _last,
                    price: _price,
                    activeOnly: _activeOnly,
                    activeCount: activeLots.length,
                    onSearch: _applySearch,
                    onTab: (active) => setState(() {
                      _activeOnly = active;
                      _selectedId = null;
                    }),
                    onAccept: () => _openEditor(l10n: l10n, lots: activeLots),
                    onPrice: _commitPrice,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _LotList(
                    l10n: l10n,
                    lots: lots,
                    selectedId: selected?.id,
                    pricePerDayGrosze: state.pricePerDayGrosze,
                    empty: _emptyLabel(l10n, lots),
                    onSelect: (id) => setState(() => _selectedId = id),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: selected == null
                      ? _EmptyDetail(l10n: l10n)
                      : _LotDetail(
                          lot: selected,
                          l10n: l10n,
                          pricePerDayGrosze: state.pricePerDayGrosze,
                          onOpenContract: selected.hasSignature
                              ? () => _openSignedContract(
                                    l10n,
                                    selected,
                                    state.pricePerDayGrosze,
                                  )
                              : null,
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (widget.embedded)
          corner
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: _BrandLockup(l10n: l10n, shopName: shopName)),
                const LanguageSwitcher(),
                const ThemeSwitcher(),
                const SizedBox(width: 8),
                _ProfileCornerButton(
                  label: l10n.profile,
                  onPressed: () => openStorageProfile(context),
                ),
              ],
            ),
          ),
        sectors,
        rack,
        const SizedBox(height: 8),
        actions,
        const SizedBox(height: 10),
        _CompactSearch(
          l10n: l10n,
          quick: _quick,
          price: _price,
          activeOnly: _activeOnly,
          activeCount: activeLots.length,
          onSearch: _applySearch,
          onTab: (active) => setState(() => _activeOnly = active),
          onAccept: () => _openEditor(l10n: l10n, lots: activeLots),
          onPrice: _commitPrice,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _LotList(
            l10n: l10n,
            lots: lots,
            selectedId: selected?.id,
            pricePerDayGrosze: state.pricePerDayGrosze,
            empty: _emptyLabel(l10n, lots),
            onSelect: (id) {
              setState(() => _selectedId = id);
              final lot = lots.firstWhere((item) => item.id == id);
              _openMobileDetail(lot, l10n, activeLots);
            },
          ),
        ),
      ],
    );
  }

  /// Phone only. Tablet and desktop keep [_deskBody].
  /// Landscape fits the whole desk in the viewport. Portrait keeps the rack,
  /// buttons, and search on screen; only the client list scrolls.
  Widget _phoneDesk({
    required double maxWidth,
    required double maxHeight,
    required StorageL10n l10n,
    required String shopName,
    required WheelStorageState state,
    required List<WheelLot> lots,
    required List<WheelLot> activeLots,
    required WheelLot? selected,
  }) {
    final landscape = maxWidth > maxHeight;
    Widget rackIn(double height) {
      return StorageRackView(
        lots: activeLots,
        l10n: l10n,
        shopName: shopName,
        sectorCount: clampSectorCount(state.sectorCount),
        selectedId: selected?.id,
        initiallyExpanded: true,
        maxHeight: height,
        fitWidth: true,
        compactChrome: true,
        showSectorButtons: false,
        onAddSector: _addSector,
        onRemoveSector: () => _removeSector(l10n),
        onTapSlot: (sector, rackRow, slot) => _onRackTap(
          l10n: l10n,
          lots: activeLots,
          sector: sector,
          rackRow: rackRow,
          slot: slot,
        ),
      );
    }

    final actions = _actionBar(
      l10n: l10n,
      state: state,
      activeLots: activeLots,
      selected: selected,
    );
    final tools = _PhoneTools(
      l10n: l10n,
      quick: _quick,
      price: _price,
      activeOnly: _activeOnly,
      dense: true,
      onSearch: _applySearch,
      onTab: (active) => setState(() {
        _activeOnly = active;
        _selectedId = null;
      }),
      onAccept: () => _openEditor(l10n: l10n, lots: activeLots),
      onPrice: _commitPrice,
    );
    final list = _LotList(
      l10n: l10n,
      lots: lots,
      selectedId: selected?.id,
      pricePerDayGrosze: state.pricePerDayGrosze,
      empty: _emptyLabel(l10n, lots),
      compact: true,
      onSelect: (id) {
        setState(() => _selectedId = id);
        if (landscape) return;
        final lot = lots.firstWhere((item) => item.id == id);
        _openMobileDetail(lot, l10n, activeLots);
      },
    );
    final mq = MediaQuery.of(context);
    final scale = landscape ? 0.70 : 0.86;
    final chromeH = landscape ? 30.0 : 34.0;
    final sectorH = landscape ? 26.0 : 30.0;
    final profile = _ProfileCornerButton(
      label: l10n.profile,
      compact: true,
      height: chromeH,
      onPressed: () => openStorageProfile(context),
    );
    final sectors = _SectorControls(
      l10n: l10n,
      showAdd: state.sectorCount < kMaxSectors,
      showRemove: state.sectorCount > kDefaultSectors,
      onAdd: _addSector,
      onRemove: () => _removeSector(l10n),
      compact: true,
      height: sectorH,
    );
    final child = SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: chromeH,
              child: Row(
                children: [
                  Transform.scale(
                    scale: 0.72,
                    alignment: Alignment.centerLeft,
                    child: const LanguageSwitcher(),
                  ),
                  Transform.scale(
                    scale: 0.72,
                    alignment: Alignment.centerLeft,
                    child: const ThemeSwitcher(),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: profile,
                    ),
                  ),
                ],
              ),
            ),
            if (state.sectorCount < kMaxSectors || state.sectorCount > kDefaultSectors) ...[
              SizedBox(height: landscape ? 2 : 3),
              sectors,
            ],
            Expanded(
              flex: landscape ? 6 : 5,
              child: LayoutBuilder(
                builder: (context, box) {
                  final h = box.maxHeight.isFinite && box.maxHeight > 0
                      ? box.maxHeight
                      : 120.0;
                  return rackIn(h);
                },
              ),
            ),
            SizedBox(height: landscape ? 2 : 4),
            actions,
            SizedBox(height: landscape ? 2 : 4),
            Expanded(
              flex: landscape ? 5 : 6,
              child: landscape
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: (maxWidth * 0.34).clamp(128.0, 200.0),
                          child: tools,
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: list),
                      ],
                    )
                  : Column(
                      children: [
                        tools,
                        const SizedBox(height: 4),
                        Expanded(child: list),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
    return MediaQuery(
      data: mq.copyWith(
        size: Size(maxWidth, maxHeight),
        textScaler: TextScaler.linear(
          (mq.textScaler.scale(1) * scale).clamp(0.62, 1.0),
        ),
      ),
      child: child,
    );
  }

  String get _shopName {
    final session = ref.read(authProvider);
    return resolveStorageShopName(
      displayName: session?.displayName ?? '',
      login: session?.login ?? '',
      shopName: session?.shopName ?? '',
    );
  }

  String _emptyLabel(StorageL10n l10n, List<WheelLot> lots) {
    if (lots.isNotEmpty) return '';
    if (!_search.isEmpty) return l10n.emptySearch;
    return _activeOnly ? l10n.emptyActive : l10n.emptyArchive;
  }

  void _commitPrice() {
    ref.read(wheelStorageProvider.notifier).setPricePerDayGrosze(
          parseZlotyToGrosze(_price.text),
        );
  }

  void _addSector() {
    ref.read(wheelStorageProvider.notifier).addSector();
  }

  void _removeSector(StorageL10n l10n) {
    final last = ref.read(wheelStorageProvider).sectorCount;
    final result = ref.read(wheelStorageProvider.notifier).removeSector();
    if (result != RemoveSectorResult.occupied || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.sectorOccupiedHint(last))),
    );
  }

  Widget _actionBar({
    required StorageL10n l10n,
    required WheelStorageState state,
    required List<WheelLot> activeLots,
    required WheelLot? selected,
    BuildContext? sheetContext,
  }) {
    final lot = selected;
    return _DeskActionBar(
      l10n: l10n,
      editLabel: lot != null && lot.isActive && !lot.intakeComplete ? l10n.markPlace : l10n.edit,
      onDelete: lot == null ? null : () => _deleteLot(lot, l10n, sheetContext: sheetContext),
      onEditPrice: lot == null
          ? null
          : () => _editLotPrice(lot, l10n, sheetContext: sheetContext),
      onEdit: lot == null
          ? null
          : () {
              if (sheetContext != null) Navigator.pop(sheetContext);
              _openEditor(l10n: l10n, existing: lot, lots: activeLots);
            },
      onRelease: lot != null && lot.isActive
          ? () {
              if (sheetContext != null) Navigator.pop(sheetContext);
              _release(lot, l10n);
            }
          : null,
      onExtend: lot != null && lot.isActive ? () => _extendLot(lot, l10n) : null,
      onPaid: lot != null && lot.isActive ? () => _markPaid(lot) : null,
      onAccrue: lot != null && lot.isActive ? () => _markAccrue(lot) : null,
      onPartial: lot != null && lot.isActive ? () => _markPartial(lot, l10n) : null,
    );
  }

  Future<void> _deleteLot(
    WheelLot lot,
    StorageL10n l10n, {
    BuildContext? sheetContext,
  }) async {
    final dialogContext = sheetContext ?? context;
    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteLot),
          content: Text(l10n.confirmDeleteLot),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.deleteLot),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }
    ref.read(wheelStorageProvider.notifier).deleteLot(lot.id);
    if (!mounted) return;
    setState(() {
      if (_selectedId == lot.id) _selectedId = null;
    });
  }

  void _onRackTap({
    required StorageL10n l10n,
    required List<WheelLot> lots,
    required int sector,
    required int rackRow,
    required int slot,
  }) {
    final occupant = lotInSlot(lots, sector, rackRow, slot);
    if (occupant != null) {
      setState(() => _selectedId = occupant.id);
      final size = MediaQuery.sizeOf(context);
      final phoneLandscape = size.shortestSide < 600 && size.width > size.height;
      if (size.width < 980 && !phoneLandscape) {
        _openMobileDetail(occupant, l10n, lots);
      }
      return;
    }
    _openEditor(
      l10n: l10n,
      lots: lots,
      sector: sector,
      rackRow: rackRow,
      slots: {slot},
    );
  }

  Future<void> _openEditor({
    required StorageL10n l10n,
    required List<WheelLot> lots,
    WheelLot? existing,
    int? sector,
    int? rackRow,
    Set<int>? slots,
  }) async {
    final saved = await showModalBottomSheet<WheelLot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LotEditorSheet(
        l10n: l10n,
        shopName: _shopName,
        lots: lots,
        existing: existing,
        sectorCount: clampSectorCount(ref.read(wheelStorageProvider).sectorCount),
        pricePerDayGrosze: ref.read(wheelStorageProvider).pricePerDayGrosze,
        presetSector: sector,
        presetRow: rackRow,
        presetSlots: slots,
      ),
    );
    if (saved == null || !mounted) return;
    ref.read(wheelStorageProvider.notifier).save(saved);
    setState(() => _selectedId = saved.id);
  }

  Future<void> _openSignedContract(
    StorageL10n l10n,
    WheelLot lot,
    int pricePerDayGrosze,
  ) {
    return showStorageContractSheet(
      context: context,
      l10n: l10n,
      previewOnly: true,
      initialPng: lot.signaturePng,
      draft: storageDraftFromLot(l10n, lot, pricePerDayGrosze, shopName: _shopName),
    );
  }

  Future<void> _openMobileDetail(
    WheelLot lot,
    StorageL10n l10n,
    List<WheelLot> lots,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12),
          child: Consumer(
            builder: (context, ref, _) {
              final latest = ref.watch(wheelStorageProvider).lots.cast<WheelLot?>().firstWhere(
                    (item) => item?.id == lot.id,
                    orElse: () => lot,
                  ) ??
                  lot;
              final cloud = ref.watch(wheelStorageProvider);
              return _LotDetail(
                lot: latest,
                l10n: l10n,
                pricePerDayGrosze: cloud.pricePerDayGrosze,
                onOpenContract: latest.hasSignature
                    ? () => _openSignedContract(l10n, latest, cloud.pricePerDayGrosze)
                    : null,
                actions: _actionBar(
                  l10n: l10n,
                  state: cloud,
                  activeLots: lots,
                  selected: latest,
                  sheetContext: context,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editLotPrice(
    WheelLot lot,
    StorageL10n l10n, {
    BuildContext? sheetContext,
  }) async {
    final shop = ref.read(wheelStorageProvider).pricePerDayGrosze;
    final current = effectiveDailyGrosze(lot, shop);
    final amount = TextEditingController(
      text: (current / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    final dialogContext = sheetContext ?? context;
    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.editPrice),
          content: TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.priceDay,
              helperText: l10n.personalPriceHint,
              helperMaxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    final grosze = parseZlotyToGrosze(amount.text);
    amount.dispose();
    if (ok != true || grosze < 0 || !mounted) return;
    final latest = ref.read(wheelStorageProvider).lots.cast<WheelLot?>().firstWhere(
          (item) => item?.id == lot.id,
          orElse: () => lot,
        ) ??
        lot;
    _persistLot(latest.copyWith(pricePerDayGrosze: grosze, setPricePerDay: true));
  }

  void _persistLot(WheelLot lot) {
    ref.read(wheelStorageProvider.notifier).save(lot);
    setState(() => _selectedId = lot.id);
  }

  void _markPaid(WheelLot lot) {
    _persistLot(lotMarkPaid(lot, DateTime.now()));
  }

  void _markAccrue(WheelLot lot) {
    _persistLot(lotMarkAccruing(lot));
  }

  Future<void> _markPartial(WheelLot lot, StorageL10n l10n) async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.payPartial),
          content: TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.enterPartial),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
        );
      },
    );
    final grosze = parseZlotyToGrosze(amount.text);
    amount.dispose();
    if (ok != true || grosze <= 0 || !mounted) return;
    _persistLot(lotMarkPartial(lot, grosze));
  }

  Future<void> _extendLot(WheelLot lot, StorageL10n l10n) async {
    final extra = TextEditingController();
    DateTime? until = lot.plannedUntil;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(l10n.extendStorage),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: extra,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.extraDays),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.newEndDate),
                    subtitle: Text(until == null ? '—' : l10n.formatDate(until!)),
                    trailing: const Icon(CupertinoIcons.calendar),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: until ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: lot.receivedAt ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setLocal(() => until = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
              ],
            );
          },
        );
      },
    );
    final extraDays = int.tryParse(extra.text.trim()) ?? 0;
    extra.dispose();
    if (ok != true || !mounted) return;
    var next = lot;
    if (extraDays > 0) {
      next = lotExtendByDays(next, extraDays);
    } else if (until != null) {
      next = lotExtendUntil(next, until!);
    } else {
      return;
    }
    _persistLot(next);
  }

  Future<void> _release(WheelLot lot, StorageL10n l10n) async {
    final palette = paletteOf(context);
    final price = ref.read(wheelStorageProvider).pricePerDayGrosze;
    final now = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              color: palette.bg,
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StorageReceiptCard(
                      lot: lot,
                      l10n: l10n,
                      shopName: _shopName,
                      pricePerDayGrosze: price,
                      until: now,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DeskTextButton(
                            label: l10n.cancel,
                            onPressed: () => Navigator.pop(context, false),
                            height: 44,
                            fontSize: 15,
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DeskTextButton(
                            label: l10n.confirmRelease,
                            onPressed: () => Navigator.pop(context, true),
                            kind: _DeskBtnKind.filled,
                            height: 44,
                            fontSize: 15,
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final closed = ref.read(wheelStorageProvider.notifier).checkout(lot, at: now);
    setState(() {
      _activeOnly = false;
      _selectedId = closed.id;
    });
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              color: palette.bg,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StorageReceiptCard(
                      lot: closed,
                      l10n: l10n,
                      shopName: _shopName,
                      pricePerDayGrosze: price,
                    ),
                    const SizedBox(height: 16),
                    _DeskTextButton(
                      label: l10n.done,
                      onPressed: () => Navigator.pop(context),
                      kind: _DeskBtnKind.filled,
                      height: 44,
                      fontSize: 15,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCornerButton extends StatelessWidget {
  const _ProfileCornerButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.height,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final h = height ?? (compact ? 32.0 : 40.0);
    return SizedBox(
      height: h,
      child: FilledButton(
        key: const Key('storage-profile-corner'),
        onPressed: onPressed,
        style: ButtonStyle(
          alignment: Alignment.center,
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
          ),
          minimumSize: WidgetStatePropertyAll(Size(0, h)),
          maximumSize: WidgetStatePropertyAll(Size(double.infinity, h)),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_crop_circle, size: compact ? 15 : 18),
            SizedBox(width: compact ? 4 : 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({
    required this.l10n,
    required this.shopName,
    this.compact = false,
  });

  final StorageL10n l10n;
  final String shopName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final name = shopName.trim().isEmpty ? l10n.title : shopName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 1.6 : 2.2,
            fontSize: compact ? 13 : 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          shopName.trim().isEmpty ? l10n.splashLead : l10n.title,
          style: TextStyle(
            color: palette.muted,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.l10n,
    required this.shopName,
    required this.quick,
    required this.phone,
    required this.plate,
    required this.vin,
    required this.first,
    required this.last,
    required this.price,
    required this.activeOnly,
    required this.activeCount,
    required this.onSearch,
    required this.onTab,
    required this.onAccept,
    required this.onPrice,
  });

  final StorageL10n l10n;
  final String shopName;
  final TextEditingController quick;
  final TextEditingController phone;
  final TextEditingController plate;
  final TextEditingController vin;
  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController price;
  final bool activeOnly;
  final int activeCount;
  final VoidCallback onSearch;
  final ValueChanged<bool> onTab;
  final VoidCallback onAccept;
  final VoidCallback onPrice;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        children: [
          Row(
            children: [
              Expanded(child: _BrandLockup(l10n: l10n, shopName: shopName, compact: true)),
              const LanguageSwitcher(),
              const ThemeSwitcher(),
            ],
          ),
          const SizedBox(height: 18),
          Text(l10n.lotsOnHand(activeCount), style: TextStyle(color: palette.muted, fontSize: 13)),
          const SizedBox(height: 12),
          _DeskTextButton(
            label: l10n.accept,
            onPressed: onAccept,
            kind: _DeskBtnKind.filled,
            expand: true,
            height: 44,
            fontSize: 15,
          ),
          const SizedBox(height: 16),
          _Seg(l10n: l10n, activeOnly: activeOnly, onTab: onTab),
          const SizedBox(height: 16),
          _Field(controller: quick, label: l10n.search, hint: l10n.searchHint, onChanged: (_) => onSearch()),
          const SizedBox(height: 8),
          _Field(controller: phone, label: l10n.phone, keyboard: TextInputType.phone, onChanged: (_) => onSearch()),
          const SizedBox(height: 8),
          _Field(controller: plate, label: l10n.plate, onChanged: (_) => onSearch()),
          const SizedBox(height: 8),
          _Field(controller: vin, label: l10n.vin, onChanged: (_) => onSearch()),
          const SizedBox(height: 8),
          _Field(controller: first, label: l10n.firstName, onChanged: (_) => onSearch()),
          const SizedBox(height: 8),
          _Field(controller: last, label: l10n.lastName, onChanged: (_) => onSearch()),
          const SizedBox(height: 18),
          _Field(
            controller: price,
            label: l10n.priceDay,
            hint: '5,00',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          _DeskTextButton(
            label: l10n.calculate,
            onPressed: onPrice,
            kind: _DeskBtnKind.filled,
            expand: true,
            height: 44,
            fontSize: 15,
          ),
          const SizedBox(height: 8),
          Text(
            'zł · ${l10n.perDay}',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CompactSearch extends StatelessWidget {
  const _CompactSearch({
    required this.l10n,
    required this.quick,
    required this.price,
    required this.activeOnly,
    required this.activeCount,
    required this.onSearch,
    required this.onTab,
    required this.onAccept,
    required this.onPrice,
  });

  final StorageL10n l10n;
  final TextEditingController quick;
  final TextEditingController price;
  final bool activeOnly;
  final int activeCount;
  final VoidCallback onSearch;
  final ValueChanged<bool> onTab;
  final VoidCallback onAccept;
  final VoidCallback onPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(controller: quick, label: l10n.search, hint: l10n.searchHint, onChanged: (_) => onSearch()),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: price,
                label: l10n.priceDay,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            _DeskTextButton(
              label: l10n.calculate,
              onPressed: onPrice,
              kind: _DeskBtnKind.filled,
              height: 44,
              fontSize: 14,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DeskTextButton(
          label: l10n.accept,
          onPressed: onAccept,
          kind: _DeskBtnKind.filled,
          expand: true,
          height: 44,
          fontSize: 15,
        ),
        const SizedBox(height: 8),
        _Seg(l10n: l10n, activeOnly: activeOnly, onTab: onTab),
      ],
    );
  }
}

class _PhoneTools extends StatelessWidget {
  const _PhoneTools({
    required this.l10n,
    required this.quick,
    required this.price,
    required this.activeOnly,
    required this.onSearch,
    required this.onTab,
    required this.onAccept,
    required this.onPrice,
    this.dense = false,
  });

  final StorageL10n l10n;
  final TextEditingController quick;
  final TextEditingController price;
  final bool activeOnly;
  final VoidCallback onSearch;
  final ValueChanged<bool> onTab;
  final VoidCallback onAccept;
  final VoidCallback onPrice;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: EdgeInsets.all(dense ? 4 : 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _PhoneField(
                    controller: quick,
                    hint: l10n.search,
                    onChanged: (_) => onSearch(),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 4,
                  child: _PhoneField(
                    controller: price,
                    hint: l10n.priceDay,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 3,
                  child: _PhoneMiniButton(label: l10n.calculate, onPressed: onPrice),
                ),
              ],
            ),
            SizedBox(height: dense ? 3 : 4),
            Row(
              children: [
                Expanded(
                  child: _PhoneMiniButton(label: l10n.accept, filled: true, onPressed: onAccept),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _Seg(l10n: l10n, activeOnly: activeOnly, onTab: onTab, dense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.hint,
    this.keyboard,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, height: 1.1),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

class _PhoneMiniButton extends StatelessWidget {
  const _PhoneMiniButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return _DeskTextButton(
      label: label,
      onPressed: onPressed,
      kind: filled ? _DeskBtnKind.filled : _DeskBtnKind.plain,
      height: 32,
      fontSize: 12,
      expand: true,
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.l10n,
    required this.activeOnly,
    required this.onTab,
    this.dense = false,
  });

  final StorageL10n l10n;
  final bool activeOnly;
  final ValueChanged<bool> onTab;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    Widget label(String text) {
      final child = Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        style: dense ? const TextStyle(fontSize: 12, fontWeight: FontWeight.w700) : null,
      );
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 8, vertical: dense ? 2 : 6),
        child: dense ? FittedBox(fit: BoxFit.scaleDown, child: child) : child,
      );
    }

    return CupertinoSlidingSegmentedControl<bool>(
      groupValue: activeOnly,
      onValueChanged: (value) {
        if (value != null) onTab(value);
      },
      children: {
        true: label(l10n.active),
        false: label(l10n.archive),
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboard,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

class _LotList extends StatelessWidget {
  const _LotList({
    required this.l10n,
    required this.lots,
    required this.selectedId,
    required this.pricePerDayGrosze,
    required this.empty,
    required this.onSelect,
    this.compact = false,
  });

  final StorageL10n l10n;
  final List<WheelLot> lots;
  final String? selectedId;
  final int pricePerDayGrosze;
  final String empty;
  final ValueChanged<String> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    if (lots.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              empty,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, height: 1.4, fontSize: 15),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        itemCount: lots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final lot = lots[index];
          final selected = lot.id == selectedId;
          final received = lot.receivedAt;
          final days = received == null
              ? null
              : storageDays(received, lot.returnedAt ?? DateTime.now());
          final daily = effectiveDailyGrosze(lot, pricePerDayGrosze);
          final bill = storageBillGrosze(
            receivedAt: received,
            until: lot.returnedAt ?? DateTime.now(),
            pricePerDayGrosze: daily,
          );
          return Material(
            color: selected ? palette.carbon : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(lot.id),
              child: Padding(
                padding: EdgeInsets.fromLTRB(compact ? 8 : 14, compact ? 8 : 12, compact ? 8 : 14, compact ? 8 : 12),
                child: Row(
                  children: [
                    WheelCargoIcon(cargo: lot.cargo, size: compact ? 28 : 42),
                    if (!compact && lot.hasSignature) ...[
                      const SizedBox(width: 8),
                      SignatureThumb(png: lot.signaturePng),
                    ],
                    SizedBox(width: compact ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lot.vehicle.trim().isEmpty
                                ? (lot.ownerName.isEmpty ? l10n.guest : lot.ownerName)
                                : lot.vehicle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 13 : 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (lot.hasPlace) lot.marker,
                              if (lot.hasCount) l10n.slotNumbers(lot.slots),
                              if (lot.hasCount) l10n.wheelsN(lot.shownWheels),
                              if (lot.plate.trim().isNotEmpty) lot.plate,
                              if (lot.ownerName.isNotEmpty && lot.vehicle.trim().isNotEmpty) lot.ownerName,
                              l10n.cargoLabel(lot.cargo),
                              lot.sizeLabel,
                              if (lot.tireBrand.trim().isNotEmpty) lot.tireBrand,
                            ].join('  ·  '),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: compact ? 11 : 12,
                              height: compact ? 1.2 : 1.3,
                            ),
                          ),
                          if (compact) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                days == null ? l10n.dateUncertain : l10n.daysCount(days),
                                days == null ? '—' : formatZloty(bill),
                                if (lot.hasPersonalDailyPrice) '${l10n.personalPrice} ${formatZloty(daily)}',
                              ].join('  ·  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: lot.hasPersonalDailyPrice ? palette.accent : palette.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            days == null ? l10n.dateUncertain : l10n.daysCount(days),
                            style: TextStyle(
                              color: days == null ? palette.danger : palette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            days == null ? '—' : formatZloty(bill),
                            style: TextStyle(color: palette.muted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (lot.hasPersonalDailyPrice) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${l10n.personalPrice} ${formatZloty(daily)}',
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _DeskBtnKind { plain, filled, danger }

class _DeskTextButton extends StatelessWidget {
  const _DeskTextButton({
    required this.label,
    required this.onPressed,
    this.kind = _DeskBtnKind.plain,
    this.height = 36,
    this.fontSize = 13,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final _DeskBtnKind kind;
  final double height;
  final double fontSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
    final child = expand
        ? Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: text,
            ),
          )
        : text;
    final style = ButtonStyle(
      alignment: Alignment.center,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, height)),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, height: 1),
      ),
    );
    final button = switch (kind) {
      _DeskBtnKind.danger => FilledButton(
          style: style.copyWith(
            backgroundColor: WidgetStatePropertyAll(palette.danger),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
          onPressed: onPressed,
          child: child,
        ),
      _DeskBtnKind.filled => FilledButton(style: style, onPressed: onPressed, child: child),
      _DeskBtnKind.plain => OutlinedButton(style: style, onPressed: onPressed, child: child),
    };
    if (expand) return SizedBox(width: double.infinity, height: height, child: button);
    return SizedBox(height: height, child: button);
  }
}

/// Add / remove sector, right-aligned under Profile and above the wheel grids.
class _SectorControls extends StatelessWidget {
  const _SectorControls({
    required this.l10n,
    required this.showAdd,
    required this.showRemove,
    required this.onAdd,
    required this.onRemove,
    this.compact = false,
    this.height,
  });

  final StorageL10n l10n;
  final bool showAdd;
  final bool showRemove;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (!showAdd && !showRemove) return const SizedBox.shrink();
    final h = height ?? (compact ? 28.0 : 36.0);
    final font = compact ? 12.0 : 13.0;
    final gap = compact ? 4.0 : 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 360.0;
        final count = (showAdd ? 1 : 0) + (showRemove ? 1 : 0);
        final gaps = count > 1 ? gap : 0.0;
        final cap = compact ? 176.0 : 210.0;
        final each = ((maxW - gaps) / count).clamp(0.0, cap);
        Widget one(String label, VoidCallback onPressed) {
          return SizedBox(
            width: each,
            height: h,
            child: _DeskTextButton(
              label: label,
              onPressed: onPressed,
              height: h,
              fontSize: font,
              expand: true,
            ),
          );
        }

        return SizedBox(
          height: h,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showRemove) one(l10n.removeSector, onRemove),
                if (showRemove && showAdd) SizedBox(width: gap),
                if (showAdd) one(l10n.addSector, onAdd),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeskActionBar extends StatelessWidget {
  const _DeskActionBar({
    required this.l10n,
    required this.editLabel,
    this.onDelete,
    this.onEdit,
    this.onEditPrice,
    this.onRelease,
    this.onExtend,
    this.onPaid,
    this.onAccrue,
    this.onPartial,
  });

  final StorageL10n l10n;
  final String editLabel;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onEditPrice;
  final VoidCallback? onRelease;
  final VoidCallback? onExtend;
  final VoidCallback? onPaid;
  final VoidCallback? onAccrue;
  final VoidCallback? onPartial;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final entries = <(String, VoidCallback, _DeskBtnKind)>[
          if (onDelete != null) (l10n.deleteLot, onDelete!, _DeskBtnKind.danger),
          if (onEdit != null) (editLabel, onEdit!, _DeskBtnKind.plain),
          if (onEditPrice != null) (l10n.editPrice, onEditPrice!, _DeskBtnKind.plain),
          if (onRelease != null) (l10n.release, onRelease!, _DeskBtnKind.filled),
          if (onExtend != null) (l10n.extendStorage, onExtend!, _DeskBtnKind.plain),
          if (onPaid != null) (l10n.payPaid, onPaid!, _DeskBtnKind.filled),
          if (onAccrue != null) (l10n.payAccrue, onAccrue!, _DeskBtnKind.plain),
          if (onPartial != null) (l10n.payPartial, onPartial!, _DeskBtnKind.plain),
        ];
        if (entries.isEmpty) return const SizedBox.shrink();
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final size = MediaQuery.sizeOf(context);
        final handset = size.shortestSide < 600;
        final landscape = size.width > size.height;
        final phone = width < 700;
        Widget button(
          (String, VoidCallback, _DeskBtnKind) entry, {
          required double height,
          required double fontSize,
          required bool expand,
        }) {
          final (label, onPressed, kind) = entry;
          return _DeskTextButton(
            label: label,
            onPressed: onPressed,
            kind: kind,
            height: height,
            fontSize: fontSize,
            expand: expand,
          );
        }

        if (handset) {
          if (landscape) {
            return SizedBox(
              height: 30,
              child: Row(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        child: button(entries[i], height: 30, fontSize: 12, expand: true),
                      ),
                    ),
                ],
              ),
            );
          }
          final cols = width < 340 ? 3 : 4;
          const rowH = 32.0;
          final rows = (entries.length / cols).ceil().clamp(1, 3);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < rows; row++)
                Padding(
                  padding: EdgeInsets.only(top: row == 0 ? 0 : 2),
                  child: SizedBox(
                    height: rowH,
                    child: Row(
                      children: [
                        for (var col = 0; col < cols; col++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: col == 0 ? 0 : 2),
                              child: (row * cols + col) >= entries.length
                                  ? const SizedBox.shrink()
                                  : button(
                                      entries[row * cols + col],
                                      height: rowH,
                                      fontSize: 12,
                                      expand: true,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
        if (phone) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  button(entries[i], height: 36, fontSize: 13, expand: false),
                ],
              ],
            ),
          );
        }
        return SizedBox(
          height: 40,
          child: Row(
            children: [
              for (var i = 0; i < entries.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    child: button(entries[i], height: 40, fontSize: 13, expand: true),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.l10n});

  final StorageL10n l10n;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.noSelection,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _LotDetail extends StatelessWidget {
  const _LotDetail({
    required this.lot,
    required this.l10n,
    required this.pricePerDayGrosze,
    this.onOpenContract,
    this.actions,
  });

  final WheelLot lot;
  final StorageL10n l10n;
  final int pricePerDayGrosze;
  final VoidCallback? onOpenContract;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final until = lot.returnedAt ?? DateTime.now();
    final daily = effectiveDailyGrosze(lot, pricePerDayGrosze);
    final days = lot.receivedAt == null ? null : lotBilledDays(lot, until);
    final bill = lotBillGrosze(
      lot: lot,
      until: until,
      pricePerDayGrosze: pricePerDayGrosze,
    );
    final due = lotDueGrosze(
      lot: lot,
      until: until,
      pricePerDayGrosze: pricePerDayGrosze,
    );

    Widget row(String k, String v) {
      if (v.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k, style: TextStyle(color: palette.muted, fontSize: 13)),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, height: 1.3),
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
              children: [
                Text(
                  lot.vehicle.trim().isEmpty ? l10n.kit : lot.vehicle,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    lot.sizeLabel,
                    if (lot.tireBrand.trim().isNotEmpty) lot.tireBrand,
                    l10n.seasonLabel(lot.season),
                    l10n.cargoLabel(lot.cargo),
                  ].join(' · '),
                  style: TextStyle(color: palette.muted, height: 1.35),
                ),
                if (lot.isActive && !lot.intakeComplete) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.fillMissing,
                    style: TextStyle(
                      color: palette.danger,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                row(l10n.owner, lot.ownerName),
                row(l10n.phone, lot.phone),
                row(l10n.plate, lot.plate),
                row(l10n.vin, lot.vin),
                row(l10n.cargo, l10n.cargoLabel(lot.cargo)),
                row(
                  l10n.place,
                  lot.hasPlace
                      ? '${l10n.sectorN(lot.sector)} · ${lot.marker}${lot.hasCount ? ' · ${l10n.slotNumbers(lot.slots)}' : ''}'
                      : '',
                ),
                if (lot.hasCount) row(l10n.wheelCountLabel, l10n.wheelsN(lot.shownWheels)),
                if (lot.hasPlannedPeriod) row(l10n.plannedPeriod, l10n.plannedLabel(lot.plannedDays)),
                if (lot.plannedUntil != null) row(l10n.until, l10n.formatDate(lot.plannedUntil!)),
                row(l10n.received, l10n.formatIntake(lot.receivedAt)),
                if (lot.returnedAt != null) row(l10n.returned, l10n.formatDate(lot.returnedAt!)),
                if (lot.hasSignature)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(l10n.signed, style: TextStyle(color: palette.muted, fontSize: 13)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: onOpenContract,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: palette.stroke),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: SignatureThumb(
                                  png: lot.signaturePng,
                                  width: 160,
                                  height: 56,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lot.hasPersonalDailyPrice || days != null)
                  row(
                    lot.hasPersonalDailyPrice ? l10n.personalPrice : l10n.perDay,
                    formatZloty(daily),
                  ),
                if (days != null) ...[
                  row(l10n.storedFor, l10n.spanLabel(storageSpan(days))),
                  row(l10n.paymentStatus, l10n.payStatusLabel(lot.payStatus)),
                  row(l10n.due, formatZloty(bill)),
                  if (lot.paidGrosze > 0) row(l10n.paidAmount, formatZloty(lot.paidGrosze)),
                  row(l10n.remainingDue, formatZloty(due)),
                ],
                row(l10n.notes, lot.notes),
              ],
            ),
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: actions,
            ),
        ],
      ),
    );
  }
}

class _LotEditorSheet extends StatefulWidget {
  const _LotEditorSheet({
    required this.l10n,
    required this.shopName,
    required this.lots,
    required this.sectorCount,
    required this.pricePerDayGrosze,
    this.existing,
    this.presetSector,
    this.presetRow,
    this.presetSlots,
  });

  final StorageL10n l10n;
  final String shopName;
  final List<WheelLot> lots;
  final int sectorCount;
  final int pricePerDayGrosze;
  final WheelLot? existing;
  final int? presetSector;
  final int? presetRow;
  final Set<int>? presetSlots;

  @override
  State<_LotEditorSheet> createState() => _LotEditorSheetState();
}

class _LotEditorSheetState extends State<_LotEditorSheet> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _plate;
  late final TextEditingController _vin;
  late final TextEditingController _vehicle;
  late final TextEditingController _size;
  late final TextEditingController _size2;
  late final TextEditingController _rim;
  late final TextEditingController _brand;
  late final TextEditingController _notes;
  late final TextEditingController _customDays;
  late DateTime? _received;
  late TireSeason _season;
  late StorageCargo _cargo;
  late int _sector;
  late int _rackRow;
  late Set<int> _slots;
  late int _plannedDays;
    late String _signaturePng;
    late String _contractVersion;
    String? _error;

  @override
  void initState() {
    super.initState();
    final lot = widget.existing;
    _first = TextEditingController(text: lot?.firstName ?? '');
    _last = TextEditingController(text: lot?.lastName ?? '');
    _phone = TextEditingController(text: lot?.phone ?? '');
    _plate = TextEditingController(text: lot?.plate ?? '');
    _vin = TextEditingController(text: lot?.vin ?? '');
    _vehicle = TextEditingController(text: lot?.vehicle ?? '');
    _size = TextEditingController(text: lot?.sizePrimary ?? '');
    _size2 = TextEditingController(text: lot?.sizeSecondary ?? '');
    _rim = TextEditingController(text: lot?.rimDiameter ?? '');
    _brand = TextEditingController(text: lot?.tireBrand ?? '');
    _notes = TextEditingController(text: lot?.notes ?? '');
    _plannedDays = lot?.plannedDays ?? 0;
    _customDays = TextEditingController(
      text: lot != null && lot.plannedDays > 0 && !const {30, 90, 180, 365}.contains(lot.plannedDays)
          ? '${lot.plannedDays}'
          : '',
    );
    _signaturePng = lot?.signaturePng ?? '';
    _contractVersion = lot?.contractVersion ?? '';
    _received = lot == null ? DateTime.now() : lot.receivedAt;
    _season = lot?.season ?? TireSeason.winter;
    _cargo = lot?.cargo ?? StorageCargo.tires;
    _sector = lot != null && lot.hasPlace ? lot.sector : (widget.presetSector ?? 0);
    _rackRow = lot != null && lot.hasPlace ? lot.rackRow : (widget.presetRow ?? 0);
    _slots = {
      if (lot != null && lot.hasCount) ...lot.slots else if (widget.presetSlots != null) ...widget.presetSlots!,
    };
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _plate.dispose();
    _vin.dispose();
    _vehicle.dispose();
    _size.dispose();
    _size2.dispose();
    _rim.dispose();
    _brand.dispose();
    _notes.dispose();
    _customDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final l10n = widget.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
          child: Column(
            children: [
              Text(
                widget.existing == null ? l10n.newLot : l10n.editLot,
                style: TextStyle(color: palette.text, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(l10n.cargo, style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cargo in StorageCargo.values)
                          ChoiceChip(
                            label: Text(l10n.cargoLabel(cargo)),
                            selected: _cargo == cargo,
                            onSelected: (_) => setState(() => _cargo = cargo),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.place, style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var sector = 1; sector <= widget.sectorCount; sector++)
                          ChoiceChip(
                            label: Text(l10n.sectorN(sector)),
                            selected: _sector == sector,
                            onSelected: (_) => setState(() {
                              _sector = sector;
                              _pruneTakenSlots();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var rackRow = 1; rackRow <= kRackCells; rackRow++)
                          ChoiceChip(
                            label: Text(
                              _sector > 0
                                  ? '${l10n.rowN(rackRow)} · ${rackMarker(_sector, rackRow)}'
                                  : l10n.rowN(rackRow),
                            ),
                            selected: _rackRow == rackRow,
                            onSelected: (_) => setState(() {
                              _rackRow = rackRow;
                              _pruneTakenSlots();
                            }),
                          ),
                      ],
                    ),
                    if (_sector > 0 && _rackRow > 0) ...[
                      const SizedBox(height: 12),
                      Text(l10n.heightSlots, style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var slot = 1; slot <= kWheelsPerCell; slot++)
                            FilterChip(
                              label: Text('$slot'),
                              selected: _slots.contains(slot),
                              onSelected: _slotTaken(slot) && !_slots.contains(slot)
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _slots.add(slot);
                                        } else {
                                          _slots.remove(slot);
                                        }
                                      });
                                    },
                            ),
                        ],
                      ),
                      if (_slots.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.wheelsN(_slots.length)} · ${l10n.slotNumbers(_slots)}',
                          style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    _Field(controller: _first, label: l10n.firstName),
                    const SizedBox(height: 8),
                    _Field(controller: _last, label: l10n.lastName),
                    const SizedBox(height: 8),
                    _Field(controller: _phone, label: l10n.phone, keyboard: TextInputType.phone),
                    const SizedBox(height: 8),
                    _Field(controller: _plate, label: l10n.plate),
                    const SizedBox(height: 8),
                    _Field(controller: _vin, label: l10n.vin),
                    const SizedBox(height: 8),
                    _Field(controller: _vehicle, label: l10n.vehicle),
                    const SizedBox(height: 8),
                    _Field(controller: _size, label: l10n.size, hint: '245/45'),
                    const SizedBox(height: 8),
                    _Field(controller: _size2, label: l10n.sizeAlt, hint: '275/40'),
                    const SizedBox(height: 8),
                    _Field(controller: _rim, label: l10n.rim, hint: '18', keyboard: TextInputType.number),
                    const SizedBox(height: 8),
                    _Field(controller: _brand, label: l10n.brandTire),
                    const SizedBox(height: 8),
                    _Field(controller: _notes, label: l10n.notes),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final season in TireSeason.values)
                          ChoiceChip(
                            label: Text(l10n.seasonLabel(season)),
                            selected: _season == season,
                            onSelected: (_) => setState(() => _season = season),
                          ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dateUncertain),
                      value: _received == null,
                      onChanged: (value) {
                        setState(() {
                          _received = value ? null : DateTime.now();
                        });
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pickDate),
                      subtitle: Text(widget.l10n.formatIntake(_received)),
                      trailing: const Icon(CupertinoIcons.calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _received ?? DateTime.now(),
                          firstDate: DateTime(2018),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setState(() => _received = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.plannedPeriod, style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in const [30, 90, 180, 365])
                          ChoiceChip(
                            label: Text(l10n.plannedLabel(item)),
                            selected: _plannedDays == item &&
                                int.tryParse(_customDays.text.trim()) == null,
                            onSelected: (on) {
                              if (!on) return;
                              setState(() {
                                _plannedDays = item;
                                _customDays.value = const TextEditingValue(text: '');
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _customDays,
                      label: l10n.customDays,
                      keyboard: TextInputType.number,
                      onChanged: (value) {
                        final days = int.tryParse(value.trim());
                        if (days != null && days > 0) {
                          setState(() => _plannedDays = days);
                        }
                      },
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!, style: TextStyle(color: palette.danger)),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _DeskTextButton(
                      label: l10n.cancel,
                      onPressed: () => Navigator.pop(context),
                      height: 44,
                      fontSize: 15,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DeskTextButton(
                      label: l10n.save,
                      onPressed: () => _save(),
                      kind: _DeskBtnKind.filled,
                      height: 44,
                      fontSize: 15,
                      expand: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _slotTaken(int slot) {
    if (_sector < 1 || _rackRow < 1) return false;
    return takenSlots(
      widget.lots,
      _sector,
      _rackRow,
      exceptId: widget.existing?.id,
    ).contains(slot);
  }

  void _pruneTakenSlots() {
    _slots.removeWhere(_slotTaken);
  }

  Future<void> _save() async {
    final identity = [_first, _last, _phone, _plate, _vin]
        .any((field) => field.text.trim().isNotEmpty);
    if (!identity) {
      setState(() => _error = widget.l10n.needIdentity);
      return;
    }
    if (_received == null) {
      setState(() => _error = widget.l10n.needDate);
      return;
    }
    if (_sector < 1 || _rackRow < 1) {
      setState(() => _error = widget.l10n.needPlace);
      return;
    }
    if (_slots.isEmpty) {
      setState(() => _error = widget.l10n.needSlots);
      return;
    }
    final planned = resolvePlannedDays(
      selected: _plannedDays,
      customText: _customDays.text,
    );
    if (planned <= 0) {
      setState(() => _error = widget.l10n.needPeriod);
      return;
    }
    _plannedDays = planned;
    for (final slot in _slots) {
      final occupant = lotInSlot(
        widget.lots,
        _sector,
        _rackRow,
        slot,
        exceptId: widget.existing?.id,
      );
      if (occupant != null) {
        final who = occupant.plate.trim().isNotEmpty
            ? occupant.plate
            : (occupant.ownerName.isEmpty ? widget.l10n.guest : occupant.ownerName);
        setState(() => _error = widget.l10n.slotTaken(rackMarker(_sector, _rackRow), slot, who));
        return;
      }
    }
    final signed = await _confirmPolicy();
    if (signed == null || !mounted) return;
    _signaturePng = signed;
    _contractVersion = kStorageContractVersion;
    final existing = widget.existing;
    final received = _received!;
    final sorted = _slots.toList()..sort();
    final lot = WheelLot(
      id: existing?.id ?? 'lot-${DateTime.now().millisecondsSinceEpoch}',
      receivedAt: DateTime(received.year, received.month, received.day, 10),
      returnedAt: existing?.returnedAt,
      dateUncertain: false,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text.trim(),
      plate: _plate.text.trim(),
      vin: _vin.text.trim(),
      vehicle: _vehicle.text.trim(),
      sizePrimary: _size.text.trim(),
      sizeSecondary: _size2.text.trim(),
      rimDiameter: _rim.text.trim(),
      tireBrand: _brand.text.trim(),
      season: _season,
      cargo: _cargo,
      sector: _sector,
      rackRow: _rackRow,
      wheelCount: sorted.length,
      wheelSlots: maskFromSlots(sorted),
      notes: _notes.text.trim(),
      journalNo: existing?.journalNo ?? 0,
      plannedDays: _plannedDays,
      signaturePng: _signaturePng,
      contractVersion: _contractVersion,
      paidGrosze: existing?.paidGrosze ?? 0,
      payStatus: existing?.payStatus ?? StoragePayStatus.accruing,
      billingFrom: existing?.billingFrom,
      pricePerDayGrosze: existing?.pricePerDayGrosze,
    );
    if (!mounted) return;
    Navigator.pop(context, lot);
  }

  Future<String?> _confirmPolicy() async {
    final l10n = widget.l10n;
    final name = [_first.text, _last.text].where((p) => p.trim().isNotEmpty).join(' ').trim();
    final received = _received;
    final until = received == null || _plannedDays <= 0
        ? ''
        : l10n.formatDate(
            DateTime(received.year, received.month, received.day)
                .add(Duration(days: _plannedDays)),
          );
    final billed = _plannedDays < 1 ? 0 : _plannedDays;
    final daily = widget.existing?.pricePerDayGrosze ?? widget.pricePerDayGrosze;
    final total = billed * daily;
    return showStorageContractSheet(
      context: context,
      l10n: l10n,
      initialPng: _signaturePng,
      draft: StorageContractDraft(
        keeper: widget.shopName.trim().isEmpty ? l10n.title : widget.shopName.trim(),
        client: name,
        plate: _plate.text.trim(),
        phone: _phone.text.trim(),
        vehicle: _vehicle.text.trim(),
        period: _plannedDays <= 0 ? '—' : l10n.plannedLabel(_plannedDays),
        dailyFee: formatZloty(daily),
        until: until,
        billedDays: billed,
        periodTotal: formatZloty(total),
        signedAt: received,
        signaturePng: _signaturePng,
      ),
    );
  }
}
