import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/wheel_storage.dart';
import 'storage_l10n.dart';
import 'storage_signature.dart';

class StorageReceiptCard extends StatelessWidget {
  const StorageReceiptCard({
    super.key,
    required this.lot,
    required this.l10n,
    required this.pricePerDayGrosze,
    this.shopName = '',
    this.until,
  });

  final WheelLot lot;
  final StorageL10n l10n;
  final int pricePerDayGrosze;
  final String shopName;
  final DateTime? until;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final end = until ?? lot.returnedAt ?? DateTime.now();
    final received = lot.receivedAt;
    final daily = effectiveDailyGrosze(lot, pricePerDayGrosze);
    final days = received == null ? 0 : lotBilledDays(lot, end);
    final span = storageSpan(days);
    final bill = lotBillGrosze(
      lot: lot,
      until: end,
      pricePerDayGrosze: pricePerDayGrosze,
    );
    final due = lotDueGrosze(
      lot: lot,
      until: end,
      pricePerDayGrosze: pricePerDayGrosze,
    );
    final line = palette.isDark ? const Color(0x33FFFFFF) : palette.stroke;
    final paper = palette.isDark ? const Color(0xFF161618) : Colors.white;

    Widget kv(String k, String v, {bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: Text(
                k,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.text,
                  fontSize: strong ? 16 : 14,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
        boxShadow: kIsWeb
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: palette.isDark ? 0.35 : 0.08,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (shopName.trim().isEmpty ? l10n.title : shopName.trim())
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontSize: 13,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shopName.trim().isEmpty ? l10n.splashLead : l10n.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.muted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: line),
            const SizedBox(height: 16),
            Text(
              l10n.receiptTitle,
              style: TextStyle(
                color: palette.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.weStored(days),
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, height: 1.4, fontSize: 14),
            ),
            const SizedBox(height: 18),
            kv(l10n.owner, lot.ownerName.isEmpty ? l10n.guest : lot.ownerName),
            if (lot.vehicle.trim().isNotEmpty) kv(l10n.vehicle, lot.vehicle),
            if (lot.plate.trim().isNotEmpty) kv(l10n.plate, lot.plate),
            if (lot.phone.trim().isNotEmpty) kv(l10n.phone, lot.phone),
            if (lot.vin.trim().isNotEmpty) kv(l10n.vin, lot.vin),
            kv(
              l10n.size,
              [
                lot.sizeLabel,
                if (lot.tireBrand.trim().isNotEmpty) lot.tireBrand,
                l10n.seasonLabel(lot.season),
                l10n.cargoLabel(lot.cargo),
              ].where((part) => part.trim().isNotEmpty).join(' · '),
            ),
            if (lot.hasPlace) kv(l10n.place, lot.hasCount ? '${lot.marker} · ${l10n.slotNumbers(lot.slots)}' : lot.marker),
            if (lot.hasCount) kv(l10n.wheelCountLabel, l10n.wheelsN(lot.shownWheels)),
            if (lot.hasPlannedPeriod) kv(l10n.plannedPeriod, l10n.plannedLabel(lot.plannedDays)),
            if (lot.plannedUntil != null) kv(l10n.until, l10n.formatDate(lot.plannedUntil!)),
            kv(l10n.received, l10n.formatIntake(lot.receivedAt)),
            kv(l10n.returned, l10n.formatDate(end)),
            kv(l10n.storedFor, l10n.spanLabel(span)),
            kv(
              lot.hasPersonalDailyPrice ? l10n.personalPrice : l10n.perDay,
              formatZloty(daily),
            ),
            kv(l10n.paymentStatus, l10n.payStatusLabel(lot.payStatus)),
            if (lot.paidGrosze > 0) kv(l10n.paidAmount, formatZloty(lot.paidGrosze)),
            const SizedBox(height: 8),
            Container(height: 1, color: line),
            const SizedBox(height: 10),
            kv(l10n.due, formatZloty(bill)),
            kv(l10n.remainingDue, formatZloty(due), strong: true),
            const SizedBox(height: 16),
            Text(
              l10n.youOwe(formatZloty(due)),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.thankYou,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, height: 1.35, fontSize: 13),
            ),
            if (lot.hasSignature) ...[
              const SizedBox(height: 14),
              Text(
                l10n.signed,
                style: TextStyle(color: palette.muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SignatureThumb(png: lot.signaturePng, width: 160, height: 64),
            ],
          ],
        ),
      ),
    );
  }
}
