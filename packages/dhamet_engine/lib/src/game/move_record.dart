import '../board/position.dart';
import '../moves/move.dart';
import '../pieces/piece.dart';
import '../pieces/player.dart';
import '../state/game_state.dart';

/// One move of a game's history, with the exact states before and after it.
///
/// Keeping both states makes undo and redo exact: nothing is recomputed or
/// reversed by hand.
final class MoveRecord {
  MoveRecord._({
    required this.move,
    required this.stateBefore,
    required this.stateAfter,
    required List<Piece> capturedPieces,
    required this.timestamp,
  }) : capturedPieces = List.unmodifiable(capturedPieces);

  /// Plays [move] in [stateBefore] and records it.
  ///
  /// Throws an `IllegalMoveException` if [move] is not legal there.
  factory MoveRecord.play(
    GameState stateBefore,
    Move move, {
    DateTime? timestamp,
  }) {
    final stateAfter = stateBefore.play(move);
    return MoveRecord._(
      move: move,
      stateBefore: stateBefore,
      stateAfter: stateAfter,
      capturedPieces: [
        for (final position in move.captured) stateBefore.board[position]!,
      ],
      timestamp: timestamp?.toUtc(),
    );
  }

  /// The move played.
  final Move move;

  /// The state in which [move] was played.
  final GameState stateBefore;

  /// The state resulting from [move].
  final GameState stateAfter;

  /// The pieces taken, in the order of [Move.captured].
  final List<Piece> capturedPieces;

  /// When the move was played (UTC), if the caller provided it.
  final DateTime? timestamp;

  /// 1-based number of this move among both players' moves.
  int get ply => stateBefore.plyCount + 1;

  /// Traditional move number: a move of each side per number.
  int get moveNumber => (ply + 1) ~/ 2;

  Player get player => move.player;

  Position get from => move.from;

  Position get to => move.to;

  /// The moving piece, before any promotion.
  Piece get piece => move.piece;

  /// Where the [capturedPieces] stood.
  List<Position> get capturedPositions => move.captured;

  /// Whether the pawn became a Sultan.
  bool get promoted => move.promotes;

  /// JSON representation. The states are not stored: they are rebuilt by
  /// replaying the moves, which also checks that the save is consistent.
  Map<String, Object?> toJson() => {
    'move': move.toJson(),
    'capturedPieces': [for (final piece in capturedPieces) piece.toJson()],
    'timestamp': timestamp?.toIso8601String(),
  };

  @override
  String toString() => '$ply. $move';
}
