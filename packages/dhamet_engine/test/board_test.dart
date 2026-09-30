import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('initial position', () {
    final board = Board.initial();

    test('40 pieces per side and an empty centre', () {
      expect(board.count(Player.white), 40);
      expect(board.count(Player.black), 40);
      expect(board.count(Player.white, type: PieceType.sultan), 0);
      expect(board.isEmpty(Position.center), isTrue);
      expect(board.pieces, hasLength(80));
    });

    test('White fills rows 1-4, Black rows 6-9', () {
      for (final p in Position.all) {
        if (p.row < 4) expect(board[p], Piece.whitePawn, reason: '$p');
        if (p.row > 4) expect(board[p], Piece.blackPawn, reason: '$p');
      }
    });

    test('each side has 4 pieces on its right-hand side of row 5', () {
      final row5 = [
        for (var column = 0; column < 9; column++)
          board[Position(column, 4)]?.symbol ?? '.',
      ].join();
      expect(row5, 'bbbb.wwww');
    });

    test('matches the reference diagram', () {
      expect(
        board,
        Board.parse('''
          9  b b b b b b b b b
          8  b b b b b b b b b
          7  b b b b b b b b b
          6  b b b b b b b b b
          5  b b b b . w w w w
          4  w w w w w w w w w
          3  w w w w w w w w w
          2  w w w w w w w w w
          1  w w w w w w w w w
             a b c d e f g h i
        '''),
      );
    });

    test('is symmetric under a half-turn with colours swapped', () {
      for (final p in Position.all) {
        final mirrored = Position(8 - p.column, 8 - p.row);
        expect(board[p]?.owner, board[mirrored]?.owner.opponent, reason: '$p');
      }
    });
  });

  group('diagrams', () {
    test('round trip through toDiagram and parse', () {
      final custom = Board.fromPieces({
        sq('a1'): Piece.whitePawn,
        sq('e5'): Piece.blackSultan,
        sq('i9'): Piece.whiteSultan,
        sq('c7'): Piece.blackPawn,
      });
      for (final board in [Board.initial(), Board.empty(), custom]) {
        expect(Board.parse(board.toDiagram()), board);
      }
    });

    test('row labels and footer are optional', () {
      final board = Board.parse('''
        .........
        .........
        .........
        .........
        ....W....
        .........
        .........
        .........
        b........
      ''');
      expect(board.pieces, {
        sq('e5'): Piece.whiteSultan,
        sq('a1'): Piece.blackPawn,
      });
    });

    test('malformed diagrams are rejected', () {
      expect(() => Board.parse('. . .'), throwsFormatException);
      final unknownSymbol = List.filled(
        9,
        '.........',
      ).join('\n').replaceFirst('.', 'x');
      expect(() => Board.parse(unknownSymbol), throwsFormatException);
      final shortRow = [...List.filled(8, '.........'), '........'].join('\n');
      expect(() => Board.parse(shortRow), throwsFormatException);
      final wrongLabel = [
        '1 .........',
        ...List.filled(8, '.........'),
      ].join('\n');
      expect(() => Board.parse(wrongLabel), throwsFormatException);
    });
  });

  group('queries and updates', () {
    final board = Board.fromPieces({
      sq('a1'): Piece.whitePawn,
      sq('b2'): Piece.whiteSultan,
      sq('e5'): Piece.blackPawn,
    });

    test('count and positionsOf', () {
      expect(board.count(Player.white), 2);
      expect(board.count(Player.white, type: PieceType.pawn), 1);
      expect(board.count(Player.black, type: PieceType.sultan), 0);
      expect(board.positionsOf(Player.white), [sq('a1'), sq('b2')]);
    });

    test('capturable pieces belong to the opponent', () {
      expect(board.isCapturableBy(sq('e5'), Player.white), isTrue);
      expect(board.isCapturableBy(sq('a1'), Player.white), isFalse);
      expect(board.isCapturableBy(sq('c3'), Player.white), isFalse);
    });

    test('withPiece returns a modified copy', () {
      final updated = board.withPiece(sq('a1'), null);
      expect(updated.isEmpty(sq('a1')), isTrue);
      expect(board.isEmpty(sq('a1')), isFalse);
      expect(updated == board, isFalse);
      expect(board.withPiece(sq('c3'), null), board);
      expect(board.withPiece(sq('c3'), null).hashCode, board.hashCode);
    });

    test('applyMove moves the piece, removes captures and promotes', () {
      final start = Board.fromPieces({
        sq('c7'): Piece.whitePawn,
        sq('c8'): Piece.blackPawn,
      });
      final after = start.applyMove(
        Move(
          piece: Piece.whitePawn,
          from: sq('c7'),
          path: [sq('c9')],
          captured: [sq('c8')],
          promotes: true,
        ),
      );
      expect(after.pieces, {sq('c9'): Piece.whiteSultan});
    });

    test('applyMove refuses a move whose piece is not on its origin', () {
      expect(
        () => board.applyMove(
          Move(piece: Piece.whitePawn, from: sq('c3'), path: [sq('c4')]),
        ),
        throwsArgumentError,
      );
      expect(
        () => board.applyMove(
          Move(piece: Piece.whitePawn, from: sq('b2'), path: [sq('b3')]),
        ),
        throwsArgumentError,
      );
    });
  });
}
