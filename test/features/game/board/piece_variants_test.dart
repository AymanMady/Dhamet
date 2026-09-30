import 'package:dhamet/features/game/presentation/pieces/piece_look.dart';
import 'package:dhamet/features/game/presentation/pieces/piece_variants.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

void main() {
  test('a look is derived from its seed only', () {
    expect(PieceLook.fromSeed(42), same(PieceLook.fromSeed(42)));
    final look = PieceLook.fromSeed(7);
    expect(look.tilt.abs(), lessThanOrEqualTo(0.08));
    expect(look.outline, hasLength(9));
  });

  test('a piece keeps its look when it moves and gets it back on undo', () {
    var game = Game.start(undoPolicy: UndoPolicy.unlimited);
    final variants = PieceVariants(game.state.board);
    final look = variants.lookAt(sq('d4'));
    final move = game.state.legalMovesMatching('d4-e5').single;
    game = game.play(move);
    variants
      ..play(move)
      ..sync(game.state.board);
    expect(variants.lookAt(sq('e5')), same(look));

    game = game.undo();
    variants
      ..takeBack(move)
      ..sync(game.state.board);
    expect(variants.lookAt(sq('d4')), same(look));
  });

  test('captured pieces are forgotten, and come back on undo', () {
    final state = position({'d4': Piece.whitePawn, 'd5': Piece.blackPawn});
    final variants = PieceVariants(state.board);
    final capturedLook = variants.lookAt(sq('d5'));
    final move = state.legalMovesMatching('d4xd6').single;
    final version = variants.version;
    variants.play(move);
    expect(variants.version, greaterThan(version));
    variants.takeBack(move);
    expect(variants.lookAt(sq('d5')), same(capturedLook));
  });

  test('sync gives a look to new pieces and drops the missing ones', () {
    final variants = PieceVariants(position({'a1': Piece.whitePawn}).board);
    final version = variants.version;
    variants.sync(position({'b2': Piece.blackPawn}).board);
    expect(variants.version, greaterThan(version));
    expect(
      variants.lookAt(sq('b2')),
      same(PieceLook.fromSeed(PieceVariants.seedFor(sq('b2')))),
    );
  });
}
