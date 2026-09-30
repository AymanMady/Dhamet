import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, QueryFailedError, Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly users: Repository<User>) {}

  findById(id: string): Promise<User | null> {
    return this.users.findOneBy({ id });
  }

  async getById(id: string): Promise<User> {
    const user = await this.findById(id);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  findByIds(ids: string[]): Promise<User[]> {
    return this.users.findBy({ id: In(ids) });
  }

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

  /** Registered accounts (not guests), best rating first. */
  leaderboard(limit: number, offset: number): Promise<User[]> {
    return this.users.find({
      where: { isGuest: false },
      order: { rating: 'DESC', createdAt: 'ASC', id: 'ASC' },
      take: limit,
      skip: offset,
    });
  }
}
