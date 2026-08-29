import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 860;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        leading: IconButton(
          onPressed: () {
            ref.read(authProvider.notifier).signOut();
            context.go('/');
          },
          icon: const Icon(Icons.logout),
          tooltip: s.logout,
        ),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            HeroPanel(
              icon: Icons.directions_car_filled,
              title: s.appTitle,
              subtitle: '${s.appSubtitle}\n${s.vpsReady}',
            ),
            const SizedBox(height: 24),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FeatureCard(
                      accent: true,
                      icon: Icons.tablet_mac,
                      title: s.clientKiosk,
                      subtitle: s.clientKioskHint,
                      onTap: () => context.push('/client-kiosk'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.touch_app,
                      title: s.kiosk,
                      subtitle: s.kioskHint,
                      onTap: () => context.push('/kiosk'),
                    ),
                  ),
                ],
              )
            else ...[
              FeatureCard(
                accent: true,
                icon: Icons.tablet_mac,
                title: s.clientKiosk,
                subtitle: s.clientKioskHint,
                onTap: () => context.push('/client-kiosk'),
              ),
              const SizedBox(height: 16),
              FeatureCard(
                icon: Icons.touch_app,
                title: s.kiosk,
                subtitle: s.kioskHint,
                onTap: () => context.push('/kiosk'),
              ),
            ],
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.precision_manufacturing,
                      title: s.workshop,
                      subtitle: s.workshopHint,
                      onTap: () => context.push('/workshop'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.star_rate,
                      title: s.ratings,
                      subtitle: s.ratingsHint,
                      onTap: () => context.push('/loyalty'),
                    ),
                  ),
                ],
              )
            else ...[
              FeatureCard(
                icon: Icons.precision_manufacturing,
                title: s.workshop,
                subtitle: s.workshopHint,
                onTap: () => context.push('/workshop'),
              ),
              const SizedBox(height: 16),
              FeatureCard(
                icon: Icons.star_rate,
                title: s.ratings,
                subtitle: s.ratingsHint,
                onTap: () => context.push('/loyalty'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
