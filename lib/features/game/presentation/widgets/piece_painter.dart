import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Draws a piece. The two sides differ by shape as well as colour: the light
/// side carries a stick (العيدان), the dark side a ring (a pellet, البعر);
/// a Sultan carries a golden crown.
void paintPiece(
  Canvas canvas,
  Offset center,
  double radius,
  Piece piece, {
  double opacity = 1,
  bool lifted = false,
}) {
  if (opacity <= 0) return;
  final bounds = Rect.fromCircle(center: center, radius: radius * 1.4);
  final layered = opacity < 1;
  if (layered) {
    canvas.saveLayer(
      bounds,
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0, 1)),
    );
  }
  final light = piece.owner == Player.white;
  final fill = light ? AppColors.lightPiece : AppColors.darkPiece;
  final edge = light ? AppColors.lightPieceEdge : AppColors.darkPieceEdge;
  final lift = lifted ? radius * 0.18 : radius * 0.1;

  canvas.drawCircle(
    center + Offset(0, lift),
    radius,
    Paint()
      ..color = const Color(0x5522170F)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
  );
  final body = Rect.fromCircle(center: center, radius: radius);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1,
        colors: [Color.lerp(fill, Colors.white, light ? 0.45 : 0.18)!, fill],
      ).createShader(body),
  );
  canvas.drawCircle(
    center,
    radius * 0.95,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..color = edge,
  );

  if (piece.isSultan) {
    canvas.drawCircle(
      center,
      radius * 0.76,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12
        ..color = AppColors.gold,
    );
    _paintCrown(canvas, center, radius);
  } else if (light) {
    final arm = radius * 0.42;
    canvas.drawLine(
      center + Offset(-arm, arm),
      center + Offset(arm, -arm),
      Paint()
        ..strokeWidth = radius * 0.2
        ..strokeCap = StrokeCap.round
        ..color = edge,
    );
  } else {
    canvas.drawCircle(
      center,
      radius * 0.38,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.14
        ..color = const Color(0xFF8B6A52),
    );
  }
  if (layered) canvas.restore();
}

void _paintCrown(Canvas canvas, Offset center, double radius) {
  Offset at(double x, double y) => center + Offset(x * radius, y * radius);
  final crown = Path()
    ..moveTo(at(-0.45, 0.28).dx, at(-0.45, 0.28).dy)
    ..lineTo(at(0.45, 0.28).dx, at(0.45, 0.28).dy)
    ..lineTo(at(0.48, -0.2).dx, at(0.48, -0.2).dy)
    ..lineTo(at(0.22, 0.02).dx, at(0.22, 0.02).dy)
    ..lineTo(at(0, -0.38).dx, at(0, -0.38).dy)
    ..lineTo(at(-0.22, 0.02).dx, at(-0.22, 0.02).dy)
    ..lineTo(at(-0.48, -0.2).dx, at(-0.48, -0.2).dy)
    ..close();
  canvas.drawPath(crown, Paint()..color = AppColors.goldLight);
  canvas.drawPath(
    crown,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.earth700,
  );
}

/// A piece drawn as an icon, e.g. in the players' panel.
class PieceIcon extends StatelessWidget {
  const PieceIcon(this.piece, {super.key, this.size = 28});

  final Piece piece;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PieceIconPainter(piece)),
  );
}

class _PieceIconPainter extends CustomPainter {
  _PieceIconPainter(this.piece);

  final Piece piece;

  @override
  void paint(Canvas canvas, Size size) {
    paintPiece(
      canvas,
      size.center(Offset.zero),
      size.shortestSide * 0.42,
      piece,
    );
  }

  @override
  bool shouldRepaint(_PieceIconPainter oldDelegate) =>
      oldDelegate.piece != piece;
}
