import 'dart:convert';

import 'package:dhamet_engine_bridge/engine_registry.dart';
import 'package:test/test.dart';

Map<String, Object?> decode(String json) =>
    jsonDecode(json) as Map<String, Object?>;

Map<String, Object?> snapshotOf(String json) =>
    decode(json)['snapshot']! as Map<String, Object?>;

Object? errorCode(String json) =>
    (decode(json)['error']! as Map<String, Object?>)['code'];

void main() {
  const timestamp = '2026-09-30T10:00:00.000Z';
  const d4e5 =
      '{"piece":"w","from":"d4","path":["e5"],"captured":[],"promotes":false}';
  late EngineRegistry registry;

  setUp(() => registry = EngineRegistry());

  test('create opens a standard game without undo', () {
    final snapshot = snapshotOf(registry.create('g'));
    expect(snapshot['currentPlayer'], 'white');
    expect(snapshot['plyCount'], 0);
    expect(snapshot['result'], isNull);
    expect(snapshot['pieceCounts'], {'white': 40, 'black': 40});
    final game = snapshot['game']! as Map<String, Object?>;
    expect(game['undoPolicy'], {'enabled': false, 'maxDepth': null});
    expect(registry.size, 1);
    expect(errorCode(registry.create('g')), 'GAME_EXISTS');
  });

  test('legalMoves lists moves with their notation', () {
    registry.create('g');
    final moves = decode(registry.legalMoves('g'))['moves']! as List<Object?>;
    expect(
      [for (final m in moves) (m! as Map<String, Object?>)['notation']],
      ['d4-e5', 'e4-e5', 'f4-e5'],
    );
  });

  test('play accepts a legal move and returns the engine copy', () {
    registry.create('g');
    final response = decode(registry.play('g', d4e5, timestamp));
    expect(response['ok'], isTrue);
    expect(response['move'], jsonDecode(d4e5));
    expect((response['snapshot']! as Map<String, Object?>)['plyCount'], 1);
  });

  test('play refuses illegal and malformed moves', () {
    registry.create('g');
    expect(
      errorCode(registry.play('g', d4e5.replaceFirst('d4', 'c4'), timestamp)),
      'ILLEGAL_MOVE',
    );
    expect(
      errorCode(registry.play('g', '{"piece":"w"}', timestamp)),
      'ILLEGAL_MOVE',
    );
    expect(
      errorCode(registry.play('g', 'not json', timestamp)),
      'ILLEGAL_MOVE',
    );
    expect(snapshotOf(registry.snapshot('g'))['plyCount'], 0);
  });

  test('resign and loseOnTime declare the result', () {
    registry.create('a');
    expect(snapshotOf(registry.resign('a', 'black'))['result'], {
      'winner': 'white',
      'reason': 'resignation',
    });
    expect(errorCode(registry.play('a', d4e5, timestamp)), 'GAME_OVER');
    expect(errorCode(registry.loseOnTime('a', 'white')), 'GAME_OVER');
    registry.create('b');
    expect(snapshotOf(registry.loseOnTime('b', 'white'))['result'], {
      'winner': 'black',
      'reason': 'timeout',
    });
  });

  test('load replays a saved game', () {
    registry.create('g');
    registry.play('g', d4e5, timestamp);
    final saved = snapshotOf(registry.snapshot('g'));
    final loaded = snapshotOf(registry.load('copy', jsonEncode(saved['game'])));
    expect(loaded, saved);
    expect(
      errorCode(
        registry.load(
          'bad',
          jsonEncode(saved['game']).replaceFirst('"d4"', '"c4"'),
        ),
      ),
      'INVALID_JSON',
    );
  });

  test('unknown and closed games are reported', () {
    expect(errorCode(registry.snapshot('none')), 'UNKNOWN_GAME');
    registry.create('g');
    registry.close('g');
    expect(registry.size, 0);
    expect(errorCode(registry.play('g', d4e5, timestamp)), 'UNKNOWN_GAME');
  });
}
