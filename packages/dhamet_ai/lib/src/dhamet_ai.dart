import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';

import 'ai_config.dart';
import 'evaluator.dart';
import 'search_result.dart';

/// A computer player.
///
/// The AI knows no rule of its own: it reads the legal moves from
/// [GameState.legalMoves], plays them with [GameState.applyUnchecked] and
/// detects the end of the game with [GameEndDetector]. The move it returns
/// is therefore always legal.
///
/// Search: negamax with alpha-beta pruning (principal variation search),
/// iterative deepening bounded by [AiConfig.maxDepth] and
/// [AiConfig.timeLimit], and a capture extension (quiescence search) while
/// the side to move is forced to capture.
final class DhametAi {
  DhametAi({
    this.config = AiConfig.medium,
    Evaluator? evaluator,
    Random? random,
  }) : evaluator = evaluator ?? const DhametEvaluator(),
       _random = random ?? Random();

  final AiConfig config;
  final Evaluator evaluator;
  final Random _random;

  /// Chooses a move for the side to move in [state].
  ///
  /// With a seeded [Random], the choice is reproducible as long as the
  /// search is bounded by [AiConfig.maxDepth] rather than by the clock.
  ///
  /// [onProgress], if given, receives the move the search would play if it
  /// were stopped now: the first move in search order before searching
  /// (depth 0, score 0), then the choice after each completed iteration.
  /// `chooseMoveInBackground` uses it to answer on time even when the
  /// engine takes long to list the moves of one position.
  ///
  /// Throws a [StateError] if the game is over, i.e. there is no legal
  /// move.
  SearchResult chooseMove(
    GameState state, {
    void Function(SearchResult provisional)? onProgress,
  }) {
    final result = const GameEndDetector().detect(state);
    if (result != null) {
      throw StateError('The game is over: $result');
    }
    return _Search(config, evaluator, _random, onProgress).run(state);
  }
}

typedef _RootScore = ({Move move, int score});

/// Thrown inside the search when the time budget is exhausted.
final class _OutOfTime implements Exception {
  const _OutOfTime();
}

/// The state of one [DhametAi.chooseMove] call.
final class _Search {
  _Search(this.config, this.evaluator, this.random, this.onProgress)
    : _budget = config.timeLimit.inMicroseconds,
      _margin = (config.randomness * _pawn).round();

  static const int _mate = SearchResult.winScore;
  static const int _infinity = 1 << 30;
  static const int _pawn = 100;
  static const int _maxPly = 2 * AiConfig.maxSupportedDepth + 2;
  static const GameEndDetector _detector = GameEndDetector();

  final AiConfig config;
  final Evaluator evaluator;
  final Random random;
  final void Function(SearchResult provisional)? onProgress;
  final int _budget;
  final int _margin;
  final Stopwatch _clock = Stopwatch();
  int _nodes = 0;

  /// Two quiet moves per ply that recently caused a cut-off.
  final List<Move?> _killers = List<Move?>.filled(2 * _maxPly, null);

  /// Cut-off counts of quiet moves, indexed by origin and destination.
  final List<int> _history = List<int>.filled(
    Position.count * Position.count,
    0,
  );

  /// Triangular table holding the principal variation found below each ply.
  final List<List<Move?>> _pv = List.generate(
    _maxPly,
    (_) => List<Move?>.filled(_maxPly, null),
  );
  final List<int> _pvLength = List<int>.filled(_maxPly, 0);

  /// Principal variation of the last completed iteration, tried first.
  List<Move?> _previousPv = const [];

  /// Best root move of the iteration in progress, for when none completes.
  _RootScore? _bestSoFar;

  SearchResult run(GameState root) {
    _clock.start();
    var moves = _order(root, 0);
    onProgress?.call(_result(moves.first, 0, 0));
    if (moves.length == 1) {
      return _result(moves.single, _staticScore(root, moves.single), 0);
    }

    List<_RootScore>? completed;
    var completedDepth = 0;
    for (var depth = 1; depth <= config.maxDepth; depth++) {
      final List<_RootScore> scores;
      try {
        scores = _searchRoot(root, moves, depth);
      } on _OutOfTime {
        break;
      }
      completed = scores;
      completedDepth = depth;
      if (onProgress case final report?) {
        final chosen = _pick(scores);
        report(_result(chosen.move, chosen.score, depth));
      }
      moves = [for (final entry in scores) entry.move];
      if (_isForcedResult(scores.first.score)) break;
      // The next iteration would most likely not finish in time.
      if (_clock.elapsedMicroseconds * 2 > _budget) break;
    }

    if (completed == null) {
      final fallback = _bestSoFar;
      if (fallback != null) return _result(fallback.move, fallback.score, 0);
      return _result(moves.first, _staticScore(root, moves.first), 0);
    }
    final chosen = _pick(completed);
    return _result(chosen.move, chosen.score, completedDepth);
  }

  /// The score of playing [move] from [root], without searching.
  ///
  /// Only a win by elimination is recognised: detecting a blocked opponent
  /// would require its legal moves, which the engine can be slow to list,
  /// and this score is used when there is no time or no need to search.
  int _staticScore(GameState root, Move move) {
    final child = root.applyUnchecked(move);
    if (child.board.count(child.currentPlayer) == 0) return _mate - 1;
    return evaluator.evaluate(child, root.currentPlayer);
  }

  SearchResult _result(Move move, int score, int depth) => SearchResult(
    move: move,
    score: score,
    depth: depth,
    nodes: _nodes,
    elapsed: _clock.elapsed,
  );

  /// Searches every root move to [depth] and returns them sorted by score,
  /// best first.
  ///
  /// With a randomness margin, the window is lowered by that margin so that
  /// every move within it gets an exact score.
  List<_RootScore> _searchRoot(GameState root, List<Move> moves, int depth) {
    _bestSoFar = null;
    _pvLength[0] = 0;
    final scores = <_RootScore>[];
    var best = -_infinity;
    for (var i = 0; i < moves.length; i++) {
      final move = moves[i];
      final child = root.applyUnchecked(move);
      int score;
      if (i == 0) {
        score = -_negamax(child, depth - 1, -_infinity, _infinity, 1);
      } else {
        final floor = best - _margin;
        score = -_negamax(child, depth - 1, -floor - 1, -floor, 1);
        if (score > floor) {
          score = -_negamax(child, depth - 1, -_infinity, -floor, 1);
        }
      }
      scores.add((move: move, score: score));
      if (score > best) {
        best = score;
        _bestSoFar = (move: move, score: score);
        _updatePv(0, move);
      }
    }
    _previousPv = List.of(_pv[0].take(_pvLength[0]));
    return _sortedByScore(scores);
  }

  int _negamax(GameState state, int depth, int alpha, int beta, int ply) {
    _pvLength[ply] = ply;
    _tick();
    final result = _detector.detect(state);
    if (result != null) return _terminalScore(result, state, ply);
    if (depth <= 0 || ply >= _maxPly - 1) {
      return _quiesce(state, alpha, beta, ply, config.quiescenceDepth);
    }
    final moves = _order(state, ply);
    var best = -_infinity;
    for (var i = 0; i < moves.length; i++) {
      final move = moves[i];
      final child = state.applyUnchecked(move);
      int score;
      if (i == 0) {
        score = -_negamax(child, depth - 1, -beta, -alpha, ply + 1);
      } else {
        score = -_negamax(child, depth - 1, -alpha - 1, -alpha, ply + 1);
        if (score > alpha && score < beta) {
          score = -_negamax(child, depth - 1, -beta, -alpha, ply + 1);
        }
      }
      if (score > best) {
        best = score;
        if (score > alpha) {
          alpha = score;
          _updatePv(ply, move);
          if (alpha >= beta) {
            _rememberCutoff(move, depth, ply);
            break;
          }
        }
      }
    }
    return best;
  }

  /// Extends the search while the side to move has captures, so that the
  /// evaluation is never taken in the middle of an exchange.
  ///
  /// When captures are mandatory (the standard rules) the side to move
  /// cannot decline them, so there is no "stand pat" score: every legal
  /// move is searched. The extension stops after [left] plies.
  int _quiesce(GameState state, int alpha, int beta, int ply, int left) {
    final moves = state.legalMoves;
    final mustCapture = moves.every((move) => move.isCapture);
    final canCapture = moves.any((move) => move.isCapture);
    if (left <= 0 || !canCapture || ply >= _maxPly - 1) {
      return evaluator.evaluate(state, state.currentPlayer);
    }
    var best = -_infinity;
    if (!mustCapture) {
      best = evaluator.evaluate(state, state.currentPlayer);
      if (best >= beta) return best;
      if (best > alpha) alpha = best;
    }
    for (final move in _order(state, ply)) {
      if (!move.isCapture) continue;
      final child = state.applyUnchecked(move);
      final score = -_quiesceNode(child, -beta, -alpha, ply + 1, left - 1);
      if (score > best) {
        best = score;
        if (score > alpha) {
          alpha = score;
          _updatePv(ply, move);
          if (alpha >= beta) break;
        }
      }
    }
    return best;
  }

  int _quiesceNode(GameState state, int alpha, int beta, int ply, int left) {
    _pvLength[ply] = ply;
    _tick();
    final result = _detector.detect(state);
    if (result != null) return _terminalScore(result, state, ply);
    return _quiesce(state, alpha, beta, ply, left);
  }

  /// A win or loss outweighs any evaluation; a nearer win scores higher and
  /// a nearer loss lower.
  int _terminalScore(GameResult result, GameState state, int ply) {
    if (result.isDraw) return 0;
    return result.winner == state.currentPlayer ? _mate - ply : ply - _mate;
  }

  static bool _isForcedResult(int score) =>
      score.abs() >= SearchResult.winThreshold;

  void _tick() {
    if ((++_nodes & 15) == 0 && _clock.elapsedMicroseconds >= _budget) {
      throw const _OutOfTime();
    }
  }

  /// The legal moves of [state], most promising first: the move of the
  /// previous principal variation, captures (most pieces, then most
  /// Sultans), promotions, killer moves, then quiet moves by history.
  ///
  /// Capture sequences that take the same pieces and end on the same
  /// intersection by different paths lead to the same position: only the
  /// first one is kept. A flying Sultan can have thousands of them.
  List<Move> _order(GameState state, int ply) {
    final legal = state.legalMoves;
    if (legal.length < 2) return legal;
    final moves = _distinctOutcomes(legal);
    final board = state.board;
    final pvMove = ply < _previousPv.length ? _previousPv[ply] : null;
    final killer1 = _killers[2 * ply];
    final killer2 = _killers[2 * ply + 1];
    final keys = List<int>.filled(moves.length, 0);
    for (var i = 0; i < moves.length; i++) {
      final move = moves[i];
      int key;
      if (move == pvMove) {
        key = 1 << 29;
      } else if (move.isCapture) {
        var sultans = 0;
        for (final position in move.captured) {
          if (board[position]?.isSultan ?? false) sultans++;
        }
        key =
            (1 << 27) +
            (move.captureCount << 16) +
            (sultans << 8) +
            (move.promotes ? 1 : 0);
      } else if (move.promotes) {
        key = 1 << 26;
      } else if (move == killer1) {
        key = (1 << 25) + 1;
      } else if (move == killer2) {
        key = 1 << 25;
      } else {
        key = _history[_historyIndex(move)];
      }
      keys[i] = key;
    }
    final order = List<int>.generate(moves.length, (i) => i)
      ..sort((a, b) {
        final byKey = keys[b].compareTo(keys[a]);
        return byKey != 0 ? byKey : a.compareTo(b);
      });
    return [for (final i in order) moves[i]];
  }

  static List<Move> _distinctOutcomes(List<Move> moves) {
    if (!moves.any((move) => move.captureCount > 1)) return moves;
    final seen = <({int from, int to, int low, int middle, int high})>{};
    return [
      for (final move in moves)
        if (move.captureCount < 2 || seen.add(_outcome(move))) move,
    ];
  }

  /// What a capture sequence changes on the board: its start, its end and
  /// the set of captured intersections (as three 27-bit masks).
  static ({int from, int to, int low, int middle, int high}) _outcome(
    Move move,
  ) {
    var low = 0, middle = 0, high = 0;
    for (final position in move.captured) {
      final index = position.index;
      if (index < 27) {
        low |= 1 << index;
      } else if (index < 54) {
        middle |= 1 << (index - 27);
      } else {
        high |= 1 << (index - 54);
      }
    }
    return (
      from: move.from.index,
      to: move.to.index,
      low: low,
      middle: middle,
      high: high,
    );
  }

  static int _historyIndex(Move move) =>
      move.from.index * Position.count + move.to.index;

  void _rememberCutoff(Move move, int depth, int ply) {
    if (move.isCapture || move.promotes) return;
    if (_killers[2 * ply] != move) {
      _killers[2 * ply + 1] = _killers[2 * ply];
      _killers[2 * ply] = move;
    }
    final index = _historyIndex(move);
    _history[index] += depth * depth;
    if (_history[index] >= 1 << 24) {
      for (var i = 0; i < _history.length; i++) {
        _history[i] >>= 1;
      }
    }
  }

  void _updatePv(int ply, Move move) {
    final line = _pv[ply];
    line[ply] = move;
    final childLength = _pvLength[ply + 1];
    final below = _pv[ply + 1];
    for (var i = ply + 1; i < childLength; i++) {
      line[i] = below[i];
    }
    _pvLength[ply] = childLength > ply + 1 ? childLength : ply + 1;
  }

  /// The best entry of [scores] (sorted, best first), or with a randomness
  /// margin a random entry among those close enough to it.
  _RootScore _pick(List<_RootScore> scores) {
    final best = scores.first;
    if (_margin == 0 || _isForcedResult(best.score)) return best;
    final candidates = [
      for (final entry in scores)
        if (entry.score >= best.score - _margin &&
            !_isForcedResult(entry.score))
          entry,
    ];
    return candidates[(_roll * candidates.length).floor()];
  }

  /// The random draw of this search, taken once so that the choice after
  /// each iteration and the final choice agree.
  late final double _roll = random.nextDouble();

  static List<_RootScore> _sortedByScore(List<_RootScore> scores) {
    final order = List<int>.generate(scores.length, (i) => i)
      ..sort((a, b) {
        final byScore = scores[b].score.compareTo(scores[a].score);
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    return [for (final i in order) scores[i]];
  }
}
