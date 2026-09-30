import 'dart:isolate';
import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';

import 'ai_config.dart';
import 'dhamet_ai.dart';
import 'evaluator.dart';
import 'search_result.dart';

/// Runs [DhametAi.chooseMove] in a background isolate ([Isolate.run]) so
/// that the calling isolate (the user interface) never blocks.
///
/// [seed] seeds the random choices for reproducible play. [evaluator] is
/// copied into the background isolate, so it must be sendable (the default
/// [DhametEvaluator] is).
///
/// The state travels as JSON and the chosen move is matched back against
/// [state]'s own legal moves, so the returned [SearchResult.move] is one of
/// `state.legalMoves`.
///
/// Completes with a [StateError] if the game is over. `dart:isolate` is not
/// available on the web; call [DhametAi.chooseMove] there.
Future<SearchResult> chooseMoveInBackground(
  GameState state, {
  required AiConfig config,
  int? seed,
  Evaluator evaluator = const DhametEvaluator(),
}) async {
  final over = const GameEndDetector().detect(state);
  if (over != null) throw StateError('The game is over: $over');
  final stateJson = state.toJson();
  final found = await Isolate.run(() {
    final ai = DhametAi(
      config: config,
      evaluator: evaluator,
      random: seed == null ? null : Random(seed),
    );
    final result = ai.chooseMove(GameState.fromJson(stateJson));
    return (
      move: result.move.toJson(),
      score: result.score,
      depth: result.depth,
      nodes: result.nodes,
      elapsed: result.elapsed.inMicroseconds,
    );
  });
  final chosen = Move.fromJson(found.move);
  final move = state.legalMoves.firstWhere(
    (legal) => legal == chosen,
    orElse: () => throw StateError('The AI returned an illegal move: $chosen'),
  );
  return SearchResult(
    move: move,
    score: found.score,
    depth: found.depth,
    nodes: found.nodes,
    elapsed: Duration(microseconds: found.elapsed),
  );
}
