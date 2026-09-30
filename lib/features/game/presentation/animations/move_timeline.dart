import 'dart:math' as math;

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../board/board_geometry.dart';

/// The choreography of a move, as a hand would play it on the sand: the
/// piece is picked up, carried along its path (hopping over each piece it
/// captures), and put down in a small puff of sand. Each captured piece is
/// taken away as the mover passes it. A new Sultan then receives its second
/// piece.
///
/// All values are functions of the animation's progress `t`, from 0 to 1;
/// the timeline itself holds no state.
@immutable
class MoveTimeline {
  const MoveTimeline(this.move);

  final Move move;

  static const pickUp = Duration(milliseconds: 90);
  static const step = Duration(milliseconds: 230);
  static const putDown = Duration(milliseconds: 110);
  static const settle = Duration(milliseconds: 220);
  static const crowning = Duration(milliseconds: 560);

  int get segments => move.path.length;

  Duration get _travel => step * segments;

  Duration get _after => move.promotes ? crowning : settle;

  Duration get duration => pickUp + _travel + putDown + _after;

  double _share(Duration elapsed) =>
      elapsed.inMicroseconds / duration.inMicroseconds;

  double get _travelStart => _share(pickUp);

  double get _travelEnd => _share(pickUp + _travel);

  double get _landed => _share(pickUp + _travel + putDown);

  /// Distance covered along the path, in segments (0 to [segments]).
  double along(double t) =>
      segments *
      ((t - _travelStart) / (_travelEnd - _travelStart)).clamp(0.0, 1.0);

  /// Height of the moving piece: 0 on the sand, 1 held in the hand, more
  /// while hopping over a captured piece.
  double height(double t) {
    if (t < _travelStart) {
      return Curves.easeOut.transform((t / _travelStart).clamp(0.0, 1.0));
    }
    if (t < _travelEnd) {
      if (!move.isCapture) return 1;
      final distance = along(t);
      final local = distance - distance.floorToDouble();
      return 1 + 0.7 * math.sin(math.pi * local);
    }
    if (t < _landed) {
      return 1 -
          Curves.easeIn.transform((t - _travelEnd) / (_landed - _travelEnd));
    }
    return 0;
  }

  /// The intersection-level point the moving piece is above.
  Offset position(double t, BoardGeometry geometry) {
    final points = [move.from, ...move.path];
    final distance = along(t);
    final segment = math.min(distance.floor(), segments - 1);
    final local = (distance - segment).clamp(0.0, 1.0);
    return Offset.lerp(
      geometry.center(points[segment]),
      geometry.center(points[segment + 1]),
      Curves.easeInOut.transform(local),
    )!;
  }

  /// Whether the piece is back on the sand.
  bool hasLanded(double t) => t >= _landed;

  /// How far the [index]-th captured piece has been taken away: 0 while it
  /// is still there, 1 once it is gone.
  double removal(int index, double t) =>
      ((along(t) - index - 0.45) / 0.5).clamp(0.0, 1.0);

  /// Progress of the puff of sand where the piece lands (0 before landing).
  double landingDust(double t) =>
      t < _landed ? 0 : ((t - _landed) / _share(settle)).clamp(0.0, 1.0);

  /// Progress of a promotion (0 before landing, and without promotion).
  double crown(double t) => !move.promotes || t < _landed
      ? 0
      : ((t - _landed) / (1 - _landed)).clamp(0.0, 1.0);

  /// How visible the hollows left by captured pieces still are: they fill
  /// back in at the end of the move.
  double imprints(double t) => ((1 - t) / 0.25).clamp(0.0, 1.0);
}
