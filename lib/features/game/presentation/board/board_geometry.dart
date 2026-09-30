import 'dart:ui';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/foundation.dart';

/// Maps intersections to pixels on a square board of side [size], seen from
/// above with the sun in the upper left.
@immutable
class BoardGeometry {
  const BoardGeometry(this.size, {this.flipped = false});

  final double size;

  /// Black's side at the bottom.
  final bool flipped;

  static const double _marginInCells = 0.7;

  /// Direction of cast shadows, per unit of height above the sand.
  static const Offset shadowDirection = Offset(0.62, 0.36);

  double get cell => size / (8 + 2 * _marginInCells);

  double get margin => cell * _marginInCells;

  /// Radius of a pebble.
  double get pieceRadius => cell * 0.29;

  /// Height of a planted stick above the sand.
  double get stickHeight => cell * 0.74;

  Offset center(Position position) {
    final column = flipped ? 8 - position.column : position.column;
    final row = flipped ? position.row : 8 - position.row;
    return Offset(margin + column * cell, margin + row * cell);
  }

  /// The intersection under [offset], or `null` outside the board.
  ///
  /// With [board], a tap on the upper part of a planted stick, which rises
  /// above its intersection, selects that stick.
  Position? positionAt(Offset offset, {Board? board}) {
    final column = ((offset.dx - margin) / cell).round();
    final row = ((offset.dy - margin) / cell).round();
    final nearest = _atScreen(column, row);
    final distance = nearest == null
        ? double.infinity
        : (center(nearest) - offset).distance;
    if (board != null && distance > cell * 0.3) {
      final below = _atScreen(column, ((offset.dy - margin) / cell).ceil());
      if (below != null && board[below]?.owner == Player.white) {
        final base = center(below);
        final rise = base.dy - offset.dy;
        if ((offset.dx - base.dx).abs() <= cell * 0.28 &&
            rise >= 0 &&
            rise <= stickHeight * 1.12) {
          return below;
        }
      }
    }
    return distance <= cell * 0.75 ? nearest : null;
  }

  Position? _atScreen(int column, int row) =>
      Position.tryAt(flipped ? 8 - column : column, flipped ? row : 8 - row);

  @override
  bool operator ==(Object other) =>
      other is BoardGeometry && other.size == size && other.flipped == flipped;

  @override
  int get hashCode => Object.hash(size, flipped);
}
