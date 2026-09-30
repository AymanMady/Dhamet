import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import { GameJson, GameResultJson } from '../engine/engine.types';
import { TimeControl } from '../rooms/time-control';
import { GamePlayer } from './game-player.entity';

export type GameStatus = 'playing' | 'finished' | 'aborted';

@Entity('games')
export class Game {
  /** Also the key of the game in the engine while it is played. */
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 6 })
  roomCode!: string;

  /** Whether the result changes ratings: a rated room between two accounts. */
  @Column({ type: 'boolean' })
  rated!: boolean;

  @Column({ type: 'varchar', length: 16 })
  status!: GameStatus;

  /** The engine `Game` JSON, saved after every move. */
  @Column({ type: 'simple-json' })
  gameJson!: GameJson;

  @Column({ type: 'simple-json', nullable: true })
  resultJson!: GameResultJson | null;

  @Column({ type: 'simple-json', nullable: true })
  timeControl!: TimeControl | null;

  @Column({ type: 'uuid', nullable: true })
  tournamentMatchId!: string | null;

  @Column({ type: 'integer', default: 0 })
  plyCount!: number;

  @Column({ type: Date })
  startedAt!: Date;

  @Column({ type: Date, nullable: true })
  finishedAt!: Date | null;

  @OneToMany(() => GamePlayer, (player) => player.game)
  players!: GamePlayer[];
}
