import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Souvlet (souvlet, NEEDS_VERIFICATION)', () {
    test('disabled by default', () {
      expect(DhametRules.standard.souvlet, SouvletRule.disabled);
      expect(SouvletRule.disabled.isEnabled, isFalse);
      expect(SouvletRule.disabled.toString(), 'SouvletRule.disabled');
    });

    test('enabling it is refused until its behaviour is confirmed', () {
      const rules = DhametRules(souvlet: SouvletRule.enabled);
      expect(() => MoveGenerator(rules), throwsUnsupportedError);
      expect(
        () => GameState.initial(rules: rules).legalMoves,
        throwsUnsupportedError,
      );
      expect(() => Game.start(rules: rules).result, throwsUnsupportedError);
    });

    test('the configuration can be saved', () {
      for (final rule in [SouvletRule.disabled, SouvletRule.enabled]) {
        expect(SouvletRule.fromJson(rule.toJson()), same(rule));
      }
    });
  });

  group('opening (opening.rencontre, VARIANT)', () {
    test('free by default', () {
      expect(DhametRules.standard.opening, OpeningRule.free);
      expect(GameState.initial().legalMoves, hasLength(3));
    });

    test('traditional encounter, White first: the script is imposed', () {
      const rules = DhametRules(opening: OpeningRule.traditionalEncounter);
      var state = GameState.initial(rules: rules);
      for (final notation in TraditionalEncounter.whiteFirst) {
        expect(notations(state.legalMoves), {
          state.legalMovesMatching(notation).single.notation,
        });
        state = state.play(state.legalMoves.single);
      }
      // After the script, the three traditional ways to take d4 are free.
      expect(notations(state.legalMoves), {'d3xd5', 'e4xc4', 'e3xc5'});
    });

    test('traditional encounter, Black first: the mirrored script', () {
      const rules = DhametRules(
        startingPlayer: Player.black,
        opening: OpeningRule.traditionalEncounter,
      );
      final script = TraditionalEncounter.sequenceFor(Player.black);
      expect(script.take(4), ['f6-e5', 'd4xf6', 'g7xe5', 'i5xg7']);
      var state = GameState.initial(rules: rules);
      for (final notation in script) {
        expect(state.legalMoves, hasLength(1), reason: notation);
        expect(state.legalMoves.single.matchesNotation(notation), isTrue);
        state = state.play(state.legalMoves.single);
      }
      expect(notations(state.legalMoves), {'f7xf5', 'e6xg6', 'e7xg5'});
    });

    test('not imposed outside the traditional starting position', () {
      const rules = DhametRules(opening: OpeningRule.traditionalEncounter);
      final state = stateWith({
        'e3': Piece.whitePawn,
        'a9': Piece.blackPawn,
      }, rules: rules);
      expect(notations(state.legalMoves), {'e3-d4', 'e3-e4', 'e3-f4'});
    });

    test('the script stops at a move the other rules forbid', () {
      // Without sideways captures, "e5xa5" (7th move) is illegal.
      const rules = DhametRules(
        opening: OpeningRule.traditionalEncounter,
        pawnCapturesSideways: false,
      );
      var state = GameState.initial(rules: rules);
      for (var ply = 0; ply < 6; ply++) {
        expect(state.legalMoves, hasLength(1));
        state = state.play(state.legalMoves.single);
      }
      final free = GameState(
        board: state.board,
        currentPlayer: state.currentPlayer,
        rules: rules.copyWith(opening: OpeningRule.free),
        plyCount: state.plyCount,
      );
      expect(state.legalMoves, free.legalMoves);
      expect(state.legalMovesMatching('e5xa5'), isEmpty);
    });
  });
}
