import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/booking_extras.dart';
import '../../data/geo_location.dart';
import '../../data/open_link.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/platform_features.dart';
import '../../domain/models/shop_models.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'widgets/booking_bits.dart';

/// Client SOS / MAPA Help — only when they cannot reach a shop alone.
class ClientHelpScreen extends ConsumerStatefulWidget {
  const ClientHelpScreen({super.key});

  @override
  ConsumerState<ClientHelpScreen> createState() => _ClientHelpScreenState();
}

class _ClientHelpScreenState extends ConsumerState<ClientHelpScreen> {
  bool _stuck = false;
  bool _urgent = false;
  bool _evacuator = false;
  bool _night = false;
  bool _showList = false;
  double? _fromLat;
  double? _fromLng;

  bool get _eligible => _stuck || _urgent || _evacuator || _night;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    final point = await detectLocation();
    if (!mounted || !point.isOk) return;
    setState(() {
      _fromLat = point.lat;
      _fromLng = point.lng;
    });
  }

  List<ShopProfile> _helpShops() {
    final account = ref.read(shopAccountProvider);
    final banned = ref.read(mapaReportsProvider).bannedShopIds;
    var list = [
      for (final shop in allNetworkShops)
        if (!banned.contains(shop.id))
          if (shop.mapaHelp ||
              (shop.id == account.catalogShopId && account.mapaHelpActive))
            shop.id == account.catalogShopId && account.mapaHelpActive
                ? shop.copyWith(mapaHelp: true)
                : shop,
    ];
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    if (_fromLat != null && _fromLng != null) {
      list = [
        for (final shop in list)
          shop.copyWith(
            distanceKm: haversineKm(_fromLat!, _fromLng!, shop.lat, shop.lng),
          ),
      ];
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list.take(16).toList();
  }

  Future<void> _reportNoAnswer(ShopProfile shop) async {
    final s = ref.read(stringsProvider);
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.mapaReportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.mapaReportLead),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: InputDecoration(labelText: s.mapaReportNote),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.confirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1200,
    );
    final bytes = shot == null ? <int>[] : await shot.readAsBytes();
    final session = ref.read(authProvider);
    ref.read(mapaReportsProvider.notifier).add(
          MapaHelpReport(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            shopId: shop.id,
            shopName: shop.name.uk,
            clientLogin: session?.login ?? '',
            reason: note.text.trim().isEmpty
                ? 'No answer after 2 calls'
                : note.text.trim(),
            at: DateTime.now(),
            photoBytes: bytes,
          ),
        );
    final account = ref.read(shopAccountProvider);
    if (shop.id == account.catalogShopId && account.mapaHelpOptIn) {
      ref.read(shopAccountProvider.notifier).save(
            account.copyWith(mapaHelpPaused: true),
          );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.mapaReportDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final shops = _showList && _eligible ? _helpShops() : const <ShopProfile>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabHelp),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: shellListPadding(context, extra: 20),
          children: [
            Text(
              s.mapaClientTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(s.mapaClientLead, style: TextStyle(color: palette.muted, height: 1.4)),
            const SizedBox(height: 16),
            Text(s.mapaClientWhen, style: const TextStyle(fontWeight: FontWeight.w700)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _stuck,
              onChanged: (v) => setState(() => _stuck = v ?? false),
              title: Text(s.mapaCondStuck),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _urgent,
              onChanged: (v) => setState(() => _urgent = v ?? false),
              title: Text(s.mapaCondUrgent),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _evacuator,
              onChanged: (v) => setState(() => _evacuator = v ?? false),
              title: Text(s.mapaCondTow),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _night,
              onChanged: (v) => setState(() => _night = v ?? false),
              title: Text(s.mapaCondNight),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: !_eligible
                  ? null
                  : () => setState(() => _showList = true),
              icon: const Icon(CupertinoIcons.location_solid),
              label: Text(s.mapaFindHelp),
            ),
            if (!_eligible)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.mapaNeedCondition,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ),
            if (_showList && _eligible) ...[
              const SizedBox(height: 20),
              Text(s.mapaHelpListTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (shops.isEmpty)
                Text(s.mapaHelpEmpty, style: TextStyle(color: palette.muted))
              else
                for (final shop in shops)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShopCoverBanner(shopId: shop.id, height: 110),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name.of(lang),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Color(0xFFFFD60A),
                              ),
                            ],
                          ),
                          Text(shop.address.of(lang), style: TextStyle(color: palette.muted)),
                          Text(
                            '${shop.distanceKm.toStringAsFixed(1)} ${s.kmAway}',
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              StarRow(value: shop.rating, count: shop.reviewCount, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                shop.rating >= 4.8
                                    ? s.mapaHelpGradeTop
                                    : shop.rating >= 4.6
                                        ? s.mapaHelpGradePro
                                        : s.mapaHelpGradeBase,
                                style: TextStyle(
                                  color: palette.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Text(shop.phone),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: FilledButton.icon(
                              onPressed: () => openLink(telUrl(shop.phone)),
                              icon: const Icon(CupertinoIcons.phone_fill, size: 16),
                              label: Text(s.callShop),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => _reportNoAnswer(shop),
                              child: Text(
                                s.mapaReportCta,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
