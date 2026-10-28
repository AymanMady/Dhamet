// Films the app for the demo video: a scripted visit of the real app in
// Arabic, rendered image by image like the store screenshots. Run it through
// tool/marketing/render.sh, which then adds the captions, the opening and
// closing cards and the sound.
//
// Writes build/demo_video/app.mkv (1080 x 1920, 30 images per second) and
// build/demo_video/timeline.json: the scenes, the taps (to draw the finger)
// and the cuts between scenes. Needs ffmpeg and the fonts prepared by
// tool/store/make_screenshot_fonts.py. Skipped unless DEMO_VIDEO is set.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dhamet/app/app.dart';
import 'package:dhamet/app/router/app_router.dart';
import 'package:dhamet/core/art/game_art.dart';
import 'package:dhamet/core/localization/l10n.dart';
import 'package:dhamet/features/ai/ai_player.dart';
import 'package:dhamet/features/game/data/game_archive.dart';
import 'package:dhamet/features/game/data/saved_game.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet/features/game/presentation/board/dhamet_board.dart';
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
import '../store/store_screenshots_test.dart' show loadFonts;

const enabled = bool.fromEnvironment('DEMO_VIDEO');
const fps = 30;
const output = 'build/demo_video';
final _boundary = GlobalKey();

/// A position from a game between two AIs, White to move: White gives up
/// c4-c5, Black must take two aouds, and White answers with a rafle of six
/// baaras that ends on the last row. The new Dhayma then takes two more
/// from afar.
final rafleGame = GameState(
  board: Board.parse('''
    9  b b . b . b . . b
    8  b b b b . . . b b
    7  b b b b . . b b b
    6  b b b b . . . . .
    5  w . . b . . . . w
    4  w . w w . w w . .
    3  w w . w w . w w .
    2  w w . . w w w . w
    1  w . w w w . . w w
  '''),
  currentPlayer: Player.white,
  plyCount: 58,
);

/// The computer's answers in the video, played after a moment of thought.
class ScriptedAi implements AiPlayer {
  ScriptedAi(this.moves);

  final List<String> moves;
  var _next = 0;

  @override
  Future<Move> chooseMove(GameState state, AiLevel level) async {
    // Past the script, the computer keeps thinking until the scene ends.
    if (_next == moves.length) return Completer<Move>().future;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return state.legalMovesMatching(moves[_next++]).single;
  }
}

/// A finished game between two weak AIs, won by [winner], for the history
/// screen.
SavedGame finishedGame(GameMode mode, Player winner, DateTime startedAt) {
  for (var seed = startedAt.day * 100; ; seed++) {
    final ai = DhametAi(
      config: const AiConfig(
        maxDepth: 1,
        timeLimit: Duration(seconds: 1),
        randomness: 1.5,
      ),
      random: Random(seed),
    );
    var game = Game.start(undoPolicy: UndoPolicy.unlimited);
    var time = startedAt;
    while (!game.isOver && game.state.plyCount < 600) {
      time = time.add(const Duration(seconds: 7));
      game = game.play(ai.chooseMove(game.state).move, timestamp: time);
    }
    if (game.result?.winner == winner) {
      return SavedGame(
        id: 'demo-${startedAt.day}',
        mode: mode,
        game: game,
        startedAt: startedAt,
        finishedAt: time,
      );
    }
  }
}

/// Films the app: each [wait] lets time pass and records one image per
/// frame; taps and scenes are noted for the captions.
class Recorder {
  Recorder(this.tester);

  final WidgetTester tester;
  late final Process _ffmpeg;
  var frames = 0;
  final _scenes = <Map<String, Object>>[];
  final _taps = <Map<String, Object>>[];
  final _drags = <Map<String, Object>>[];
  final _cuts = <int>[];

  Future<void> start() async {
    await tester.runAsync(() async {
      await Directory(output).create(recursive: true);
      _ffmpeg = await Process.start('ffmpeg', [
        '-y', '-loglevel', 'error', //
        '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '1080x1920',
        '-r', '$fps', '-i', '-',
        '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '8',
        '-pix_fmt', 'yuv444p', '$output/app.mkv',
      ]);
      _ffmpeg.stderr.listen(stderr.add);
    });
  }

  Future<void> _frame() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      _ffmpeg.stdin.add(pixels!.buffer.asUint8List());
      await _ffmpeg.stdin.flush();
    });
    frames++;
  }

  /// Lets [duration] pass in the app, filming it.
  Future<void> wait(Duration duration) async {
    final count = (duration.inMicroseconds * fps / 1e6).round();
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(microseconds: 1000000 ~/ fps));
      await _frame();
    }
  }

  Future<void> waitMs(int milliseconds) =>
      wait(Duration(milliseconds: milliseconds));

  /// Starts the scene [id]; the captions are chosen by id.
  void scene(String id) {
    if (_scenes.isNotEmpty) _scenes.last['end'] = frames;
    _scenes.add({'id': id, 'start': frames});
  }

  /// Marks a jump in the app, which the video softens with a fade.
  void cut() => _cuts.add(frames);

  /// A finger tap at [at], in logical pixels.
  Future<void> tapAt(Offset at) async {
    _taps.add({'frame': frames, 'x': at.dx, 'y': at.dy});
    await tester.tapAt(at);
  }

  Future<void> tap(Finder finder) => tapAt(tester.getCenter(finder.first));

  /// A finger slid from [from] by [by] over [duration], e.g. to scroll.
  Future<void> drag(Offset from, Offset by, Duration duration) async {
    final gesture = await tester.startGesture(from);
    final count = (duration.inMicroseconds * fps / 1e6).round();
    final points = <List<double>>[];
    _drags.add({'frame': frames, 'points': points});
    for (var i = 1; i <= count; i++) {
      final at = from + by * Curves.easeInOut.transform(i / count);
      points.add([at.dx, at.dy]);
      await gesture.moveTo(at);
      await tester.pump(const Duration(microseconds: 1000000 ~/ fps));
      await _frame();
    }
    await gesture.up();
  }

  /// A tap on the intersection [square] of the board on screen.
  Future<void> tapSquare(String square) {
    final board = find.descendant(
      of: find.byType(DhametBoard),
      matching: find.byType(GestureDetector),
    );
    final rect = tester.getRect(board.first);
    final geometry = BoardGeometry(rect.shortestSide);
    return tapAt(rect.topLeft + geometry.center(Position.parse(square)));
  }

  Future<void> finish() async {
    _scenes.last['end'] = frames;
    await tester.runAsync(() async {
      await _ffmpeg.stdin.close();
      final code = await _ffmpeg.exitCode;
      if (code != 0) throw StateError('ffmpeg failed ($code)');
      await File('$output/timeline.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'fps': fps,
          'size': [1080, 1920],
          'logicalSize': [360, 640],
          'frames': frames,
          'scenes': _scenes,
          'taps': _taps,
          'drags': _drags,
          'cuts': _cuts,
        }),
      );
    });
  }
}

void main() {
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

  testWidgets('demo video', skip: !enabled, (tester) async {
    final l10n = lookupAppLocalizations(AppLanguage.arabic.locale);
    final archive = InMemoryGameArchive();
    // Oldest first: the history lists the latest game at the top.
    final history = [
      (2, AiLevel.easy, Player.white),
      (4, AiLevel.expert, Player.black),
      (5, AiLevel.medium, Player.white),
      (7, null, Player.black),
      (8, AiLevel.hard, Player.white),
    ];
    for (final (day, level, winner) in history) {
      final mode = level == null
          ? const LocalMode()
          : AiMode(level: level, humanSide: Player.white);
      await archive.addFinished(
        finishedGame(mode, winner, DateTime(2026, 10, day, 20, 30)),
      );
    }
    final art = (await tester.runAsync(() => GameArt.load(rootBundle)))!;
    final container = await testContainer(
      ai: ScriptedAi(['c6xc4xe4', 'd7-d6']),
      archive: archive,
      preferences: {
        'settings.language': AppLanguage.arabic.code,
        // As in the release: online play only with a server.
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
    final controller = container.read(gameControllerProvider.notifier);
    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));

    /// Back to a home screen without a game to resume.
    Future<void> home(Recorder video) async {
      controller.close();
      await tester.runAsync(archive.clearCurrent);
      video.cut();
      router().go(AppRoutes.home);
      await video.waitMs(400);
    }

    final video = Recorder(tester);
    await video.start();

    // The launch screen, then the menu.
    video.scene('splash');
    await video.waitMs(1900);
    video.scene('home');
    await video.waitMs(1300);

    // Two players on one phone: the opening, with a capture each.
    await video.tap(find.text(l10n.homePlayFriend));
    await video.waitMs(700);
    video.scene('local');
    await video.waitMs(1200);
    await video.tapSquare('e4');
    await video.waitMs(700);
    await video.tapSquare('e5');
    await video.waitMs(1100);
    await video.tapSquare('e6');
    await video.waitMs(600);
    await video.tapSquare('e4');
    await video.waitMs(1200);
    await video.tapSquare('e3');
    await video.waitMs(600);
    await video.tapSquare('e5');
    await video.waitMs(1400);

    // Against the computer: the level, then the game.
    video.scene('ai_setup');
    await home(video);
    await video.waitMs(500);
    await video.tap(find.text(l10n.homePlayAi));
    await video.waitMs(1000);
    await video.tap(find.text(l10n.difficultyHard));
    await video.waitMs(800);
    await video.tap(find.text(l10n.startGame));
    await video.waitMs(900);

    video.cut();
    controller.startFrom(
      rafleGame,
      mode: const AiMode(level: AiLevel.hard, humanSide: Player.white),
    );
    video.scene('ai_move');
    await video.waitMs(1200);
    await video.tapSquare('c4');
    await video.waitMs(900);
    await video.tapSquare('c5');
    await video.waitMs(2400); // the computer thinks, then takes two
    video.scene('must_capture');
    await video.waitMs(1400);
    await video.tapSquare('e3');
    await video.waitMs(1200);
    await video.tapSquare('g9');
    await video.waitMs(2400); // six captures
    video.scene('dhayma');
    await video.waitMs(1800);
    await video.waitMs(1400); // the computer answers
    video.scene('flying');
    await video.tapSquare('g9');
    await video.waitMs(900);
    await video.tapSquare('c6');
    await video.waitMs(2200);

    // The tutorial: two lessons, then the first exercise.
    video.scene('tutorial');
    await home(video);
    await video.tap(find.text(l10n.homeHowToPlay));
    await video.waitMs(1400);
    await video.tap(find.text(l10n.tutorialNext));
    await video.waitMs(1300);
    await video.tap(find.text(l10n.tutorialNext));
    await video.waitMs(1200);
    await video.tapSquare('e3');
    await video.waitMs(700);
    await video.tapSquare('e4');
    await video.waitMs(700);
    await video.drag(
      const Offset(180, 460),
      const Offset(0, -170),
      const Duration(milliseconds: 700),
    );
    await video.waitMs(1300);

    // The history and its statistics.
    video.scene('history');
    await home(video);
    await video.tap(find.text(l10n.homeHistory));
    await video.waitMs(1800);
    await video.drag(
      const Offset(180, 520),
      const Offset(0, -330),
      const Duration(milliseconds: 1000),
    );
    await video.waitMs(1600);

    await video.finish();
    controller.close();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
