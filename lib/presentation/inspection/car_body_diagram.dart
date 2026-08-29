import 'package:flutter/material.dart';

import '../../domain/models/crm_models.dart';

class CarBodyDiagram extends StatelessWidget {
  const CarBodyDiagram({
    super.key,
    required this.defects,
    required this.selectedZone,
    required this.labels,
    required this.onSelect,
  });

  final Map<BodyZone, Set<DefectKind>> defects;
  final BodyZone? selectedZone;
  final Map<BodyZone, String> labels;
  final ValueChanged<BodyZone> onSelect;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.62,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CarOutlinePainter(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              _zone(context, BodyZone.frontBumper, w * 0.22, h * 0.03, w * 0.56, h * 0.09),
              _zone(context, BodyZone.leftFender, w * 0.05, h * 0.13, w * 0.18, h * 0.16),
              _zone(context, BodyZone.hood, w * 0.24, h * 0.13, w * 0.52, h * 0.16),
              _zone(context, BodyZone.rightFender, w * 0.77, h * 0.13, w * 0.18, h * 0.16),
              _zone(context, BodyZone.leftDoor, w * 0.05, h * 0.31, w * 0.18, h * 0.32),
              _zone(context, BodyZone.roof, w * 0.24, h * 0.31, w * 0.52, h * 0.22),
              _zone(context, BodyZone.rightDoor, w * 0.77, h * 0.31, w * 0.18, h * 0.32),
              _zone(context, BodyZone.glass, w * 0.24, h * 0.54, w * 0.52, h * 0.12),
              _zone(context, BodyZone.rearBumper, w * 0.22, h * 0.86, w * 0.56, h * 0.09),
            ],
          );
        },
      ),
    );
  }

  Widget _zone(
    BuildContext context,
    BodyZone zone,
    double left,
    double top,
    double width,
    double height,
  ) {
    final theme = Theme.of(context);
    final selected = selectedZone == zone;
    final damaged = defects[zone]?.isNotEmpty ?? false;
    final fill = selected
        ? theme.colorScheme.primaryContainer
        : damaged
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelect(zone),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              labels[zone] ?? zone.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarOutlinePainter extends CustomPainter {
  _CarOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.02, size.width * 0.84, size.height * 0.96),
        const Radius.circular(28),
      ),
      paint,
    );
    final wheel = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.22), 8, wheel);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.22), 8, wheel);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.72), 8, wheel);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.72), 8, wheel);
  }

  @override
  bool shouldRepaint(covariant _CarOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
