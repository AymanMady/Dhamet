import 'package:dhamet/features/game/presentation/animations/move_timeline.dart';
import 'package:dhamet/features/game/presentation/board/board_geometry.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  const geometry = BoardGeometry(470);

  test('a simple move: picked up, carried, put down', () {
    final move = GameState.initial().legalMovesMatching('d4-e5').single;
    final timeline = MoveTimeline(move);
    expect(timeline.position(0, geometry), geometry.center(sq('d4')));
    expect(timeline.position(1, geometry), geometry.center(sq('e5')));
    final midway = [for (var t = 0.0; t <= 1; t += 0.01) t]
        .firstWhere((t) => timeline.along(t) >= 0.5);
    expect(timeline.height(0), 0);
    expect(timeline.height(midway), 1);
    expect(timeline.height(1), 0);
    expect(timeline.hasLanded(0.5), isFalse);
    expect(timeline.hasLanded(1), isTrue);
    expect(timeline.crown(1), 0);
  });

  test('longer paths take longer', () {
    final single = position({'c3': Piece.whitePawn, 'c4': Piece.blackPawn})
        .legalMovesMatching('c3xc5')
        .single;
    final double = position({
      'c3': Piece.whitePawn,
      'c4': Piece.blackPawn,
      'c6': Piece.blackPawn,
    }).legalMoves.single;
    expect(double.path, hasLength(2));
    expect(
      MoveTimeline(double).duration,
      greaterThan(MoveTimeline(single).duration),
    );
  });

  test('each captured piece is taken away as the mover passes over it', () {
    final move = position({
      'c3': Piece.whitePawn,
      'c4': Piece.blackPawn,
      'c6': Piece.blackPawn,
    }).legalMoves.single;
    final timeline = MoveTimeline(move);
    expect(timeline.removal(0, 0), 0);
    expect(timeline.removal(1, 0), 0);
    // Halfway: the first piece is gone, the second one still there.
    final halfway = [for (var t = 0.0; t <= 1; t += 0.01) t]
        .firstWhere((t) => timeline.along(t) >= 1);
    expect(timeline.removal(0, halfway), 1);
    expect(timeline.removal(1, halfway), 0);
    expect(timeline.removal(1, 1), 1);
    // The mover hops over the captured pieces.
    expect(timeline.height(halfway - 0.1), greaterThan(1));
  });

  test('a promotion ends with the crowning', () {
    final move = position({'e8': Piece.whitePawn})
        .legalMovesMatching('e8-e9')
        .single;
    expect(move.promotes, isTrue);
    final timeline = MoveTimeline(move);
    expect(
      timeline.duration,
      greaterThan(
        MoveTimeline(GameState.initial().legalMovesMatching('d4-e5').single)
            .duration,
      ),
    );
    final landing = [for (var t = 0.0; t <= 1; t += 0.01) t]
        .firstWhere(timeline.hasLanded);
    expect(timeline.crown(landing - 0.02), 0);
    expect(timeline.crown(1), 1);
  });
}
