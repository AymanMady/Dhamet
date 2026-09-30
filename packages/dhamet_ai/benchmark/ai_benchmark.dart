// Measures the AI on positions from AI games: search speed (positions per
// second), depth reached and time used per move for each difficulty, and
// the cost of one static evaluation.
//
// Run compiled, as in a release build:
//   dart compile exe benchmark/ai_benchmark.dart -o /tmp/dhamet_ai_bench
//   /tmp/dhamet_ai_bench
import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';

void main() {
  final positions = _samplePositions();
  print(
    '${positions.length} positions from AI games '
    '(plies ${positions.map((s) => s.plyCount).join(', ')})\n',
  );

  _benchmarkEvaluation(positions);

  print(
    '\n${'level'.padRight(8)}${'depth'.padLeft(12)}${'time/move'.padLeft(16)}'
    '${'nodes/move'.padLeft(12)}${'nodes/s'.padLeft(10)}',
  );
  for (final difficulty in AiDifficulty.values) {
    final config = AiConfig.forDifficulty(difficulty).copyWith(randomness: 0);
    final ai = DhametAi(config: config);
    final depths = <int>[];
    final times = <int>[];
    var nodes = 0;
    for (final state in positions) {
      final result = ai.chooseMove(state);
      depths.add(result.depth);
      times.add(result.elapsed.inMicroseconds);
      nodes += result.nodes;
    }
    final totalMicros = times.fold(0, (sum, t) => sum + t);
    final depthRange = '${depths.reduce(min)}–${depths.reduce(max)}';
    final averageMs = totalMicros / times.length / 1000;
    final maxMs = times.reduce(max) / 1000;
    print(
      '${difficulty.name.padRight(8)}'
      '${depthRange.padLeft(12)}'
      '${'${averageMs.toStringAsFixed(0)} ms (max ${maxMs.toStringAsFixed(0)})'.padLeft(16)}'
      '${(nodes / positions.length).round().toString().padLeft(12)}'
      '${(nodes / totalMicros * 1e6).round().toString().padLeft(10)}',
    );
  }
}

/// Positions every 15 plies of a few games between medium-strength AIs
/// (depth-bounded, seeded: the same positions on every run).
List<GameState> _samplePositions() {
  final positions = <GameState>[];
  for (var seed = 0; seed < 3; seed++) {
    final ai = DhametAi(
      config: const AiConfig(
        maxDepth: 2,
        timeLimit: Duration(seconds: 10),
        randomness: 0.5,
      ),
      random: Random(seed),
    );
    var game = Game.start();
    while (!game.isOver && game.state.plyCount < 120) {
      if (game.state.plyCount % 15 == 10 && game.state.legalMoves.length > 1) {
        positions.add(game.state);
      }
      game = game.play(ai.chooseMove(game.state).move);
    }
  }
  return positions;
}

void _benchmarkEvaluation(List<GameState> positions) {
  const evaluator = DhametEvaluator();
  const rounds = 2000;
  var sink = 0;
  for (final state in positions) {
    sink += evaluator.evaluate(state, Player.white);
  }
  final clock = Stopwatch()..start();
  for (var i = 0; i < rounds; i++) {
    for (final state in positions) {
      sink += evaluator.evaluate(state, state.currentPlayer);
    }
  }
  final micros = clock.elapsedMicroseconds / (rounds * positions.length);
  print(
    'static evaluation: ${micros.toStringAsFixed(2)} µs / position '
    '(checksum $sink)',
  );
}
