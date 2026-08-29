import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';

/// Current language: color flag + chevron. Tap opens the list.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);

    return PopupMenuButton<AppLang>(
      tooltip: lang.label,
      offset: const Offset(0, 36),
      padding: EdgeInsets.zero,
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.stroke),
      ),
      onSelected: (next) => ref.read(localeProvider.notifier).setLang(next),
      itemBuilder: (context) {
        return [
          for (final item in AppLang.values)
            PopupMenuItem<AppLang>(
              value: item,
              height: 44,
              child: Row(
                children: [
                  _ColorFlag(lang: item, width: 26, height: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: palette.text,
                      ),
                    ),
                  ),
                  if (item == lang)
                    Icon(CupertinoIcons.checkmark, size: 16, color: palette.accent),
                ],
              ),
            ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorFlag(lang: lang, width: 24, height: 16),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorFlag extends StatelessWidget {
  const _ColorFlag({
    required this.lang,
    required this.width,
    required this.height,
  });

  final AppLang lang;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _ColorFlagPainter(lang)),
      ),
    );
  }
}

class _ColorFlagPainter extends CustomPainter {
  _ColorFlagPainter(this.lang);

  final AppLang lang;

  @override
  void paint(Canvas canvas, Size size) {
    switch (lang) {
      case AppLang.uk:
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height / 2),
          Paint()..color = const Color(0xFF0057B7),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
          Paint()..color = const Color(0xFFFFD700),
        );
      case AppLang.en:
        canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF012169));
        final white = Paint()
          ..color = Colors.white
          ..strokeWidth = size.height * 0.28
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset.zero, Offset(size.width, size.height), white);
        canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), white);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.28,
            height: size.height,
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height * 0.36,
          ),
          Paint()..color = Colors.white,
        );
        final red = Paint()..color = const Color(0xFFC8102E);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.16,
            height: size.height,
          ),
          red,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height * 0.18,
          ),
          red,
        );
      case AppLang.ru:
        final h = size.height / 3;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), Paint()..color = Colors.white);
        canvas.drawRect(Rect.fromLTWH(0, h, size.width, h), Paint()..color = const Color(0xFF0039A6));
        canvas.drawRect(Rect.fromLTWH(0, h * 2, size.width, h), Paint()..color = const Color(0xFFD52B1E));
      case AppLang.pl:
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height / 2),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
          Paint()..color = const Color(0xFFDC143C),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ColorFlagPainter oldDelegate) => oldDelegate.lang != lang;
}
