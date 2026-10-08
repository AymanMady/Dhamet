// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dhametna';

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
  String get whiteStarts => 'Laoudane moves first.';

  @override
  String get startGame => 'Start';

  @override
  String get playerWhite => 'Laoudane';

  @override
  String get playerBlack => 'Lebaar';

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
  String get mustCapture => 'Capture is mandatory: play the longest sequence.';

  @override
  String piecesCount(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aouds',
      one: '1 aoud',
      zero: 'no aouds',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baaras',
      one: '1 baara',
      zero: 'no baaras',
    );
    String _temp2 = intl.Intl.selectLogic(side, {
      'white': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String sultansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dhaymas',
      one: '1 Dhayma',
      zero: 'no Dhayma',
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
  String get pause => 'Pause';

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
  String get reasonElimination => 'The opponent has nothing left on the board.';

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
  String get showResult => 'See the result';

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
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyBody =>
      'Dhametna has no ads and no trackers, and asks for no sensitive permission.\n\nOn your device: local games and games against the AI, your history, the game in progress and your settings. They never leave the device.\n\nOnline, only if you play online: the Dhametna server keeps your player name, your password in hashed form (never in plain text) or a guest account, your online games, your rating and your tournaments. This data is only used for the game; it is neither sold nor shared. Connections are encrypted (HTTPS).\n\nUsage statistics, if you turn them on, stay on the device in this version.\n\nYou can delete your account at any time: Play online → Delete my account. Your name and password are erased; your past games stay in your opponents\' history under an anonymous name.';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutBody =>
      'Dhametna brings you Dhamet (ظامت), the traditional draughts game of Mauritania. The rules applied and their sources are documented; some still need to be confirmed with players.';

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
  String get statsPiecesCaptured => 'Captures';

  @override
  String get statsSultansCreated => 'Dhaymas made';

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
  String get tutorialPiecesTitle => 'Laoudane and Lebaar';

  @override
  String get tutorialPiecesBody =>
      'Two sides face each other: Laoudane plays with aouds, small sticks planted in the sand, and Lebaar with baaras, camel-dung pellets. Each side has 40; only the central intersection is empty at the start.';

  @override
  String get tutorialMoveTitle => 'Moving';

  @override
  String get tutorialMoveBody =>
      'An aoud or a baara moves one step to an empty intersection, straight or diagonally along a line. Never backwards, never sideways. Move the aoud forward.';

  @override
  String get tutorialCaptureTitle => 'Capturing';

  @override
  String get tutorialCaptureBody =>
      'You capture by jumping over a neighbouring opponent to the free intersection right behind it, in any direction, even backwards. Capturing is mandatory. Capture the baara.';

  @override
  String get tutorialRafleTitle => 'Multiple captures';

  @override
  String get tutorialRafleBody =>
      'If the aoud can capture again after a capture, it goes on: a multiple capture. Whatever is captured is removed at once, and you must always play the sequence that captures the most. Capture the five baaras in one move.';

  @override
  String get tutorialPromotionTitle => 'Promotion';

  @override
  String get tutorialPromotionBody =>
      'An aoud or a baara that ends its move on the opponent\'s last row becomes a Dhayma. As on the sand, it is doubled: two crossed aouds, or a second, lighter baara set on the first. Take the aoud to the last row.';

  @override
  String get tutorialSultanTitle => 'The Dhayma';

  @override
  String get tutorialSultanBody =>
      'The Dhayma moves any number of intersections along a line, forwards or backwards. It captures from a distance if the intersection behind the opponent is free. Capture the baara with the Dhayma.';

  @override
  String get tutorialVictoryTitle => 'Winning';

  @override
  String get tutorialVictoryBody =>
      'You win when the opponent has nothing left on the board, or cannot move. Capture the last baara.';

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
  String get pieceWhitePawn => 'aoud';

  @override
  String get pieceBlackPawn => 'baara';

  @override
  String get pieceWhiteSultan => 'Laoudane Dhayma';

  @override
  String get pieceBlackSultan => 'Lebaar Dhayma';

  @override
  String get onlineTitle => 'Play online';

  @override
  String get onlineSignInTitle => 'Sign in';

  @override
  String get onlineUsername => 'Username';

  @override
  String get onlinePassword => 'Password';

  @override
  String get onlineUsernameRule => '3 to 20 characters: letters, digits or _';

  @override
  String get onlinePasswordRule => 'At least 8 characters';

  @override
  String get onlineSignIn => 'Sign in';

  @override
  String get onlineRegister => 'Create an account';

  @override
  String get onlineGuest => 'Play as a guest';

  @override
  String get onlineSignOut => 'Sign out';

  @override
  String get onlineDeleteAccount => 'Delete my account';

  @override
  String get onlineDeleteAccountTitle => 'Delete your account?';

  @override
  String get onlineDeleteAccountBody =>
      'Your player name and password will be erased, and you will no longer be able to sign in with this account. A game in progress and your remaining tournament matches will be lost by resignation. Your past games stay in your opponents\' history under an anonymous name. This cannot be undone.';

  @override
  String get onlineDeleteAccountConfirm => 'Delete';

  @override
  String get onlineAccountDeleted => 'Your account has been deleted.';

  @override
  String get onlineGuestBadge => 'Guest';

  @override
  String onlineRating(int rating) {
    return 'Elo rating: $rating';
  }

  @override
  String get onlineConnected => 'Connected';

  @override
  String get onlineConnecting => 'Connecting…';

  @override
  String get onlineReconnecting => 'Connection lost, reconnecting…';

  @override
  String get onlineDisconnected => 'Offline';

  @override
  String get onlineCreateRoom => 'Create a private room';

  @override
  String get onlineJoinRoom => 'Join a room';

  @override
  String get onlineRoomCode => 'Room code';

  @override
  String get onlineJoin => 'Join';

  @override
  String get onlineRated => 'Rated game';

  @override
  String get onlineRatedGuestNote => 'Guests cannot play rated games.';

  @override
  String get onlineTimeControl => 'Clock';

  @override
  String get onlineNoClock => 'No limit, as in tradition';

  @override
  String onlineClock(int minutes, int seconds) {
    return '$minutes min + $seconds s';
  }

  @override
  String onlineRoomTitle(String code) {
    return 'Room $code';
  }

  @override
  String get onlineShareCode => 'Give this code to your opponent.';

  @override
  String get onlineCopy => 'Copy the code';

  @override
  String get onlineCopied => 'Code copied';

  @override
  String get onlineWaitingOpponent => 'Waiting for an opponent…';

  @override
  String get onlineReady => 'I\'m ready';

  @override
  String get onlinePlayerReady => 'Ready';

  @override
  String get onlinePlayerNotReady => 'Not ready yet';

  @override
  String get onlinePlayerAway => 'Disconnected';

  @override
  String get onlineHost => 'Host';

  @override
  String get onlineLeave => 'Leave the room';

  @override
  String get onlineOpponentTurn => 'Opponent\'s turn';

  @override
  String get onlineSending => 'Sending the move…';

  @override
  String onlineOpponentAway(int seconds) {
    return 'Your opponent disconnected: $seconds s to come back.';
  }

  @override
  String onlineRatingChange(String delta) {
    return 'Rating: $delta';
  }

  @override
  String get onlineBackToLobby => 'Back to the lobby';

  @override
  String get onlineErrorNetwork => 'Cannot reach the server.';

  @override
  String get onlineErrorCredentials => 'Wrong username or password.';

  @override
  String get onlineErrorTaken => 'This name is already taken.';

  @override
  String get onlineErrorRoomNotFound => 'Room not found.';

  @override
  String get onlineErrorRoomFull => 'This room is full.';

  @override
  String get onlineErrorMove => 'The server refused the move.';

  @override
  String onlineErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get onlineLeaderboard => 'Leaderboard';

  @override
  String get onlineTournaments => 'Tournaments';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardEmpty => 'No ranked player yet.';

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '$wins W · $losses L · $draws D';
  }

  @override
  String get tournamentsTitle => 'Tournaments';

  @override
  String get tournamentsEmpty => 'No tournament yet.';

  @override
  String get tournamentCreate => 'Create a tournament';

  @override
  String get tournamentName => 'Tournament name';

  @override
  String get tournamentMaxPlayers => 'Maximum number of players';

  @override
  String get tournamentRoundRobin => 'Round robin: everyone meets everyone';

  @override
  String get tournamentJoin => 'Register';

  @override
  String get tournamentStart => 'Start the tournament';

  @override
  String tournamentPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
      zero: 'no players',
    );
    return '$_temp0';
  }

  @override
  String get tournamentStatusRegistering => 'Registration open';

  @override
  String get tournamentStatusRunning => 'In progress';

  @override
  String get tournamentStatusFinished => 'Finished';

  @override
  String tournamentRound(int number) {
    return 'Round $number';
  }

  @override
  String get tournamentStandings => 'Standings';

  @override
  String tournamentPoints(String points) {
    return '$points pts';
  }

  @override
  String get tournamentPlayMatch => 'Play';
}
