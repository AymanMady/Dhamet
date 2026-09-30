/// Rules engine for Dhamet (ظامت), the traditional Mauritanian draughts game.
///
/// Pure Dart: no dependency on Flutter, so it can be used by the app, by
/// tests, by tools and by a Dart server alike.
library;

export 'src/board/board.dart';
export 'src/board/board_topology.dart';
export 'src/board/direction.dart';
export 'src/board/position.dart';
export 'src/errors.dart';
export 'src/moves/capture_resolver.dart';
export 'src/moves/move.dart';
export 'src/moves/move_generator.dart';
export 'src/pieces/piece.dart';
export 'src/pieces/player.dart';
export 'src/rules/dhamet_rules.dart';
export 'src/rules/rule_catalog.dart';
export 'src/state/game_state.dart';
