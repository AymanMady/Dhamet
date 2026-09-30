import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { AuthResponse, AuthService } from './auth.service';
import { CredentialsDto, GuestDto } from './dto/credentials.dto';

@Controller('auth')
@UseGuards(ThrottlerGuard)
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() dto: CredentialsDto): Promise<AuthResponse> {
    return this.auth.register(dto.username, dto.password);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: CredentialsDto): Promise<AuthResponse> {
    return this.auth.login(dto.username, dto.password);
  }

  @Post('guest')
  guest(@Body() dto: GuestDto): Promise<AuthResponse> {
    return this.auth.guest(dto.username);
  }
}
