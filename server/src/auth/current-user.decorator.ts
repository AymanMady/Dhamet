import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { User } from '../users/user.entity';
import { AuthenticatedRequest } from './jwt-auth.guard';

/** The user authenticated by `JwtAuthGuard`. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): User =>
    context.switchToHttp().getRequest<AuthenticatedRequest>().user,
);
