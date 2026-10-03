import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/storage_contract.dart';
import '../../domain/models/wheel_storage.dart';
import 'storage_contract_export.dart';
import 'storage_l10n.dart';
import 'storage_signature.dart';

class StorageContractSheet extends StatefulWidget {
  const StorageContractSheet({
    super.key,
    required this.l10n,
    required this.draft,
    this.initialPng = '',
    this.previewOnly = false,
  });

  final StorageL10n l10n;
  final StorageContractDraft draft;
  final String initialPng;
  final bool previewOnly;

  @override
  State<StorageContractSheet> createState() => _StorageContractSheetState();
}

class _StorageContractSheetState extends State<StorageContractSheet> {
  final _pad = GlobalKey<StorageSignaturePadState>();
  var _agreed = false;
  String? _error;
  String _signedPng = '';

  @override
  void initState() {
    super.initState();
    _signedPng = widget.initialPng;
    _agreed = widget.previewOnly || _signedPng.isNotEmpty;
  }

  StorageContractDraft get _live => widget.draft.copyWith(
        signaturePng: _signedPng.isEmpty ? widget.initialPng : _signedPng,
        signedAt: widget.draft.signedAt ??
            (_signedPng.isNotEmpty ? DateTime.now() : null),
        contractVersion: kStorageContractVersion,
      );

  List<({String title, String body})> get _clauses {
    return widget.l10n.contractClauses(
      keeper: widget.draft.keeper,
      client: widget.draft.client,
      plate: widget.draft.plate,
      vehicle: widget.draft.vehicle,
      period: widget.draft.period,
      dailyFee: widget.draft.dailyFee,
      until: widget.draft.until,
      periodTotal: widget.draft.periodTotal,
      billedDays: widget.draft.billedDays,
    );
  }

  String _html() {
    final l10n = widget.l10n;
    return buildStorageContractHtml(
      title: l10n.contractDocTitle,
      city: widget.draft.keeper,
      keeperLabel: l10n.contractKeeper,
      clientLabel: l10n.contractClient,
      signedLabel: l10n.signedAt,
      versionLabel: l10n.contractVersionLabel,
      draft: _live,
      clauses: _clauses,
    );
  }

  Future<void> _print() async {
    await printStorageContractHtml(_html(), storageContractFileName(_live));
  }

  Future<void> _save() async {
    await downloadStorageContractHtml(_html(), storageContractFileName(_live));
  }

  Future<void> _confirm() async {
    if (!_agreed) {
      setState(() => _error = widget.l10n.needAgree);
      return;
    }
    final png = await _pad.currentState?.exportPng() ?? _signedPng;
    if (png == null || png.isEmpty) {
      setState(() => _error = widget.l10n.needSignature);
      return;
    }
    setState(() {
      _signedPng = png;
      _error = null;
    });
  }

  void _finish() {
    if (_signedPng.isEmpty) return;
    Navigator.pop(context, _signedPng);
  }

  Widget _contractBtn(String label, VoidCallback onPressed, {bool filled = false}) {
    const height = 44.0;
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
      ),
    );
    final style = ButtonStyle(
      alignment: Alignment.center,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
      minimumSize: const WidgetStatePropertyAll(Size(0, height)),
      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, height)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1),
      ),
    );
    final button = filled
        ? FilledButton(style: style, onPressed: onPressed, child: child)
        : OutlinedButton(style: style, onPressed: onPressed, child: child);
    return SizedBox(width: double.infinity, height: height, child: button);
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final l10n = widget.l10n;
    final signed = _signedPng.isNotEmpty || widget.previewOnly;
    final paper = palette.isDark ? const Color(0xFFF4EFE6) : const Color(0xFFFFF8EE);
    final ink = const Color(0xFF1A1814);
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.policyTitle,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (!signed)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  l10n.contractReadFirst,
                  style: TextStyle(color: palette.muted, height: 1.35),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4CBB8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: ink,
                          fontSize: 14,
                          height: 1.45,
                          fontFamily: 'Times',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.contractDocTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.4,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.draft.keeper} · ${l10n.contractVersionLabel} $kStorageContractVersion',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5A564C)),
                            ),
                            const SizedBox(height: 14),
                            Text('${l10n.contractKeeper}: ${widget.draft.keeper}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${l10n.contractClient}: ${[
                                if (widget.draft.client.trim().isNotEmpty) widget.draft.client,
                                if (widget.draft.phone.trim().isNotEmpty) widget.draft.phone,
                                if (widget.draft.plate.trim().isNotEmpty) widget.draft.plate,
                              ].join(' · ')}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            for (final clause in _clauses) ...[
                              Text(clause.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(clause.body),
                              const SizedBox(height: 10),
                            ],
                            const Divider(color: Color(0xFFC8BEAA)),
                            Text(l10n.policySign, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            if (signed)
                              _BurnedSignature(
                                png: _signedPng.isEmpty ? widget.initialPng : _signedPng,
                                client: widget.draft.client,
                                plate: widget.draft.plate,
                                date: _live.signedAt,
                                signedLabel: l10n.signedAt,
                              )
                            else
                              StorageSignaturePad(
                                key: _pad,
                                l10n: l10n,
                                initialPng: widget.initialPng,
                                height: 132,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!signed) ...[
                    CheckboxListTile(
                      value: _agreed,
                      onChanged: (value) => setState(() => _agreed = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.policyAgree),
                    ),
                    if (_error != null)
                      Text(_error!, style: TextStyle(color: palette.danger)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + MediaQuery.paddingOf(context).bottom),
              child: signed
                  ? Row(
                      children: [
                        Expanded(child: _contractBtn(l10n.contractPrint, _print)),
                        const SizedBox(width: 8),
                        Expanded(child: _contractBtn(l10n.contractSave, _save)),
                        if (!widget.previewOnly) ...[
                          const SizedBox(width: 8),
                          Expanded(child: _contractBtn(l10n.contractDone, _finish, filled: true)),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _contractBtn(l10n.cancel, () => Navigator.pop(context))),
                        const SizedBox(width: 10),
                        Expanded(child: _contractBtn(l10n.confirmPolicy, _confirm, filled: true)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurnedSignature extends StatelessWidget {
  const _BurnedSignature({
    required this.png,
    required this.client,
    required this.plate,
    required this.date,
    required this.signedLabel,
  });

  final String png;
  final String client;
  final String plate;
  final DateTime? date;
  final String signedLabel;

  @override
  Widget build(BuildContext context) {
    final when = date;
    final stamp = [
      if (when != null)
        '${when.day.toString().padLeft(2, '0')}.${when.month.toString().padLeft(2, '0')}.${when.year}',
      if (client.trim().isNotEmpty) client.trim(),
      if (plate.trim().isNotEmpty) plate.trim(),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 96,
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1A1814))),
          ),
          alignment: Alignment.centerLeft,
          child: png.trim().isEmpty
              ? const SizedBox.shrink()
              : Image.memory(base64Decode(png), height: 88, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        Text(
          '$signedLabel: ${stamp.isEmpty ? '—' : stamp}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5A564C)),
        ),
      ],
    );
  }
}

StorageContractDraft storageDraftFromLot(
  StorageL10n l10n,
  WheelLot lot,
  int pricePerDayGrosze, {
  String shopName = '',
}) {
  final keeper = shopName.trim().isEmpty ? l10n.title : shopName.trim();
  final daily = effectiveDailyGrosze(lot, pricePerDayGrosze);
  return StorageContractDraft(
    keeper: keeper,
    client: lot.ownerName,
    plate: lot.plate,
    phone: lot.phone,
    vehicle: lot.vehicle,
    period: lot.plannedDays <= 0 ? '—' : l10n.plannedLabel(lot.plannedDays),
    dailyFee: formatZloty(daily),
    until: lot.plannedUntil == null ? '' : l10n.formatDate(lot.plannedUntil!),
    billedDays: lot.plannedDays > 0
        ? lot.plannedDays
        : (lot.receivedAt == null
            ? 0
            : billedStorageDays(lot.receivedAt!, lot.plannedUntil ?? DateTime.now())),
    periodTotal: formatZloty(
      lot.plannedDays > 0 && daily > 0
          ? lot.plannedDays * daily
          : storageBillGrosze(
              receivedAt: lot.receivedAt,
              until: lot.plannedUntil ?? DateTime.now(),
              pricePerDayGrosze: daily,
            ),
    ),
    signedAt: lot.receivedAt,
    signaturePng: lot.signaturePng,
    contractVersion:
        lot.contractVersion.trim().isEmpty ? kStorageContractVersion : lot.contractVersion,
  );
}

Future<String?> showStorageContractSheet({
  required BuildContext context,
  required StorageL10n l10n,
  required StorageContractDraft draft,
  String initialPng = '',
  bool previewOnly = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: previewOnly,
    enableDrag: previewOnly,
    backgroundColor: Colors.transparent,
    builder: (context) => StorageContractSheet(
      l10n: l10n,
      draft: draft,
      initialPng: initialPng,
      previewOnly: previewOnly,
    ),
  );
}
