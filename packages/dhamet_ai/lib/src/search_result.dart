import 'package:dhamet_engine/dhamet_engine.dart';

/// The move chosen by the AI and how it was found.
final class SearchResult {
  const SearchResult({
    required this.move,
    required this.score,
    required this.depth,
    required this.nodes,
    required this.elapsed,
  });

  /// The chosen move, always one of the searched state's `legalMoves`.
  final Move move;

  /// Value of [move] from the point of view of the side to move: positive
  /// is good for it. See [isWin] and [isLoss] for forced results.
  final int score;

  /// Deepest search iteration completed, in plies. 0 when the move was
  /// forced (single legal move) or no iteration finished in time.
  final int depth;

  /// Number of positions visited.
  final int nodes;

  /// Time spent searching.
  final Duration elapsed;

  /// Scores at least this large (in absolute value) announce a forced
  /// result.
  static const int winThreshold = 1000000 - 1000;

  /// Whether the side to move has a forced win.
  bool get isWin => score >= winThreshold;

  /// Whether the side to move loses against best play.
  bool get isLoss => score <= -winThreshold;

  @override
  String toString() =>
      'SearchResult($move, score: $score, depth: $depth, nodes: $nodes, '
      'elapsed: ${elapsed.inMilliseconds} ms)';
}
