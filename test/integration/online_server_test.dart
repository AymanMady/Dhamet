// End-to-end test of the Flutter client against a running Dhamet server.
//
// Skipped unless a server address is given:
//   (cd server && DB_TYPE=sqljs PORT=3999 node dist/main) &
//   flutter test test/integration --dart-define=DHAMET_SERVER=http://localhost:3999
@Tags(['server'])
library;

import 'dart:math';

import 'package:dhamet/core/services/feedback_service.dart';
import 'package:dhamet/features/multiplayer/data/realtime_client.dart';
import 'package:dhamet/features/multiplayer/presentation/online_controller.dart';
import 'package:dhamet/features/settings/presentation/settings_controller.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const server = String.fromEnvironment('DHAMET_SERVER');

/// A player: its own storage, controller and connection.
class TestClient {
  TestClient._(this.container);

  static Future<TestClient> create() async {
    SharedPreferences.setMockInitialValues({'settings.serverUrl': server});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        feedbackServiceProvider.overrideWithValue(
          const FeedbackService(sound: false, haptics: false),
        ),
      ],
    );
    return TestClient._(container);
  }

  final ProviderContainer container;

  OnlineController get controller =>
      container.read(onlineControllerProvider.notifier);

  OnlineState get state => container.read(onlineControllerProvider);

  Future<void> waitFor(bool Function(OnlineState state) condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!condition(state)) {
      if (DateTime.now().isAfter(deadline)) {
        fail(
          'Timed out; state: error=${state.errorCode} ${state.errorMessage}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> play(String notation) async {
    final move = state.game!.state.legalMovesMatching(notation).single;
    controller
      ..tap(move.from)
      ..tap(move.to);
  }
}

void main() {
  final suffix = Random().nextInt(1 << 20).toRadixString(36);

  test(
    'two players play a rated game through the server',
    () async {
      final amina = await TestClient.create();
      final sidi = await TestClient.create();
      addTearDown(amina.container.dispose);
      addTearDown(sidi.container.dispose);

      await amina.controller.register('amina_$suffix', 'password-123');
      await sidi.controller.register('sidi_$suffix', 'password-456');
      expect(amina.state.signedIn, isTrue, reason: amina.state.errorMessage);
      expect(sidi.state.signedIn, isTrue, reason: sidi.state.errorMessage);

      await amina.controller.connect();
      await sidi.controller.connect();
      await amina.waitFor((s) => s.connection == ConnectionStatus.connected);
      await sidi.waitFor((s) => s.connection == ConnectionStatus.connected);

      amina.controller.createRoom(color: Player.white, rated: true);
      await amina.waitFor((s) => s.room != null);
      final code = amina.state.room!.code;
      expect(code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));

      sidi.controller.joinRoom(code);
      await amina.waitFor((s) => s.room!.players.length == 2);
      amina.controller.setReady(true);
      sidi.controller.setReady(true);
      await amina.waitFor((s) => s.game != null);
      await sidi.waitFor((s) => s.game != null);
      expect(amina.state.myColor, Player.white);
      expect(sidi.state.myColor, Player.black);

      // The traditional opening: the server confirms every move.
      await amina.play('d4-e5');
      await sidi.waitFor((s) => s.game!.state.plyCount == 1);
      await sidi.play('f6xd4');
      await amina.waitFor((s) => s.game!.state.plyCount == 2);
      await amina.play('c3xe5');
      await sidi.waitFor((s) => s.game!.state.plyCount == 3);
      expect(sidi.state.game!.state.board, amina.state.game!.state.board);

      // Black may not move twice.
      amina.controller.tap(Position.parse('e5'));
      expect(amina.state.selected, isNull);

      sidi.controller.resign();
      await amina.waitFor((s) => s.result != null);
      await sidi.waitFor((s) => s.result != null);
      expect(
        amina.state.result,
        const GameResult.win(Player.white, GameEndReason.resignation),
      );
      expect(amina.state.ratingChanges[amina.state.user!.id], 16);
      expect(sidi.state.ratingChanges[sidi.state.user!.id], -16);

      await amina.waitFor((s) => s.user!.rating == 1216);
      final api = amina.container.read(apiClientProvider);
      final leaderboard = await api.leaderboard();
      expect(
        leaderboard.map((entry) => entry.user.username),
        contains('amina_$suffix'),
      );
      final replay = await api.game(amina.state.gameId!);
      expect(replay.state.plyCount, 3);
      expect(replay.result!.reason, GameEndReason.resignation);
    },
    skip: server.isEmpty ? 'set --dart-define=DHAMET_SERVER=<url>' : false,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
