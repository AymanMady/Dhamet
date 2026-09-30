import {
  generateRoomCode,
  ROOM_CODE_ALPHABET,
  ROOM_CODE_LENGTH,
  uniqueRoomCode,
} from './room-code';

describe('room codes', () => {
  it('use 32 unambiguous characters', () => {
    expect(ROOM_CODE_ALPHABET).toHaveLength(32);
    expect(new Set(ROOM_CODE_ALPHABET).size).toBe(32);
    for (const confusing of ['I', 'O', '0', '1'])
      expect(ROOM_CODE_ALPHABET).not.toContain(confusing);
  });

  it('are 6 characters from the alphabet', () => {
    expect(ROOM_CODE_LENGTH).toBe(6);
    for (let i = 0; i < 500; i++) {
      expect(generateRoomCode()).toMatch(/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/);
    }
  });

  it('can produce every character', () => {
    const seen = new Set<string>();
    for (let i = 0; i < 2000; i++) for (const char of generateRoomCode()) seen.add(char);
    expect(seen).toEqual(new Set(ROOM_CODE_ALPHABET));
  });

  it('are drawn from the given random source', () => {
    expect(generateRoomCode(() => 0)).toBe('AAAAAA');
    expect(generateRoomCode((max) => max - 1)).toBe('999999');
  });

  it('skip the codes already taken', () => {
    const sequence = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1];
    let index = 0;
    const random = (): number => sequence[index++] ?? 2;
    expect(uniqueRoomCode((code) => code === 'AAAAAA', random)).toBe('BBBBBB');
  });

  it('give up when no code is free', () => {
    expect(() => uniqueRoomCode(() => true)).toThrow('No free room code found');
  });
});
