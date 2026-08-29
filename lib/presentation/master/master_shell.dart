import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/platform_features.dart';
import '../workshop/shop_parts_hub_screen.dart';
import '../widgets/ios_section_switcher.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

String _partsLangCode(AppLang lang) => lang.code;

class MasterShell extends ConsumerWidget {
  const MasterShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final tab = ref.watch(masterTabProvider);

    return Scaffold(
      extendBody: true,
      body: IosSectionSwitcher(
        index: tab,
        direction: ref.watch(sectionSlideDirProvider),
        onDirectionConsumed: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(sectionSlideDirProvider) != 0) {
              ref.read(sectionSlideDirProvider.notifier).state = 0;
            }
          });
        },
        children: const [
          MasterJobsScreen(),
          ShopPartsHubScreen(),
          MasterCabinetScreen(),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: tab,
        backgroundColor: palette.surface.withValues(alpha: kIsWeb ? 0.96 : 0.92),
        activeColor: palette.accent,
        inactiveColor: palette.muted,
        onTap: (i) {
          ref.read(sectionSlideDirProvider.notifier).state = 0;
          ref.read(masterTabProvider.notifier).state = i;
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.wrench),
            activeIcon: const Icon(CupertinoIcons.wrench_fill),
            label: s.masterTabJobs,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.cube_box),
            activeIcon: const Icon(CupertinoIcons.cube_box_fill),
            label: s.masterTabParts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person),
            activeIcon: const Icon(CupertinoIcons.person_fill),
            label: s.masterTabMe,
          ),
        ],
      ),
    );
  }
}

class MasterJobsScreen extends ConsumerWidget {
  const MasterJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final session = ref.watch(authProvider);
    final jobs = [
      for (final order in ref.watch(ordersProvider))
        if (order.status != JobStatus.cancelled &&
            (order.masterId == null ||
                order.masterId == session?.login ||
                order.status == JobStatus.inProgress ||
                order.status == JobStatus.created))
          order,
    ].take(40).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.masterTabJobs),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(
              s.masterPartsLead,
              style: TextStyle(color: palette.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            if (jobs.isEmpty)
              Text('—', style: TextStyle(color: palette.muted))
            else
              for (final order in jobs)
                Card(
                  child: ListTile(
                    title: Text('${order.brand} ${order.model} · ${order.plate}'),
                    subtitle: Text(
                      'VIN ${order.vin.isEmpty ? '—' : order.vin}\n'
                      '${order.lines.map((l) => l.title.uk).take(2).join(' · ')}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: s.masterPartsTitle,
                          icon: const Icon(CupertinoIcons.cube_box),
                          onPressed: () {
                            ref.read(masterTabProvider.notifier).state =
                                MasterTabs.parts;
                            ref.read(masterPartsPrefillProvider.notifier).state =
                                MasterPartsPrefill(
                              vin: order.vin,
                              carLabel: '${order.brand} ${order.model}',
                              orderId: order.id,
                            );
                          },
                        ),
                        IconButton(
                          tooltip: s.liveEstimateTitle,
                          icon: const Icon(CupertinoIcons.doc_text),
                          onPressed: () =>
                              context.push('/master/orders/${order.id}'),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/master/orders/${order.id}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class MasterPartsPrefill {
  const MasterPartsPrefill({
    this.vin = '',
    this.carLabel = '',
    this.orderId = '',
  });

  final String vin;
  final String carLabel;
  final String orderId;
}

final masterPartsPrefillProvider =
    StateProvider<MasterPartsPrefill>((ref) => const MasterPartsPrefill());

class MasterPartsScreen extends ConsumerStatefulWidget {
  const MasterPartsScreen({super.key});

  @override
  ConsumerState<MasterPartsScreen> createState() => _MasterPartsScreenState();
}

class _MasterPartsScreenState extends ConsumerState<MasterPartsScreen> {
  late final TextEditingController _body;
  late final TextEditingController _query;
  PartsCatalogHint? _picked;

  @override
  void initState() {
    super.initState();
    final pre = ref.read(masterPartsPrefillProvider);
    _body = TextEditingController(text: pre.vin);
    _query = TextEditingController();
  }

  @override
  void dispose() {
    _body.dispose();
    _query.dispose();
    super.dispose();
  }

  void _submit() {
    final session = ref.read(authProvider);
    final s = ref.read(stringsProvider);
    if (session == null || _picked == null) {
      return;
    }
    final pre = ref.read(masterPartsPrefillProvider);
    final vin = normalizeVin(_body.text.isEmpty ? pre.vin : _body.text);
    final lang = _partsLangCode(ref.read(localeProvider));
    ref.read(partsRequestsProvider.notifier).upsert(
          PartsRequest(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            masterId: session.login,
            masterName: session.displayName,
            partName: _picked!.title(lang),
            createdAt: DateTime.now(),
            orderId: pre.orderId,
            vin: vin,
            carLabel: pre.carLabel.isEmpty ? vin : pre.carLabel,
            query: _query.text.trim(),
            status: PartsRequestStatus.pendingShop,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.masterPartsPending)),
    );
    setState(() {
      _picked = null;
      _query.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MasterPartsPrefill>(masterPartsPrefillProvider, (prev, next) {
      if (next.vin.isNotEmpty && next.vin != _body.text) {
        _body.text = next.vin;
      }
    });
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final lang = _partsLangCode(ref.watch(localeProvider));
    final session = ref.watch(authProvider);
    final mine = [
      for (final r in ref.watch(partsRequestsProvider))
        if (r.masterId == session?.login) r,
    ];
    final hints = suggestParts(_query.text);

    return Scaffold(
      appBar: AppBar(title: Text(s.masterTabParts)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(s.masterPartsLead, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'VIN / body number',
                prefixIcon: Icon(CupertinoIcons.number),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() => _picked = null),
              decoration: InputDecoration(
                labelText: s.masterPartsTitle,
                hintText: 'шрус, шаровая, программатор…',
                prefixIcon: const Icon(CupertinoIcons.search),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hint in hints)
                  ChoiceChip(
                    label: Text(hint.title(lang)),
                    selected: _picked?.id == hint.id,
                    onSelected: (_) => setState(() => _picked = hint),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _picked == null ? null : _submit,
              icon: const Icon(CupertinoIcons.cube_box),
              label: Text(s.masterPartsSend),
            ),
            const SizedBox(height: 22),
            Text(s.masterTabParts, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final r in mine)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.partName),
                subtitle: Text(
                  '${r.carLabel} · ${r.vin.isEmpty ? '—' : r.vin}\n'
                  '${r.status.name} · ${DateFormat('dd.MM HH:mm').format(r.createdAt)}',
                ),
                isThreeLine: true,
                trailing: r.status == PartsRequestStatus.ready
                    ? TextButton(
                        onPressed: () {
                          ref.read(partsRequestsProvider.notifier).setStatus(
                                r.id,
                                PartsRequestStatus.received,
                              );
                        },
                        child: Text(s.masterPartsReceive),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class MasterCabinetScreen extends ConsumerWidget {
  const MasterCabinetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final session = ref.watch(authProvider);
    final palette = paletteOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.masterTabMe)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(
              session?.displayName ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(session?.login ?? '', style: TextStyle(color: palette.muted)),
            const SizedBox(height: 8),
            Text(s.shopRoleMasterHint, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(CupertinoIcons.gift_fill, color: palette.accent),
              title: Text(s.referralTitle),
              subtitle: Text(s.referralProfileSubtitle),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
              onTap: () => context.push('/referral'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
                context.go('/');
              },
              child: Text(s.logout),
            ),
          ],
        ),
      ),
    );
  }
}
