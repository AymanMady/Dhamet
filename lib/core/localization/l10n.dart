import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/widgets.dart';

import '../../features/game/domain/game_mode.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized names of engine and app values.
extension GameNames on AppLocalizations {
  String playerName(Player player) =>
      player == Player.white ? playerWhite : playerBlack;

  String levelName(AiLevel level) => switch (level) {
    AiLevel.easy => difficultyEasy,
    AiLevel.medium => difficultyMedium,
    AiLevel.hard => difficultyHard,
    AiLevel.expert => difficultyExpert,
  };

  String levelDescription(AiLevel level) => switch (level) {
    AiLevel.easy => difficultyEasyDescription,
    AiLevel.medium => difficultyMediumDescription,
    AiLevel.hard => difficultyHardDescription,
    AiLevel.expert => difficultyExpertDescription,
  };

  String reasonText(GameEndReason reason) => switch (reason) {
    GameEndReason.elimination => reasonElimination,
    GameEndReason.blocked => reasonBlocked,
    GameEndReason.resignation => reasonResignation,
    GameEndReason.timeout => reasonTimeout,
    GameEndReason.repetition => reasonRepetition,
    GameEndReason.agreement => reasonAgreement,
  };

  String pieceName(Piece piece) => switch (piece) {
    Piece.whitePawn => pieceWhitePawn,
    Piece.blackPawn => pieceBlackPawn,
    Piece.whiteSultan => pieceWhiteSultan,
    Piece.blackSultan => pieceBlackSultan,
  };

  String modeName(GameMode mode) => switch (mode) {
    LocalMode() => historyLocal,
    AiMode(:final level) => historyAgainstAi(levelName(level)),
  };
}

/// Each language shown in its own script, whatever the interface language.
String nativeLanguageName(AppLanguage language) => switch (language) {
  AppLanguage.arabic => 'العربية',
  AppLanguage.hassaniya => 'الحسانية',
  AppLanguage.french => 'Français',
  AppLanguage.english => 'English',
};
