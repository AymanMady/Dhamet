import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:dhamet_engine/src/moves/piece_movement.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  final pawnMovement = PawnMovement(
    BoardTopology.standard,
    DhametRules.standard,
  );

  Set<String> jumpLandings(Map<String, Piece> pieces, String from) {
    final board = Board.fromPieces({
      for (final entry in pieces.entries) sq(entry.key): entry.value,
    });
    return {
      for (final step in pawnMovement.captureSteps(
        board,
        sq(from),
        board[sq(from)]!.owner,
      ))
        step.landing.notation,
    };
  }

  group('pawn capture directions (capture.pawnDirections)', () {
    test('open point: eight directions (French source, diagram 2, c7)', () {
      // "le pion blanc c7 peut capturer un pion noir en sautant en a9, c9,
      // e7, c5 ou a5".
      expect(
        jumpLandings({
          'c7': Piece.whitePawn,
          'b8': Piece.blackPawn,
          'c8': Piece.blackPawn,
          'd7': Piece.blackPawn,
          'c6': Piece.blackPawn,
          'b6': Piece.blackPawn,
        }, 'c7'),
        {'a9', 'c9', 'e7', 'c5', 'a5'},
      );
    });

    test('closed point: four directions (French source, diagram 2, g6)', () {
      // "le pion blanc g6 peut prendre en g4, e6, g8 ou i6".
      expect(
        jumpLandings({
          'g6': Piece.whitePawn,
          'g5': Piece.blackPawn,
          'f6': Piece.blackPawn,
          'g7': Piece.blackPawn,
          'h6': Piece.blackPawn,
          'f7': Piece.blackPawn,
          'h5': Piece.blackPawn,
        }, 'g6'),
        {'g4', 'e6', 'g8', 'i6'},
      );
    });

    test('backward capture', () {
      final state = stateWith({'e5': Piece.whitePawn, 'e4': Piece.blackPawn});
      expect(notations(state.legalMoves), {'e5xe3'});

      final forwardOnly = stateWith({
        'e5': Piece.whitePawn,
        'e4': Piece.blackPawn,
      }, rules: const DhametRules(pawnCapturesBackward: false));
      expect(notations(forwardOnly.legalMoves), {'e5-d6', 'e5-e6', 'e5-f6'});
    });

    test('diagonal backward capture by a black pawn', () {
      final state = stateWith({
        'e5': Piece.blackPawn,
        'f6': Piece.whitePawn,
      }, toMove: Player.black);
      expect(notations(state.legalMoves), {'e5xg7'});
    });

    test('sideways capture', () {
      final state = stateWith({'e5': Piece.whitePawn, 'f5': Piece.blackPawn});
      expect(notations(state.legalMoves), {'e5xg5'});

      final noSideways = stateWith({
        'e5': Piece.whitePawn,
        'f5': Piece.blackPawn,
      }, rules: const DhametRules(pawnCapturesSideways: false));
      expect(noSideways.legalMoves.any((m) => m.isCapture), isFalse);
    });

    test('no diagonal capture from a closed point', () {
      final state = stateWith({'d5': Piece.whitePawn, 'e6': Piece.blackPawn});
      expect(notations(state.legalMoves), {'d5-d6'});
    });
  });

  group('impossible captures', () {
    test('a piece of the same side cannot be captured', () {
      final state = stateWith({'e5': Piece.whitePawn, 'e6': Piece.whitePawn});
      expect(state.mustCapture, isFalse);
    });

    test('the landing intersection must be empty', () {
      final state = stateWith({
        'e5': Piece.whitePawn,
        'e6': Piece.blackPawn,
        'e7': Piece.blackPawn,
      });
      expect(state.mustCapture, isFalse);
    });

    test('the landing intersection must be on the board', () {
      final state = stateWith({'e8': Piece.whitePawn, 'e9': Piece.blackPawn});
      expect(state.mustCapture, isFalse);
    });

    test('a pawn only captures an adjacent piece', () {
      final state = stateWith({'e3': Piece.whitePawn, 'e5': Piece.blackPawn});
      expect(state.mustCapture, isFalse);
    });
  });

  group('mandatory capture (capture.mandatory)', () {
    final diagram = '''
      9  . . . . . . . . .
      8  . . . . . . . . .
      7  . . . . . . . . .
      6  . . . . . . . . .
      5  . . . . . . . . .
      4  . . . . . . . . .
      3  . . . b w . . . .
      2  . . . . . . . . .
      1  w . . . . . . . .
         a b c d e f g h i
    ''';

    test('when a capture exists, normal moves are not offered', () {
      final state = stateFrom(diagram);
      expect(state.mustCapture, isTrue);
      expect(notations(state.legalMoves), {'e3xc3'});
      expect(state.legalMovesFrom(sq('a1')), isEmpty);
    });

    test('when capture is optional, normal moves are offered as well', () {
      final state = stateFrom(
        diagram,
        rules: const DhametRules(mandatoryCapture: false),
      );
      expect(notations(state.legalMoves), containsAll(['e3xc3', 'a1-a2']));
    });

    test('hasCapture agrees with the generated moves', () {
      final generator = MoveGenerator.forRules(DhametRules.standard);
      final board = stateFrom(diagram).board;
      // White e3 can take d3, and Black d3 can take e3 as well.
      expect(generator.hasCapture(board, Player.white), isTrue);
      expect(generator.hasCapture(board, Player.black), isTrue);
      expect(generator.hasCapture(Board.initial(), Player.white), isFalse);
      expect(generator.hasCapture(Board.initial(), Player.black), isFalse);
    });
  });

  group('multiple captures', () {
    test('rafle of the French source (diagram 3): g7 i5 g3 g5 e7 c9', () {
      // "le pion blanc g7 exécute la rafle suivante : i5 x g3 x g5 x e7 x c9"
      final state = stateFrom('''
        9  . . . . . . . . .
        8  . . . b . . . . .
        7  . . . . . . w . .
        6  . . . . . b . b .
        5  . . . . . . . . .
        4  . . . . . . b b .
        3  . . . . . . . . .
        2  . . . . . . . . .
        1  . . . . . . . . .
           a b c d e f g h i
      ''');
      expect(state.legalMoves, hasLength(1));
      final move = state.legalMoves.single;
      expect(move.notation, 'g7xi5xg3xg5xe7xc9');
      expect(move.captured.map((p) => p.notation), [
        'h6',
        'h4',
        'g4',
        'f6',
        'd8',
      ]);
      expect(move.type, MoveType.multipleCapture);
      expect(move.promotes, isTrue);

      final after = state.play(move);
      expect(after.board.pieces, {sq('c9'): Piece.whiteSultan});
    });

    test('a sequence cannot be stopped half-way', () {
      final state = stateFrom('''
        9  . . . . . . . . .
        8  . . . . . . . . .
        7  . . . . . . . . .
        6  . . . . b . . . .
        5  . . . . . . . . .
        4  . . . . b . . . .
        3  . . . . w . . . .
        2  . . . . . . . . .
        1  . . . . . . . . .
           a b c d e f g h i
      ''', rules: const DhametRules(captureChoice: CaptureChoice.free));
      expect(notations(state.legalMoves), {'e3xe5xe7'});
    });

    test(
      'the sequence taking the most pieces is compulsory (capture.maximum)',
      () {
        const diagram = '''
        9  . . . . . . . . .
        8  . . . . . . . . .
        7  . . . . . . . . .
        6  . . . . b . . . .
        5  . . . . . . . . .
        4  . . . . b . . . .
        3  . . . b w . . . .
        2  . . . . . . . . .
        1  . . . . . . . . .
           a b c d e f g h i
      ''';
        expect(notations(stateFrom(diagram).legalMoves), {'e3xe5xe7'});

        final free = stateFrom(
          diagram,
          rules: const DhametRules(captureChoice: CaptureChoice.free),
        );
        expect(notations(free.legalMoves), {'e3xe5xe7', 'e3xc3'});
      },
    );

    test('the maximum is computed over all pieces of the side', () {
      // e3 can take one piece, h3 can take two: only h3 may capture.
      final state = stateFrom('''
        9  . . . . . . . . .
        8  . . . . . . . . .
        7  . . . . . . . . .
        6  . . . . . . . b .
        5  . . . . . . . . .
        4  . . . . . . . b .
        3  . . . b w . . w .
        2  . . . . . . . . .
        1  . . . . . . . . .
           a b c d e f g h i
      ''');
      expect(notations(state.legalMoves), {'h3xh5xh7'});
    });

    test('several maximal sequences: the player chooses', () {
      final state = stateWith({
        'e3': Piece.whitePawn,
        'd3': Piece.blackPawn,
        'f3': Piece.blackPawn,
      });
      expect(notations(state.legalMoves), {'e3xc3', 'e3xg3'});
    });

    test('a pawn may change direction and come back to its start', () {
      final state = stateFrom('''
        9  . . . . . . . . .
        8  . . . . . . . . .
        7  . . . . . . . . .
        6  . . . . . . . . .
        5  . . . b . . . . .
        4  . . b . b . . . .
        3  . . w b . . . . .
        2  . . . . . . . . .
        1  . . . . . . . . .
           a b c d e f g h i
      ''');
      // c3 x c4 → c5, c5 x d5 → e5, e5 x e4 → e3, e3 x d3 → c3, or the
      // same loop the other way round.
      expect(notations(state.legalMoves), {'c3xc5xe5xe3xc3', 'c3xe3xe5xc5xc3'});
      final after = state.play(state.legalMoves.first);
      expect(after.board.pieces, {sq('c3'): Piece.whitePawn});
    });
  });

  test('every piece taken during a sequence leaves the board', () {
    final state = stateWith({
      'e5': Piece.whitePawn,
      'd5': Piece.blackPawn,
      'b5': Piece.blackPawn,
    });
    final after = state.play(state.legalMovesMatching('e5xa5').single);
    expect(after.board.pieces, {sq('a5'): Piece.whitePawn});
  });
}
