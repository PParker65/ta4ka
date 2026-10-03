const kStorageContractVersion = '1';

class StorageContractDraft {
  const StorageContractDraft({
    required this.keeper,
    required this.client,
    required this.plate,
    required this.phone,
    required this.vehicle,
    required this.period,
    required this.dailyFee,
    required this.until,
    this.periodTotal = '',
    this.billedDays = 0,
    this.signedAt,
    this.signaturePng = '',
    this.contractVersion = kStorageContractVersion,
  });

  final String keeper;
  final String client;
  final String plate;
  final String phone;
  final String vehicle;
  final String period;
  final String dailyFee;
  final String until;
  final String periodTotal;
  final int billedDays;
  final DateTime? signedAt;
  final String signaturePng;
  final String contractVersion;

  StorageContractDraft copyWith({
    String? signaturePng,
    DateTime? signedAt,
    String? contractVersion,
  }) {
    return StorageContractDraft(
      keeper: keeper,
      client: client,
      plate: plate,
      phone: phone,
      vehicle: vehicle,
      period: period,
      dailyFee: dailyFee,
      until: until,
      periodTotal: periodTotal,
      billedDays: billedDays,
      signedAt: signedAt ?? this.signedAt,
      signaturePng: signaturePng ?? this.signaturePng,
      contractVersion: contractVersion ?? this.contractVersion,
    );
  }
}

String storageContractFileName(StorageContractDraft draft) {
  final plate = draft.plate.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
  final tag = plate.isEmpty ? 'lot' : plate;
  return 'kolesasave-umowa-$tag.html';
}

String escapeHtml(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String buildStorageContractHtml({
  required String title,
  required String city,
  required String keeperLabel,
  required String clientLabel,
  required String signedLabel,
  required String versionLabel,
  required StorageContractDraft draft,
  required List<({String title, String body})> clauses,
}) {
  final sign = draft.signaturePng.trim();
  final signHtml = sign.isEmpty
      ? ''
      : '<img class="sign" alt="" src="data:image/png;base64,$sign" />';
  final when = draft.signedAt;
  final date = when == null
      ? ''
      : '${when.day.toString().padLeft(2, '0')}.${when.month.toString().padLeft(2, '0')}.${when.year}';
  final bits = [
    if (draft.client.trim().isNotEmpty) escapeHtml(draft.client),
    if (draft.phone.trim().isNotEmpty) escapeHtml(draft.phone),
    if (draft.plate.trim().isNotEmpty) escapeHtml(draft.plate),
  ];
  final clauseHtml = clauses
      .map(
        (c) =>
            '<h2>${escapeHtml(c.title)}</h2><p>${escapeHtml(c.body)}</p>',
      )
      .join();
  return '''<!doctype html>
<html><head><meta charset="utf-8">
<title>${escapeHtml(title)}</title>
<style>
  @page { margin: 16mm; }
  body { font: 13px/1.45 "Times New Roman", Times, serif; color: #111; margin: 24px; }
  h1 { font-size: 18px; letter-spacing: .04em; text-align: center; margin: 0 0 6px; }
  .meta { text-align: center; color: #444; margin: 0 0 18px; font-size: 12px; }
  h2 { font-size: 13px; margin: 14px 0 4px; }
  p { margin: 0 0 8px; }
  .signbox { margin-top: 22px; border-top: 1px solid #bbb; padding-top: 10px; }
  .sign { height: 72px; display: block; }
  .foot { font-size: 11px; color: #555; margin-top: 8px; }
</style></head>
<body>
<h1>${escapeHtml(title)}</h1>
<p class="meta">${escapeHtml(draft.keeper)} · ${escapeHtml(city)} · $versionLabel ${escapeHtml(draft.contractVersion)}</p>
<p><b>${escapeHtml(keeperLabel)}:</b> ${escapeHtml(draft.keeper)}</p>
<p><b>${escapeHtml(clientLabel)}:</b> ${bits.isEmpty ? '—' : bits.join(' · ')}</p>
$clauseHtml
<div class="signbox">
  $signHtml
  <div class="foot">${escapeHtml(signedLabel)}: ${date.isEmpty ? '—' : date}${draft.plate.trim().isEmpty ? '' : ' · ${escapeHtml(draft.plate)}'}${draft.client.trim().isEmpty ? '' : ' · ${escapeHtml(draft.client)}'}</div>
</div>
</body></html>''';
}
