import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/auto_spheres.dart';
import '../widgets/mono_image.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'widgets/category_icon.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _query = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoBase64;
  String? _photoMime;
  bool _loading = false;
  String? _aiSummary;
  List<String> _suggestedIds = const [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _mimeOf(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showPhotoSheet() {
    final s = ref.read(stringsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: Text(s.profileTakePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: Text(s.profileChoosePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photoBytes != null)
                ListTile(
                  leading: const Icon(CupertinoIcons.trash),
                  title: Text(s.categoriesClearPhoto),
                  onTap: () {
                    Navigator.pop(context);
                    _clearPhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final s = ref.read(stringsProvider);
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 82);
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoBase64 = base64Encode(bytes);
        _photoMime = _mimeOf(file.name);
      });
      await _analyzePhoto();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.photoError)),
      );
    }
  }

  Future<void> _analyzePhoto() async {
    if (_loading || _photoBase64 == null) {
      return;
    }
    final lang = ref.read(localeProvider);
    setState(() => _loading = true);
    try {
      final result = await ref.read(aiTriageApiProvider).analyze(
            query: _query.text.trim(),
            lang: lang,
            photoBase64: _photoBase64,
            photoMime: _photoMime,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _aiSummary = result.summary.of(lang);
        _suggestedIds = result.sphereIds;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  void _clearPhoto() {
    setState(() {
      _photoBytes = null;
      _photoBase64 = null;
      _photoMime = null;
      _aiSummary = null;
      _suggestedIds = const [];
    });
  }

  List<AutoSphere> _items() {
    final lang = ref.read(localeProvider);
    final q = _query.text.trim();
    final base = q.isEmpty ? List<AutoSphere>.from(autoSpheres) : searchSpheres(q, lang: lang);
    if (_suggestedIds.isEmpty) {
      return base;
    }
    final suggested = spheresFromIds(_suggestedIds);
    final rest = base.where((sphere) => !_suggestedIds.contains(sphere.id));
    return [...suggested, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final items = _items();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabCategories),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        sphereId: _suggestedIds.isNotEmpty ? _suggestedIds.first : null,
        child: ListView(
          padding: shellListPadding(context),
          children: [
            Text(
              s.categoriesLead,
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: s.searchCategories,
                      prefixIcon: const Icon(CupertinoIcons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _PhotoSearchButton(
                  palette: palette,
                  loading: _loading,
                  bytes: _photoBytes,
                  onTap: _showPhotoSheet,
                ),
              ],
            ),
            if (_photoBytes != null) ...[
              const SizedBox(height: 12),
              _PhotoHintCard(
                palette: palette,
                loading: _loading,
                looking: s.categoriesLooking,
                hint: _aiSummary ?? s.categoriesPhotoHint,
                onClear: _clearPhoto,
                clearLabel: s.categoriesClearPhoto,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                s.categoriesPhotoHint,
                style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35),
              ),
            ],
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final sphere = items[index];
                final suggested = _suggestedIds.contains(sphere.id);
                return CategoryGridEntrance(
                  index: index,
                  child: CategoryFocusCard(
                    sphere: sphere,
                    lang: lang,
                    suggested: suggested,
                    suggestedLabel: suggested ? s.categoriesSuggested : '',
                    onTap: () {
                      if (sphere.id == 'usa') {
                        ref.read(sectionSlideDirProvider.notifier).state = 1;
                        ref.read(clientTabProvider.notifier).state = ClientTabs.usa;
                        return;
                      }
                      context.push('/home/categories/${sphere.id}');
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSearchButton extends StatelessWidget {
  const _PhotoSearchButton({
    required this.palette,
    required this.loading,
    required this.bytes,
    required this.onTap,
  });

  final AppPalette palette;
  final bool loading;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : bytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppMemoryImage(
                        bytes: bytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(CupertinoIcons.camera_fill, color: palette.accent, size: 22),
        ),
      ),
    );
  }
}

class _PhotoHintCard extends StatelessWidget {
  const _PhotoHintCard({
    required this.palette,
    required this.loading,
    required this.looking,
    required this.hint,
    required this.onClear,
    required this.clearLabel,
  });

  final AppPalette palette;
  final bool loading;
  final String looking;
  final String hint;
  final VoidCallback onClear;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.sparkles, size: 18, color: palette.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loading ? looking : hint,
              style: TextStyle(
                color: palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            tooltip: clearLabel,
            onPressed: onClear,
            icon: Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: palette.muted),
          ),
        ],
      ),
    );
  }
}
