import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/painting.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/art/game_art.dart';
import '../../../../core/utils/smooth_path.dart';
import '../board/board_geometry.dart';
import 'piece_look.dart';

/// Draws pieces standing on the sand, lit by the sun in the upper left.
///
/// The light side plays planted sticks and the dark side pebbles: the two
/// differ by shape, not only by colour. A Sultan gets a second piece, as
/// players do on the sand (docs/rules.md § 8): two crossed sticks bound with
/// an indigo cord, or a light pebble set on the dark one.
///
/// With [GameArt], the sticks and pebbles are those cut out of the reference
/// art; otherwise they are drawn.
///
/// [base] is the intersection and [cell] the distance between two
/// intersections. [lift] raises the piece off the sand, from 0 (planted) to
/// 1 (held in the hand). Shadows and bodies are painted separately so that
/// all the shadows of a layer fall on the sand, beneath every piece.
abstract final class PieceRenderer {
  static void paintShadow(
    Canvas canvas,
    Offset base,
    double cell,
    Piece piece,
    BoardPalette palette, {
    PieceLook look = PieceLook.plain,
    double lift = 0,
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final air = lift.clamp(0.0, 1.5);
    final paint = Paint()
      ..color = palette.shadow.withValues(
        alpha: 0.38 * (1 - 0.4 * air.clamp(0.0, 1.0)) * opacity,
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        cell * (0.02 + 0.05 * air),
      );
    final contact = air < 0.08
        ? (Paint()
            ..color = palette.shadow.withValues(alpha: 0.35 * opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.025))
        : null;
    final detach = BoardGeometry.shadowDirection * (cell * 0.45 * air);

    if (piece.owner == Player.white) {
      for (final stick in _sticks(piece, look)) {
        final foot = base + stick.offset * cell;
        final height = cell * _stickHeight * stick.length;
        final width = cell * _stickWidth;
        final start = foot + detach;
        // A leaning stick throws its shadow a little sideways.
        final end =
            start +
            BoardGeometry.shadowDirection * height +
            Offset(math.sin(stick.tilt) * height * 0.6, 0);
        final direction = (end - start) / (end - start).distance;
        final across = Offset(-direction.dy, direction.dx);
        canvas.drawPath(
          Path()
            ..moveTo(
              start.dx + across.dx * width * 0.5,
              start.dy + across.dy * width * 0.5,
            )
            ..lineTo(
              end.dx + across.dx * width * 0.2,
              end.dy + across.dy * width * 0.2,
            )
            ..lineTo(
              end.dx - across.dx * width * 0.2,
              end.dy - across.dy * width * 0.2,
            )
            ..lineTo(
              start.dx - across.dx * width * 0.5,
              start.dy - across.dy * width * 0.5,
            )
            ..close(),
          paint,
        );
        if (contact != null) {
          canvas.drawOval(
            Rect.fromCenter(
              center: foot + Offset(cell * 0.02, cell * 0.015),
              width: cell * 0.26,
              height: cell * 0.09,
            ),
            contact,
          );
        }
      }
      return;
    }

    final radius = cell * _pebbleRadius * look.size;
    final center = base + Offset(0, cell * 0.01);
    canvas.drawPath(
      _pebblePath(
        center + BoardGeometry.shadowDirection * (cell * 0.2) + detach,
        radius * (1 + 0.08 * air),
        look,
      ),
      paint,
    );
    if (contact != null) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(cell * 0.03, radius * 0.55),
          width: radius * 1.8,
          height: radius * 0.5,
        ),
        contact,
      );
    }
  }

  static void paintBody(
    Canvas canvas,
    Offset base,
    double cell,
    Piece piece,
    BoardPalette palette, {
    PieceLook look = PieceLook.plain,
    double lift = 0,
    double opacity = 1,
    double scale = 1,
    GameArt? art,
  }) {
    if (opacity <= 0) return;
    final layered = opacity < 1;
    if (layered) {
      canvas.saveLayer(
        Rect.fromCircle(center: base, radius: cell * 1.2),
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
      );
    }
    final raised = base - Offset(0, cell * 0.2 * lift);
    final scaled = scale != 1;
    if (scaled) {
      canvas
        ..save()
        ..translate(raised.dx, raised.dy)
        ..scale(scale)
        ..translate(-raised.dx, -raised.dy);
    }
    if (piece.owner == Player.white) {
      _paintSticks(
        canvas,
        base,
        raised,
        cell,
        piece,
        look,
        palette,
        lift,
        art?.stick,
      );
    } else {
      _paintPebbles(canvas, raised, cell, piece, look, art?.pebble);
    }
    if (scaled) canvas.restore();
    if (layered) canvas.restore();
  }

  /// Where the eye sees a piece: the middle of a stick, a pebble's centre.
  static Offset visualCenter(Offset base, double cell, Piece piece) =>
      piece.owner == Player.white
      ? base - Offset(0, cell * _stickHeight * 0.45)
      : base - Offset(0, cell * 0.03);

  static const double _stickHeight = 0.74;
  static const double _stickWidth = 0.19;
  static const double _pebbleRadius = 0.29;

  static List<_Stick> _sticks(Piece piece, PieceLook look) => piece.isSultan
      ? [
          _Stick(
            const Offset(-0.12, 0),
            0.3 + look.tilt * 0.4,
            look.length * 1.08,
          ),
          _Stick(
            const Offset(0.12, 0),
            -0.3 + look.tilt * 0.4,
            look.length * 1.05,
          ),
        ]
      : [_Stick(Offset.zero, look.tilt, look.length)];

  static void _paintSticks(
    Canvas canvas,
    Offset base,
    Offset raised,
    double cell,
    Piece piece,
    PieceLook look,
    BoardPalette palette,
    double lift,
    ui.Image? sprite,
  ) {
    final sticks = _sticks(piece, look);
    final planted = lift < 0.05;
    if (planted) {
      for (final stick in sticks) {
        _moundBack(canvas, base + stick.offset * cell, cell, palette);
      }
    }
    for (final stick in sticks) {
      final foot = raised + stick.offset * cell;
      if (sprite != null) {
        _paintStickSprite(
          canvas,
          foot,
          cell,
          stick,
          look,
          sprite,
          planted: planted,
        );
      } else {
        _paintStick(canvas, foot, cell, stick, look, planted: planted);
      }
    }
    if (planted) {
      for (final stick in sticks) {
        _moundFront(canvas, base + stick.offset * cell, cell, palette);
      }
    }
    if (piece.isSultan) _paintBinding(canvas, raised, cell, sticks);
  }

  /// The stick cut out of the reference art, standing on [foot].
  static void _paintStickSprite(
    Canvas canvas,
    Offset foot,
    double cell,
    _Stick stick,
    PieceLook look,
    ui.Image sprite, {
    required bool planted,
  }) {
    final height = cell * _stickHeight * stick.length;
    // A little thicker than the photo, to be seen and tapped.
    final width = height * sprite.width / sprite.height * 1.3;
    // Planted, the foot of the stick goes a little under the sand.
    final sink = planted ? width * 0.35 : 0.0;
    final destination = Rect.fromLTWH(-width / 2, sink - height, width, height);
    canvas
      ..save()
      ..translate(foot.dx, foot.dy)
      ..rotate(stick.tilt);
    // A thin dark edge keeps the light wood readable on the sand.
    _drawSprite(canvas, sprite, destination.inflate(cell * 0.014), _edge);
    _drawSprite(canvas, sprite, destination, _toneFilter(look.tone - 0.15));
    canvas.restore();
  }

  static void _paintStick(
    Canvas canvas,
    Offset foot,
    double cell,
    _Stick stick,
    PieceLook look, {
    required bool planted,
  }) {
    final height = cell * _stickHeight * stick.length;
    final width = cell * _stickWidth;
    final axis = Offset(math.sin(stick.tilt), -math.cos(stick.tilt));
    final normal = Offset(math.cos(stick.tilt), math.sin(stick.tilt));
    // Planted, the stick goes on a little under the sand.
    final bottom = planted ? foot - axis * (width * 0.3) : foot;
    final top = foot + axis * height;
    final tipStart = foot + axis * (height - width * 1.3);
    Offset at(Offset point, double side) => point + normal * (width * side);

    final body = _polygon([
      at(bottom, -0.5),
      at(bottom, 0.5),
      at(tipStart, 0.44),
      at(top, 0.1),
      at(top, -0.1),
      at(tipStart, -0.44),
    ]);
    final light = _toned(AppColors.woodLight, look.tone);
    final mid = _toned(AppColors.wood, look.tone);
    final dark = _toned(AppColors.woodDark, look.tone);
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          at(bottom, -0.5),
          at(bottom, 0.5),
          [light, mid, dark],
          const [0, 0.42, 1],
        ),
    );

    // Bark streaks and a knot.
    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.5, width * 0.08)
      ..color = AppColors.woodGrain.withValues(alpha: 0.42);
    for (final (side, reach) in [(-0.2, 0.7), (0.06, 0.55), (0.28, 0.8)]) {
      canvas.drawLine(
        at(foot + axis * (height * 0.06), side),
        at(
          foot + axis * (height * reach * (0.85 + 0.15 * look.knot)),
          side * 0.8,
        ),
        streak,
      );
    }
    final knot = at(foot + axis * (height * (0.25 + 0.4 * look.knot)), 0.08);
    canvas.drawOval(
      Rect.fromCenter(center: knot, width: width * 0.5, height: width * 0.34),
      Paint()..color = AppColors.woodGrain.withValues(alpha: 0.6),
    );

    // The carved, lighter tip.
    canvas.drawPath(
      _polygon([
        at(tipStart, 0.44),
        at(top, 0.1),
        at(top, -0.1),
        at(tipStart, -0.44),
      ]),
      Paint()
        ..shader = ui.Gradient.linear(at(tipStart, -0.44), at(tipStart, 0.44), [
          AppColors.woodCut,
          Color.lerp(AppColors.woodCut, AppColors.wood, 0.5)!,
        ]),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(0.8, width * 0.1)
        ..color = AppColors.woodGrain.withValues(alpha: 0.85),
    );
    if (!planted) {
      // Pulled out of the sand: the cut end shows.
      canvas.drawOval(
        Rect.fromCenter(center: bottom, width: width, height: width * 0.45),
        Paint()..color = Color.lerp(AppColors.woodCut, AppColors.wood, 0.3)!,
      );
    }
  }

  static Rect _mound(Offset foot, double cell) => Rect.fromCenter(
    center: foot + Offset(0, cell * 0.01),
    width: cell * 0.44,
    height: cell * 0.16,
  );

  /// The little heap of sand around a planted stick, and the hole it
  /// stands in.
  static void _moundBack(
    Canvas canvas,
    Offset foot,
    double cell,
    BoardPalette palette,
  ) {
    final rect = _mound(foot, cell);
    canvas
      ..drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            rect.center - Offset(cell * 0.04, cell * 0.02),
            rect.width / 2,
            [
              palette.sandLight.withValues(alpha: 0.95),
              palette.sandLight.withValues(alpha: 0.5),
              palette.sand.withValues(alpha: 0),
            ],
            const [0, 0.55, 1],
          ),
      )
      ..drawOval(
        Rect.fromCenter(center: foot, width: cell * 0.2, height: cell * 0.07),
        Paint()
          ..color = palette.groove.withValues(alpha: 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.01),
      );
  }

  /// The near lip of the heap, which hides the foot of the stick.
  static void _moundFront(
    Canvas canvas,
    Offset foot,
    double cell,
    BoardPalette palette,
  ) {
    final rect = _mound(foot, cell).deflate(cell * 0.03);
    canvas
      ..save()
      ..clipRect(
        Rect.fromLTRB(rect.left - 1, foot.dy, rect.right + 1, rect.bottom + 1),
      )
      ..drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, foot.dy),
            Offset(0, rect.bottom),
            [
              Color.lerp(palette.sandLight, palette.sand, 0.5)!,
              palette.sand.withValues(alpha: 0.9),
              palette.sandShade.withValues(alpha: 0),
            ],
            const [0, 0.6, 1],
          ),
      )
      ..restore();
  }

  /// The indigo cord that binds the two sticks of a Sultan where they cross.
  static void _paintBinding(
    Canvas canvas,
    Offset raised,
    double cell,
    List<_Stick> sticks,
  ) {
    Offset direction(_Stick stick) =>
        Offset(math.sin(stick.tilt), -math.cos(stick.tilt));
    final a = raised + sticks[0].offset * cell;
    final b = raised + sticks[1].offset * cell;
    final da = direction(sticks[0]);
    final db = direction(sticks[1]);
    double cross(Offset v, Offset w) => v.dx * w.dy - v.dy * w.dx;
    final denominator = cross(da, db);
    if (denominator.abs() < 1e-6) return;
    final knot = a + da * (cross(b - a, db) / denominator);
    final cord = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell * 0.045
      ..color = AppColors.indigo;
    final sheen = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell * 0.015
      ..color = AppColors.indigoLight;
    for (final dy in [-0.05, 0.0, 0.05]) {
      final left = knot + Offset(-cell * 0.1, cell * (dy - 0.012));
      final right = knot + Offset(cell * 0.1, cell * (dy + 0.012));
      canvas
        ..drawLine(left, right, cord)
        ..drawLine(
          left - Offset(0, cell * 0.01),
          right - Offset(0, cell * 0.01),
          sheen,
        );
    }
    canvas.drawCircle(
      knot + Offset(cell * 0.12, cell * 0.03),
      cell * 0.03,
      Paint()..color = AppColors.gold,
    );
  }

  static void _paintPebbles(
    Canvas canvas,
    Offset raised,
    double cell,
    Piece piece,
    PieceLook look,
    ui.Image? sprite,
  ) {
    final center = raised - Offset(0, cell * 0.03);
    final radius = cell * _pebbleRadius * look.size;
    if (sprite != null) {
      _paintPebbleSprites(canvas, center, radius, piece, look, sprite);
      return;
    }
    _paintPebble(
      canvas,
      center,
      radius,
      look,
      AppColors.stoneLight,
      AppColors.stone,
      AppColors.stoneDark,
    );
    if (!piece.isSultan) return;
    final topCenter = center - Offset(radius * 0.08, radius * 0.62);
    final topRadius = radius * 0.64;
    canvas
      ..save()
      ..clipPath(_pebblePath(center, radius, look))
      ..drawOval(
        Rect.fromCenter(
          center: topCenter + Offset(radius * 0.2, radius * 0.4),
          width: topRadius * 2.1,
          height: topRadius * 1.3,
        ),
        Paint()
          ..color = AppColors.stoneDark.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
      )
      ..restore();
    _paintPebble(
      canvas,
      topCenter,
      topRadius,
      PieceLook.fromSeed(look.speckles + 1),
      AppColors.quartzLight,
      AppColors.quartz,
      AppColors.quartzDark,
    );
  }

  /// The pebble cut out of the reference art; a Sultan carries a second,
  /// lighter one.
  static void _paintPebbleSprites(
    Canvas canvas,
    Offset center,
    double radius,
    Piece piece,
    PieceLook look,
    ui.Image sprite,
  ) {
    _paintPebbleSprite(canvas, center, radius, look, sprite);
    if (!piece.isSultan) return;
    final topCenter = center - Offset(radius * 0.08, radius * 0.66);
    final topRadius = radius * 0.64;
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(
          Rect.fromCenter(
            center: center,
            width: radius * 2.1,
            height: radius * 1.9,
          ),
        ),
      )
      ..drawOval(
        Rect.fromCenter(
          center: topCenter + Offset(radius * 0.2, radius * 0.42),
          width: topRadius * 2.1,
          height: topRadius * 1.3,
        ),
        Paint()
          ..color = AppColors.stoneDark.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
      )
      ..restore();
    _paintPebbleSprite(
      canvas,
      topCenter,
      topRadius,
      PieceLook.fromSeed(look.speckles + 1),
      sprite,
      filter: _quartz,
    );
  }

  static void _paintPebbleSprite(
    Canvas canvas,
    Offset center,
    double radius,
    PieceLook look,
    ui.Image sprite, {
    ColorFilter? filter,
  }) {
    final width = radius * 2.15;
    final height = width * sprite.height / sprite.width;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      // A slight turn only: the photo is lit from the upper left.
      ..rotate((look.rotation - math.pi) * 0.06);
    _drawSprite(
      canvas,
      sprite,
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      filter ?? _toneFilter(look.tone),
    );
    canvas.restore();
  }

  static void _drawSprite(
    Canvas canvas,
    ui.Image sprite,
    Rect destination,
    ColorFilter? filter,
  ) => canvas.drawImageRect(
    sprite,
    Offset.zero & Size(sprite.width.toDouble(), sprite.height.toDouble()),
    destination,
    Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = filter,
  );

  /// Lightens or darkens a photographed piece a little.
  static ColorFilter? _toneFilter(double tone) {
    if (tone == 0) return null;
    final k = 1 + tone * 0.8;
    return ColorFilter.matrix(<double>[
      k, 0, 0, 0, 0, //
      0, k, 0, 0, 0, //
      0, 0, k, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  static const _edge = ColorFilter.mode(Color(0xB3281A0E), BlendMode.srcIn);

  /// Turns the dark pebble into the light one stacked on a Sultan.
  static const _quartz = ColorFilter.matrix(<double>[
    0.32, 0.45, 0.1, 0, 105, //
    0.3, 0.47, 0.1, 0, 98, //
    0.28, 0.42, 0.12, 0, 86, //
    0, 0, 0, 1, 0, //
  ]);

  static void _paintPebble(
    Canvas canvas,
    Offset center,
    double radius,
    PieceLook look,
    Color light,
    Color mid,
    Color dark,
  ) {
    final path = _pebblePath(center, radius, look);
    final shade = _toned(dark, look.tone);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(
          center + Offset(-radius * 0.38, -radius * 0.42),
          radius * 1.45,
          [_toned(light, look.tone), _toned(mid, look.tone), shade],
          const [0, 0.45, 1],
        ),
    );
    canvas
      ..save()
      ..clipPath(path);
    final random = math.Random(look.speckles);
    final speck = Paint();
    for (var i = 0; i < 18; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = math.sqrt(random.nextDouble()) * radius;
      speck.color =
          (random.nextBool()
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF000000))
              .withValues(alpha: 0.07 + random.nextDouble() * 0.1);
      canvas.drawCircle(
        center +
            Offset(
              math.cos(angle) * distance,
              math.sin(angle) * distance * 0.84,
            ),
        radius * (0.03 + random.nextDouble() * 0.05),
        speck,
      );
    }
    final sheenCenter = center + Offset(-radius * 0.3, -radius * 0.36);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: sheenCenter,
          width: radius * 0.9,
          height: radius * 0.5,
        ),
        Paint()
          ..shader = ui.Gradient.radial(sheenCenter, radius * 0.45, [
            const Color(0x47FFFFFF),
            const Color(0x00FFFFFF),
          ]),
      )
      ..restore()
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.7, radius * 0.05)
          ..color = shade.withValues(alpha: 0.75),
      );
  }

  static Path _pebblePath(Offset center, double radius, PieceLook look) {
    final count = look.outline.length;
    return smoothClosedPath([
      for (var i = 0; i < count; i++)
        center +
            Offset(
                  math.cos(look.rotation + i * 2 * math.pi / count),
                  math.sin(look.rotation + i * 2 * math.pi / count) * 0.84,
                ) *
                (radius * look.outline[i] * 1.06),
    ]);
  }

  static Path _polygon(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Color _toned(Color color, double tone) => Color.lerp(
    color,
    tone > 0 ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
    tone.abs(),
  )!;
}

/// One stick of a piece: its foot relative to the intersection (in cells),
/// its lean and its relative length.
class _Stick {
  const _Stick(this.offset, this.tilt, this.length);

  final Offset offset;
  final double tilt;
  final double length;
}
