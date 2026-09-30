import 'package:dhamet_engine/dhamet_engine.dart';

/// Plays the first moves of the traditional opening and prints the board.
void main() {
  var state = GameState.initial();
  print(state.board);
  print('${state.currentPlayer.name} to move: ${state.legalMoves}');

  for (final notation in ['d4-e5', 'f6xd4', 'c3xe5']) {
    state = state.play(state.legalMovesMatching(notation).single);
    print('\n${state.lastMove}');
  }
  print(state.board);
}
