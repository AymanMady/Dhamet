# dhamet_engine

Pure Dart rules engine for **Dhamet (ظامت)**, the traditional Mauritanian
draughts game. It has no Flutter dependency.

```dart
import 'package:dhamet_engine/dhamet_engine.dart';

var state = GameState.initial();
print(state.legalMoves);                 // [d4-e5, e4-e5, f4-e5]
state = state.play(state.legalMovesMatching('d4-e5').single);
print(state.board);
```

- `BoardTopology.standard` is the graph of lines on the 9×9 board
  (quadruple alquerque pattern).
- `MoveGenerator` returns the legal moves: captures are mandatory and the
  sequence taking the most pieces must be played.
- `DhametRules` holds the configurable rules. `dhametRuleCatalog` gives the
  status of each rule.
- `Game` is an immutable game session with history (`GameHistory`,
  `MoveRecord`), exact undo/redo gated by `UndoPolicy`, end detection
  (`GameEndDetector`) and JSON save/load (`Game.toJson` / `Game.fromJson`).

```dart
var game = Game.start(undoPolicy: UndoPolicy.unlimited); // local game
game = game.play(game.state.legalMoves.first);
game = game.undo();
final saved = jsonEncode(game.toJson());
final restored = Game.fromJson(jsonDecode(saved));
```

The rules, their statuses and their sources are documented in
[`docs/rules.md`](../../docs/rules.md).

```bash
dart test                                   # run the tests
dart test --coverage-path=coverage/lcov.info
dart compile exe benchmark/engine_benchmark.dart -o /tmp/bench && /tmp/bench
```
