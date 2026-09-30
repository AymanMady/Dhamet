import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('promotion (promotion.lastRow)', () {
    test("a white pawn reaching row 9 becomes a Sultan", () {
      final state = stateWith({'d8': Piece.whitePawn});
      expect(notations(state.legalMoves), {'d8-c9', 'd8-d9', 'd8-e9'});
      expect(state.legalMoves.every((m) => m.promotes), isTrue);

      final after = state.play(state.legalMovesMatching('d8-d9').single);
      expect(after.board[sq('d9')], Piece.whiteSultan);
      expect(after.board.count(Player.white, type: PieceType.sultan), 1);
    });

    test('a black pawn reaching row 1 becomes a Sultan', () {
      final state = stateWith({'b2': Piece.blackPawn}, toMove: Player.black);
      expect(notations(state.legalMoves), {'b2-a1', 'b2-b1', 'b2-c1'});
      expect(state.legalMoves.every((m) => m.promotes), isTrue);
      final after = state.play(state.legalMoves.first);
      expect(after.board[state.legalMoves.first.to], Piece.blackSultan);
    });

    test('a pawn not reaching the last row is not promoted', () {
      final state = stateWith({'d7': Piece.whitePawn});
      expect(state.legalMoves.any((m) => m.promotes), isFalse);
    });

    test('a pawn reaching its own home row is not promoted', () {
      final state = stateWith({'e3': Piece.whitePawn, 'e2': Piece.blackPawn});
      final move = state.legalMoves.single;
      expect(move.notation, 'e3xe1');
      expect(move.promotes, isFalse);
    });

    test('a pawn ending a capture on the last row is promoted', () {
      final state = stateWith({'c7': Piece.whitePawn, 'c8': Piece.blackPawn});
      final move = state.legalMoves.single;
      expect(move.notation, 'c7xc9');
      expect(move.promotes, isTrue);
    });

    test('a pawn only passing through the last row is not promoted '
        '(promotion.notDuringCapture)', () {
      // c7 x c8 → c9 (last row), then c9 x d9 → e9, then e9 x e8 → e7.
      final state = stateWith({
        'c7': Piece.whitePawn,
        'c8': Piece.blackPawn,
        'd9': Piece.blackPawn,
        'e8': Piece.blackPawn,
      });
      final move = state.legalMoves.single;
      expect(move.notation, 'c7xc9xe9xe7');
      expect(move.promotes, isFalse);
      final after = state.play(move);
      expect(after.board.pieces, {sq('e7'): Piece.whitePawn});
    });

    test('a Sultan reaching the last row is not promoted again', () {
      final state = stateWith({'e5': Piece.whiteSultan});
      expect(state.legalMoves.any((m) => m.promotes), isFalse);
    });
  });
}
