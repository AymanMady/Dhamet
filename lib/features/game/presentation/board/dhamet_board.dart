import 'dart:math' as math;

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/art/game_art.dart';
import '../../../../core/widgets/rasterized_paint.dart';
import '../animations/move_timeline.dart';
import '../pieces/piece_look.dart';
import '../pieces/piece_variants.dart';
import 'board_geometry.dart';
import 'board_layers.dart';
import 'board_surface_painter.dart';

export 'board_geometry.dart' show BoardGeometry;

/// Describes an intersection for screen readers.
typedef IntersectionLabel = String Function(
  Position position,
  Piece? piece, {
  required bool isTarget,
});

/// The Dhamet board, traced in the sand: lines, pieces, highlights and move
/// animations. Purely visual: it reports taps and never decides what is
/// legal.
///
/// It is painted in separate layers so that each repaints only when it
/// must: the sand and its lines and the pieces at rest, both kept as images,
/// with the marks beneath the pieces and what moves above them painted live.
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
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final PieceVariants _variants = PieceVariants(widget.state.board);

  MoveTimeline? _timeline;

  /// Board before the animated move, to draw the pieces being captured.
  Board? _animatedFrom;
  Map<Position, PieceLook> _capturedLooks = const {};

  @override
  void didUpdateWidget(DhametBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected != null) {
      _selectAnimation.forward(from: 0);
    }
    final state = widget.state;
    final previous = oldWidget.state;
    final move = state.lastMove;
    if (move != null &&
        state.plyCount == previous.plyCount + 1 &&
        previous.board[move.from] == move.piece) {
      _capturedLooks = {
        for (final captured in move.captured)
          captured: _variants.lookAt(captured),
      };
      _variants.play(move);
      if (widget.animate) {
        _animate(move, previous.board);
      } else {
        _stopAnimation();
      }
    } else if (state.plyCount == previous.plyCount - 1 &&
        previous.lastMove != null) {
      _variants.takeBack(previous.lastMove!);
      _stopAnimation();
    } else if (state.plyCount != previous.plyCount ||
        state.board != previous.board) {
      _stopAnimation();
    }
    _variants.sync(state.board);
  }

  void _animate(Move move, Board from) {
    final timeline = MoveTimeline(move);
    _timeline = timeline;
    _animatedFrom = from;
    _moveAnimation.duration = timeline.duration;
    _moveAnimation.forward(from: 0).whenCompleteOrCancel(() {
      // A newer move may have taken over the controller.
      if (mounted && _timeline == timeline) setState(_clearAnimation);
    });
  }

  void _stopAnimation() {
    _moveAnimation.stop();
    _clearAnimation();
  }

  void _clearAnimation() {
    _timeline = null;
    _animatedFrom = null;
    _capturedLooks = const {};
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
    final art = GameArtScope.of(context);
    final textDirection = Directionality.of(context);
    final board = widget.state.board;
    final timeline = _timeline;
    final animating = timeline != null && _animatedFrom != null;
    final focused = widget.focusedMove;
    final shown = !widget.showHints
        ? const <Move>[]
        : focused != null
        ? [focused]
        : widget.targets;
    final selected = widget.selected;
    final hidden = <Position>{if (animating) timeline.move.to else ?selected};
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final geometry = BoardGeometry(size, flipped: widget.flipped);
        // Static layers are painted once into an image; animated ones are
        // painted live.
        Widget layer(CustomPainter painter, {bool cached = false}) =>
            RepaintBoundary(
              child: cached
                  ? RasterizedPaint(painter: painter, size: Size.square(size))
                  : CustomPaint(size: Size.square(size), painter: painter),
            );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.onTap == null
              ? null
              : (details) {
                  final position = geometry.positionAt(
                    details.localPosition,
                    board: board,
                  );
                  if (position != null) widget.onTap!(position);
                },
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                layer(
                  BoardSurfacePainter(
                    geometry: geometry,
                    palette: palette,
                    showCoordinates: widget.showCoordinates,
                    sand: art?.sand,
                  ),
                  cached: true,
                ),
                layer(
                  BoardHintsPainter(
                    geometry: geometry,
                    palette: palette,
                    lastMove: animating ? null : widget.state.lastMove,
                    selected: selected,
                    targets: shown,
                    focused: focused != null,
                    mustCaptureFrom: widget.mustCaptureFrom,
                    appear: _selectAnimation,
                  ),
                ),
                layer(
                  BoardPiecesPainter(
                    geometry: geometry,
                    palette: palette,
                    board: board,
                    variants: _variants,
                    hidden: hidden,
                    art: art,
                  ),
                  cached: true,
                ),
                layer(
                  BoardEffectsPainter(
                    geometry: geometry,
                    palette: palette,
                    board: board,
                    variants: _variants,
                    selected: selected,
                    selectProgress: _selectAnimation,
                    victims: {for (final move in shown) ...move.captured},
                    timeline: timeline,
                    animatedFrom: _animatedFrom,
                    capturedLooks: _capturedLooks,
                    moveProgress: _moveAnimation,
                    art: art,
                  ),
                ),
                CustomPaint(
                  size: Size.square(size),
                  painter: BoardSemanticsPainter(
                    geometry: geometry,
                    board: board,
                    selected: selected,
                    targets: {for (final move in widget.targets) move.to},
                    onTap: widget.onTap,
                    label: widget.intersectionLabel,
                    textDirection: textDirection,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
