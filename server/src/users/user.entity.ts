import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

export const INITIAL_RATING = 1200;

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** As chosen by the user (3–20 characters among `[A-Za-z0-9_]`). */
  @Column({ type: 'varchar', length: 20 })
  username!: string;

  /** Lower-case [username]: makes names unique regardless of case. */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 20 })
  usernameKey!: string;

  /** scrypt hash; empty for a guest, who has no password. */
  @Column({ type: 'varchar', length: 255, default: '' })
  passwordHash!: string;

  @Column({ type: 'boolean', default: false })
  isGuest!: boolean;

  @Column({ type: 'varchar', length: 255, nullable: true })
  avatar!: string | null;

  @Column({ type: 'integer', default: INITIAL_RATING })
  rating!: number;

  @Column({ type: 'integer', default: 0 })
  wins!: number;

  @Column({ type: 'integer', default: 0 })
  losses!: number;

  @Column({ type: 'integer', default: 0 })
  draws!: number;

  @CreateDateColumn()
  createdAt!: Date;
}
