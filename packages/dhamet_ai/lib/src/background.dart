import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';

import 'ai_config.dart';
import 'dhamet_ai.dart';
import 'evaluator.dart';
import 'search_result.dart';

/// Runs [DhametAi.chooseMove] in a background isolate so that the calling
/// isolate (the user interface) never blocks.
///
/// The answer comes at the latest [grace] after [AiConfig.timeLimit]: the
/// search reports its choice after each completed iteration, and if it has
/// not finished by then (the engine may take long to list the moves of a
/// position with a flying Sultan), the isolate is stopped and the last
/// reported choice is returned. Only if not even the first report has
/// arrived is the answer later.
///
/// [seed] seeds the random choices for reproducible play. [evaluator] is
/// copied into the background isolate, so it must be sendable (the default
/// [DhametEvaluator] is).
///
/// The state travels as JSON and the chosen move is matched back against
/// [state]'s own legal moves, so the returned [SearchResult.move] is one of
/// `state.legalMoves`.
///
/// Completes with a [StateError] if the game is over, and with a
/// [RemoteError] if the search fails in the background isolate.
/// `dart:isolate` is not available on the web; call [DhametAi.chooseMove]
/// there.
Future<SearchResult> chooseMoveInBackground(
  GameState state, {
  required AiConfig config,
  int? seed,
  Evaluator evaluator = const DhametEvaluator(),
  Duration grace = const Duration(milliseconds: 100),
}) async {
  final over = const GameEndDetector().detect(state);
  if (over != null) throw StateError('The game is over: $over');

  final port = ReceivePort();
  final Isolate isolate;
  try {
    isolate = await Isolate.spawn(
      _searchInBackground,
      (port.sendPort, state.toJson(), config, seed, evaluator),
      onError: port.sendPort,
      onExit: port.sendPort,
    );
  } on Object {
    port.close();
    rethrow;
  }

  final answer = Completer<SearchResult>();
  _Report? latest;
  var overdue = false;
  void finish(_Report report) {
    if (!answer.isCompleted) answer.complete(_resultFor(state, report));
  }

  final watchdog = Timer(config.timeLimit + grace, () {
    overdue = true;
    if (latest case final report?) finish(report);
  });
  port.listen((message) {
    switch (message) {
      case (final bool isFinal, final _Report report):
        latest = report;
        if (isFinal || overdue) finish(report);
      case [final Object? error, final Object? stackTrace]:
        if (!answer.isCompleted) {
          answer.completeError(RemoteError('$error', '$stackTrace'));
        }
      case null when !answer.isCompleted:
        answer.completeError(
          StateError('The AI isolate stopped without choosing a move'),
        );
    }
  });

  try {
    return await answer.future;
  } finally {
    watchdog.cancel();
    port.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

/// A [SearchResult] in a form that can be sent between isolates.
typedef _Report = ({
  Map<String, Object?> move,
  int score,
  int depth,
  int nodes,
  int elapsedMicroseconds,
});

void _searchInBackground(
  (SendPort, Map<String, Object?>, AiConfig, int?, Evaluator) message,
) {
  final (port, stateJson, config, seed, evaluator) = message;
  final ai = DhametAi(
    config: config,
    evaluator: evaluator,
    random: seed == null ? null : Random(seed),
  );
  final result = ai.chooseMove(
    GameState.fromJson(stateJson),
    onProgress: (provisional) => port.send((false, _reportOf(provisional))),
  );
  port.send((true, _reportOf(result)));
}

_Report _reportOf(SearchResult result) => (
  move: result.move.toJson(),
  score: result.score,
  depth: result.depth,
  nodes: result.nodes,
  elapsedMicroseconds: result.elapsed.inMicroseconds,
);

SearchResult _resultFor(GameState state, _Report report) {
  final chosen = Move.fromJson(report.move);
  final move = state.legalMoves.firstWhere(
    (legal) => legal == chosen,
    orElse: () => throw StateError('The AI returned an illegal move: $chosen'),
  );
  return SearchResult(
    move: move,
    score: report.score,
    depth: report.depth,
    nodes: report.nodes,
    elapsed: Duration(microseconds: report.elapsedMicroseconds),
  );
}
