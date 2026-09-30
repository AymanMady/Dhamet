import { GameResultJson } from '../engine/engine.types';
import { toUserView, UserView } from '../users/user.view';
import { Tournament, TournamentFormat, TournamentStatus } from './tournament.entity';

/** `tournament` in docs/multiplayer.md. */
export interface TournamentView {
  id: string;
  name: string;
  format: TournamentFormat;
  status: TournamentStatus;
  maxPlayers: number;
  createdBy: UserView;
  /** Standings: best score first. */
  players: { user: UserView; score: number }[];
  rounds: {
    number: number;
    matches: {
      id: string;
      white: UserView;
      black: UserView;
      roomCode: string;
      gameId: string | null;
      result: GameResultJson | null;
    }[];
  }[];
  createdAt: string;
}

/** [tournament] with its creator, players (and users) and matches (and users) loaded. */
export function toTournamentView(tournament: Tournament): TournamentView {
  const players = [...tournament.players].sort((a, b) => b.score - a.score || a.seed - b.seed);
  const rounds = new Map<number, TournamentView['rounds'][number]>();
  const matches = [...tournament.matches].sort(
    (a, b) => a.round - b.round || a.white.username.localeCompare(b.white.username),
  );
  for (const match of matches) {
    const round = rounds.get(match.round) ?? { number: match.round, matches: [] };
    round.matches.push({
      id: match.id,
      white: toUserView(match.white),
      black: toUserView(match.black),
      roomCode: match.roomCode,
      gameId: match.gameId,
      result: match.resultJson,
    });
    rounds.set(match.round, round);
  }
  return {
    id: tournament.id,
    name: tournament.name,
    format: tournament.format,
    status: tournament.status,
    maxPlayers: tournament.maxPlayers,
    createdBy: toUserView(tournament.createdBy),
    players: players.map((player) => ({ user: toUserView(player.user), score: player.score })),
    rounds: [...rounds.values()],
    createdAt: tournament.createdAt.toISOString(),
  };
}
