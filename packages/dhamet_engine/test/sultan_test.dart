import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Sultan normal moves (sultan.flying)', () {
    test('moves any distance along its eight lines on an open point', () {
      final state = stateWith({'e5': Piece.whiteSultan});
      expect(state.legalMoves, hasLength(32));
      expect(state.legalMoves.every((m) => m.isSultanMove), isTrue);
      expect(
        notations(state.legalMoves),
        containsAll([
          'e5-e9',
          'e5-e1',
          'e5-a5',
          'e5-i5',
          'e5-a1',
          'e5-i9',
          'e5-a9',
          'e5-i1',
        ]),
      );
    });

    test(
      'on a closed point only follows its row and column (French source, b7)',
      () {
        // "Le Sultan b7 ne peut se déplacer que sur la rangée 7 et la colonne b
        // (il n'a pas de diagonale)."
        final state = stateWith({'b7': Piece.whiteSultan});
        expect(state.legalMoves, hasLength(16));
        expect(
          state.legalMoves.every((m) => m.to.row == 6 || m.to.column == 1),
          isTrue,
        );
      },
    );

    test('moves backwards as well as forwards', () {
      final state = stateWith({'e5': Piece.blackSultan}, toMove: Player.black);
      expect(notations(state.legalMoves), containsAll(['e5-e9', 'e5-e1']));
    });

    test('is stopped by any piece in its way', () {
      final state = stateWith({
        'e5': Piece.whiteSultan,
        'e7': Piece.whitePawn,
        'b5': Piece.whitePawn,
      });
      final fromSultan = notations(state.legalMovesFrom(sq('e5')));
      expect(fromSultan, containsAll(['e5-e6', 'e5-d5', 'e5-c5']));
      expect(fromSultan, isNot(contains('e5-e7')));
      expect(fromSultan, isNot(contains('e5-e8')));
      expect(fromSultan, isNot(contains('e5-a5')));
    });

    test('a non-flying Sultan moves one step in every direction', () {
      final state = stateWith({
        'e5': Piece.whiteSultan,
      }, rules: const DhametRules(sultanFlies: false));
      expect(notations(state.legalMoves), {
        'e5-d4', 'e5-e4', 'e5-f4', 'e5-d5', 'e5-f5', 'e5-d6', 'e5-e6', //
        'e5-f6',
      });
    });
  });

  group('Sultan captures', () {
    // "Le Sultan e5 [...] comme il peut capturer le pion c3, il doit le
    // faire, en sautant par-dessus et en se posant sur b2." (a1 is occupied
    // here so that b2 is the only landing, as in the source's example.)
    test('must capture at a distance (French source, diagram 3)', () {
      final state = stateWith({
        'e5': Piece.whiteSultan,
        'c3': Piece.blackPawn,
        'a1': Piece.whitePawn,
      });
      expect(notations(state.legalMoves), {'e5xb2'});
      expect(state.legalMoves.single.captured, [sq('c3')]);
    });

    test(
      'lands on any empty point beyond the piece (sultan.landing, LIKELY)',
      () {
        final state = stateWith({
          'e5': Piece.whiteSultan,
          'c3': Piece.blackPawn,
        });
        expect(notations(state.legalMoves), {'e5xb2', 'e5xa1'});
      },
    );

    test('lands right behind the piece in the immediatelyBehind variant', () {
      final state = stateWith(
        {'e5': Piece.whiteSultan, 'c3': Piece.blackPawn},
        rules: const DhametRules(
          sultanLanding: SultanLanding.immediatelyBehind,
        ),
      );
      expect(notations(state.legalMoves), {'e5xb2'});
    });

    test('the way to the captured piece must be clear', () {
      final blockedByOwn = stateWith({
        'a1': Piece.whiteSultan,
        'b2': Piece.whitePawn,
        'd4': Piece.blackPawn,
      });
      expect(blockedByOwn.mustCapture, isFalse);

      final twoInARow = stateWith({
        'a1': Piece.whiteSultan,
        'c3': Piece.blackPawn,
        'd4': Piece.blackPawn,
      });
      expect(twoInARow.mustCapture, isFalse);
    });

    test('a non-flying Sultan captures by the short leap only', () {
      const rules = DhametRules(sultanFlies: false);
      final distant = stateWith({
        'e5': Piece.whiteSultan,
        'c3': Piece.blackPawn,
      }, rules: rules);
      expect(distant.mustCapture, isFalse);

      final adjacent = stateWith({
        'e5': Piece.whiteSultan,
        'd4': Piece.blackPawn,
      }, rules: rules);
      expect(notations(adjacent.legalMoves), {'e5xc3'});
    });

    test('captures a Sultan like any other piece', () {
      final state = stateWith({
        'e1': Piece.whiteSultan,
        'e6': Piece.blackSultan,
      });
      expect(notations(state.legalMoves), {'e1xe7', 'e1xe8', 'e1xe9'});
    });

    test('multiple capture with changes of direction', () {
      final state = stateWith({
        'a1': Piece.whiteSultan,
        'c3': Piece.blackPawn,
        'f6': Piece.blackPawn,
        'h4': Piece.blackPawn,
      });
      // a1 x c3 (north-east, landing d4 or e5), x f6 (north-east, landing
      // h8 to reach h4), x h4 (south, landing h3, h2 or h1). Landing on g7
      // or i9, or taking h4 from d4 along row 4, only takes two pieces.
      expect(notations(state.legalMoves), {
        'a1xd4xh8xh3',
        'a1xd4xh8xh2',
        'a1xd4xh8xh1',
        'a1xe5xh8xh3',
        'a1xe5xh8xh2',
        'a1xe5xh8xh1',
      });
      for (final move in state.legalMoves) {
        expect(move.captured, [sq('c3'), sq('f6'), sq('h4')]);
      }
    });
  });

  group('captured pieces removal (capture.immediateRemoval)', () {
    // White Sultan e5 takes e4 (landing e2), c2 (landing a2), a3 (landing
    // a4) and then, looking east along row 4, crosses e4 — empty only if
    // captured pieces are removed immediately — to take g4.
    final pieces = {
      'e5': Piece.whiteSultan,
      'e4': Piece.blackPawn,
      'c2': Piece.blackPawn,
      'a3': Piece.blackPawn,
      'g4': Piece.blackPawn,
    };

    test('immediate removal: the Sultan flies over emptied points', () {
      final state = stateWith(pieces);
      expect(notations(state.legalMoves), {'e5xe2xa2xa4xh4', 'e5xe2xa2xa4xi4'});
      expect(state.legalMoves.first.captured.map((p) => p.notation), [
        'e4',
        'c2',
        'a3',
        'g4',
      ]);
    });

    test('removal at the end of the sequence: captured pieces block', () {
      final state = stateWith(
        pieces,
        rules: const DhametRules(
          capturedPieceRemoval: CapturedPieceRemoval.endOfSequence,
        ),
      );
      expect(state.legalMoves.every((m) => m.captureCount == 3), isTrue);
      expect(notations(state.legalMoves), {
        'e5xe2xa2xa4',
        'e5xe2xa2xa5',
        'e5xe2xa2xa6',
        'e5xe2xa2xa7',
        'e5xe2xa2xa8',
        'e5xe2xa2xa9',
      });
    });

    test('a captured piece is never taken twice', () {
      final state = stateWith(
        {'c1': Piece.whiteSultan, 'e1': Piece.blackPawn},
        rules: const DhametRules(
          capturedPieceRemoval: CapturedPieceRemoval.endOfSequence,
        ),
      );
      expect(state.legalMoves.every((m) => m.captureCount == 1), isTrue);
    });
  });

  group('reversing during a capture (sultan.reverseDuringCapture)', () {
    final pieces = {
      'c1': Piece.whiteSultan,
      'b1': Piece.blackPawn,
      'f1': Piece.blackPawn,
    };

    test('allowed by default: west then back east', () {
      final state = stateWith(pieces);
      expect(notations(state.legalMoves), {
        'c1xa1xg1',
        'c1xa1xh1',
        'c1xa1xi1',
        'c1xg1xa1',
        'c1xh1xa1',
        'c1xi1xa1',
      });
    });

    test('forbidden in the variant', () {
      final state = stateWith(
        pieces,
        rules: const DhametRules(sultanMayReverseDuringCapture: false),
      );
      expect(notations(state.legalMoves), {'c1xa1', 'c1xg1', 'c1xh1', 'c1xi1'});
    });
  });

  test('a pawn sequence taking more pieces beats a Sultan capture', () {
    // The Sultan can only take i8 (landing i7, where it is stuck); the pawn
    // takes e4 and e6.
    final state = stateWith({
      'i9': Piece.whiteSultan,
      'i8': Piece.blackPawn,
      'i6': Piece.whitePawn,
      'e3': Piece.whitePawn,
      'e4': Piece.blackPawn,
      'e6': Piece.blackPawn,
    });
    expect(notations(state.legalMoves), {'e3xe5xe7'});

    final free = stateWith({
      'i9': Piece.whiteSultan,
      'i8': Piece.blackPawn,
      'i6': Piece.whitePawn,
      'e3': Piece.whitePawn,
      'e4': Piece.blackPawn,
      'e6': Piece.blackPawn,
    }, rules: const DhametRules(captureChoice: CaptureChoice.free));
    expect(notations(free.legalMoves), {'e3xe5xe7', 'i9xi7'});
  });
}
