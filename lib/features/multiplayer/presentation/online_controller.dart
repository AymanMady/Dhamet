import 'dart:async';
import 'dart:convert';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/services/feedback_service.dart';
import '../../game/domain/board_interaction.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/api_client.dart';
import '../data/online_models.dart';
import '../data/realtime_client.dart';

/// Everything the online screens show.
@immutable
class OnlineState {
  const OnlineState({
    this.user,
    this.token,
    this.connection = ConnectionStatus.disconnected,
    this.room,
    this.gameId,
    this.game,
    this.myColor,
    this.clocks,
    this.clocksAt,
    this.result,
    this.ratingChanges = const {},
    this.selected,
    this.pendingChoices = const [],
    this.awaitingServer = false,
    this.opponentAwayUntil,
    this.errorCode,
    this.errorMessage,
    this.busy = false,
  });

  final OnlineUser? user;
  final String? token;
  final ConnectionStatus connection;
  final Room? room;
  final String? gameId;

  /// The game as confirmed by the server, replayed by the local engine.
  final Game? game;
  final Player? myColor;
  final Clocks? clocks;

  /// When [clocks] was received, to count down locally.
  final DateTime? clocksAt;
  final GameResult? result;
  final Map<String, int> ratingChanges;
  final Position? selected;
  final List<Move> pendingChoices;

  /// A move was sent and not yet confirmed.
  final bool awaitingServer;

  /// The opponent is disconnected and forfeits at this time.
  final DateTime? opponentAwayUntil;
  final String? errorCode;
  final String? errorMessage;

  /// A REST request is running.
  final bool busy;

  bool get signedIn => user != null && token != null;

  bool get isMyTurn =>
      game != null &&
      result == null &&
      !game!.isOver &&
      myColor == game!.state.currentPlayer &&
      !awaitingServer;

  List<Move> get selectedMoves => selected == null || game == null
      ? const []
      : distinctOutcomes(game!.state.legalMovesFrom(selected!));

  /// Remaining time of [player] now, in milliseconds.
  int? remainingMs(Player player, DateTime now) {
    final clocks = this.clocks;
    if (clocks == null) return null;
    var remaining = clocks.of(player);
    final running =
        game != null &&
        result == null &&
        !game!.isOver &&
        game!.state.currentPlayer == player;
    if (running && clocksAt != null) {
      remaining -= now.difference(clocksAt!).inMilliseconds;
    }
    return remaining < 0 ? 0 : remaining;
  }

  OnlineState copyWith({
    OnlineUser? Function()? user,
    String? Function()? token,
    ConnectionStatus? connection,
    Room? Function()? room,
    String? Function()? gameId,
    Game? Function()? game,
    Player? Function()? myColor,
    Clocks? Function()? clocks,
    DateTime? Function()? clocksAt,
    GameResult? Function()? result,
    Map<String, int>? ratingChanges,
    Position? Function()? selected,
    List<Move>? pendingChoices,
    bool? awaitingServer,
    DateTime? Function()? opponentAwayUntil,
    String? Function()? errorCode,
    String? Function()? errorMessage,
    bool? busy,
  }) => OnlineState(
    user: user == null ? this.user : user(),
    token: token == null ? this.token : token(),
    connection: connection ?? this.connection,
    room: room == null ? this.room : room(),
    gameId: gameId == null ? this.gameId : gameId(),
    game: game == null ? this.game : game(),
    myColor: myColor == null ? this.myColor : myColor(),
    clocks: clocks == null ? this.clocks : clocks(),
    clocksAt: clocksAt == null ? this.clocksAt : clocksAt(),
    result: result == null ? this.result : result(),
    ratingChanges: ratingChanges ?? this.ratingChanges,
    selected: selected == null ? this.selected : selected(),
    pendingChoices: pendingChoices ?? this.pendingChoices,
    awaitingServer: awaitingServer ?? this.awaitingServer,
    opponentAwayUntil: opponentAwayUntil == null
        ? this.opponentAwayUntil
        : opponentAwayUntil(),
    errorCode: errorCode == null ? this.errorCode : errorCode(),
    errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
    busy: busy ?? this.busy,
  );
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: ref.watch(settingsProvider.select((s) => s.serverUrl)),
  ),
);

/// Creates the WebSocket client for a server address (overridden in tests).
final realtimeClientFactoryProvider = Provider<RealtimeClient Function(Uri)>(
  (ref) =>
      (uri) =>
          RealtimeClient(uri: uri, channelFactory: WebSocketChannel.connect),
);

final onlineControllerProvider =
    NotifierProvider<OnlineController, OnlineState>(OnlineController.new);

/// Online play. The server is authoritative: a move is only applied once
/// the server has confirmed it, and the local engine checks it again.
class OnlineController extends Notifier<OnlineState> {
  RealtimeClient? _client;
  StreamSubscription<ServerEvent>? _events;
  StreamSubscription<ConnectionStatus>? _statuses;

  static const _tokenKey = 'online.token';
  static const _userKey = 'online.user';

  @override
  OnlineState build() {
    ref.onDispose(_disconnect);
    final preferences = ref.read(sharedPreferencesProvider);
    final token = preferences.getString(_tokenKey);
    final userJson = preferences.getString(_userKey);
    OnlineUser? user;
    if (token != null && userJson != null) {
      try {
        user = OnlineUser.fromJson(jsonDecode(userJson));
      } on FormatException {
        user = null;
      }
    }
    return OnlineState(user: user, token: user == null ? null : token);
  }

  ApiClient get _api => ref.read(apiClientProvider).withToken(state.token);

  Future<void> signIn(String username, String password) =>
      _authenticate(() => _api.login(username, password));

  Future<void> register(String username, String password) =>
      _authenticate(() => _api.register(username, password));

  Future<void> signInAsGuest() => _authenticate(() => _api.guest());

  Future<void> signOut() async {
    await _disconnect();
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);
    state = const OnlineState();
  }

  /// Deletes the account on the server, then forgets it on this device.
  /// Resolves to `false` if the server could not delete it.
  Future<bool> deleteAccount() async {
    state = state.copyWith(
      busy: true,
      errorCode: () => null,
      errorMessage: () => null,
    );
    try {
      await _api.deleteAccount();
    } on ApiException catch (error) {
      // An expired session: signing in again lets the player retry.
      if (error.isUnauthorized) {
        await signOut();
        return false;
      }
      state = state.copyWith(
        busy: false,
        errorCode: () =>
            error.isNetwork ? 'NETWORK' : 'HTTP_${error.statusCode}',
        errorMessage: () => error.message,
      );
      return false;
    }
    await signOut();
    return true;
  }

  /// Refreshes the profile (rating, results) from the server.
  Future<void> refreshProfile() async {
    if (!state.signedIn) return;
    try {
      final user = await _api.me();
      await _storeUser(user);
      state = state.copyWith(user: () => user);
    } on ApiException catch (error) {
      if (error.isUnauthorized) await signOut();
    }
  }

  Future<void> connect() async {
    final token = state.token;
    if (token == null || _client != null) return;
    final client = ref.read(realtimeClientFactoryProvider)(
      RealtimeClient.socketUri(ref.read(apiClientProvider).baseUrl, token),
    );
    _client = client;
    _events = client.events.listen(_onEvent);
    _statuses = client.statusChanges.listen(_onStatus);
    await client.connect();
  }

  void createRoom({
    Player? color,
    bool rated = false,
    TimeControl? timeControl,
  }) {
    _clearGame();
    _send('room:create', {
      'color': color?.toJson() ?? 'random',
      'rated': rated,
      'timeControl': timeControl?.toJson(),
    });
  }

  void joinRoom(String code) {
    _clearGame();
    _send('room:join', {'code': code.trim().toUpperCase()});
  }

  void setReady(bool ready) {
    final room = state.room;
    if (room != null) _send('room:ready', {'code': room.code, 'ready': ready});
  }

  void leaveRoom() {
    final room = state.room;
    if (room != null) _send('room:leave', {'code': room.code});
    state = state.copyWith(room: () => null);
    _clearGame();
  }

  void resign() {
    final room = state.room;
    if (room != null && state.result == null) {
      _send('game:resign', {'code': room.code});
    }
  }

  void clearError() =>
      state = state.copyWith(errorCode: () => null, errorMessage: () => null);

  /// A tap on the board during an online game.
  void tap(Position position) {
    final game = state.game;
    if (game == null || !state.isMyTurn) return;
    switch (resolveTap(game.state, state.selected, position)) {
      case PlayMove(:final move):
        _sendMove(move);
      case ChooseMove(:final moves):
        state = state.copyWith(pendingChoices: moves);
      case SelectPiece(:final position):
        state = state.copyWith(
          selected: () => position,
          pendingChoices: const [],
        );
        ref.read(feedbackServiceProvider).play(FeedbackEvent.select);
      case ClearSelection():
        state = state.copyWith(selected: () => null, pendingChoices: const []);
    }
  }

  void choose(Move move) {
    if (state.pendingChoices.contains(move)) _sendMove(move);
  }

  void cancelChoice() => state = state.copyWith(pendingChoices: const []);

  void _sendMove(Move move) {
    final room = state.room;
    final game = state.game;
    if (room == null || game == null) return;
    _send('game:move', {
      'code': room.code,
      'ply': game.state.plyCount,
      'move': move.toJson(),
    });
    state = state.copyWith(
      awaitingServer: true,
      selected: () => null,
      pendingChoices: const [],
    );
  }

  Future<void> _authenticate(Future<AuthResult> Function() request) async {
    state = state.copyWith(
      busy: true,
      errorCode: () => null,
      errorMessage: () => null,
    );
    try {
      final result = await request();
      final preferences = ref.read(sharedPreferencesProvider);
      await preferences.setString(_tokenKey, result.token);
      await _storeUser(result.user);
      state = state.copyWith(
        user: () => result.user,
        token: () => result.token,
        busy: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        busy: false,
        errorCode: () => error.isNetwork
            ? 'NETWORK'
            : error.isUnauthorized
            ? 'CREDENTIALS'
            : error.isConflict
            ? 'TAKEN'
            : 'HTTP_${error.statusCode}',
        errorMessage: () => error.message,
      );
    }
  }

  Future<void> _storeUser(OnlineUser user) => ref
      .read(sharedPreferencesProvider)
      .setString(_userKey, jsonEncode(user.toJson()));

  void _send(String event, Map<String, Object?> data) {
    _client?.send(event, data);
  }

  void _clearGame() {
    state = state.copyWith(
      gameId: () => null,
      game: () => null,
      myColor: () => null,
      clocks: () => null,
      clocksAt: () => null,
      result: () => null,
      ratingChanges: const {},
      selected: () => null,
      pendingChoices: const [],
      awaitingServer: false,
      opponentAwayUntil: () => null,
    );
  }

  void _onStatus(ConnectionStatus status) {
    final wasReconnecting = state.connection == ConnectionStatus.reconnecting;
    state = state.copyWith(connection: status);
    final room = state.room;
    if (status == ConnectionStatus.connected &&
        wasReconnecting &&
        room != null) {
      _send('room:rejoin', {'code': room.code});
    }
  }

  void _onEvent(ServerEvent event) {
    try {
      _handle(event);
    } on FormatException catch (error) {
      debugPrint('Ignored malformed ${event.event}: $error');
    }
  }

  void _handle(ServerEvent event) {
    final data = event.data;
    switch (event.event) {
      case 'room:updated':
        final room = Room.fromJson(data['room']);
        state = state.copyWith(room: () => room, myColor: () => _myColor(room));
      case 'game:started':
        final room = Room.fromJson(data['room']);
        _clearGame();
        state = state.copyWith(
          room: () => room,
          gameId: () => data['gameId'] as String?,
          game: () => Game.fromJson(data['game']),
          myColor: () => _myColor(room),
          clocks: () => _clocks(data),
          clocksAt: DateTime.now,
        );
      case 'game:moved':
        _onMoved(data);
      case 'game:sync':
        final room = Room.fromJson(data['room']);
        final game = Game.fromJson(data['game']);
        state = state.copyWith(
          room: () => room,
          gameId: () => data['gameId'] as String?,
          game: () => game,
          myColor: () => _myColor(room),
          clocks: () => _clocks(data),
          clocksAt: DateTime.now,
          result: () => game.result ?? state.result,
          awaitingServer: false,
          selected: () => null,
          pendingChoices: const [],
        );
      case 'game:over':
        _onOver(data);
      case 'player:disconnected':
        if (data['userId'] != state.user?.id) {
          final grace = (data['graceSeconds'] as num?)?.toInt() ?? 60;
          state = state.copyWith(
            opponentAwayUntil: () =>
                DateTime.now().add(Duration(seconds: grace)),
          );
        }
      case 'player:reconnected':
        state = state.copyWith(opponentAwayUntil: () => null);
      case 'error':
        final code = data['code'] as String?;
        state = state.copyWith(
          awaitingServer: false,
          errorCode: () => code,
          errorMessage: () => data['message'] as String?,
        );
        if (code == 'STALE_PLY' || code == 'ILLEGAL_MOVE') _requestSync();
      case 'pong':
        break;
    }
  }

  void _onMoved(Map<String, Object?> data) {
    final game = state.game;
    final ply = (data['ply'] as num?)?.toInt();
    if (game == null || ply == null) return _requestSync();
    if (ply <= game.state.plyCount) return; // Already applied.
    if (ply != game.state.plyCount + 1) return _requestSync();
    final Game next;
    try {
      next = game.play(Move.fromJson(data['move']));
    } on Object catch (error) {
      // The server accepted a move the local engine refuses: resynchronise.
      debugPrint('Local engine refused a confirmed move: $error');
      return _requestSync();
    }
    final move = next.state.lastMove!;
    state = state.copyWith(
      game: () => next,
      clocks: () => _clocks(data) ?? state.clocks,
      clocksAt: DateTime.now,
      awaitingServer: false,
      selected: () => null,
      pendingChoices: const [],
    );
    ref
        .read(feedbackServiceProvider)
        .play(
          move.promotes
              ? FeedbackEvent.promotion
              : move.isCapture
              ? FeedbackEvent.capture
              : FeedbackEvent.move,
        );
  }

  void _onOver(Map<String, Object?> data) {
    final result = GameResult.fromJson(data['result']);
    var game = state.game;
    if (game != null && !game.isOver) {
      try {
        game = switch (result.reason) {
          GameEndReason.resignation => game.resign(result.loser!),
          GameEndReason.timeout => game.loseOnTime(result.loser!),
          _ => game,
        };
      } on StateError {
        // Keep the server's result even if the local game disagrees.
      }
    }
    final changes = <String, int>{};
    final raw = data['ratingChanges'];
    if (raw is Map<String, Object?>) {
      raw.forEach((userId, delta) {
        if (delta is num) changes[userId] = delta.round();
      });
    }
    state = state.copyWith(
      game: () => game,
      result: () => result,
      ratingChanges: changes,
      awaitingServer: false,
      opponentAwayUntil: () => null,
    );
    final me = state.myColor;
    ref
        .read(feedbackServiceProvider)
        .play(
          me != null && result.loser == me
              ? FeedbackEvent.defeat
              : FeedbackEvent.victory,
        );
    unawaited(refreshProfile());
  }

  void _requestSync() {
    final room = state.room;
    if (room != null) _send('game:sync', {'code': room.code});
  }

  Player? _myColor(Room room) {
    final user = state.user;
    return user == null ? null : room.playerOf(user.id)?.color;
  }

  static Clocks? _clocks(Map<String, Object?> data) =>
      data['clocks'] == null ? null : Clocks.fromJson(data['clocks']);

  Future<void> _disconnect() async {
    await _events?.cancel();
    await _statuses?.cancel();
    final client = _client;
    _client = null;
    _events = null;
    _statuses = null;
    await client?.close();
  }
}
