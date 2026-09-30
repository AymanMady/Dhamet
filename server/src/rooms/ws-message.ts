import { WebSocket } from 'ws';

/** Sends `{event, data}` to [socket] if it is open. */
export function sendEvent(socket: WebSocket, event: string, data: unknown): void {
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ event, data }));
}
