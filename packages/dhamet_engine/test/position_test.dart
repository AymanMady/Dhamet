import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Position', () {
    test('there are 81 intersections indexed row by row', () {
      expect(Position.all, hasLength(81));
      for (var i = 0; i < Position.count; i++) {
        expect(Position.all[i].index, i);
        expect(Position.fromIndex(i), same(Position.all[i]));
      }
      expect(Position(0, 0).notation, 'a1');
      expect(Position(8, 0).notation, 'i1');
      expect(Position(0, 1).notation, 'a2');
      expect(Position(8, 8).notation, 'i9');
    });

    test('parses and formats algebraic notation', () {
      expect(Position.parse('a1'), Position(0, 0));
      expect(Position.parse('i9'), Position(8, 8));
      expect(Position.parse('E5'), Position(4, 4));
      expect(Position.parse(' c7 '), Position(2, 6));
      for (final position in Position.all) {
        expect(Position.parse(position.notation), same(position));
      }
    });

    test('the centre is e5', () {
      expect(Position.center, Position.parse('e5'));
    });

    test('rejects intersections outside the board', () {
      expect(() => Position(9, 0), throwsRangeError);
      expect(() => Position(0, 9), throwsRangeError);
      expect(() => Position(-1, 4), throwsRangeError);
      expect(() => Position.fromIndex(81), throwsRangeError);
      expect(() => Position.fromIndex(-1), throwsRangeError);
      expect(Position.tryAt(9, 0), isNull);
      expect(Position.tryAt(4, -1), isNull);
      expect(Position.isValidCoordinate(8, 8), isTrue);
      expect(Position.isValidCoordinate(8, 9), isFalse);
      for (final text in ['j1', 'a0', 'a10', '', 'e', '55', 'ee']) {
        expect(Position.tryParse(text), isNull, reason: text);
      }
      expect(() => Position.parse('z9'), throwsFormatException);
    });

    test('instances are canonical, equal by value and ordered by index', () {
      expect(Position(4, 4), same(Position.parse('e5')));
      expect(Position(4, 4) == Position.parse('e5'), isTrue);
      expect(Position(4, 4).hashCode, Position.parse('e5').hashCode);
      final sorted = [
        Position.parse('a2'),
        Position.parse('i1'),
        Position.parse('a1'),
      ]..sort();
      expect(sorted.map((p) => p.notation), ['a1', 'i1', 'a2']);
    });
  });

  group('Direction', () {
    test('opposite directions', () {
      expect(Direction.north.opposite, Direction.south);
      expect(Direction.northEast.opposite, Direction.southWest);
      expect(Direction.east.opposite, Direction.west);
      expect(Direction.southEast.opposite, Direction.northWest);
      for (final direction in Direction.values) {
        expect(direction.opposite.opposite, direction);
      }
    });

    test('four diagonal and four orthogonal directions', () {
      expect(Direction.values.where((d) => d.isDiagonal), hasLength(4));
      expect(Direction.values.where((d) => d.isOrthogonal), hasLength(4));
    });
  });

  group('Player and Piece', () {
    test('players advance towards the opponent', () {
      expect(Player.white.opponent, Player.black);
      expect(Player.black.opponent, Player.white);
      expect(Player.white.isForward(Direction.northWest), isTrue);
      expect(Player.white.isBackward(Direction.south), isTrue);
      expect(Player.black.isForward(Direction.southEast), isTrue);
      expect(Player.black.isForward(Direction.east), isFalse);
      expect(Player.black.isBackward(Direction.east), isFalse);
      expect(Player.white.promotionRow, 8);
      expect(Player.black.promotionRow, 0);
    });

    test('pieces know their owner, type and symbol', () {
      expect(Piece.of(Player.white, PieceType.pawn), Piece.whitePawn);
      expect(Piece.of(Player.black, PieceType.sultan), Piece.blackSultan);
      expect(Piece.whitePawn.promoted, Piece.whiteSultan);
      expect(Piece.blackSultan.promoted, Piece.blackSultan);
      expect(Piece.fromSymbol('B'), Piece.blackSultan);
      expect(Piece.fromSymbol('x'), isNull);
      expect(Piece.blackPawn.isPawn, isTrue);
      expect(Piece.whiteSultan.isSultan, isTrue);
    });
  });
}
