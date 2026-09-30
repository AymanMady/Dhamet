import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/screens/ai_setup_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/game/presentation/screens/home_screen.dart';
import '../../features/game/presentation/screens/new_game_screen.dart';
import '../../features/game/presentation/screens/replay_screen.dart';
import '../../features/game/presentation/screens/result_screen.dart';
import '../../features/game/presentation/screens/splash_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/multiplayer/presentation/online_game_screen.dart';
import '../../features/multiplayer/presentation/online_room_screen.dart';
import '../../features/multiplayer/presentation/online_screen.dart';
import '../../features/profile/leaderboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tournaments/tournaments_screen.dart';
import '../../features/tutorial/tutorial_screen.dart';

/// Route paths. Screens reached from the home screen are nested under it so
/// that "back" always leads home.
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const newGame = '/home/new';
  static const aiSetup = '/home/new/ai';
  static const game = '/home/game';
  static const result = '/home/result';
  static const replay = '/home/replay';
  static const history = '/home/history';
  static const settings = '/home/settings';
  static const tutorial = '/home/tutorial';
  static const online = '/home/online';
  static const onlineRoom = '/home/online/room';
  static const onlineGame = '/home/online/game';
  static const leaderboard = '/home/online/leaderboard';
  static const tournaments = '/home/online/tournaments';

  static String tournament(String id) => '$tournaments/$id';

  static String historyGame(String id) => '$history/$id';
}

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NewGameScreen(),
            routes: [
              GoRoute(
                path: 'ai',
                builder: (context, state) => const AiSetupScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'game',
            builder: (context, state) => const GameScreen(),
          ),
          GoRoute(
            path: 'result',
            builder: (context, state) => const ResultScreen(),
          ),
          GoRoute(
            path: 'replay',
            builder: (context, state) =>
                ReplayScreen(game: state.extra as Game?),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ReplayScreen(savedGameId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'tutorial',
            builder: (context, state) => const TutorialScreen(),
          ),
          GoRoute(
            path: 'online',
            builder: (context, state) => const OnlineScreen(),
            routes: [
              GoRoute(
                path: 'room',
                builder: (context, state) => const OnlineRoomScreen(),
              ),
              GoRoute(
                path: 'game',
                builder: (context, state) => const OnlineGameScreen(),
              ),
              GoRoute(
                path: 'leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
              GoRoute(
                path: 'tournaments',
                builder: (context, state) => const TournamentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        TournamentScreen(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
