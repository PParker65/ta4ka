import 'package:go_router/go_router.dart';

import '../presentation/storage/storage_desk_screen.dart';
import 'page_transitions.dart';

/// Storage-only routes for kolesasave.com — no teaser, CRM desk, or feed.
final storageAppRouter = GoRouter(
  initialLocation: '/storage',
  errorBuilder: (context, state) => const StorageDeskScreen(),
  redirect: (context, state) {
    if (state.uri.path == '/storage') return null;
    return '/storage';
  },
  routes: [
    GoRoute(
      path: '/storage',
      pageBuilder: (context, state) =>
          iosPage(state, const StorageDeskScreen()),
    ),
  ],
);
