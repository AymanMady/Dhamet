import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks that the app can use the rules engine package.
void main() {
  test('the app resolves the engine and starts a game', () {
    final state = GameState.initial();
    expect(state.legalMoves.map((m) => m.notation), [
      'd4-e5',
      'e4-e5',
      'f4-e5',
    ]);
  });
}
