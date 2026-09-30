import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// One client connection to the fake server.
class FakeSocket with StreamChannelMixin<dynamic> implements WebSocketChannel {
  FakeSocket(this.uri, {this.fail = false});

  final Uri uri;
  final bool fail;
  final _toClient = StreamController<dynamic>();
  final sent = <Map<String, Object?>>[];
  int? _closeCode;

  @override
  Future<void> get ready =>
      fail ? Future.error(Exception('unreachable')) : Future.value();

  @override
  Stream<dynamic> get stream => _toClient.stream;

  @override
  late final WebSocketSink sink = _FakeSink(this);

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  /// Pushes a server event to the client.
  void emit(String event, [Map<String, Object?> data = const {}]) =>
      _toClient.add(jsonEncode({'event': event, 'data': data}));

  /// The server closes the connection.
  Future<void> drop([int? code]) async {
    _closeCode = code;
    await _toClient.close();
  }

  /// Events sent by the client, by name.
  List<Map<String, Object?>> sentEvents(String event) => [
    for (final message in sent)
      if (message['event'] == event) message['data']! as Map<String, Object?>,
  ];
}

class _FakeSink extends DelegatingStreamSink<dynamic> implements WebSocketSink {
  _FakeSink(this._socket) : super(StreamController<dynamic>());

  final FakeSocket _socket;

  @override
  void add(dynamic data) =>
      _socket.sent.add(jsonDecode(data as String) as Map<String, Object?>);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}

/// Records every connection the client opens.
class FakeServer {
  final sockets = <FakeSocket>[];
  bool reachable = true;

  FakeSocket connect(Uri uri) {
    final socket = FakeSocket(uri, fail: !reachable);
    sockets.add(socket);
    return socket;
  }

  FakeSocket get last => sockets.last;
}
