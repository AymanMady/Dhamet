import { GamePlayer } from '../games/game-player.entity';
import { Game } from '../games/game.entity';
import { Move } from '../games/move.entity';
import { Ranking } from '../ranking/ranking.entity';
import { Room } from '../rooms/room.entity';
import { TournamentMatch } from '../tournaments/tournament-match.entity';
import { TournamentPlayer } from '../tournaments/tournament-player.entity';
import { Tournament } from '../tournaments/tournament.entity';
import { User } from '../users/user.entity';

export const ENTITIES = [
  User,
  Game,
  GamePlayer,
  Move,
  Room,
  Ranking,
  Tournament,
  TournamentPlayer,
  TournamentMatch,
];
