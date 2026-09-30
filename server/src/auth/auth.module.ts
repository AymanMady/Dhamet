import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppConfig, appConfig } from '../config/app.config';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

/** Global so that any controller can use `JwtAuthGuard`. */
@Global()
@Module({
  imports: [
    UsersModule,
    JwtModule.registerAsync({
      inject: [appConfig.KEY],
      useFactory: (settings: AppConfig) => ({
        secret: settings.jwt.secret,
        signOptions: { expiresIn: settings.jwt.expiresInSeconds },
      }),
    }),
    ThrottlerModule.forRootAsync({
      inject: [appConfig.KEY],
      useFactory: (settings: AppConfig) => ({
        throttlers: [
          { ttl: settings.authThrottle.ttlSeconds * 1000, limit: settings.authThrottle.limit },
        ],
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard],
  exports: [AuthService, JwtAuthGuard],
})
export class AuthModule {}
