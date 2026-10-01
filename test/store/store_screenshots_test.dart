// Renders the Google Play screenshots from the real app. Run it through
// tool/store/screenshots.sh, which prepares the fonts and converts the
// images to what Google Play accepts.
//
// Writes build/store_screenshots/<language>/*.png (1080 x 1920). Tests have
// no system fonts: the text is set in Roboto merged with Noto Sans Arabic
// (build/store_fonts), as on an Android phone, and the icons come from the
// Flutter SDK. With --dart-define=DHAMET_SERVER=<url>, the home screen shows
// online play, as in a release built with a server. Skipped unless
// STORE_SCREENSHOTS is set.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dhamet/app/app.dart';
import 'package:dhamet/app/router/app_router.dart';
import 'package:dhamet/core/art/game_art.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet/features/game/presentation/controllers/game_controller.dart';
import 'package:dhamet/features/settings/domain/app_settings.dart';
import 'package:dhamet_ai/dhamet_ai.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers.dart';

const enabled = bool.fromEnvironment('STORE_SCREENSHOTS');
final _boundary = GlobalKey();

Future<void> loadFonts() async {
  Future<ByteData> file(String path) async {
    final font = File(path);
    if (!font.existsSync()) {
      throw StateError('$path is missing: see the top of this file.');
    }
    return ByteData.sublistView(await font.readAsBytes());
  }

  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(file('build/store_fonts/RobotoArabic-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(
        file(
          '$flutterRoot/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf',
        ),
      ))
      .load();
  await (FontLoader(
    'ReemKufi',
  )..addFont(rootBundle.load('assets/fonts/ReemKufi.ttf'))).load();
}

/// A middle game between two shallow AIs, with White to move.
GameState middleGame() {
  final ai = DhametAi(
    config: const AiConfig(maxDepth: 2, timeLimit: Duration(seconds: 5)),
    random: Random(11),
  );
  var state = GameState.initial();
  for (var ply = 0; ply < 46; ply++) {
    state = state.play(ai.chooseMove(state).move);
  }
  if (state.currentPlayer != Player.white) {
    state = state.play(ai.chooseMove(state).move);
  }
  return state;
}

void main() {
  late GameArt art;

  setUpAll(() async {
    if (!enabled) return;
    await loadFonts();
  });

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    AppLanguage language,
  ) async {
    art = (await tester.runAsync(() => GameArt.load(rootBundle)))!;
    final container = await testContainer(
      preferences: {
        'settings.language': language.code,
        // As in the release: online play only with a server, e.g.
        // --dart-define=DHAMET_SERVER=https://dhamet-server.onrender.com
        'settings.serverUrl': const String.fromEnvironment('DHAMET_SERVER'),
      },
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          parent: container,
          overrides: [gameArtProvider.overrideWithValue(art)],
        ),
        child: RepaintBoundary(key: _boundary, child: const DhametApp()),
      ),
    );
    await skipSplash(tester);
    return container;
  }

  Future<void> shoot(WidgetTester tester, String language, String name) async {
    await tester.pumpAndSettle();
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/store_screenshots/$language/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
  }

  GoRouter router(WidgetTester tester) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first));

  for (final language in [
    AppLanguage.french,
    AppLanguage.arabic,
    AppLanguage.english,
  ]) {
    final code = language.code;
    testWidgets('screenshots ($code)', skip: !enabled, (tester) async {
      final container = await pump(tester, language);
      await shoot(tester, code, '1_home');

      // A game against the AI, a piece selected with its moves shown.
      final controller = container.read(gameControllerProvider.notifier);
      final state = middleGame();
      controller.startFrom(
        state,
        mode: const AiMode(level: AiLevel.hard, humanSide: Player.white),
      );
      router(tester).go(AppRoutes.game);
      await tester.pumpAndSettle();
      final quiet = state.legalMoves.where((move) => !move.isCapture);
      final move = (quiet.isEmpty ? state.legalMoves : quiet).reduce(
        (a, b) => a.from.row >= b.from.row ? a : b,
      );
      controller.tap(move.from);
      await shoot(tester, code, '2_game');

      router(tester).go(AppRoutes.aiSetup);
      await shoot(tester, code, '3_ai_levels');

      router(tester).go(AppRoutes.tutorial);
      await shoot(tester, code, '4_tutorial');

      controller.close();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
