import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FactorRating extends StatelessWidget {
  const FactorRating({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.text),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => onChanged(i),
                iconSize: 32,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_border_rounded,
                  color: palette.accent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
