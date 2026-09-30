import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// Stands for a position the engine takes very long to process: after
/// [after] evaluations, every evaluation blocks for [stall].
final class StallingEvaluator implements Evaluator {
  StallingEvaluator({required this.after, required this.stall});

  final int after;
  final Duration stall;
  int _calls = 0;

  int get calls => _calls;

  @override
  int evaluate(GameState state, Player perspective) {
    if (++_calls > after) {
      final clock = Stopwatch()..start();
      while (clock.elapsed < stall) {}
    }
    return const DhametEvaluator().evaluate(state, perspective);
  }
}

final class FailingEvaluator implements Evaluator {
  @override
  int evaluate(GameState state, Player perspective) =>
      throw UnsupportedError('evaluation failed');
}

void main() {
  final middleGame = randomPosition(3, 24);

  test('returns one of the legal moves of the given state', () async {
    final result = await chooseMoveInBackground(
      middleGame,
      config: depthOnly(2),
    );
    expect(
      middleGame.legalMoves.any((move) => identical(move, result.move)),
      isTrue,
    );
    expect(result.depth, 2);
    expect(result.nodes, greaterThan(0));
  });

  test('matches the foreground search for the same seed', () async {
    final config = depthOnly(2, randomness: 1.5);
    for (final seed in [1, 2, 3]) {
      final background = await chooseMoveInBackground(
        middleGame,
        config: config,
        seed: seed,
      );
      final foreground = DhametAi(
        config: config,
        random: Random(seed),
      ).chooseMove(middleGame);
      expect(background.move, foreground.move);
      expect(background.score, foreground.score);
      expect(background.depth, foreground.depth);
      expect(background.nodes, foreground.nodes);
    }
  });

  test('accepts a custom evaluator', () async {
    const materialOnly = DhametEvaluator(
      advancement: 0,
      homeRow: 0,
      exposure: 0,
      hanging: 0,
    );
    final result = await chooseMoveInBackground(
      middleGame,
      config: depthOnly(2),
      evaluator: materialOnly,
    );
    final expected = DhametAi(
      config: depthOnly(2),
      evaluator: materialOnly,
    ).chooseMove(middleGame);
    expect(result.move, expected.move);
  });

  test('keeps the calling isolate responsive', () async {
    var ticks = 0;
    final timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => ticks++,
    );
    final result = await chooseMoveInBackground(
      middleGame,
      config: const AiConfig(
        maxDepth: AiConfig.maxSupportedDepth,
        timeLimit: Duration(milliseconds: 300),
      ),
    );
    timer.cancel();
    expect(middleGame.legalMoves, contains(result.move));
    expect(ticks, greaterThanOrEqualTo(5));
  });

  group('answers on time when a single position stalls the search', () {
    const config = AiConfig(
      maxDepth: 8,
      timeLimit: Duration(milliseconds: 200),
    );
    const grace = Duration(milliseconds: 100);
    const bound = Duration(milliseconds: 800);

    test('with the move of the last completed iteration', () async {
      // Count the evaluations of the first iteration, then stall right
      // after them, at the start of the second one.
      final counter = StallingEvaluator(after: 1 << 30, stall: Duration.zero);
      DhametAi(config: depthOnly(1), evaluator: counter).chooseMove(middleGame);
      final clock = Stopwatch()..start();
      final result = await chooseMoveInBackground(
        middleGame,
        config: config,
        grace: grace,
        evaluator: StallingEvaluator(
          after: counter.calls,
          stall: const Duration(seconds: 5),
        ),
      );
      expect(clock.elapsed, lessThan(bound));
      expect(middleGame.legalMoves, contains(result.move));
      expect(result.depth, 1);
      expect(
        result.move,
        DhametAi(config: depthOnly(1)).chooseMove(middleGame).move,
      );
    });

    test('with the first move in search order if nothing completed', () async {
      final clock = Stopwatch()..start();
      final result = await chooseMoveInBackground(
        middleGame,
        config: config,
        grace: grace,
        evaluator: StallingEvaluator(
          after: 0,
          stall: const Duration(seconds: 5),
        ),
      );
      expect(clock.elapsed, lessThan(bound));
      expect(middleGame.legalMoves, contains(result.move));
      expect(result.depth, 0);
    });
  });

  test('reports errors of the background isolate', () {
    expect(
      chooseMoveInBackground(
        middleGame,
        config: depthOnly(2),
        evaluator: FailingEvaluator(),
      ),
      throwsA(isA<RemoteError>()),
    );
  });

  test('fails with a StateError when the game is over', () {
    final state = stateWith({'e5': Piece.whitePawn}, toMove: Player.black);
    expect(
      chooseMoveInBackground(state, config: AiConfig.easy),
      throwsStateError,
    );
  });
}
