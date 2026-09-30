import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/theme/app_theme.dart';
import '../animations/move_timeline.dart';
import '../animations/sand_effects.dart';
import '../pieces/piece_look.dart';
import '../pieces/piece_renderer.dart';
import '../pieces/piece_variants.dart';
import 'board_geometry.dart';
import 'sand_marks.dart';

/// Lift of the selected piece, as if picked up by the hand.
const double _heldLift = 0.55;

/// Marks in the sand beneath the pieces: the track of the last move, the
/// rings around the selected piece and the pieces that must capture, and
/// hollows on the possible destinations.
class BoardHintsPainter extends CustomPainter {
  BoardHintsPainter({
    required this.geometry,
    required this.palette,
    required this.lastMove,
    required this.selected,
    required this.targets,
    required this.focused,
    required this.mustCaptureFrom,
    required this.appear,
  }) : super(repaint: appear);

  final BoardGeometry geometry;
  final BoardPalette palette;

  /// `null` while a move is animated.
  final Move? lastMove;
  final Position? selected;

  /// Destinations to show.
  final List<Move> targets;

  /// Whether [targets] is a single sequence being chosen.
  final bool focused;
  final Set<Position> mustCaptureFrom;

  /// Grows the selection marks when a piece is picked.
  final Animation<double> appear;

  double get _cell => geometry.cell;

  @override
  void paint(Canvas canvas, Size size) {
    final last = lastMove;
    if (last != null) _paintLastMove(canvas, last);
    for (final position in mustCaptureFrom) {
      paintTracedRing(
        canvas,
        geometry.center(position),
        _cell * 0.47,
        _cell * 0.06,
        palette.capture,
        palette,
        dashes: 10,
      );
    }
    final grow = Curves.easeOutBack.transform(appear.value);
    final selected = this.selected;
    if (selected != null) {
      paintTracedRing(
        canvas,
        geometry.center(selected),
        _cell * (0.36 + 0.1 * grow),
        _cell * 0.065,
        palette.highlight,
        palette,
      );
    }
    for (final move in targets) {
      final destination = geometry.center(move.to);
      if (move.isCapture) {
        _paintFingerDots(canvas, [move.from, ...move.path]);
        paintTracedRing(
          canvas,
          destination,
          _cell * 0.3 * grow,
          _cell * 0.05,
          palette.capture,
          palette,
        );
      }
      paintHollow(
        canvas,
        destination,
        _cell * 0.2 * grow,
        palette,
        tint: move.isCapture ? palette.capture : palette.highlight,
      );
    }
  }

  void _paintLastMove(Canvas canvas, Move move) {
    paintTrail(
      canvas,
      [
        for (final point in [move.from, ...move.path]) geometry.center(point),
      ],
      _cell * 0.2,
      palette,
      palette.lastMove,
    );
    paintHollow(canvas, geometry.center(move.from), _cell * 0.14, palette);
    for (final captured in move.captured) {
      paintHollow(
        canvas,
        geometry.center(captured),
        _cell * 0.12,
        palette,
        opacity: 0.6,
      );
    }
    final to = geometry.center(move.to);
    canvas.drawOval(
      Rect.fromCenter(
        center: to,
        width: _cell * 1.05,
        height: _cell * 1.05 * sandPerspective,
      ),
      Paint()
        ..shader = ui.Gradient.radial(to, _cell * 0.52, [
          palette.lastMove.withValues(alpha: 0.55),
          palette.lastMove.withValues(alpha: 0),
        ]),
    );
  }

  /// A capture path, dotted in the sand with a fingertip.
  void _paintFingerDots(Canvas canvas, List<Position> points) {
    final dot = Paint()
      ..color = palette.capture.withValues(alpha: focused ? 0.95 : 0.7);
    for (var i = 0; i + 1 < points.length; i++) {
      final a = geometry.center(points[i]);
      final b = geometry.center(points[i + 1]);
      final count = math.max(1, ((b - a).distance / (_cell * 0.3)).floor());
      for (var k = 1; k < count; k++) {
        canvas.drawCircle(
          Offset.lerp(a, b, k / count)!,
          _cell * (focused ? 0.055 : 0.045),
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardHintsPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.palette != palette ||
      oldDelegate.lastMove != lastMove ||
      oldDelegate.selected != selected ||
      !listEquals(oldDelegate.targets, targets) ||
      oldDelegate.focused != focused ||
      !setEquals(oldDelegate.mustCaptureFrom, mustCaptureFrom);
}

/// The pieces at rest, back to front, all shadows first. Repainted only
/// when the position changes.
class BoardPiecesPainter extends CustomPainter {
  BoardPiecesPainter({
    required this.geometry,
    required this.palette,
    required this.board,
    required this.variants,
    required this.hidden,
  }) : _variantsVersion = variants.version;

  final BoardGeometry geometry;
  final BoardPalette palette;
  final Board board;
  final PieceVariants variants;
  final int _variantsVersion;

  /// Pieces drawn by [BoardEffectsPainter] instead: held or moving.
  final Set<Position> hidden;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = geometry.cell;
    final pieces =
        [
          for (final entry in board.pieces.entries)
            if (!hidden.contains(entry.key))
              (
                geometry.center(entry.key),
                entry.value,
                variants.lookAt(entry.key),
              ),
        ]..sort(
          (a, b) => a.$1.dy != b.$1.dy
              ? a.$1.dy.compareTo(b.$1.dy)
              : a.$1.dx.compareTo(b.$1.dx),
        );
    for (final (base, piece, look) in pieces) {
      PieceRenderer.paintShadow(canvas, base, cell, piece, palette, look: look);
    }
    for (final (base, piece, look) in pieces) {
      PieceRenderer.paintBody(canvas, base, cell, piece, palette, look: look);
    }
  }

  @override
  bool shouldRepaint(BoardPiecesPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.palette != palette ||
      oldDelegate.board != board ||
      oldDelegate._variantsVersion != _variantsVersion ||
      !setEquals(oldDelegate.hidden, hidden);
}

/// What moves above the pieces: the selected piece held up, crosses on the
/// pieces a capture would take, and the animation of the last move.
class BoardEffectsPainter extends CustomPainter {
  BoardEffectsPainter({
    required this.geometry,
    required this.palette,
    required this.board,
    required this.variants,
    required this.selected,
    required this.selectProgress,
    required this.victims,
    required this.timeline,
    required this.animatedFrom,
    required this.capturedLooks,
    required this.moveProgress,
  }) : super(repaint: Listenable.merge([selectProgress, moveProgress]));

  final BoardGeometry geometry;
  final BoardPalette palette;
  final Board board;
  final PieceVariants variants;
  final Position? selected;
  final Animation<double> selectProgress;

  /// Pieces the shown captures would take.
  final Set<Position> victims;

  /// The move being animated, and the board before it.
  final MoveTimeline? timeline;
  final Board? animatedFrom;

  /// Looks of the pieces the animated move captures.
  final Map<Position, PieceLook> capturedLooks;
  final Animation<double> moveProgress;

  double get _cell => geometry.cell;

  @override
  void paint(Canvas canvas, Size size) {
    final timeline = this.timeline;
    final from = animatedFrom;
    if (timeline != null && from != null) {
      _paintMove(canvas, timeline, from);
      return;
    }
    for (final victim in victims) {
      final piece = board[victim];
      if (piece != null) {
        _paintCross(
          canvas,
          PieceRenderer.visualCenter(geometry.center(victim), _cell, piece),
        );
      }
    }
    final selected = this.selected;
    final piece = selected == null ? null : board[selected];
    if (selected != null && piece != null) {
      final lift =
          _heldLift * Curves.easeOutBack.transform(selectProgress.value);
      final base = geometry.center(selected);
      final look = variants.lookAt(selected);
      PieceRenderer.paintShadow(
        canvas,
        base,
        _cell,
        piece,
        palette,
        look: look,
        lift: lift,
      );
      PieceRenderer.paintBody(
        canvas,
        base,
        _cell,
        piece,
        palette,
        look: look,
        lift: lift,
        scale: 1 + 0.11 * lift,
      );
    }
  }

  void _paintMove(Canvas canvas, MoveTimeline timeline, Board from) {
    final t = moveProgress.value;
    final move = timeline.move;
    for (final (index, captured) in move.captured.indexed) {
      final piece = from[captured];
      if (piece == null) continue;
      final center = geometry.center(captured);
      final removal = timeline.removal(index, t);
      if (removal > 0) {
        paintHollow(
          canvas,
          center,
          _cell * 0.14,
          palette,
          opacity: timeline.imprints(t),
        );
      }
      if (removal < 1) {
        final look = capturedLooks[captured] ?? PieceLook.plain;
        PieceRenderer.paintShadow(
          canvas,
          center,
          _cell,
          piece,
          palette,
          look: look,
          lift: removal * 1.2,
          opacity: 1 - removal,
        );
        PieceRenderer.paintBody(
          canvas,
          center,
          _cell,
          piece,
          palette,
          look: look,
          lift: removal * 1.2,
          opacity: 1 - removal,
          scale: 1 - 0.2 * removal,
        );
      }
      paintSandPuff(
        canvas,
        center,
        _cell,
        removal,
        palette,
        seed: captured.index,
      );
    }

    final landing = geometry.center(move.to);
    paintSandPuff(
      canvas,
      landing,
      _cell,
      timeline.landingDust(t),
      palette,
      seed: move.to.index + 101,
    );
    final crown = timeline.crown(t);
    paintCrowning(canvas, landing, _cell, crown, palette.lastMove);
    final base = timeline.position(t, geometry);
    final lift = _heldLift * timeline.height(t);
    final piece = crown > 0 ? move.piece.promoted : move.piece;
    final look = variants.lookAt(move.to);
    PieceRenderer.paintShadow(
      canvas,
      base,
      _cell,
      piece,
      palette,
      look: look,
      lift: lift,
    );
    PieceRenderer.paintBody(
      canvas,
      base,
      _cell,
      piece,
      palette,
      look: look,
      lift: lift,
      scale: (1 + 0.11 * lift) * (1 + 0.14 * math.sin(math.pi * crown)),
    );
  }

  /// A cross of red ochre on a piece that would be captured.
  void _paintCross(Canvas canvas, Offset center) {
    final arm = _cell * 0.13;
    final outline = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _cell * 0.1
      ..color = palette.sandLight.withValues(alpha: 0.9);
    final ink = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _cell * 0.06
      ..color = palette.capture;
    for (final paint in [outline, ink]) {
      canvas
        ..drawLine(
          center + Offset(-arm, -arm),
          center + Offset(arm, arm),
          paint,
        )
        ..drawLine(
          center + Offset(-arm, arm),
          center + Offset(arm, -arm),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(BoardEffectsPainter oldDelegate) => true;
}

/// Describes each intersection for screen readers; paints nothing.
class BoardSemanticsPainter extends CustomPainter {
  BoardSemanticsPainter({
    required this.geometry,
    required this.board,
    required this.selected,
    required this.targets,
    required this.onTap,
    required this.label,
    required this.textDirection,
  });

  final BoardGeometry geometry;
  final Board board;
  final Position? selected;
  final Set<Position> targets;
  final ValueChanged<Position>? onTap;
  final String Function(
    Position position,
    Piece? piece, {
    required bool isTarget,
  })?
  label;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final label = this.label;
    final onTap = this.onTap;
    return [
      for (final position in Position.all)
        CustomPainterSemantics(
          rect: Rect.fromCircle(
            center: geometry.center(position),
            radius: geometry.cell / 2,
          ),
          properties: SemanticsProperties(
            label: label != null
                ? label(
                    position,
                    board[position],
                    isTarget: targets.contains(position),
                  )
                : position.notation,
            selected: position == selected,
            button: onTap != null,
            textDirection: textDirection,
            onTap: onTap == null ? null : () => onTap(position),
          ),
        ),
    ];
  };

  @override
  bool shouldRepaint(BoardSemanticsPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(BoardSemanticsPainter oldDelegate) => true;
}
