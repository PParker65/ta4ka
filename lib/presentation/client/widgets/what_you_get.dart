import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/currency/uah.dart';
import '../../../data/you_get_steps.dart';
import '../../../domain/models/crm_models.dart';
import '../booking_format.dart';

class WorkPickTile extends StatefulWidget {
  const WorkPickTile({
    super.key,
    required this.work,
    required this.selected,
    required this.lang,
    required this.strings,
    required this.onToggle,
  });

  final ServiceWork work;
  final bool selected;
  final AppLang lang;
  final AppStrings strings;
  final VoidCallback onToggle;

  @override
  State<WorkPickTile> createState() => _WorkPickTileState();
}

class _WorkPickTileState extends State<WorkPickTile> {
  bool _peek = false;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final selected = widget.selected;
    final open = _peek;
    final steps = widget.work.youGet;

    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.12) : palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? palette.accent : palette.stroke,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? palette.accent : palette.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.work.title.of(widget.lang),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.text,
                            ),
                          ),
                          Text(
                            '${formatUah(widget.work.priceStandard)} · ${formatEta(widget.work.minutes, widget.strings)}',
                            style: TextStyle(color: palette.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.work.olegTip.of(widget.lang),
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (steps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 8, 10),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _peek = !_peek),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.strings.youGetCta,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: open ? 0.25 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(CupertinoIcons.arrow_right, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: open
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 8, 6),
                              child: WhatYouGetSteps(
                                title: widget.strings.youGetTitle,
                                steps: [
                                  for (final step in steps) step.of(widget.lang),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WhatYouGetSteps extends StatelessWidget {
  const WhatYouGetSteps({
    super.key,
    required this.steps,
    this.title,
  });

  final String? title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            index: i + 1,
            text: steps[i],
            last: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    required this.last,
  });

  final int index;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: last ? palette.accent : palette.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: last ? palette.onAccent : palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: palette.accent.withValues(alpha: 0.28),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12, top: 2),
              child: Text(
                text,
                style: TextStyle(
                  color: last ? palette.text : palette.text.withValues(alpha: 0.92),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: last ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
