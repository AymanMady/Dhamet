import '../rules/draw_rules.dart';
import '../state/game_state.dart';
import 'game_result.dart';

/// Reads from a position whether the game is over.
///
/// - Elimination (`end.elimination`, CONFIRMED): a side without pieces
///   loses.
/// - Blocking (`end.blocked`, CONFIRMED): the side to move, with pieces but
///   no legal move, loses.
/// - Repetition (`end.draw`, NEEDS_VERIFICATION): only when
///   [DrawRules.repetitionLimit] is set; disabled by default.
///
/// Declared ends (resignation, agreement, timeout) are not read from the
/// position; see `Game`.
final class GameEndDetector {
  const GameEndDetector();

  /// The result of the game in [state], or `null` if it goes on.
  ///
  /// [previousStates] are the states that led to [state], used only for the
  /// optional repetition rule. Throws a [StateError] if the board is empty.
  GameResult? detect(
    GameState state, {
    Iterable<GameState> previousStates = const [],
  }) {
    final toMove = state.currentPlayer;
    final ownPieces = state.board.count(toMove);
    final opponentPieces = state.board.count(toMove.opponent);
    if (ownPieces == 0 && opponentPieces == 0) {
      throw StateError('There is no piece on the board');
    }
    if (ownPieces == 0) {
      return GameResult.win(toMove.opponent, GameEndReason.elimination);
    }
    if (opponentPieces == 0) {
      return GameResult.win(toMove, GameEndReason.elimination);
    }
    if (state.legalMoves.isEmpty) {
      return GameResult.win(toMove.opponent, GameEndReason.blocked);
    }
    final limit = state.rules.draw.repetitionLimit;
    if (limit != null) {
      var occurrences = 1;
      for (final previous in previousStates) {
        if (previous.currentPlayer == toMove && previous.board == state.board) {
          occurrences++;
        }
      }
      if (occurrences >= limit) {
        return const GameResult.draw(GameEndReason.repetition);
      }
    }
    return null;
  }
}
