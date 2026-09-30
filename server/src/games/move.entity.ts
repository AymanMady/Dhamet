import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, Unique } from 'typeorm';
import { MoveJson } from '../engine/engine.types';
import { User } from '../users/user.entity';
import { Game } from './game.entity';

@Entity('moves')
@Unique(['gameId', 'ply'])
export class Move {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  gameId!: string;

  @ManyToOne(() => Game, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'gameId' })
  game!: Game;

  /** Number of moves played after this one (1 for the first move). */
  @Column({ type: 'integer' })
  ply!: number;

  @Column({ type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user!: User;

  /** The engine's `Move` JSON. */
  @Column({ type: 'simple-json' })
  moveJson!: MoveJson;

  /** Server time of the move. */
  @Column({ type: Date })
  playedAt!: Date;
}
