import '../board/board.dart';
import '../board/position.dart';
import '../pieces/player.dart';
import '../rules/dhamet_rules.dart';
import '../rules/opening_rule.dart';
import '../state/game_state.dart';

/// The traditional opening "rencontre" (`opening.rencontre`, VARIANT).
///
/// "Une partie débute par une "rencontre" qui est conventionnellement
/// toujours la même : d4-e5 (f6xd4) ; c3xe5 (a5xc3) ; b2xd4 (c5xc3) ; e5xa5
/// (c3xe5) ; f5xd5 (d6xd4)" — jeuxstrategieter.free.fr, White moving first.
///
/// Only used when [DhametRules.opening] is
/// [OpeningRule.traditionalEncounter]; never imposed by default.
abstract final class TraditionalEncounter {
  /// The sequence as written in the source, when White moves first.
  static const List<String> whiteFirst = [
    'd4-e5', 'f6xd4', //
    'c3xe5', 'a5xc3',
    'b2xd4', 'c5xc3',
    'e5xa5', 'c3xe5',
    'f5xd5', 'd6xd4',
  ];

  /// The sequence for [startingPlayer]. When Black moves first, the same
  /// moves are played by the other side, mirrored by a half-turn of the
  /// board (the starting position is symmetric).
  static List<String> sequenceFor(Player startingPlayer) =>
      startingPlayer == Player.white
      ? whiteFirst
      : [for (final notation in whiteFirst) _mirror(notation)];

  /// The notation of the scripted move to play in [state], or `null` when
  /// [state] is not on the scripted line: the script is over, the game did
  /// not start from the traditional position, or a scripted move is not
  /// legal under [GameState.rules].
  static String? scriptedMoveFor(GameState state) {
    final line = _lineFor(state.rules);
    if (state.plyCount >= line.length) return null;
    final (board, player, notation) = line[state.plyCount];
    return state.board == board && state.currentPlayer == player
        ? notation
        : null;
  }

  static final Map<DhametRules, List<(Board, Player, String)>> _lines = {};

  /// The positions met along the script, replayed with [rules] in free
  /// opening mode so that every scripted move is checked for legality.
  static List<(Board, Player, String)> _lineFor(DhametRules rules) {
    final free = rules.copyWith(opening: OpeningRule.free);
    return _lines[free] ??= () {
      final line = <(Board, Player, String)>[];
      var state = GameState.initial(rules: free);
      for (final notation in sequenceFor(free.startingPlayer)) {
        final matches = state.legalMovesMatching(notation);
        if (matches.length != 1) break;
        line.add((state.board, state.currentPlayer, notation));
        state = state.applyUnchecked(matches.single);
      }
      return List<(Board, Player, String)>.unmodifiable(line);
    }();
  }

  static String _mirror(String notation) =>
      notation.replaceAllMapped(RegExp('[a-i][1-9]'), (match) {
        final position = Position.parse(match[0]!);
        return Position(8 - position.column, 8 - position.row).notation;
      });
}
