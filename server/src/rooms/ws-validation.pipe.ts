import { ValidationError, ValidationPipe } from '@nestjs/common';
import { GameError } from './game-error';

function describe(errors: ValidationError[], parent = ''): string[] {
  return errors.flatMap((error) => {
    const path = parent ? `${parent}.${error.property}` : error.property;
    return [
      ...Object.values(error.constraints ?? {}).map((text) => text.replace(error.property, path)),
      ...describe(error.children ?? [], path),
    ];
  });
}

/** Validates WebSocket payloads; a bad payload is refused with INVALID_MESSAGE. */
export const wsValidationPipe = new ValidationPipe({
  whitelist: true,
  transform: true,
  exceptionFactory: (errors) => new GameError('INVALID_MESSAGE', describe(errors).join('; ')),
});
