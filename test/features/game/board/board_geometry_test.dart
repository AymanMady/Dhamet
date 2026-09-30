import 'package:dhamet/features/game/presentation/board/board_geometry.dart';
import 'package:dhamet/features/game/presentation/board/board_surface_painter.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  const geometry = BoardGeometry(470);

  test('every intersection maps back to itself, flipped or not', () {
    for (final g in [geometry, const BoardGeometry(470, flipped: true)]) {
      for (final position in Position.all) {
        expect(g.positionAt(g.center(position)), position);
      }
    }
  });

  test('White is at the bottom, Black when flipped', () {
    expect(
      geometry.center(sq('a1')).dy,
      greaterThan(geometry.center(sq('a9')).dy),
    );
    const flipped = BoardGeometry(470, flipped: true);
    expect(flipped.center(sq('a1')).dy, lessThan(flipped.center(sq('a9')).dy));
    expect(
      flipped.center(sq('a1')).dx,
      greaterThan(flipped.center(sq('i1')).dx),
    );
  });

  test('taps far from any intersection are ignored', () {
    expect(geometry.positionAt(const Offset(-40, -40)), isNull);
    expect(geometry.positionAt(const Offset(1000, 10)), isNull);
  });

  test('a tap on the top of a planted stick selects it', () {
    final board = position({'d4': Piece.whitePawn}).board;
    final top =
        geometry.center(sq('d4')) - Offset(0, geometry.stickHeight * 0.9);
    // Nearer to d5 than to d4, yet on the stick.
    expect(geometry.positionAt(top), sq('d5'));
    expect(geometry.positionAt(top, board: board), sq('d4'));
  });

  test('the stick does not steal taps on the intersection above it', () {
    final board = position({'d4': Piece.whitePawn}).board;
    expect(
      geometry.positionAt(geometry.center(sq('d5')), board: board),
      sq('d5'),
    );
  });

  test('pebbles do not rise above their intersection', () {
    final board = position({'d4': Piece.blackPawn}).board;
    final above =
        geometry.center(sq('d4')) - Offset(0, geometry.stickHeight * 0.9);
    expect(geometry.positionAt(above, board: board), sq('d5'));
  });

  test('the board is traced as 18 rows and columns and 14 diagonals', () {
    final lines = tracedLines(BoardTopology.standard);
    expect(lines.where((line) => !line.isDiagonal), hasLength(18));
    expect(lines.where((line) => line.isDiagonal), hasLength(14));
    // Rows 2, 4, 6, 8 and columns b, d, f, h.
    expect(lines.where((line) => line.traditionallyUndrawn), hasLength(8));
    final rowTwo = lines.singleWhere(
      (line) => !line.isDiagonal && line.from.row == 1 && line.to.row == 1,
    );
    expect(rowTwo.traditionallyUndrawn, isTrue);
    expect((rowTwo.from, rowTwo.to), (sq('a2'), sq('i2')));
  });
}
