import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';

/// Marks made in the sand with a finger. The board is seen slightly from
/// the front, so circles on the sand look like flattened ellipses.
const double sandPerspective = 0.82;

Rect _onSand(Offset center, double radius) => Rect.fromCenter(
  center: center,
  width: radius * 2,
  height: radius * 2 * sandPerspective,
);

/// A hollow pressed into the sand: dark inside, its far edge lit by the
/// sun. With [tint], a coloured dot marks its bottom.
void paintHollow(
  Canvas canvas,
  Offset center,
  double radius,
  BoardPalette palette, {
  double opacity = 1,
  Color? tint,
}) {
  if (opacity <= 0 || radius <= 0) return;
  final bounds = _onSand(center, radius);
  canvas.drawOval(
    bounds,
    Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(radius * 0.25, radius * 0.25),
        radius * 1.2,
        [
          palette.groove.withValues(alpha: 0.85 * opacity),
          palette.groove.withValues(alpha: 0.45 * opacity),
        ],
      ),
  );
  canvas.drawArc(
    bounds.inflate(radius * 0.06),
    -math.pi * 0.15,
    math.pi * 0.85,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.8, radius * 0.22)
      ..color = palette.sandLight.withValues(alpha: 0.9 * opacity),
  );
  if (tint != null) {
    canvas.drawOval(
      _onSand(center, radius * 0.45),
      Paint()..color = tint.withValues(alpha: 0.9 * opacity),
    );
  }
}

/// A ring traced in the sand around a piece, coloured with [color] like a
/// line of ochre or indigo powder. [dashes] breaks it into segments.
void paintTracedRing(
  Canvas canvas,
  Offset center,
  double radius,
  double width,
  Color color,
  BoardPalette palette, {
  int dashes = 0,
  double opacity = 1,
}) {
  if (opacity <= 0) return;
  final bounds = _onSand(center, radius);
  final lit = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width * 1.1
    ..color = palette.sandLight.withValues(alpha: 0.85 * opacity);
  final ink = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width
    ..color = color.withValues(alpha: 0.92 * opacity);
  final litBounds = bounds.shift(Offset(width * 0.45, width * 0.45));
  if (dashes <= 0) {
    canvas
      ..drawOval(litBounds, lit)
      ..drawOval(bounds, ink);
    return;
  }
  final sweep = math.pi / dashes;
  for (var i = 0; i < dashes; i++) {
    final start = i * 2 * sweep;
    canvas
      ..drawArc(litBounds, start, sweep, false, lit)
      ..drawArc(bounds, start, sweep, false, ink);
  }
}

/// The shallow track a piece leaves when it is dragged along [points].
void paintTrail(
  Canvas canvas,
  List<Offset> points,
  double width,
  BoardPalette palette,
  Color accent,
) {
  if (points.length < 2) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  canvas
    ..drawPath(
      path.shift(Offset(width * 0.12, width * 0.12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..color = palette.sandLight.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.15),
    )
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width * 0.8
        ..color = palette.sandShade.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.12),
    )
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1, width * 0.16)
        ..color = accent.withValues(alpha: 0.7),
    );
}

/// Text written in the sand: dark strokes with a lit lower edge.
TextStyle engravedStyle(BoardPalette palette, double fontSize) => TextStyle(
  fontFamily: AppTypography.displayFamily,
  color: palette.ink.withValues(alpha: 0.78),
  fontSize: fontSize,
  fontWeight: FontWeight.w700,
  shadows: [
    Shadow(
      color: palette.inkGlow.withValues(alpha: 0.7),
      offset: Offset(fontSize * 0.05, fontSize * 0.07),
    ),
  ],
);
