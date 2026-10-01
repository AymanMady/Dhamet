import { IsNull, Repository } from 'typeorm';
import { User } from './user.entity';
import { UsersService } from './users.service';

describe('UsersService account deletion', () => {
  /** Lower-case names already in the table. */
  let taken: (name: string) => boolean;
  const repository = {
    findOneBy: jest.fn(({ usernameKey }: { usernameKey: string }) =>
      Promise.resolve(taken(usernameKey) ? new User() : null),
    ),
    update: jest.fn().mockResolvedValue(undefined),
    findOneByOrFail: jest.fn().mockResolvedValue(new User()),
  };
  const users = new UsersService(repository as unknown as Repository<User>);

  beforeEach(() => {
    jest.clearAllMocks();
    taken = () => false;
  });

  it('renames the account deleted_XXXX and erases its personal data', async () => {
    await users.delete('u1');
    expect(repository.update).toHaveBeenCalledTimes(1);
    const [criteria, changes] = repository.update.mock.calls[0] as [object, Partial<User>];
    // A second deletion changes nothing.
    expect(criteria).toEqual({ id: 'u1', deletedAt: IsNull() });
    expect(changes).toEqual({
      username: expect.stringMatching(/^deleted_[a-z0-9]{4}$/),
      usernameKey: changes.username,
      passwordHash: '',
      avatar: null,
      deletedAt: expect.any(Date),
    });
  });

  it('takes a longer name when the short ones are taken', async () => {
    taken = (name) => name.length === 'deleted_'.length + 4;
    expect(await users.unusedUsername('deleted_')).toMatch(/^deleted_[a-z0-9]{5}$/);
    expect(repository.findOneBy).toHaveBeenCalledTimes(6);
  });
});
