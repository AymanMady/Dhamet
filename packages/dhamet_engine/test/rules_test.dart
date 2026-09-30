import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('DhametRules', () {
    test('defaults follow the documented Mauritanian rules', () {
      const rules = DhametRules.standard;
      expect(rules.startingPlayer, Player.white);
      expect(rules.mandatoryCapture, isTrue);
      expect(rules.captureChoice, CaptureChoice.maximumPieces);
      expect(rules.capturedPieceRemoval, CapturedPieceRemoval.immediate);
      expect(rules.pawnCapturesBackward, isTrue);
      expect(rules.pawnCapturesSideways, isTrue);
      expect(rules.sultanFlies, isTrue);
      expect(rules.sultanLanding, SultanLanding.anyEmptyPointBeyond);
      expect(rules.sultanMayReverseDuringCapture, isTrue);
      expect(rules.opening, OpeningRule.free);
      expect(rules.souvlet, SouvletRule.disabled);
      expect(rules.draw, DrawRules.none);
      expect(rules.draw.isEnabled, isFalse);
    });

    test('copyWith covers the opening, Souvlet and draw settings', () {
      final changed = DhametRules.standard.copyWith(
        opening: OpeningRule.traditionalEncounter,
        souvlet: SouvletRule.enabled,
        draw: const DrawRules(repetitionLimit: 3),
      );
      expect(changed.opening, OpeningRule.traditionalEncounter);
      expect(changed.souvlet.isEnabled, isTrue);
      expect(changed.draw.repetitionLimit, 3);
      expect(changed.startingPlayer, Player.white);
      expect(changed == DhametRules.standard, isFalse);
    });

    test('copyWith changes only the given settings', () {
      const rules = DhametRules.standard;
      final changed = rules.copyWith(
        startingPlayer: Player.black,
        sultanLanding: SultanLanding.immediatelyBehind,
      );
      expect(changed.startingPlayer, Player.black);
      expect(changed.sultanLanding, SultanLanding.immediatelyBehind);
      expect(changed.captureChoice, rules.captureChoice);
      expect(changed == rules, isFalse);
      expect(rules.copyWith(), rules);
      expect(rules.copyWith().hashCode, rules.hashCode);
      expect(
        const DhametRules(sultanFlies: false),
        rules.copyWith(sultanFlies: false),
      );
    });

    test('generators are shared per rule set', () {
      expect(
        MoveGenerator.forRules(const DhametRules()),
        same(MoveGenerator.forRules(DhametRules.standard)),
      );
      expect(
        MoveGenerator.forRules(const DhametRules(sultanFlies: false)),
        isNot(same(MoveGenerator.forRules(DhametRules.standard))),
      );
    });
  });

  group('DrawRules', () {
    test('disabled unless a rule is chosen', () {
      expect(const DrawRules(byAgreement: true).isEnabled, isTrue);
      expect(const DrawRules(repetitionLimit: 3).isEnabled, isTrue);
      expect(
        const DrawRules(repetitionLimit: 3),
        const DrawRules(repetitionLimit: 3),
      );
      expect(
        const DrawRules(repetitionLimit: 3).hashCode,
        const DrawRules(repetitionLimit: 3).hashCode,
      );
      expect(
        DrawRules.none.toString(),
        'DrawRules(byAgreement: false, repetitionLimit: null)',
      );
    });
  });

  group('UndoPolicy', () {
    test('values, equality and JSON', () {
      expect(UndoPolicy.disabled.isEnabled, isFalse);
      expect(UndoPolicy.unlimited.maxDepth, isNull);
      expect(const UndoPolicy.limited(3).maxDepth, 3);
      expect(const UndoPolicy.limited(3), const UndoPolicy.limited(3));
      expect(
        const UndoPolicy.limited(3).hashCode,
        const UndoPolicy.limited(3).hashCode,
      );
      for (final policy in [
        UndoPolicy.disabled,
        UndoPolicy.unlimited,
        const UndoPolicy.limited(3),
      ]) {
        expect(UndoPolicy.fromJson(policy.toJson()), policy);
      }
      expect(UndoPolicy.disabled.toString(), 'UndoPolicy.disabled');
      expect(UndoPolicy.unlimited.toString(), 'UndoPolicy.unlimited');
      expect(const UndoPolicy.limited(3).toString(), 'UndoPolicy.limited(3)');
      expect(
        () => UndoPolicy.fromJson({'enabled': 'yes'}),
        throwsFormatException,
      );
    });
  });

  group('rule catalog', () {
    test('identifiers are unique', () {
      final ids = dhametRuleCatalog.map((rule) => rule.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every uncertain rule that is implemented has a setting', () {
      for (final rule in dhametRuleCatalog) {
        if (rule.implemented && rule.status != RuleStatus.confirmed) {
          expect(rule.setting, isNotNull, reason: rule.id);
        }
      }
    });

    test('lists the rules still to verify', () {
      final toVerify = {
        for (final rule in dhametRuleCatalog)
          if (rule.status == RuleStatus.needsVerification) rule.id,
      };
      expect(
        toVerify,
        containsAll([
          'turn.startingPlayer',
          'sultan.reverseDuringCapture',
          'souvlet',
          'end.draw',
        ]),
      );
    });
  });

  test('IllegalMoveException describes the move and the reason', () {
    final exception = IllegalMoveException(
      Move(piece: Piece.whitePawn, from: sq('e3'), path: [sq('e5')]),
      'the rules do not allow it',
    );
    expect(exception.toString(), contains('e3-e5'));
    expect(exception.toString(), contains('the rules do not allow it'));
  });
}
