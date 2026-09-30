import '../board/direction.dart';
import '../board/position.dart';

/// One of the two sides.
///
/// White starts on rows 1–5 and advances towards row 9; Black starts on rows
/// 5–9 and advances towards row 1. The colour names follow the written
/// sources; traditionally one army is made of sticks (العيدان) and the other
/// of camel-dung pellets (البعر). Which side moves first is a rule setting
/// (`DhametRules.firstPlayer`).
enum Player {
  white(rowStep: 1, promotionRow: Position.size - 1),
  black(rowStep: -1, promotionRow: 0);

  const Player({required this.rowStep, required this.promotionRow});

  /// +1 if this player's pawns advance towards higher rows, -1 otherwise.
  final int rowStep;

  /// Row (0-based) on which this player's pawns become Sultans: the
  /// opponent's home row.
  final int promotionRow;

  /// The other side.
  Player get opponent => this == white ? black : white;

  /// Whether [direction] goes towards the opponent's side for this player.
  bool isForward(Direction direction) => direction.rowStep == rowStep;

  /// Whether [direction] goes towards this player's own side.
  bool isBackward(Direction direction) => direction.rowStep == -rowStep;
}
