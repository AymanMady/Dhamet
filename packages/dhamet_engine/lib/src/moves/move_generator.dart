import '../board/board.dart';
import '../board/board_topology.dart';
import '../board/position.dart';
import '../pieces/player.dart';
import '../rules/dhamet_rules.dart';
import '../state/game_state.dart';
import 'capture_resolver.dart';
import 'move.dart';
import 'piece_movement.dart';

/// Generates the legal moves of a position.
///
/// This is the single source of truth for legality: the user interface, the
/// AI and the server must all go through it.
///
/// ```text
/// if a capture is available (capture.mandatory)
///     return only the complete capture sequences taking the most pieces
///     (capture.maximum)
/// else
///     return the normal moves
/// ```
final class MoveGenerator {
  MoveGenerator(this.rules, {BoardTopology? topology})
    : topology = topology ?? BoardTopology.standard,
      captureResolver = CaptureResolver(rules, topology: topology),
      _movements = PieceMovements(topology ?? BoardTopology.standard, rules);

  /// A shared generator for [rules] on the standard board.
  factory MoveGenerator.forRules(DhametRules rules) =>
      _shared[rules] ??= MoveGenerator(rules);

  static final Map<DhametRules, MoveGenerator> _shared = {};

  final DhametRules rules;
  final BoardTopology topology;
  final CaptureResolver captureResolver;
  final PieceMovements _movements;

  /// The legal moves of the player to move in [state].
  List<Move> legalMoves(GameState state) =>
      legalMovesFor(state.board, state.currentPlayer);

  /// The legal moves of [player] on [board].
  List<Move> legalMovesFor(BoardView board, Player player) {
    final origins = [
      for (final position in Position.all)
        if (board.pieceAt(position)?.owner == player) position,
    ];
    final captures = _selectCaptures([
      for (final from in origins)
        ...captureResolver.captureSequencesFrom(board, from),
    ]);
    if (captures.isNotEmpty && rules.mandatoryCapture) return captures;
    return [
      ...captures,
      for (final from in origins) ..._normalMoves(board, from),
    ];
  }

  /// Whether [player] has at least one capture available on [board].
  bool hasCapture(BoardView board, Player player) => Position.all.any(
    (from) =>
        board.pieceAt(from)?.owner == player &&
        captureResolver.captureSequencesFrom(board, from).isNotEmpty,
  );

  List<Move> _selectCaptures(List<Move> captures) {
    if (captures.isEmpty || rules.captureChoice == CaptureChoice.free) {
      return captures;
    }
    var most = 0;
    for (final move in captures) {
      if (move.captureCount > most) most = move.captureCount;
    }
    return [
      for (final move in captures)
        if (move.captureCount == most) move,
    ];
  }

  List<Move> _normalMoves(BoardView board, Position from) {
    final piece = board.pieceAt(from)!;
    return [
      for (final to
          in _movements
              .of(piece.type)
              .normalDestinations(board, from, piece.owner))
        Move(
          piece: piece,
          from: from,
          path: [to],
          promotes: piece.isPawn && to.row == piece.owner.promotionRow,
        ),
    ];
  }
}
