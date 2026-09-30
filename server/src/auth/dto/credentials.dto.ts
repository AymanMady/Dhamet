import { IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export const USERNAME_PATTERN = /^[A-Za-z0-9_]{3,20}$/;
const USERNAME_MESSAGE = 'username must be 3 to 20 characters among A-Z, a-z, 0-9 and _';

export class CredentialsDto {
  @IsString()
  @Matches(USERNAME_PATTERN, { message: USERNAME_MESSAGE })
  username!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}

export class GuestDto {
  @IsOptional()
  @IsString()
  @Matches(USERNAME_PATTERN, { message: USERNAME_MESSAGE })
  username?: string;
}
