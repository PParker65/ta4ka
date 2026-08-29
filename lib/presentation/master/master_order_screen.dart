import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/marked_defect_photo.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import '../widgets/work_order_naryad.dart';
import '../workshop/shop_jobs.dart';
import '../workshop/shop_ops_screens.dart';

/// Master bay screen: live заказ-наряд + marked defect photos.
class MasterOrderScreen extends ConsumerStatefulWidget {
  const MasterOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<MasterOrderScreen> createState() => _MasterOrderScreenState();
}

class _MasterOrderScreenState extends ConsumerState<MasterOrderScreen> {
  WorkOrder? _order() {
    for (final o in ref.read(ordersProvider)) {
      if (o.id == widget.orderId) return o;
    }
    return null;
  }

  void _save(WorkOrder next) {
    ref.read(ordersProvider.notifier).save(next);
  }

  Future<void> _addPhoto() async {
    final order = _order();
    if (order == null) return;
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 72,
      maxWidth: 1600,
    );
    if (shot == null || !mounted) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => DefectPhotoMarkupEditor(
          bytes: bytes,
          onDone: (marks, caption) {
            Navigator.of(ctx).pop();
            _save(
              order.copyWith(
                defectPhotos: [
                  ...order.defectPhotos,
                  MarkedDefectPhoto(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    bytes: bytes,
                    at: DateTime.now(),
                    caption: caption,
                    marks: marks,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    WorkOrder? order;
    for (final o in ref.watch(ordersProvider)) {
      if (o.id == widget.orderId) order = o;
    }
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.masterTabJobs)),
        body: const Center(child: Text('—')),
      );
    }
    final current = order;

    return Scaffold(
      appBar: AppBar(
        title: Text('${current.brand} ${current.model}'),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (current.status == JobStatus.created) ...[
              FilledButton.icon(
                onPressed: () =>
                    takeIntoBay(ref.read(ordersProvider.notifier), current),
                icon: const Icon(CupertinoIcons.cube_box_fill),
                label: Text(s.shopTakeInBay),
              ),
              const SizedBox(height: 12),
            ] else if (current.status == JobStatus.inProgress) ...[
              FilledButton.icon(
                onPressed: () => markReady(
                  ref.read(ordersProvider.notifier),
                  current,
                  shop: ref.read(shopAccountProvider.notifier),
                ),
                icon: const Icon(CupertinoIcons.checkmark_seal_fill),
                label: Text(s.shopMarkReady),
              ),
              const SizedBox(height: 12),
            ],
            JobClockStrip(orderId: current.id),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => Scaffold(
                      appBar: AppBar(title: Text(s.opsCheckTitle)),
                      body: InspectionChecklist(order: current),
                    ),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.checkmark_square),
              label: Text(s.opsCheckTitle),
            ),
            const SizedBox(height: 12),
            WorkOrderNaryadPanel(order: current, mode: NaryadMode.master),
            const SizedBox(height: 28),
            Text(
              s.defectPhotoTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(s.defectPhotoLead, style: TextStyle(color: palette.muted)),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _addPhoto,
              icon: const Icon(CupertinoIcons.camera),
              label: Text(s.defectPhotoAdd),
            ),
            const SizedBox(height: 12),
            for (final photo in current.defectPhotos) ...[
              MarkedDefectPhotoView(photo: photo),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
