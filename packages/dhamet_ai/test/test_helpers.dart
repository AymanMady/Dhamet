import 'dart:math';

import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';

const GameEndDetector detector = GameEndDetector();

/// Shorthand for [Position.parse].
Position sq(String notation) => Position.parse(notation);

/// A game state built from a board diagram (see [Board.parse]).
GameState stateFrom(
  String diagram, {
  Player toMove = Player.white,
  DhametRules rules = DhametRules.standard,
}) =>
    GameState(board: Board.parse(diagram), currentPlayer: toMove, rules: rules);

/// A game state holding only [pieces], keyed by algebraic notation.
GameState stateWith(
  Map<String, Piece> pieces, {
  Player toMove = Player.white,
  DhametRules rules = DhametRules.standard,
}) => GameState(
  board: Board.fromPieces({
    for (final entry in pieces.entries) sq(entry.key): entry.value,
  }),
  currentPlayer: toMove,
  rules: rules,
);

/// The notations of [moves], for readable expectations.
Set<String> notations(Iterable<Move> moves) => {
  for (final move in moves) move.toString(),
};

/// The unique legal move of [state] written [notation].
Move legalMove(GameState state, String notation) =>
    state.legalMovesMatching(notation).single;

/// A search bounded by depth only, so that results are reproducible.
AiConfig depthOnly(int depth, {double randomness = 0, int quiescence = 8}) =>
    AiConfig(
      maxDepth: depth,
      quiescenceDepth: quiescence,
      timeLimit: const Duration(seconds: 60),
      randomness: randomness,
    );

/// A position reached after [plies] random moves from the start.
GameState randomPosition(int seed, int plies) {
  final random = Random(seed);
  var state = GameState.initial();
  for (var ply = 0; ply < plies; ply++) {
    final moves = state.legalMoves;
    if (moves.isEmpty) break;
    state = state.play(moves[random.nextInt(moves.length)]);
  }
  return state;
}

// Engine-only proof search, independent of the AI: it tries every legal
// move, so it proves what the AI is expected to find.

/// Whether the side to move in [state] can force a win within [plies]
/// plies.
bool winsWithin(GameState state, int plies) {
  final result = detector.detect(state);
  if (result != null) return result.winner == state.currentPlayer;
  if (plies <= 0) return false;
  return state.legalMoves.any(
    (move) => losesWithin(state.play(move), plies - 1),
  );
}

/// Whether the side to move in [state] loses by force within [plies] plies.
bool losesWithin(GameState state, int plies) {
  final result = detector.detect(state);
  if (result != null) return result.winner == state.currentPlayer.opponent;
  if (plies <= 0) return false;
  return state.legalMoves.every(
    (move) => winsWithin(state.play(move), plies - 1),
  );
}

/// The legal moves of [state] after which its side to move has a forced win
/// within [plies] plies (counting the move itself).
List<Move> winningMoves(GameState state, int plies) => [
  for (final move in state.legalMoves)
    if (losesWithin(state.play(move), plies - 1)) move,
];
