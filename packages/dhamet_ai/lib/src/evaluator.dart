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
/// piece, White's total minus Black's.
///
/// | Term        | Default | Counted for                                   |
/// |-------------|---------|-----------------------------------------------|
/// | pawn        | 100     | each pawn                                     |
/// | Sultan      | 300     | each Sultan                                   |
/// | mobility    | 2       | each free step of a pawn (empty intersection  |
/// |             |         | ahead along a line), each empty intersection  |
/// |             |         | a Sultan could slide to                       |
/// | advancement | 3       | each row a pawn has advanced from its side's  |
/// |             |         | home row                                      |
/// | centre      | 2       | each ring a piece stands nearer to e5         |
/// |             |         | (0 on the edge, 4 on e5)                      |
///
/// Mobility counts free space around the pieces; it does not decide what is
/// legal (captures are mandatory, so the legal moves may differ). Legality is
/// left to the engine.
///
/// The score is antisymmetric: `evaluate(s, white) == -evaluate(s, black)`,
/// and it does not change when the board is turned around and the colours
/// swapped.
final class DhametEvaluator implements Evaluator {
  const DhametEvaluator({
    this.pawn = 100,
    this.sultan = 300,
    this.mobility = 2,
    this.advancement = 3,
    this.centre = 2,
  });

  /// Value of a pawn.
  final int pawn;

  /// Value of a Sultan.
  final int sultan;

  /// Bonus per free step (pawn) or reachable empty intersection (Sultan).
  final int mobility;

  /// Bonus per row a pawn has advanced.
  final int advancement;

  /// Bonus per ring nearer to the centre.
  final int centre;

  @override
  int evaluate(GameState state, Player perspective) {
    final board = state.board;
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
        for (final ahead in _forward[owner.index][index]) {
          if (board.isEmpty(ahead)) value += mobility;
        }
      } else {
        value += sultan;
        for (final ray in _rays[index]) {
          for (final point in ray) {
            if (!board.isEmpty(point)) break;
            value += mobility;
          }
        }
      }
      score += owner == Player.white ? value : -value;
    }
    return perspective == Player.white ? score : -score;
  }

  @override
  bool operator ==(Object other) =>
      other is DhametEvaluator &&
      other.pawn == pawn &&
      other.sultan == sultan &&
      other.mobility == mobility &&
      other.advancement == advancement &&
      other.centre == centre;

  @override
  int get hashCode => Object.hash(pawn, sultan, mobility, advancement, centre);

  @override
  String toString() =>
      'DhametEvaluator(pawn: $pawn, sultan: $sultan, mobility: $mobility, '
      'advancement: $advancement, centre: $centre)';

  /// Distance ring of each intersection: 4 on e5, 0 on the edge.
  static final List<int> _ring = List.unmodifiable([
    for (final position in Position.all)
      Position.size ~/ 2 -
          _max(
            (position.column - Position.center.column).abs(),
            (position.row - Position.center.row).abs(),
          ),
  ]);

  /// For each player and intersection, the neighbours a pawn steps to.
  static final List<List<List<Position>>> _forward = List.unmodifiable([
    for (final player in Player.values)
      List<List<Position>>.unmodifiable([
        for (final from in Position.all)
          List<Position>.unmodifiable([
            for (final direction in BoardTopology.standard.directionsFrom(from))
              if (player.isForward(direction))
                BoardTopology.standard.neighbor(from, direction)!,
          ]),
      ]),
  ]);

  /// For each intersection, the lines leaving it.
  static final List<List<List<Position>>> _rays = List.unmodifiable([
    for (final from in Position.all)
      List<List<Position>>.unmodifiable([
        for (final direction in BoardTopology.standard.directionsFrom(from))
          BoardTopology.standard.ray(from, direction),
      ]),
  ]);

  static int _max(int a, int b) => a > b ? a : b;
}
