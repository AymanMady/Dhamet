import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';

/// Scores positions for the search.
///
/// Scores are in hundredths of a pawn by convention (see
/// `AiConfig.randomness`). They must stay well below
/// `SearchResult.winThreshold`, which is reserved for forced results.
abstract interface class Evaluator {
  /// Static score of [state] from [perspective]'s point of view: positive
  /// when [perspective] stands better.
  int evaluate(GameState state, Player perspective);
}

/// The default evaluation: a sum of simple, cheap terms computed for each
/// piece, White's total minus Black's. All weights are constructor
/// parameters; the defaults were chosen by self-play (see the README).
///
/// | Term          | Default | Counted for                                  |
/// |---------------|---------|----------------------------------------------|
/// | [pawn]        | 100     | each pawn                                    |
/// | [sultan]      | 300     | each Sultan                                  |
/// | [advancement] | 2       | each row a pawn has advanced from its home   |
/// |               |         | row                                          |
/// | [homeRow]     | 15      | each pawn still on its home row, which the   |
/// |               |         | opponent must reach to promote               |
/// | [exposure]    | -3      | each line along which a piece could be       |
/// |               |         | jumped: the intersection behind it is empty  |
/// |               |         | and the one in front is not held by its side |
/// | [hanging]     | -40     | each piece of the side to move that an       |
/// |               |         | adjacent enemy piece can jump right now      |
/// | [mobility]    | 0       | each free step of a pawn, each empty         |
/// |               |         | intersection a Sultan could slide to         |
/// | [centre]      | 0       | each ring a piece stands nearer to e5        |
///
/// [mobility] and [centre] are disabled by default: with positive weights
/// they lost self-play matches, because free space around a piece and the
/// many lines of the central points are exactly what exposes it to
/// captures in Dhamet.
///
/// These terms only describe the arrangement of the pieces; they never
/// decide what is legal (captures are mandatory, the legal moves may
/// differ). Legality is left to the engine.
///
/// The score is antisymmetric: `evaluate(s, white) == -evaluate(s, black)`.
/// It does not change when the board is turned around, the colours swapped
/// and the other side given the move.
final class DhametEvaluator implements Evaluator {
  const DhametEvaluator({
    this.pawn = 100,
    this.sultan = 300,
    this.advancement = 2,
    this.homeRow = 15,
    this.exposure = 3,
    this.hanging = 40,
    this.mobility = 0,
    this.centre = 0,
  });

  /// Value of a pawn.
  final int pawn;

  /// Value of a Sultan.
  final int sultan;

  /// Bonus per row a pawn has advanced.
  final int advancement;

  /// Bonus per pawn on its home row.
  final int homeRow;

  /// Penalty per line along which a piece could be jumped.
  final int exposure;

  /// Penalty per piece of the side to move under immediate attack.
  final int hanging;

  /// Bonus per free step (pawn) or reachable empty intersection (Sultan).
  final int mobility;

  /// Bonus per ring nearer to the centre.
  final int centre;

  @override
  int evaluate(GameState state, Player perspective) {
    final board = state.board;
    final toMove = state.currentPlayer;
    var score = 0;
    for (var index = 0; index < Position.count; index++) {
      final position = Position.all[index];
      final piece = board[position];
      if (piece == null) continue;
      final owner = piece.owner;
      var value = centre * _ring[index];
      if (piece.isPawn) {
        final advanced = owner == Player.white
            ? position.row
            : Position.size - 1 - position.row;
        value += pawn + advancement * advanced;
        if (advanced == 0) value += homeRow;
        if (mobility != 0) {
          for (final ahead in _forward[owner.index][index]) {
            if (board.isEmpty(ahead)) value += mobility;
          }
        }
      } else {
        value += sultan;
        if (mobility != 0) {
          for (final ray in _rays[index]) {
            for (final point in ray) {
              if (!board.isEmpty(point)) break;
              value += mobility;
            }
          }
        }
      }
      var attacked = false;
      for (final (front, behind) in _lines[index]) {
        if (!board.isEmpty(behind)) continue;
        final attacker = board[front];
        if (attacker == null) {
          value -= exposure;
        } else if (attacker.owner != owner) {
          value -= exposure;
          attacked = true;
        }
      }
      if (attacked && owner == toMove) value -= hanging;
      score += owner == Player.white ? value : -value;
    }
    return perspective == Player.white ? score : -score;
  }

  @override
  bool operator ==(Object other) =>
      other is DhametEvaluator &&
      other.pawn == pawn &&
      other.sultan == sultan &&
      other.advancement == advancement &&
      other.homeRow == homeRow &&
      other.exposure == exposure &&
      other.hanging == hanging &&
      other.mobility == mobility &&
      other.centre == centre;

  @override
  int get hashCode => Object.hash(
    pawn,
    sultan,
    advancement,
    homeRow,
    exposure,
    hanging,
    mobility,
    centre,
  );

  @override
  String toString() =>
      'DhametEvaluator(pawn: $pawn, sultan: $sultan, '
      'advancement: $advancement, homeRow: $homeRow, exposure: $exposure, '
      'hanging: $hanging, mobility: $mobility, centre: $centre)';

  static final BoardTopology _topology = BoardTopology.standard;

  /// Distance ring of each intersection: 4 on e5, 0 on the edge.
  static final List<int> _ring = List.unmodifiable([
    for (final position in Position.all)
      Position.size ~/ 2 -
          max(
            (position.column - Position.center.column).abs(),
            (position.row - Position.center.row).abs(),
          ),
  ]);

  /// For each intersection, the (front, behind) neighbours along every line
  /// passing through it: an enemy piece in front jumps it by landing behind.
  static final List<List<(Position, Position)>> _lines = List.unmodifiable([
    for (final at in Position.all)
      List<(Position, Position)>.unmodifiable([
        for (final direction in _topology.directionsFrom(at))
          if (_topology.neighbor(at, direction.opposite) case final behind?)
            (_topology.neighbor(at, direction)!, behind),
      ]),
  ]);

  /// For each player and intersection, the neighbours a pawn steps to.
  static final List<List<List<Position>>> _forward = List.unmodifiable([
    for (final player in Player.values)
      List<List<Position>>.unmodifiable([
        for (final from in Position.all)
          List<Position>.unmodifiable([
            for (final direction in _topology.directionsFrom(from))
              if (player.isForward(direction))
                _topology.neighbor(from, direction)!,
          ]),
      ]),
  ]);

  /// For each intersection, the lines leaving it.
  static final List<List<List<Position>>> _rays = List.unmodifiable([
    for (final from in Position.all)
      List<List<Position>>.unmodifiable([
        for (final direction in _topology.directionsFrom(from))
          _topology.ray(from, direction),
      ]),
  ]);
}
