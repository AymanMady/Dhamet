import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { TournamentMatch } from './tournament-match.entity';
import { TournamentPlayer } from './tournament-player.entity';

export const TOURNAMENT_FORMATS = ['roundRobin', 'singleElimination'] as const;

export type TournamentFormat = (typeof TOURNAMENT_FORMATS)[number];

export type TournamentStatus = 'registering' | 'running' | 'finished';

@Entity('tournaments')
export class Tournament {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 60 })
  name!: string;

  @Column({ type: 'varchar', length: 20 })
  format!: TournamentFormat;

  @Column({ type: 'varchar', length: 16 })
  status!: TournamentStatus;

  @Column({ type: 'integer' })
  maxPlayers!: number;

  @Column({ type: 'uuid' })
  createdById!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'createdById' })
  createdBy!: User;

  @OneToMany(() => TournamentPlayer, (player) => player.tournament)
  players!: TournamentPlayer[];

  @OneToMany(() => TournamentMatch, (match) => match.tournament)
  matches!: TournamentMatch[];

  @CreateDateColumn()
  createdAt!: Date;
}
