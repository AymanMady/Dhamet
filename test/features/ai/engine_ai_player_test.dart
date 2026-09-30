import 'package:dhamet/features/ai/engine_ai_player.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  const ai = EngineAiPlayer(minimumThinkingTime: Duration.zero);

  test('plays a legal move at every level, off the UI thread', () async {
    final state = GameState.initial();
    for (final level in AiLevel.values) {
      final move = await ai.chooseMove(state, level);
      expect(state.legalMoves, contains(move), reason: level.name);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('respects the mandatory maximum capture', () async {
    final state = position({
      'e3': Piece.whitePawn,
      'd3': Piece.blackPawn,
      'e4': Piece.blackPawn,
      'e6': Piece.blackPawn,
      'a9': Piece.blackPawn,
    });
    final move = await ai.chooseMove(state, AiLevel.easy);
    expect(move.notation, 'e3xe5xe7');
  });

  test('waits at least the minimum thinking time', () async {
    const slow = EngineAiPlayer(
      minimumThinkingTime: Duration(milliseconds: 300),
    );
    final stopwatch = Stopwatch()..start();
    await slow.chooseMove(GameState.initial(), AiLevel.easy);
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(300));
  });
}
