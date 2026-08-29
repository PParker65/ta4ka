import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'shop_chat_box.dart';

/// Chat-only staff screen — keeps ShopShell bottom nav visible.
class ShopChatOnlyScreen extends ConsumerWidget {
  const ShopChatOnlyScreen({
    super.key,
    required this.orderId,
    this.withMaster = false,
  });

  final String orderId;
  final bool withMaster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final orders = ref.watch(ordersProvider);
    final matches = [for (final o in orders) if (o.id == orderId) o];
    final order = matches.isEmpty ? null : matches.first;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(s.shopTabChat),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/staff'),
          ),
        ),
        body: const Center(child: Text('—')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${order.brand} ${order.model} · ${order.plate}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/staff');
            }
          },
        ),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
          children: [
            Text(
              withMaster ? s.shopChatMasters : s.shopChatClients,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10),
            ShopChatBox(order: order, withMaster: withMaster),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/staff/orders/${order.id}'),
              child: Text(s.shopOpenOrder),
            ),
          ],
        ),
      ),
    );
  }
}
