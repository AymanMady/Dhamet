import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('pawn normal moves (pawn.move)', () {
    test('examples from the French source (diagram 2): a1, b3, e3', () {
      // "le pion en a1 a le choix entre a2 et b2; celui en b3 ne peut aller
      // qu'en b4; celui en e3, en d4, e4 ou f4."
      final state = stateWith({
        'a1': Piece.whitePawn,
        'b3': Piece.whitePawn,
        'e3': Piece.whitePawn,
      });
      expect(notations(state.legalMovesFrom(sq('a1'))), {'a1-a2', 'a1-b2'});
      expect(notations(state.legalMovesFrom(sq('b3'))), {'b3-b4'});
      expect(notations(state.legalMovesFrom(sq('e3'))), {
        'e3-d4',
        'e3-e4',
        'e3-f4',
      });
    });

    test('a pawn never moves sideways or backwards', () {
      final state = stateWith({'e5': Piece.whitePawn});
      expect(notations(state.legalMoves), {'e5-d6', 'e5-e6', 'e5-f6'});
    });

    test('a pawn on a closed point only moves straight ahead', () {
      final state = stateWith({'d5': Piece.whitePawn});
      expect(notations(state.legalMoves), {'d5-d6'});
    });

    test('black pawns advance towards row 1', () {
      final state = stateWith({
        'e5': Piece.blackPawn,
        'e6': Piece.blackPawn,
      }, toMove: Player.black);
      expect(notations(state.legalMovesFrom(sq('e5'))), {
        'e5-d4',
        'e5-e4',
        'e5-f4',
      });
      expect(notations(state.legalMovesFrom(sq('e6'))), isEmpty);
    });

    test('a pawn cannot move onto an occupied intersection', () {
      final state = stateWith({
        'e5': Piece.whitePawn,
        'e6': Piece.whitePawn,
        'd6': Piece.whitePawn,
      });
      expect(notations(state.legalMovesFrom(sq('e5'))), {'e5-f6'});
    });

    test('moves stop at the edge of the board', () {
      final state = stateWith({'i5': Piece.whitePawn, 'a3': Piece.whitePawn});
      expect(notations(state.legalMovesFrom(sq('i5'))), {'i5-i6', 'i5-h6'});
      expect(notations(state.legalMovesFrom(sq('a3'))), {'a3-a4', 'a3-b4'});
    });

    test('only the pieces of the player to move can move', () {
      final state = stateWith({'a1': Piece.whitePawn, 'i9': Piece.blackPawn});
      expect(state.legalMoves.every((m) => m.player == Player.white), isTrue);
      expect(state.legalMovesFrom(sq('i9')), isEmpty);
      expect(state.legalMovesFrom(sq('e5')), isEmpty);
    });

    test('a blocked player has no legal move', () {
      final state = stateWith({'e8': Piece.whitePawn, 'e9': Piece.blackPawn});
      expect(state.legalMoves, isEmpty);
    });
  });

  group('initial position', () {
    test('White (moving first by default) can only enter the centre', () {
      final state = GameState.initial();
      expect(state.currentPlayer, Player.white);
      expect(notations(state.legalMoves), {'d4-e5', 'e4-e5', 'f4-e5'});
    });

    test('with Black moving first, Black can only enter the centre', () {
      final state = GameState.initial(
        rules: const DhametRules(firstPlayer: Player.black),
      );
      expect(state.currentPlayer, Player.black);
      expect(notations(state.legalMoves), {'d6-e5', 'e6-e5', 'f6-e5'});
    });
  });
}
