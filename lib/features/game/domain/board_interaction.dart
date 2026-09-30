import 'package:dhamet_engine/dhamet_engine.dart';

/// What a tap on the board means, given the legal moves.
sealed class TapOutcome {
  const TapOutcome();
}

/// Select the piece on [position].
final class SelectPiece extends TapOutcome {
  const SelectPiece(this.position);
  final Position position;
}

/// Clear the selection.
final class ClearSelection extends TapOutcome {
  const ClearSelection();
}

/// Play [move].
final class PlayMove extends TapOutcome {
  const PlayMove(this.move);
  final Move move;
}

/// Several capture sequences end on the tapped intersection: the player
/// must choose one.
final class ChooseMove extends TapOutcome {
  const ChooseMove(this.moves);
  final List<Move> moves;
}

/// Keeps one move per distinct outcome: capture sequences that take the
/// same pieces and end on the same point lead to the same position, so the
/// player does not need to choose between them. A flying Sultan can have
/// thousands of such equivalent paths.
List<Move> distinctOutcomes(Iterable<Move> moves) {
  final seen = <String>{};
  return [
    for (final move in moves)
      if (seen.add(
        '${move.to.index}|${move.promotes}|'
        '${(move.captured.map((p) => p.index).toList()..sort()).join(',')}',
      ))
        move,
  ];
}

/// Interprets a tap on [tapped] when [selected] is the selected piece.
///
/// A highlighted destination plays the move (or asks to choose among the
/// sequences ending there that take different pieces); a piece that can
/// move is selected; anything else clears the selection. Only moves from
/// [GameState.legalMoves] are ever proposed.
TapOutcome resolveTap(GameState state, Position? selected, Position tapped) {
  if (selected != null) {
    final toTarget = distinctOutcomes([
      for (final move in state.legalMovesFrom(selected))
        if (move.to == tapped) move,
    ]);
    if (toTarget.length == 1) return PlayMove(toTarget.single);
    if (toTarget.length > 1) return ChooseMove(toTarget);
  }
  final canMove = state.legalMoves.any((move) => move.from == tapped);
  if (canMove && tapped != selected) return SelectPiece(tapped);
  return const ClearSelection();
}
