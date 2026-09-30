import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'node:crypto';
import { DataSource, IsNull, Repository } from 'typeorm';
import { SerialQueue } from '../common/serial-queue';
import { FinishedGame, GameLifecycleListener, StartedGame } from '../rooms/game-lifecycle';
import { GameplayService } from '../rooms/gameplay.service';
import { RoomsService } from '../rooms/rooms.service';
import { User } from '../users/user.entity';
import { CreateTournamentDto } from './dto/create-tournament.dto';
import { roundRobin } from './round-robin';
import { TournamentMatch } from './tournament-match.entity';
import { TournamentPlayer } from './tournament-player.entity';
import { Tournament } from './tournament.entity';
import { toTournamentView, TournamentView } from './tournament.view';

const RELATIONS = {
  createdBy: true,
  players: { user: true },
  matches: { white: true, black: true },
} as const;

/**
 * Tournaments. Only the round robin is implemented; the format is a field
 * so that other formats can be added. Every change goes through one queue,
 * so registrations, starts and results never interleave.
 */
@Injectable()
export class TournamentsService implements OnModuleInit, GameLifecycleListener {
  private readonly queue = new SerialQueue();

  constructor(
    @InjectRepository(Tournament) private readonly tournaments: Repository<Tournament>,
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly rooms: RoomsService,
    private readonly gameplay: GameplayService,
  ) {}

  onModuleInit(): void {
    this.gameplay.subscribe(this);
  }

  async create(user: User, dto: CreateTournamentDto): Promise<TournamentView> {
    if (dto.format !== 'roundRobin') {
      throw new BadRequestException(`Format "${dto.format}" is not implemented yet`);
    }
    const { id } = await this.tournaments.save(
      this.tournaments.create({
        name: dto.name,
        format: dto.format,
        status: 'registering',
        maxPlayers: dto.maxPlayers,
        createdById: user.id,
      }),
    );
    return this.view(id);
  }

  async list(): Promise<TournamentView[]> {
    const tournaments = await this.tournaments.find({
      relations: RELATIONS,
      order: { createdAt: 'DESC' },
    });
    return tournaments.map(toTournamentView);
  }

  async view(id: string): Promise<TournamentView> {
    return toTournamentView(await this.load(id));
  }

  /** Registers [user]; joining twice is harmless. */
  join(user: User, id: string): Promise<TournamentView> {
    return this.queue.run(async () => {
      const tournament = await this.load(id);
      if (tournament.players.some((player) => player.userId === user.id)) {
        return toTournamentView(tournament);
      }
      if (tournament.status !== 'registering') {
        throw new BadRequestException('Registrations are closed');
      }
      if (tournament.players.length >= tournament.maxPlayers) {
        throw new BadRequestException('The tournament is full');
      }
      await this.dataSource
        .getRepository(TournamentPlayer)
        .insert({ tournamentId: id, userId: user.id });
      return this.view(id);
    });
  }

  /**
   * Starts the tournament (creator only): generates every round and opens a
   * private rated room for each match.
   */
  start(user: User, id: string): Promise<TournamentView> {
    return this.queue.run(async () => {
      const tournament = await this.load(id);
      if (tournament.createdById !== user.id) {
        throw new ForbiddenException('Only the creator can start the tournament');
      }
      if (tournament.status !== 'registering') {
        throw new BadRequestException('The tournament has already started');
      }
      if (tournament.players.length < 2) {
        throw new BadRequestException('At least two players are needed');
      }
      const seeds = [...tournament.players]
        .sort((a, b) => a.seed - b.seed)
        .map((player) => player.user);
      const matches = this.dataSource.getRepository(TournamentMatch);
      const rounds = roundRobin(seeds);
      for (const [index, pairings] of rounds.entries()) {
        for (const { white, black } of pairings) {
          const matchId = randomUUID();
          const roomCode = await this.rooms.createForMatch(matchId, white, black);
          await matches.insert({
            id: matchId,
            tournamentId: id,
            round: index + 1,
            whiteId: white.id,
            blackId: black.id,
            roomCode,
            gameId: null,
            resultJson: null,
          });
        }
      }
      await this.tournaments.update(id, { status: 'running' });
      return this.view(id);
    });
  }

  async gameStarted(game: StartedGame): Promise<void> {
    const { tournamentMatchId } = game;
    if (!tournamentMatchId) return;
    await this.queue.run(() =>
      this.dataSource
        .getRepository(TournamentMatch)
        .update(tournamentMatchId, { gameId: game.gameId }),
    );
  }

  /** Records the result of a match: 1 point for a win, 0.5 for a draw. */
  async gameFinished(game: FinishedGame): Promise<void> {
    const { tournamentMatchId } = game;
    if (!tournamentMatchId) return;
    await this.queue.run(() =>
      this.dataSource.transaction(async (manager) => {
        const match = await manager.findOneBy(TournamentMatch, { id: tournamentMatchId });
        if (!match || match.resultJson) return;
        await manager.update(TournamentMatch, match.id, {
          gameId: game.gameId,
          resultJson: game.result,
        });
        const { winner } = game.result;
        const points = winner
          ? [{ userId: game.players[winner], score: 1 }]
          : [
              { userId: game.players.white, score: 0.5 },
              { userId: game.players.black, score: 0.5 },
            ];
        for (const { userId, score } of points) {
          await manager.increment(
            TournamentPlayer,
            { tournamentId: match.tournamentId, userId },
            'score',
            score,
          );
        }
        const pending = await manager.countBy(TournamentMatch, {
          tournamentId: match.tournamentId,
          resultJson: IsNull(),
        });
        if (pending === 0) {
          await manager.update(Tournament, match.tournamentId, { status: 'finished' });
        }
      }),
    );
  }

  private async load(id: string): Promise<Tournament> {
    const tournament = await this.tournaments.findOne({ where: { id }, relations: RELATIONS });
    if (!tournament) throw new NotFoundException('Tournament not found');
    return tournament;
  }
}
