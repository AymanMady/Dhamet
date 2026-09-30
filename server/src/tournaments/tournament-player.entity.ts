import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Tournament } from './tournament.entity';

@Entity('tournament_players')
@Unique(['tournamentId', 'userId'])
export class TournamentPlayer {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  tournamentId!: string;

  @ManyToOne(() => Tournament, (tournament) => tournament.players, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tournamentId' })
  tournament!: Tournament;

  @Column({ type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user!: User;

  /** 1 point per win, 0.5 per draw. */
  @Column({ type: 'real', default: 0 })
  score!: number;

  /** Registration order, which is also the seeding order. */
  @CreateDateColumn()
  joinedAt!: Date;
}
