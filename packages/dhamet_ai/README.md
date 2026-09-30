# dhamet_ai

Computer opponent for **Dhamet (ظامت)**, the traditional Mauritanian
draughts game. Pure Dart, no Flutter dependency; the rules come from
[`dhamet_engine`](../dhamet_engine).

```dart
import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';

final ai = DhametAi(config: AiConfig.forDifficulty(AiDifficulty.hard));
final result = ai.chooseMove(game.state);   // SearchResult
game = game.play(result.move);

// In the app, search in a background isolate so the UI never blocks:
final result = await chooseMoveInBackground(
  game.state,
  config: AiConfig.forDifficulty(AiDifficulty.hard),
);
```

## Separation from the rules

The AI implements no rule. It reads moves only from `state.legalMoves`,
reaches positions only with `state.applyUnchecked(move)` on those moves,
and detects the end of the game only with `GameEndDetector`. The move it
returns is always an element of `state.legalMoves`: mandatory captures, the
maximum-capture rule, promotion and every rule option (`DhametRules`) are
respected by construction. `chooseMove` throws a `StateError` when the game
is over.

## Search

- **Negamax with alpha-beta pruning**, as a principal variation search
  (null-window search of all moves but the first).
- **Iterative deepening** from depth 1 to `maxDepth`. The clock is checked
  every 16 positions; when `timeLimit` is reached the iteration in progress
  is dropped and the best move of the **last completed iteration** is
  played. A new iteration is not started once half the budget is spent (it
  would almost never finish). If not even depth 1 completes, the best root
  move searched so far, or else the first legal move in search order, is
  played.
- **Capture extension (quiescence)**: at depth 0, while the side to move has
  captures, the search goes on through them, up to `quiescenceDepth` extra
  plies, so the evaluation is never taken in the middle of an exchange.
  Captures being mandatory, the side to move cannot "stand pat": every
  (capture) move is searched. Under the optional-capture variant, standing
  pat is allowed.
- **Terminal scores**: a win `n` plies ahead scores `1 000 000 − n`, a loss
  `n − 1 000 000`, far beyond any evaluation. The AI plays the fastest win
  and the slowest loss, and stops deepening once a forced result is proven
  (`SearchResult.isWin`, `isLoss`, `pliesToForcedEnd`).
- **Move ordering**: move of the previous iteration's principal variation,
  then captures (most pieces, then most Sultans taken), promotions, two
  killer moves per ply, and the history heuristic.
- **Duplicate rafles**: capture sequences that take the same pieces and end
  on the same point by different paths lead to the same position; only one
  is searched. A flying Sultan can have thousands of them.
- **Randomness**: with `randomness = r`, the root is searched with its
  lower bound lowered by `r × 100` points, which gives every move within
  that margin of the best an exact score; one of them is picked uniformly.
  A forced win is always played, a move losing by force never picked. With
  a seeded `Random`, the choice is reproducible (for a search bounded by
  depth rather than by the clock).

## Evaluation

`DhametEvaluator` adds, for each piece, the terms below and returns White's
total minus Black's (negated for Black). All weights are constructor
parameters (penalties are given as positive values).

| Term          | Weight | Counted for                                            |
|---------------|-------:|--------------------------------------------------------|
| `pawn`        | 100    | each pawn                                              |
| `sultan`      | 300    | each Sultan                                            |
| `advancement` | 2      | each row a pawn has advanced                           |
| `homeRow`     | 15     | each pawn still on its home row (guards promotion)     |
| `exposure`    | −3     | each line along which a piece could be jumped: empty point behind it, no friendly piece in front |
| `hanging`     | −40    | each piece of the side to move that an adjacent enemy piece can jump now |
| `mobility`    | 0      | each free step of a pawn / empty point a Sultan reaches |
| `centre`      | 0      | each ring nearer to e5                                 |

It costs about ▲EVAL▲ µs per position, is antisymmetric
(`evaluate(s, white) == −evaluate(s, black)`) and colour-blind (turning the
board around and swapping colours and turn gives the same score).

The weights come from self-play matches at fixed depth: 32 random 8-ply
openings, each played with both colours (64 games; games still running
after 300 plies are not counted; differences below about ±8 games are
noise).

| Change (at depth 2 unless noted)                      | Result (wins–losses) |
|-------------------------------------------------------|----------------------|
| mobility 2 vs material only                           | 10–31                |
| centre 2 vs material only                             | 8–35                 |
| advancement 3 vs material only                        | 32–32                |
| exposure 5 vs material only                           | 42–19                |
| hanging 30 vs material only                           | 49–15                |
| home row 10 vs material only                          | 41–21                |
| Sultan 200 vs 300 (material only)                     | 16–32                |
| hanging 40, home row 15 vs 30, 10 (depth 3)           | 38–20                |
| Sultan 400 vs 300 (depth 3)                           | 31–32                |
| Sultan mobility 1 vs 0 (depth 3)                      | 29–30                |
| without advancement vs advancement 2                  | 23–31                |
| final weights vs material only (depth 3)              | ▲FINAL▲              |

Mobility and centre control, the usual draughts terms, lose in Dhamet:
open space around a piece and the many lines through the central points
are exactly what lets the opponent jump it. They stay available but are
off by default.

## Difficulty levels

| Level  | `maxDepth` | `quiescenceDepth` | `timeLimit` | `randomness` | Measured (desktop) |
|--------|-----------:|------------------:|------------:|-------------:|--------------------|
| easy   | 1          | 2                 | 0.25 s      | 1.5          | ▲EASY▲             |
| medium | 3          | 6                 | 0.7 s       | 0.4          | ▲MEDIUM▲           |
| hard   | 6          | 10                | 1.8 s       | 0.05         | ▲HARD▲             |
| expert | 16         | 16                | 3.5 s       | 0            | ▲EXPERT▲           |

- **Easy** looks one move ahead plus the forced captures that follow, and
  picks at random among the moves within 1.5 pawns of the best: it never
  walks into a large rafle, but it misses threats and often drops a pawn.
- **Medium** sees simple combinations (sacrifice, forced capture,
  recapture) and varies its play among moves within 0.4 pawn.
- **Hard** searches 6 plies; its randomness (0.05 pawn) only breaks ties.
- **Expert** is limited by time, not depth, and never randomises.

Level against level (presets, 8 openings × both colours):
▲MATCHES▲

**Time budgets.** The limits (0.25 / 0.7 / 1.8 / 3.5 s) stay within the
mobile-friendly targets of 0.3 / 0.8 / 2 / 4 s. They are wall-clock bounds:
a phone (3 to 5 times slower than a desktop) answers just as fast and
simply searches one or two plies less, and `chooseMoveInBackground`
guarantees the answer within the limit plus 100 ms. Because a new iteration
is not started after half the budget, the average time per move is well
below the limit. Easy and medium are bounded by depth on a desktop, so they
answer almost instantly; the app may add a short delay for a natural
rhythm.

## Background isolate

`chooseMoveInBackground(state, config: …, seed: …, evaluator: …, grace: …)`
runs the search in a background isolate, so the UI isolate never blocks.

- The state is sent as JSON and the chosen move is matched back against the
  caller's `state.legalMoves`: the result holds the caller's own `Move`.
- **Hard time limit.** The search reports its current choice after each
  completed iteration (`chooseMove(onProgress: …)`). If it has not
  answered `grace` (100 ms) after `timeLimit`, because the engine is stuck
  listing the moves of one position (see limitations), the isolate is
  killed and the last reported choice is returned.
- A seed gives the same move as `DhametAi(random: Random(seed))`; a custom
  evaluator must be sendable to another isolate; errors in the isolate
  surface as a `RemoteError`.
- `dart:isolate` is not available on the web; call `chooseMove` there.

## Tests and benchmark

```bash
dart test                 # ~20 s: legality, rules, tactics, time, isolate
dart compile exe benchmark/ai_benchmark.dart -o /tmp/ai_bench && /tmp/ai_bench
```

The tactical tests use positions whose answer is proven by an engine-only
exhaustive search (`winsWithin` in `test/test_helpers.dart`), so they do
not depend on the evaluation: blocking win, sacrifice leading to a winning
rafle, choice among six promotions, choice among forced captures, and
avoiding a promotion that loses every piece.

## Limitations and ideas

- **Slow positions with a flying Sultan.** The engine lists every capture
  path; with several landing points per jump, one position had 76 800
  maximal sequences (15 pieces) and took 1.9 s to generate on a desktop.
  A single `legalMoves` call cannot be interrupted, so `chooseMove` can
  exceed its time limit on such a node (~1 % of moves in self-play, by up
  to ~0.9 s on an idle desktop, several seconds on a loaded one).
  `chooseMoveInBackground` still answers on time thanks to its watchdog.
  The AI searches each distinct outcome once; the real fix belongs in the
  engine (generate distinct outcomes, or generate lazily).
- No **transposition table**: a Zobrist hash of the board would let the
  search reuse results across transpositions and iterations.
- **Repetition draws** (optional rule, off by default) are ignored: the
  search only sees the current state, not the game history.
- **Evaluation** is deliberately simple and tuned on small matches; ideas:
  Sultan-endgame knowledge (AI-against-AI Sultan endings can shuffle
  without progress), tempo, trapped pieces, the traditional traps (أشرك).
- No **opening book**, no pondering, no time management across the game.
