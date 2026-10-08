import { randomInt } from 'node:crypto';

/** No I, O, 0 or 1, which are easily confused. */
export const ROOM_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export const ROOM_CODE_LENGTH = 6;

const MAX_ATTEMPTS = 100;

export function generateRoomCode(random: (max: number) => number = randomInt): string {
  let code = '';
  for (let i = 0; i < ROOM_CODE_LENGTH; i++) {
    code += ROOM_CODE_ALPHABET.charAt(random(ROOM_CODE_ALPHABET.length));
  }
  return code;
}

/** A code for which [isTaken] is false. With 32^6 ≈ 10^9 codes, a retry is rare. */
export async function uniqueRoomCode(
  isTaken: (code: string) => Promise<boolean>,
  random: (max: number) => number = randomInt,
): Promise<string> {
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const code = generateRoomCode(random);
    if (!(await isTaken(code))) return code;
  }
  throw new Error('No free room code found');
}
