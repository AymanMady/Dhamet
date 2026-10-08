import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'node:crypto';
import { EntityManager, IsNull, MoreThan, Repository } from 'typeorm';
import { Color, GameResultJson, opponentOf } from '../engine/engine.types';
import { TransactionRunner, Tx } from '../realtime/transactions';
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

/** The lock key of the tournaments: their changes never interleave. */
const TOURNAMENTS_KEY = 'tournaments';

/**
 * Tournaments. Only the round robin is implemented; the format is a field
 * so that other formats can be added. Every change holds one lock, on every
 * instance of the server, so registrations, starts and results never
 * interleave.
 */
@Injectable()
export class TournamentsService implements OnModuleInit, GameLifecycleListener {
  constructor(
    @InjectRepository(Tournament) private readonly tournaments: Repository<Tournament>,
    private readonly runner: TransactionRunner,
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
    return toTournamentView(await this.load(this.tournaments.manager, id));
  }

  /** Registers [user]; joining twice is harmless. */
  join(user: User, id: string): Promise<TournamentView> {
    return this.runner.run(TOURNAMENTS_KEY, async ({ manager }) => {
      const tournament = await this.load(manager, id);
      if (tournament.players.some((player) => player.userId === user.id)) {
        return toTournamentView(tournament);
      }
      if (tournament.status !== 'registering') {
        throw new BadRequestException('Registrations are closed');
      }
      if (tournament.players.length >= tournament.maxPlayers) {
        throw new BadRequestException('The tournament is full');
      }
      await manager.insert(TournamentPlayer, {
        tournamentId: id,
        userId: user.id,
        seed: tournament.players.length + 1,
      });
      return toTournamentView(await this.load(manager, id));
    });
  }

  /**
   * Starts the tournament (creator only): generates every round and opens a
   * private rated room for each match.
   */
  start(user: User, id: string): Promise<TournamentView> {
    return this.runner.run(TOURNAMENTS_KEY, async (tx) => {
      const { manager } = tx;
      const tournament = await this.load(manager, id);
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
      const rounds = roundRobin(seeds);
      for (const [index, pairings] of rounds.entries()) {
        for (const { white, black } of pairings) {
          const matchId = randomUUID();
          const roomCode = await this.rooms.createForMatch(tx, matchId, white, black);
          await manager.insert(TournamentMatch, {
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
      await manager.update(Tournament, id, { status: 'running' });
      return toTournamentView(await this.load(manager, id));
    });
  }

  /** In the transaction of the room of the match. */
  async gameStarted(tx: Tx, game: StartedGame): Promise<void> {
    const { tournamentMatchId } = game;
    if (!tournamentMatchId) return;
    await tx.lock(TOURNAMENTS_KEY);
    await tx.manager.update(TournamentMatch, tournamentMatchId, { gameId: game.gameId });
  }

  /**
   * Records the result of a match: 1 point for a win, 0.5 for a draw. In
   * the transaction of the room of the match.
   */
  async gameFinished(tx: Tx, game: FinishedGame): Promise<void> {
    const { tournamentMatchId } = game;
    if (!tournamentMatchId) return;
    await tx.lock(TOURNAMENTS_KEY);
    const match = await tx.manager.findOneBy(TournamentMatch, { id: tournamentMatchId });
    if (!match || match.resultJson) return;
    await this.recordResult(tx.manager, match, game.gameId, game.result, game.players);
  }

  /**
   * The account of [userId] is being deleted. Its registrations to the
   * tournaments not started yet are removed, and so are the tournaments not
   * started yet that it created (nobody else could start them). Its matches
   * without a result, in running tournaments, are lost by resignation, as
   * when a player does not come back: `RoomsService.leaveAll` has resigned
   * its game in progress and closed the rooms of the others.
   */
  withdraw(userId: string): Promise<void> {
    return this.runner.run(TOURNAMENTS_KEY, async ({ manager }) => {
      const created = await manager.findBy(Tournament, {
        createdById: userId,
        status: 'registering',
      });
      for (const tournament of created) {
        await manager.delete(TournamentPlayer, { tournamentId: tournament.id });
        await manager.delete(Tournament, tournament.id);
      }
      const registrations = await manager.findBy(TournamentPlayer, {
        userId,
        tournament: { status: 'registering' },
      });
      for (const registration of registrations) {
        await manager.delete(TournamentPlayer, registration.id);
        // Seeds stay 1, 2, 3…: the registration order.
        await manager.decrement(
          TournamentPlayer,
          { tournamentId: registration.tournamentId, seed: MoreThan(registration.seed) },
          'seed',
          1,
        );
      }
      const pending = await manager.findBy(TournamentMatch, [
        { whiteId: userId, resultJson: IsNull() },
        { blackId: userId, resultJson: IsNull() },
      ]);
      for (const match of pending) {
        const winner = opponentOf(match.whiteId === userId ? 'white' : 'black');
        await this.recordResult(
          manager,
          match,
          match.gameId,
          { winner, reason: 'resignation' },
          { white: match.whiteId, black: match.blackId },
        );
      }
    });
  }

  /** Saves the result of [match] and the points, and finishes the tournament after its last match. */
  private async recordResult(
    manager: EntityManager,
    match: TournamentMatch,
    gameId: string | null,
    result: GameResultJson,
    players: Record<Color, string>,
  ): Promise<void> {
    await manager.update(TournamentMatch, match.id, { gameId, resultJson: result });
    const { winner } = result;
    const points = winner
      ? [{ userId: players[winner], score: 1 }]
      : [
          { userId: players.white, score: 0.5 },
          { userId: players.black, score: 0.5 },
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
  }

  private async load(manager: EntityManager, id: string): Promise<Tournament> {
    const tournament = await manager.findOne(Tournament, { where: { id }, relations: RELATIONS });
    if (!tournament) throw new NotFoundException('Tournament not found');
    return tournament;
  }
}
