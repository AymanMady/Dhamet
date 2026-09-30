import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// Each position comes with an engine-only proof (see `winsWithin` in
/// test_helpers.dart) that the expected answer is the only correct one, so
/// these tests do not depend on the evaluation.
void main() {
  List<AiConfig> configsFrom(int depth) => [
    for (final preset in [
      AiConfig.easy,
      AiConfig.medium,
      AiConfig.hard,
      AiConfig.expert,
    ])
      if (preset.maxDepth >= depth)
        preset.copyWith(
          maxDepth: min(preset.maxDepth, depth + 2),
          timeLimit: const Duration(seconds: 30),
        ),
  ];

  void expectPlays(GameState state, String expected, {required int depth}) {
    final configs = configsFrom(depth);
    expect(configs, isNotEmpty);
    for (final config in configs) {
      for (var seed = 0; seed < 3; seed++) {
        final result = DhametAi(
          config: config,
          random: Random(seed),
        ).chooseMove(state);
        expect(result.move.toString(), expected, reason: '$config');
        expect(result.isWin, isTrue, reason: '$result');
      }
    }
  }

  test('wins at once by blocking the last enemy pawn (end.blocked)', () {
    // The black pawn on a2 can only step to a1: occupying a1 blocks it.
    final state = stateFrom('''
      9  . . . . . . . . .
      8  . . . . . . . . .
      7  . . . . . . . . .
      6  . . . . . . . . .
      5  . . . . . . . . .
      4  . . . . . . . . .
      3  . . . . . . . . .
      2  b . . . . . . . .
      1  . . . . W . . . .
         a b c d e f g h i
    ''');
    final blocking = [
      for (final move in state.legalMoves)
        if (detector.detect(state.play(move)) ==
            const GameResult.win(Player.white, GameEndReason.blocked))
          move,
    ];
    expect(notations(blocking), {'e1-a1'});
    expect(state.legalMoves.length, greaterThan(10));

    expectPlays(state, 'e1-a1', depth: 1);
    final result = DhametAi(config: depthOnly(4)).chooseMove(state);
    expect(result.pliesToForcedEnd, 1);
    expect(result.depth, 1, reason: 'a forced result stops the search');
  });

  test('sacrifices a pawn to set up a winning rafle', () {
    // g2-g3 forces h4xf2, then g1xe3xc3 takes both black pawns.
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
    expect(winsWithin(state, 1), isFalse);
    expect(notations(winningMoves(state, 3)), {'g2-g3'});
    final afterSacrifice = state.play(legalMove(state, 'g2-g3'));
    expect(notations(afterSacrifice.legalMoves), {'h4xf2'});

    expectPlays(state, 'g2-g3', depth: 1);
    expect(
      DhametAi(config: depthOnly(3)).chooseMove(state).pliesToForcedEnd,
      3,
    );
  });

  test('chooses the one promotion that wins', () {
    // Six promotions are available; only the Sultan on i9 wins by force.
    final state = stateFrom('''
      9  . . . . . . . . .
      8  . . . w . . . w b
      7  . . . . . . . . .
      6  . w . . . . . . .
      5  . . . . . . . . .
      4  . . . . . . . . .
      3  . . . . . . . . .
      2  . . . . b . . . .
      1  . . . . . . . . .
         a b c d e f g h i
    ''');
    expect(state.legalMoves.where((move) => move.promotes), hasLength(6));
    expect(winsWithin(state, 1), isFalse);
    expect(notations(winningMoves(state, 3)), {'h8-i9=S'});

    expectPlays(state, 'h8-i9=S', depth: 3);
  });

  test('among forced captures, takes the one that promotes and wins', () {
    final state = stateFrom('''
      9  . . . . . . . . .
      8  . b . . . . . . .
      7  . . w . . . . . .
      6  . . . . . . . . .
      5  . . . . b . . . .
      4  . b w . . . . . .
      3  . . . . . . . . B
      2  . . . . . . . . .
      1  . . . . . . . . .
         a b c d e f g h i
    ''');
    expect(notations(state.legalMoves), {'c4xa4', 'c7xa9=S'});
    expect(notations(winningMoves(state, 3)), {'c7xa9=S'});

    expectPlays(state, 'c7xa9=S', depth: 3);
  });

  test('never promotes into a rafle that takes every piece', () {
    // After d8-d9 or d8-c9 the black Sultan takes all three white pawns.
    final state = stateFrom('''
      9  . . . . B . . . .
      8  w . . w . . . . .
      7  . . . . . . . . .
      6  . . . . b . . . .
      5  . . . . . . . w .
      4  . . . . . . . . .
      3  . . . . . . . . .
      2  . . . . . . . . .
      1  . . . . . . . . .
         a b c d e f g h i
    ''');
    final losing = {
      for (final move in state.legalMoves)
        if (winsWithin(state.play(move), 1)) move.toString(),
    };
    final safe = {
      for (final move in state.legalMoves)
        if (!winsWithin(state.play(move), 1)) move.toString(),
    };
    expect(losing, {'d8-d9=S', 'd8-c9=S'});
    expect(safe, {'a8-a9=S', 'h5-h6'});

    for (final config in configsFrom(1)) {
      for (var seed = 0; seed < 5; seed++) {
        final result = DhametAi(
          config: config,
          random: Random(seed),
        ).chooseMove(state);
        expect(safe, contains(result.move.toString()), reason: '$config');
      }
    }
  });

  test('recognises a lost position and still plays a legal move', () {
    // Wherever the black pawn steps, a white Sultan takes it.
    final state = stateFrom('''
      9  . . . . . . . . .
      8  . . . . . . . . .
      7  . . . . . . . . .
      6  . b . . . . . . .
      5  . . . . . . . W .
      4  . . . . . . . . .
      3  W . . . . . . . .
      2  . . . . . . . . .
      1  . . . . . . . . .
         a b c d e f g h i
    ''', toMove: Player.black);
    expect(state.legalMoves, hasLength(3));
    expect(losesWithin(state, 2), isTrue);
    for (final config in configsFrom(2)) {
      final result = DhametAi(config: config).chooseMove(state);
      expect(result.isLoss, isTrue, reason: '$result');
      expect(result.pliesToForcedEnd, 2);
      expect(state.legalMoves, contains(result.move));
    }
  });
}
