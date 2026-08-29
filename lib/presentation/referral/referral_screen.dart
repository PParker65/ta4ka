import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../domain/models/referral.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/mono_image.dart';
import '../widgets/ui.dart';

/// Personal referral cabinet — 3 levels · 3% lifelong · payouts.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authProvider);
      if (session == null) return;
      ref.read(referralHubProvider.notifier).ensureAccount(
            login: session.login,
            displayName: session.displayName,
          );
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final session = ref.watch(authProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.referralTitle)),
        body: Center(child: Text(s.signIn)),
      );
    }
    ref.watch(referralHubProvider);
    final account = ref.read(referralHubProvider.notifier).ensureAccount(
          login: session.login,
          displayName: session.displayName,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.referralTitle),
        actions: const [AppBarTools()],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: s.referralTabCabinet),
            Tab(text: s.referralTabTerms),
            Tab(text: s.referralTabConnect),
            Tab(text: s.referralTabAdmin),
          ],
        ),
      ),
      body: ScreenCanvas(
        child: TabBarView(
          controller: _tabs,
          children: [
            _CabinetTab(account: account),
            _TermsTab(),
            _ConnectTab(login: session.login),
            _AdminTab(account: account),
          ],
        ),
      ),
    );
  }
}

class _CabinetTab extends ConsumerStatefulWidget {
  const _CabinetTab({required this.account});

  final ReferralAccount account;

  @override
  ConsumerState<_CabinetTab> createState() => _CabinetTabState();
}

class _CabinetTabState extends ConsumerState<_CabinetTab> {
  late final TextEditingController _fullName;
  late final TextEditingController _iban;
  late final TextEditingController _phone;
  late final TextEditingController _extra;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.account.fullName);
    _iban = TextEditingController(text: widget.account.iban);
    _phone = TextEditingController(text: widget.account.phone);
    _extra = TextEditingController(text: widget.account.payoutRequisites);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _iban.dispose();
    _phone.dispose();
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final account = widget.account;

    return ListView(
      padding: shellListPadding(context, extra: 20),
      children: [
        Text(s.referralCabinetLead, style: TextStyle(color: palette.muted, height: 1.4)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.accent.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.referralYourCode, style: TextStyle(color: palette.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.inviteCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: account.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.referralCodeCopied)),
                      );
                    },
                    icon: const Icon(CupertinoIcons.doc_on_doc),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _Stat(label: s.referralStatShops, value: '${account.shopsBrought}')),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: s.referralStatTurnover,
                value: formatUah(account.monthShopTurnoverUah),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: s.referralStatEarned,
                value: formatUah(account.monthEarnedUah),
                accent: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: s.referralStatLevels,
                value: 'L1 ${account.level1Count} · L2 ${account.level2Count} · L3 ${account.level3Count}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(s.referralPayoutTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 6),
        Text(s.referralPayoutLead, style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35)),
        const SizedBox(height: 10),
        TextField(controller: _fullName, decoration: InputDecoration(labelText: s.referralFullName)),
        TextField(controller: _iban, decoration: InputDecoration(labelText: s.referralIban)),
        TextField(controller: _phone, decoration: InputDecoration(labelText: s.referralPhone)),
        TextField(
          controller: _extra,
          maxLines: 2,
          decoration: InputDecoration(labelText: s.referralRequisitesExtra),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            ref.read(referralHubProvider.notifier).saveRequisites(
                  login: account.ownerLogin,
                  fullName: _fullName.text.trim(),
                  iban: _iban.text.trim(),
                  phone: _phone.text.trim(),
                  payoutRequisites: _extra.text.trim(),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.referralRequisitesSaved)),
            );
          },
          child: Text(s.referralSaveRequisites),
        ),
        const SizedBox(height: 22),
        Text(s.referralMyShops, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 8),
        if (account.shops.isEmpty)
          Text(s.referralNoShops, style: TextStyle(color: palette.muted))
        else
          for (final shop in account.shops) _ShopCard(shop: shop),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final green = palette.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent ? green.withValues(alpha: 0.12) : palette.carbon.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent ? green.withValues(alpha: 0.5) : palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: accent ? green : palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends ConsumerWidget {
  const _ShopCard({required this.shop});

  final ReferralShopLink shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final statusLabel = switch (shop.status) {
      ReferralShopStatus.approved => s.referralStatusApproved,
      ReferralShopStatus.pending => s.referralStatusPending,
      ReferralShopStatus.rejected => s.referralStatusRejected,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: shop.photoUrl.isEmpty
                ? Container(
                    width: 72,
                    height: 56,
                    color: palette.carbon,
                    child: const Icon(CupertinoIcons.building_2_fill),
                  )
                : AppNetworkImage(url: 
                    shop.photoUrl,
                    width: 72,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 56,
                      color: palette.carbon,
                      child: const Icon(CupertinoIcons.building_2_fill),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${shop.city} · L${shop.level} · ${(shop.rate * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: palette.muted, fontSize: 12)),
                Text(statusLabel, style: TextStyle(color: palette.muted, fontSize: 12)),
                if (shop.status == ReferralShopStatus.approved)
                  Text(
                    '${s.referralMonthEarn}: ${formatUah(shop.monthEarnedUah)} '
                    '(${s.referralFromTurnover} ${formatUah(shop.monthTurnoverUah)})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final steps = [
      s.referralTerm1,
      s.referralTerm2,
      s.referralTerm3,
      s.referralTerm4,
      s.referralTerm5,
      s.referralTerm6,
      s.referralTerm7,
      s.referralTerm8,
    ];
    return ListView(
      padding: shellListPadding(context, extra: 20),
      children: [
        Text(s.referralTermsTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text(s.referralTermsLead, style: TextStyle(color: palette.muted, height: 1.4)),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(steps[i], style: const TextStyle(height: 1.4))),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
          ),
          child: Text(
            s.referralLevelsExplain,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ConnectTab extends ConsumerStatefulWidget {
  const _ConnectTab({required this.login});

  final String login;

  @override
  ConsumerState<_ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends ConsumerState<_ConnectTab> {
  final _shop = TextEditingController();
  final _city = TextEditingController(text: 'Warsaw');
  final _manager = TextEditingController();
  final _photo = TextEditingController(
    text: 'https://picsum.photos/seed/ref-new/900/560',
  );
  final _note = TextEditingController();

  @override
  void dispose() {
    _shop.dispose();
    _city.dispose();
    _manager.dispose();
    _photo.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    return ListView(
      padding: shellListPadding(context, extra: 20),
      children: [
        Text(s.referralConnectTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text(s.referralConnectLead, style: TextStyle(color: palette.muted, height: 1.4)),
        const SizedBox(height: 12),
        TextField(controller: _shop, decoration: InputDecoration(labelText: s.referralShopName)),
        TextField(controller: _city, decoration: InputDecoration(labelText: s.referralShopCity)),
        TextField(controller: _manager, decoration: InputDecoration(labelText: s.referralManager)),
        TextField(controller: _photo, decoration: InputDecoration(labelText: s.referralPhotoLink)),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: InputDecoration(labelText: s.referralConnectNote),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            if (_shop.text.trim().isEmpty || _manager.text.trim().isEmpty) {
              return;
            }
            ref.read(referralHubProvider.notifier).submitShop(
                  login: widget.login,
                  shopName: _shop.text,
                  city: _city.text,
                  managerName: _manager.text,
                  photoUrl: _photo.text,
                  note: _note.text,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.referralSubmitted)),
            );
            _shop.clear();
            _manager.clear();
            _note.clear();
          },
          icon: const Icon(CupertinoIcons.camera_fill),
          label: Text(s.referralSubmitShop),
        ),
      ],
    );
  }
}

class _AdminTab extends ConsumerWidget {
  const _AdminTab({required this.account});

  final ReferralAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final pending = account.pending;
    final approved = account.approved;
    return ListView(
      padding: shellListPadding(context, extra: 20),
      children: [
        Text(s.referralAdminTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text(s.referralAdminLead, style: TextStyle(color: palette.muted, height: 1.4)),
        const SizedBox(height: 14),
        Text(s.referralPendingTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          Text(s.referralPendingEmpty, style: TextStyle(color: palette.muted))
        else
          for (final shop in pending)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${shop.city} · ${shop.managerName}', style: TextStyle(color: palette.muted)),
                  if (shop.note.isNotEmpty) Text(shop.note, style: TextStyle(color: palette.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => ref.read(referralHubProvider.notifier).setShopStatus(
                                login: account.ownerLogin,
                                shopId: shop.id,
                                status: ReferralShopStatus.approved,
                              ),
                          child: Text(s.referralApprove),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(referralHubProvider.notifier).setShopStatus(
                                login: account.ownerLogin,
                                shopId: shop.id,
                                status: ReferralShopStatus.rejected,
                              ),
                          child: Text(s.referralReject),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        const SizedBox(height: 16),
        Text(s.referralNetworkTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          s.referralNetworkStats(
            approved.length,
            formatUah(account.monthShopTurnoverUah),
            formatUah(account.monthEarnedUah),
          ),
          style: TextStyle(color: palette.muted, height: 1.4),
        ),
      ],
    );
  }
}

/// Compact floating CTA for the car home screen.
class ReferralHomeChip extends ConsumerWidget {
  const ReferralHomeChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    return Material(
      color: palette.accent,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: () => context.push('/referral'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                s.referralHomeCta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
