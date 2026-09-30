import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:test/test.dart';

void main() {
  group('AiConfig.forDifficulty', () {
    final presets = [
      for (final difficulty in AiDifficulty.values)
        AiConfig.forDifficulty(difficulty),
    ];

    test('returns the named presets', () {
      expect(presets, [
        AiConfig.easy,
        AiConfig.medium,
        AiConfig.hard,
        AiConfig.expert,
      ]);
    });

    test('each level searches at least as deep and as long as the one '
        'below, with no more randomness', () {
      for (var i = 1; i < presets.length; i++) {
        final weaker = presets[i - 1];
        final stronger = presets[i];
        expect(stronger.maxDepth, greaterThan(weaker.maxDepth));
        expect(
          stronger.quiescenceDepth,
          greaterThanOrEqualTo(weaker.quiescenceDepth),
        );
        expect(stronger.timeLimit, greaterThan(weaker.timeLimit));
        expect(stronger.randomness, lessThan(weaker.randomness));
      }
    });

    test('easy is shallow and random, expert is deterministic', () {
      expect(AiConfig.easy.maxDepth, lessThanOrEqualTo(2));
      expect(AiConfig.easy.randomness, greaterThanOrEqualTo(1));
      expect(AiConfig.expert.randomness, 0);
    });

    test('time budgets stay mobile friendly', () {
      const budgets = {
        AiDifficulty.easy: Duration(milliseconds: 300),
        AiDifficulty.medium: Duration(milliseconds: 800),
        AiDifficulty.hard: Duration(seconds: 2),
        AiDifficulty.expert: Duration(seconds: 4),
      };
      budgets.forEach((difficulty, budget) {
        expect(
          AiConfig.forDifficulty(difficulty).timeLimit,
          lessThanOrEqualTo(budget),
        );
      });
    });
  });

  test('copyWith replaces only the given fields', () {
    final config = AiConfig.hard.copyWith(
      timeLimit: const Duration(milliseconds: 10),
    );
    expect(config.timeLimit, const Duration(milliseconds: 10));
    expect(config.maxDepth, AiConfig.hard.maxDepth);
    expect(config.quiescenceDepth, AiConfig.hard.quiescenceDepth);
    expect(config.randomness, AiConfig.hard.randomness);
    expect(config, isNot(AiConfig.hard));
    expect(AiConfig.hard.copyWith(), AiConfig.hard);
    expect(AiConfig.hard.copyWith().hashCode, AiConfig.hard.hashCode);
  });
}
