import '../board/board.dart';
import '../board/board_topology.dart';
import '../board/direction.dart';
import '../board/position.dart';
import '../pieces/piece.dart';
import '../pieces/player.dart';
import '../rules/dhamet_rules.dart';

/// A single jump inside a capture sequence.
final class CaptureStep {
  const CaptureStep(this.direction, this.captured, this.landing);

  final Direction direction;

  /// Intersection of the piece being jumped.
  final Position captured;

  /// Intersection where the capturing piece lands.
  final Position landing;

  @override
  String toString() => 'x$captured→$landing';
}

/// How one kind of piece moves: normal moves and single capture jumps.
///
/// Chaining jumps into complete sequences and choosing among them is the job
/// of `CaptureResolver` and `MoveGenerator`.
sealed class PieceMovement {
  const PieceMovement(this.topology, this.rules);

  final BoardTopology topology;
  final DhametRules rules;

  /// Destinations of normal (non-capturing) moves from [from].
  List<Position> normalDestinations(
    BoardView board,
    Position from,
    Player player,
  );

  /// Captures available from [from]. [previousDirection] is the direction of
  /// the previous jump when continuing a sequence.
  List<CaptureStep> captureSteps(
    BoardView board,
    Position from,
    Player player, {
    Direction? previousDirection,
  });
}

/// Pawn movement.
///
/// Normal move (`pawn.move`, CONFIRMED): one step to an empty intersection,
/// straight or diagonally forward along a line, never sideways ("النزل على
/// ظر" is forbidden) nor backwards.
///
/// Capture (`capture.pawnDirections`, CONFIRMED): short leap over an
/// adjacent enemy piece to the empty intersection right behind it, in any
/// direction along a line, backwards and sideways included.
final class PawnMovement extends PieceMovement {
  const PawnMovement(super.topology, super.rules);

  @override
  List<Position> normalDestinations(
    BoardView board,
    Position from,
    Player player,
  ) => [
    for (final direction in topology.directionsFrom(from))
      if (player.isForward(direction))
        if (topology.neighbor(from, direction) case final to?)
          if (board.isEmpty(to)) to,
  ];

  @override
  List<CaptureStep> captureSteps(
    BoardView board,
    Position from,
    Player player, {
    Direction? previousDirection,
  }) {
    final steps = <CaptureStep>[];
    for (final direction in topology.directionsFrom(from)) {
      if (!rules.pawnCapturesBackward && player.isBackward(direction)) continue;
      if (!rules.pawnCapturesSideways && direction.rowStep == 0) continue;
      final over = topology.neighbor(from, direction)!;
      final landing = topology.neighbor(over, direction);
      if (landing != null &&
          board.isCapturableBy(over, player) &&
          board.isEmpty(landing)) {
        steps.add(CaptureStep(direction, over, landing));
      }
    }
    return steps;
  }
}

/// Sultan movement.
///
/// Normal move (`sultan.flying`, CONFIRMED): any distance in any direction
/// along a line, until blocked by a piece.
///
/// Capture (`sultan.flying`, CONFIRMED): along a line, over the first piece
/// met at any distance if it is an enemy piece followed by an empty
/// intersection. Landing (`sultan.landing`, LIKELY) and reversal
/// (`sultan.reverseDuringCapture`, NEEDS_VERIFICATION) follow [rules].
final class SultanMovement extends PieceMovement {
  const SultanMovement(super.topology, super.rules);

  @override
  List<Position> normalDestinations(
    BoardView board,
    Position from,
    Player player,
  ) {
    final destinations = <Position>[];
    for (final direction in topology.directionsFrom(from)) {
      for (final to in topology.ray(from, direction)) {
        if (!board.isEmpty(to)) break;
        destinations.add(to);
        if (!rules.sultanFlies) break;
      }
    }
    return destinations;
  }

  @override
  List<CaptureStep> captureSteps(
    BoardView board,
    Position from,
    Player player, {
    Direction? previousDirection,
  }) {
    final steps = <CaptureStep>[];
    for (final direction in topology.directionsFrom(from)) {
      if (previousDirection != null &&
          !rules.sultanMayReverseDuringCapture &&
          direction == previousDirection.opposite) {
        continue;
      }
      final ray = topology.ray(from, direction);
      var target = 0;
      if (rules.sultanFlies) {
        while (target < ray.length && board.isEmpty(ray[target])) {
          target++;
        }
      }
      if (target >= ray.length || !board.isCapturableBy(ray[target], player)) {
        continue;
      }
      for (var landing = target + 1; landing < ray.length; landing++) {
        if (!board.isEmpty(ray[landing])) break;
        steps.add(CaptureStep(direction, ray[target], ray[landing]));
        if (!rules.sultanFlies ||
            rules.sultanLanding == SultanLanding.immediatelyBehind) {
          break;
        }
      }
    }
    return steps;
  }
}

/// The movement of each piece type for one rule set.
final class PieceMovements {
  PieceMovements(BoardTopology topology, DhametRules rules)
    : pawn = PawnMovement(topology, rules),
      sultan = SultanMovement(topology, rules);

  final PawnMovement pawn;
  final SultanMovement sultan;

  PieceMovement of(PieceType type) => switch (type) {
    PieceType.pawn => pawn,
    PieceType.sultan => sultan,
  };
}
