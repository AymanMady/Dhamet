import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomInt } from 'node:crypto';
import { User } from '../users/user.entity';
import { toUserView, UserView } from '../users/user.view';
import { UsersService } from '../users/users.service';
import { hashPassword, verifyPassword } from './password';

export interface AuthResponse {
  token: string;
  user: UserView;
}

interface TokenPayload {
  sub: string;
}

const GUEST_ALPHABET = 'abcdefghijklmnopqrstuvwxyz0123456789';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async register(username: string, password: string): Promise<AuthResponse> {
    const user = await this.users.create(username, await hashPassword(password), false);
    return this.respond(user);
  }

  async login(username: string, password: string): Promise<AuthResponse> {
    const user = await this.users.findByUsername(username);
    const valid = user && !user.isGuest && (await verifyPassword(password, user.passwordHash));
    if (!valid) throw new UnauthorizedException('Invalid username or password');
    return this.respond(user);
  }

  /** A guest account, named [username] or `invite_XXXX`. */
  async guest(username?: string): Promise<AuthResponse> {
    if (username) return this.respond(await this.users.create(username, '', true));
    for (let length = 4; ; length++) {
      for (let attempt = 0; attempt < 5; attempt++) {
        const name = `invite_${randomString(length)}`;
        if (!(await this.users.findByUsername(name))) {
          return this.respond(await this.users.create(name, '', true));
        }
      }
    }
  }

  /** The user a JWT belongs to, or null if it is invalid or expired. */
  userIdFromToken(token: string): string | null {
    try {
      return this.jwt.verify<TokenPayload>(token).sub;
    } catch {
      return null;
    }
  }

  /** The user a JWT belongs to, if the token is valid and the user exists. */
  async authenticate(token: string): Promise<User | null> {
    const id = this.userIdFromToken(token);
    return id ? this.users.findById(id) : null;
  }

  private respond(user: User): AuthResponse {
    const payload: TokenPayload = { sub: user.id };
    return { token: this.jwt.sign(payload), user: toUserView(user) };
  }
}

function randomString(length: number): string {
  let result = '';
  for (let i = 0; i < length; i++)
    result += GUEST_ALPHABET.charAt(randomInt(GUEST_ALPHABET.length));
  return result;
}
