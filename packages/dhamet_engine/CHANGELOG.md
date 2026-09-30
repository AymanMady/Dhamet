## 0.2.0 (unreleased)

- `GameEndDetector`: elimination, blocking, optional repetition draw.
- `Game`, `GameHistory`, `MoveRecord`: exact undo/redo, `UndoPolicy`
  (disabled by default, for local games only), resignation, timeout,
  optional draw by agreement.
- JSON serialization of every engine type; versioned `dhamet.game` format
  with replay validation on load.
- `SouvletRule` (disabled; enabling it is refused until confirmed),
  `OpeningRule` (free by default, optional traditional encounter),
  `DrawRules` (none by default).
- `DhametRules.firstPlayer` renamed `startingPlayer`.
- Benchmark in `benchmark/engine_benchmark.dart`.

## 0.1.0

- Board topology (9×9 alquerque pattern), positions, pieces, players.
- Rule configuration (`DhametRules`) and rule status catalog.
- Legal move generation: pawn moves, Sultan moves, mandatory captures,
  multi-captures with maximum-capture rule, promotion.
- `GameState` with validated move application.
