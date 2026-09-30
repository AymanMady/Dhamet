import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A message from the server: `{"event": ..., "data": {...}}`.
@immutable
class ServerEvent {
  const ServerEvent(this.event, this.data);

  final String event;
  final Map<String, Object?> data;

  @override
  String toString() => 'ServerEvent($event, $data)';
}

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

typedef ChannelFactory = WebSocketChannel Function(Uri uri);

/// The WebSocket link to the server.
///
/// Reconnects automatically with a growing delay when the connection
/// drops, except when the server rejects the token (close code 4401).
class RealtimeClient {
  RealtimeClient({
    required this.uri,
    ChannelFactory? channelFactory,
    this.pingInterval = const Duration(seconds: 25),
    this.initialRetryDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 10),
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  /// Close code sent by the server for a missing or invalid token.
  static const int unauthenticatedCode = 4401;

  final Uri uri;
  final Duration pingInterval;
  final Duration initialRetryDelay;
  final Duration maxRetryDelay;
  final ChannelFactory _channelFactory;

  final _events = StreamController<ServerEvent>.broadcast();
  final _status = StreamController<ConnectionStatus>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  int _attempts = 0;
  bool _closed = false;
  ConnectionStatus _current = ConnectionStatus.disconnected;

  Stream<ServerEvent> get events => _events.stream;

  Stream<ConnectionStatus> get statusChanges => _status.stream;

  ConnectionStatus get status => _current;

  /// Builds the WebSocket address from the server's HTTP base URL.
  static Uri socketUri(String baseUrl, String token) {
    final base = Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), ''));
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/ws',
      queryParameters: {'token': token},
    );
  }

  Future<void> connect() async {
    _closed = false;
    await _open(reconnecting: false);
  }

  void send(String event, [Map<String, Object?> data = const {}]) {
    final channel = _channel;
    if (channel == null || _current != ConnectionStatus.connected) return;
    channel.sink.add(jsonEncode({'event': event, 'data': data}));
  }

  Future<void> close() async {
    _closed = true;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
    await _events.close();
    await _status.close();
  }

  Future<void> _open({required bool reconnecting}) async {
    _setStatus(
      reconnecting
          ? ConnectionStatus.reconnecting
          : ConnectionStatus.connecting,
    );
    final channel = _channelFactory(uri);
    _channel = channel;
    try {
      await channel.ready;
    } catch (_) {
      _scheduleRetry();
      return;
    }
    if (_closed) return;
    _attempts = 0;
    _subscription = channel.stream.listen(
      _onMessage,
      onDone: () => _onDone(channel.closeCode),
      onError: (Object _) => _onDone(channel.closeCode),
    );
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => send('ping'));
    _setStatus(ConnectionStatus.connected);
  }

  void _onMessage(Object? message) {
    if (message is! String) return;
    try {
      final json = jsonDecode(message);
      if (json is Map<String, Object?> && json['event'] is String) {
        final data = json['data'];
        _events.add(
          ServerEvent(
            json['event']! as String,
            data is Map<String, Object?> ? data : const {},
          ),
        );
      }
    } on FormatException {
      // Ignore malformed frames.
    }
  }

  void _onDone(int? closeCode) {
    _pingTimer?.cancel();
    _subscription = null;
    _channel = null;
    if (_closed) return;
    if (closeCode == unauthenticatedCode) {
      _setStatus(ConnectionStatus.disconnected);
      _events.add(
        const ServerEvent('error', {
          'code': 'UNAUTHENTICATED',
          'message': 'The server rejected the session',
        }),
      );
      return;
    }
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed) return;
    _setStatus(ConnectionStatus.reconnecting);
    final delay = Duration(
      milliseconds: min(
        maxRetryDelay.inMilliseconds,
        initialRetryDelay.inMilliseconds * pow(2, _attempts).toInt(),
      ),
    );
    _attempts++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => _open(reconnecting: true));
  }

  void _setStatus(ConnectionStatus status) {
    if (_current == status || _status.isClosed) return;
    _current = status;
    _status.add(status);
  }
}
