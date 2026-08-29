import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/auth/profile_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/auth/shop_auth_screen.dart';
import '../presentation/master/master_order_screen.dart';
import '../presentation/master/master_shell.dart';
import '../presentation/client/booking_detail_screen.dart';
import '../presentation/client/booking_summary_screen.dart';
import '../presentation/client/category_detail_screen.dart';
import '../presentation/client/client_business_screen.dart';
import '../presentation/client/client_shell.dart';
import '../presentation/referral/referral_screen.dart';
import '../presentation/client/shop_detail_screen.dart';
import '../presentation/client/shop_reviews_screen.dart';
import '../presentation/client/slot_picker_screen.dart';
import '../presentation/inspection/inspection_screen.dart';
import '../presentation/kiosk/client_intake_screen.dart';
import '../presentation/kiosk/client_kiosk_view.dart';
import '../presentation/kiosk/kiosk_screen.dart';
import '../presentation/loyalty/loyalty_screen.dart';
import '../presentation/workshop/shop_chat_only_screen.dart';
import '../presentation/workshop/shop_order_screen.dart';
import '../presentation/workshop/shop_platform_screens.dart';
import '../presentation/workshop/shop_parts_requests_screen.dart';
import '../presentation/workshop/shop_design_screen.dart';
import '../presentation/workshop/shop_shell.dart';
import '../presentation/workshop/shop_camera_screen.dart';
import '../presentation/workshop/shop_ops_screens.dart';
import '../presentation/workshop/shop_parts_hub_screen.dart';
import '../presentation/workshop/workshop_screen.dart';
import 'page_transitions.dart';
import '../presentation/client/widgets/client_skin_chrome.dart';
import '../presentation/client/widgets/user_guide_reel.dart';

final _shellNavKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/', pageBuilder: (context, state) => iosPage(state, const LoginScreen())),
    GoRoute(
      path: '/auth/register',
      pageBuilder: (context, state) => iosPage(state, const RegisterScreen()),
    ),
    GoRoute(
      path: '/auth/shop',
      pageBuilder: (context, state) => iosPage(state, const ShopRoleGateScreen()),
    ),
    GoRoute(
      path: '/auth/shop/manager',
      pageBuilder: (context, state) =>
          iosPage(state, const ShopAuthScreen(asMaster: false)),
    ),
    GoRoute(
      path: '/auth/shop/master',
      pageBuilder: (context, state) => iosPage(
        state,
        ShopAuthScreen(
          asMaster: true,
          asReception: state.uri.queryParameters['kind'] == 'reception',
        ),
      ),
    ),
    GoRoute(
      path: '/master',
      pageBuilder: (context, state) => iosPage(state, const MasterShell()),
      routes: [
        GoRoute(
          path: 'orders/:orderId',
          pageBuilder: (context, state) => iosPage(
            state,
            MasterOrderScreen(
              orderId: state.pathParameters['orderId'] ?? '',
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/auth/triage',
      redirect: (context, state) => '/home',
    ),

    GoRoute(
      path: '/home/guide',
      pageBuilder: (context, state) => iosPage(state, const UserGuideScreen()),
    ),
    ShellRoute(
      navigatorKey: _shellNavKey,
      builder: (context, state, child) => _ClientNavShell(child: child),
      routes: [
        GoRoute(path: '/home', pageBuilder: (context, state) => iosPage(state, const ClientShell())),
        GoRoute(
          path: '/home/categories/:sphereId',
          pageBuilder: (context, state) => iosPage(
            state,
            CategoryDetailScreen(sphereId: state.pathParameters['sphereId'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/home/bookings/:orderId',
          pageBuilder: (context, state) => iosPage(
            state,
            BookingDetailScreen(orderId: state.pathParameters['orderId'] ?? ''),
          ),
        ),
        GoRoute(
          path: '/home/profile',
          pageBuilder: (context, state) => iosPage(state, const ProfileScreen()),
        ),
        GoRoute(
          path: '/home/shops/:shopId/reviews',
          pageBuilder: (context, state) => iosPage(
            state,
            ShopReviewsScreen(
              shopId: Uri.decodeComponent(state.pathParameters['shopId'] ?? ''),
            ),
          ),
        ),
        GoRoute(
          path: '/home/shops/:shopId',
          pageBuilder: (context, state) => iosPage(
            state,
            ShopDetailScreen(
              shopId: Uri.decodeComponent(state.pathParameters['shopId'] ?? ''),
            ),
          ),
        ),
        GoRoute(
          path: '/home/slots',
          pageBuilder: (context, state) => iosPage(state, const SlotPickerScreen()),
        ),
        GoRoute(
          path: '/home/confirm',
          pageBuilder: (context, state) => iosPage(state, const BookingSummaryScreen()),
        ),
        GoRoute(
          path: '/home/business',
          pageBuilder: (context, state) => iosPage(state, const ClientBusinessScreen()),
        ),
        GoRoute(
          path: '/home/referral',
          pageBuilder: (context, state) => iosPage(state, const ReferralScreen()),
        ),
      ],
    ),

    GoRoute(
      path: '/referral',
      pageBuilder: (context, state) => iosPage(state, const ReferralScreen()),
    ),

    GoRoute(path: '/client', pageBuilder: (context, state) => iosPage(state, const ClientIntakeScreen())),
    ShellRoute(
      builder: (context, state, child) => ShopShell(child: child),
      routes: [
        GoRoute(
          path: '/staff',
          pageBuilder: (context, state) => iosPage(state, const ShopTabsHost()),
          routes: [
            GoRoute(
              path: 'chat/:orderId',
              pageBuilder: (context, state) => iosPage(
                state,
                ShopChatOnlyScreen(
                  orderId: state.pathParameters['orderId'] ?? '',
                  withMaster: state.uri.queryParameters['side'] == 'master',
                ),
              ),
            ),
            GoRoute(
              path: 'orders/:orderId',
              pageBuilder: (context, state) => iosPage(
                state,
                ShopOrderScreen(
                  orderId: state.pathParameters['orderId'] ?? '',
                  focusMasterChat: state.uri.queryParameters['tab'] == 'master',
                ),
              ),
            ),
            GoRoute(
              path: 'tax-report',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopTaxReportScreen()),
            ),
            GoRoute(
              path: 'vin-history',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopVinHistoryScreen()),
            ),
            GoRoute(
              path: 'blacklist',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopBlacklistScreen()),
            ),
            GoRoute(
              path: 'parts-requests',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopPartsRequestsScreen()),
            ),
            GoRoute(
              path: 'camera',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopCameraScreen()),
            ),
            GoRoute(
              path: 'ops/parts',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopPartsHubScreen()),
            ),
            GoRoute(
              path: 'ops/stock',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopStockScreen()),
            ),
            GoRoute(
              path: 'ops/checklist',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopChecklistScreen()),
            ),
            GoRoute(
              path: 'ops/bays',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopBaysScreen()),
            ),
            GoRoute(
              path: 'ops/kpi',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopKpiScreen()),
            ),
            GoRoute(
              path: 'ops/reminders',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopRemindersScreen()),
            ),
            GoRoute(
              path: 'design',
              pageBuilder: (context, state) =>
                  iosPage(state, const ShopDesignScreen()),
            ),
            GoRoute(
              path: 'referral',
              pageBuilder: (context, state) =>
                  iosPage(state, const ReferralScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/staff/tools', redirect: (context, state) => '/staff'),
    GoRoute(
      path: '/client-kiosk',
      pageBuilder: (context, state) => iosPage(state, const ClientKioskView()),
    ),
    GoRoute(
      path: '/client-kiosk/flow',
      pageBuilder: (context, state) => iosPage(state, const KioskScreen(clientMode: true)),
    ),
    GoRoute(
      path: '/client-kiosk/rate/:orderId',
      pageBuilder: (context, state) => iosPage(
        state,
        KioskRatingScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
    ),
    GoRoute(path: '/kiosk', pageBuilder: (context, state) => iosPage(state, const KioskScreen())),
    GoRoute(
      path: '/kiosk/inspection',
      pageBuilder: (context, state) => iosPage(state, const InspectionScreen()),
    ),
    GoRoute(
      path: '/workshop',
      pageBuilder: (context, state) => iosPage(state, const WorkshopScreen()),
    ),
    GoRoute(
      path: '/loyalty',
      pageBuilder: (context, state) => iosPage(state, const LoyaltyScreen()),
    ),
  ],
);

class _ClientNavShell extends ConsumerWidget {
  const _ClientNavShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClientSkinChrome(child: child);
  }
}
