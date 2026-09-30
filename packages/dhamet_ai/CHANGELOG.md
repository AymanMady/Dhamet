## 0.1.0 (unreleased)

- `DhametAi`: negamax with alpha-beta pruning (principal variation search),
  iterative deepening bounded by depth and time, capture extension
  (quiescence), killer and history move ordering, distance-to-win scores.
  Moves come only from `GameState.legalMoves`.
- `DhametEvaluator`: material, pawn advancement, home-row guard, exposure
  and hanging-piece terms, with configurable weights (mobility and centre
  terms available, disabled by default).
- `AiDifficulty` and `AiConfig` presets: easy, medium, hard, expert.
- Controlled randomness: picks among the moves within a margin of the best
  score, never instead of a forced win.
- `chooseMoveInBackground`: the search in a background isolate, with a
  watchdog that answers on time even when one position stalls the search
  (`chooseMove(onProgress: …)` reports each completed iteration).
- Benchmark in `benchmark/ai_benchmark.dart`.
