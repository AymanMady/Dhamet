import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { TimeControl } from './time-control';

export type RoomStatus = 'waiting' | 'playing' | 'finished';

/**
 * History of the rooms. Active rooms live in memory (`RoomStore`); a room
 * code is only unique among active rooms.
 */
@Entity('rooms')
export class Room {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ type: 'varchar', length: 6 })
  code!: string;

  @Column({ type: 'uuid' })
  hostId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'hostId' })
  host!: User;

  @Column({ type: 'varchar', length: 16 })
  status!: RoomStatus;

  @Column({ type: 'boolean' })
  rated!: boolean;

  @Column({ type: 'simple-json', nullable: true })
  timeControl!: TimeControl | null;

  @Column({ type: 'uuid', nullable: true })
  tournamentMatchId!: string | null;

  @CreateDateColumn()
  createdAt!: Date;
}
