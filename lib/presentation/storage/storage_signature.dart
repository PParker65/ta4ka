import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'storage_l10n.dart';

class StorageSignaturePad extends StatefulWidget {
  const StorageSignaturePad({
    super.key,
    required this.l10n,
    this.initialPng,
    this.height = 168,
  });

  final StorageL10n l10n;
  final String? initialPng;
  final double height;

  @override
  State<StorageSignaturePad> createState() => StorageSignaturePadState();
}

class StorageSignaturePadState extends State<StorageSignaturePad> {
  final _strokes = <List<Offset>>[];
  var _dirty = false;

  bool get hasInk => _strokes.any((stroke) => stroke.length >= 2);

  void clear() {
    setState(() {
      _strokes.clear();
      _dirty = true;
    });
  }

  Future<String?> exportPng() async {
    if (!hasInk) {
      final keep = widget.initialPng?.trim() ?? '';
      return keep.isEmpty ? null : keep;
    }
    const width = 640.0;
    const height = 240.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final box = context.findRenderObject() as RenderBox?;
    final sx = width / (box?.size.width ?? width);
    final sy = height / (box?.size.height ?? height);
    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx * sx, stroke.first.dy * sy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * sx, point.dy * sy);
      }
      canvas.drawPath(path, paint);
    }
    final image = await recorder.endRecording().toImage(640, 240);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return base64Encode(bytes.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    Uint8List? preview;
    if (!_dirty && (widget.initialPng?.isNotEmpty ?? false)) {
      try {
        preview = base64Decode(widget.initialPng!);
      } catch (_) {}
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.isDark ? const Color(0xFF111114) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.stroke),
          ),
          child: SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (preview != null)
                    Image.memory(preview, fit: BoxFit.contain),
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _dirty = true;
                        _strokes.add([details.localPosition]);
                      });
                    },
                    onPanUpdate: (details) {
                      if (_strokes.isEmpty) return;
                      setState(() => _strokes.last.add(details.localPosition));
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: clear,
            child: Text(widget.l10n.clearSign),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class SignatureThumb extends StatelessWidget {
  const SignatureThumb({super.key, required this.png, this.width = 56, this.height = 28});

  final String png;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (png.trim().isEmpty) return const SizedBox.shrink();
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(png),
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
