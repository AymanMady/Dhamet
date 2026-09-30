import 'package:dhamet/app/theme/app_theme.dart';
import 'package:dhamet/features/game/presentation/board/dhamet_board.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers.dart';

/// Hosts a board whose state the test can change.
class _Host extends StatelessWidget {
  const _Host(this.state, {this.onTap, this.animate = true});

  final ValueNotifier<GameState> state;
  final ValueChanged<Position>? onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    home: Center(
      child: SizedBox.square(
        dimension: 400,
        child: ValueListenableBuilder(
          valueListenable: state,
          builder: (context, value, _) =>
              DhametBoard(state: value, onTap: onTap, animate: animate),
        ),
      ),
    ),
  );
}

void main() {
  Future<void> tapAt(WidgetTester tester, Offset local) async {
    final rect = tester.getRect(find.byType(DhametBoard));
    await tester.tapAt(rect.topLeft + local);
    await tester.pump();
  }

  testWidgets('reports taps on intersections and on standing sticks', (
    tester,
  ) async {
    final tapped = <Position>[];
    await tester.pumpWidget(
      _Host(ValueNotifier(GameState.initial()), onTap: tapped.add),
    );
    const geometry = BoardGeometry(400);
    await tapAt(tester, geometry.center(sq('e5')));
    // The top of the stick planted on d4.
    await tapAt(
      tester,
      geometry.center(sq('d4')) - Offset(0, geometry.stickHeight * 0.9),
    );
    expect(tapped, [sq('e5'), sq('d4')]);
  });

  testWidgets('animates a capture to the end', (tester) async {
    final before = position({
      'c3': Piece.whitePawn,
      'c4': Piece.blackPawn,
      'c6': Piece.blackPawn,
    });
    final state = ValueNotifier(before);
    await tester.pumpWidget(_Host(state));
    state.value = before.play(before.legalMoves.single);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animates a promotion to the end', (tester) async {
    final before = position({'e8': Piece.whitePawn, 'a1': Piece.blackPawn});
    final state = ValueNotifier(before);
    await tester.pumpWidget(_Host(state));
    state.value = before.play(before.legalMovesMatching('e8-e9').single);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('without animations, moves are shown at once', (tester) async {
    final before = GameState.initial();
    final state = ValueNotifier(before);
    await tester.pumpWidget(_Host(state, animate: false));
    state.value = before.play(before.legalMovesMatching('d4-e5').single);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('keeps working when the position jumps', (tester) async {
    final state = ValueNotifier(GameState.initial());
    await tester.pumpWidget(_Host(state));
    state.value = position({'a1': Piece.whiteSultan, 'i9': Piece.blackSultan});
    await tester.pumpAndSettle();
    state.value = GameState.initial();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
