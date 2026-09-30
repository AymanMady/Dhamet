import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/sand/sand_background.dart';
import '../../../../core/widgets/sand/sand_plate.dart';
import '../../../../core/widgets/wood_button.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../data/game_archive.dart';
import '../board/dhamet_board.dart';

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
    final palette = context.boardPalette;
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
              child: SandPlate(
                child: Text(
                  _index == 0
                      ? l10n.replayStart
                      : l10n.replayPosition(_index, last),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
              SandPlate(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(l10n.lastMoveLabel(state.lastMove!.notation)),
              ),
            Padding(
              padding: AppSpacing.screen,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  WoodButton.icon(
                    tooltip: l10n.replayFirst,
                    onPressed: _index > 0 ? () => _go(0) : null,
                    icon: isRtl ? Icons.last_page : Icons.first_page,
                  ),
                  WoodButton.icon(
                    tooltip: l10n.replayPrevious,
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
                  ),
                  WoodButton.icon(
                    tooltip: l10n.replayNext,
                    onPressed: _index < last ? () => _go(_index + 1) : null,
                    icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
                  ),
                  WoodButton.icon(
                    tooltip: l10n.replayLast,
                    onPressed: _index < last ? () => _go(last) : null,
                    icon: isRtl ? Icons.first_page : Icons.last_page,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.ink,
        title: Text(l10n.replayTitle),
      ),
      body: SandBackground(child: SafeArea(child: body)),
    );
  }
}
