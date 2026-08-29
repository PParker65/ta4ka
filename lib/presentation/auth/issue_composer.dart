import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/design_skin.dart';
import '../../app/theme.dart';
import '../widgets/mono_image.dart';
import '../../core/l10n/app_strings.dart';

class IssueComposer extends StatefulWidget {
  const IssueComposer({
    super.key,
    required this.strings,
    required this.query,
    required this.loading,
    required this.photoAttached,
    required this.onPhoto,
    required this.onAnalyze,
    this.onClear,
    this.photoBytes,
    this.accentColor,
  });

  final AppStrings strings;
  final TextEditingController query;
  final bool loading;
  final bool photoAttached;
  final Uint8List? photoBytes;
  final VoidCallback onPhoto;
  final VoidCallback onAnalyze;
  final VoidCallback? onClear;
  final Color? accentColor;

  @override
  State<IssueComposer> createState() => _IssueComposerState();
}

class _IssueComposerState extends State<IssueComposer>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  final _fieldFocus = FocusNode();
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    widget.query.addListener(_onQuery);
    _fieldFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _enter, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enter.forward();
    });
    _enter.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        HapticFeedback.lightImpact();
        setState(() => _landed = true);
      }
    });
  }

  @override
  void dispose() {
    widget.query.removeListener(_onQuery);
    _fieldFocus.dispose();
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onQuery() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phone = isPhoneLayout(context);
    final s = widget.strings;
    final typed = widget.query.text.trim().isNotEmpty;
    final focused = _fieldFocus.hasFocus;
    final ready = typed || widget.photoAttached;
    final pad = phone ? 10.0 : 14.0;
    final titleSize = phone ? 16.0 : 20.0;
    final fieldSize = phone ? 15.0 : 16.0;
    const outerRadius = 18.0;
    final accent = widget.accentColor ?? palette.accent;
    final fieldFill = palette.isDark ? palette.fillDeep : palette.carbon;
    final fieldInk = palette.text;
    final fieldHint = palette.muted;

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(outerRadius),
      child: ColoredBox(
        color: palette.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0),
                    accent,
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, phone ? 10 : 14, pad, phone ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PinMark(accent: accent, palette: palette, size: phone ? 28 : 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.aiQuickTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w700,
                            fontSize: titleSize,
                            letterSpacing: 0,
                            height: 1.2,
                            shadows: const [],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.aiQuickLead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: phone ? 12 : 13,
                        height: 1.2,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                        shadows: const [],
                      ),
                    ),
                  ),
                  SizedBox(height: phone ? 8 : 10),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = Curves.easeInOutCubic.transform(_pulse.value);
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: fieldFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Color.lerp(
                              accent.withValues(alpha: 0.40),
                              accent,
                              0.18 + t * 0.22,
                            )!,
                            width: focused || typed ? 1.6 : 1.2 + t * 0.25,
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      height: phone ? 44 : 48,
                      child: TextField(
                        controller: widget.query,
                        focusNode: _fieldFocus,
                        minLines: 1,
                        maxLines: 1,
                        style: TextStyle(
                          color: fieldInk,
                          fontSize: fieldSize,
                          letterSpacing: 0,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          shadows: const [],
                        ),
                        cursorColor: fieldInk,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: s.aiQuickFieldHint,
                          hintStyle: TextStyle(
                            color: fieldHint,
                            fontSize: fieldSize,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w500,
                            shadows: const [],
                          ),
                          prefixIcon: Icon(CupertinoIcons.search, size: 17, color: fieldHint),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          suffixIcon: typed
                              ? IconButton(
                                  onPressed: widget.onClear ?? widget.query.clear,
                                  icon: Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    size: 18,
                                    color: fieldHint,
                                  ),
                                )
                              : Icon(
                                  CupertinoIcons.pencil,
                                  size: 15,
                                  color: fieldHint,
                                ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: phone ? 10 : 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: palette.stroke.withValues(alpha: 0.55)),
            Builder(
              builder: (context) {
                final layout = tokensOf(context).composerLayout;
                final photo = _ActionTile(
                  palette: palette,
                  icon: widget.photoAttached
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.camera_fill,
                  label: widget.photoAttached ? s.aiQuickPhotoDone : s.aiQuickPhoto,
                  active: widget.photoAttached,
                  leading: widget.photoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AppMemoryImage(
                            bytes: widget.photoBytes!,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                  onTap: widget.onPhoto,
                );
                final analyze = _ActionTile(
                  palette: palette,
                  icon: CupertinoIcons.location_solid,
                  label: s.aiQuickAnalyze,
                  primary: true,
                  enabled: ready,
                  loading: widget.loading,
                  onTap: widget.onAnalyze,
                );
                if (layout == ComposerActionsLayout.stackedAnalyzeTop) {
                  return Column(
                    children: [
                      analyze,
                      Divider(height: 1, thickness: 0.5, color: palette.stroke.withValues(alpha: 0.55)),
                      photo,
                    ],
                  );
                }
                final analyzeFirst =
                    layout == ComposerActionsLayout.rowAnalyzeThenPhoto;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: analyzeFirst ? analyze : photo),
                      Container(width: 0.5, color: palette.stroke.withValues(alpha: 0.55)),
                      Expanded(child: analyzeFirst ? photo : analyze),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    final card = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_pulse.value);
        // Half of the previous 0.985–1.020 travel.
        final scale = 0.9925 + t * 0.0175;
        return Stack(
          children: [
            Positioned.fill(
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(outerRadius),
                    border: Border.all(
                      color: Color.lerp(palette.stroke, accent, 0.28 + t * 0.22)!,
                      width: 1.15 + t * 0.3,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(1.5),
              child: child,
            ),
          ],
        );
      },
      child: inner,
    );

    if (_landed) return card;
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        return Opacity(
          opacity: 0.55 + _fade.value * 0.45,
          child: Transform.scale(
            scale: _scale.value,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.none,
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

class _PinMark extends StatelessWidget {
  const _PinMark({
    required this.accent,
    required this.palette,
    required this.size,
  });

  final Color accent;
  final AppPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: palette.isDark ? 0.16 : 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Icon(
        CupertinoIcons.location_solid,
        size: size * 0.42,
        color: accent,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.active = false,
    this.enabled = true,
    this.loading = false,
    this.leading,
  });

  final AppPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool active;
  final bool enabled;
  final bool loading;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final phone = isPhoneLayout(context);
    final on = primary ? enabled : true;
    final btnFill = palette.isDark ? palette.fillDeep : palette.carbon;
    final btnFg = on ? palette.text : palette.muted;
    final bg = on ? btnFill : btnFill.withValues(alpha: 0.55);
    final fg = btnFg;
    final border = palette.stroke;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: on && !loading ? onTap : null,
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: phone ? 6 : 8, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else ...[
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 8),
                    ] else ...[
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: phone ? 13 : 14,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
