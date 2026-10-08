import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/sand/sand_background.dart';
import '../../../../core/widgets/wood_button.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../domain/game_mode.dart';
import '../../domain/game_session.dart';
import '../board/dhamet_board.dart';
import '../controllers/game_controller.dart';
import '../hud/game_actions.dart';
import '../hud/game_panels.dart';
import '../hud/game_status.dart';
import '../hud/pause_menu.dart';
import '../hud/result_sign.dart';
import '../pieces/piece_icon.dart';

/// A local game, against a friend on the same device or against the AI,
/// played on the sand. The board takes all the room it can; the HUD stays
/// light around it.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Move? _focusedChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsProvider);
    ref.listen(gameControllerProvider.select((s) => s?.isOver ?? false), (
      previous,
      over,
    ) {
      if (over && previous == false) {
        _showResultSoon(settings.animationsEnabled);
      }
    });
    ref.listen(gameControllerProvider.select((s) => s?.pendingChoices), (_, _) {
      if (_focusedChoice != null) setState(() => _focusedChoice = null);
    });

    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(l10n.backHome),
          ),
        ),
      );
    }

    final controller = ref.read(gameControllerProvider.notifier);
    final state = session.state;
    final flipped = session.humanSide == Player.black;
    final topPlayer = flipped ? Player.white : Player.black;
    final animate =
        settings.animationsEnabled && !MediaQuery.of(context).disableAnimations;
    final mustCapture = session.isHumanTurn && state.mustCapture;
    final result = session.result;

    final board = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DhametBoard(
              state: state,
              selected: session.selected,
              targets: session.selectedMoves,
              mustCaptureFrom: mustCapture ? session.movablePieces : const {},
              focusedMove: _focusedChoice,
              onTap: controller.tap,
              flipped: flipped,
              showCoordinates: settings.showCoordinates,
              showHints: settings.showMoveHints,
              animate: animate,
              intersectionLabel: (position, piece, {required isTarget}) {
                final base = piece == null
                    ? l10n.semanticsIntersection(position.notation)
                    : l10n.semanticsPiece(
                        position.notation,
                        l10n.pieceName(piece),
                      );
                return isTarget ? l10n.semanticsTarget(base) : base;
              },
            ),
          ),
          if (result != null)
            ResultSign(
              title: result.isDraw
                  ? l10n.resultDraw
                  : session.humanSide != null &&
                        result.loser == session.humanSide
                  ? l10n.resultDefeat
                  : l10n.resultVictory,
              emblem: result.isDraw
                  ? null
                  : PieceIcon(
                      Piece.of(result.winner!, PieceType.sultan),
                      size: 40,
                    ),
              animate: animate,
            ),
        ],
      ),
    );

    Widget panel(Player player) => PlayerPanel(
      player: player,
      name: _playerLabel(l10n, session, player),
      board: state.board,
      active: !session.isOver && state.currentPlayer == player,
    );

    final status = GameStatus(
      session: session,
      mustCapture: mustCapture,
      focusedChoice: _focusedChoice,
      onFocusChoice: (move) => setState(() => _focusedChoice = move),
      onConfirmChoice: () {
        final move = _focusedChoice;
        if (move != null) controller.choose(move);
      },
      onCancelChoice: controller.cancelChoice,
    );

    final actions = GameActions(
      canUndo: controller.canUndo,
      canRedo: controller.canRedo,
      isOver: session.isOver,
      onUndo: controller.undo,
      onRedo: controller.redo,
      onResign: () => _confirmResign(controller),
      onShowResult: () => context.push(AppRoutes.result),
    );

    final back = WoodButton.icon(
      icon: Icons.arrow_back,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: _leave,
    );
    final pause = WoodButton.icon(
      icon: Icons.pause,
      tooltip: l10n.pause,
      onPressed: () => _openPauseMenu(controller),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SandBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth > constraints.maxHeight * 1.15;
                if (wide) {
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Center(child: board),
                        ),
                      ),
                      SizedBox(
                        width: 360,
                        child: ListView(
                          padding: AppSpacing.screen,
                          children: [
                            Row(children: [back, const Spacer(), pause]),
                            const SizedBox(height: AppSpacing.sm),
                            panel(topPlayer),
                            const SizedBox(height: AppSpacing.sm),
                            Center(child: status),
                            const SizedBox(height: AppSpacing.sm),
                            panel(topPlayer.opponent),
                            const SizedBox(height: AppSpacing.md),
                            actions,
                          ],
                        ),
                      ),
                    ],
                  );
                }
                // Small phones: tighter spacing so that the board stays big.
                final gap = constraints.maxHeight < 640
                    ? AppSpacing.xs
                    : AppSpacing.sm;
                return ScreenFrame(
                  maxWidth: 640,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          gap,
                          AppSpacing.sm,
                          gap,
                        ),
                        child: Row(
                          children: [
                            back,
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: panel(topPlayer)),
                            const SizedBox(width: AppSpacing.xs),
                            pause,
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: status,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(gap),
                          child: Center(child: board),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: panel(topPlayer.opponent),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          gap + AppSpacing.xs,
                          AppSpacing.md,
                          gap + AppSpacing.xs,
                        ),
                        child: actions,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _playerLabel(
    AppLocalizations l10n,
    GameSession session,
    Player player,
  ) {
    final mode = session.mode;
    return switch (mode) {
      LocalMode() => l10n.playerName(player),
      AiMode(:final humanSide, :final level) =>
        player == humanSide
            ? '${l10n.playerYou} · ${l10n.playerName(player)}'
            : l10n.playerAi(l10n.levelName(level)),
    };
  }

  /// Back to the home screen; the game stays saved and can be resumed.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _showResultSoon(bool animations) {
    Future<void>.delayed(Duration(milliseconds: animations ? 1400 : 300), () {
      if (mounted) context.push(AppRoutes.result);
    });
  }

  Future<void> _confirmResign(GameController controller) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.resignTitle,
      body: l10n.resignBody,
      confirmLabel: l10n.resign,
      cancelLabel: l10n.cancel,
    );
    if (confirmed) controller.resign();
  }

  Future<void> _openPauseMenu(GameController controller) async {
    final action = await showPauseMenu(context);
    if (!mounted) return;
    final l10n = context.l10n;
    switch (action) {
      case null:
        break;
      case PauseAction.restart:
        final confirmed = await confirmDialog(
          context,
          title: l10n.restartTitle,
          body: l10n.restartBody,
          confirmLabel: l10n.restart,
          cancelLabel: l10n.cancel,
        );
        if (confirmed) controller.restart();
      case PauseAction.settings:
        await context.push(AppRoutes.settings);
      case PauseAction.leave:
        _leave();
    }
  }
}
