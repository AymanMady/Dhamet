import { WsAdapter } from '@nestjs/platform-ws';
import { MessageMappingProperties } from '@nestjs/websockets';
import { Observable, of } from 'rxjs';

interface Envelope {
  event: string;
  data?: unknown;
}

function isEnvelope(message: unknown): message is Envelope {
  return (
    typeof message === 'object' &&
    message !== null &&
    typeof (message as { event?: unknown }).event === 'string'
  );
}

function error(code: string, message: string, event: string | null): Observable<unknown> {
  return of({ event: 'error', data: { code, message, event } });
}

/**
 * The `ws` adapter, answering `INVALID_MESSAGE` to frames that are not JSON
 * `{event, data}` or name an unknown event (the stock adapter drops them).
 */
export class DhametWsAdapter extends WsAdapter {
  override bindMessageHandler(
    buffer: { data: unknown },
    handlers: Map<string, MessageMappingProperties>,
    transform: (data: unknown) => Observable<unknown>,
  ): Observable<unknown> {
    let message: unknown;
    try {
      message = JSON.parse(String(buffer.data));
    } catch {
      return error('INVALID_MESSAGE', 'Messages must be JSON', null);
    }
    if (!isEnvelope(message)) {
      return error('INVALID_MESSAGE', 'Expected {"event": string, "data": object}', null);
    }
    const handler = handlers.get(message.event);
    if (!handler) {
      return error('INVALID_MESSAGE', `Unknown event "${message.event}"`, message.event);
    }
    try {
      return transform(handler.callback(message.data, message.event));
    } catch (thrown) {
      // Handler errors normally reach WsErrorFilter; a synchronous throw here
      // would otherwise end the message stream of this client.
      this.logger.error(thrown);
      return error('INTERNAL_ERROR', 'Internal server error', message.event);
    }
  }
}
