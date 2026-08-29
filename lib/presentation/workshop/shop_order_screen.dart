import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/service_report.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/platform_features.dart';
import '../client/widgets/job_status_stage.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import '../widgets/work_order_naryad.dart';
import 'shop_chat_box.dart';
import 'shop_jobs.dart';
import 'shop_jobs_screen.dart';
import 'shop_ops_screens.dart';

class ShopOrderScreen extends ConsumerWidget {
  const ShopOrderScreen({
    super.key,
    required this.orderId,
    this.focusMasterChat = false,
  });

  final String orderId;
  final bool focusMasterChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final orders = ref.watch(ordersProvider);
    WorkOrder? order;
    for (final item in orders) {
      if (item.id == orderId) {
        order = item;
        break;
      }
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tabBookings)),
        body: const Center(child: Text('—')),
      );
    }
    final current = order;
    final when = current.scheduledAt;
    final report = incomingReport(current);
    final blacklist = ref.watch(blacklistProvider);
    final loginKey = normalizeClientKey(current.clientLogin);
    final plateKey = normalizeClientKey(current.plate);
    final blacklistHits = [
      for (final e in blacklist)
        if ((loginKey.isNotEmpty && e.clientKey == loginKey) ||
            (plateKey.isNotEmpty && e.clientKey == plateKey))
          e,
    ];
    final blacklisted = blacklistHits.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('${current.brand} ${current.model}'),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.plate,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: palette.text,
                    ),
                  ),
                  if (blacklisted) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.danger.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.blacklistHit,
                            style: TextStyle(
                              color: palette.danger,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          for (final hit in blacklistHits)
                            Text(
                              '· ${hit.shopName}: ${hit.reason}',
                              style: TextStyle(color: palette.text, height: 1.35),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(ordersProvider.notifier).save(
                              current.copyWith(status: JobStatus.cancelled),
                            );
                        Navigator.of(context).maybePop();
                      },
                      child: Text(s.blacklistCancelOk),
                    ),
                  ],
                  Text(
                    '${current.brand} ${current.model}${current.year > 0 ? ' ${current.year}' : ''}',
                    style: TextStyle(color: palette.muted),
                  ),
                  if (when != null)
                    Text(
                      DateFormat('d MMM, HH:mm').format(when),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                      ),
                    ),
                  const SizedBox(height: 10),
                  JobPhaseStrip(order: current, strings: s),
                  const SizedBox(height: 12),
                  JobClockStrip(orderId: current.id),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (current.status == JobStatus.created)
              FilledButton(
                onPressed: () =>
                    takeIntoBay(ref.read(ordersProvider.notifier), current),
                child: Text(s.shopTakeInBay),
              )
            else if (current.status == JobStatus.inProgress)
              FilledButton(
                onPressed: () => markReady(
                  ref.read(ordersProvider.notifier),
                  current,
                  shop: ref.read(shopAccountProvider.notifier),
                ),
                child: Text(s.shopMarkReady),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(ordersProvider.notifier).addChat(
                      current.id,
                      ServiceChatMessage(
                        id: 'ping_${DateTime.now().millisecondsSinceEpoch}',
                        fromShop: true,
                        at: DateTime.now(),
                        text: L(s.opsRemindPing, s.opsRemindPing, s.opsRemindPing),
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.opsRemindSent)),
                );
              },
              icon: const Icon(CupertinoIcons.chat_bubble),
              label: Text(s.opsNotifyClient),
            ),
            const SizedBox(height: 16),
            JobStatusStage(
              order: current,
              label: shopStatusLabel(s, current),
            ),
            const SizedBox(height: 8),
            Text(s.jobProcess, style: TextStyle(color: palette.muted, fontSize: 13)),
            const SizedBox(height: 22),
            Text(
              s.gallery,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.4,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = report[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 148,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(item.asset, fit: BoxFit.cover),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Text(
                              item.title.of(lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                shadows: [
                                  Shadow(blurRadius: 8, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          if (item.video)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                CupertinoIcons.play_circle_fill,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            Text(
              s.confirmedWorks,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in current.confirmedLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(line.title.of(lang))),
                    Text(formatUah(line.priceUah)),
                  ],
                ),
              ),
            Text(
              formatUah(current.totalUah),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 18),
            WorkOrderNaryadPanel(order: current, mode: NaryadMode.shop),
            const SizedBox(height: 22),
            Text(
              s.shopTabChat,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                final clientBox = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.shopChatClients,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShopChatBox(order: current, compact: wide),
                  ],
                );
                final masterBox = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.shopChatMasters,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShopChatBox(
                      order: current,
                      compact: wide,
                      withMaster: true,
                    ),
                  ],
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: focusMasterChat ? masterBox : clientBox),
                      const SizedBox(width: 12),
                      Expanded(child: focusMasterChat ? clientBox : masterBox),
                    ],
                  );
                }
                return Column(
                  children: [
                    if (focusMasterChat) ...[
                      masterBox,
                      const SizedBox(height: 14),
                      clientBox,
                    ] else ...[
                      clientBox,
                      const SizedBox(height: 14),
                      masterBox,
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
