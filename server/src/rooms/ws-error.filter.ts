import { ArgumentsHost, Catch, ExceptionFilter, Logger } from '@nestjs/common';
import { WebSocket } from 'ws';
import { GameError } from './game-error';
import { sendEvent } from './ws-message';

/** Sends every failure of a WebSocket handler back as `{event: "error", data: {code, message, event}}`. */
@Catch()
export class WsErrorFilter implements ExceptionFilter {
  private readonly logger = new Logger('WebSocket');

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToWs();
    let error: GameError;
    if (exception instanceof GameError) {
      error = exception;
    } else {
      this.logger.error(exception);
      error = new GameError('INTERNAL_ERROR', 'Internal server error');
    }
    sendEvent(context.getClient<WebSocket>(), 'error', {
      code: error.code,
      message: error.message,
      event: context.getPattern(),
    });
  }
}
