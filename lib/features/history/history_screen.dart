import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/common.dart';
import '../game/data/game_archive.dart';
import '../game/data/saved_game.dart';
import '../game/domain/game_mode.dart';
import '../game/presentation/pieces/piece_icon.dart';
import 'game_statistics.dart';

final finishedGamesProvider = FutureProvider.autoDispose<List<SavedGame>>(
  (ref) => ref.watch(gameArchiveProvider).finishedGames(),
);

/// Finished games and statistics.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final games = ref.watch(finishedGamesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: ScreenFrame(
        maxWidth: 640,
        child: games.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (games) => ListView(
            padding: AppSpacing.screen,
            children: [
              _StatisticsCard(GameStatistics.from(games)),
              const SizedBox(height: AppSpacing.md),
              if (games.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(l10n.historyEmpty, textAlign: TextAlign.center),
                ),
              for (final game in games)
                Dismissible(
                  key: ValueKey(game.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Semantics(
                      label: l10n.historyDelete,
                      child: const Icon(Icons.delete_outline),
                    ),
                  ),
                  onDismissed: (_) async {
                    await ref.read(gameArchiveProvider).deleteFinished(game.id);
                    ref.invalidate(finishedGamesProvider);
                  },
                  child: _GameTile(game),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile(this.saved);

  final SavedGame saved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final result = saved.game.result!;
    final mode = saved.mode;
    final human = mode is AiMode ? mode.humanSide : null;
    final outcome = result.isDraw
        ? l10n.historyDrawn
        : human == null
        ? l10n.resultWinner(l10n.playerName(result.winner!))
        : result.winner == human
        ? l10n.historyWon
        : l10n.historyLost;
    final date = saved.finishedAt ?? saved.startedAt;
    final when =
        '${localizations.formatMediumDate(date)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    return Card(
      child: ListTile(
        minTileHeight: AppSpacing.minTouchTarget,
        leading: result.isDraw
            ? const Icon(Icons.balance)
            : PieceIcon(Piece.of(result.winner!, PieceType.sultan), size: 36),
        title: Text('${l10n.modeName(mode)} · $outcome'),
        subtitle: Text('$when · ${l10n.movesCount(saved.game.state.plyCount)}'),
        trailing: const Icon(Icons.slideshow_outlined),
        onTap: () => context.push(AppRoutes.historyGame(saved.id)),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard(this.stats);

  final GameStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget stat(String label, String value) => SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.statsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.statsAgainstAi, style: theme.textTheme.titleSmall),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                stat(l10n.statsWins, '${stats.wins}'),
                stat(l10n.statsLosses, '${stats.losses}'),
                stat(l10n.statsWinRate, '${(stats.winRate * 100).round()} %'),
                stat(l10n.statsPiecesCaptured, '${stats.piecesCaptured}'),
                stat(l10n.statsSultansCreated, '${stats.sultansCreated}'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.statsAllGames, style: theme.textTheme.titleSmall),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                stat(l10n.statsGamesPlayed, '${stats.gamesPlayed}'),
                stat(l10n.statsDraws, '${stats.draws}'),
                stat(l10n.statsLongestGame, l10n.movesCount(stats.longestGame)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
