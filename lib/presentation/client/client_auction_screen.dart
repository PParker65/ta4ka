import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/platform_features.dart';
import '../widgets/mono_image.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

/// Client auction — Copart-style lots with photos, bid + Buy Now.
class ClientAuctionScreen extends ConsumerStatefulWidget {
  const ClientAuctionScreen({super.key});

  @override
  ConsumerState<ClientAuctionScreen> createState() => _ClientAuctionScreenState();
}

class _ClientAuctionScreenState extends ConsumerState<ClientAuctionScreen> {
  Timer? _tick;
  Timer? _bots;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _bots = Timer.periodic(const Duration(seconds: 18), (_) {
      final live = [
        for (final a in ref.read(auctionsProvider))
          if (a.isLive) a,
      ];
      if (live.isEmpty) return;
      live.shuffle();
      ref.read(auctionsProvider.notifier).placeBotBid(live.first.id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(auctionDraftProvider);
      if (draft == null) return;
      ref.read(auctionDraftProvider.notifier).state = null;
      WorkOrder? order;
      for (final o in ref.read(ordersProvider)) {
        if (o.id == draft.orderId) {
          order = o;
          break;
        }
      }
      _createLot(fromOrder: order, estimateUah: draft.estimateUah);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _bots?.cancel();
    super.dispose();
  }

  Future<void> _createLot({WorkOrder? fromOrder, int estimateUah = 0}) async {
    final session = ref.read(authProvider);
    if (session == null) return;
    final s = ref.read(stringsProvider);
    final brand = TextEditingController(text: fromOrder?.brand ?? '');
    final model = TextEditingController(text: fromOrder?.model ?? '');
    final details = TextEditingController(
      text: fromOrder == null
          ? ''
          : s.auctionPrefillDetails(formatUah(estimateUah)),
    );
    final damage = TextEditingController();
    final reason = TextEditingController();
    final mileage = TextEditingController();
    final buyNow = TextEditingController();
    final plate = TextEditingController(text: fromOrder?.plate ?? '');
    DateTime starts = DateTime.now().add(const Duration(minutes: 5));
    DateTime ends = starts.add(const Duration(hours: 2));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.auctionCreateTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 10),
                    TextField(controller: brand, decoration: InputDecoration(labelText: s.brand)),
                    TextField(controller: model, decoration: InputDecoration(labelText: s.model)),
                    TextField(controller: plate, decoration: InputDecoration(labelText: s.plate)),
                    TextField(
                      controller: mileage,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.auctionMileage),
                    ),
                    TextField(controller: damage, decoration: InputDecoration(labelText: s.auctionDamage)),
                    TextField(controller: reason, decoration: InputDecoration(labelText: s.auctionSellReason)),
                    TextField(controller: details, maxLines: 3, decoration: InputDecoration(labelText: s.auctionFieldDetails)),
                    TextField(
                      controller: buyNow,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.auctionBuyNowPrice),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          initialDate: starts,
                        );
                        if (d == null) return;
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(starts),
                        );
                        setModal(() {
                          starts = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t?.hour ?? starts.hour,
                            t?.minute ?? starts.minute,
                          );
                          ends = starts.add(const Duration(hours: 2));
                        });
                      },
                      icon: const Icon(CupertinoIcons.calendar),
                      label: Text(
                        '${s.auctionStartsAt}: ${DateFormat('dd.MM HH:mm').format(starts)}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.auctionStart),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (ok != true || brand.text.trim().isEmpty || model.text.trim().isEmpty) {
      return;
    }
    final now = DateTime.now();
    final b = brand.text.trim();
    final m = model.text.trim();
    final seed = '${b.toLowerCase()}-$m-${now.millisecondsSinceEpoch}';
    ref.read(auctionsProvider.notifier).upsert(
          VehicleAuction(
            id: 'auc-${now.millisecondsSinceEpoch}',
            ownerLogin: session.login,
            ownerLabel: session.displayName.isEmpty ? session.login : session.displayName,
            title: '$b $m',
            details: details.text.trim().isEmpty
                ? s.auctionFieldDetails
                : details.text.trim(),
            damage: damage.text.trim(),
            sellReason: reason.text.trim(),
            mileageKm: int.tryParse(mileage.text.trim()) ?? 0,
            buyNowUah: int.tryParse(buyNow.text.trim()) ?? 0,
            createdAt: now,
            startsAt: starts,
            endsAt: ends.isAfter(starts) ? ends : starts.add(const Duration(hours: 2)),
            plate: plate.text.trim(),
            brand: b,
            model: m,
            estimateUah: estimateUah,
            shopId: fromOrder?.shopId ?? '',
            orderId: fromOrder?.id ?? '',
            photoUrls: [
              for (var i = 1; i <= 3; i++)
                'https://picsum.photos/seed/$seed-$i/900/560',
            ],
          ),
        );
  }

  void _openLot(VehicleAuction auction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final topGap = media.padding.top + kToolbarHeight;
        return Padding(
          padding: EdgeInsets.only(top: topGap),
          child: SizedBox(
            height: media.size.height - topGap,
            child: _AuctionDetailSheet(auctionId: auction.id),
          ),
        );
      },
    );
  }

  String _timer(VehicleAuction a) {
    final now = DateTime.now();
    if (a.isScheduled) {
      final left = a.startsAt.difference(now);
      return '⏳ ${left.inHours}h ${left.inMinutes.remainder(60)}m';
    }
    if (!a.isLive) return a.status.name;
    final left = a.endsAt.difference(now);
    if (left.isNegative) return '—';
    return '${left.inHours}h ${left.inMinutes.remainder(60)}m ${left.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final session = ref.watch(authProvider);
    final all = ref.watch(auctionsProvider);
    final live = [for (final a in all) if (a.isLive || a.isScheduled) a];
    final mine = [
      for (final a in all)
        if (session != null && a.ownerLogin == session.login) a,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabAuction),
        centerTitle: false,
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context, extra: 20),
          children: [
            Text(s.auctionHeroTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text(s.auctionHeroLead, style: TextStyle(color: palette.muted, height: 1.4, fontSize: 13)),
            const SizedBox(height: 8),
            Text(s.auctionSoftCloseHint, style: TextStyle(color: palette.muted, fontSize: 12, height: 1.35)),
            const SizedBox(height: 16),
            Text(s.auctionLiveTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (live.isEmpty)
              Text(s.auctionLiveEmpty, style: TextStyle(color: palette.muted))
            else
              for (final a in live)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LotCard(
                    auction: a,
                    timer: _timer(a),
                    onTap: () => _openLot(a),
                  ),
                ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.auctionMyTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final a in mine)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: a.photoUrls.isEmpty
                      ? const Icon(CupertinoIcons.car_detailed)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            url: a.photoUrls.first,
                            width: 56,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.car_detailed),
                          ),
                        ),
                  title: Text(a.title),
                  subtitle: Text(_timer(a)),
                  onTap: () => _openLot(a),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LotCard extends ConsumerWidget {
  const _LotCard({
    required this.auction,
    required this.timer,
    required this.onTap,
  });

  final VehicleAuction auction;
  final String timer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final a = auction;
    final photos = a.photoUrls;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: a.isLive ? palette.accent : palette.stroke,
              width: a.isLive ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photos.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: SizedBox(
                    height: 168,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 2),
                      itemBuilder: (_, i) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: AppNetworkImage(
                          url: photos[i],
                          width: photos.length == 1 ? MediaQuery.sizeOf(context).width - 42 : 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 220,
                            color: palette.carbon,
                            alignment: Alignment.center,
                            child: const Icon(CupertinoIcons.car_detailed, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        Text(timer, style: TextStyle(color: palette.muted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (a.year.isNotEmpty) a.year,
                        if (a.mileageKm > 0) '${NumberFormat.decimalPattern().format(a.mileageKm)} km',
                        if (photos.isNotEmpty) '${photos.length} foto',
                      ].join(' · '),
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                    if (a.damage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(a.damage, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.muted, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      a.topBid == null
                          ? s.auctionNoBids
                          : s.auctionTopBid(a.topBid!.buyerName, formatUah(a.topBid!.amountUah)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (a.buyNowUah > 0)
                      Text(
                        '${s.auctionBuyNow}: ${formatUah(a.buyNowUah)}',
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(CupertinoIcons.money_dollar_circle, size: 18),
                        label: Text(a.isLive ? s.auctionPlaceBid : s.auctionOpenLot),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuctionDetailSheet extends ConsumerStatefulWidget {
  const _AuctionDetailSheet({required this.auctionId});

  final String auctionId;

  @override
  ConsumerState<_AuctionDetailSheet> createState() => _AuctionDetailSheetState();
}

class _AuctionDetailSheetState extends ConsumerState<_AuctionDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _amount = TextEditingController();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _ensureAmount(VehicleAuction a) {
    if (_amount.text.isNotEmpty) return;
    final top = a.topBid?.amountUah ?? 50000;
    _amount.text = '${top + 2000}';
  }

  void _placeBid(VehicleAuction a) {
    final session = ref.read(authProvider);
    if (session == null || !a.isLive) return;
    final uah = int.tryParse(_amount.text.trim()) ?? 0;
    if (uah <= 0) return;
    ref.read(auctionsProvider.notifier).addBid(
          a.id,
          AuctionBid(
            id: '${session.login}-${DateTime.now().millisecondsSinceEpoch}',
            buyerId: session.login,
            buyerName: session.displayName.isEmpty ? session.login : session.displayName,
            amountUah: uah,
            at: DateTime.now(),
          ),
        );
    _tabs.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${ref.read(stringsProvider).auctionPlaceBid}: ${formatUah(uah)}')),
    );
  }

  void _buyNow(VehicleAuction a) {
    final session = ref.read(authProvider);
    if (session == null || !a.hasBuyNow) return;
    ref.read(auctionsProvider.notifier).buyNow(
          a.id,
          AuctionBid(
            id: 'bn-${session.login}-${DateTime.now().millisecondsSinceEpoch}',
            buyerId: session.login,
            buyerName: session.displayName.isEmpty ? session.login : session.displayName,
            amountUah: a.buyNowUah,
            at: DateTime.now(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final session = ref.watch(authProvider);
    VehicleAuction? auction;
    for (final a in ref.watch(auctionsProvider)) {
      if (a.id == widget.auctionId) auction = a;
    }
    if (auction == null) {
      return Material(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: const Center(child: Text('—')),
      );
    }
    final a = auction;
    _ensureAmount(a);
    final top = a.topBid;
    final bids = [...a.bids]..sort((x, y) => y.amountUah.compareTo(x.amountUah));
    final participants = <String, AuctionBid>{};
    for (final b in bids) {
      participants.putIfAbsent(b.buyerId, () => b);
    }

    return Material(
      color: palette.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: palette.stroke, borderRadius: BorderRadius.circular(99)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: palette.accent,
            unselectedLabelColor: palette.muted,
            indicatorColor: palette.accent,
            tabs: [
              Tab(text: s.auctionTabLot),
              Tab(text: '${s.auctionTabParticipants} (${participants.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    if (a.photoUrls.isNotEmpty)
                      SizedBox(
                        height: 210,
                        child: PageView.builder(
                          itemCount: a.photoUrls.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AppNetworkImage(
                                url: a.photoUrls[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: palette.carbon,
                                  alignment: Alignment.center,
                                  child: const Icon(CupertinoIcons.car_detailed, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (a.photoUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Text(
                          '${a.photoUrls.length} ${s.auctionPhotosHint}',
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (a.year.isNotEmpty) _Chip(label: a.year),
                        if (a.mileageKm > 0)
                          _Chip(label: '${NumberFormat.decimalPattern().format(a.mileageKm)} km'),
                        if (a.isLive) const _Chip(label: 'LIVE', green: true),
                        if (a.isScheduled) _Chip(label: s.auctionStartsAt),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(s.auctionFieldDetails, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(a.details, style: TextStyle(color: palette.muted, height: 1.4)),
                    if (a.damage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(s.auctionDamage, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(a.damage, style: TextStyle(color: palette.muted, height: 1.35)),
                    ],
                    if (a.sellReason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(s.auctionSellReason, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(a.sellReason, style: TextStyle(color: palette.muted, height: 1.35)),
                    ],
                    const SizedBox(height: 10),
                    Text('${s.auctionStartsAt}: ${DateFormat('dd.MM.yyyy HH:mm').format(a.startsAt)}'),
                    Text('${s.auctionEndsAt}: ${DateFormat('dd.MM.yyyy HH:mm').format(a.endsAt)}'),
                    const SizedBox(height: 12),
                    Text(
                      top == null
                          ? s.auctionNoBids
                          : s.auctionTopBid(top.buyerName, formatUah(top.amountUah)),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                    if (a.isScheduled)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(s.auctionNotStarted, style: TextStyle(color: palette.muted)),
                      ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    if (bids.isEmpty)
                      Text(s.auctionNoBids, style: TextStyle(color: palette.muted))
                    else
                      for (var i = 0; i < bids.length; i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: i == 0
                                ? palette.accent.withValues(alpha: 0.2)
                                : palette.carbon,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: i == 0 ? palette.accent : palette.text,
                              ),
                            ),
                          ),
                          title: Text(bids[i].buyerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(DateFormat('dd.MM HH:mm:ss').format(bids[i].at)),
                          trailing: Text(
                            formatUah(bids[i].amountUah),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: i == 0 ? palette.accent : palette.text,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.stroke)),
              ),
              child: session == null
                  ? Text(s.auctionLoginToBid, textAlign: TextAlign.center, style: TextStyle(color: palette.muted))
                  : !a.isLive
                      ? Text(s.auctionNotStarted, textAlign: TextAlign.center, style: TextStyle(color: palette.muted))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _amount,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: s.auctionBidAmount),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _placeBid(a),
                                    child: Text(s.auctionPlaceBid),
                                  ),
                                ),
                                if (a.hasBuyNow) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: palette.accent),
                                      onPressed: () => _buyNow(a),
                                      child: Text(
                                        '${s.auctionBuyNow}\n${formatUah(a.buyNowUah)}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(height: 1.15, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (a.ownerLogin == session.login && top != null)
                              TextButton(
                                onPressed: () {
                                  ref.read(auctionsProvider.notifier).acceptTop(a.id);
                                  Navigator.pop(context);
                                },
                                child: Text(s.auctionAccept),
                              ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.green = false});

  final String label;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final color = green ? paletteOf(context).accent : paletteOf(context).muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

/// Shop side: bid as flipper on live auctions.
class ShopAuctionPanel extends ConsumerWidget {
  const ShopAuctionPanel({super.key});

  Future<void> _bid(BuildContext context, WidgetRef ref, VehicleAuction auction) async {
    final account = ref.read(shopAccountProvider);
    final s = ref.read(stringsProvider);
    final palette = paletteOf(context);
    final amount = TextEditingController(
      text: '${(auction.topBid?.amountUah ?? 0) + 1000}',
    );
    final note = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(auction.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: s.auctionBidAmount),
              ),
              TextField(controller: note, decoration: InputDecoration(labelText: s.auctionBidNote)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.auctionPlaceBid),
              ),
              if (auction.hasBuyNow) ...[
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: palette.accent),
                  onPressed: () {
                    Navigator.pop(ctx, false);
                    ref.read(auctionsProvider.notifier).buyNow(
                          auction.id,
                          AuctionBid(
                            id: 'bn-${account.catalogShopId}-${DateTime.now().millisecondsSinceEpoch}',
                            buyerId: account.catalogShopId.isEmpty ? 'local-shop' : account.catalogShopId,
                            buyerName: account.shopName.isEmpty ? 'Shop' : account.shopName,
                            amountUah: auction.buyNowUah,
                            at: DateTime.now(),
                          ),
                        );
                  },
                  child: Text('${s.auctionBuyNow} · ${formatUah(auction.buyNowUah)}'),
                ),
              ],
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    final uah = int.tryParse(amount.text.trim()) ?? 0;
    if (uah <= 0) return;
    ref.read(auctionsProvider.notifier).addBid(
          auction.id,
          AuctionBid(
            id: '${account.catalogShopId}-${DateTime.now().millisecondsSinceEpoch}',
            buyerId: account.catalogShopId.isEmpty ? 'local-shop' : account.catalogShopId,
            buyerName: account.shopName.isEmpty ? 'Shop' : account.shopName,
            amountUah: uah,
            at: DateTime.now(),
            note: note.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final live = [
      for (final a in ref.watch(auctionsProvider))
        if (a.isLive) a,
    ];
    if (live.isEmpty) {
      return Text(s.auctionLiveEmpty, style: TextStyle(color: palette.muted));
    }
    return Column(
      children: [
        for (final a in live)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.photoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppNetworkImage(
                      url: a.photoUrls.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (a.photoUrls.isNotEmpty) const SizedBox(height: 8),
                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(a.details, style: TextStyle(color: palette.muted)),
                Text(
                  a.topBid == null
                      ? s.auctionNoBids
                      : s.auctionTopBid(a.topBid!.buyerName, formatUah(a.topBid!.amountUah)),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _bid(context, ref, a),
                  child: Text(s.auctionPlaceBid),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
