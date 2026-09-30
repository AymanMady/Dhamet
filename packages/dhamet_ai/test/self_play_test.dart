import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

/// The preset for [difficulty] with a short time limit, to keep the suite
/// fast. The depth and randomness of the level are unchanged.
AiConfig quick(AiDifficulty difficulty) =>
    AiConfig.forDifficulty(difficulty)
        .copyWith(timeLimit: const Duration(milliseconds: 25));

/// Plays [game] to the end or to [maxPlies], asking [chooseFor] for each
/// move, and checks that every move is legal and made by the side to move.
Game playOut(
  Game game,
  Move Function(GameState state) chooseFor, {
  int maxPlies = 300,
}) {
  var current = game;
  while (!current.isOver && current.state.plyCount < maxPlies) {
    final state = current.state;
    final move = chooseFor(state);
    expect(state.legalMoves, contains(move));
    expect(move.player, state.currentPlayer);
    // Game.play validates the move again through GameState.play.
    current = current.play(move);
  }
  return current;
}

void main() {
  group('against a random mover', () {
    for (final difficulty in AiDifficulty.values) {
      test('${difficulty.name} plays legal moves and wins', () {
        for (final aiPlays in Player.values) {
          final random = Random(difficulty.index * 2 + aiPlays.index);
          final ai = DhametAi(config: quick(difficulty), random: random);
          final game = playOut(
            Game.start(),
            (state) => state.currentPlayer == aiPlays
                ? ai.chooseMove(state).move
                : state.legalMoves[random.nextInt(state.legalMoves.length)],
          );
          expect(game.isOver, isTrue, reason: 'ply ${game.state.plyCount}');
          expect(game.result!.winner, aiPlays);
        }
      });
    }
  });

  group('against itself', () {
    for (final difficulty in AiDifficulty.values) {
      test('${difficulty.name} games end without error', () {
        final white = DhametAi(config: quick(difficulty), random: Random(1));
        final black = DhametAi(config: quick(difficulty), random: Random(2));
        final game = playOut(
          Game.start(),
          (state) => (state.currentPlayer == Player.white ? white : black)
              .chooseMove(state)
              .move,
          maxPlies: 250,
        );
        if (game.isOver) {
          expect(game.result!.isDraw, isFalse);
          expect(() => white.chooseMove(game.state), throwsStateError);
        } else {
          expect(game.state.plyCount, 250);
        }
      });
    }

    test('a stronger level beats a weaker one', () {
      // Easy against hard, each playing both colours.
      for (final hardPlays in Player.values) {
        final hard = DhametAi(
          config: quick(AiDifficulty.hard),
          random: Random(3),
        );
        final easy = DhametAi(
          config: quick(AiDifficulty.easy),
          random: Random(4),
        );
        final game = playOut(
          Game.start(),
          (state) => (state.currentPlayer == hardPlays ? hard : easy)
              .chooseMove(state)
              .move,
        );
        expect(game.result?.winner, hardPlays);
      }
    });
  });
}
