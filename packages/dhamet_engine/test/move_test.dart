import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  final step = Move(piece: Piece.whitePawn, from: sq('d4'), path: [sq('e5')]);
  final single = Move(
    piece: Piece.blackPawn,
    from: sq('f6'),
    path: [sq('d4')],
    captured: [sq('e5')],
  );
  final rafle = Move(
    piece: Piece.whitePawn,
    from: sq('e5'),
    path: [sq('c5'), sq('a5')],
    captured: [sq('d5'), sq('b5')],
  );

  test('type, destination and player', () {
    expect(step.type, MoveType.normal);
    expect(single.type, MoveType.capture);
    expect(rafle.type, MoveType.multipleCapture);
    expect(rafle.to, sq('a5'));
    expect(rafle.captureCount, 2);
    expect(single.player, Player.black);
    expect(step.isCapture, isFalse);
    expect(step.isSultanMove, isFalse);
  });

  test('notation lists every landing', () {
    expect(step.notation, 'd4-e5');
    expect(single.notation, 'f6xd4');
    expect(rafle.notation, 'e5xc5xa5');
    final promoting = Move(
      piece: Piece.whitePawn,
      from: sq('d8'),
      path: [sq('d9')],
      promotes: true,
    );
    expect(promoting.toString(), 'd8-d9=S');
  });

  test('matches full and abbreviated notations', () {
    expect(rafle.matchesNotation('e5xc5xa5'), isTrue);
    expect(rafle.matchesNotation('e5xa5'), isTrue);
    expect(rafle.matchesNotation('E5 x A5'), isTrue);
    expect(rafle.matchesNotation('e5xb5xa5'), isFalse);
    expect(rafle.matchesNotation('e5-a5'), isFalse);
    expect(rafle.matchesNotation('e5xa5xc5xa5'), isFalse);
    expect(step.matchesNotation('d4-e5'), isTrue);
    expect(step.matchesNotation('d4xe5'), isFalse);
    expect(step.matchesNotation('d4-e5=S'), isTrue);
    expect(step.matchesNotation('d4'), isFalse);
    expect(step.matchesNotation('d4-z9'), isFalse);
    expect(step.matchesNotation('d4-e5xf6'), isFalse);
  });

  test('equality by value', () {
    final same = Move(
      piece: Piece.whitePawn,
      from: sq('e5'),
      path: [sq('c5'), sq('a5')],
      captured: [sq('d5'), sq('b5')],
    );
    expect(same, rafle);
    expect(same.hashCode, rafle.hashCode);
    final otherRoute = Move(
      piece: Piece.whitePawn,
      from: sq('e5'),
      path: [sq('c5'), sq('a5')],
      captured: [sq('d5'), sq('b4')],
    );
    expect(otherRoute == rafle, isFalse);
    expect(step == single, isFalse);
  });

  test('path and captured lists are immutable copies', () {
    final path = [sq('e5')];
    final move = Move(piece: Piece.whitePawn, from: sq('d4'), path: path);
    path.add(sq('f6'));
    expect(move.path, [sq('e5')]);
    expect(() => move.path.add(sq('a1')), throwsUnsupportedError);
  });

  test('a capture sequence has one captured piece per landing', () {
    expect(
      () => Move(
        piece: Piece.whitePawn,
        from: sq('e5'),
        path: [sq('c5'), sq('a5')],
        captured: [sq('d5')],
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => Move(piece: Piece.whitePawn, from: sq('e5'), path: []),
      throwsA(isA<AssertionError>()),
    );
  });
}
