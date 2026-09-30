import { Injectable } from '@nestjs/common';
import { WebSocket } from 'ws';
import { sendEvent } from './ws-message';

/** The open WebSocket connections of each authenticated user. */
@Injectable()
export class ConnectionRegistry {
  private readonly users = new Map<WebSocket, string>();
  private readonly sockets = new Map<string, Set<WebSocket>>();

  add(socket: WebSocket, userId: string): void {
    this.users.set(socket, userId);
    const sockets = this.sockets.get(userId) ?? new Set<WebSocket>();
    sockets.add(socket);
    this.sockets.set(userId, sockets);
  }

  /** Forgets [socket]. Returns its user if they have no connection left. */
  remove(socket: WebSocket): string | null {
    const userId = this.users.get(socket);
    if (userId === undefined) return null;
    this.users.delete(socket);
    const sockets = this.sockets.get(userId);
    sockets?.delete(socket);
    if (sockets?.size) return null;
    this.sockets.delete(userId);
    return userId;
  }

  userId(socket: WebSocket): string | undefined {
    return this.users.get(socket);
  }

  /** Sends an event to every connection of every user in [userIds]. */
  broadcast(userIds: Iterable<string>, event: string, data: unknown): void {
    for (const userId of userIds) {
      for (const socket of this.sockets.get(userId) ?? []) sendEvent(socket, event, data);
    }
  }
}
