// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dhamet';

  @override
  String get appTagline => 'Mauritanian Traditional Game';

  @override
  String get homeNewGame => 'New game';

  @override
  String get homePlayAi => 'Play against the AI';

  @override
  String get homePlayFriend => 'Play with a friend';

  @override
  String get homePlayOnline => 'Play online';

  @override
  String get homeHowToPlay => 'How to play';

  @override
  String get homeHistory => 'History';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeResume => 'Resume game';

  @override
  String homeResumeDetails(String mode, int moveNumber) {
    return '$mode · move $moveNumber';
  }

  @override
  String get modeTitle => 'Game mode';

  @override
  String get modeLocal => 'Player vs player';

  @override
  String get modeLocalDescription => 'Two players on the same device';

  @override
  String get modeAi => 'Player vs AI';

  @override
  String get modeAiDescription => 'Challenge the computer';

  @override
  String get aiSetupTitle => 'Against the AI';

  @override
  String get difficultyTitle => 'Difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get difficultyEasyDescription => 'To discover the game';

  @override
  String get difficultyMediumDescription => 'A fair opponent';

  @override
  String get difficultyHardDescription => 'Punishes every mistake';

  @override
  String get difficultyExpertDescription => 'Thinks longer and plays strong';

  @override
  String get sideTitle => 'Your side';

  @override
  String get sideRandom => 'Random';

  @override
  String get whiteStarts => 'White moves first.';

  @override
  String get startGame => 'Start';

  @override
  String get playerWhite => 'White';

  @override
  String get playerBlack => 'Black';

  @override
  String get playerYou => 'You';

  @override
  String playerAi(String level) {
    return 'AI · $level';
  }

  @override
  String turnOf(String player) {
    return '$player to move';
  }

  @override
  String get yourTurn => 'Your turn';

  @override
  String get aiThinking => 'The AI is thinking…';

  @override
  String get toMove => 'To move';

  @override
  String get mustCapture =>
      'Capture is mandatory: take as many pieces as possible.';

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces',
      one: '1 piece',
      zero: 'no pieces',
    );
    return '$_temp0';
  }

  @override
  String sultansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sultans',
      one: '1 Sultan',
      zero: 'no Sultan',
    );
    return '$_temp0';
  }

  @override
  String lastMoveLabel(String move) {
    return 'Last move: $move';
  }

  @override
  String get chooseCapture => 'Several capture sequences end here: choose one.';

  @override
  String captureOption(String notation, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count captures',
      one: '1 capture',
    );
    return '$notation · $_temp0';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get resign => 'Resign';

  @override
  String get restart => 'Restart';

  @override
  String get resignTitle => 'Resign the game?';

  @override
  String get resignBody => 'Your opponent will be declared the winner.';

  @override
  String get restartTitle => 'Restart?';

  @override
  String get restartBody => 'The current game will be abandoned.';

  @override
  String get resultVictory => 'Victory';

  @override
  String get resultDefeat => 'Defeat';

  @override
  String get resultDraw => 'Draw';

  @override
  String resultWinner(String player) {
    return '$player wins';
  }

  @override
  String get reasonElimination => 'All the opponent\'s pieces were captured.';

  @override
  String get reasonBlocked => 'The opponent has no move left.';

  @override
  String get reasonResignation => 'Resignation.';

  @override
  String get reasonTimeout => 'Time ran out.';

  @override
  String get reasonRepetition => 'The same position was repeated.';

  @override
  String get reasonAgreement => 'Draw by agreement.';

  @override
  String movesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
      zero: 'no moves',
    );
    return '$_temp0';
  }

  @override
  String get playAgain => 'Play again';

  @override
  String get backHome => 'Back to home';

  @override
  String get viewGame => 'View the game';

  @override
  String get replayTitle => 'Game replay';

  @override
  String get replayStart => 'Starting position';

  @override
  String replayPosition(int ply, int total) {
    return 'Move $ply of $total';
  }

  @override
  String get replayFirst => 'Start';

  @override
  String get replayPrevious => 'Previous move';

  @override
  String get replayNext => 'Next move';

  @override
  String get replayLast => 'End';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGame => 'Game';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsSectionAdvanced => 'Advanced';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsSound => 'Sounds';

  @override
  String get settingsHaptics => 'Vibrations';

  @override
  String get settingsAnimations => 'Animations';

  @override
  String get settingsAnimationsDescription => 'Turn off for instant moves.';

  @override
  String get settingsCoordinates => 'Show coordinates';

  @override
  String get settingsHints => 'Show possible moves';

  @override
  String get settingsAnalytics => 'Anonymous usage statistics';

  @override
  String get settingsAnalyticsDescription =>
      'Nothing is sent without your consent.';

  @override
  String get settingsDeveloper => 'Developer mode';

  @override
  String get settingsDeveloperDescription =>
      'Coordinates, legal moves, game state, AI timing.';

  @override
  String get settingsPerformanceOverlay => 'Show performance (FPS)';

  @override
  String get settingsServerUrl => 'Server address';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutBody =>
      'Dhamet (ظامت) is the traditional draughts game of Mauritania. The rules applied and their sources are documented; some still need to be confirmed with players.';

  @override
  String get devPanelTitle => 'Developer';

  @override
  String devLegalMoves(int count) {
    return 'Legal moves ($count)';
  }

  @override
  String devAiTime(int milliseconds) {
    return 'AI time: $milliseconds ms';
  }

  @override
  String devPly(int ply) {
    return 'Plies played: $ply';
  }

  @override
  String get devState => 'Game state (JSON)';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No finished game yet.';

  @override
  String historyAgainstAi(String level) {
    return 'Against the AI · $level';
  }

  @override
  String get historyLocal => 'Two players';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyWon => 'Won';

  @override
  String get historyLost => 'Lost';

  @override
  String get historyDrawn => 'Drawn';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsAgainstAi => 'Against the AI';

  @override
  String get statsAllGames => 'All games';

  @override
  String get statsGamesPlayed => 'Games played';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsLosses => 'Losses';

  @override
  String get statsDraws => 'Draws';

  @override
  String get statsWinRate => 'Win rate';

  @override
  String get statsPiecesCaptured => 'Pieces captured';

  @override
  String get statsSultansCreated => 'Sultans made';

  @override
  String get statsLongestGame => 'Longest game';

  @override
  String get tutorialTitle => 'How to play';

  @override
  String tutorialStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialPrevious => 'Previous';

  @override
  String get tutorialFinish => 'Finish';

  @override
  String get tutorialWellDone => 'Well done!';

  @override
  String get tutorialTryAgain => 'That is not the expected move. Try again.';

  @override
  String get tutorialReset => 'Reset the exercise';

  @override
  String get tutorialBoardTitle => 'The board';

  @override
  String get tutorialBoardBody =>
      'Dhamet is played on the 81 intersections of a 9 × 9 grid of lines, drawn like four alquerque boards. Diagonals only run through every other point, the \"wide\" points. The other, \"narrow\" points have no diagonal.';

  @override
  String get tutorialPiecesTitle => 'The pieces';

  @override
  String get tutorialPiecesBody =>
      'Each side has 40 pieces; only the central intersection is empty at the start. Traditionally one side plays with sticks and the other with camel-dung pellets: here the light pieces carry a stick and the dark ones a ring.';

  @override
  String get tutorialMoveTitle => 'Moving';

  @override
  String get tutorialMoveBody =>
      'A pawn moves one step to an empty intersection, straight or diagonally along a line. It never moves backwards or sideways. Move the white pawn forward.';

  @override
  String get tutorialCaptureTitle => 'Capturing';

  @override
  String get tutorialCaptureBody =>
      'You capture by jumping over a neighbouring enemy piece to the free intersection right behind it, in any direction, even backwards. Capturing is mandatory. Capture the black pawn.';

  @override
  String get tutorialRafleTitle => 'Multiple captures';

  @override
  String get tutorialRafleBody =>
      'If the pawn can capture again after a capture, it goes on: a multiple capture. Captured pieces are removed at once, and you must always play the sequence taking the most pieces. Play the five-piece capture.';

  @override
  String get tutorialPromotionTitle => 'Promotion';

  @override
  String get tutorialPromotionBody =>
      'A pawn that ends its move on the opponent\'s last row becomes a Sultan. Take the pawn to the last row.';

  @override
  String get tutorialSultanTitle => 'The Sultan';

  @override
  String get tutorialSultanBody =>
      'The Sultan moves any number of intersections along a line, forwards or backwards. It captures a piece at a distance if the intersection behind it is free. Capture the black pawn with the Sultan.';

  @override
  String get tutorialVictoryTitle => 'Winning';

  @override
  String get tutorialVictoryBody =>
      'You win by capturing all the opponent\'s pieces, or when the opponent cannot move. Capture the last black piece.';

  @override
  String get tutorialSpecialTitle => 'Special rules';

  @override
  String get tutorialSpecialBody =>
      'When several captures are possible, the longest is mandatory. Traditionally, an incomplete capture sequence can be \"blown\" by the opponent; here the app simply enforces the right move. A few rules still need confirmation and are configurable. Play the longest capture.';

  @override
  String semanticsIntersection(String position) {
    return '$position';
  }

  @override
  String semanticsPiece(String position, String piece) {
    return '$position, $piece';
  }

  @override
  String semanticsTarget(String label) {
    return '$label, possible destination';
  }

  @override
  String get pieceWhitePawn => 'white pawn';

  @override
  String get pieceBlackPawn => 'black pawn';

  @override
  String get pieceWhiteSultan => 'white Sultan';

  @override
  String get pieceBlackSultan => 'black Sultan';
}
