import 'package:dhamet/app/theme/app_theme.dart';
import 'package:dhamet/core/art/game_art.dart';
import 'package:dhamet/core/widgets/sand/sand_background.dart';
import 'package:dhamet/core/widgets/wood_button.dart';
import 'package:dhamet/features/game/presentation/board/dhamet_board.dart';
import 'package:dhamet/features/game/presentation/pieces/piece_icon.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('the images cut out of the reference art load', (tester) async {
    final art = (await tester.runAsync(() => GameArt.load(rootBundle)))!;
    // The stick is tall and thin, its foot at the bottom; the plank wide.
    expect(art.stick.height, greaterThan(art.stick.width * 3));
    expect(art.plank.width, greaterThan(art.plank.height * 2));
    expect(art.sand.width, art.sand.height);
    expect(art.scene.height, greaterThan(art.scene.width));
    expect(art.pebble.width, greaterThan(0));
  });

  testWidgets('board, pieces, planks and scene are drawn with the art', (
    tester,
  ) async {
    final art = (await tester.runAsync(() => GameArt.load(rootBundle)))!;
    final state = ValueNotifier(
      position({
        'c3': Piece.whitePawn,
        'c4': Piece.blackPawn,
        'e8': Piece.whitePawn,
        'g7': Piece.blackSultan,
        'a1': Piece.whiteSultan,
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: GameArtScope(
          art: art,
          child: Scaffold(
            body: SandBackground(
              child: Column(
                children: [
                  const Row(
                    children: [
                      PieceIcon(Piece.whiteSultan),
                      PieceIcon(Piece.blackSultan),
                    ],
                  ),
                  WoodButton(label: 'Undo', onPressed: () {}),
                  SizedBox.square(
                    dimension: 360,
                    child: ValueListenableBuilder(
                      valueListenable: state,
                      builder: (context, value, _) => DhametBoard(
                        state: value,
                        selected: sq('c3'),
                        targets: value.legalMovesFrom(sq('c3')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Play the capture, animated with the photographed pieces.
    state.value = state.value.play(
      state.value.legalMovesMatching('c3xc5').single,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsWidgets);
  });
}
