import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';

import '../game/domain/game_mode.dart';
import 'ai_player.dart';

/// The computer opponent of `packages/dhamet_ai`, searching in a background
/// isolate so the interface never freezes.
class EngineAiPlayer implements AiPlayer {
  const EngineAiPlayer({
    this.minimumThinkingTime = const Duration(milliseconds: 450),
  });

  /// Instant replies are hard to follow on the board: the AI always takes at
  /// least this long.
  final Duration minimumThinkingTime;

  static AiDifficulty difficultyFor(AiLevel level) => switch (level) {
    AiLevel.easy => AiDifficulty.easy,
    AiLevel.medium => AiDifficulty.medium,
    AiLevel.hard => AiDifficulty.hard,
    AiLevel.expert => AiDifficulty.expert,
  };

  @override
  Future<Move> chooseMove(GameState state, AiLevel level) async {
    final results = await Future.wait([
      chooseMoveInBackground(
        state,
        config: AiConfig.forDifficulty(difficultyFor(level)),
      ),
      Future<void>.delayed(minimumThinkingTime),
    ]);
    return (results.first as SearchResult).move;
  }
}
