import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/live_cams.dart';
import '../../data/service_report.dart';
import '../client/widgets/bay_live_camera.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'shop_jobs.dart';
import 'webcam_preview.dart';

class ShopCameraScreen extends ConsumerStatefulWidget {
  const ShopCameraScreen({super.key});

  @override
  ConsumerState<ShopCameraScreen> createState() => _ShopCameraScreenState();
}

class _ShopCameraScreenState extends ConsumerState<ShopCameraScreen> {
  bool _busy = false;
  bool _usedDevice = false;
  LiveCam _cam = liveCamFor('pitlane');

  Future<void> _connect() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final ok = await attachShopWebcam();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _usedDevice = ok;
    });
    ref.read(shopAccountProvider.notifier).patch(cameraConnected: true);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(stringsProvider).shopCamFallback)),
      );
    }
  }

  @override
  void dispose() {
    detachShopWebcam();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final liveView = _usedDevice ? shopWebcamView() : null;
    final jobs = shopJobs(ref.watch(ordersProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shopTabCamera),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
          children: [
            Text(
              s.shopCamHowToTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.shopCamHowToBody,
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: kBayLiveHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (liveView != null)
                      liveView
                    else
                      BayLiveCamera(
                        seed: _cam.id,
                        liveLabel: account.liveOn ? s.bayLive : s.shopCamOn,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kLiveCams.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cam = kLiveCams[i];
                  final on = cam.id == _cam.id;
                  return ChoiceChip(
                    label: Text('${cam.camCode} · ${cam.hostShort}'),
                    selected: on,
                    onSelected: (_) => setState(() => _cam = cam),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (!account.cameraConnected)
              FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: const Icon(CupertinoIcons.videocam_fill, size: 20),
                label: Text(_busy ? s.shopCamConnecting : s.shopConnectCam),
              )
            else ...[
              Text(
                account.liveOn ? s.shopCamOn : s.shopCamOff,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: account.liveOn ? palette.danger : palette.text,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {
                  ref
                      .read(shopAccountProvider.notifier)
                      .patch(liveOn: !account.liveOn);
                },
                child: Text(account.liveOn ? s.shopStopLive : s.shopGoLive),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  detachShopWebcam();
                  setState(() => _usedDevice = false);
                  ref.read(shopAccountProvider.notifier).patch(
                        cameraConnected: false,
                        liveOn: false,
                      );
                },
                child: Text(s.shopCamOff),
              ),
            ],
            const SizedBox(height: 28),
            Divider(color: palette.stroke),
            const SizedBox(height: 16),
            Text(
              s.shopMyCameras,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.shopMyCamerasHint,
              style: TextStyle(color: palette.muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            if (jobs.isEmpty)
              Text(s.shopNoJobs, style: TextStyle(color: palette.muted))
            else
              for (final order in jobs) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.stroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.brand} ${order.model} · ${order.plate}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BayLiveCamera(
                            assets: bayCameraAssets(order),
                            seed: order.id,
                            liveLabel: s.bayLive,
                            compact: true,
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
