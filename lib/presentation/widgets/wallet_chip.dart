import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/tap_wallet.dart';

class WalletChip extends ConsumerWidget {
  const WalletChip({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(tapWalletProvider);
    final palette = paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        compact ? wallet.balanceLabel : '${wallet.balanceLabel} · ${wallet.balanceUah} ₴',
        style: TextStyle(
          color: palette.accent,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class TapWalletHud extends ConsumerStatefulWidget {
  const TapWalletHud({super.key});

  @override
  ConsumerState<TapWalletHud> createState() => _TapWalletHudState();
}

class _TapWalletHudState extends ConsumerState<TapWalletHud>
    with TickerProviderStateMixin {
  late final AnimationController _hit;
  late final AnimationController _levelFlash;

  @override
  void initState() {
    super.initState();
    _hit = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _levelFlash = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _hit.dispose();
    _levelFlash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(tapWalletProvider);
    final progress = wallet.goalProgress;
    ref.listen<TapWalletState>(tapWalletProvider, (prev, next) {
      if (prev == null) {
        return;
      }
      if (next.balanceUsdCents > prev.balanceUsdCents) {
        _levelFlash.forward(from: 0);
        _hit.forward(from: 0);
        return;
      }
      if (next.pluses > prev.pluses) {
        _hit.forward(from: 0);
      }
    });
    final palette = paletteOf(context);
    final dark = palette.isDark;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([_hit, _levelFlash]),
          builder: (context, _) {
            return SizedBox(
              width: 16,
              child: CustomPaint(
                painter: _EnergyBarPainter(
                  progress: value,
                  shimmer: 0,
                  pulse: 0,
                  hit: _hit.value,
                  levelFlash: _levelFlash.value,
                  accent: palette.accent,
                  glow: palette.glow,
                  fillDeep: palette.fillDeep,
                  dark: dark,
                  vertical: true,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        );
      },
    );
  }
}

class _EnergyBarPainter extends CustomPainter {
  _EnergyBarPainter({
    required this.progress,
    required this.shimmer,
    required this.pulse,
    required this.hit,
    required this.levelFlash,
    required this.accent,
    required this.glow,
    required this.fillDeep,
    required this.dark,
    this.vertical = false,
  });

  final double progress;
  final double shimmer;
  final double pulse;
  final double hit;
  final double levelFlash;
  final Color accent;
  final Color glow;
  final Color fillDeep;
  final bool dark;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    if (vertical) {
      canvas.save();
      canvas.translate(0, size.height);
      canvas.rotate(-math.pi / 2);
      _paintBar(canvas, Size(size.height, size.width));
      canvas.restore();
      return;
    }
    _paintBar(canvas, size);
  }

  void _paintBar(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromLTRBR(0, 0, size.width, size.height, radius);

    canvas.drawRRect(
      track.inflate(5),
      Paint()
        ..color = accent.withValues(alpha: 0.10 + pulse * 0.08 + hit * 0.16)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      track,
      Paint()..color = dark ? const Color(0x66FFFFFF) : accent.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      track.deflate(1.1),
      Paint()..color = dark ? const Color(0xEE08080A) : const Color(0xFFC4869A),
    );

    final tickPaint = Paint()
      ..color = (dark ? Colors.white : accent).withValues(alpha: dark ? 0.13 : 0.18)
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 5), Offset(x, size.height - 5), tickPaint);
    }

    final fillW = (size.width * progress.clamp(0.0, 1.0)).clamp(0.0, size.width);
    if (fillW < 1.6 && levelFlash <= 0.05) {
      return;
    }
    final shown = fillW;
    final fill = RRect.fromLTRBR(0, 0, shown, size.height, radius);

    canvas.drawRRect(
      fill.inflate(3 + hit * 4),
      Paint()
        ..color = glow.withValues(alpha: 0.22 + pulse * 0.18 + hit * 0.35)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );

    canvas.save();
    canvas.clipRRect(fill);

    final shift = (shimmer * 0.35) - 0.08;
    final fillRect = Rect.fromLTWH(0, 0, shown, size.height);
    canvas.drawRect(
      fillRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(shown * (0.05 + shift), 0),
          Offset(shown, size.height),
          [
            fillDeep,
            accent,
            glow,
            const Color(0xFFFFFFFF),
          ],
          const [0.0, 0.38, 0.78, 1.0],
        ),
    );

    canvas.drawRRect(
      RRect.fromLTRBR(3, 2, shown - 3, size.height * 0.42, const Radius.circular(99)),
      Paint()..color = Colors.white.withValues(alpha: 0.22 + pulse * 0.08),
    );

    final band = shown * 0.28;
    final x = -band + shimmer * (shown + band);
    canvas.drawRect(
      Rect.fromLTWH(x, 0, band, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, 0),
          Offset(x + band, 0),
          [
            const Color(0x00FFFFFF),
            Colors.white.withValues(alpha: 0.55 + hit * 0.25),
            const Color(0x00FFFFFF),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    if (levelFlash > 0.02) {
      canvas.drawRect(
        fillRect,
        Paint()..color = Colors.white.withValues(alpha: (1 - levelFlash) * 0.55),
      );
    }
    canvas.restore();

    if (shown < 6) {
      return;
    }
    final head = Offset(shown - size.height * 0.42, size.height / 2);
    final headR = size.height * (0.28 + pulse * 0.06 + hit * 0.08);
    canvas.drawCircle(
      head,
      headR * 2.1,
      Paint()
        ..color = glow.withValues(alpha: 0.35 + pulse * 0.2 + hit * 0.3)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
    );
    canvas.drawCircle(head, headR, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
      head.translate(-headR * 0.18, -headR * 0.18),
      headR * 0.35,
      Paint()..color = const Color(0xCCFFFFFF),
    );

    final spark = Paint()..color = Colors.white.withValues(alpha: 0.35 + hit * 0.4);
    for (var i = 0; i < 4; i++) {
      final a = shimmer * math.pi * 2 + i * 1.7;
      final dist = size.height * (0.7 + 0.35 * math.sin(shimmer * math.pi * 2 + i));
      canvas.drawCircle(
        head + Offset(math.cos(a) * dist * 0.35, math.sin(a) * dist * 0.22),
        1.1 + (i.isEven ? 0.6 : 0),
        spark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.pulse != pulse ||
        oldDelegate.hit != hit ||
        oldDelegate.levelFlash != levelFlash ||
        oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.fillDeep != fillDeep ||
        oldDelegate.dark != dark ||
        oldDelegate.vertical != vertical;
  }
}
