// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Dhametna';

  @override
  String get appTagline => 'Jeu traditionnel mauritanien';

  @override
  String get homeNewGame => 'Nouvelle partie';

  @override
  String get homePlayAi => 'Jouer contre l\'IA';

  @override
  String get homePlayFriend => 'Jouer avec un ami';

  @override
  String get homePlayOnline => 'Jouer en ligne';

  @override
  String get homeHowToPlay => 'Comment jouer';

  @override
  String get homeHistory => 'Historique';

  @override
  String get homeSettings => 'Paramètres';

  @override
  String get homeResume => 'Reprendre la partie';

  @override
  String homeResumeDetails(String mode, int moveNumber) {
    return '$mode · coup $moveNumber';
  }

  @override
  String get modeTitle => 'Mode de jeu';

  @override
  String get modeLocal => 'Joueur contre joueur';

  @override
  String get modeLocalDescription => 'À deux sur le même appareil';

  @override
  String get modeAi => 'Joueur contre IA';

  @override
  String get modeAiDescription => 'Affrontez l\'ordinateur';

  @override
  String get aiSetupTitle => 'Contre l\'IA';

  @override
  String get difficultyTitle => 'Difficulté';

  @override
  String get difficultyEasy => 'Facile';

  @override
  String get difficultyMedium => 'Moyen';

  @override
  String get difficultyHard => 'Difficile';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get difficultyEasyDescription => 'Pour découvrir le jeu';

  @override
  String get difficultyMediumDescription => 'Un adversaire honnête';

  @override
  String get difficultyHardDescription => 'Il ne laisse rien passer';

  @override
  String get difficultyExpertDescription => 'Réfléchit longtemps et joue fort';

  @override
  String get sideTitle => 'Votre camp';

  @override
  String get sideRandom => 'Au hasard';

  @override
  String get whiteStarts => 'Les Blancs commencent.';

  @override
  String get startGame => 'Commencer';

  @override
  String get playerWhite => 'Blancs';

  @override
  String get playerBlack => 'Noirs';

  @override
  String get playerYou => 'Vous';

  @override
  String playerAi(String level) {
    return 'IA · $level';
  }

  @override
  String turnOf(String player) {
    return 'Au tour des $player';
  }

  @override
  String get yourTurn => 'À vous de jouer';

  @override
  String get aiThinking => 'L\'IA réfléchit…';

  @override
  String get toMove => 'Au trait';

  @override
  String get mustCapture =>
      'Prise obligatoire : prenez le plus de pièces possible.';

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces',
      one: '1 pièce',
      zero: 'aucune pièce',
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
      zero: 'aucun Sultan',
    );
    return '$_temp0';
  }

  @override
  String lastMoveLabel(String move) {
    return 'Dernier coup : $move';
  }

  @override
  String get chooseCapture =>
      'Plusieurs rafles mènent ici : choisissez-en une.';

  @override
  String captureOption(String notation, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prises',
      one: '1 prise',
    );
    return '$notation · $_temp0';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get undo => 'Annuler le coup';

  @override
  String get redo => 'Rétablir';

  @override
  String get resign => 'Abandonner';

  @override
  String get restart => 'Recommencer';

  @override
  String get pause => 'Pause';

  @override
  String get resignTitle => 'Abandonner la partie ?';

  @override
  String get resignBody => 'La victoire sera donnée à l\'adversaire.';

  @override
  String get restartTitle => 'Recommencer ?';

  @override
  String get restartBody => 'La partie en cours sera abandonnée.';

  @override
  String get resultVictory => 'Victoire';

  @override
  String get resultDefeat => 'Défaite';

  @override
  String get resultDraw => 'Égalité';

  @override
  String resultWinner(String player) {
    return 'Les $player gagnent';
  }

  @override
  String get reasonElimination => 'Toutes les pièces adverses ont été prises.';

  @override
  String get reasonBlocked => 'Le camp adverse ne peut plus jouer.';

  @override
  String get reasonResignation => 'Abandon.';

  @override
  String get reasonTimeout => 'Temps écoulé.';

  @override
  String get reasonRepetition => 'Même position répétée.';

  @override
  String get reasonAgreement => 'Nulle d\'un commun accord.';

  @override
  String movesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coups',
      one: '1 coup',
      zero: 'aucun coup',
    );
    return '$_temp0';
  }

  @override
  String get playAgain => 'Rejouer';

  @override
  String get showResult => 'Voir le résultat';

  @override
  String get backHome => 'Retour à l\'accueil';

  @override
  String get viewGame => 'Voir la partie';

  @override
  String get replayTitle => 'Revoir la partie';

  @override
  String get replayStart => 'Position initiale';

  @override
  String replayPosition(int ply, int total) {
    return 'Coup $ply sur $total';
  }

  @override
  String get replayFirst => 'Début';

  @override
  String get replayPrevious => 'Coup précédent';

  @override
  String get replayNext => 'Coup suivant';

  @override
  String get replayLast => 'Fin';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionGame => 'Jeu';

  @override
  String get settingsSectionDisplay => 'Affichage';

  @override
  String get settingsSectionPrivacy => 'Confidentialité';

  @override
  String get settingsSectionAdvanced => 'Avancé';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue de l\'appareil';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Automatique';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsSound => 'Sons';

  @override
  String get settingsHaptics => 'Vibrations';

  @override
  String get settingsAnimations => 'Animations';

  @override
  String get settingsAnimationsDescription =>
      'Désactivez-les pour des déplacements instantanés.';

  @override
  String get settingsCoordinates => 'Afficher les coordonnées';

  @override
  String get settingsHints => 'Montrer les coups possibles';

  @override
  String get settingsAnalytics => 'Statistiques d\'usage anonymes';

  @override
  String get settingsAnalyticsDescription =>
      'Rien n\'est envoyé sans votre accord.';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicyBody =>
      'Dhametna ne contient ni publicité ni traceur, et ne demande aucune autorisation sensible.\n\nSur votre appareil : les parties locales et contre l\'IA, l\'historique, la partie en cours et vos réglages. Ils ne quittent pas l\'appareil.\n\nEn ligne, seulement si vous jouez en ligne : le serveur de Dhametna conserve votre nom de joueur, votre mot de passe sous forme hachée (jamais en clair) ou un compte invité, vos parties en ligne, votre classement et vos tournois. Ces données servent uniquement au jeu ; elles ne sont ni vendues ni partagées. Les échanges sont chiffrés (HTTPS).\n\nLes statistiques d\'usage, si vous les activez, restent sur l\'appareil dans cette version.\n\nVous pouvez supprimer votre compte à tout moment : Jouer en ligne → Supprimer mon compte. Votre nom et votre mot de passe sont effacés ; vos parties passées restent dans l\'historique de vos adversaires sous un nom anonyme.';

  @override
  String get settingsDeveloper => 'Mode développeur';

  @override
  String get settingsDeveloperDescription =>
      'Coordonnées, coups légaux, état de la partie, temps de l\'IA.';

  @override
  String get settingsPerformanceOverlay => 'Afficher les performances (FPS)';

  @override
  String get settingsServerUrl => 'Adresse du serveur';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get aboutBody =>
      'Dhametna fait vivre le Dhamet (ظامت), le jeu de dames traditionnel de Mauritanie. Les règles appliquées et leurs sources sont documentées ; certaines restent à confirmer auprès des joueurs.';

  @override
  String get devPanelTitle => 'Développeur';

  @override
  String devLegalMoves(int count) {
    return 'Coups légaux ($count)';
  }

  @override
  String devAiTime(int milliseconds) {
    return 'Temps de l\'IA : $milliseconds ms';
  }

  @override
  String devPly(int ply) {
    return 'Demi-coups joués : $ply';
  }

  @override
  String get devState => 'État de la partie (JSON)';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyEmpty => 'Aucune partie terminée pour l\'instant.';

  @override
  String historyAgainstAi(String level) {
    return 'Contre l\'IA · $level';
  }

  @override
  String get historyLocal => 'À deux';

  @override
  String get historyDelete => 'Supprimer';

  @override
  String get historyWon => 'Gagnée';

  @override
  String get historyLost => 'Perdue';

  @override
  String get historyDrawn => 'Nulle';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsAgainstAi => 'Contre l\'IA';

  @override
  String get statsAllGames => 'Toutes les parties';

  @override
  String get statsGamesPlayed => 'Parties jouées';

  @override
  String get statsWins => 'Victoires';

  @override
  String get statsLosses => 'Défaites';

  @override
  String get statsDraws => 'Égalités';

  @override
  String get statsWinRate => 'Taux de victoire';

  @override
  String get statsPiecesCaptured => 'Pièces prises';

  @override
  String get statsSultansCreated => 'Sultans obtenus';

  @override
  String get statsLongestGame => 'Plus longue partie';

  @override
  String get tutorialTitle => 'Comment jouer';

  @override
  String tutorialStep(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get tutorialNext => 'Suivant';

  @override
  String get tutorialPrevious => 'Précédent';

  @override
  String get tutorialFinish => 'Terminer';

  @override
  String get tutorialWellDone => 'Bravo !';

  @override
  String get tutorialTryAgain => 'Ce n\'est pas le coup attendu. Réessayez.';

  @override
  String get tutorialReset => 'Recommencer l\'exercice';

  @override
  String get tutorialBoardTitle => 'Le plateau';

  @override
  String get tutorialBoardBody =>
      'Le Dhamet se joue sur les 81 intersections d\'une grille de 9 × 9 lignes, tracée comme quatre plateaux d\'alquerque. Les diagonales ne passent que par un point sur deux, les points « vastes ». Les autres points, « étroits », n\'ont pas de diagonale.';

  @override
  String get tutorialPiecesTitle => 'Les pièces';

  @override
  String get tutorialPiecesBody =>
      'Chaque camp a 40 pièces ; seule l\'intersection centrale est vide au départ. Traditionnellement, un camp joue avec des bâtonnets et l\'autre avec des crottes de chameau : ici, les Blancs sont des bâtonnets plantés dans le sable et les Noirs des cailloux.';

  @override
  String get tutorialMoveTitle => 'Le déplacement';

  @override
  String get tutorialMoveBody =>
      'Un pion avance d\'un pas vers une intersection vide, tout droit ou en diagonale en suivant une ligne. Il ne recule jamais et ne se déplace pas sur le côté. Avancez le pion blanc.';

  @override
  String get tutorialCaptureTitle => 'La prise';

  @override
  String get tutorialCaptureBody =>
      'On prend en sautant par-dessus une pièce adverse voisine, vers l\'intersection libre juste derrière, dans toutes les directions, même en arrière. Prendre est obligatoire. Prenez le pion noir.';

  @override
  String get tutorialRafleTitle => 'La rafle';

  @override
  String get tutorialRafleBody =>
      'Si le pion peut encore prendre après une prise, il continue : c\'est une rafle. Les pièces prises sont retirées aussitôt, et il faut toujours jouer la rafle qui prend le plus de pièces. Réalisez la rafle de cinq pièces.';

  @override
  String get tutorialPromotionTitle => 'La promotion';

  @override
  String get tutorialPromotionBody =>
      'Un pion qui termine son coup sur la dernière rangée adverse devient Sultan. Comme sur le sable, on lui ajoute une seconde pièce : deux bâtonnets croisés, ou un caillou clair posé sur le sombre. Menez le pion jusqu\'à la dernière rangée.';

  @override
  String get tutorialSultanTitle => 'Le Sultan';

  @override
  String get tutorialSultanBody =>
      'Le Sultan se déplace d\'autant d\'intersections qu\'il veut le long d\'une ligne, en avant comme en arrière. Il prend une pièce à distance si l\'intersection derrière elle est libre. Prenez le pion noir avec le Sultan.';

  @override
  String get tutorialVictoryTitle => 'La victoire';

  @override
  String get tutorialVictoryBody =>
      'On gagne en prenant toutes les pièces adverses, ou quand l\'adversaire ne peut plus jouer. Prenez la dernière pièce noire.';

  @override
  String get tutorialSpecialTitle => 'Règles particulières';

  @override
  String get tutorialSpecialBody =>
      'Quand plusieurs prises sont possibles, la plus longue est obligatoire. Dans la tradition, une rafle incomplète peut être « soufflée » par l\'adversaire ; ici, l\'application impose directement le bon coup. Quelques règles restent à confirmer et sont réglables. Jouez la prise la plus longue.';

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
    return '$label, destination possible';
  }

  @override
  String get pieceWhitePawn => 'pion blanc';

  @override
  String get pieceBlackPawn => 'pion noir';

  @override
  String get pieceWhiteSultan => 'Sultan blanc';

  @override
  String get pieceBlackSultan => 'Sultan noir';

  @override
  String get onlineTitle => 'Jouer en ligne';

  @override
  String get onlineSignInTitle => 'Connexion';

  @override
  String get onlineUsername => 'Nom d\'utilisateur';

  @override
  String get onlinePassword => 'Mot de passe';

  @override
  String get onlineUsernameRule => '3 à 20 caractères : lettres, chiffres ou _';

  @override
  String get onlinePasswordRule => 'Au moins 8 caractères';

  @override
  String get onlineSignIn => 'Se connecter';

  @override
  String get onlineRegister => 'Créer un compte';

  @override
  String get onlineGuest => 'Jouer en invité';

  @override
  String get onlineSignOut => 'Se déconnecter';

  @override
  String get onlineDeleteAccount => 'Supprimer mon compte';

  @override
  String get onlineDeleteAccountTitle => 'Supprimer votre compte ?';

  @override
  String get onlineDeleteAccountBody =>
      'Votre nom de joueur et votre mot de passe seront effacés, et vous ne pourrez plus vous connecter avec ce compte. Une partie en cours et vos matchs de tournoi restants seront perdus par abandon. Vos parties passées restent dans l\'historique de vos adversaires sous un nom anonyme. Cette action est définitive.';

  @override
  String get onlineDeleteAccountConfirm => 'Supprimer';

  @override
  String get onlineAccountDeleted => 'Votre compte a été supprimé.';

  @override
  String get onlineGuestBadge => 'Invité';

  @override
  String onlineRating(int rating) {
    return 'Classement Elo : $rating';
  }

  @override
  String get onlineConnected => 'Connecté';

  @override
  String get onlineConnecting => 'Connexion…';

  @override
  String get onlineReconnecting => 'Connexion perdue, reconnexion…';

  @override
  String get onlineDisconnected => 'Hors ligne';

  @override
  String get onlineCreateRoom => 'Créer une salle privée';

  @override
  String get onlineJoinRoom => 'Rejoindre une salle';

  @override
  String get onlineRoomCode => 'Code de la salle';

  @override
  String get onlineJoin => 'Rejoindre';

  @override
  String get onlineRated => 'Partie classée';

  @override
  String get onlineRatedGuestNote =>
      'Les invités ne jouent pas de parties classées.';

  @override
  String get onlineTimeControl => 'Pendule';

  @override
  String get onlineNoClock => 'Sans limite, comme le veut la tradition';

  @override
  String onlineClock(int minutes, int seconds) {
    return '$minutes min + $seconds s';
  }

  @override
  String onlineRoomTitle(String code) {
    return 'Salle $code';
  }

  @override
  String get onlineShareCode => 'Donnez ce code à votre adversaire.';

  @override
  String get onlineCopy => 'Copier le code';

  @override
  String get onlineCopied => 'Code copié';

  @override
  String get onlineWaitingOpponent => 'En attente d\'un adversaire…';

  @override
  String get onlineReady => 'Je suis prêt';

  @override
  String get onlinePlayerReady => 'Prêt';

  @override
  String get onlinePlayerNotReady => 'Pas encore prêt';

  @override
  String get onlinePlayerAway => 'Déconnecté';

  @override
  String get onlineHost => 'Hôte';

  @override
  String get onlineLeave => 'Quitter la salle';

  @override
  String get onlineOpponentTurn => 'Au tour de l\'adversaire';

  @override
  String get onlineSending => 'Envoi du coup…';

  @override
  String onlineOpponentAway(int seconds) {
    return 'L\'adversaire s\'est déconnecté : il a $seconds s pour revenir.';
  }

  @override
  String onlineRatingChange(String delta) {
    return 'Classement : $delta';
  }

  @override
  String get onlineBackToLobby => 'Retour au salon';

  @override
  String get onlineErrorNetwork => 'Impossible de joindre le serveur.';

  @override
  String get onlineErrorCredentials =>
      'Nom d\'utilisateur ou mot de passe incorrect.';

  @override
  String get onlineErrorTaken => 'Ce nom est déjà pris.';

  @override
  String get onlineErrorRoomNotFound => 'Salle introuvable.';

  @override
  String get onlineErrorRoomFull => 'Cette salle est complète.';

  @override
  String get onlineErrorMove => 'Coup refusé par le serveur.';

  @override
  String onlineErrorGeneric(String message) {
    return 'Erreur : $message';
  }

  @override
  String get onlineLeaderboard => 'Classement';

  @override
  String get onlineTournaments => 'Tournois';

  @override
  String get leaderboardTitle => 'Classement';

  @override
  String get leaderboardEmpty => 'Aucun joueur classé pour l\'instant.';

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '$wins V · $losses D · $draws N';
  }

  @override
  String get tournamentsTitle => 'Tournois';

  @override
  String get tournamentsEmpty => 'Aucun tournoi pour l\'instant.';

  @override
  String get tournamentCreate => 'Créer un tournoi';

  @override
  String get tournamentName => 'Nom du tournoi';

  @override
  String get tournamentMaxPlayers => 'Nombre maximum de joueurs';

  @override
  String get tournamentRoundRobin => 'Toutes rondes : chacun rencontre chacun';

  @override
  String get tournamentJoin => 'S\'inscrire';

  @override
  String get tournamentStart => 'Lancer le tournoi';

  @override
  String tournamentPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs',
      one: '1 joueur',
      zero: 'aucun joueur',
    );
    return '$_temp0';
  }

  @override
  String get tournamentStatusRegistering => 'Inscriptions ouvertes';

  @override
  String get tournamentStatusRunning => 'En cours';

  @override
  String get tournamentStatusFinished => 'Terminé';

  @override
  String tournamentRound(int number) {
    return 'Ronde $number';
  }

  @override
  String get tournamentStandings => 'Classement du tournoi';

  @override
  String tournamentPoints(String points) {
    return '$points pts';
  }

  @override
  String get tournamentPlayMatch => 'Jouer';
}
