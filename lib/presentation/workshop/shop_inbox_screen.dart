import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'shop_jobs.dart';

class ShopInboxScreen extends ConsumerWidget {
  const ShopInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final jobs = shopJobs(ref.watch(ordersProvider));

    final clients = [...jobs]
      ..sort((a, b) {
        final ua = shopUnread(a) ? 0 : 1;
        final ub = shopUnread(b) ? 0 : 1;
        if (ua != ub) return ua.compareTo(ub);
        return shopThread(b).last.at.compareTo(shopThread(a).last.at);
      });

    final masters = [...jobs]
      ..sort((a, b) {
        final ua = masterUnread(a) ? 0 : 1;
        final ub = masterUnread(b) ? 0 : 1;
        if (ua != ub) return ua.compareTo(ub);
        return masterThread(b).last.at.compareTo(masterThread(a).last.at);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shopTabChat),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: jobs.isEmpty
            ? Center(
                child: Text(
                  s.shopChatEmpty,
                  style: TextStyle(color: palette.muted),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _InboxColumn(
                        title: s.shopChatClients,
                        jobs: clients,
                        strings: s,
                        lang: lang,
                        masterSide: false,
                      ),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: palette.stroke,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InboxColumn(
                        title: s.shopChatMasters,
                        jobs: masters,
                        strings: s,
                        lang: lang,
                        masterSide: true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InboxColumn extends StatelessWidget {
  const _InboxColumn({
    required this.title,
    required this.jobs,
    required this.strings,
    required this.lang,
    required this.masterSide,
  });

  final String title;
  final List<WorkOrder> jobs;
  final AppStrings strings;
  final AppLang lang;
  final bool masterSide;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: palette.text,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = jobs[index];
              final thread =
                  masterSide ? masterThread(order) : shopThread(order);
              final unread =
                  masterSide ? masterUnread(order) : shopUnread(order);
              final last = thread.last;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(
                    '/staff/chat/${order.id}?side=${masterSide ? 'master' : 'client'}',
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: unread
                          ? palette.accent.withValues(alpha: 0.12)
                          : palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unread
                            ? palette.accent.withValues(alpha: 0.7)
                            : palette.stroke,
                        width: unread ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${order.brand} ${order.model}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: palette.text,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: palette.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          order.plate,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          last.text.of(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(last.at),
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
