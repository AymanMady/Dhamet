import 'package:dhamet_engine/dhamet_engine.dart';

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
  for (final move in moves) move.notation,
};

/// Plays the unique legal move matching [notation].
GameState playNotation(GameState state, String notation) {
  final matches = state.legalMovesMatching(notation);
  if (matches.length != 1) {
    throw StateError(
      '$notation matches ${matches.length} legal moves; '
      'legal moves are ${notations(state.legalMoves)}',
    );
  }
  return state.play(matches.single);
}

/// A local game (undo allowed) from [state] or the initial position.
Game localGame({GameState? state, DhametRules rules = DhametRules.standard}) =>
    Game.start(
      initialState: state,
      rules: rules,
      undoPolicy: UndoPolicy.unlimited,
    );

/// [game] after the unique legal moves matching [moves], in order.
Game playAll(Game game, List<String> moves) {
  var current = game;
  for (final notation in moves) {
    final matches = current.state.legalMovesMatching(notation);
    if (matches.length != 1) {
      throw StateError(
        '$notation matches ${matches.length} legal moves; '
        'legal moves are ${notations(current.state.legalMoves)}',
      );
    }
    current = current.play(matches.single);
  }
  return current;
}
