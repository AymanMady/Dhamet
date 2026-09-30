import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { User } from '../users/user.entity';
import { AuthService } from './auth.service';

export type AuthenticatedRequest = Request & { user: User };

/** Requires `Authorization: Bearer <JWT>` and puts the user on the request. */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly auth: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const [scheme, token] = request.headers.authorization?.split(' ') ?? [];
    const user = scheme === 'Bearer' && token ? await this.auth.authenticate(token) : null;
    if (!user) throw new UnauthorizedException();
    request.user = user;
    return true;
  }
}
