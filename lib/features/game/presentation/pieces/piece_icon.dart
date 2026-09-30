import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/art/game_art.dart';
import 'piece_renderer.dart';

/// A piece drawn as an icon, e.g. in the players' panels: the same stick or
/// pebble as on the board, with its shadow.
class PieceIcon extends StatelessWidget {
  const PieceIcon(this.piece, {super.key, this.size = 28});

  final Piece piece;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _PieceIconPainter(
        piece,
        context.boardPalette,
        GameArtScope.of(context),
      ),
    ),
  );
}

class _PieceIconPainter extends CustomPainter {
  _PieceIconPainter(this.piece, this.palette, this.art);

  final Piece piece;
  final BoardPalette palette;
  final GameArt? art;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stick = piece.owner == Player.white;
    // Fit the piece, and its shadow, in the square.
    final cell = side / (stick ? 0.9 : (piece.isSultan ? 1.0 : 0.8));
    final base = Offset(
      side * (stick ? 0.42 : 0.46),
      side * (stick ? 0.84 : (piece.isSultan ? 0.66 : 0.54)),
    );
    PieceRenderer.paintShadow(canvas, base, cell, piece, palette);
    PieceRenderer.paintBody(canvas, base, cell, piece, palette, art: art);
  }

  @override
  bool shouldRepaint(_PieceIconPainter oldDelegate) =>
      oldDelegate.piece != piece ||
      oldDelegate.palette != palette ||
      oldDelegate.art != art;
}
