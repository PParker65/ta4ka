import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/models/crm_models.dart';
import '../widgets/language_switcher.dart';
import '../widgets/ui.dart';
import 'car_body_diagram.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key});

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  final _mileage = TextEditingController();
  final _picker = ImagePicker();
  BodyZone? _zone;

  @override
  void initState() {
    super.initState();
    final km = ref.read(kioskProvider).inspection.mileageKm;
    if (km != null) {
      _mileage.text = '$km';
    }
  }

  @override
  void dispose() {
    _mileage.dispose();
    super.dispose();
  }

  Map<BodyZone, String> _labels(AppStrings s) => {
        BodyZone.frontBumper: s.zoneFrontBumper,
        BodyZone.hood: s.zoneHood,
        BodyZone.leftFender: s.zoneLeftFender,
        BodyZone.rightFender: s.zoneRightFender,
        BodyZone.leftDoor: s.zoneLeftDoor,
        BodyZone.rightDoor: s.zoneRightDoor,
        BodyZone.roof: s.zoneRoof,
        BodyZone.glass: s.zoneGlass,
        BodyZone.rearBumper: s.zoneRearBumper,
      };

  void _update(VehicleInspection Function(VehicleInspection current) change) {
    final current = ref.read(kioskProvider).inspection;
    ref.read(kioskProvider.notifier).setInspection(change(current));
  }

  Future<void> _pickSource(AppStrings s) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(s.camera),
              onTap: () {
                Navigator.pop(context);
                _fromCamera(s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.gallery),
              onTap: () {
                Navigator.pop(context);
                _fromGallery(s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(s.files),
              onTap: () {
                Navigator.pop(context);
                _fromFiles(s);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fromCamera(AppStrings s) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (file != null) {
        await _addXFiles([file]);
      }
    } catch (_) {
      _error(s);
    }
  }

  Future<void> _fromGallery(AppStrings s) async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isNotEmpty) {
        await _addXFiles(files);
      }
    } catch (_) {
      _error(s);
    }
  }

  Future<void> _fromFiles(AppStrings s) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final photos = <InspectionPhoto>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          photos.add(InspectionPhoto(
            id: '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
            name: file.name,
            bytes: bytes,
          ));
        }
      }
      _addPhotos(photos);
    } catch (_) {
      _error(s);
    }
  }

  Future<void> _addXFiles(List<XFile> files) async {
    final photos = <InspectionPhoto>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      photos.add(
        InspectionPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
          name: file.name,
          bytes: bytes,
        ),
      );
    }
    _addPhotos(photos);
  }

  void _addPhotos(List<InspectionPhoto> photos) {
    if (photos.isEmpty) return;
    _update((current) => current.copyWith(photos: [...current.photos, ...photos]));
  }

  void _error(AppStrings s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.photoError)));
  }

  void _toggle(BodyZone zone, DefectKind kind) {
    _update((current) {
      final next = <BodyZone, Set<DefectKind>>{
        for (final entry in current.zoneDefects.entries) entry.key: {...entry.value},
      };
      final set = next.putIfAbsent(zone, () => <DefectKind>{});
      if (set.contains(kind)) {
        set.remove(kind);
        if (set.isEmpty) next.remove(zone);
      } else {
        set.add(kind);
      }
      return current.copyWith(zoneDefects: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final inspection = ref.watch(kioskProvider).inspection;
    final selectedDefects =
        _zone == null ? const <DefectKind>{} : inspection.zoneDefects[_zone] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(s.inspectionTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSwitcher(),
          ),
        ],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(s.inspectionHint),
          const SizedBox(height: 16),
          TextField(
            controller: _mileage,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.mileage,
              suffixText: s.km,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _update(
                (current) => current.copyWith(
                  mileageKm: int.tryParse(value),
                  clearMileage: value.isEmpty,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('${s.fuel}: ${s.fuelEighths(inspection.fuelEighths)}'),
          Slider(
            value: inspection.fuelEighths.toDouble(),
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (value) {
              _update((current) => current.copyWith(fuelEighths: value.round()));
            },
          ),
          const SizedBox(height: 8),
          Text(s.tapZone),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: CarBodyDiagram(
                defects: inspection.zoneDefects,
                selectedZone: _zone,
                labels: _labels(s),
                onSelect: (zone) => setState(() => _zone = zone),
              ),
            ),
          ),
          if (_zone != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(s.scratch),
                  selected: selectedDefects.contains(DefectKind.scratch),
                  onSelected: (_) => _toggle(_zone!, DefectKind.scratch),
                ),
                FilterChip(
                  label: Text(s.dent),
                  selected: selectedDefects.contains(DefectKind.dent),
                  onSelected: (_) => _toggle(_zone!, DefectKind.dent),
                ),
                FilterChip(
                  label: Text(s.defect),
                  selected: selectedDefects.contains(DefectKind.other),
                  onSelected: (_) => _toggle(_zone!, DefectKind.other),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final photo in inspection.photos)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        Uint8List.fromList(photo.bytes),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: InkWell(
                        onTap: () {
                          _update(
                            (current) => current.copyWith(
                              photos: current.photos
                                  .where((item) => item.id != photo.id)
                                  .toList(),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          child: Icon(Icons.close, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              OutlinedButton.icon(
                onPressed: () => _pickSource(s),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(s.attachPhoto),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: Text(s.saveInspection),
          ),
          TextButton(
            onPressed: () {
              ref.read(kioskProvider.notifier).setInspection(const VehicleInspection());
              _mileage.clear();
              setState(() => _zone = null);
            },
            child: Text(s.resetInspection),
          ),
        ],
        ),
      ),
    );
  }
}
