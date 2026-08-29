import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../auth/post_login_ai_screen.dart';
import '../auth/profile_screen.dart';
import '../widgets/ios_section_switcher.dart';
import 'categories_screen.dart';
import 'client_auction_screen.dart';
import 'client_help_screen.dart';
import 'client_open_jobs_screen.dart';
import 'feed_screen.dart';
import 'my_bookings_screen.dart';
import 'service_book_screen.dart';
import 'shop_catalog_screen.dart';
import 'usa_delivery_screen.dart';

class ClientShell extends ConsumerWidget {
  const ClientShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(clientTabProvider);
    final brandPicked = ref.watch(carBrandPickedProvider);

    return PopScope(
      canPop: tab == ClientTabs.car && !brandPicked,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (tab == ClientTabs.car && brandPicked) {
          ref.read(carBrandClearTickProvider.notifier).state++;
          return;
        }
        ref.read(sectionSlideDirProvider.notifier).state = -1;
        ref.read(clientTabProvider.notifier).state = ClientTabs.car;
      },
      child: IosSectionSwitcher(
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
          FeedScreen(),
          ShopCatalogScreen(),
          PostLoginAiScreen(inShell: true),
          CategoriesScreen(),
          ClientHelpScreen(),
          MyBookingsScreen(),
          ClientOpenJobsScreen(),
          ClientAuctionScreen(),
          ServiceBookScreen(),
          ProfileScreen(),
          UsaDeliveryScreen(),
        ],
      ),
    );
  }
}
