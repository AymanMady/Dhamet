import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// [state] with the board turned around, the colours swapped and the other
/// side to move.
GameState mirrored(GameState state) => GameState(
  board: Board.fromPieces({
    for (final MapEntry(key: position, value: piece)
        in state.board.pieces.entries)
      Position(
        Position.size - 1 - position.column,
        Position.size - 1 - position.row,
      ): Piece.of(
        piece.owner.opponent,
        piece.type,
      ),
  }),
  currentPlayer: state.currentPlayer.opponent,
);

void main() {
  const evaluator = DhametEvaluator();

  final positions = [
    GameState.initial(),
    for (var seed = 0; seed < 30; seed++) randomPosition(seed, 10 + seed * 4),
  ];

  test('the symmetric starting position is level', () {
    final state = GameState.initial();
    expect(evaluator.evaluate(state, Player.white), 0);
    expect(evaluator.evaluate(state, Player.black), 0);
  });

  test('is antisymmetric: one side\'s gain is the other\'s loss', () {
    for (final state in positions) {
      expect(
        evaluator.evaluate(state, Player.white),
        -evaluator.evaluate(state, Player.black),
      );
    }
  });

  test('does not depend on the colour names (mirror symmetry)', () {
    for (final state in positions) {
      final mirror = mirrored(state);
      expect(
        evaluator.evaluate(mirror, Player.black),
        evaluator.evaluate(state, Player.white),
        reason: state.board.toDiagram(),
      );
    }
  });

  test('is never close to the scores reserved for forced results', () {
    final crowded = stateWith({
      for (final position in Position.all)
        if (position.row > 0) position.notation: Piece.whiteSultan,
      'a1': Piece.blackPawn,
    });
    expect(
      evaluator.evaluate(crowded, Player.white).abs(),
      lessThan(SearchResult.winThreshold ~/ 10),
    );
  });

  group('material', () {
    test('an extra pawn is an advantage', () {
      final state = GameState.initial();
      final withoutBlackPawn = GameState(
        board: state.board.withPiece(sq('e9'), null),
        currentPlayer: Player.white,
      );
      expect(
        evaluator.evaluate(withoutBlackPawn, Player.white),
        greaterThan(50),
      );
    });

    test('a Sultan is worth more than two pawns', () {
      final pawn = stateWith({'e5': Piece.whitePawn, 'a9': Piece.blackPawn});
      final sultan = stateWith({
        'e5': Piece.whiteSultan,
        'a9': Piece.blackPawn,
      });
      expect(
        evaluator.evaluate(sultan, Player.white),
        greaterThan(evaluator.evaluate(pawn, Player.white) + evaluator.pawn),
      );
    });

    test('weights are configurable', () {
      const materialOnly = DhametEvaluator(
        pawn: 1,
        sultan: 5,
        advancement: 0,
        homeRow: 0,
        exposure: 0,
        hanging: 0,
      );
      final state = stateWith({
        'a1': Piece.whitePawn,
        'c3': Piece.whiteSultan,
        'i9': Piece.blackPawn,
      });
      expect(materialOnly.evaluate(state, Player.white), 1 + 5 - 1);
      expect(materialOnly, isNot(evaluator));
      expect(
        const DhametEvaluator(pawn: 1, sultan: 5).hashCode,
        const DhametEvaluator(pawn: 1, sultan: 5).hashCode,
      );
    });
  });

  group('positional terms', () {
    test('advanced pawns are worth more', () {
      const advancementOnly = DhametEvaluator(
        homeRow: 0,
        exposure: 0,
        hanging: 0,
      );
      final back = stateWith({'e2': Piece.whitePawn, 'a9': Piece.blackPawn});
      final forward = stateWith({'e7': Piece.whitePawn, 'a9': Piece.blackPawn});
      expect(
        advancementOnly.evaluate(forward, Player.white) -
            advancementOnly.evaluate(back, Player.white),
        5 * advancementOnly.advancement,
      );
    });

    test('a piece on an open point is more exposed', () {
      // e7 is crossed by four lines, e8 only by its row and column.
      const exposureOnly = DhametEvaluator(
        advancement: 0,
        homeRow: 0,
        hanging: 0,
      );
      final open = stateWith({'e7': Piece.whitePawn, 'a9': Piece.blackPawn});
      final closed = stateWith({'e8': Piece.whitePawn, 'a9': Piece.blackPawn});
      expect(
        exposureOnly.evaluate(closed, Player.white) -
            exposureOnly.evaluate(open, Player.white),
        4 * exposureOnly.exposure,
      );
    });

    test('a pawn guarding its home row is rewarded', () {
      const homeRowOnly = DhametEvaluator(
        advancement: 0,
        exposure: 0,
        hanging: 0,
      );
      final home = stateWith({'a1': Piece.whitePawn, 'i9': Piece.blackPawn});
      final away = stateWith({'a2': Piece.whitePawn, 'i9': Piece.blackPawn});
      expect(
        homeRowOnly.evaluate(home, Player.white) -
            homeRowOnly.evaluate(away, Player.white),
        homeRowOnly.homeRow,
      );
    });

    test('a piece of the side to move that can be jumped is penalised', () {
      // The black pawn on e6 can jump e5 and land on e4.
      final pieces = {
        'e5': Piece.whitePawn,
        'e6': Piece.blackPawn,
        'a1': Piece.whitePawn,
      };
      final hanging = stateWith(pieces);
      final safe = stateWith({...pieces, 'e4': Piece.whitePawn});
      expect(
        evaluator.evaluate(hanging, Player.white),
        lessThan(evaluator.evaluate(safe, Player.white) - evaluator.pawn),
      );
    });

    test('mobility and centre can be enabled', () {
      const open = DhametEvaluator(
        advancement: 0,
        homeRow: 0,
        exposure: 0,
        hanging: 0,
        mobility: 1,
        centre: 1,
      );
      final centre = stateWith({
        'e5': Piece.whiteSultan,
        'a9': Piece.blackPawn,
      });
      final corner = stateWith({
        'a1': Piece.whiteSultan,
        'i9': Piece.blackPawn,
      });
      expect(
        open.evaluate(centre, Player.white),
        greaterThan(open.evaluate(corner, Player.white)),
      );
    });
  });
}
