import 'dart:convert';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:http/http.dart' as http;

import 'online_models.dart';

/// An error reported by the server (or the network).
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  /// HTTP status, or 0 when the server could not be reached.
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Signed-in user and their token.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final OnlineUser user;
}

/// REST calls of docs/multiplayer.md.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client, this.token})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final String? token;

  ApiClient withToken(String? token) =>
      ApiClient(baseUrl: baseUrl, client: _client, token: token);

  Future<AuthResult> register(String username, String password) =>
      _auth('register', {'username': username, 'password': password});

  Future<AuthResult> login(String username, String password) =>
      _auth('login', {'username': username, 'password': password});

  Future<AuthResult> guest({String? username}) =>
      _auth('guest', {'username': ?username});

  Future<OnlineUser> me() async => OnlineUser.fromJson(await _get('users/me'));

  Future<List<LeaderboardEntry>> leaderboard({int limit = 50}) async => [
    for (final entry in await _getList('leaderboard?limit=$limit'))
      LeaderboardEntry.fromJson(entry),
  ];

  /// The engine game of a finished or running online game, for replay.
  Future<Game> game(String id) async {
    final json = await _get('games/$id') as Map<String, Object?>;
    return Game.fromJson(json['game']);
  }

  Future<List<Tournament>> tournaments() async => [
    for (final tournament in await _getList('tournaments'))
      Tournament.fromJson(tournament),
  ];

  Future<Tournament> tournament(String id) async =>
      Tournament.fromJson(await _get('tournaments/$id'));

  Future<Tournament> createTournament({
    required String name,
    required int maxPlayers,
  }) async => Tournament.fromJson(
    await _send('POST', 'tournaments', {
      'name': name,
      'format': 'roundRobin',
      'maxPlayers': maxPlayers,
    }),
  );

  Future<Tournament> joinTournament(String id) async =>
      Tournament.fromJson(await _send('POST', 'tournaments/$id/join', {}));

  Future<Tournament> startTournament(String id) async =>
      Tournament.fromJson(await _send('POST', 'tournaments/$id/start', {}));

  Future<AuthResult> _auth(String route, Map<String, Object?> body) async {
    final json = await _send('POST', 'auth/$route', body);
    if (json is! Map<String, Object?> || json['token'] is! String) {
      throw const FormatException('Unexpected authentication response');
    }
    return AuthResult(
      token: json['token']! as String,
      user: OnlineUser.fromJson(json['user']),
    );
  }

  Future<Object?> _get(String route) => _send('GET', route, null);

  Future<List<Object?>> _getList(String route) async {
    final json = await _get(route);
    if (json is List<Object?>) return json;
    throw const FormatException('Expected a list');
  }

  Future<Object?> _send(
    String method,
    String route,
    Map<String, Object?>? body,
  ) async {
    final uri = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/$route',
    );
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 15)),
      );
    } on Exception catch (error) {
      throw ApiException(0, '$error');
    }
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map<String, Object?>
          ? '${decoded['message'] ?? response.reasonPhrase}'
          : '${response.reasonPhrase}';
      throw ApiException(response.statusCode, message);
    }
    return decoded;
  }
}
