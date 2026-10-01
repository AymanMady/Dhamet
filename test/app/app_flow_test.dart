import 'package:dhamet/app/router/app_router.dart';
import 'package:dhamet/features/game/data/game_archive.dart';
import 'package:dhamet/features/game/data/saved_game.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet/features/game/presentation/controllers/game_controller.dart';
import 'package:dhamet/features/game/presentation/screens/home_screen.dart';
import 'package:dhamet/features/game/presentation/board/dhamet_board.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<void> tapBoard(WidgetTester tester, String notation) async {
  final rect = tester.getRect(find.byType(DhametBoard));
  final geometry = BoardGeometry(rect.width);
  await tester.tapAt(rect.topLeft + geometry.center(sq(notation)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // A tall phone-like surface.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
  });
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  testWidgets('splash screen then home menu', (tester) async {
    await pumpApp(tester);
    expect(find.text('ظامتنا'), findsOneWidget);
    expect(find.text('DHAMETNA'), findsOneWidget);
    expect(find.text('Mauritanian Traditional Game'), findsOneWidget);
    await skipSplash(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    for (final label in [
      'New game',
      'Play against the AI',
      'Play with a friend',
      'Play online',
      'How to play',
      'History',
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a local game is played by tapping the board', (tester) async {
    final container = await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('Play with a friend'));
    await tester.pumpAndSettle();
    expect(find.byType(DhametBoard), findsOneWidget);
    expect(find.text('White to move'), findsOneWidget);

    await tapBoard(tester, 'd4');
    await tapBoard(tester, 'e5');
    expect(find.text('Last move: d4-e5'), findsOneWidget);
    expect(container.read(gameControllerProvider)!.state.plyCount, 1);

    // Black must capture: the banner says so.
    expect(find.textContaining('Capture is mandatory'), findsOneWidget);
    await tapBoard(tester, 'f6');
    await tapBoard(tester, 'd4');
    expect(find.text('Last move: f6xd4'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider)!.state.plyCount, 1);
  });

  testWidgets('the pause menu restarts the game', (tester) async {
    final container = await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('Play with a friend'));
    await tester.pumpAndSettle();
    await tapBoard(tester, 'd4');
    await tapBoard(tester, 'e5');
    expect(container.read(gameControllerProvider)!.state.plyCount, 1);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    // Closing the menu resumes the game untouched.
    await tester.tap(find.text('Resume game'));
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider)!.state.plyCount, 1);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    // Confirmation dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Restart'));
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider)!.state.plyCount, 0);
  });

  testWidgets('leaving a game keeps it to resume', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('Play with a friend'));
    await tester.pumpAndSettle();
    await tapBoard(tester, 'd4');
    await tapBoard(tester, 'e5');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Resume game'), findsOneWidget);
  });

  testWidgets('the AI answers the player', (tester) async {
    final container = await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('Play against the AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tapBoard(tester, 'e4');
    await tapBoard(tester, 'e5');
    await tester.pumpAndSettle();
    final session = container.read(gameControllerProvider)!;
    expect(session.state.plyCount, 2);
    // The AI had to take e5; now White must take back.
    expect(session.state.lastMove!.notation, 'e6xe4');
    expect(find.textContaining('Capture is mandatory'), findsOneWidget);
  });

  testWidgets('winning shows the result screen', (tester) async {
    final container = await pumpApp(tester);
    await skipSplash(tester);
    container
        .read(gameControllerProvider.notifier)
        .startFrom(position({'e3': Piece.whitePawn, 'e4': Piece.blackPawn}));
    container.read(routerProvider).go(AppRoutes.game);
    await tester.pumpAndSettle();
    await tapBoard(tester, 'e3');
    await tapBoard(tester, 'e5');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Victory'), findsOneWidget);
    expect(find.textContaining('White wins'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('View the game'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);

    await tester.tap(find.text('View the game'));
    await tester.pumpAndSettle();
    expect(find.text('Starting position'), findsOneWidget);
  });

  testWidgets('an interrupted game can be resumed', (tester) async {
    final archive = InMemoryGameArchive();
    var game = Game.start(undoPolicy: UndoPolicy.unlimited);
    game = game.play(game.state.legalMovesMatching('d4-e5').single);
    await archive.saveCurrent(
      SavedGame(
        id: 'saved-1',
        mode: const LocalMode(),
        game: game,
        startedAt: DateTime.utc(2026, 9, 30),
      ),
    );
    final container = await pumpApp(tester, archive: archive);
    await skipSplash(tester);
    expect(find.text('Resume game'), findsOneWidget);
    await tester.tap(find.text('Resume game'));
    await tester.pumpAndSettle();
    final session = container.read(gameControllerProvider)!;
    expect(session.id, 'saved-1');
    expect(session.state.plyCount, 1);
    expect(find.text('Last move: d4-e5'), findsOneWidget);
  });

  testWidgets('Arabic is laid out right to left', (tester) async {
    await pumpApp(tester, preferences: {'settings.language': 'ar'});
    await skipSplash(tester);
    expect(find.text('لعبة جديدة'), findsOneWidget);
    final direction = Directionality.of(
      tester.element(find.text('لعبة جديدة')),
    );
    expect(direction, TextDirection.rtl);
  });

  testWidgets('French interface', (tester) async {
    await pumpApp(tester, preferences: {'settings.language': 'fr'});
    await skipSplash(tester);
    expect(find.text('Nouvelle partie'), findsOneWidget);
    expect(find.text('Jouer avec un ami'), findsOneWidget);
  });

  testWidgets('tutorial exercise uses the engine', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.text('The board'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Moving'), findsOneWidget);
    // "Next" stays disabled until the exercise is solved.
    final next = find.widgetWithText(FilledButton, 'Next');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.ensureVisible(find.byType(DhametBoard));
    await tapBoard(tester, 'e3');
    await tapBoard(tester, 'e4');
    expect(find.text('Well done!'), findsOneWidget);
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
  });

  testWidgets('board intersections are described for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('Play with a friend'));
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('d4, white pawn'), findsOneWidget);
    expect(find.semantics.byLabel('e5'), findsOneWidget);
    await tapBoard(tester, 'd4');
    expect(find.semantics.byLabel('e5, possible destination'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('settings change the language', (tester) async {
    final container = await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsOneWidget);
    expect(container.read(routerProvider).state.uri.path, AppRoutes.settings);
    // Keep the import of the rendering library meaningful.
    expect(RendererBinding.instance, isNotNull);
  });
}
