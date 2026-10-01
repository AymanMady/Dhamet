import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomInt } from 'node:crypto';
import { IsNull, QueryFailedError, Repository } from 'typeorm';
import { User } from './user.entity';

const NAME_ALPHABET = 'abcdefghijklmnopqrstuvwxyz0123456789';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly users: Repository<User>) {}

  /** The account [id], unless it was deleted. */
  findById(id: string): Promise<User | null> {
    return this.users.findOneBy({ id, deletedAt: IsNull() });
  }

  async getById(id: string): Promise<User> {
    const user = await this.findById(id);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  /** Deleted accounts included: their anonymous names stay taken. */
  findByUsername(username: string): Promise<User | null> {
    return this.users.findOneBy({ usernameKey: username.toLowerCase() });
  }

  /**
   * Creates an account. Throws a 409 if [username] is taken, whatever its
   * case.
   */
  async create(username: string, passwordHash: string, isGuest: boolean): Promise<User> {
    if (await this.findByUsername(username)) throw new ConflictException('Username already taken');
    try {
      return await this.users.save(
        this.users.create({ username, usernameKey: username.toLowerCase(), passwordHash, isGuest }),
      );
    } catch (error) {
      // Two registrations of the same name at once: the unique index decides.
      if (error instanceof QueryFailedError) throw new ConflictException('Username already taken');
      throw error;
    }
  }

  /** A free name: [prefix] and 4 characters among `[a-z0-9]`, more after collisions. */
  async unusedUsername(prefix: string): Promise<string> {
    for (let length = 4; ; length++) {
      for (let attempt = 0; attempt < 5; attempt++) {
        const name = `${prefix}${randomString(length)}`;
        if (!(await this.findByUsername(name))) return name;
      }
    }
  }

  /**
   * Deletes the account [id]: its name becomes `deleted_XXXX`, which frees
   * the old one, its password and avatar are erased, and [findById] no
   * longer finds it. Returns the anonymized account.
   */
  async delete(id: string): Promise<User> {
    const username = await this.unusedUsername('deleted_');
    await this.users.update(
      { id, deletedAt: IsNull() },
      {
        username,
        usernameKey: username.toLowerCase(),
        passwordHash: '',
        avatar: null,
        deletedAt: new Date(),
      },
    );
    return this.users.findOneByOrFail({ id });
  }

  /** Registered accounts (not guests, not deleted), best rating first. */
  leaderboard(limit: number, offset: number): Promise<User[]> {
    return this.users.find({
      where: { isGuest: false, deletedAt: IsNull() },
      order: { rating: 'DESC', createdAt: 'ASC', id: 'ASC' },
      take: limit,
      skip: offset,
    });
  }
}

function randomString(length: number): string {
  let result = '';
  for (let i = 0; i < length; i++) result += NAME_ALPHABET.charAt(randomInt(NAME_ALPHABET.length));
  return result;
}
