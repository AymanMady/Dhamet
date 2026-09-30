import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../app/theme/app_theme.dart';
import '../../art/game_art.dart';
import '../rasterized_paint.dart';
import 'sand_texture.dart';

/// The scene behind the game: the game scene of the reference art (sand,
/// mud-brick walls out of focus), cropped to cover the screen. Before the
/// art is loaded, and in tests, a drawn scene stands in: sand everywhere
/// and, with [horizon], a blurred strip of sky and walls at the top.
class SandBackground extends StatelessWidget {
  const SandBackground({super.key, required this.child, this.horizon = true});

  final Widget child;
  final bool horizon;

  @override
  Widget build(BuildContext context) {
    final palette = context.boardPalette;
    final scene = GameArtScope.of(context)?.scene;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: scene != null
              ? CustomPaint(
                  painter: ScenePhotoPainter(image: scene, palette: palette),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => RasterizedPaint(
                    painter: SandScenePainter(
                      palette: palette,
                      horizon: horizon,
                    ),
                    size: constraints.biggest,
                  ),
                ),
        ),
        child,
      ],
    );
  }
}

/// The photograph of the scene, covering the whole area, tinted for the
/// theme, with a soft vignette that keeps the eye on the middle.
class ScenePhotoPainter extends CustomPainter {
  const ScenePhotoPainter({required this.image, required this.palette});

  final ui.Image image;
  final BoardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.cover,
      // Keep the walls in view when the height is cropped.
      alignment: const Alignment(0.1, -0.3),
      filterQuality: FilterQuality.medium,
    );
    if (palette.dusk.a > 0) {
      canvas.drawRect(rect, Paint()..color = palette.dusk);
    }
    _paintVignette(canvas, rect, palette);
  }

  @override
  bool shouldRepaint(ScenePhotoPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.palette != palette;
}

void _paintVignette(Canvas canvas, Rect rect, BoardPalette palette) {
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        rect.center,
        rect.longestSide * 0.75,
        [
          palette.shadow.withValues(alpha: 0),
          palette.shadow.withValues(alpha: 0.2),
        ],
        const [0.55, 1],
      ),
  );
}

class SandScenePainter extends CustomPainter {
  const SandScenePainter({required this.palette, this.horizon = true});

  final BoardPalette palette;
  final bool horizon;

  /// Height of the blurred horizon for a scene of [size].
  static double horizonHeight(Size size) =>
      (size.height * 0.13).clamp(64.0, 150.0);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintSand(canvas, rect, palette, seed: 3);
    if (horizon) _paintHorizon(canvas, size);
    _paintVignette(canvas, rect, palette);
  }

  void _paintHorizon(Canvas canvas, Size size) {
    final height = horizonHeight(size);
    final random = math.Random(5);
    final base = height * 0.92;
    final hazeBottom = base + height * 0.6;
    // Sky, then haze melting into the far sand: no hard edge anywhere.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, hazeBottom),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, hazeBottom),
          [
            palette.sky,
            Color.lerp(palette.sky, palette.haze, 0.85)!,
            Color.lerp(palette.haze, palette.sand, 0.4)!,
            palette.sand.withValues(alpha: 0),
          ],
          [0, 0.5, base / hazeBottom, 1],
        ),
    );
    // Flat-roofed mud-brick houses, out of focus.
    final blur = MaskFilter.blur(BlurStyle.normal, height * 0.05);
    var x = -random.nextDouble() * 40;
    while (x < size.width) {
      final width = height * (0.9 + random.nextDouble() * 1.6);
      final wallHeight = height * (0.35 + random.nextDouble() * 0.45);
      final tone = Color.lerp(
        palette.wall,
        random.nextBool() ? palette.haze : palette.shadow,
        random.nextDouble() * 0.25,
      )!;
      canvas.drawRect(
        Rect.fromLTWH(x, base - wallHeight, width, wallHeight),
        Paint()
          ..color = tone
          ..maskFilter = blur,
      );
      if (random.nextDouble() < 0.5) {
        final doorWidth = width * 0.16;
        canvas.drawRect(
          Rect.fromLTWH(
            x + width * (0.2 + random.nextDouble() * 0.5),
            base - wallHeight * 0.62,
            doorWidth,
            wallHeight * 0.62,
          ),
          Paint()
            ..color = palette.shadow.withValues(alpha: 0.5)
            ..maskFilter = blur,
        );
      }
      x += width + random.nextDouble() * height * 0.8;
    }
    // Haze and far sand over the foot of the walls.
    final hazeTop = base - height * 0.25;
    canvas.drawRect(
      Rect.fromLTRB(0, hazeTop, size.width, hazeBottom),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, hazeTop),
          Offset(0, hazeBottom),
          [
            palette.haze.withValues(alpha: 0),
            Color.lerp(palette.haze, palette.sand, 0.55)!,
            palette.sand.withValues(alpha: 0),
          ],
          [0, (base - hazeTop) / (hazeBottom - hazeTop), 1],
        ),
    );
  }

  @override
  bool shouldRepaint(SandScenePainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.horizon != horizon;
}
