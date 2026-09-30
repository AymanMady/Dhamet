import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/sand/sand_plate.dart';
import '../../domain/game_session.dart';
import 'game_panels.dart';

/// What is happening, on a plate above the board: whose turn it is, a
/// mandatory capture, the computer thinking or the end of the game, and the
/// last move. While several capture sequences compete, the choice between
/// them takes its place.
class GameStatus extends StatelessWidget {
  const GameStatus({
    super.key,
    required this.session,
    required this.mustCapture,
    required this.focusedChoice,
    required this.onFocusChoice,
    required this.onConfirmChoice,
    required this.onCancelChoice,
  });

  final GameSession session;
  final bool mustCapture;
  final Move? focusedChoice;
  final ValueChanged<Move> onFocusChoice;
  final VoidCallback onConfirmChoice;
  final VoidCallback onCancelChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.boardPalette;
    if (session.pendingChoices.isNotEmpty) {
      return CaptureChoicePanel(
        choices: session.pendingChoices,
        focused: focusedChoice,
        onFocus: onFocusChoice,
        onConfirm: onConfirmChoice,
        onCancel: onCancelChoice,
      );
    }
    final headlineStyle = theme.textTheme.titleMedium?.copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w700,
    );
    final lastMove = session.state.lastMove;
    final Widget headline;
    if (session.aiThinking) {
      headline = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(l10n.aiThinking, style: headlineStyle)),
        ],
      );
    } else if (session.isOver) {
      final result = session.result!;
      headline = Text(
        result.isDraw
            ? l10n.resultDraw
            : l10n.resultWinner(l10n.playerName(result.winner!)),
        style: headlineStyle,
      );
    } else if (mustCapture) {
      headline = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.capture),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(l10n.mustCapture, style: headlineStyle)),
        ],
      );
    } else {
      final current = session.state.currentPlayer;
      headline = Text(
        session.humanSide == current
            ? l10n.yourTurn
            : l10n.turnOf(l10n.playerName(current)),
        style: headlineStyle,
      );
    }
    return Semantics(
      liveRegion: true,
      child: SandPlate(
        tint: mustCapture && !session.aiThinking ? palette.capture : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            headline,
            if (lastMove != null)
              Text(
                l10n.lastMoveLabel(lastMove.notation),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.ink.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
