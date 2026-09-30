import 'package:dhamet_engine/dhamet_engine.dart';

/// Reads JSON produced by the server; malformed data raises a
/// [FormatException].
T _field<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Unexpected server data for "$key"', value);
}

Map<String, Object?> _map(Object? json) {
  if (json is Map<String, Object?>) return json;
  throw FormatException('Expected an object', json);
}

/// An account on the server.
class OnlineUser {
  const OnlineUser({
    required this.id,
    required this.username,
    required this.isGuest,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  factory OnlineUser.fromJson(Object? json) {
    final map = _map(json);
    return OnlineUser(
      id: _field<String>(map, 'id'),
      username: _field<String>(map, 'username'),
      isGuest: map['isGuest'] == true,
      rating: _field<num>(map, 'rating').round(),
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String username;
  final bool isGuest;
  final int rating;
  final int wins;
  final int losses;
  final int draws;

  int get gamesPlayed => wins + losses + draws;

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'isGuest': isGuest,
    'rating': rating,
    'wins': wins,
    'losses': losses,
    'draws': draws,
  };
}

/// Optional clock of an online game (an application rule).
class TimeControl {
  const TimeControl({required this.initialSeconds, this.incrementSeconds = 0});

  factory TimeControl.fromJson(Object? json) {
    final map = _map(json);
    return TimeControl(
      initialSeconds: _field<num>(map, 'initialSeconds').toInt(),
      incrementSeconds: (map['incrementSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  final int initialSeconds;
  final int incrementSeconds;

  Map<String, Object?> toJson() => {
    'initialSeconds': initialSeconds,
    'incrementSeconds': incrementSeconds,
  };
}

enum RoomStatus { waiting, playing, finished }

class RoomPlayer {
  const RoomPlayer({
    required this.user,
    required this.color,
    required this.ready,
    required this.connected,
  });

  factory RoomPlayer.fromJson(Object? json) {
    final map = _map(json);
    final color = map['color'];
    return RoomPlayer(
      user: OnlineUser.fromJson(map['user']),
      color: color == null ? null : Player.fromJson(color),
      ready: map['ready'] == true,
      connected: map['connected'] != false,
    );
  }

  final OnlineUser user;

  /// `null` until colours are assigned.
  final Player? color;
  final bool ready;
  final bool connected;
}

class Room {
  const Room({
    required this.code,
    required this.status,
    required this.hostId,
    required this.rated,
    required this.players,
    this.timeControl,
    this.gameId,
  });

  factory Room.fromJson(Object? json) {
    final map = _map(json);
    return Room(
      code: _field<String>(map, 'code'),
      status: RoomStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => throw FormatException('room.status', map['status']),
      ),
      hostId: _field<String>(map, 'hostId'),
      rated: map['rated'] == true,
      players: [
        for (final player in (map['players'] as List<Object?>? ?? const []))
          RoomPlayer.fromJson(player),
      ],
      timeControl: map['timeControl'] == null
          ? null
          : TimeControl.fromJson(map['timeControl']),
      gameId: map['gameId'] as String?,
    );
  }

  final String code;
  final RoomStatus status;
  final String hostId;
  final bool rated;
  final List<RoomPlayer> players;
  final TimeControl? timeControl;
  final String? gameId;

  RoomPlayer? playerOf(String userId) {
    for (final player in players) {
      if (player.user.id == userId) return player;
    }
    return null;
  }
}

/// Remaining time of each side, in milliseconds.
class Clocks {
  const Clocks({required this.white, required this.black});

  factory Clocks.fromJson(Object? json) {
    final map = _map(json);
    return Clocks(
      white: _field<num>(map, 'white').toInt(),
      black: _field<num>(map, 'black').toInt(),
    );
  }

  final int white;
  final int black;

  int of(Player player) => player == Player.white ? white : black;
}

class LeaderboardEntry {
  const LeaderboardEntry({required this.rank, required this.user});

  factory LeaderboardEntry.fromJson(Object? json) {
    final map = _map(json);
    return LeaderboardEntry(
      rank: _field<num>(map, 'rank').toInt(),
      user: OnlineUser.fromJson(map['user']),
    );
  }

  final int rank;
  final OnlineUser user;
}

class TournamentPlayer {
  const TournamentPlayer({required this.user, required this.score});

  factory TournamentPlayer.fromJson(Object? json) {
    final map = _map(json);
    return TournamentPlayer(
      user: OnlineUser.fromJson(map['user']),
      score: _field<num>(map, 'score').toDouble(),
    );
  }

  final OnlineUser user;
  final double score;
}

class TournamentMatch {
  const TournamentMatch({
    required this.id,
    required this.white,
    required this.black,
    this.roomCode,
    this.gameId,
    this.result,
  });

  factory TournamentMatch.fromJson(Object? json) {
    final map = _map(json);
    return TournamentMatch(
      id: _field<String>(map, 'id'),
      white: OnlineUser.fromJson(map['white']),
      black: OnlineUser.fromJson(map['black']),
      roomCode: map['roomCode'] as String?,
      gameId: map['gameId'] as String?,
      result: map['result'] == null ? null : GameResult.fromJson(map['result']),
    );
  }

  final String id;
  final OnlineUser white;
  final OnlineUser black;
  final String? roomCode;
  final String? gameId;
  final GameResult? result;
}

class TournamentRound {
  const TournamentRound({required this.number, required this.matches});

  factory TournamentRound.fromJson(Object? json) {
    final map = _map(json);
    return TournamentRound(
      number: _field<num>(map, 'number').toInt(),
      matches: [
        for (final match in (map['matches'] as List<Object?>? ?? const []))
          TournamentMatch.fromJson(match),
      ],
    );
  }

  final int number;
  final List<TournamentMatch> matches;
}

enum TournamentStatus { registering, running, finished }

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.status,
    required this.maxPlayers,
    required this.createdBy,
    required this.players,
    required this.rounds,
  });

  factory Tournament.fromJson(Object? json) {
    final map = _map(json);
    return Tournament(
      id: _field<String>(map, 'id'),
      name: _field<String>(map, 'name'),
      format: _field<String>(map, 'format'),
      status: TournamentStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => throw FormatException('tournament.status', map['status']),
      ),
      maxPlayers: _field<num>(map, 'maxPlayers').toInt(),
      createdBy: OnlineUser.fromJson(map['createdBy']),
      players: [
        for (final player in (map['players'] as List<Object?>? ?? const []))
          TournamentPlayer.fromJson(player),
      ],
      rounds: [
        for (final round in (map['rounds'] as List<Object?>? ?? const []))
          TournamentRound.fromJson(round),
      ],
    );
  }

  final String id;
  final String name;
  final String format;
  final TournamentStatus status;
  final int maxPlayers;
  final OnlineUser createdBy;
  final List<TournamentPlayer> players;
  final List<TournamentRound> rounds;

  /// Players sorted by score, best first.
  List<TournamentPlayer> get standings =>
      [...players]..sort((a, b) => b.score.compareTo(a.score));
}
