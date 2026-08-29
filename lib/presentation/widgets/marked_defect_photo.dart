import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/crm_models.dart';

/// Photo + red circle / arrow overlays (normalized marks).
class MarkedDefectPhotoView extends StatelessWidget {
  const MarkedDefectPhotoView({
    super.key,
    required this.photo,
    this.height = 220,
  });

  final MarkedDefectPhoto photo;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              Uint8List.fromList(photo.bytes),
              fit: BoxFit.cover,
            ),
            CustomPaint(painter: _MarksPainter(photo.marks)),
            if (photo.caption.isNotEmpty)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  photo.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DefectPhotoMarkupEditor extends StatefulWidget {
  const DefectPhotoMarkupEditor({
    super.key,
    required this.bytes,
    required this.onDone,
  });

  final List<int> bytes;
  final void Function(List<DefectMark> marks, String caption) onDone;

  @override
  State<DefectPhotoMarkupEditor> createState() =>
      _DefectPhotoMarkupEditorState();
}

class _DefectPhotoMarkupEditorState extends State<DefectPhotoMarkupEditor> {
  DefectMarkKind _kind = DefectMarkKind.circle;
  final _marks = <DefectMark>[];
  Offset? _arrowStart;
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details, BoxConstraints box) {
    final nx = (details.localPosition.dx / box.maxWidth).clamp(0.0, 1.0);
    final ny = (details.localPosition.dy / box.maxHeight).clamp(0.0, 1.0);
    if (_kind == DefectMarkKind.circle) {
      setState(() {
        _marks.add(DefectMark(kind: DefectMarkKind.circle, x: nx, y: ny));
      });
      return;
    }
    if (_arrowStart == null) {
      setState(() => _arrowStart = Offset(nx, ny));
      return;
    }
    setState(() {
      _marks.add(
        DefectMark(
          kind: DefectMarkKind.arrow,
          x: _arrowStart!.dx,
          y: _arrowStart!.dy,
          x2: nx,
          y2: ny,
        ),
      );
      _arrowStart = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark defect'),
        actions: [
          TextButton(
            onPressed: () => widget.onDone(_marks, _caption.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Circle'),
                  selected: _kind == DefectMarkKind.circle,
                  onSelected: (_) =>
                      setState(() => _kind = DefectMarkKind.circle),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Arrow'),
                  selected: _kind == DefectMarkKind.arrow,
                  onSelected: (_) =>
                      setState(() => _kind = DefectMarkKind.arrow),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    if (_marks.isNotEmpty) _marks.removeLast();
                  }),
                  child: const Text('Undo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                return GestureDetector(
                  onTapDown: (d) => _onTapDown(d, box),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        Uint8List.fromList(widget.bytes),
                        fit: BoxFit.contain,
                      ),
                      CustomPaint(painter: _MarksPainter(_marks)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _caption,
              decoration: InputDecoration(
                labelText: 'Caption',
                hintText: 'Crack on CV boot…',
                fillColor: palette.surface,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.marks);

  final List<DefectMark> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    for (final mark in marks) {
      if (mark.kind == DefectMarkKind.circle) {
        canvas.drawCircle(
          Offset(mark.x * size.width, mark.y * size.height),
          size.shortestSide * 0.08,
          paint,
        );
      } else {
        final a = Offset(mark.x * size.width, mark.y * size.height);
        final b = Offset(mark.x2 * size.width, mark.y2 * size.height);
        canvas.drawLine(a, b, paint);
        final dir = b - a;
        if (dir.distance > 4) {
          final n = dir / dir.distance;
          final left = Offset(-n.dy, n.dx);
          final tip = b;
          canvas.drawLine(tip, tip - n * 14 + left * 8, paint);
          canvas.drawLine(tip, tip - n * 14 - left * 8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarksPainter oldDelegate) =>
      oldDelegate.marks != marks;
}
