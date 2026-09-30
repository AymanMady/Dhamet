import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsString, Length, Max, Min } from 'class-validator';
import { TOURNAMENT_FORMATS, TournamentFormat } from '../tournament.entity';

export class CreateTournamentDto {
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Length(1, 60)
  name!: string;

  @IsIn(TOURNAMENT_FORMATS)
  format!: TournamentFormat;

  @IsInt()
  @Min(2)
  @Max(16)
  maxPlayers!: number;
}
