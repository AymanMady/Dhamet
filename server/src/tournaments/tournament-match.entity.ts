import { Column, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { GameResultJson } from '../engine/engine.types';
import { User } from '../users/user.entity';
import { Tournament } from './tournament.entity';

@Entity('tournament_matches')
export class TournamentMatch {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ type: 'uuid' })
  tournamentId!: string;

  @ManyToOne(() => Tournament, (tournament) => tournament.matches, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tournamentId' })
  tournament!: Tournament;

  /** 1-based round number. */
  @Column({ type: 'integer' })
  round!: number;

  @Column({ type: 'uuid' })
  whiteId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'whiteId' })
  white!: User;

  @Column({ type: 'uuid' })
  blackId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'blackId' })
  black!: User;

  @Column({ type: 'varchar', length: 6 })
  roomCode!: string;

  /** Set when the game of the match starts. */
  @Column({ type: 'uuid', nullable: true })
  gameId!: string | null;

  @Column({ type: 'simple-json', nullable: true })
  resultJson!: GameResultJson | null;
}
