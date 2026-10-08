import { Injectable } from '@nestjs/common';
import { WebSocket } from 'ws';
import { sendEvent } from './ws-message';

/** Close code for a missing or invalid token, or a deleted account. */
export const WS_UNAUTHENTICATED = 4401;

/**
 * The WebSocket connections held by this instance, by user. Other
 * instances hold the others: events reach them through the realtime bus.
 */
@Injectable()
export class ConnectionRegistry {
  private readonly users = new Map<WebSocket, string>();
  private readonly sockets = new Map<string, Set<WebSocket>>();
  private readonly listeners: ((count: number) => void)[] = [];

  add(socket: WebSocket, userId: string): void {
    this.users.set(socket, userId);
    const sockets = this.sockets.get(userId) ?? new Set<WebSocket>();
    sockets.add(socket);
    this.sockets.set(userId, sockets);
    this.changed();
  }

  /** Forgets [socket]. Returns its user if they have no connection left here. */
  remove(socket: WebSocket): string | null {
    const userId = this.users.get(socket);
    if (userId === undefined) return null;
    this.users.delete(socket);
    const sockets = this.sockets.get(userId);
    sockets?.delete(socket);
    const gone = !sockets?.size;
    if (gone) this.sockets.delete(userId);
    this.changed();
    return gone ? userId : null;
  }

  userId(socket: WebSocket): string | undefined {
    return this.users.get(socket);
  }

  /** Users with a connection here. */
  userIds(): string[] {
    return [...this.sockets.keys()];
  }

  /** Whether one of [userIds] has a connection here. */
  hasAny(userIds: Iterable<string>): boolean {
    for (const userId of userIds) if (this.sockets.has(userId)) return true;
    return false;
  }

  /** Called with the number of connections whenever it changes. */
  onChange(listener: (count: number) => void): void {
    this.listeners.push(listener);
  }

  /** Closes every connection of [userId] here with code 4401; they are forgotten once closed. */
  closeAll(userId: string): void {
    for (const socket of this.sockets.get(userId) ?? []) {
      socket.close(WS_UNAUTHENTICATED, 'Unauthenticated');
    }
  }

  /** Sends an event to the connections, here, of every user in [userIds]. */
  broadcast(userIds: Iterable<string>, event: string, data: unknown): void {
    for (const userId of userIds) {
      for (const socket of this.sockets.get(userId) ?? []) sendEvent(socket, event, data);
    }
  }

  private changed(): void {
    for (const listener of this.listeners) listener(this.users.size);
  }
}
