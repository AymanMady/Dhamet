import { User } from './user.entity';

/** The public representation of a user (`user` in docs/multiplayer.md). */
export interface UserView {
  id: string;
  username: string;
  isGuest: boolean;
  rating: number;
  wins: number;
  losses: number;
  draws: number;
  gamesPlayed: number;
  createdAt: string;
}

export function toUserView(user: User): UserView {
  return {
    id: user.id,
    username: user.username,
    isGuest: user.isGuest,
    rating: user.rating,
    wins: user.wins,
    losses: user.losses,
    draws: user.draws,
    gamesPlayed: user.wins + user.losses + user.draws,
    createdAt: user.createdAt.toISOString(),
  };
}
