import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/domain/game_mode.dart';

/// Chooses the computer's moves. Implementations must only return moves
/// from `state.legalMoves` and must not block the UI thread.
abstract interface class AiPlayer {
  Future<Move> chooseMove(GameState state, AiLevel level);
}

/// Plays a random legal move. Used as a stand-in and in tests.
class RandomAiPlayer implements AiPlayer {
  RandomAiPlayer([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  Future<Move> chooseMove(GameState state, AiLevel level) async {
    final moves = state.legalMoves;
    if (moves.isEmpty) throw StateError('No legal move');
    return moves[_random.nextInt(moves.length)];
  }
}

final aiPlayerProvider = Provider<AiPlayer>((ref) => RandomAiPlayer());
