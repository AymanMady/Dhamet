import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// Every preset, with a depth-bounded search so that results do not depend
/// on the machine's speed.
final Map<String, AiConfig> levels = {
  for (final difficulty in AiDifficulty.values)
    difficulty.name: AiConfig.forDifficulty(difficulty).copyWith(
      maxDepth: min(AiConfig.forDifficulty(difficulty).maxDepth, 4),
      timeLimit: const Duration(seconds: 30),
    ),
};

void main() {
  group('side to move', () {
    test('White moves first by default', () {
      final result = DhametAi(config: depthOnly(2))
          .chooseMove(GameState.initial());
      expect(result.move.player, Player.white);
      expect(GameState.initial().legalMoves, contains(result.move));
    });

    test('Black moves when it is its turn', () {
      final initial = GameState.initial();
      final state = initial.play(initial.legalMoves.first);
      final move = DhametAi(config: depthOnly(2)).chooseMove(state).move;
      expect(move.player, Player.black);
      expect(state.legalMoves, contains(move));
    });

    test('Black moves first when the rules say so', () {
      final state = GameState.initial(
        rules: const DhametRules(startingPlayer: Player.black),
      );
      final move = DhametAi(config: depthOnly(2)).chooseMove(state).move;
      expect(move.player, Player.black);
      expect(state.legalMoves, contains(move));
    });
  });

  group('mandatory capture (capture.mandatory)', () {
    // White could promote on h9, but c3 and g3 must capture.
    final state = stateFrom('''
      9  b . . . . . . . .
      8  . . . . . . . w .
      7  . . . . . . . . .
      6  . . . . . . . . .
      5  . . . . . . . . .
      4  . . b . . . b . .
      3  . . w . . . w . .
      2  . . . . . . . . .
      1  . . . . . . . . .
         a b c d e f g h i
    ''');

    test('the engine only offers the captures', () {
      expect(notations(state.legalMoves), {'c3xc5', 'g3xg5'});
      final withoutCaptures = GameState(
        board: state.board.withPiece(sq('c4'), null).withPiece(sq('g4'), null),
        currentPlayer: Player.white,
      );
      expect(notations(withoutCaptures.legalMoves), contains('h8-h9=S'));
    });

    levels.forEach((name, config) {
      test('$name captures instead of promoting', () {
        for (var seed = 0; seed < 3; seed++) {
          final move = DhametAi(
            config: config,
            random: Random(seed),
          ).chooseMove(state).move;
          expect(move.isCapture, isTrue);
          expect(state.legalMoves, contains(move));
        }
      });
    });
  });

  group('maximum capture (capture.maximum)', () {
    // a1 and e1 can take two pawns, i1 only one.
    final white = stateFrom('''
      9  . . . . . . . . .
      8  . . . . . . . . .
      7  . . . . . . . . .
      6  . . . . . . . . .
      5  . . . . . . . . .
      4  b . . . b . . . .
      3  . . . . . . . . .
      2  b . . . b . . . b
      1  w . . . w . . . w
         a b c d e f g h i
    ''');

    test('the engine only offers the two-piece sequences', () {
      expect(notations(white.legalMoves), {'a1xa3xa5', 'e1xe3xe5'});
      final free = GameState(
        board: white.board,
        currentPlayer: Player.white,
        rules: const DhametRules(captureChoice: CaptureChoice.free),
      );
      expect(notations(free.legalMoves), contains('i1xi3'));
    });

    levels.forEach((name, config) {
      test('$name takes the most pieces, for either side', () {
        final black = GameState(
          board: Board.fromPieces({
            for (final MapEntry(key: position, value: piece)
                in white.board.pieces.entries)
              Position(8 - position.column, 8 - position.row): Piece.of(
                piece.owner.opponent,
                piece.type,
              ),
          }),
          currentPlayer: Player.black,
        );
        for (final state in [white, black]) {
          final move = DhametAi(
            config: config,
            random: Random(1),
          ).chooseMove(state).move;
          expect(move.player, state.currentPlayer);
          expect(move.captureCount, 2);
          expect(state.legalMoves, contains(move));
        }
      });
    });
  });

  group('other rule sets', () {
    const variants = {
      'free capture choice': DhametRules(captureChoice: CaptureChoice.free),
      'optional captures': DhametRules(mandatoryCapture: false),
      'removal at end of sequence': DhametRules(
        capturedPieceRemoval: CapturedPieceRemoval.endOfSequence,
      ),
      'traditional opening': DhametRules(
        opening: OpeningRule.traditionalEncounter,
      ),
    };

    variants.forEach((name, rules) {
      test('only legal moves under "$name"', () {
        final ai = DhametAi(config: depthOnly(2), random: Random(3));
        var game = Game.start(rules: rules);
        for (var ply = 0; ply < 40 && !game.isOver; ply++) {
          final move = ai.chooseMove(game.state).move;
          expect(game.state.legalMoves, contains(move));
          game = game.play(move);
        }
      });
    });

    test('the traditional opening is followed', () {
      final ai = DhametAi(config: depthOnly(2));
      var game = Game.start(
        rules: const DhametRules(opening: OpeningRule.traditionalEncounter),
      );
      for (final expected in TraditionalEncounter.whiteFirst) {
        final move = ai.chooseMove(game.state).move;
        expect(move.matchesNotation(expected), isTrue, reason: '$move');
        game = game.play(move);
      }
    });
  });
}
