// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ظامتنا';

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
  String get whiteStarts => 'العودان تبدأ.';

  @override
  String get startGame => 'ابدأ';

  @override
  String get playerWhite => 'العودان';

  @override
  String get playerBlack => 'لبعر';

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
  String get mustCapture => 'الأكل إجباري: كُل أكثر ما يمكن.';

  @override
  String piecesCount(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عود',
      many: '$count عودًا',
      few: '$count عودان',
      two: 'عودان',
      one: 'عود واحد',
      zero: 'لا عود',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بعرة',
      many: '$count بعرة',
      few: '$count بعرات',
      two: 'بعرتان',
      one: 'بعرة واحدة',
      zero: 'لا بعرة',
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
      other: '$count ظايمة',
      many: '$count ظايمة',
      few: '$count ظايمات',
      two: 'ظايمتان',
      one: 'ظايمة واحدة',
      zero: 'لا ظايمة',
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
      other: '$count أكلة',
      many: '$count أكلة',
      few: '$count أكلات',
      two: 'أكلتان',
      one: 'أكلة واحدة',
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
  String get pause => 'إيقاف مؤقت';

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
  String get reasonElimination => 'لم يبق للخصم شيء على الرقعة.';

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
  String get showResult => 'عرض النتيجة';

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
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyBody =>
      'ظامتنا لا تحتوي على إعلانات ولا على أدوات تتبّع، ولا تطلب أي إذن حساس.\n\nعلى جهازك: الألعاب المحلية والألعاب ضد الحاسوب، والسجل، واللعبة الجارية، وإعداداتك. لا تغادر هذه البيانات جهازك.\n\nعبر الإنترنت، فقط إذا لعبت عبر الإنترنت: يحتفظ خادم ظامتنا باسم اللاعب، وبكلمة المرور في صيغة مُجزَّأة (لا تُحفظ أبدًا كما هي) أو بحساب ضيف، وبألعابك عبر الإنترنت وترتيبك وبطولاتك. تُستخدم هذه البيانات للّعبة فقط، ولا تُباع ولا تُشارَك. الاتصالات مشفّرة (HTTPS).\n\nإحصاءات الاستخدام، إن فعّلتها، تبقى على الجهاز في هذا الإصدار.\n\nيمكنك حذف حسابك في أي وقت: اللعب عبر الإنترنت ← حذف حسابي. يُمحى اسمك وكلمة مرورك، وتبقى ألعابك السابقة في سجل خصومك باسم مجهول.';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get aboutBody =>
      'ظامتنا تتيح لك لعب ظامت، لعبة الداما التقليدية في موريتانيا. القواعد المطبقة ومصادرها موثقة، وبعضها ما زال بحاجة إلى تأكيد من اللاعبين.';

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
  String get statsPiecesCaptured => 'الأكلات';

  @override
  String get statsSultansCreated => 'الظايمات المحصَّلة';

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
  String get tutorialPiecesTitle => 'العودان ولبعر';

  @override
  String get tutorialPiecesBody =>
      'يتواجه طرفان: العودان ولبعر. العود غصن صغير مغروس في الرمل، والبعرة من بعر الإبل. لكل طرف 40، ولا تبقى فارغة في البداية إلا النقطة الوسطى.';

  @override
  String get tutorialMoveTitle => 'التحرك';

  @override
  String get tutorialMoveBody =>
      'يتقدم العود أو البعرة خطوة واحدة إلى نقطة فارغة، مستقيمًا أو قطريًا على خط مرسوم. لا يرجع إلى الخلف أبدًا ولا يتحرك جانبيًا. قدّم العود.';

  @override
  String get tutorialCaptureTitle => 'الأكل';

  @override
  String get tutorialCaptureBody =>
      'يكون الأكل بالقفز فوق خصم مجاور إلى النقطة الفارغة خلفه مباشرة، في كل الاتجاهات، حتى إلى الخلف. والأكل إجباري. كُل البعرة.';

  @override
  String get tutorialRafleTitle => 'الأكل المتتالي';

  @override
  String get tutorialRafleBody =>
      'إذا استطاع العود الأكل مجددًا بعد أكلة، فإنه يواصل. يُزال ما أُكل فورًا، ويجب دائمًا لعب السلسلة التي تأكل أكثر. كُل البعرات الخمس في نقلة واحدة.';

  @override
  String get tutorialPromotionTitle => 'الترقية';

  @override
  String get tutorialPromotionBody =>
      'العود أو البعرة إذا أنهى نقلته على آخر صف للخصم يصبح ظايمة. وكما على الرمل، تُضاعَف الظايمة: عودان متقاطعان، أو بعرة ثانية فاتحة فوق الأولى. أوصل العود إلى الصف الأخير.';

  @override
  String get tutorialSultanTitle => 'الظايمة';

  @override
  String get tutorialSultanBody =>
      'تتحرك الظايمة على طول الخط بأي عدد من النقاط، إلى الأمام أو إلى الخلف، وتأكل من بعيد إذا كانت النقطة خلف الخصم فارغة. كُل البعرة بالظايمة.';

  @override
  String get tutorialVictoryTitle => 'الفوز';

  @override
  String get tutorialVictoryBody =>
      'تفوز عندما لا يبقى للخصم شيء على الرقعة، أو عندما لا يستطيع التحرك. كُل آخر بعرة.';

  @override
  String get tutorialSpecialTitle => 'قواعد خاصة';

  @override
  String get tutorialSpecialBody =>
      'عندما تتعدد إمكانيات الأكل، يجب لعب أطولها. في التقليد يمكن للخصم «نفخ» العود أو البعرة التي لم تُكمل أكلها، أما هنا فيفرض التطبيق النقلة الصحيحة مباشرة. بعض القواعد ما زالت بحاجة إلى تأكيد وهي قابلة للضبط. العب أطول أكل.';

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
  String get pieceWhitePawn => 'عود';

  @override
  String get pieceBlackPawn => 'بعرة';

  @override
  String get pieceWhiteSultan => 'ظايمة العودان';

  @override
  String get pieceBlackSultan => 'ظايمة لبعر';

  @override
  String get onlineTitle => 'اللعب عبر الإنترنت';

  @override
  String get onlineSignInTitle => 'تسجيل الدخول';

  @override
  String get onlineUsername => 'اسم المستخدم';

  @override
  String get onlinePassword => 'كلمة المرور';

  @override
  String get onlineUsernameRule => 'من 3 إلى 20 حرفًا: حروف أو أرقام أو _';

  @override
  String get onlinePasswordRule => '8 أحرف على الأقل';

  @override
  String get onlineSignIn => 'دخول';

  @override
  String get onlineRegister => 'إنشاء حساب';

  @override
  String get onlineGuest => 'العب كضيف';

  @override
  String get onlineSignOut => 'تسجيل الخروج';

  @override
  String get onlineDeleteAccount => 'حذف حسابي';

  @override
  String get onlineDeleteAccountTitle => 'حذف حسابك؟';

  @override
  String get onlineDeleteAccountBody =>
      'سيُمحى اسم اللاعب وكلمة المرور، ولن تتمكن بعد ذلك من تسجيل الدخول بهذا الحساب. ستُحتسب اللعبة الجارية ومبارياتك المتبقية في البطولات خسارةً بالاستسلام. تبقى ألعابك السابقة في سجل خصومك باسم مجهول. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get onlineDeleteAccountConfirm => 'حذف';

  @override
  String get onlineAccountDeleted => 'تم حذف حسابك.';

  @override
  String get onlineGuestBadge => 'ضيف';

  @override
  String onlineRating(int rating) {
    return 'تصنيف إيلو: $rating';
  }

  @override
  String get onlineConnected => 'متصل';

  @override
  String get onlineConnecting => 'جارٍ الاتصال…';

  @override
  String get onlineReconnecting => 'انقطع الاتصال، جارٍ إعادة الاتصال…';

  @override
  String get onlineDisconnected => 'غير متصل';

  @override
  String get onlineCreateRoom => 'إنشاء غرفة خاصة';

  @override
  String get onlineJoinRoom => 'الانضمام إلى غرفة';

  @override
  String get onlineRoomCode => 'رمز الغرفة';

  @override
  String get onlineJoin => 'انضمام';

  @override
  String get onlineRated => 'لعبة مصنَّفة';

  @override
  String get onlineRatedGuestNote => 'لا يمكن للضيوف لعب ألعاب مصنَّفة.';

  @override
  String get onlineTimeControl => 'الساعة';

  @override
  String get onlineNoClock => 'بلا حد زمني كما في التقليد';

  @override
  String onlineClock(int minutes, int seconds) {
    return '$minutes د + $seconds ث';
  }

  @override
  String onlineRoomTitle(String code) {
    return 'الغرفة $code';
  }

  @override
  String get onlineShareCode => 'أعطِ هذا الرمز لخصمك.';

  @override
  String get onlineCopy => 'نسخ الرمز';

  @override
  String get onlineCopied => 'تم نسخ الرمز';

  @override
  String get onlineWaitingOpponent => 'في انتظار خصم…';

  @override
  String get onlineReady => 'أنا جاهز';

  @override
  String get onlinePlayerReady => 'جاهز';

  @override
  String get onlinePlayerNotReady => 'ليس جاهزًا بعد';

  @override
  String get onlinePlayerAway => 'غير متصل';

  @override
  String get onlineHost => 'المضيف';

  @override
  String get onlineLeave => 'مغادرة الغرفة';

  @override
  String get onlineOpponentTurn => 'دور الخصم';

  @override
  String get onlineSending => 'جارٍ إرسال النقلة…';

  @override
  String onlineOpponentAway(int seconds) {
    return 'انقطع اتصال الخصم: أمامه $seconds ثانية للعودة.';
  }

  @override
  String onlineRatingChange(String delta) {
    return 'التصنيف: $delta';
  }

  @override
  String get onlineBackToLobby => 'العودة إلى الردهة';

  @override
  String get onlineErrorNetwork => 'تعذّر الوصول إلى الخادم.';

  @override
  String get onlineErrorCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get onlineErrorTaken => 'هذا الاسم مستخدم بالفعل.';

  @override
  String get onlineErrorRoomNotFound => 'الغرفة غير موجودة.';

  @override
  String get onlineErrorRoomFull => 'هذه الغرفة ممتلئة.';

  @override
  String get onlineErrorMove => 'رفض الخادم النقلة.';

  @override
  String onlineErrorGeneric(String message) {
    return 'خطأ: $message';
  }

  @override
  String get onlineLeaderboard => 'الترتيب';

  @override
  String get onlineTournaments => 'البطولات';

  @override
  String get leaderboardTitle => 'الترتيب';

  @override
  String get leaderboardEmpty => 'لا يوجد لاعب مصنَّف بعد.';

  @override
  String leaderboardRecord(int wins, int losses, int draws) {
    return '$wins ف · $losses خ · $draws ت';
  }

  @override
  String get tournamentsTitle => 'البطولات';

  @override
  String get tournamentsEmpty => 'لا توجد بطولة بعد.';

  @override
  String get tournamentCreate => 'إنشاء بطولة';

  @override
  String get tournamentName => 'اسم البطولة';

  @override
  String get tournamentMaxPlayers => 'العدد الأقصى للاعبين';

  @override
  String get tournamentRoundRobin => 'دوري كامل: يلتقي الجميع بالجميع';

  @override
  String get tournamentJoin => 'التسجيل';

  @override
  String get tournamentStart => 'بدء البطولة';

  @override
  String tournamentPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لاعب',
      many: '$count لاعبًا',
      few: '$count لاعبين',
      two: 'لاعبان',
      one: 'لاعب واحد',
      zero: 'لا لاعبين',
    );
    return '$_temp0';
  }

  @override
  String get tournamentStatusRegistering => 'التسجيل مفتوح';

  @override
  String get tournamentStatusRunning => 'جارية';

  @override
  String get tournamentStatusFinished => 'منتهية';

  @override
  String tournamentRound(int number) {
    return 'الجولة $number';
  }

  @override
  String get tournamentStandings => 'ترتيب البطولة';

  @override
  String tournamentPoints(String points) {
    return '$points نقطة';
  }

  @override
  String get tournamentPlayMatch => 'العب';
}

/// The translations for Arabic, as used in Mauritania (`ar_MR`).
class AppLocalizationsArMr extends AppLocalizationsAr {
  AppLocalizationsArMr() : super('ar_MR');
}
