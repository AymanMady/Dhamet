import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../data/game_archive.dart';
import '../widgets/board_view.dart';

/// Steps through a finished (or current) game, move by move.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key, this.game, this.savedGameId});

  /// The game to replay, when already in memory.
  final Game? game;

  /// Otherwise, the identifier of a finished game in the archive.
  final String? savedGameId;

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  List<GameState>? _states;
  int _index = 0;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    final game = widget.game;
    if (game != null) {
      _states = game.history.states;
    } else if (widget.savedGameId != null) {
      _load(widget.savedGameId!);
    } else {
      _notFound = true;
    }
  }

  Future<void> _load(String id) async {
    final saved = await ref.read(gameArchiveProvider).finishedGame(id);
    if (!mounted) return;
    setState(() {
      _states = saved?.game.history.states;
      _notFound = saved == null;
    });
  }

  void _go(int index) {
    final states = _states;
    if (states == null) return;
    setState(() => _index = index.clamp(0, states.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final states = _states;
    final Widget body;
    if (states == null) {
      body = Center(
        child: _notFound
            ? Text(l10n.historyEmpty)
            : const CircularProgressIndicator(),
      );
    } else {
      final state = states[_index];
      final last = states.length - 1;
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      body = ScreenFrame(
        maxWidth: 640,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                _index == 0
                    ? l10n.replayStart
                    : l10n.replayPosition(_index, last),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DhametBoard(
                      state: state,
                      showCoordinates: settings.showCoordinates,
                      showHints: false,
                      animate:
                          settings.animationsEnabled &&
                          !MediaQuery.of(context).disableAnimations,
                    ),
                  ),
                ),
              ),
            ),
            if (state.lastMove != null)
              Text(l10n.lastMoveLabel(state.lastMove!.notation)),
            Padding(
              padding: AppSpacing.screen,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.outlined(
                    tooltip: l10n.replayFirst,
                    iconSize: 28,
                    onPressed: _index > 0 ? () => _go(0) : null,
                    icon: Icon(isRtl ? Icons.last_page : Icons.first_page),
                  ),
                  IconButton.outlined(
                    tooltip: l10n.replayPrevious,
                    iconSize: 28,
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: Icon(
                      isRtl ? Icons.chevron_right : Icons.chevron_left,
                    ),
                  ),
                  IconButton.filled(
                    tooltip: l10n.replayNext,
                    iconSize: 28,
                    onPressed: _index < last ? () => _go(_index + 1) : null,
                    icon: Icon(
                      isRtl ? Icons.chevron_left : Icons.chevron_right,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: l10n.replayLast,
                    iconSize: 28,
                    onPressed: _index < last ? () => _go(last) : null,
                    icon: Icon(isRtl ? Icons.first_page : Icons.last_page),
                  ),
                ],
              ),
            ),
            if (last > 0)
              Slider(
                value: _index.toDouble(),
                max: last.toDouble(),
                divisions: last,
                label: '$_index',
                onChanged: (value) => _go(value.round()),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.replayTitle)),
      body: body,
    );
  }
}
