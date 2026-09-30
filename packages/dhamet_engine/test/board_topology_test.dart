import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  final topology = BoardTopology.standard;

  Set<String> neighbours(String notation) => {
    for (final p in topology.adjacency[sq(notation)]!) p.notation,
  };

  bool isDiagonalSegment((Position, Position) segment) =>
      segment.$1.column != segment.$2.column &&
      segment.$1.row != segment.$2.row;

  group('open ("wide", لوسع) and closed ("narrow", الظيك) points', () {
    test('examples from the French source', () {
      // "cases ouvertes ou vastes (a1, e3, h4...)",
      // "cases fermées ou étroites (b1, c4, h5...)".
      for (final open in ['a1', 'e3', 'h4']) {
        expect(topology.isOpen(sq(open)), isTrue, reason: open);
      }
      for (final closed in ['b1', 'c4', 'h5']) {
        expect(topology.isOpen(sq(closed)), isFalse, reason: closed);
      }
    });

    test('open points are those whose column + row is even', () {
      for (final p in Position.all) {
        expect(topology.isOpen(p), (p.column + p.row).isEven, reason: '$p');
      }
      expect(Position.all.where(topology.isOpen), hasLength(41));
    });

    test('the four corners and the centre are open', () {
      for (final p in ['a1', 'i1', 'a9', 'i9', 'e5']) {
        expect(topology.isOpen(sq(p)), isTrue, reason: p);
      }
    });

    test('closed points are crossed only by their row and column', () {
      for (final p in Position.all.where((p) => !topology.isOpen(p))) {
        expect(
          topology.directionsFrom(p).every((d) => d.isOrthogonal),
          isTrue,
          reason: '$p',
        );
      }
    });
  });

  group('lines', () {
    test('every row and column is a complete line: 144 segments', () {
      final orthogonal = topology.segments.where((s) => !isDiagonalSegment(s));
      expect(orthogonal, hasLength(2 * 9 * 8));
    });

    test('64 diagonal segments forming 14 diagonal lines', () {
      expect(topology.segments.where(isDiagonalSegment), hasLength(64));
      expect(topology.segments, hasLength(208));

      // A line starts where it has a next point but no previous one.
      var lines = 0;
      for (final p in Position.all) {
        for (final d in [Direction.northEast, Direction.northWest]) {
          if (topology.neighbor(p, d) != null &&
              topology.neighbor(p, d.opposite) == null) {
            lines++;
          }
        }
      }
      expect(lines, 14);
    });

    test('connections of typical intersections', () {
      expect(neighbours('a1'), {'a2', 'b1', 'b2'});
      expect(neighbours('b1'), {'a1', 'c1', 'b2'});
      expect(neighbours('b3'), {'a3', 'c3', 'b2', 'b4'});
      expect(neighbours('e5'), {
        'd4', 'e4', 'f4', 'd5', 'f5', 'd6', 'e6', 'f6', //
      });
      expect(neighbours('i9'), {'h9', 'i8', 'h8'});
      expect(neighbours('e1'), {'d1', 'f1', 'e2', 'd2', 'f2'});
    });

    test('connections are symmetric', () {
      topology.adjacency.forEach((from, tos) {
        for (final to in tos) {
          expect(topology.adjacency[to], contains(from), reason: '$from-$to');
          expect(topology.areConnected(to, from), isTrue);
        }
      });
      expect(topology.areConnected(sq('b1'), sq('c2')), isFalse);
      expect(topology.areConnected(sq('a1'), sq('c3')), isFalse);
    });

    test('rays follow a line to the edge of the board', () {
      expect(
        topology.ray(sq('a1'), Direction.northEast).map((p) => p.notation),
        ['b2', 'c3', 'd4', 'e5', 'f6', 'g7', 'h8', 'i9'],
      );
      expect(topology.ray(sq('e5'), Direction.west).map((p) => p.notation), [
        'd5',
        'c5',
        'b5',
        'a5',
      ]);
      expect(topology.ray(sq('b1'), Direction.northEast), isEmpty);
      expect(topology.ray(sq('a1'), Direction.south), isEmpty);
      expect(topology.neighbor(sq('a1'), Direction.west), isNull);
    });
  });

  test('a custom diagonal pattern changes the graph', () {
    final noDiagonals = BoardTopology(hasDiagonals: (_) => false);
    expect(noDiagonals.segments, hasLength(144));
    expect(noDiagonals.directionsFrom(sq('e5')), hasLength(4));
  });
}
