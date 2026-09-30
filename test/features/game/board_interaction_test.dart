import 'package:dhamet/features/game/domain/board_interaction.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final initial = GameState.initial();

  test('tapping a piece that can move selects it', () {
    final outcome = resolveTap(initial, null, sq('d4'));
    expect(outcome, isA<SelectPiece>());
    expect((outcome as SelectPiece).position, sq('d4'));
  });

  test('tapping a piece that cannot move clears the selection', () {
    expect(resolveTap(initial, null, sq('a1')), isA<ClearSelection>());
    expect(resolveTap(initial, sq('d4'), sq('e6')), isA<ClearSelection>());
  });

  test('tapping the selected piece again deselects it', () {
    expect(resolveTap(initial, sq('d4'), sq('d4')), isA<ClearSelection>());
  });

  test('tapping a destination plays the move', () {
    final outcome = resolveTap(initial, sq('d4'), sq('e5'));
    expect((outcome as PlayMove).move.notation, 'd4-e5');
  });

  test('tapping another movable piece switches the selection', () {
    final outcome = resolveTap(initial, sq('d4'), sq('f4'));
    expect((outcome as SelectPiece).position, sq('f4'));
  });

  test('several sequences ending on the same point ask for a choice', () {
    // Two loops return the pawn to c3 (see the engine capture tests).
    final state = position({
      'c3': Piece.whitePawn,
      'c4': Piece.blackPawn,
      'd5': Piece.blackPawn,
      'e4': Piece.blackPawn,
      'd3': Piece.blackPawn,
    });
    final outcome = resolveTap(state, sq('c3'), sq('c3'));
    expect(outcome, isA<ChooseMove>());
    expect((outcome as ChooseMove).moves, hasLength(2));
  });

  test('only legal moves are ever proposed', () {
    // A capture is mandatory: the pawn that cannot capture is not selectable.
    final state = position({
      'e3': Piece.whitePawn,
      'd3': Piece.blackPawn,
      'a1': Piece.whitePawn,
    });
    expect(resolveTap(state, null, sq('a1')), isA<ClearSelection>());
    expect(resolveTap(state, null, sq('e3')), isA<SelectPiece>());
  });
}
