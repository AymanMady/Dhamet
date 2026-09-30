import 'dart:convert';
import 'dart:io';

import 'package:dhamet/core/services/feedback_service.dart';
import 'package:dhamet/features/multiplayer/data/api_client.dart';
import 'package:dhamet/features/multiplayer/data/online_models.dart';
import 'package:dhamet/features/multiplayer/data/realtime_client.dart';
import 'package:dhamet/features/multiplayer/presentation/online_controller.dart';
import 'package:dhamet/features/settings/presentation/settings_controller.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';
import 'fake_server.dart';

Map<String, Object?> userJson(String id, String name, {bool guest = true}) => {
  'id': id,
  'username': name,
  'isGuest': guest,
  'rating': 1200,
  'wins': 0,
  'losses': 0,
  'draws': 0,
  'gamesPlayed': 0,
  'createdAt': '2026-09-30T00:00:00.000Z',
};

Map<String, Object?> roomJson({
  String status = 'waiting',
  bool withOpponent = false,
}) => {
  'code': 'ABC234',
  'status': status,
  'hostId': 'u1',
  'rated': false,
  'timeControl': null,
  'gameId': status == 'playing' ? 'g1' : null,
  'players': [
    {
      'user': userJson('u1', 'amina'),
      'color': 'white',
      'ready': false,
      'connected': true,
    },
    if (withOpponent)
      {
        'user': userJson('u2', 'sidi'),
        'color': 'black',
        'ready': false,
        'connected': true,
      },
  ],
};

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Future<void> settle([int milliseconds = 0]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

void main() {
  late FakeServer server;
  late ProviderContainer container;
  late OnlineController controller;
  var networkDown = false;

  final api = MockClient((request) async {
    if (networkDown) throw const SocketException('offline');
    final body = request.body.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;
    return switch (request.url.path) {
      '/api/auth/guest' => json({
        'token': 'token-1',
        'user': userJson('u1', 'amina'),
      }, 201),
      '/api/auth/login' when body['password'] == 'good-password' => json({
        'token': 'token-2',
        'user': userJson('u1', 'amina', guest: false),
      }),
      '/api/auth/login' => json({
        'statusCode': 401,
        'message': 'Invalid credentials',
      }, 401),
      '/api/auth/register' => json({
        'statusCode': 409,
        'message': 'Username already taken',
      }, 409),
      '/api/users/me' => json(userJson('u1', 'amina')),
      _ => json({'statusCode': 404, 'message': 'Not found'}, 404),
    };
  });

  Future<void> setUpContainer({
    Map<String, Object> preferences = const {},
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    server = FakeServer();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        feedbackServiceProvider.overrideWithValue(
          const FeedbackService(sound: false, haptics: false),
        ),
        apiClientProvider.overrideWithValue(
          ApiClient(baseUrl: 'http://dhamet.test:3000', client: api),
        ),
        realtimeClientFactoryProvider.overrideWithValue(
          (uri) => RealtimeClient(
            uri: uri,
            channelFactory: server.connect,
            initialRetryDelay: const Duration(milliseconds: 1),
            pingInterval: const Duration(hours: 1),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(onlineControllerProvider.notifier);
  }

  OnlineState read() => container.read(onlineControllerProvider);

  Future<void> signedInAndConnected() async {
    await controller.signInAsGuest();
    await controller.connect();
    await settle();
  }

  Future<void> gameStarted() async {
    await signedInAndConnected();
    controller.createRoom(color: Player.white);
    server.last.emit('room:updated', {'room': roomJson()});
    await settle();
    server.last.emit('game:started', {
      'room': roomJson(status: 'playing', withOpponent: true),
      'gameId': 'g1',
      'game': Game.start().toJson(),
    });
    await settle();
  }

  setUp(() => networkDown = false);

  group('accounts', () {
    setUp(() => setUpContainer());

    test('a guest session is stored and restored', () async {
      await controller.signInAsGuest();
      expect(read().signedIn, isTrue);
      expect(read().user!.username, 'amina');
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('online.token'), 'token-1');

      final restored = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restored.dispose);
      expect(restored.read(onlineControllerProvider).user!.id, 'u1');

      await controller.signOut();
      expect(read().signedIn, isFalse);
      expect(prefs.getString('online.token'), isNull);
    });

    test('wrong password, taken name and network errors', () async {
      await controller.signIn('amina', 'wrong-password');
      expect(read().errorCode, 'CREDENTIALS');
      await controller.signIn('amina', 'good-password');
      expect(read().user!.isGuest, isFalse);
      await controller.signOut();
      await controller.register('amina', 'whatever-123');
      expect(read().errorCode, 'TAKEN');
      networkDown = true;
      await controller.signInAsGuest();
      expect(read().errorCode, 'NETWORK');
      controller.clearError();
      expect(read().errorCode, isNull);
    });
  });

  group('online game', () {
    setUp(() => setUpContainer());

    test('connects with the token to the WebSocket endpoint', () async {
      await signedInAndConnected();
      expect(
        server.last.uri.toString(),
        'ws://dhamet.test:3000/ws?token=token-1',
      );
      expect(read().connection, ConnectionStatus.connected);
    });

    test('room creation, readiness and game start', () async {
      await signedInAndConnected();
      controller.createRoom(
        color: Player.white,
        timeControl: const TimeControl(initialSeconds: 300),
      );
      expect(server.last.sentEvents('room:create').single, {
        'color': 'white',
        'rated': false,
        'timeControl': {'initialSeconds': 300, 'incrementSeconds': 0},
      });
      server.last.emit('room:updated', {'room': roomJson()});
      await settle();
      expect(read().room!.code, 'ABC234');
      controller.setReady(true);
      expect(server.last.sentEvents('room:ready').single, {
        'code': 'ABC234',
        'ready': true,
      });
      server.last.emit('game:started', {
        'room': roomJson(status: 'playing', withOpponent: true),
        'gameId': 'g1',
        'game': Game.start().toJson(),
      });
      await settle();
      expect(read().game!.state.plyCount, 0);
      expect(read().myColor, Player.white);
      expect(read().isMyTurn, isTrue);
    });

    test('a move is applied only once the server confirms it', () async {
      await gameStarted();
      controller
        ..tap(sq('d4'))
        ..tap(sq('e5'));
      final sent = server.last.sentEvents('game:move').single;
      expect(sent['ply'], 0);
      expect(Move.fromJson(sent['move']).notation, 'd4-e5');
      expect(read().awaitingServer, isTrue);
      expect(read().game!.state.plyCount, 0, reason: 'not applied yet');
      expect(read().isMyTurn, isFalse);

      server.last.emit('game:moved', {
        'code': 'ABC234',
        'gameId': 'g1',
        'ply': 1,
        'move': sent['move'],
      });
      await settle();
      expect(read().game!.state.plyCount, 1);
      expect(read().awaitingServer, isFalse);

      // The opponent's forced reply.
      final reply = read().game!.state.legalMoves.single;
      server.last.emit('game:moved', {
        'code': 'ABC234',
        'gameId': 'g1',
        'ply': 2,
        'move': reply.toJson(),
      });
      await settle();
      expect(read().game!.state.plyCount, 2);
      expect(read().isMyTurn, isTrue);
    });

    test('gaps, stale plies and refused moves trigger a resync', () async {
      await gameStarted();
      server.last.emit('game:moved', {
        'ply': 5,
        'move': GameState.initial().legalMoves.first.toJson(),
      });
      await settle();
      expect(server.last.sentEvents('game:sync'), hasLength(1));

      final illegal = Move(
        piece: Piece.whitePawn,
        from: sq('e3'),
        path: [sq('e5')],
      );
      server.last.emit('game:moved', {'ply': 1, 'move': illegal.toJson()});
      await settle();
      expect(read().game!.state.plyCount, 0);
      expect(server.last.sentEvents('game:sync'), hasLength(2));

      server.last.emit('error', {'code': 'STALE_PLY', 'message': 'stale'});
      await settle();
      expect(read().errorCode, 'STALE_PLY');
      expect(server.last.sentEvents('game:sync'), hasLength(3));

      var synced = Game.start();
      synced = synced.play(synced.state.legalMovesMatching('d4-e5').single);
      server.last.emit('game:sync', {
        'room': roomJson(status: 'playing', withOpponent: true),
        'gameId': 'g1',
        'game': synced.toJson(),
      });
      await settle();
      expect(read().game!.state.plyCount, 1);
    });

    test('game over by resignation with rating change', () async {
      await gameStarted();
      server.last.emit('game:over', {
        'code': 'ABC234',
        'gameId': 'g1',
        'result': {'winner': 'black', 'reason': 'resignation'},
        'ratingChanges': {'u1': -16, 'u2': 16},
      });
      await settle();
      expect(
        read().result,
        const GameResult.win(Player.black, GameEndReason.resignation),
      );
      expect(read().game!.isOver, isTrue);
      expect(read().ratingChanges['u1'], -16);
      expect(read().isMyTurn, isFalse);
    });

    test('opponent disconnection countdown', () async {
      await gameStarted();
      server.last.emit('player:disconnected', {
        'code': 'ABC234',
        'userId': 'u2',
        'graceSeconds': 60,
      });
      await settle();
      expect(read().opponentAwayUntil, isNotNull);
      server.last.emit('player:reconnected', {
        'code': 'ABC234',
        'userId': 'u2',
      });
      await settle();
      expect(read().opponentAwayUntil, isNull);
    });

    test('clocks count down for the side to move only', () async {
      await signedInAndConnected();
      server.last.emit('game:started', {
        'room': roomJson(status: 'playing', withOpponent: true),
        'gameId': 'g1',
        'game': Game.start().toJson(),
        'clocks': {'white': 300000, 'black': 300000},
      });
      await settle();
      final later = DateTime.now().add(const Duration(seconds: 2));
      expect(read().remainingMs(Player.white, later), lessThan(300000));
      expect(read().remainingMs(Player.black, later), 300000);
    });

    test('after a dropped connection the client rejoins its room', () async {
      await gameStarted();
      final first = server.last;
      await first.drop();
      await settle(30);
      expect(server.sockets.length, greaterThan(1));
      expect(read().connection, ConnectionStatus.connected);
      expect(server.last.sentEvents('room:rejoin').single, {'code': 'ABC234'});
    });

    test('a rejected token stops reconnecting', () async {
      await signedInAndConnected();
      await server.last.drop(RealtimeClient.unauthenticatedCode);
      await settle(30);
      expect(server.sockets, hasLength(1));
      expect(read().connection, ConnectionStatus.disconnected);
      expect(read().errorCode, 'UNAUTHENTICATED');
    });
  });

  test('WebSocket address from the server address', () {
    expect(
      RealtimeClient.socketUri('https://play.example.mr/', 'abc').toString(),
      'wss://play.example.mr/ws?token=abc',
    );
    expect(
      RealtimeClient.socketUri('http://10.0.2.2:3000', 'abc').toString(),
      'ws://10.0.2.2:3000/ws?token=abc',
    );
  });
}
