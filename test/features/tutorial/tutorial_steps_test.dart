import 'package:dhamet/features/tutorial/tutorial_steps.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nine lessons, in the order of the rules', () {
    expect(tutorialSteps, hasLength(9));
    expect(tutorialSteps.take(2).every((step) => !step.isExercise), isTrue);
    expect(tutorialSteps.skip(2).every((step) => step.isExercise), isTrue);
  });

  test('every exercise can be solved with a legal move', () {
    for (final step in tutorialSteps.where((s) => s.isExercise)) {
      expect(step.state.legalMoves.where(step.goal!), isNotEmpty);
    }
  });

  test('the multiple capture lesson is the rafle of the source', () {
    final step = tutorialSteps[4];
    expect(step.state.legalMoves.single.notation, 'g7xi5xg3xg5xe7xc9');
  });

  test('the capture lesson shows that capturing is mandatory', () {
    final step = tutorialSteps[3];
    expect(step.state.legalMoves.every((move) => move.isCapture), isTrue);
    expect(step.state.legalMovesFrom(Position.parse('c3')), isEmpty);
  });

  test('the victory lesson ends the game', () {
    final step = tutorialSteps[7];
    final move = step.state.legalMoves.firstWhere(step.goal!);
    expect(
      const GameEndDetector().detect(step.state.play(move)),
      const GameResult.win(Player.white, GameEndReason.elimination),
    );
  });

  test('the special rules lesson needs the longest capture', () {
    final step = tutorialSteps[8];
    expect(step.state.legalMoves.single.captureCount, 2);
  });
}
