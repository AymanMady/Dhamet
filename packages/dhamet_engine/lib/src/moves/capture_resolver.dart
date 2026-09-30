import '../board/board.dart';
import '../board/board_topology.dart';
import '../board/direction.dart';
import '../board/position.dart';
import '../pieces/piece.dart';
import '../pieces/player.dart';
import '../rules/dhamet_rules.dart';
import 'move.dart';
import 'piece_movement.dart';

/// Finds the complete capture sequences ("rafles") of a piece.
///
/// A sequence is complete when the piece has no further capture available:
/// a player may not stop a rafle half-way. The capturing piece leaves its
/// starting intersection, which is therefore empty during the sequence.
/// Captured pieces are removed immediately or at the end of the sequence
/// depending on [DhametRules.capturedPieceRemoval].
///
/// Promotion (`promotion.notDuringCapture`, CONFIRMED): a pawn is promoted
/// only if the sequence *ends* on its promotion row; passing through it does
/// not promote and the pawn keeps capturing as a pawn.
///
/// Choosing among sequences (majority rule) is done by `MoveGenerator`.
final class CaptureResolver {
  CaptureResolver(this.rules, {BoardTopology? topology})
    : topology = topology ?? BoardTopology.standard,
      _movements = PieceMovements(topology ?? BoardTopology.standard, rules);

  final DhametRules rules;
  final BoardTopology topology;
  final PieceMovements _movements;

  /// Every complete capture sequence of the piece on [from], or an empty
  /// list if it cannot capture (or if [from] is empty).
  List<Move> captureSequencesFrom(BoardView board, Position from) {
    final piece = board.pieceAt(from);
    if (piece == null) return const [];
    final movement = _movements.of(piece.type);
    // The first jump does not depend on the piece having left [from], so
    // most pieces are ruled out without copying the board.
    if (movement.captureSteps(board, from, piece.owner).isEmpty) {
      return const [];
    }
    final search = _SearchBoard(board, rules.capturedPieceRemoval)
      ..vacate(from);
    final sequences = <Move>[];
    final path = <Position>[];
    final captured = <Position>[];

    void extend(Position current, Direction? previousDirection) {
      final steps = movement.captureSteps(
        search,
        current,
        piece.owner,
        previousDirection: previousDirection,
      );
      if (steps.isEmpty) {
        if (captured.isNotEmpty) {
          sequences.add(
            Move(
              piece: piece,
              from: from,
              path: path,
              captured: captured,
              promotes: piece.isPawn && current.row == piece.owner.promotionRow,
            ),
          );
        }
        return;
      }
      for (final step in steps) {
        final taken = search.capture(step.captured);
        path.add(step.landing);
        captured.add(step.captured);
        extend(step.landing, step.direction);
        path.removeLast();
        captured.removeLast();
        search.restore(step.captured, taken);
      }
    }

    extend(from, null);
    return sequences;
  }
}

/// Mutable copy of the board used while exploring capture sequences.
final class _SearchBoard implements BoardView {
  _SearchBoard(BoardView source, this._removal)
    : _cells = [for (final position in Position.all) source.pieceAt(position)];

  final CapturedPieceRemoval _removal;
  final List<Piece?> _cells;
  final List<bool> _taken = List<bool>.filled(Position.count, false);

  void vacate(Position position) => _cells[position.index] = null;

  /// Takes the piece on [position] and returns it so it can be restored.
  Piece capture(Position position) {
    final piece = _cells[position.index]!;
    switch (_removal) {
      case CapturedPieceRemoval.immediate:
        _cells[position.index] = null;
      case CapturedPieceRemoval.endOfSequence:
        _taken[position.index] = true;
    }
    return piece;
  }

  void restore(Position position, Piece piece) {
    _cells[position.index] = piece;
    _taken[position.index] = false;
  }

  @override
  Piece? pieceAt(Position position) => _cells[position.index];

  @override
  bool isEmpty(Position position) => _cells[position.index] == null;

  @override
  bool isCapturableBy(Position position, Player player) {
    final piece = _cells[position.index];
    return piece != null && piece.owner != player && !_taken[position.index];
  }
}
