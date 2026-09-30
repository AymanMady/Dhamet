import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('GameState', () {
    test('initial state', () {
      final state = GameState.initial();
      expect(state.board, Board.initial());
      expect(state.currentPlayer, Player.white);
      expect(state.rules, DhametRules.standard);
      expect(state.plyCount, 0);
      expect(state.lastMove, isNull);
      expect(state.mustCapture, isFalse);
    });

    test('playing a move switches the turn and records the move', () {
      final start = GameState.initial();
      final move = start.legalMovesMatching('d4-e5').single;
      final next = start.play(move);
      expect(next.currentPlayer, Player.black);
      expect(next.plyCount, 1);
      expect(next.lastMove, move);
      expect(next.board[sq('e5')], Piece.whitePawn);
      expect(next.board.isEmpty(sq('d4')), isTrue);
    });

    test('a state is never modified by playing from it', () {
      final start = GameState.initial();
      start.play(start.legalMoves.first);
      expect(start.board, Board.initial());
      expect(start.currentPlayer, Player.white);
    });

    test('illegal moves are refused with a reason', () {
      final start = GameState.initial();

      Matcher refused(String reason) => throwsA(
        isA<IllegalMoveException>().having(
          (e) => e.reason,
          'reason',
          contains(reason),
        ),
      );

      expect(
        () => start.play(
          Move(piece: Piece.blackPawn, from: sq('e6'), path: [sq('e5')]),
        ),
        refused("white's turn"),
      );
      expect(
        () => start.play(
          Move(piece: Piece.whitePawn, from: sq('e5'), path: [sq('e6')]),
        ),
        refused('no whitePawn on e5'),
      );
      expect(
        () => start.play(
          Move(piece: Piece.whitePawn, from: sq('e3'), path: [sq('e5')]),
        ),
        refused('do not allow'),
      );

      final mustCapture = playNotation(start, 'd4-e5');
      expect(
        () => mustCapture.play(
          Move(piece: Piece.blackPawn, from: sq('e6'), path: [sq('d5')]),
        ),
        throwsA(isA<IllegalMoveException>()),
      );
    });

    test('a non-capturing move is refused when a capture is mandatory', () {
      final state = stateWith({
        'e3': Piece.whitePawn,
        'd3': Piece.blackPawn,
        'a1': Piece.whitePawn,
      });
      expect(
        () => state.play(
          Move(piece: Piece.whitePawn, from: sq('a1'), path: [sq('a2')]),
        ),
        throwsA(
          isA<IllegalMoveException>().having(
            (e) => e.reason,
            'reason',
            contains('capture is mandatory'),
          ),
        ),
      );
    });

    test('a shorter capture is refused when a longer one exists', () {
      final state = stateWith({
        'e3': Piece.whitePawn,
        'd3': Piece.blackPawn,
        'e4': Piece.blackPawn,
        'e6': Piece.blackPawn,
      });
      expect(
        () => state.play(
          Move(
            piece: Piece.whitePawn,
            from: sq('e3'),
            path: [sq('c3')],
            captured: [sq('d3')],
          ),
        ),
        throwsA(
          isA<IllegalMoveException>().having(
            (e) => e.reason,
            'reason',
            contains('more pieces'),
          ),
        ),
      );
    });

    test('applyUnchecked applies a generated move without re-validating', () {
      final start = GameState.initial();
      final next = start.applyUnchecked(start.legalMoves.first);
      expect(next.plyCount, 1);
      expect(next.currentPlayer, Player.black);
    });
  });

  group('traditional opening "rencontre" (French source)', () {
    // "d4-e5 (f6xd4); c3xe5 (a5xc3); b2xd4 (c5xc3); e5xa5 (c3xe5);
    // f5xd5 (d6xd4);... (Les coups des noirs sont indiqués entre
    // parenthèses.)" — White moves first in this source.
    const opening = [
      'd4-e5', 'f6xd4', //
      'c3xe5', 'a5xc3',
      'b2xd4', 'c5xc3',
      'e5xa5', 'c3xe5',
      'f5xd5', 'd6xd4',
    ];

    test('every move is legal under the engine rules', () {
      var state = GameState.initial();
      for (final notation in opening) {
        state = playNotation(state, notation);
      }
      expect(state.plyCount, 10);
      expect(state.board.count(Player.white), 35);
      expect(state.board.count(Player.black), 35);
    });

    test('White then has exactly three ways to take d4', () {
      // "Ce pion d4 peut être pris de trois manières différentes : la prise
      // en d5, la prise en c4, préférée des grands maîtres, et la prise en
      // c5."
      var state = GameState.initial();
      for (final notation in opening) {
        state = playNotation(state, notation);
      }
      expect(notations(state.legalMoves), {'d3xd5', 'e4xc4', 'e3xc5'});

      // "Une fois que les blancs auront pris le pion d4, ils posséderont un
      // avantage matériel d'un pion."
      for (final move in state.legalMoves) {
        final after = state.play(move);
        expect(after.board.count(Player.white), 35);
        expect(after.board.count(Player.black), 34);
      }
    });

    test('the forced replies are the only legal moves', () {
      // After d4-e5, f6xd4 is Black's only move; after it, c3xe5 is White's.
      var state = playNotation(GameState.initial(), 'd4-e5');
      expect(notations(state.legalMoves), {'f6xd4'});
      state = playNotation(state, 'f6xd4');
      expect(notations(state.legalMoves), {'c3xe5'});
    });
  });
}
