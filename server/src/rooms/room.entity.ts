import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Color } from '../engine/engine.types';
import { User } from '../users/user.entity';
import { ClockState } from './game-clock';
import { TimeControl } from './time-control';

export type RoomStatus = 'waiting' | 'playing' | 'finished';

/** A player of a room. */
export interface RoomSeat {
  userId: string;
  color: Color;
  ready: boolean;
  /** As shown to the others: false once they have been told of a disconnection. */
  connected: boolean;
  /**
   * When the player's last connection closed, while the others are not told
   * yet (`DISCONNECT_NOTICE_SECONDS`); null otherwise.
   */
  leftAt: number | null;
  /** During a game, a disconnected player forfeits at this time unless they come back. */
  forfeitAt: number | null;
}

/**
 * A private room. The open rooms (`closedAt` null) are the live state of
 * the multiplayer server, shared by all its instances; closed ones are
 * history. A code is unique among the open rooms.
 */
@Entity('rooms')
@Index('IDX_rooms_open_code', ['code'], { unique: true, where: '"closedAt" IS NULL' })
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

  /** The players, host first. */
  @Column({ type: 'simple-json', default: '[]' })
  players!: RoomSeat[];

  /** User of each color, copied from [players] to find the rooms of a user. */
  @Index('IDX_rooms_whiteId')
  @Column({ type: 'uuid', nullable: true })
  whiteId!: string | null;

  @Index('IDX_rooms_blackId')
  @Column({ type: 'uuid', nullable: true })
  blackId!: string | null;

  /** The game of the room, from its start. */
  @Column({ type: 'uuid', nullable: true })
  gameId!: string | null;

  @Column({ type: 'simple-json', nullable: true })
  clock!: ClockState | null;

  /** The room closes at this time: a waiting room left empty, or a finished game. */
  @Column({ type: Date, nullable: true })
  expiresAt!: Date | null;

  /** The earliest time something must happen in the room, for the sweeps. */
  @Index('IDX_rooms_deadlineAt')
  @Column({ type: Date, nullable: true })
  deadlineAt!: Date | null;

  @Column({ type: Date, nullable: true })
  closedAt!: Date | null;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
