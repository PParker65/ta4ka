import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/preview_context.dart';
import '../../app/theme.dart';
import '../../domain/models/wheel_storage.dart';
import 'storage_l10n.dart';

class StorageRackView extends StatefulWidget {
  const StorageRackView({
    super.key,
    required this.lots,
    required this.l10n,
    required this.sectorCount,
    this.shopName = '',
    this.selectedId,
    this.initiallyExpanded = true,
    this.maxHeight,
    this.lite,
    this.fitWidth = false,
    this.compactChrome = false,
    this.showSectorButtons = true,
    required this.onTapSlot,
    required this.onAddSector,
    required this.onRemoveSector,
  });

  final List<WheelLot> lots;
  final StorageL10n l10n;
  final String shopName;
  final int sectorCount;
  final String? selectedId;
  final bool initiallyExpanded;
  final double? maxHeight;
  final bool? lite;
  /// Lay sectors in the real width. No minimum sector width and no
  /// horizontal list that can grow the page past the screen.
  final bool fitWidth;
  final bool compactChrome;
  final bool showSectorButtons;
  final void Function(int sector, int rackRow, int slot) onTapSlot;
  final VoidCallback onAddSector;
  final VoidCallback onRemoveSector;

  @override
  State<StorageRackView> createState() => _StorageRackViewState();
}

class _StorageRackViewState extends State<StorageRackView> {
  late bool _expanded = widget.initiallyExpanded;
  var _height = 0.0;
  var _dragging = false;
  var _visibleSector = 1;

  static const _collapsedH = 168.0;

  @override
  void initState() {
    super.initState();
    _followSelection();
  }

  @override
  void didUpdateWidget(covariant StorageRackView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) _followSelection();
  }

  void _followSelection() {
    final id = widget.selectedId;
    if (id == null) return;
    for (final lot in widget.lots) {
      if (lot.id == id && lot.sector >= 1) {
        _visibleSector = lot.sector;
        return;
      }
    }
  }

  int get _sectors => clampSectorCount(widget.sectorCount);

  bool get _liteWheels {
    return widget.lite ??
        (kIsWeb || isKolesaSaveHost() || MediaQuery.sizeOf(context).shortestSide < 720);
  }

  double get _minH => widget.compactChrome ? 52.0 : _collapsedH;

  double _fit(double value, double lo, double hi) {
    final low = lo.isFinite && lo > 0 ? lo : _collapsedH;
    final high = hi.isFinite && hi >= low ? hi : low;
    if (!value.isFinite) return _expanded ? high : low;
    if (value < low) return low;
    if (value > high) return high;
    return value;
  }

  double get _maxH {
    final screen = MediaQuery.sizeOf(context).height;
    if (widget.compactChrome) {
      final raw = widget.maxHeight ?? (screen.isFinite && screen > 0 ? screen * 0.36 : 180);
      final cap = screen.isFinite && screen > _minH ? screen : _minH + 40;
      return _fit(raw, _minH, cap);
    }
    final raw = widget.maxHeight ?? (screen.isFinite && screen > 0 ? screen * 0.72 : 520);
    final floor = _minH + 120;
    final cap = screen.isFinite && screen > floor ? screen : floor + 80;
    return _fit(raw, floor, cap);
  }

  double get _currentH {
    if (_height >= _minH) return _fit(_height, _minH, _maxH);
    return _expanded ? _maxH : _minH;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragging = true;
      _height = _fit(_currentH + d.delta.dy, _minH, _maxH);
      _expanded = _height > (_minH + _maxH) / 2;
    });
  }

  void _onDragEnd(DragEndDetails _) {
    final snapOpen = _currentH >= (_minH + _maxH) / 2;
    setState(() {
      _expanded = snapOpen;
      _height = snapOpen ? _maxH : _minH;
      _dragging = false;
    });
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _height = _expanded ? _maxH : _minH;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final l10n = widget.l10n;
    final lite = _liteWheels;
    final sectors = _sectors;
    final clamped = _currentH;
    final compact = widget.compactChrome;
    final floor = palette.isDark ? const Color(0xFF0E0E10) : const Color(0xFFE9D3DA);
    final grid = _rackGrid(l10n, lite);
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(compact ? 16 : 22),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(8, 4, 8, 2)
            : const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shopName.trim().isEmpty
                            ? l10n.title
                            : widget.shopName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                          letterSpacing: compact ? 0.4 : 1.4,
                          fontSize: compact ? 14 : 22,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        widget.shopName.trim().isEmpty
                            ? l10n.splashLead
                            : l10n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: compact ? 0.4 : 1.2,
                          fontSize: compact ? 9 : 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showSectorButtons)
                  _SectorButtonRow(
                    l10n: l10n,
                    sectors: sectors,
                    onAdd: widget.onAddSector,
                    onRemove: widget.onRemoveSector,
                  ),
              ],
            ),
            SizedBox(height: compact ? 2 : 6),
            Expanded(
              child: CustomPaint(
                painter: _StandFramePainter(
                  steel: palette.stroke,
                  fill: palette.carbon,
                  floor: floor,
                  sectors: sectors,
                ),
                child: grid,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              onTap: _toggle,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, compact ? 2 : 8, 8, compact ? 2 : 6),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 6,
                        decoration: BoxDecoration(
                          color: palette.muted.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (!_expanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.dragRack,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return AnimatedContainer(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: clamped,
      clipBehavior: Clip.hardEdge,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: body,
        ),
      ),
    );
  }

  Widget _rackGrid(StorageL10n l10n, bool lite) {
    final compact = widget.compactChrome;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 2 : 8, compact ? 2 : 8, compact ? 2 : 8, compact ? 2 : 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = _sectors;
          final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 640.0;
          final maxH = constraints.maxHeight.isFinite && constraints.maxHeight > 8
              ? constraints.maxHeight
              : 280.0;
          Widget sectorCol(int sector) {
            return Column(
              children: [
                Text(
                  l10n.sectorN(sector),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: paletteOf(context).accent,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 10 : 12,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Expanded(
                  child: _SectorStack(
                    sector: sector,
                    lots: widget.lots,
                    l10n: l10n,
                    selectedId: widget.selectedId,
                    lite: lite,
                    onTapSlot: widget.onTapSlot,
                  ),
                ),
              ],
            );
          }

          if (widget.fitWidth) {
            return _fitSectors(
              count: count,
              maxW: maxW,
              l10n: l10n,
              sectorCol: sectorCol,
            );
          }

          final minW = lite ? 160.0 : 196.0;
          final even = maxW / count;
          final sectorW = even < minW ? minW : even;
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              for (var sector = 1; sector <= count; sector++) ...[
                if (sector > 1) const SizedBox(width: 8),
                SizedBox(
                  width: sectorW - (_expanded ? 18 / count : 0),
                  height: maxH,
                  child: sectorCol(sector),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// One sector is 3×8. If every sector fits with tappable wheels, show them
  /// in a row. Otherwise keep a single sector on screen and switch with a strip.
  Widget _fitSectors({
    required int count,
    required double maxW,
    required StorageL10n l10n,
    required Widget Function(int sector) sectorCol,
  }) {
    const gap = 4.0;
    const slotGap = 2.0;
    final gaps = count > 1 ? gap * (count - 1) : 0.0;
    final per = count == 0 ? maxW : (maxW - gaps) / count;
    final wheel = (per - slotGap * (kWheelsPerCell - 1)) / kWheelsPerCell;
    final page = count > 1 && wheel < 18;
    if (!page) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var sector = 1; sector <= count; sector++) ...[
            if (sector > 1) const SizedBox(width: gap),
            Expanded(child: sectorCol(sector)),
          ],
        ],
      );
    }
    final shown = _visibleSector < 1 ? 1 : (_visibleSector > count ? count : _visibleSector);
    return Column(
      children: [
        SizedBox(
          height: 22,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var sector = 1; sector <= count; sector++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _visibleSector = sector),
                      child: Text(
                        l10n.sectorN(sector),
                        style: TextStyle(
                          color: sector == shown
                              ? paletteOf(context).accent
                              : paletteOf(context).muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Expanded(child: sectorCol(shown)),
      ],
    );
  }
}

class _SectorButtonRow extends StatelessWidget {
  const _SectorButtonRow({
    required this.l10n,
    required this.sectors,
    required this.onAdd,
    required this.onRemove,
  });

  final StorageL10n l10n;
  final int sectors;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sectors > kDefaultSectors)
          TextButton(
            onPressed: onRemove,
            child: Text(l10n.removeSector, maxLines: 1, softWrap: false),
          ),
        if (sectors < kMaxSectors)
          TextButton(
            onPressed: onAdd,
            child: Text(l10n.addSector, maxLines: 1, softWrap: false),
          ),
      ],
    );
  }
}

/// One sector: three rows, eight wheel circles in each row.
class _SectorStack extends StatelessWidget {
  const _SectorStack({
    required this.sector,
    required this.lots,
    required this.l10n,
    required this.selectedId,
    this.lite = false,
    required this.onTapSlot,
  });

  final int sector;
  final List<WheelLot> lots;
  final StorageL10n l10n;
  final String? selectedId;
  final bool lite;
  final void Function(int sector, int rackRow, int slot) onTapSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 1; row <= kRackCells; row++) ...[
          if (row > 1) const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                for (var slot = 1; slot <= kWheelsPerCell; slot++) ...[
                  if (slot > 1) const SizedBox(width: 2),
                  Expanded(
                    child: _WheelSlot(
                      sector: sector,
                      rackRow: row,
                      slot: slot,
                      lots: lots,
                      selectedId: selectedId,
                      lite: lite,
                      l10n: l10n,
                      onTapSlot: onTapSlot,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WheelSlot extends StatelessWidget {
  const _WheelSlot({
    required this.sector,
    required this.rackRow,
    required this.slot,
    required this.lots,
    required this.selectedId,
    this.lite = false,
    required this.l10n,
    required this.onTapSlot,
  });

  final int sector;
  final int rackRow;
  final int slot;
  final List<WheelLot> lots;
  final String? selectedId;
  final bool lite;
  final StorageL10n l10n;
  final void Function(int sector, int rackRow, int slot) onTapSlot;

  @override
  Widget build(BuildContext context) {
    final lot = lotInSlot(lots, sector, rackRow, slot);
    final plate = lot == null
        ? ''
        : (lot.plate.trim().isNotEmpty ? lot.plate : l10n.cellBusy);
    return Tooltip(
      message: lot == null
          ? '${l10n.cellFree} · ${rackMarker(sector, rackRow)} · $slot'
          : '${l10n.cellBusy} · $plate · ${rackMarker(sector, rackRow)} · $slot · ${l10n.cargoLabel(lot.cargo)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTapSlot(sector, rackRow, slot),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 28.0;
            final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 28.0;
            final side = math.min(width, height);
            final size = side.clamp(1.0, 56.0).toDouble();
            return Center(
              child: WheelCargoIcon(
                cargo: lot?.cargo,
                empty: lot == null,
                selected: lot?.id == selectedId,
                size: size,
                lite: lite,
              ),
            );
          },
        ),
      ),
    );
  }
}

class WheelCargoIcon extends StatelessWidget {
  const WheelCargoIcon({
    super.key,
    this.cargo,
    this.empty = false,
    this.selected = false,
    this.size = 36,
    this.lite = false,
  });

  final StorageCargo? cargo;
  final bool empty;
  final bool selected;
  final double size;
  final bool lite;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    if (empty) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: WheelCargoPainter(
            cargo: null,
            selected: selected,
            dark: palette.isDark,
            accent: palette.accent,
            muted: palette.isDark ? palette.muted : palette.text,
          ),
        ),
      );
    }
    if (lite) {
      final fill = switch (cargo ?? StorageCargo.tires) {
              StorageCargo.tires => palette.isDark
                  ? const Color(0xFF2A2A2E)
                  : const Color(0xFF3A3A40),
              StorageCargo.tiresOnRims => palette.isDark
                  ? const Color(0xFF4A4A52)
                  : const Color(0xFF6A6A72),
              StorageCargo.rims => palette.isDark
                  ? const Color(0xFFC8CCD2)
                  : const Color(0xFF8A9098),
            };
      return SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(
              color: selected ? palette.accent : palette.stroke.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      );
    }
    final child = CustomPaint(
      painter: WheelCargoPainter(
        cargo: empty ? null : (cargo ?? StorageCargo.tires),
        selected: selected,
        dark: palette.isDark,
        accent: palette.accent,
        muted: palette.muted,
      ),
    );
    return SizedBox(width: size, height: size, child: child);
  }
}

class WheelCargoPainter extends CustomPainter {
  WheelCargoPainter({
    required this.cargo,
    required this.selected,
    required this.dark,
    required this.accent,
    required this.muted,
  });

  final StorageCargo? cargo;
  final bool selected;
  final bool dark;
  final Color accent;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1.2;
    if (r < 4) return;

    if (selected) {
      canvas.drawCircle(
        c,
        r + 1.4,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }

    if (cargo == null) {
      _empty(canvas, c, r);
      return;
    }
    switch (cargo!) {
      case StorageCargo.tires:
        _tire(canvas, c, r, withRim: false);
      case StorageCargo.tiresOnRims:
        _tire(canvas, c, r, withRim: true);
      case StorageCargo.rims:
        _rimOnly(canvas, c, r);
    }
  }

  Color get _rubber => dark ? const Color(0xFF161618) : const Color(0xFF1C1C1F);
  Color get _rubberHi => dark ? const Color(0xFF2A1E18) : const Color(0xFF3A2A22);
  Color get _metal => dark ? const Color(0xFFD8DCE2) : const Color(0xFF8A9098);
  Color get _metalDeep => dark ? const Color(0xFF9AA0B0) : const Color(0xFF5C6570);

  void _empty(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = muted.withValues(alpha: dark ? 0.55 : 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dark ? 1.3 : 1.7;
    const dashes = 18;
    for (var i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      final a0 = i / dashes * math.pi * 2;
      final a1 = (i + 0.55) / dashes * math.pi * 2;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.92), a0, a1 - a0, false, paint);
    }
  }

  void _tire(Canvas canvas, Offset c, double r, {required bool withRim}) {
    canvas.drawCircle(c, r, Paint()..color = _rubber);
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..color = _rubberHi
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );
    final tread = Paint()
      ..color = const Color(0xFF0A0A0C)
      ..strokeWidth = math.max(1.1, r * 0.06)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 20; i++) {
      final a = i / 20 * math.pi * 2;
      final outer = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + outer * (r * 0.97), c + outer * (r * 0.78), tread);
    }
    if (withRim) {
      canvas.drawCircle(c, r * 0.58, Paint()..color = _rubber);
      _alloy(canvas, c, r * 0.52);
    } else {
      canvas.drawCircle(c, r * 0.46, Paint()..color = const Color(0xFF0E0E10));
      canvas.drawCircle(
        c,
        r * 0.22,
        Paint()
          ..color = muted.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _rimOnly(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 0.98,
      Paint()
        ..color = _metalDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1,
    );
    canvas.drawCircle(
      c,
      r * 0.86,
      Paint()
        ..color = _metal
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07,
    );
    _alloy(canvas, c, r * 0.72);
    canvas.drawCircle(
      c,
      r * 0.98,
      Paint()
        ..color = muted.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _alloy(Canvas canvas, Offset c, double r) {
    final spoke = Paint()
      ..color = _metal
      ..strokeWidth = math.max(2.2, r * 0.22)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * (r * 0.82), spoke);
    }
    canvas.drawCircle(c, r * 0.28, Paint()..color = _metalDeep);
    canvas.drawCircle(c, r * 0.14, Paint()..color = _metal);
    final lug = Paint()..color = const Color(0xFF2C2C30);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5 + 0.18;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r * 0.16), r * 0.04, lug);
    }
  }

  @override
  bool shouldRepaint(covariant WheelCargoPainter oldDelegate) {
    return oldDelegate.cargo != cargo ||
        oldDelegate.selected != selected ||
        oldDelegate.dark != dark ||
        oldDelegate.accent != accent;
  }
}

class _StandFramePainter extends CustomPainter {
  _StandFramePainter({
    required this.steel,
    required this.fill,
    required this.floor,
    required this.sectors,
  });

  final Color steel;
  final Color fill;
  final Color floor;
  final int sectors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, Paint()..color = floor);
    final frame = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 6, size.width - 8, size.height - 10),
        const Radius.circular(10),
      ),
      frame,
    );
    final post = Paint()
      ..color = steel
      ..strokeWidth = 3;
    final n = sectors < 1 ? 1 : sectors;
    final step = (size.width - 8) / n;
    for (var i = 0; i <= n; i++) {
      final x = 4 + step * i;
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 8), post);
    }
    canvas.drawLine(
      Offset(8, size.height - 8),
      Offset(size.width - 8, size.height - 8),
      Paint()
        ..color = steel
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StandFramePainter oldDelegate) {
    return oldDelegate.steel != steel ||
        oldDelegate.fill != fill ||
        oldDelegate.floor != floor ||
        oldDelegate.sectors != sectors;
  }
}
