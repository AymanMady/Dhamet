import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../app/theme/app_theme.dart';

/// Paints sand in [rect]: a sunlit base, soft lighter and darker patches,
/// wind ripples, fine grains and a few small stones. Everything derives
/// from [seed], so a static layer always looks the same.
///
/// [ripples] and [stones] (0 to 1) set how marked the ripples are and how
/// many stones lie around: the playing area, smoothed by hand, has fewer of
/// both than the sand around it.
void paintSand(
  Canvas canvas,
  Rect rect,
  BoardPalette palette, {
  int seed = 1,
  double ripples = 1,
  double stones = 1,
}) {
  if (rect.isEmpty) return;
  final random = math.Random(seed);

  // The sun is in the upper left.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          Color.lerp(palette.sand, palette.sandLight, 0.3)!,
          palette.sand,
          Color.lerp(palette.sand, palette.sandShade, 0.3)!,
        ],
        const [0, 0.55, 1],
      ),
  );

  final area = rect.width * rect.height;
  final patch = Paint();
  final patches = (area / 6000).clamp(6, 140).round();
  for (var i = 0; i < patches; i++) {
    final center = _pointIn(rect, random);
    final radius = rect.shortestSide * (0.05 + random.nextDouble() * 0.16);
    final color = random.nextBool() ? palette.sandLight : palette.sandShade;
    final alpha = 0.08 + random.nextDouble() * 0.14;
    patch.shader = ui.Gradient.radial(center, radius, [
      color.withValues(alpha: alpha),
      color.withValues(alpha: 0),
    ]);
    canvas.drawCircle(center, radius, patch);
  }

  canvas.save();
  canvas.clipRect(rect);
  if (ripples > 0) _paintRipples(canvas, rect, palette, random, ripples);
  _paintGrains(canvas, rect, palette, random);
  if (stones > 0) _paintStones(canvas, rect, palette, random, stones);
  canvas.restore();
}

Offset _pointIn(Rect rect, math.Random random) => Offset(
  rect.left + random.nextDouble() * rect.width,
  rect.top + random.nextDouble() * rect.height,
);

/// Wind ripples: broken, roughly parallel crests, lit on one side.
void _paintRipples(
  Canvas canvas,
  Rect rect,
  BoardPalette palette,
  math.Random random,
  double strength,
) {
  final crest = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2
    ..color = palette.sandLight.withValues(alpha: 0.3 * strength)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7);
  final trough = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6
    ..color = palette.sandShade.withValues(alpha: 0.26 * strength)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7);
  final slope = (random.nextDouble() - 0.5) * 0.16;
  var y = rect.top - 6.0;
  while (y < rect.bottom + 6) {
    var x = rect.left - random.nextDouble() * 80;
    while (x < rect.right) {
      final length = 50 + random.nextDouble() * 190;
      final amplitude = 1.5 + random.nextDouble() * 3.5;
      final wavelength = 40 + random.nextDouble() * 70;
      final phase = random.nextDouble() * math.pi * 2;
      final path = Path();
      for (var dx = 0.0; dx <= length; dx += 5) {
        // Thin at both ends, like a real crest.
        final envelope = math.sin(math.pi * dx / length);
        final point = Offset(
          x + dx,
          y +
              slope * (x + dx - rect.left) +
              envelope *
                  amplitude *
                  math.sin(dx / wavelength * 2 * math.pi + phase),
        );
        if (dx == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas
        ..drawPath(path, crest)
        ..drawPath(path.shift(const Offset(0.6, 1.7)), trough);
      x += length + 10 + random.nextDouble() * 60;
    }
    y += 9 + random.nextDouble() * 10;
  }
}

/// Fine grains: dark and light specks, and a few quartz glints.
void _paintGrains(
  Canvas canvas,
  Rect rect,
  BoardPalette palette,
  math.Random random,
) {
  final count = (rect.width * rect.height / 7).clamp(0, 120000).round();
  final glint = Color.lerp(palette.sandLight, const Color(0xFFFFFFFF), 0.6)!;
  final batches = <(Color, double, double, double)>[
    // Colour, share of the grains, opacity, size.
    (palette.grain, 0.34, 0.45, 0.75),
    (palette.sandShade, 0.28, 0.55, 0.95),
    (palette.sandLight, 0.28, 0.7, 0.95),
    (glint, 0.10, 0.75, 0.7),
  ];
  final paint = Paint()..strokeCap = StrokeCap.round;
  for (final (color, share, alpha, size) in batches) {
    final n = (count * share).round();
    final points = Float32List(n * 2);
    for (var i = 0; i < n; i++) {
      points[2 * i] = rect.left + random.nextDouble() * rect.width;
      points[2 * i + 1] = rect.top + random.nextDouble() * rect.height;
    }
    paint
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = size;
    canvas.drawRawPoints(ui.PointMode.points, points, paint);
  }
}

/// Small stones and bits of gravel, each with its shadow.
void _paintStones(
  Canvas canvas,
  Rect rect,
  BoardPalette palette,
  math.Random random,
  double amount,
) {
  final count = (rect.width * rect.height / 7000 * amount).round();
  final shadow = Paint()..color = palette.shadow.withValues(alpha: 0.28);
  final light = Paint()..color = palette.sandLight.withValues(alpha: 0.55);
  final body = Paint();
  for (var i = 0; i < count; i++) {
    final center = _pointIn(rect, random);
    final radius = 0.8 + math.pow(random.nextDouble(), 2) * 2.6;
    final stretch = 1.1 + random.nextDouble() * 0.5;
    body.color = Color.lerp(
      palette.grain,
      palette.sandShade,
      random.nextDouble(),
    )!;
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: center + Offset(radius * 0.55, radius * 0.45),
          width: radius * 2 * stretch,
          height: radius * 1.5,
        ),
        shadow,
      )
      ..drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 * stretch,
          height: radius * 1.6,
        ),
        body,
      )
      ..drawCircle(
        center - Offset(radius * 0.4, radius * 0.35),
        radius * 0.45,
        light,
      );
  }
}

/// Paints the sand texture of the reference art in [rect], each tile
/// [tile] pixels wide, lit by the sun in the upper left and tinted for the
/// theme.
void paintSandImage(
  Canvas canvas,
  Rect rect,
  ui.Image image,
  BoardPalette palette, {
  required double tile,
}) {
  final scale = tile / image.width;
  canvas
    ..drawRect(
      rect,
      Paint()
        ..shader = ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.diagonal3Values(scale, scale, 1).storage,
          filterQuality: FilterQuality.medium,
        ),
    )
    ..drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            palette.sandLight.withValues(alpha: 0.16),
            palette.sand.withValues(alpha: 0),
            palette.sandShade.withValues(alpha: 0.18),
          ],
          const [0, 0.5, 1],
        ),
    );
  if (palette.dusk.a > 0) canvas.drawRect(rect, Paint()..color = palette.dusk);
}

/// Paints the sand texture of the reference art over its whole area.
class SandImagePainter extends CustomPainter {
  const SandImagePainter({
    required this.image,
    required this.palette,
    this.tile = 256,
  });

  final ui.Image image;
  final BoardPalette palette;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) =>
      paintSandImage(canvas, Offset.zero & size, image, palette, tile: tile);

  @override
  bool shouldRepaint(SandImagePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.palette != palette ||
      oldDelegate.tile != tile;
}

/// Paints sand over its whole area; see [paintSand].
class SandPainter extends CustomPainter {
  const SandPainter({
    required this.palette,
    this.seed = 1,
    this.ripples = 1,
    this.stones = 1,
  });

  final BoardPalette palette;
  final int seed;
  final double ripples;
  final double stones;

  @override
  void paint(Canvas canvas, Size size) => paintSand(
    canvas,
    Offset.zero & size,
    palette,
    seed: seed,
    ripples: ripples,
    stones: stones,
  );

  @override
  bool shouldRepaint(SandPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.seed != seed ||
      oldDelegate.ripples != ripples ||
      oldDelegate.stones != stones;
}
