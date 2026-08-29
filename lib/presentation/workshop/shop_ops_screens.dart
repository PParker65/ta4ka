import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/sto_ops_providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/sto_ops.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'shop_jobs.dart';

class ShopStockScreen extends ConsumerWidget {
  const ShopStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final stock = ref.watch(warehouseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsStockTitle),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(s.opsStockLead, style: TextStyle(color: palette.muted, height: 1.35)),
            const SizedBox(height: 12),
            for (final item in stock)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'OEM ${item.oem} · ${s.opsBin} ${item.bin}\n'
                  '${s.opsFree}: ${item.free} · ${s.opsReserved}: ${item.reserved} · ${formatUah(item.costUah)}',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: s.opsReserve,
                      onPressed: item.free <= 0
                          ? null
                          : () => ref.read(warehouseProvider.notifier).reserve(item.id, 1),
                      icon: const Icon(CupertinoIcons.bookmark),
                    ),
                    IconButton(
                      tooltip: s.opsReceive,
                      onPressed: () => ref.read(warehouseProvider.notifier).receive(item.id, 1),
                      icon: const Icon(CupertinoIcons.plus_circle),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ShopChecklistScreen extends ConsumerWidget {
  const ShopChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final jobs = shopJobs(ref.watch(ordersProvider));
    final order = jobs.isEmpty ? null : jobs.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsCheckTitle),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: order == null
            ? Center(child: Text(s.shopNoJobs, style: TextStyle(color: palette.muted)))
            : InspectionChecklist(order: order),
      ),
    );
  }
}

class InspectionChecklist extends ConsumerWidget {
  const InspectionChecklist({super.key, required this.order, this.compact = false});

  final WorkOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final run = ref.watch(inspectionsProvider)[order.id] ?? InspectionRun(orderId: order.id);
    final okCount = run.marks.where((m) => m.ok).length;
    final failCount = run.marks.where((m) => !m.ok).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, compact ? 24 : 32),
      children: [
        Text(
          '${order.brand} ${order.model} · ${order.plate}',
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.text),
        ),
        const SizedBox(height: 4),
        Text(
          '${s.opsCheckOk}: $okCount · ${s.opsCheckFail}: $failCount · ${kChecklist.length}',
          style: TextStyle(color: palette.muted),
        ),
        const SizedBox(height: 12),
        for (final point in kChecklist)
          _CheckRow(orderId: order.id, point: point, lang: lang, run: run),
      ],
    );
  }
}

class _CheckRow extends ConsumerWidget {
  const _CheckRow({
    required this.orderId,
    required this.point,
    required this.lang,
    required this.run,
  });

  final String orderId;
  final ChecklistPoint point;
  final AppLang lang;
  final InspectionRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = paletteOf(context);
    ChecklistMark? mark;
    for (final m in run.marks) {
      if (m.pointId == point.id) mark = m;
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(point.title(lang), style: TextStyle(color: palette.text, fontSize: 15)),
      subtitle: Text(point.zone, style: TextStyle(color: palette.muted, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => ref.read(inspectionsProvider.notifier).mark(
                  orderId,
                  ChecklistMark(pointId: point.id, ok: true),
                ),
            icon: Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: mark?.ok == true ? const Color(0xFF2ECC71) : palette.muted,
            ),
          ),
          IconButton(
            onPressed: () => ref.read(inspectionsProvider.notifier).mark(
                  orderId,
                  ChecklistMark(pointId: point.id, ok: false),
                ),
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: mark?.ok == false ? palette.danger : palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class ShopBaysScreen extends ConsumerWidget {
  const ShopBaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final bays = ref.watch(baysProvider);
    final jobs = jobsToday(ref.watch(ordersProvider), DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsBaysTitle),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(s.opsBaysLead, style: TextStyle(color: palette.muted, height: 1.35)),
            const SizedBox(height: 12),
            for (final bay in bays)
              Card(
                child: ListTile(
                  title: Text(bay.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(_bayJob(jobs, bay.orderId) ?? s.opsBayFree),
                  trailing: PopupMenuButton<String>(
                    onSelected: (id) => ref.read(baysProvider.notifier).assign(
                          bay.bayId,
                          id == '_' ? null : id,
                        ),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: '_', child: Text(s.opsBayFree)),
                      for (final job in jobs)
                        PopupMenuItem(
                          value: job.id,
                          child: Text('${job.plate} · ${job.brand}'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _bayJob(List<WorkOrder> jobs, String? id) {
    if (id == null) return null;
    for (final job in jobs) {
      if (job.id == id) return '${job.brand} ${job.model} · ${job.plate}';
    }
    return id;
  }
}

class ShopKpiScreen extends ConsumerWidget {
  const ShopKpiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final orders = shopJobs(ref.watch(ordersProvider));
    final ready = [for (final o in orders) if (o.status == JobStatus.ready) o];
    final labor = ready.fold<int>(0, (n, o) => n + laborUah(o.etaMinutes));
    final parts = ready.fold<int>(0, (n, o) => n + (o.totalUah - laborUah(o.etaMinutes)).clamp(0, o.totalUah));
    final pay = (labor * 0.32).round();
    final clocks = ref.watch(jobClocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsKpiTitle),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(s.opsKpiLead, style: TextStyle(color: palette.muted, height: 1.35)),
            const SizedBox(height: 14),
            _kpi(s.opsClosed, '${ready.length}', palette),
            _kpi(s.opsLabor, formatUah(labor), palette),
            _kpi(s.opsPartsShare, formatUah(parts < 0 ? 0 : parts), palette),
            _kpi(s.opsPayroll, formatUah(pay), palette),
            const SizedBox(height: 18),
            Text(s.opsTimeOnJobs, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final clock in clocks.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(clock.orderId),
                trailing: Text(_fmt(clock.live())),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: palette.muted))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: palette.text)),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ShopRemindersScreen extends ConsumerWidget {
  const ShopRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final items = ref.watch(remindersProvider);
    final jobs = shopJobs(ref.watch(ordersProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsRemindTitle),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(s.opsRemindLead, style: TextStyle(color: palette.muted, height: 1.35)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: jobs.isEmpty
                  ? null
                  : () => ref.read(remindersProvider.notifier).addFromOrder(jobs.last),
              icon: const Icon(CupertinoIcons.plus),
              label: Text(s.opsRemindAdd),
            ),
            const SizedBox(height: 14),
            for (final r in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${r.plate} · ${r.work}'),
                subtitle: Text(
                  '${r.client} · ${r.dueKm} km · ${DateFormat('d MMM').format(r.dueAt)}'
                  '${r.sent ? ' · ${s.opsRemindSent}' : ''}',
                ),
                trailing: r.sent
                    ? Icon(CupertinoIcons.checkmark_seal_fill, color: palette.accent)
                    : TextButton(
                        onPressed: () {
                          ref.read(remindersProvider.notifier).markSent(r.id);
                          _pingClient(ref, jobs, r, s.opsRemindPing);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.opsRemindSent)),
                          );
                        },
                        child: Text(s.opsRemindSend),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  void _pingClient(WidgetRef ref, List<WorkOrder> jobs, ServiceReminder r, String text) {
    WorkOrder? hit;
    for (final job in jobs) {
      if (job.plate == r.plate || job.vin == r.vin) {
        hit = job;
        break;
      }
    }
    if (hit == null) return;
    ref.read(ordersProvider.notifier).addChat(
          hit.id,
          ServiceChatMessage(
            id: 'to_${DateTime.now().millisecondsSinceEpoch}',
            fromShop: true,
            at: DateTime.now(),
            text: L(text, text, text),
          ),
        );
  }
}

class JobClockStrip extends ConsumerWidget {
  const JobClockStrip({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final clock = ref.watch(jobClocksProvider)[orderId] ?? JobClock(orderId: orderId);
    final live = clock.live();
    return Row(
      children: [
        Expanded(
          child: Text(
            '${s.opsClock}: ${live.inHours}:${live.inMinutes.remainder(60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        FilledButton(
          onPressed: () => ref.read(jobClocksProvider.notifier).toggle(orderId),
          child: Text(clock.running ? s.opsClockStop : s.opsClockStart),
        ),
      ],
    );
  }
}
