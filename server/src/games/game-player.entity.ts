import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Color } from '../engine/engine.types';
import { User } from '../users/user.entity';
import { Game } from './game.entity';

@Entity('game_players')
@Unique(['gameId', 'color'])
export class GamePlayer {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  gameId!: string;

  @ManyToOne(() => Game, (game) => game.players, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'gameId' })
  game!: Game;

  @Index()
  @Column({ type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user!: User;

  @Column({ type: 'varchar', length: 5 })
  color!: Color;

  @Column({ type: 'integer' })
  ratingBefore!: number;

  /** Null until a rated game ends; stays null for unrated games. */
  @Column({ type: 'integer', nullable: true })
  ratingAfter!: number | null;
}
