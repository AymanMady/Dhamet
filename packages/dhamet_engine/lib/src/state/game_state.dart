import '../board/board.dart';
import '../board/position.dart';
import '../errors.dart';
import '../moves/move.dart';
import '../moves/move_generator.dart';
import '../pieces/player.dart';
import '../rules/dhamet_rules.dart';

/// An immutable snapshot of a game: the board, the side to move and the
/// rules in force.
///
/// Playing a move returns a new state; the previous one is unchanged, which
/// makes history, undo and AI search straightforward.
final class GameState {
  GameState({
    required this.board,
    required this.currentPlayer,
    this.rules = DhametRules.standard,
    this.plyCount = 0,
    this.lastMove,
  });

  /// The traditional starting position with [DhametRules.firstPlayer] to
  /// move.
  factory GameState.initial({DhametRules rules = DhametRules.standard}) =>
      GameState(
        board: Board.initial(),
        currentPlayer: rules.firstPlayer,
        rules: rules,
      );

  final Board board;

  /// The side to move.
  final Player currentPlayer;

  final DhametRules rules;

  /// Number of moves played so far by both sides.
  final int plyCount;

  /// The move that led to this state, if any.
  final Move? lastMove;

  /// Every legal move of [currentPlayer]. Computed once, on first access.
  late final List<Move> legalMoves = List.unmodifiable(
    MoveGenerator.forRules(rules).legalMoves(this),
  );

  /// The legal moves of the piece on [from].
  List<Move> legalMovesFrom(Position from) => [
    for (final move in legalMoves)
      if (move.from == from) move,
  ];

  /// The legal moves described by [notation] (see [Move.matchesNotation]).
  List<Move> legalMovesMatching(String notation) => [
    for (final move in legalMoves)
      if (move.matchesNotation(notation)) move,
  ];

  bool isLegal(Move move) => legalMoves.contains(move);

  /// Whether the side to move has a capture to make.
  bool get mustCapture => legalMoves.any((move) => move.isCapture);

  /// The state after [move].
  ///
  /// Throws an [IllegalMoveException] if [move] is not one of [legalMoves].
  GameState play(Move move) {
    if (!isLegal(move)) {
      throw IllegalMoveException(move, _illegalReason(move));
    }
    return applyUnchecked(move);
  }

  /// The state after [move], without checking that it is legal.
  ///
  /// Only for moves taken from [legalMoves], e.g. inside an AI search where
  /// legality is already guaranteed.
  GameState applyUnchecked(Move move) => GameState(
    board: board.applyMove(move),
    currentPlayer: currentPlayer.opponent,
    rules: rules,
    plyCount: plyCount + 1,
    lastMove: move,
  );

  String _illegalReason(Move move) {
    if (move.player != currentPlayer) {
      return 'it is ${currentPlayer.name}\'s turn';
    }
    if (board.pieceAt(move.from) != move.piece) {
      return 'there is no ${move.piece.name} on ${move.from}';
    }
    if (mustCapture && !move.isCapture) {
      return 'a capture is mandatory';
    }
    if (move.isCapture &&
        legalMoves.any((m) => m.captureCount > move.captureCount)) {
      return 'a sequence capturing more pieces is available';
    }
    return 'the rules do not allow it';
  }
}
