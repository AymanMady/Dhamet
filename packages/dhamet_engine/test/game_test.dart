import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Game', () {
    test('starts from the traditional position with undo disabled', () {
      final game = Game.start();
      expect(game.state, GameState.initial());
      expect(game.rules, DhametRules.standard);
      expect(game.undoPolicy, UndoPolicy.disabled);
      expect(game.result, isNull);
      expect(game.isOver, isFalse);
      expect(game.declaredResult, isNull);
    });

    test('uses the given rules', () {
      const rules = DhametRules(startingPlayer: Player.black);
      final game = Game.start(rules: rules);
      expect(game.state.currentPlayer, Player.black);
      expect(game.rules, rules);
    });

    test('plays legal moves only', () {
      final game = Game.start();
      expect(
        () => game.play(
          Move(piece: Piece.whitePawn, from: sq('e3'), path: [sq('e5')]),
        ),
        throwsA(isA<IllegalMoveException>()),
      );
      final next = playAll(game, ['d4-e5']);
      expect(next.state.currentPlayer, Player.black);
      expect(game.state, GameState.initial(), reason: 'immutable');
    });
  });

  group('undo policy (local games only)', () {
    test('disabled: no undo, no redo (online and competitive games)', () {
      final game = playAll(Game.start(), ['d4-e5']);
      expect(game.canUndo, isFalse);
      expect(game.canRedo, isFalse);
      expect(
        game.undo,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('disabled'),
          ),
        ),
      );
      expect(game.redo, throwsStateError);
    });

    test('unlimited: back to the start', () {
      var game = playAll(localGame(), TraditionalEncounter.whiteFirst);
      for (var i = 0; i < 10; i++) {
        game = game.undo();
      }
      expect(game.state, GameState.initial());
      expect(game.canUndo, isFalse);
      expect(game.canRedo, isTrue);
    });

    test('limited: at most maxDepth moves taken back in a row', () {
      var game = playAll(
        Game.start(undoPolicy: const UndoPolicy.limited(2)),
        TraditionalEncounter.whiteFirst.sublist(0, 4),
      );
      game = game.undo().undo();
      expect(game.canUndo, isFalse);
      expect(game.undo, throwsStateError);

      // Redo frees one step of the limit.
      game = game.redo();
      expect(game.canUndo, isTrue);

      // A new move clears the redo list, so undo is possible again.
      game = game.undo();
      game = game.play(game.state.legalMoves.first);
      expect(game.canRedo, isFalse);
      expect(game.canUndo, isTrue);
    });

    test('undoing the move that ended the game resumes it', () {
      final start = stateWith({'e3': Piece.whitePawn, 'e4': Piece.blackPawn});
      final over = playAll(localGame(state: start), ['e3xe5']);
      expect(
        over.result,
        const GameResult.win(Player.white, GameEndReason.elimination),
      );
      expect(() => over.play(over.state.legalMoves.first), throwsStateError);

      final resumed = over.undo();
      expect(resumed.result, isNull);
      expect(resumed.redo().result, over.result);
    });
  });

  group('declared results', () {
    test('resignation: the opponent wins and the game is over', () {
      final game = playAll(localGame(), ['d4-e5']).resign(Player.black);
      expect(
        game.result,
        const GameResult.win(Player.white, GameEndReason.resignation),
      );
      expect(game.isOver, isTrue);
      expect(() => game.play(game.state.legalMoves.single), throwsStateError);
      expect(() => game.resign(Player.white), throwsStateError);
      expect(game.canUndo, isFalse, reason: 'a resignation cannot be undone');
      expect(
        game.undo,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('resignation'),
          ),
        ),
      );
    });

    test('timeout: the opponent wins', () {
      final game = Game.start().loseOnTime(Player.white);
      expect(
        game.result,
        const GameResult.win(Player.black, GameEndReason.timeout),
      );
    });

    test('draw by agreement is disabled by default', () {
      expect(() => Game.start().agreeToDraw(), throwsStateError);
    });

    test('draw by agreement when the rules allow it', () {
      final game = Game.start(
        rules: const DhametRules(draw: DrawRules(byAgreement: true)),
      ).agreeToDraw();
      expect(game.result, const GameResult.draw(GameEndReason.agreement));
    });

    test('no declaration once the game is over', () {
      final over = playAll(
        localGame(
          state: stateWith({'e3': Piece.whitePawn, 'e4': Piece.blackPawn}),
        ),
        ['e3xe5'],
      );
      expect(() => over.resign(Player.black), throwsStateError);
      expect(() => over.loseOnTime(Player.black), throwsStateError);
    });
  });
}
