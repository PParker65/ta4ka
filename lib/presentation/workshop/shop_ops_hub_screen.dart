import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class ShopOpsHubScreen extends ConsumerWidget {
  const ShopOpsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final reception = ref.watch(authProvider)?.isReceptionist == true;

    final tiles = <_OpsTile>[
      _OpsTile(
        icon: CupertinoIcons.search,
        title: s.opsPartsTitle,
        lead: s.opsPartsLead,
        path: '/staff/ops/parts',
      ),
      _OpsTile(
        icon: CupertinoIcons.checkmark_square,
        title: s.opsCheckTitle,
        lead: s.opsCheckLead,
        path: '/staff/ops/checklist',
      ),
      _OpsTile(
        icon: CupertinoIcons.square_grid_2x2,
        title: s.opsBaysTitle,
        lead: s.opsBaysLead,
        path: '/staff/ops/bays',
      ),
      _OpsTile(
        icon: CupertinoIcons.bell,
        title: s.opsRemindTitle,
        lead: s.opsRemindLead,
        path: '/staff/ops/reminders',
      ),
      _OpsTile(
        icon: CupertinoIcons.videocam,
        title: s.shopTabCamera,
        lead: s.bayCamera,
        path: '/staff/camera',
      ),
      if (!reception) ...[
        _OpsTile(
          icon: CupertinoIcons.cube_box,
          title: s.opsStockTitle,
          lead: s.opsStockLead,
          path: '/staff/ops/stock',
        ),
        _OpsTile(
          icon: CupertinoIcons.chart_bar,
          title: s.opsKpiTitle,
          lead: s.opsKpiLead,
          path: '/staff/ops/kpi',
        ),
        _OpsTile(
          icon: CupertinoIcons.cube_box_fill,
          title: s.shopPartsApprove,
          lead: s.opsRequestsLead,
          path: '/staff/parts-requests',
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.opsHubTitle),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
          children: [
            Text(
              reception ? s.opsHubLeadReception : s.opsHubLeadShop,
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            for (final tile in tiles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => context.push(tile.path),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Row(
                        children: [
                          Icon(tile.icon, color: palette.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tile.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tile.lead,
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_right, size: 16, color: palette.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpsTile {
  const _OpsTile({
    required this.icon,
    required this.title,
    required this.lead,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String lead;
  final String path;
}
