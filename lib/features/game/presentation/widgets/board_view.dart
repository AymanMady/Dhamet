import 'dart:math' as math;

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/theme/app_theme.dart';
import 'piece_painter.dart';

/// Maps intersections to pixels on a square board of side [size].
@immutable
class BoardGeometry {
  const BoardGeometry(this.size, {this.flipped = false});

  final double size;

  /// Black's side at the bottom.
  final bool flipped;

  static const double _marginInCells = 0.7;

  double get cell => size / (8 + 2 * _marginInCells);

  double get margin => cell * _marginInCells;

  double get pieceRadius => cell * 0.37;

  Offset center(Position position) {
    final column = flipped ? 8 - position.column : position.column;
    final row = flipped ? position.row : 8 - position.row;
    return Offset(margin + column * cell, margin + row * cell);
  }

  /// The intersection under [offset], or `null` outside the board.
  Position? positionAt(Offset offset) {
    final column = ((offset.dx - margin) / cell).round();
    final row = ((offset.dy - margin) / cell).round();
    final position = Position.tryAt(
      flipped ? 8 - column : column,
      flipped ? row : 8 - row,
    );
    if (position == null) return null;
    return (center(position) - offset).distance <= cell * 0.75
        ? position
        : null;
  }
}

/// Describes an intersection for screen readers.
typedef IntersectionLabel = String Function(
  Position position,
  Piece? piece, {
  required bool isTarget,
});

/// The Dhamet board: lines, pieces and highlights. Purely visual: it
/// reports taps and never decides what is legal.
class DhametBoard extends StatefulWidget {
  const DhametBoard({
    super.key,
    required this.state,
    this.selected,
    this.targets = const [],
    this.mustCaptureFrom = const {},
    this.focusedMove,
    this.onTap,
    this.flipped = false,
    this.showCoordinates = false,
    this.showHints = true,
    this.animate = true,
    this.intersectionLabel,
  });

  final GameState state;

  /// The selected piece.
  final Position? selected;

  /// Legal moves of the selected piece.
  final List<Move> targets;

  /// Pieces that can capture, when a capture is mandatory.
  final Set<Position> mustCaptureFrom;

  /// A move to emphasise, e.g. while choosing between capture sequences.
  final Move? focusedMove;

  final ValueChanged<Position>? onTap;
  final bool flipped;
  final bool showCoordinates;
  final bool showHints;
  final bool animate;
  final IntersectionLabel? intersectionLabel;

  @override
  State<DhametBoard> createState() => _DhametBoardState();
}

class _DhametBoardState extends State<DhametBoard>
    with TickerProviderStateMixin {
  late final AnimationController _moveAnimation = AnimationController(
    vsync: this,
  );
  late final AnimationController _selectAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    value: 1,
  );

  /// Board before the animated move, to draw the pieces being captured.
  Board? _animatedFrom;
  Move? _animatedMove;

  @override
  void didUpdateWidget(DhametBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected != null) {
      _selectAnimation.forward(from: 0);
    }
    final move = widget.state.lastMove;
    final isNextMove = widget.state.plyCount == oldWidget.state.plyCount + 1;
    if (widget.animate &&
        move != null &&
        isNextMove &&
        oldWidget.state.board[move.from] == move.piece) {
      _animatedFrom = oldWidget.state.board;
      _animatedMove = move;
      _moveAnimation.duration = Duration(
        milliseconds: 200 * move.path.length + (move.promotes ? 450 : 80),
      );
      _moveAnimation.forward(from: 0).whenCompleteOrCancel(() {
        if (mounted) {
          setState(() {
            _animatedFrom = null;
            _animatedMove = null;
          });
        }
      });
    } else if (widget.state.plyCount != oldWidget.state.plyCount) {
      _moveAnimation.stop();
      _animatedFrom = null;
      _animatedMove = null;
    }
  }

  @override
  void dispose() {
    _moveAnimation.dispose();
    _selectAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.boardPalette;
    final textDirection = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final geometry = BoardGeometry(size, flipped: widget.flipped);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.onTap == null
              ? null
              : (details) {
                  final position = geometry.positionAt(details.localPosition);
                  if (position != null) widget.onTap!(position);
                },
          child: CustomPaint(
            size: Size.square(size),
            painter: _BoardPainter(
              geometry: geometry,
              palette: palette,
              widget: widget,
              animatedFrom: _animatedFrom,
              animatedMove: _animatedMove,
              moveProgress: _moveAnimation,
              selectProgress: _selectAnimation,
              textDirection: textDirection,
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.geometry,
    required this.palette,
    required this.widget,
    required this.animatedFrom,
    required this.animatedMove,
    required this.moveProgress,
    required this.selectProgress,
    required this.textDirection,
  }) : super(repaint: Listenable.merge([moveProgress, selectProgress]));

  final BoardGeometry geometry;
  final BoardPalette palette;
  final DhametBoard widget;
  final Board? animatedFrom;
  final Move? animatedMove;
  final Animation<double> moveProgress;
  final Animation<double> selectProgress;
  final TextDirection textDirection;

  double get _cell => geometry.cell;
  double get _radius => geometry.pieceRadius;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSurface(canvas);
    _paintLines(canvas);
    if (widget.showCoordinates) _paintCoordinates(canvas);
    _paintLastMove(canvas);
    if (widget.showHints) _paintPaths(canvas);
    _paintMustCapture(canvas);
    _paintPieces(canvas);
    if (widget.showHints) _paintTargets(canvas);
    _paintSelection(canvas);
  }

  void _paintSurface(Canvas canvas) {
    final rect = Offset.zero & Size.square(geometry.size);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(_cell * 0.5));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(palette.surface, Colors.white, 0.18)!,
            palette.surface,
          ],
          radius: 0.9,
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = palette.surfaceEdge,
    );
  }

  void _paintLines(Canvas canvas) {
    final strong = Paint()
      ..color = palette.line
      ..strokeWidth = math.max(1.2, _cell * 0.045)
      ..strokeCap = StrokeCap.round;
    final faint = Paint()
      ..color = palette.faintLine
      ..strokeWidth = math.max(0.8, _cell * 0.025)
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in BoardTopology.standard.segments) {
      final horizontal = a.row == b.row;
      final vertical = a.column == b.column;
      final traditionallyUndrawn =
          (horizontal && a.row.isOdd) || (vertical && a.column.isOdd);
      canvas.drawLine(
        geometry.center(a),
        geometry.center(b),
        traditionallyUndrawn ? faint : strong,
      );
    }
    final dot = Paint()..color = palette.line;
    for (final position in Position.all) {
      canvas.drawCircle(geometry.center(position), _cell * 0.05, dot);
    }
  }

  void _paintCoordinates(Canvas canvas) {
    final style = TextStyle(
      color: palette.coordinates,
      fontSize: _cell * 0.26,
      fontWeight: FontWeight.w600,
    );
    void label(String text, Offset center) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final bottomRow = widget.flipped ? 8 : 0;
    final leftColumn = widget.flipped ? 8 : 0;
    for (var i = 0; i < 9; i++) {
      final columnPoint = geometry.center(Position(i, bottomRow));
      label(
        String.fromCharCode(0x61 + i),
        columnPoint + Offset(0, _cell * 0.55),
      );
      final rowPoint = geometry.center(Position(leftColumn, i));
      label('${i + 1}', rowPoint - Offset(_cell * 0.55, 0));
    }
  }

  void _paintPolyline(Canvas canvas, List<Position> points, Paint paint) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = geometry.center(points[i]);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _paintCross(Canvas canvas, Position position, Color color) {
    final center = geometry.center(position);
    final arm = _radius * 0.45;
    final paint = Paint()
      ..color = color
      ..strokeWidth = _cell * 0.07
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(center + Offset(-arm, -arm), center + Offset(arm, arm), paint)
      ..drawLine(center + Offset(-arm, arm), center + Offset(arm, -arm), paint);
  }

  void _paintLastMove(Canvas canvas) {
    final move = widget.state.lastMove;
    if (move == null || animatedMove != null) return;
    final color = palette.lastMove;
    canvas.drawCircle(
      geometry.center(move.to),
      _radius * 1.22,
      Paint()..color = color.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      geometry.center(move.from),
      _radius * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cell * 0.05
        ..color = color.withValues(alpha: 0.8),
    );
    _paintPolyline(
      canvas,
      [move.from, ...move.path],
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cell * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.5),
    );
    for (final captured in move.captured) {
      _paintCross(canvas, captured, palette.capture.withValues(alpha: 0.45));
    }
  }

  List<Move> get _shownTargets {
    final focused = widget.focusedMove;
    return focused != null ? [focused] : widget.targets;
  }

  void _paintPaths(Canvas canvas) {
    for (final move in _shownTargets) {
      if (!move.isCapture) continue;
      _paintPolyline(
        canvas,
        [move.from, ...move.path],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _cell * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = palette.capture.withValues(
            alpha: widget.focusedMove != null ? 0.8 : 0.45,
          ),
      );
    }
  }

  void _paintMustCapture(Canvas canvas) {
    if (widget.mustCaptureFrom.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cell * 0.05
      ..color = palette.capture;
    for (final position in widget.mustCaptureFrom) {
      final center = geometry.center(position);
      // Dashed ring: shape, not only colour, marks the pieces that must take.
      const dashes = 10;
      for (var i = 0; i < dashes; i++) {
        final start = i * 2 * math.pi / dashes;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: _radius * 1.2),
          start,
          math.pi / dashes,
          false,
          paint,
        );
      }
    }
  }

  void _paintPieces(Canvas canvas) {
    final board = widget.state.board;
    final move = animatedMove;
    final from = animatedFrom;
    if (move == null || from == null) {
      for (final MapEntry(key: position, value: piece)
          in board.pieces.entries) {
        paintPiece(canvas, geometry.center(position), _radius, piece);
      }
      return;
    }

    final progress = moveProgress.value;
    final travelShare = move.promotes ? 0.7 : 1.0;
    final travel = (progress / travelShare).clamp(0.0, 1.0);
    final segments = move.path.length;
    final along = travel * segments;

    for (final MapEntry(key: position, value: piece) in board.pieces.entries) {
      if (position == move.to) continue;
      paintPiece(canvas, geometry.center(position), _radius, piece);
    }
    for (var i = 0; i < move.captured.length; i++) {
      final captured = move.captured[i];
      final piece = from[captured];
      if (piece == null) continue;
      final opacity = (1 - (along - i - 0.5) * 2).clamp(0.0, 1.0);
      paintPiece(
        canvas,
        geometry.center(captured),
        _radius,
        piece,
        opacity: opacity,
      );
    }

    final points = [move.from, ...move.path];
    final segment = math.min(along.floor(), segments - 1);
    final local = along - segment;
    final center = Offset.lerp(
      geometry.center(points[segment]),
      geometry.center(points[segment + 1]),
      Curves.easeInOut.transform(local.clamp(0.0, 1.0)),
    )!;
    final arrived = travel >= 1;
    final piece = arrived && move.promotes ? move.piece.promoted : move.piece;
    if (arrived && move.promotes) {
      final glow = ((progress - travelShare) / (1 - travelShare)).clamp(
        0.0,
        1.0,
      );
      canvas.drawCircle(
        center,
        _radius * (1 + glow * 0.9),
        Paint()..color = palette.lastMove.withValues(alpha: 0.55 * (1 - glow)),
      );
    }
    paintPiece(
      canvas,
      center,
      _radius * (arrived ? 1 : 1.08),
      piece,
      lifted: !arrived,
    );
  }

  void _paintTargets(Canvas canvas) {
    for (final move in _shownTargets) {
      final center = geometry.center(move.to);
      if (move.isCapture) {
        canvas.drawCircle(
          center,
          _radius * 0.8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _cell * 0.08
            ..color = palette.capture,
        );
        for (final captured in move.captured) {
          _paintCross(canvas, captured, palette.capture);
        }
      } else {
        canvas.drawCircle(
          center,
          _radius * 0.34,
          Paint()..color = palette.highlight.withValues(alpha: 0.85),
        );
      }
    }
  }

  void _paintSelection(Canvas canvas) {
    final selected = widget.selected;
    if (selected == null) return;
    final grow = Curves.easeOutBack.transform(selectProgress.value);
    canvas.drawCircle(
      geometry.center(selected),
      _radius * (1.0 + 0.2 * grow),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cell * 0.08
        ..color = palette.highlight,
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final label = widget.intersectionLabel;
    final targets = {for (final move in widget.targets) move.to};
    return [
      for (final position in Position.all)
        CustomPainterSemantics(
          rect: Rect.fromCircle(
            center: geometry.center(position),
            radius: _cell / 2,
          ),
          properties: SemanticsProperties(
            label: label != null
                ? label(
                    position,
                    widget.state.board[position],
                    isTarget: targets.contains(position),
                  )
                : position.notation,
            selected: position == widget.selected,
            button: widget.onTap != null,
            textDirection: textDirection,
            onTap: widget.onTap == null ? null : () => widget.onTap!(position),
          ),
        ),
    ];
  };

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(_BoardPainter oldDelegate) => true;
}
