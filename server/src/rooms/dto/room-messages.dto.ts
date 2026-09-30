import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class TimeControlDto {
  @IsNumber()
  @Min(0.1)
  @Max(3 * 3600)
  initialSeconds!: number;

  @IsNumber()
  @Min(0)
  @Max(600)
  incrementSeconds!: number;
}

export class CreateRoomDto {
  @IsOptional()
  @IsIn(['white', 'black', 'random'])
  color?: 'white' | 'black' | 'random';

  @IsOptional()
  @IsBoolean()
  rated?: boolean;

  @IsOptional()
  @ValidateNested()
  @Type(() => TimeControlDto)
  timeControl?: TimeControlDto | null;
}

/** `{code}`; codes are case-insensitive for the client. */
export class RoomCodeDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(16)
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  code!: string;
}

export class ReadyDto extends RoomCodeDto {
  @IsBoolean()
  ready!: boolean;
}

export class MoveDto extends RoomCodeDto {
  /** Number of moves already played, as seen by the client. */
  @IsInt()
  @Min(0)
  ply!: number;

  /** A `Move` JSON, checked by the engine. */
  @IsObject()
  move!: Record<string, unknown>;
}
