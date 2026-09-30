import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The small imperfections that make each piece its own, as with real
/// sticks and pebbles: a slight lean, a length, a shade, an outline.
@immutable
class PieceLook {
  const PieceLook({
    this.tilt = 0,
    this.length = 1,
    this.tone = 0,
    this.knot = 0.5,
    this.size = 1,
    this.rotation = 0,
    this.outline = _round,
    this.speckles = 0,
  });

  /// The look derived from [seed]; the same seed always gives the same look.
  factory PieceLook.fromSeed(int seed) => _cache[seed] ??= () {
    final random = math.Random(seed);
    return PieceLook(
      tilt: (random.nextDouble() - 0.5) * 0.16,
      length: 0.93 + random.nextDouble() * 0.13,
      tone: (random.nextDouble() - 0.5) * 0.2,
      knot: random.nextDouble(),
      size: 0.93 + random.nextDouble() * 0.12,
      rotation: random.nextDouble() * math.pi * 2,
      outline: List.unmodifiable([
        for (var i = 0; i < 9; i++) 0.9 + random.nextDouble() * 0.17,
      ]),
      speckles: random.nextInt(1 << 20),
    );
  }();

  static final Map<int, PieceLook> _cache = {};

  static const List<double> _round = [1, 1, 1, 1, 1, 1, 1, 1, 1];

  /// A regular piece, for icons.
  static const plain = PieceLook();

  /// Lean of a stick, in radians.
  final double tilt;

  /// Relative length of a stick.
  final double length;

  /// Shade shift, from -0.1 (darker) to 0.1 (lighter).
  final double tone;

  /// Where the knot of a stick sits, from 0 (low) to 1 (high).
  final double knot;

  /// Relative size of a pebble.
  final double size;

  /// Orientation of a pebble's outline, in radians.
  final double rotation;

  /// Radius of a pebble's outline at regular angles, relative to its size.
  final List<double> outline;

  /// Seed of the specks on a pebble.
  final int speckles;
}
