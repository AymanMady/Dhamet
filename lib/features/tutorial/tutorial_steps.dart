import 'package:dhamet_engine/dhamet_engine.dart';

import '../../core/localization/l10n.dart';

/// One lesson of the tutorial. Positions are real engine states, and an
/// exercise is solved by a legal move that satisfies [goal].
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    required this.state,
    this.goal,
  });

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
  final GameState state;

  /// `null` for a lesson without exercise.
  final bool Function(Move move)? goal;

  bool get isExercise => goal != null;
}

GameState _position(Map<String, Piece> pieces) => GameState(
  board: Board.fromPieces({
    for (final MapEntry(:key, :value) in pieces.entries)
      Position.parse(key): value,
  }),
  currentPlayer: Player.white,
);

/// The tutorial, in order.
final List<TutorialStep> tutorialSteps = [
  TutorialStep(
    title: (l10n) => l10n.tutorialBoardTitle,
    body: (l10n) => l10n.tutorialBoardBody,
    state: GameState(board: Board.empty(), currentPlayer: Player.white),
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialPiecesTitle,
    body: (l10n) => l10n.tutorialPiecesBody,
    state: GameState.initial(),
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialMoveTitle,
    body: (l10n) => l10n.tutorialMoveBody,
    state: _position({'e3': Piece.whitePawn, 'a9': Piece.blackPawn}),
    goal: (move) => !move.isCapture,
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialCaptureTitle,
    body: (l10n) => l10n.tutorialCaptureBody,
    state: _position({
      'e4': Piece.whitePawn,
      'c3': Piece.whitePawn,
      'e5': Piece.blackPawn,
      'a9': Piece.blackPawn,
    }),
    goal: (move) => move.isCapture,
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialRafleTitle,
    body: (l10n) => l10n.tutorialRafleBody,
    // The multiple capture given as an example by the French source.
    state: _position({
      'g7': Piece.whitePawn,
      'h6': Piece.blackPawn,
      'h4': Piece.blackPawn,
      'g4': Piece.blackPawn,
      'f6': Piece.blackPawn,
      'd8': Piece.blackPawn,
      'a9': Piece.blackPawn,
    }),
    goal: (move) => move.captureCount == 5,
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialPromotionTitle,
    body: (l10n) => l10n.tutorialPromotionBody,
    state: _position({'d8': Piece.whitePawn, 'a9': Piece.blackPawn}),
    goal: (move) => move.promotes,
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialSultanTitle,
    body: (l10n) => l10n.tutorialSultanBody,
    state: _position({
      'e5': Piece.whiteSultan,
      'c3': Piece.blackPawn,
      'a9': Piece.blackPawn,
    }),
    goal: (move) => move.isSultanMove && move.isCapture,
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialVictoryTitle,
    body: (l10n) => l10n.tutorialVictoryBody,
    state: _position({'e3': Piece.whitePawn, 'e4': Piece.blackPawn}),
    goal: (move) => move.isCapture,
  ),
  TutorialStep(
    title: (l10n) => l10n.tutorialSpecialTitle,
    body: (l10n) => l10n.tutorialSpecialBody,
    state: _position({
      'e3': Piece.whitePawn,
      'd3': Piece.blackPawn,
      'e4': Piece.blackPawn,
      'e6': Piece.blackPawn,
      'a9': Piece.blackPawn,
    }),
    goal: (move) => move.captureCount == 2,
  ),
];
