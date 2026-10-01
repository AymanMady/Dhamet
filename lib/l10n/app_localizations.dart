import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ar', 'MR'),
    Locale('en'),
    Locale('fr'),
  ];

  /// Name of the app in the current script (lib/app/brand.dart): Dhametna, or ظامتنا in Arabic.
  ///
  /// In fr, this message translates to:
  /// **'Dhametna'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Jeu traditionnel mauritanien'**
  String get appTagline;

  /// No description provided for @homeNewGame.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle partie'**
  String get homeNewGame;

  /// No description provided for @homePlayAi.
  ///
  /// In fr, this message translates to:
  /// **'Jouer contre l\'IA'**
  String get homePlayAi;

  /// No description provided for @homePlayFriend.
  ///
  /// In fr, this message translates to:
  /// **'Jouer avec un ami'**
  String get homePlayFriend;

  /// No description provided for @homePlayOnline.
  ///
  /// In fr, this message translates to:
  /// **'Jouer en ligne'**
  String get homePlayOnline;

  /// No description provided for @homeHowToPlay.
  ///
  /// In fr, this message translates to:
  /// **'Comment jouer'**
  String get homeHowToPlay;

  /// No description provided for @homeHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get homeHistory;

  /// No description provided for @homeSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get homeSettings;

  /// No description provided for @homeResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la partie'**
  String get homeResume;

  /// No description provided for @homeResumeDetails.
  ///
  /// In fr, this message translates to:
  /// **'{mode} · coup {moveNumber}'**
  String homeResumeDetails(String mode, int moveNumber);

  /// No description provided for @modeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode de jeu'**
  String get modeTitle;

  /// No description provided for @modeLocal.
  ///
  /// In fr, this message translates to:
  /// **'Joueur contre joueur'**
  String get modeLocal;

  /// No description provided for @modeLocalDescription.
  ///
  /// In fr, this message translates to:
  /// **'À deux sur le même appareil'**
  String get modeLocalDescription;

  /// No description provided for @modeAi.
  ///
  /// In fr, this message translates to:
  /// **'Joueur contre IA'**
  String get modeAi;

  /// No description provided for @modeAiDescription.
  ///
  /// In fr, this message translates to:
  /// **'Affrontez l\'ordinateur'**
  String get modeAiDescription;

  /// No description provided for @aiSetupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contre l\'IA'**
  String get aiSetupTitle;

  /// No description provided for @difficultyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté'**
  String get difficultyTitle;

  /// No description provided for @difficultyEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// No description provided for @difficultyEasyDescription.
  ///
  /// In fr, this message translates to:
  /// **'Pour découvrir le jeu'**
  String get difficultyEasyDescription;

  /// No description provided for @difficultyMediumDescription.
  ///
  /// In fr, this message translates to:
  /// **'Un adversaire honnête'**
  String get difficultyMediumDescription;

  /// No description provided for @difficultyHardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Il ne laisse rien passer'**
  String get difficultyHardDescription;

  /// No description provided for @difficultyExpertDescription.
  ///
  /// In fr, this message translates to:
  /// **'Réfléchit longtemps et joue fort'**
  String get difficultyExpertDescription;

  /// No description provided for @sideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre camp'**
  String get sideTitle;

  /// No description provided for @sideRandom.
  ///
  /// In fr, this message translates to:
  /// **'Au hasard'**
  String get sideRandom;

  /// No description provided for @whiteStarts.
  ///
  /// In fr, this message translates to:
  /// **'Les Blancs commencent.'**
  String get whiteStarts;

  /// No description provided for @startGame.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get startGame;

  /// No description provided for @playerWhite.
  ///
  /// In fr, this message translates to:
  /// **'Blancs'**
  String get playerWhite;

  /// No description provided for @playerBlack.
  ///
  /// In fr, this message translates to:
  /// **'Noirs'**
  String get playerBlack;

  /// No description provided for @playerYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get playerYou;

  /// No description provided for @playerAi.
  ///
  /// In fr, this message translates to:
  /// **'IA · {level}'**
  String playerAi(String level);

  /// No description provided for @turnOf.
  ///
  /// In fr, this message translates to:
  /// **'Au tour des {player}'**
  String turnOf(String player);

  /// No description provided for @yourTurn.
  ///
  /// In fr, this message translates to:
  /// **'À vous de jouer'**
  String get yourTurn;

  /// No description provided for @aiThinking.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA réfléchit…'**
  String get aiThinking;

  /// No description provided for @toMove.
  ///
  /// In fr, this message translates to:
  /// **'Au trait'**
  String get toMove;

  /// No description provided for @mustCapture.
  ///
  /// In fr, this message translates to:
  /// **'Prise obligatoire : prenez le plus de pièces possible.'**
  String get mustCapture;

  /// No description provided for @piecesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucune pièce} =1{1 pièce} other{{count} pièces}}'**
  String piecesCount(int count);

  /// No description provided for @sultansCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun Sultan} =1{1 Sultan} other{{count} Sultans}}'**
  String sultansCount(int count);

  /// No description provided for @lastMoveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dernier coup : {move}'**
  String lastMoveLabel(String move);

  /// No description provided for @chooseCapture.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs rafles mènent ici : choisissez-en une.'**
  String get chooseCapture;

  /// No description provided for @captureOption.
  ///
  /// In fr, this message translates to:
  /// **'{notation} · {count, plural, =1{1 prise} other{{count} prises}}'**
  String captureOption(String notation, int count);

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le coup'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get redo;

  /// No description provided for @resign.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get resign;

  /// No description provided for @restart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get restart;

  /// Bouton et titre du menu de pause pendant une partie
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resignTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner la partie ?'**
  String get resignTitle;

  /// No description provided for @resignBody.
  ///
  /// In fr, this message translates to:
  /// **'La victoire sera donnée à l\'adversaire.'**
  String get resignBody;

  /// No description provided for @restartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer ?'**
  String get restartTitle;

  /// No description provided for @restartBody.
  ///
  /// In fr, this message translates to:
  /// **'La partie en cours sera abandonnée.'**
  String get restartBody;

  /// No description provided for @resultVictory.
  ///
  /// In fr, this message translates to:
  /// **'Victoire'**
  String get resultVictory;

  /// No description provided for @resultDefeat.
  ///
  /// In fr, this message translates to:
  /// **'Défaite'**
  String get resultDefeat;

  /// No description provided for @resultDraw.
  ///
  /// In fr, this message translates to:
  /// **'Égalité'**
  String get resultDraw;

  /// No description provided for @resultWinner.
  ///
  /// In fr, this message translates to:
  /// **'Les {player} gagnent'**
  String resultWinner(String player);

  /// No description provided for @reasonElimination.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les pièces adverses ont été prises.'**
  String get reasonElimination;

  /// No description provided for @reasonBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Le camp adverse ne peut plus jouer.'**
  String get reasonBlocked;

  /// No description provided for @reasonResignation.
  ///
  /// In fr, this message translates to:
  /// **'Abandon.'**
  String get reasonResignation;

  /// No description provided for @reasonTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé.'**
  String get reasonTimeout;

  /// No description provided for @reasonRepetition.
  ///
  /// In fr, this message translates to:
  /// **'Même position répétée.'**
  String get reasonRepetition;

  /// No description provided for @reasonAgreement.
  ///
  /// In fr, this message translates to:
  /// **'Nulle d\'un commun accord.'**
  String get reasonAgreement;

  /// No description provided for @movesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun coup} =1{1 coup} other{{count} coups}}'**
  String movesCount(int count);

  /// No description provided for @playAgain.
  ///
  /// In fr, this message translates to:
  /// **'Rejouer'**
  String get playAgain;

  /// No description provided for @showResult.
  ///
  /// In fr, this message translates to:
  /// **'Voir le résultat'**
  String get showResult;

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backHome;

  /// No description provided for @viewGame.
  ///
  /// In fr, this message translates to:
  /// **'Voir la partie'**
  String get viewGame;

  /// No description provided for @replayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Revoir la partie'**
  String get replayTitle;

  /// No description provided for @replayStart.
  ///
  /// In fr, this message translates to:
  /// **'Position initiale'**
  String get replayStart;

  /// No description provided for @replayPosition.
  ///
  /// In fr, this message translates to:
  /// **'Coup {ply} sur {total}'**
  String replayPosition(int ply, int total);

  /// No description provided for @replayFirst.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get replayFirst;

  /// No description provided for @replayPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Coup précédent'**
  String get replayPrevious;

  /// No description provided for @replayNext.
  ///
  /// In fr, this message translates to:
  /// **'Coup suivant'**
  String get replayNext;

  /// No description provided for @replayLast.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get replayLast;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGame.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get settingsSectionGame;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Affichage'**
  String get settingsSectionDisplay;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsSectionAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get settingsSectionAdvanced;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'appareil'**
  String get languageSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @settingsSound.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settingsSound;

  /// No description provided for @settingsHaptics.
  ///
  /// In fr, this message translates to:
  /// **'Vibrations'**
  String get settingsHaptics;

  /// No description provided for @settingsAnimations.
  ///
  /// In fr, this message translates to:
  /// **'Animations'**
  String get settingsAnimations;

  /// No description provided for @settingsAnimationsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Désactivez-les pour des déplacements instantanés.'**
  String get settingsAnimationsDescription;

  /// No description provided for @settingsCoordinates.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les coordonnées'**
  String get settingsCoordinates;

  /// No description provided for @settingsHints.
  ///
  /// In fr, this message translates to:
  /// **'Montrer les coups possibles'**
  String get settingsHints;

  /// No description provided for @settingsAnalytics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques d\'usage anonymes'**
  String get settingsAnalytics;

  /// No description provided for @settingsAnalyticsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est envoyé sans votre accord.'**
  String get settingsAnalyticsDescription;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get settingsPrivacyPolicy;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In fr, this message translates to:
  /// **'Dhametna ne contient ni publicité ni traceur, et ne demande aucune autorisation sensible.\n\nSur votre appareil : les parties locales et contre l\'IA, l\'historique, la partie en cours et vos réglages. Ils ne quittent pas l\'appareil.\n\nEn ligne, seulement si vous jouez en ligne : le serveur de Dhametna conserve votre nom de joueur, votre mot de passe sous forme hachée (jamais en clair) ou un compte invité, vos parties en ligne, votre classement et vos tournois. Ces données servent uniquement au jeu ; elles ne sont ni vendues ni partagées. Les échanges sont chiffrés (HTTPS).\n\nLes statistiques d\'usage, si vous les activez, restent sur l\'appareil dans cette version.\n\nVous pouvez supprimer votre compte à tout moment : Jouer en ligne → Supprimer mon compte. Votre nom et votre mot de passe sont effacés ; vos parties passées restent dans l\'historique de vos adversaires sous un nom anonyme.'**
  String get privacyPolicyBody;

  /// No description provided for @settingsDeveloper.
  ///
  /// In fr, this message translates to:
  /// **'Mode développeur'**
  String get settingsDeveloper;

  /// No description provided for @settingsDeveloperDescription.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées, coups légaux, état de la partie, temps de l\'IA.'**
  String get settingsDeveloperDescription;

  /// No description provided for @settingsPerformanceOverlay.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les performances (FPS)'**
  String get settingsPerformanceOverlay;

  /// No description provided for @settingsServerUrl.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du serveur'**
  String get settingsServerUrl;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @aboutBody.
  ///
  /// In fr, this message translates to:
  /// **'Dhametna fait vivre le Dhamet (ظامت), le jeu de dames traditionnel de Mauritanie. Les règles appliquées et leurs sources sont documentées ; certaines restent à confirmer auprès des joueurs.'**
  String get aboutBody;

  /// No description provided for @devPanelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Développeur'**
  String get devPanelTitle;

  /// No description provided for @devLegalMoves.
  ///
  /// In fr, this message translates to:
  /// **'Coups légaux ({count})'**
  String devLegalMoves(int count);

  /// No description provided for @devAiTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps de l\'IA : {milliseconds} ms'**
  String devAiTime(int milliseconds);

  /// No description provided for @devPly.
  ///
  /// In fr, this message translates to:
  /// **'Demi-coups joués : {ply}'**
  String devPly(int ply);

  /// No description provided for @devState.
  ///
  /// In fr, this message translates to:
  /// **'État de la partie (JSON)'**
  String get devState;

  /// No description provided for @historyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie terminée pour l\'instant.'**
  String get historyEmpty;

  /// No description provided for @historyAgainstAi.
  ///
  /// In fr, this message translates to:
  /// **'Contre l\'IA · {level}'**
  String historyAgainstAi(String level);

  /// No description provided for @historyLocal.
  ///
  /// In fr, this message translates to:
  /// **'À deux'**
  String get historyLocal;

  /// No description provided for @historyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get historyDelete;

  /// No description provided for @historyWon.
  ///
  /// In fr, this message translates to:
  /// **'Gagnée'**
  String get historyWon;

  /// No description provided for @historyLost.
  ///
  /// In fr, this message translates to:
  /// **'Perdue'**
  String get historyLost;

  /// No description provided for @historyDrawn.
  ///
  /// In fr, this message translates to:
  /// **'Nulle'**
  String get historyDrawn;

  /// No description provided for @statsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statsTitle;

  /// No description provided for @statsAgainstAi.
  ///
  /// In fr, this message translates to:
  /// **'Contre l\'IA'**
  String get statsAgainstAi;

  /// No description provided for @statsAllGames.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les parties'**
  String get statsAllGames;

  /// No description provided for @statsGamesPlayed.
  ///
  /// In fr, this message translates to:
  /// **'Parties jouées'**
  String get statsGamesPlayed;

  /// No description provided for @statsWins.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get statsWins;

  /// No description provided for @statsLosses.
  ///
  /// In fr, this message translates to:
  /// **'Défaites'**
  String get statsLosses;

  /// No description provided for @statsDraws.
  ///
  /// In fr, this message translates to:
  /// **'Égalités'**
  String get statsDraws;

  /// No description provided for @statsWinRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de victoire'**
  String get statsWinRate;

  /// No description provided for @statsPiecesCaptured.
  ///
  /// In fr, this message translates to:
  /// **'Pièces prises'**
  String get statsPiecesCaptured;

  /// No description provided for @statsSultansCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sultans obtenus'**
  String get statsSultansCreated;

  /// No description provided for @statsLongestGame.
  ///
  /// In fr, this message translates to:
  /// **'Plus longue partie'**
  String get statsLongestGame;

  /// No description provided for @tutorialTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment jouer'**
  String get tutorialTitle;

  /// No description provided for @tutorialStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} sur {total}'**
  String tutorialStep(int step, int total);

  /// No description provided for @tutorialNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get tutorialNext;

  /// No description provided for @tutorialPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get tutorialPrevious;

  /// No description provided for @tutorialFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get tutorialFinish;

  /// No description provided for @tutorialWellDone.
  ///
  /// In fr, this message translates to:
  /// **'Bravo !'**
  String get tutorialWellDone;

  /// No description provided for @tutorialTryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas le coup attendu. Réessayez.'**
  String get tutorialTryAgain;

  /// No description provided for @tutorialReset.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer l\'exercice'**
  String get tutorialReset;

  /// No description provided for @tutorialBoardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le plateau'**
  String get tutorialBoardTitle;

  /// No description provided for @tutorialBoardBody.
  ///
  /// In fr, this message translates to:
  /// **'Le Dhamet se joue sur les 81 intersections d\'une grille de 9 × 9 lignes, tracée comme quatre plateaux d\'alquerque. Les diagonales ne passent que par un point sur deux, les points « vastes ». Les autres points, « étroits », n\'ont pas de diagonale.'**
  String get tutorialBoardBody;

  /// No description provided for @tutorialPiecesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les pièces'**
  String get tutorialPiecesTitle;

  /// No description provided for @tutorialPiecesBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque camp a 40 pièces ; seule l\'intersection centrale est vide au départ. Traditionnellement, un camp joue avec des bâtonnets et l\'autre avec des crottes de chameau : ici, les Blancs sont des bâtonnets plantés dans le sable et les Noirs des cailloux.'**
  String get tutorialPiecesBody;

  /// No description provided for @tutorialMoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le déplacement'**
  String get tutorialMoveTitle;

  /// No description provided for @tutorialMoveBody.
  ///
  /// In fr, this message translates to:
  /// **'Un pion avance d\'un pas vers une intersection vide, tout droit ou en diagonale en suivant une ligne. Il ne recule jamais et ne se déplace pas sur le côté. Avancez le pion blanc.'**
  String get tutorialMoveBody;

  /// No description provided for @tutorialCaptureTitle.
  ///
  /// In fr, this message translates to:
  /// **'La prise'**
  String get tutorialCaptureTitle;

  /// No description provided for @tutorialCaptureBody.
  ///
  /// In fr, this message translates to:
  /// **'On prend en sautant par-dessus une pièce adverse voisine, vers l\'intersection libre juste derrière, dans toutes les directions, même en arrière. Prendre est obligatoire. Prenez le pion noir.'**
  String get tutorialCaptureBody;

  /// No description provided for @tutorialRafleTitle.
  ///
  /// In fr, this message translates to:
  /// **'La rafle'**
  String get tutorialRafleTitle;

  /// No description provided for @tutorialRafleBody.
  ///
  /// In fr, this message translates to:
  /// **'Si le pion peut encore prendre après une prise, il continue : c\'est une rafle. Les pièces prises sont retirées aussitôt, et il faut toujours jouer la rafle qui prend le plus de pièces. Réalisez la rafle de cinq pièces.'**
  String get tutorialRafleBody;

  /// No description provided for @tutorialPromotionTitle.
  ///
  /// In fr, this message translates to:
  /// **'La promotion'**
  String get tutorialPromotionTitle;

  /// No description provided for @tutorialPromotionBody.
  ///
  /// In fr, this message translates to:
  /// **'Un pion qui termine son coup sur la dernière rangée adverse devient Sultan. Comme sur le sable, on lui ajoute une seconde pièce : deux bâtonnets croisés, ou un caillou clair posé sur le sombre. Menez le pion jusqu\'à la dernière rangée.'**
  String get tutorialPromotionBody;

  /// No description provided for @tutorialSultanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Sultan'**
  String get tutorialSultanTitle;

  /// No description provided for @tutorialSultanBody.
  ///
  /// In fr, this message translates to:
  /// **'Le Sultan se déplace d\'autant d\'intersections qu\'il veut le long d\'une ligne, en avant comme en arrière. Il prend une pièce à distance si l\'intersection derrière elle est libre. Prenez le pion noir avec le Sultan.'**
  String get tutorialSultanBody;

  /// No description provided for @tutorialVictoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'La victoire'**
  String get tutorialVictoryTitle;

  /// No description provided for @tutorialVictoryBody.
  ///
  /// In fr, this message translates to:
  /// **'On gagne en prenant toutes les pièces adverses, ou quand l\'adversaire ne peut plus jouer. Prenez la dernière pièce noire.'**
  String get tutorialVictoryBody;

  /// No description provided for @tutorialSpecialTitle.
  ///
  /// In fr, this message translates to:
  /// **'Règles particulières'**
  String get tutorialSpecialTitle;

  /// No description provided for @tutorialSpecialBody.
  ///
  /// In fr, this message translates to:
  /// **'Quand plusieurs prises sont possibles, la plus longue est obligatoire. Dans la tradition, une rafle incomplète peut être « soufflée » par l\'adversaire ; ici, l\'application impose directement le bon coup. Quelques règles restent à confirmer et sont réglables. Jouez la prise la plus longue.'**
  String get tutorialSpecialBody;

  /// No description provided for @semanticsIntersection.
  ///
  /// In fr, this message translates to:
  /// **'{position}'**
  String semanticsIntersection(String position);

  /// No description provided for @semanticsPiece.
  ///
  /// In fr, this message translates to:
  /// **'{position}, {piece}'**
  String semanticsPiece(String position, String piece);

  /// No description provided for @semanticsTarget.
  ///
  /// In fr, this message translates to:
  /// **'{label}, destination possible'**
  String semanticsTarget(String label);

  /// No description provided for @pieceWhitePawn.
  ///
  /// In fr, this message translates to:
  /// **'pion blanc'**
  String get pieceWhitePawn;

  /// No description provided for @pieceBlackPawn.
  ///
  /// In fr, this message translates to:
  /// **'pion noir'**
  String get pieceBlackPawn;

  /// No description provided for @pieceWhiteSultan.
  ///
  /// In fr, this message translates to:
  /// **'Sultan blanc'**
  String get pieceWhiteSultan;

  /// No description provided for @pieceBlackSultan.
  ///
  /// In fr, this message translates to:
  /// **'Sultan noir'**
  String get pieceBlackSultan;

  /// No description provided for @onlineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jouer en ligne'**
  String get onlineTitle;

  /// No description provided for @onlineSignInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get onlineSignInTitle;

  /// No description provided for @onlineUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get onlineUsername;

  /// No description provided for @onlinePassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get onlinePassword;

  /// No description provided for @onlineUsernameRule.
  ///
  /// In fr, this message translates to:
  /// **'3 à 20 caractères : lettres, chiffres ou _'**
  String get onlineUsernameRule;

  /// No description provided for @onlinePasswordRule.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get onlinePasswordRule;

  /// No description provided for @onlineSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get onlineSignIn;

  /// No description provided for @onlineRegister.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get onlineRegister;

  /// No description provided for @onlineGuest.
  ///
  /// In fr, this message translates to:
  /// **'Jouer en invité'**
  String get onlineGuest;

  /// No description provided for @onlineSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get onlineSignOut;

  /// No description provided for @onlineGuestBadge.
  ///
  /// In fr, this message translates to:
  /// **'Invité'**
  String get onlineGuestBadge;

  /// No description provided for @onlineRating.
  ///
  /// In fr, this message translates to:
  /// **'Classement Elo : {rating}'**
  String onlineRating(int rating);

  /// No description provided for @onlineConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get onlineConnected;

  /// No description provided for @onlineConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion…'**
  String get onlineConnecting;

  /// No description provided for @onlineReconnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion perdue, reconnexion…'**
  String get onlineReconnecting;

  /// No description provided for @onlineDisconnected.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get onlineDisconnected;

  /// No description provided for @onlineCreateRoom.
  ///
  /// In fr, this message translates to:
  /// **'Créer une salle privée'**
  String get onlineCreateRoom;

  /// No description provided for @onlineJoinRoom.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre une salle'**
  String get onlineJoinRoom;

  /// No description provided for @onlineRoomCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de la salle'**
  String get onlineRoomCode;

  /// No description provided for @onlineJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get onlineJoin;

  /// No description provided for @onlineRated.
  ///
  /// In fr, this message translates to:
  /// **'Partie classée'**
  String get onlineRated;

  /// No description provided for @onlineRatedGuestNote.
  ///
  /// In fr, this message translates to:
  /// **'Les invités ne jouent pas de parties classées.'**
  String get onlineRatedGuestNote;

  /// No description provided for @onlineTimeControl.
  ///
  /// In fr, this message translates to:
  /// **'Pendule'**
  String get onlineTimeControl;

  /// No description provided for @onlineNoClock.
  ///
  /// In fr, this message translates to:
  /// **'Sans limite, comme le veut la tradition'**
  String get onlineNoClock;

  /// No description provided for @onlineClock.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min + {seconds} s'**
  String onlineClock(int minutes, int seconds);

  /// No description provided for @onlineRoomTitle.
  ///
  /// In fr, this message translates to:
  /// **'Salle {code}'**
  String onlineRoomTitle(String code);

  /// No description provided for @onlineShareCode.
  ///
  /// In fr, this message translates to:
  /// **'Donnez ce code à votre adversaire.'**
  String get onlineShareCode;

  /// No description provided for @onlineCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get onlineCopy;

  /// No description provided for @onlineCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get onlineCopied;

  /// No description provided for @onlineWaitingOpponent.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'un adversaire…'**
  String get onlineWaitingOpponent;

  /// No description provided for @onlineReady.
  ///
  /// In fr, this message translates to:
  /// **'Je suis prêt'**
  String get onlineReady;

  /// No description provided for @onlinePlayerReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get onlinePlayerReady;

  /// No description provided for @onlinePlayerNotReady.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore prêt'**
  String get onlinePlayerNotReady;

  /// No description provided for @onlinePlayerAway.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecté'**
  String get onlinePlayerAway;

  /// No description provided for @onlineHost.
  ///
  /// In fr, this message translates to:
  /// **'Hôte'**
  String get onlineHost;

  /// No description provided for @onlineLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la salle'**
  String get onlineLeave;

  /// No description provided for @onlineOpponentTurn.
  ///
  /// In fr, this message translates to:
  /// **'Au tour de l\'adversaire'**
  String get onlineOpponentTurn;

  /// No description provided for @onlineSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi du coup…'**
  String get onlineSending;

  /// No description provided for @onlineOpponentAway.
  ///
  /// In fr, this message translates to:
  /// **'L\'adversaire s\'est déconnecté : il a {seconds} s pour revenir.'**
  String onlineOpponentAway(int seconds);

  /// No description provided for @onlineRatingChange.
  ///
  /// In fr, this message translates to:
  /// **'Classement : {delta}'**
  String onlineRatingChange(String delta);

  /// No description provided for @onlineBackToLobby.
  ///
  /// In fr, this message translates to:
  /// **'Retour au salon'**
  String get onlineBackToLobby;

  /// No description provided for @onlineErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur.'**
  String get onlineErrorNetwork;

  /// No description provided for @onlineErrorCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur ou mot de passe incorrect.'**
  String get onlineErrorCredentials;

  /// No description provided for @onlineErrorTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom est déjà pris.'**
  String get onlineErrorTaken;

  /// No description provided for @onlineErrorRoomNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Salle introuvable.'**
  String get onlineErrorRoomNotFound;

  /// No description provided for @onlineErrorRoomFull.
  ///
  /// In fr, this message translates to:
  /// **'Cette salle est complète.'**
  String get onlineErrorRoomFull;

  /// No description provided for @onlineErrorMove.
  ///
  /// In fr, this message translates to:
  /// **'Coup refusé par le serveur.'**
  String get onlineErrorMove;

  /// No description provided for @onlineErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String onlineErrorGeneric(String message);

  /// No description provided for @onlineLeaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get onlineLeaderboard;

  /// No description provided for @onlineTournaments.
  ///
  /// In fr, this message translates to:
  /// **'Tournois'**
  String get onlineTournaments;

  /// No description provided for @leaderboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur classé pour l\'instant.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardRecord.
  ///
  /// In fr, this message translates to:
  /// **'{wins} V · {losses} D · {draws} N'**
  String leaderboardRecord(int wins, int losses, int draws);

  /// No description provided for @tournamentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tournois'**
  String get tournamentsTitle;

  /// No description provided for @tournamentsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tournoi pour l\'instant.'**
  String get tournamentsEmpty;

  /// No description provided for @tournamentCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un tournoi'**
  String get tournamentCreate;

  /// No description provided for @tournamentName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du tournoi'**
  String get tournamentName;

  /// No description provided for @tournamentMaxPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximum de joueurs'**
  String get tournamentMaxPlayers;

  /// No description provided for @tournamentRoundRobin.
  ///
  /// In fr, this message translates to:
  /// **'Toutes rondes : chacun rencontre chacun'**
  String get tournamentRoundRobin;

  /// No description provided for @tournamentJoin.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get tournamentJoin;

  /// No description provided for @tournamentStart.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le tournoi'**
  String get tournamentStart;

  /// No description provided for @tournamentPlayers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun joueur} =1{1 joueur} other{{count} joueurs}}'**
  String tournamentPlayers(int count);

  /// No description provided for @tournamentStatusRegistering.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions ouvertes'**
  String get tournamentStatusRegistering;

  /// No description provided for @tournamentStatusRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get tournamentStatusRunning;

  /// No description provided for @tournamentStatusFinished.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get tournamentStatusFinished;

  /// No description provided for @tournamentRound.
  ///
  /// In fr, this message translates to:
  /// **'Ronde {number}'**
  String tournamentRound(int number);

  /// No description provided for @tournamentStandings.
  ///
  /// In fr, this message translates to:
  /// **'Classement du tournoi'**
  String get tournamentStandings;

  /// No description provided for @tournamentPoints.
  ///
  /// In fr, this message translates to:
  /// **'{points} pts'**
  String tournamentPoints(String points);

  /// No description provided for @tournamentPlayMatch.
  ///
  /// In fr, this message translates to:
  /// **'Jouer'**
  String get tournamentPlayMatch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'ar':
      {
        switch (locale.countryCode) {
          case 'MR':
            return AppLocalizationsArMr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
