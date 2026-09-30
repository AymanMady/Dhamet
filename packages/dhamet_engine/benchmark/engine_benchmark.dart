// Measures the engine's main operations on positions from random games.
//
// Run compiled, as in a release build:
//   dart compile exe benchmark/engine_benchmark.dart -o /tmp/dhamet_bench
//   /tmp/dhamet_bench
import 'dart:convert';
import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';

void main() {
  final games = _randomGames(count: 40, maxPlies: 300);
  final records = [for (final game in games) ...game.history.playedMoves];
  final generator = MoveGenerator.forRules(DhametRules.standard);
  print(
    '${games.length} random games, ${records.length} moves '
    '(avg ${(records.length / games.length).toStringAsFixed(0)} plies/game)\n',
  );

  _report('legal move generation', 'position', records.length, () {
    for (final r in records) {
      generator.legalMovesFor(r.stateBefore.board, r.stateBefore.currentPlayer);
    }
  });

  _report('apply move (unchecked)', 'move', records.length, () {
    for (final r in records) {
      r.stateBefore.applyUnchecked(r.move);
    }
  });

  _report(
    'apply move (validated: generation + check)',
    'move',
    records.length,
    () {
      for (final r in records) {
        final before = r.stateBefore;
        GameState(
          board: before.board,
          currentPlayer: before.currentPlayer,
          rules: before.rules,
          plyCount: before.plyCount,
        ).play(r.move);
      }
    },
  );

  _report(
    'Game.play (validation + history + end detection)',
    'move',
    records.length,
    () {
      for (final game in games) {
        var replay = Game.start(undoPolicy: UndoPolicy.unlimited);
        for (final r in game.history.playedMoves) {
          replay = replay.play(r.move);
          replay.result;
        }
      }
    },
  );

  _report('undo', 'undo', records.length, () {
    for (final game in games) {
      var g = game;
      while (g.canUndo) {
        g = g.undo();
      }
    }
  });

  final rewound = [for (final game in games) _rewind(game)];
  _report('redo', 'redo', records.length, () {
    for (final game in rewound) {
      var g = game;
      while (g.canRedo) {
        g = g.redo();
      }
    }
  });

  final texts = [for (final game in games) jsonEncode(game.toJson())];
  final bytes = texts.fold<int>(0, (sum, t) => sum + t.length);
  print(
    'save size: ${(bytes / games.length / 1024).toStringAsFixed(1)} KiB/game '
    '(${(bytes / records.length).toStringAsFixed(0)} bytes/move)',
  );
  _report('serialize (toJson + jsonEncode)', 'game', games.length, () {
    for (final game in games) {
      jsonEncode(game.toJson());
    }
  });
  _report(
    'deserialize (jsonDecode + fromJson, replay checked)',
    'game',
    games.length,
    () {
      for (final text in texts) {
        Game.fromJson(jsonDecode(text));
      }
    },
  );
}

List<Game> _randomGames({required int count, required int maxPlies}) => [
  for (var seed = 0; seed < count; seed++)
    () {
      final random = Random(seed);
      var game = Game.start(undoPolicy: UndoPolicy.unlimited);
      for (var ply = 0; ply < maxPlies && !game.isOver; ply++) {
        final moves = game.state.legalMoves;
        game = game.play(moves[random.nextInt(moves.length)]);
      }
      return game;
    }(),
];

Game _rewind(Game game) {
  var g = game;
  while (g.canUndo) {
    g = g.undo();
  }
  return g;
}

/// Runs [body] once to warm up, then 5 times, and prints the median time per
/// [unit].
void _report(String label, String unit, int operations, void Function() body) {
  body();
  final times = <int>[];
  for (var i = 0; i < 5; i++) {
    final stopwatch = Stopwatch()..start();
    body();
    times.add(stopwatch.elapsedMicroseconds);
  }
  times.sort();
  final perOperation = times[2] / operations;
  final value = perOperation >= 1000
      ? '${(perOperation / 1000).toStringAsFixed(2)} ms'
      : '${perOperation.toStringAsFixed(2)} µs';
  print('${label.padRight(52)} $value / $unit');
}
