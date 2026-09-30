import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../../../app/theme/app_theme.dart';
import '../board/sand_marks.dart';

/// A puff of sand where a piece lands or is taken away: a ring of pushed
/// sand and a few grains thrown up. [progress] runs from 0 to 1.
void paintSandPuff(
  Canvas canvas,
  Offset center,
  double cell,
  double progress,
  BoardPalette palette, {
  int seed = 0,
}) {
  if (progress <= 0 || progress >= 1) return;
  final random = math.Random(seed);
  final fade = 1 - progress;
  final spread = Curves.easeOut.transform(progress);
  canvas.drawOval(
    Rect.fromCenter(
      center: center,
      width: cell * (0.35 + 0.55 * spread),
      height: cell * (0.35 + 0.55 * spread) * sandPerspective,
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.05 * fade
      ..color = palette.sandLight.withValues(alpha: 0.7 * fade),
  );
  final grain = Paint();
  for (var i = 0; i < 10; i++) {
    final angle = random.nextDouble() * math.pi * 2;
    final distance = cell * (0.15 + 0.35 * random.nextDouble()) * spread;
    final rise =
        cell * 0.2 * math.sin(math.pi * progress) * random.nextDouble();
    grain.color = (i.isEven ? palette.sandLight : palette.sandShade).withValues(
      alpha: 0.9 * fade,
    );
    canvas.drawCircle(
      center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance * sandPerspective - rise,
          ),
      cell * (0.018 + 0.02 * random.nextDouble()) * (0.6 + 0.4 * fade),
      grain,
    );
  }
}

/// The glint of a new Sultan: a golden ring spreading on the sand.
void paintCrowning(
  Canvas canvas,
  Offset center,
  double cell,
  double progress,
  Color gold,
) {
  if (progress <= 0 || progress >= 1) return;
  final spread = Curves.easeOut.transform(progress);
  final radius = cell * (0.3 + 0.55 * spread);
  canvas.drawOval(
    Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2 * sandPerspective,
    ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.07 * (1 - progress)
      ..color = gold.withValues(alpha: 0.85 * (1 - progress)),
  );
}
