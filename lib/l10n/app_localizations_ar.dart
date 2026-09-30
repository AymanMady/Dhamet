// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ظامت';

  @override
  String get appTagline => 'لعبة موريتانية تقليدية';

  @override
  String get homeNewGame => 'لعبة جديدة';

  @override
  String get homePlayAi => 'العب ضد الحاسوب';

  @override
  String get homePlayFriend => 'العب مع صديق';

  @override
  String get homePlayOnline => 'العب عبر الإنترنت';

  @override
  String get homeHowToPlay => 'طريقة اللعب';

  @override
  String get homeHistory => 'السجل';

  @override
  String get homeSettings => 'الإعدادات';

  @override
  String get homeResume => 'استئناف اللعبة';

  @override
  String homeResumeDetails(String mode, int moveNumber) {
    return '$mode · النقلة $moveNumber';
  }

  @override
  String get modeTitle => 'نمط اللعب';

  @override
  String get modeLocal => 'لاعب ضد لاعب';

  @override
  String get modeLocalDescription => 'لاعبان على الجهاز نفسه';

  @override
  String get modeAi => 'لاعب ضد الحاسوب';

  @override
  String get modeAiDescription => 'تحدَّ الحاسوب';

  @override
  String get aiSetupTitle => 'ضد الحاسوب';

  @override
  String get difficultyTitle => 'مستوى الصعوبة';

  @override
  String get difficultyEasy => 'سهل';

  @override
  String get difficultyMedium => 'متوسط';

  @override
  String get difficultyHard => 'صعب';

  @override
  String get difficultyExpert => 'خبير';

  @override
  String get difficultyEasyDescription => 'لاكتشاف اللعبة';

  @override
  String get difficultyMediumDescription => 'خصم متوازن';

  @override
  String get difficultyHardDescription => 'لا يترك لك أي خطأ';

  @override
  String get difficultyExpertDescription => 'يفكر طويلًا ويلعب بقوة';

  @override
  String get sideTitle => 'جانبك';

  @override
  String get sideRandom => 'عشوائي';

  @override
  String get whiteStarts => 'الأبيض يبدأ.';

  @override
  String get startGame => 'ابدأ';

  @override
  String get playerWhite => 'الأبيض';

  @override
  String get playerBlack => 'الأسود';

  @override
  String get playerYou => 'أنت';

  @override
  String playerAi(String level) {
    return 'الحاسوب · $level';
  }

  @override
  String turnOf(String player) {
    return 'دور $player';
  }

  @override
  String get yourTurn => 'دورك';

  @override
  String get aiThinking => 'الحاسوب يفكر…';

  @override
  String get toMove => 'الدور';

  @override
  String get mustCapture => 'الأكل إجباري: خذ أكبر عدد ممكن من القطع.';

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قطعة',
      many: '$count قطعة',
      few: '$count قطع',
      two: 'قطعتان',
      one: 'قطعة واحدة',
      zero: 'لا قطع',
    );
    return '$_temp0';
  }

  @override
  String sultansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سلطان',
      many: '$count سلطانًا',
      few: '$count سلاطين',
      two: 'سلطانان',
      one: 'سلطان واحد',
      zero: 'لا سلطان',
    );
    return '$_temp0';
  }

  @override
  String lastMoveLabel(String move) {
    return 'آخر نقلة: $move';
  }

  @override
  String get chooseCapture => 'عدة طرق للأكل تنتهي هنا: اختر واحدة.';

  @override
  String captureOption(String notation, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قطعة',
      many: '$count قطعة',
      few: '$count قطع',
      two: 'قطعتان',
      one: 'قطعة واحدة',
      zero: 'بلا أكل',
    );
    return '$notation · $_temp0';
  }

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get undo => 'تراجع';

  @override
  String get redo => 'إعادة';

  @override
  String get resign => 'استسلام';

  @override
  String get restart => 'إعادة اللعبة';

  @override
  String get resignTitle => 'هل تريد الاستسلام؟';

  @override
  String get resignBody => 'سيُعلَن خصمك فائزًا.';

  @override
  String get restartTitle => 'إعادة اللعبة؟';

  @override
  String get restartBody => 'ستُترك اللعبة الحالية.';

  @override
  String get resultVictory => 'فوز';

  @override
  String get resultDefeat => 'خسارة';

  @override
  String get resultDraw => 'تعادل';

  @override
  String resultWinner(String player) {
    return 'فاز $player';
  }

  @override
  String get reasonElimination => 'أُخذت كل قطع الخصم.';

  @override
  String get reasonBlocked => 'لم يعد لدى الخصم أي نقلة.';

  @override
  String get reasonResignation => 'استسلام.';

  @override
  String get reasonTimeout => 'انتهى الوقت.';

  @override
  String get reasonRepetition => 'تكرر الوضع نفسه.';

  @override
  String get reasonAgreement => 'تعادل بالاتفاق.';

  @override
  String movesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نقلة',
      many: '$count نقلة',
      few: '$count نقلات',
      two: 'نقلتان',
      one: 'نقلة واحدة',
      zero: 'لا نقلات',
    );
    return '$_temp0';
  }

  @override
  String get playAgain => 'العب مجددًا';

  @override
  String get backHome => 'العودة إلى الرئيسية';

  @override
  String get viewGame => 'مشاهدة اللعبة';

  @override
  String get replayTitle => 'إعادة مشاهدة اللعبة';

  @override
  String get replayStart => 'الوضع الابتدائي';

  @override
  String replayPosition(int ply, int total) {
    return 'النقلة $ply من $total';
  }

  @override
  String get replayFirst => 'البداية';

  @override
  String get replayPrevious => 'النقلة السابقة';

  @override
  String get replayNext => 'النقلة التالية';

  @override
  String get replayLast => 'النهاية';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSectionGame => 'اللعب';

  @override
  String get settingsSectionDisplay => 'العرض';

  @override
  String get settingsSectionPrivacy => 'الخصوصية';

  @override
  String get settingsSectionAdvanced => 'متقدم';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsSound => 'الأصوات';

  @override
  String get settingsHaptics => 'الاهتزاز';

  @override
  String get settingsAnimations => 'الحركات';

  @override
  String get settingsAnimationsDescription => 'عطّلها لتصبح النقلات فورية.';

  @override
  String get settingsCoordinates => 'إظهار الإحداثيات';

  @override
  String get settingsHints => 'إظهار النقلات الممكنة';

  @override
  String get settingsAnalytics => 'إحصاءات استخدام مجهولة';

  @override
  String get settingsAnalyticsDescription => 'لا يُرسَل أي شيء دون موافقتك.';

  @override
  String get settingsDeveloper => 'وضع المطوّر';

  @override
  String get settingsDeveloperDescription =>
      'الإحداثيات والنقلات القانونية وحالة اللعبة ووقت الحاسوب.';

  @override
  String get settingsPerformanceOverlay => 'إظهار الأداء (FPS)';

  @override
  String get settingsServerUrl => 'عنوان الخادم';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get aboutBody =>
      'ظامت هي لعبة الداما التقليدية في موريتانيا. القواعد المطبقة ومصادرها موثقة، وبعضها ما زال بحاجة إلى تأكيد من اللاعبين.';

  @override
  String get devPanelTitle => 'المطوّر';

  @override
  String devLegalMoves(int count) {
    return 'النقلات القانونية ($count)';
  }

  @override
  String devAiTime(int milliseconds) {
    return 'وقت الحاسوب: $milliseconds ms';
  }

  @override
  String devPly(int ply) {
    return 'أنصاف النقلات: $ply';
  }

  @override
  String get devState => 'حالة اللعبة (JSON)';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyEmpty => 'لا توجد لعبة منتهية بعد.';

  @override
  String historyAgainstAi(String level) {
    return 'ضد الحاسوب · $level';
  }

  @override
  String get historyLocal => 'لاعبان';

  @override
  String get historyDelete => 'حذف';

  @override
  String get historyWon => 'فوز';

  @override
  String get historyLost => 'خسارة';

  @override
  String get historyDrawn => 'تعادل';

  @override
  String get statsTitle => 'الإحصاءات';

  @override
  String get statsAgainstAi => 'ضد الحاسوب';

  @override
  String get statsAllGames => 'كل الألعاب';

  @override
  String get statsGamesPlayed => 'الألعاب الملعوبة';

  @override
  String get statsWins => 'انتصارات';

  @override
  String get statsLosses => 'هزائم';

  @override
  String get statsDraws => 'تعادلات';

  @override
  String get statsWinRate => 'نسبة الفوز';

  @override
  String get statsPiecesCaptured => 'القطع المأخوذة';

  @override
  String get statsSultansCreated => 'السلاطين المحصَّلون';

  @override
  String get statsLongestGame => 'أطول لعبة';

  @override
  String get tutorialTitle => 'طريقة اللعب';

  @override
  String tutorialStep(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get tutorialNext => 'التالي';

  @override
  String get tutorialPrevious => 'السابق';

  @override
  String get tutorialFinish => 'إنهاء';

  @override
  String get tutorialWellDone => 'أحسنت!';

  @override
  String get tutorialTryAgain => 'ليست هذه النقلة المطلوبة. حاول مجددًا.';

  @override
  String get tutorialReset => 'إعادة التمرين';

  @override
  String get tutorialBoardTitle => 'الرقعة';

  @override
  String get tutorialBoardBody =>
      'تُلعب ظامت على النقاط الإحدى والثمانين لشبكة من 9 × 9 خطوط، مرسومة كأربع رقع من لعبة القِرْق. لا تمر الأقطار إلا بنقطة من كل نقطتين، وهي النقاط «الواسعة» (لوسع). أما النقاط «الضيقة» (الظيك) فليس لها قطر.';

  @override
  String get tutorialPiecesTitle => 'القطع';

  @override
  String get tutorialPiecesBody =>
      'لكل جانب 40 قطعة، ولا تبقى فارغة في البداية إلا النقطة الوسطى. تقليديًا يلعب جانب بالعيدان والآخر بالبعر: هنا تحمل القطع الفاتحة عودًا والداكنة حلقة.';

  @override
  String get tutorialMoveTitle => 'التحرك';

  @override
  String get tutorialMoveBody =>
      'يتقدم الجندي خطوة واحدة إلى نقطة فارغة، مستقيمًا أو قطريًا على خط مرسوم. لا يرجع إلى الخلف أبدًا ولا يتحرك جانبيًا. قدّم الجندي الأبيض.';

  @override
  String get tutorialCaptureTitle => 'الأكل';

  @override
  String get tutorialCaptureBody =>
      'يكون الأكل بالقفز فوق قطعة مجاورة للخصم إلى النقطة الفارغة خلفها مباشرة، في كل الاتجاهات، حتى إلى الخلف. والأكل إجباري. كُل الجندي الأسود.';

  @override
  String get tutorialRafleTitle => 'الأكل المتتالي';

  @override
  String get tutorialRafleBody =>
      'إذا استطاع الجندي الأكل مجددًا بعد أكلة، فإنه يواصل. تُزال القطع المأكولة فورًا، ويجب دائمًا لعب السلسلة التي تأكل أكبر عدد من القطع. نفّذ أكل القطع الخمس.';

  @override
  String get tutorialPromotionTitle => 'الترقية';

  @override
  String get tutorialPromotionBody =>
      'الجندي الذي ينهي نقلته على آخر صف للخصم يصبح سلطانًا (ظايم). أوصل الجندي إلى الصف الأخير.';

  @override
  String get tutorialSultanTitle => 'السلطان';

  @override
  String get tutorialSultanBody =>
      'يتحرك السلطان على طول الخط بأي عدد من النقاط، إلى الأمام أو إلى الخلف، ويأكل قطعة بعيدة إذا كانت النقطة خلفها فارغة. كُل الجندي الأسود بالسلطان.';

  @override
  String get tutorialVictoryTitle => 'الفوز';

  @override
  String get tutorialVictoryBody =>
      'تفوز بأكل كل قطع الخصم، أو عندما لا يستطيع الخصم التحرك. كُل آخر قطعة سوداء.';

  @override
  String get tutorialSpecialTitle => 'قواعد خاصة';

  @override
  String get tutorialSpecialBody =>
      'عندما تتعدد إمكانيات الأكل، يجب لعب أطولها. في التقليد يمكن للخصم «نفخ» القطعة التي لم تُكمل أكلها، أما هنا فيفرض التطبيق النقلة الصحيحة مباشرة. بعض القواعد ما زالت بحاجة إلى تأكيد وهي قابلة للضبط. العب أطول أكل.';

  @override
  String semanticsIntersection(String position) {
    return '$position';
  }

  @override
  String semanticsPiece(String position, String piece) {
    return '$position، $piece';
  }

  @override
  String semanticsTarget(String label) {
    return '$label، وجهة ممكنة';
  }

  @override
  String get pieceWhitePawn => 'جندي أبيض';

  @override
  String get pieceBlackPawn => 'جندي أسود';

  @override
  String get pieceWhiteSultan => 'سلطان أبيض';

  @override
  String get pieceBlackSultan => 'سلطان أسود';
}
