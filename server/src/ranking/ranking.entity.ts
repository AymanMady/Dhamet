import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Game } from '../games/game.entity';
import { User } from '../users/user.entity';

/** One rating change of a user, after a rated game. */
@Entity('rankings')
export class Ranking {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user!: User;

  @Column({ type: 'uuid' })
  gameId!: string;

  @ManyToOne(() => Game, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'gameId' })
  game!: Game;

  @Column({ type: 'integer' })
  ratingBefore!: number;

  @Column({ type: 'integer' })
  ratingAfter!: number;

  @CreateDateColumn()
  createdAt!: Date;
}
