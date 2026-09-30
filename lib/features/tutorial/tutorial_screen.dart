import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/common.dart';
import '../game/domain/board_interaction.dart';
import '../game/presentation/widgets/board_view.dart';
import '../settings/presentation/settings_controller.dart';
import 'tutorial_steps.dart';

enum _Feedback { none, success, wrong }

/// "How to play": lessons and exercises on the real engine.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _index = 0;
  late GameState _state = tutorialSteps.first.state;
  Position? _selected;
  _Feedback _feedback = _Feedback.none;

  TutorialStep get _step => tutorialSteps[_index];

  void _goTo(int index) {
    setState(() {
      _index = index;
      _reset();
    });
  }

  void _reset() {
    _state = _step.state;
    _selected = null;
    _feedback = _Feedback.none;
  }

  void _onTap(Position position) {
    if (!_step.isExercise || _feedback == _Feedback.success) return;
    switch (resolveTap(_state, _selected, position)) {
      case PlayMove(:final move):
        _play(move);
      case ChooseMove(:final moves):
        _play(moves.firstWhere(_step.goal!, orElse: () => moves.first));
      case SelectPiece(:final position):
        setState(() => _selected = position);
      case ClearSelection():
        setState(() => _selected = null);
    }
  }

  void _play(Move move) {
    setState(() {
      _selected = null;
      if (_step.goal!(move)) {
        _state = _state.play(move);
        _feedback = _Feedback.success;
      } else {
        _feedback = _Feedback.wrong;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final last = tutorialSteps.length - 1;
    final solved = !_step.isExercise || _feedback == _Feedback.success;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tutorialTitle)),
      body: ScreenFrame(
        maxWidth: 640,
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / tutorialSteps.length),
            Expanded(
              child: ListView(
                padding: AppSpacing.screen,
                children: [
                  Text(
                    l10n.tutorialStep(_index + 1, tutorialSteps.length),
                    style: theme.textTheme.labelLarge,
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      _step.title(l10n),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_step.body(l10n), style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  AspectRatio(
                    aspectRatio: 1,
                    child: DhametBoard(
                      state: _state,
                      selected: _selected,
                      targets: _selected == null
                          ? const []
                          : _state.legalMovesFrom(_selected!),
                      onTap: _step.isExercise ? _onTap : null,
                      showCoordinates: true,
                      animate:
                          settings.animationsEnabled &&
                          !MediaQuery.of(context).disableAnimations,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_feedback != _Feedback.none)
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          Icon(
                            _feedback == _Feedback.success
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: _feedback == _Feedback.success
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _feedback == _Feedback.success
                                  ? l10n.tutorialWellDone
                                  : l10n.tutorialTryAgain,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_step.isExercise && _feedback != _Feedback.none)
                    TextButton.icon(
                      onPressed: () => setState(_reset),
                      icon: const Icon(Icons.restart_alt),
                      label: Text(l10n.tutorialReset),
                    ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.screen,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      child: Text(l10n.tutorialPrevious),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: !solved
                          ? null
                          : _index < last
                          ? () => _goTo(_index + 1)
                          : () => Navigator.of(context).maybePop(),
                      child: Text(
                        _index < last ? l10n.tutorialNext : l10n.tutorialFinish,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
