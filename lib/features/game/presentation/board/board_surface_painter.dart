import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/smooth_path.dart';
import '../../../../core/widgets/sand/sand_texture.dart';
import 'board_geometry.dart';
import 'sand_marks.dart';

/// The static part of the board: a patch of sand smoothed by hand, the
/// lines traced in it with a finger and a small hollow at each
/// intersection. It changes only with the size or the theme, so the board
/// paints it in its own cached layer.
class BoardSurfacePainter extends CustomPainter {
  const BoardSurfacePainter({
    required this.geometry,
    required this.palette,
    this.showCoordinates = false,
    this.sand,
  });

  final BoardGeometry geometry;
  final BoardPalette palette;
  final bool showCoordinates;

  /// The sand texture of the reference art; without it, the sand is drawn.
  final ui.Image? sand;

  double get _cell => geometry.cell;

  @override
  void paint(Canvas canvas, Size size) {
    final patch = _patch();
    _paintPatch(canvas, patch);
    _paintGrooves(canvas);
    _paintHollows(canvas);
    if (showCoordinates) _paintCoordinates(canvas);
  }

  /// The smoothed area: a rounded square whose edge wanders a little.
  Path _patch() {
    final inset = _cell * 0.1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      geometry.size - 2 * inset,
      geometry.size - 2 * inset,
    );
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(_cell * 0.9)));
    final metric = outline.computeMetrics().first;
    const samples = 72;
    return smoothClosedPath([
      for (var i = 0; i < samples; i++)
        () {
          final tangent = metric.getTangentForOffset(
            metric.length * i / samples,
          )!;
          final normal = Offset(tangent.vector.dy, -tangent.vector.dx);
          final t = i / samples * 2 * math.pi;
          final wobble =
              _cell * (0.07 * math.sin(3 * t + 0.7) + 0.04 * math.sin(8 * t));
          return tangent.position + normal * wobble;
        }(),
    ]);
  }

  void _paintPatch(Canvas canvas, Path patch) {
    // Sand pushed aside while smoothing forms a low rim around the patch.
    canvas
      ..drawPath(
        patch.shift(Offset(_cell * 0.07, _cell * 0.09)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _cell * 0.22
          ..color = palette.shadow.withValues(alpha: 0.16)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _cell * 0.12),
      )
      ..drawPath(
        patch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _cell * 0.3
          ..color = palette.sandLight.withValues(alpha: 0.75)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _cell * 0.1),
      );
    canvas.save();
    canvas.clipPath(patch);
    final area = Offset.zero & Size.square(geometry.size);
    final sand = this.sand;
    if (sand != null) {
      // Tiled about twice across the board.
      paintSandImage(canvas, area, sand, palette, tile: geometry.size / 2);
    } else {
      paintSand(
        canvas,
        area,
        palette.copyWith(
          sand: Color.lerp(palette.sand, palette.sandLight, 0.12),
        ),
        seed: 11,
        ripples: 0.15,
        stones: 0.2,
      );
    }
    // The patch lies a little lower than its rim.
    canvas.drawPath(
      patch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cell * 0.25
        ..color = palette.shadow.withValues(alpha: 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _cell * 0.14),
    );
    canvas.restore();
  }

  void _paintGrooves(Canvas canvas) {
    for (final line in tracedLines(BoardTopology.standard)) {
      _paintGroove(canvas, line);
    }
  }

  /// A finger-traced groove: its near wall in shadow, its far wall lit, and
  /// a little sand heaped along both sides. The lines are not ruled: they
  /// waver and run slightly past the last intersections.
  void _paintGroove(Canvas canvas, TracedLine line) {
    final start = geometry.center(line.from);
    final end = geometry.center(line.to);
    final length = (end - start).distance;
    if (length == 0) return;
    final along = (end - start) / length;
    final across = Offset(-along.dy, along.dx);
    final overshoot = _cell * (line.isDiagonal ? 0.06 : 0.28);
    final random = math.Random(line.seed);
    final phase1 = random.nextDouble() * math.pi * 2;
    final phase2 = random.nextDouble() * math.pi * 2;
    final path = Path();
    final total = length + 2 * overshoot;
    final steps = math.max(2, (total / (_cell * 0.2)).ceil());
    for (var i = 0; i <= steps; i++) {
      final distance = -overshoot + total * i / steps;
      final t = distance / _cell;
      final wobble =
          _cell *
          (0.016 * math.sin(t * 1.3 + phase1) +
              0.01 * math.sin(t * 3.7 + phase2));
      final point = start + along * distance + across * wobble;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    // Lines not traditionally traced in the sand are shallower.
    final depth = line.traditionallyUndrawn ? 0.5 : 1.0;
    final width = _cell * (line.traditionallyUndrawn ? 0.05 : 0.075);
    final toSun = Offset(-width * 0.32, -width * 0.32);
    Paint stroke(double w, Color color, {double blur = 0}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w
      ..color = color
      ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

    canvas
      ..drawPath(
        path,
        stroke(
          width * 2.6,
          palette.sandLight.withValues(alpha: 0.4 * depth),
          blur: width * 0.6,
        ),
      )
      ..drawPath(
        path.shift(-toSun),
        stroke(width, palette.sandLight.withValues(alpha: 0.75 * depth)),
      )
      ..drawPath(
        path,
        stroke(width * 0.8, palette.groove.withValues(alpha: 0.5 * depth)),
      )
      ..drawPath(
        path.shift(toSun),
        stroke(width * 0.45, palette.shadow.withValues(alpha: 0.28 * depth)),
      );
  }

  void _paintHollows(Canvas canvas) {
    for (final position in Position.all) {
      paintHollow(canvas, geometry.center(position), _cell * 0.065, palette);
    }
  }

  void _paintCoordinates(Canvas canvas) {
    final style = engravedStyle(palette, _cell * 0.26);
    void label(String text, Offset center) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final bottomRow = geometry.flipped ? 8 : 0;
    final leftColumn = geometry.flipped ? 8 : 0;
    for (var i = 0; i < 9; i++) {
      final columnPoint = geometry.center(Position(i, bottomRow));
      label(
        String.fromCharCode(0x61 + i),
        columnPoint + Offset(_cell * 0.22, _cell * 0.45),
      );
      final rowPoint = geometry.center(Position(leftColumn, i));
      label('${i + 1}', rowPoint - Offset(_cell * 0.45, _cell * 0.22));
    }
  }

  @override
  bool shouldRepaint(BoardSurfacePainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.palette != palette ||
      oldDelegate.showCoordinates != showCoordinates ||
      oldDelegate.sand != sand;
}

/// A straight line of the board, from one edge intersection to the other.
class TracedLine {
  const TracedLine(
    this.from,
    this.to, {
    required this.isDiagonal,
    required this.traditionallyUndrawn,
    required this.seed,
  });

  final Position from;
  final Position to;
  final bool isDiagonal;

  /// Rows 2, 4, 6, 8 and columns b, d, f, h are often not traced in the
  /// sand (see docs/rules.md § 3); they are drawn shallower.
  final bool traditionallyUndrawn;

  /// Makes the line's hand-drawn wobble its own.
  final int seed;
}

/// Groups the segments of [topology] into full lines, so that each line is
/// traced in one stroke, as a finger would.
List<TracedLine> tracedLines(BoardTopology topology) {
  final groups = <String, Set<Position>>{};
  for (final (a, b) in topology.segments) {
    final dc = b.column - a.column;
    final dr = b.row - a.row;
    final key = dr == 0
        ? 'h${a.row}'
        : dc == 0
        ? 'v${a.column}'
        : dc == dr
        ? 'd${a.column - a.row}'
        : 'a${a.column + a.row}';
    (groups[key] ??= {})
      ..add(a)
      ..add(b);
  }
  final keys = groups.keys.toList()..sort();
  return [
    for (final (index, key) in keys.indexed)
      () {
        final points = groups[key]!.toList()
          ..sort(
            (p, q) => p.column != q.column
                ? p.column.compareTo(q.column)
                : p.row.compareTo(q.row),
          );
        final kind = key[0];
        final number = int.parse(key.substring(1));
        return TracedLine(
          points.first,
          points.last,
          isDiagonal: kind == 'd' || kind == 'a',
          traditionallyUndrawn: (kind == 'h' || kind == 'v') && number.isOdd,
          seed: 31 * index + 7,
        );
      }(),
  ];
}
