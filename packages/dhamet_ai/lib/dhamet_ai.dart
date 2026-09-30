/// Computer opponent for Dhamet (ظامت), the traditional Mauritanian
/// draughts game.
///
/// The AI relies on `dhamet_engine` for every rule: it only plays moves
/// taken from `GameState.legalMoves`. Pure Dart, no Flutter dependency.
library;

export 'src/ai_config.dart';
export 'src/background.dart';
export 'src/dhamet_ai.dart';
export 'src/evaluator.dart';
export 'src/search_result.dart';
