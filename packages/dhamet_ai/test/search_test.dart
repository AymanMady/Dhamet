import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// Counts the positions it evaluates.
final class CountingEvaluator implements Evaluator {
  int calls = 0;

  @override
  int evaluate(GameState state, Player perspective) {
    calls++;
    return const DhametEvaluator().evaluate(state, perspective);
  }
}

void main() {
  // A middle-game position without Sultans, with many legal moves.
  final middleGame = randomPosition(3, 24);

  setUpAll(() {
    expect(middleGame.legalMoves.length, greaterThan(10));
    expect(middleGame.mustCapture, isFalse);
  });

  group('game over', () {
    test('chooseMove throws when a side has no piece left', () {
      final state = stateWith({'e5': Piece.whitePawn}, toMove: Player.black);
      expect(() => DhametAi().chooseMove(state), throwsStateError);
    });

    test('chooseMove throws when the side to move is blocked', () {
      final state = stateWith({
        'a2': Piece.blackPawn,
        'a1': Piece.whiteSultan,
      }, toMove: Player.black);
      expect(state.legalMoves, isEmpty);
      expect(() => DhametAi().chooseMove(state), throwsStateError);
    });
  });

  test('a forced move is returned at once', () {
    final state = stateWith({
      'e5': Piece.whitePawn,
      'e6': Piece.blackPawn,
      'a9': Piece.blackPawn,
      'a1': Piece.whitePawn,
    }, toMove: Player.black);
    expect(notations(state.legalMoves), {'e6xe4'});
    final result = DhametAi(config: AiConfig.expert).chooseMove(state);
    expect(result.move, same(state.legalMoves.single));
    expect(result.depth, 0);
    expect(result.elapsed, lessThan(const Duration(milliseconds: 100)));
    expect(result.isWin || result.isLoss, isFalse);
  });

  test('a forced move that ends the game is scored as a win', () {
    final state = stateWith({'e5': Piece.whitePawn, 'e6': Piece.blackPawn});
    expect(notations(state.legalMoves), {'e5xe7'});
    final result = DhametAi(config: AiConfig.expert).chooseMove(state);
    expect(result.depth, 0);
    expect(result.isWin, isTrue);
    expect(result.pliesToForcedEnd, 1);
  });

  test('searches to maxDepth when time allows', () {
    for (final depth in [1, 2, 3]) {
      final result = DhametAi(config: depthOnly(depth)).chooseMove(middleGame);
      expect(result.depth, depth);
      expect(middleGame.legalMoves, contains(result.move));
    }
    final shallow = DhametAi(config: depthOnly(1)).chooseMove(middleGame);
    final deep = DhametAi(config: depthOnly(3)).chooseMove(middleGame);
    expect(deep.nodes, greaterThan(shallow.nodes));
  });

  group('time limit', () {
    const limit = Duration(milliseconds: 300);
    const margin = Duration(milliseconds: 150);

    test('is respected', () {
      const config = AiConfig(
        maxDepth: AiConfig.maxSupportedDepth,
        timeLimit: limit,
      );
      for (final state in [GameState.initial(), middleGame]) {
        final clock = Stopwatch()..start();
        final result = DhametAi(config: config).chooseMove(state);
        clock.stop();
        expect(result.elapsed, lessThanOrEqualTo(limit + margin));
        expect(clock.elapsed, lessThanOrEqualTo(limit + margin));
        expect(result.depth, inInclusiveRange(1, config.maxDepth - 1));
        expect(state.legalMoves, contains(result.move));
      }
    });

    test('a tiny budget still gives a legal move', () {
      const config = AiConfig(
        maxDepth: 10,
        timeLimit: Duration(microseconds: 1),
      );
      final result = DhametAi(config: config).chooseMove(middleGame);
      expect(middleGame.legalMoves, contains(result.move));
      expect(result.depth, 0);
      expect(result.elapsed, lessThan(const Duration(milliseconds: 100)));
    });
  });

  group('randomness', () {
    test('a seed makes the choice reproducible', () {
      for (final randomness in [0.0, 0.4, 1.5]) {
        final config = depthOnly(2, randomness: randomness);
        final first = DhametAi(
          config: config,
          random: Random(42),
        ).chooseMove(middleGame);
        final second = DhametAi(
          config: config,
          random: Random(42),
        ).chooseMove(middleGame);
        expect(second.move, first.move);
        expect(second.score, first.score);
        expect(second.nodes, first.nodes);
      }
    });

    test('without randomness the seed does not matter', () {
      final moves = {
        for (var seed = 0; seed < 5; seed++)
          DhametAi(
            config: depthOnly(2),
            random: Random(seed),
          ).chooseMove(middleGame).move,
      };
      expect(moves, hasLength(1));
    });

    test('varies the play, within the margin of the best score', () {
      const randomness = 1.5;
      final margin = (randomness * 100).round();
      final best = DhametAi(config: depthOnly(1)).chooseMove(middleGame);
      final chosen = <Move>{};
      for (var seed = 0; seed < 20; seed++) {
        final result = DhametAi(
          config: depthOnly(1, randomness: randomness),
          random: Random(seed),
        ).chooseMove(middleGame);
        expect(result.score, lessThanOrEqualTo(best.score));
        expect(result.score, greaterThanOrEqualTo(best.score - margin));
        chosen.add(result.move);
      }
      expect(chosen.length, greaterThan(1));
    });

    test('never replaces a forced win', () {
      // g2-g3 wins in three plies (see tactics_test.dart).
      final state = stateFrom('''
        9  . . . . . . . . .
        8  . . . . . . . . .
        7  . . . . . . . . .
        6  . . . . . . . . .
        5  . . . . . . . . .
        4  . . . . . w . b .
        3  . . . b . . . . .
        2  . . . . . . w . .
        1  . . . . . . w . .
           a b c d e f g h i
      ''');
      for (var seed = 0; seed < 10; seed++) {
        final result = DhametAi(
          config: AiConfig.easy.copyWith(randomness: 5),
          random: Random(seed),
        ).chooseMove(state);
        expect(result.move.toString(), 'g2-g3');
      }
    });
  });

  test('uses the given evaluator', () {
    final evaluator = CountingEvaluator();
    final ai = DhametAi(config: depthOnly(2), evaluator: evaluator);
    expect(ai.evaluator, same(evaluator));
    ai.chooseMove(middleGame);
    expect(evaluator.calls, greaterThan(0));
  });

  test('search results describe themselves', () {
    final result = DhametAi(config: depthOnly(1)).chooseMove(middleGame);
    expect(result.toString(), contains(result.move.toString()));
    expect(result.isWin || result.isLoss, isFalse);
    expect(result.pliesToForcedEnd, isNull);
  });
}
