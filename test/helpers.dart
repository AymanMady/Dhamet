import 'package:dhamet/app/app.dart';
import 'package:dhamet/core/services/feedback_service.dart';
import 'package:dhamet/features/ai/ai_player.dart';
import 'package:dhamet/features/game/data/game_archive.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet/features/settings/presentation/settings_controller.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Position sq(String notation) => Position.parse(notation);

GameState position(Map<String, Piece> pieces, {Player toMove = Player.white}) =>
    GameState(
      board: Board.fromPieces({
        for (final MapEntry(:key, :value) in pieces.entries) sq(key): value,
      }),
      currentPlayer: toMove,
    );

/// An AI that answers instantly with the first legal move (deterministic).
class FirstMoveAi implements AiPlayer {
  int calls = 0;

  @override
  Future<Move> chooseMove(GameState state, AiLevel level) async {
    calls++;
    return state.legalMoves.first;
  }
}

/// A container with in-memory storage and a deterministic AI.
Future<ProviderContainer> testContainer({
  AiPlayer? ai,
  GameArchive? archive,
  Map<String, Object> preferences = const {},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      aiPlayerProvider.overrideWithValue(ai ?? FirstMoveAi()),
      gameArchiveProvider.overrideWithValue(archive ?? InMemoryGameArchive()),
      feedbackServiceProvider.overrideWithValue(
        const FeedbackService(sound: false, haptics: false),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps the whole app with in-memory storage.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> preferences = const {},
  AiPlayer? ai,
  GameArchive? archive,
}) async {
  final container = await testContainer(
    preferences: preferences,
    ai: ai,
    archive: archive,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DhametApp()),
  );
  return container;
}

/// Lets the splash screen hand over to the home screen.
Future<void> skipSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pumpAndSettle();
}
