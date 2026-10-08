import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Open rooms move from memory to the database, so that several instances
 * of the server can share them (Vercel).
 */
export class SharedRooms1791600000000 implements MigrationInterface {
  name = 'SharedRooms1791600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "rooms" ADD "players" text NOT NULL DEFAULT '[]'`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "whiteId" uuid`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "blackId" uuid`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "gameId" uuid`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "clock" text`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "expiresAt" TIMESTAMP`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "deadlineAt" TIMESTAMP`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "closedAt" TIMESTAMP`);
    await queryRunner.query(`ALTER TABLE "rooms" ADD "updatedAt" TIMESTAMP NOT NULL DEFAULT now()`);
    // The rooms and games of the previous server lived in its memory: what
    // the table holds is history.
    await queryRunner.query(`UPDATE "rooms" SET "status" = 'finished', "closedAt" = "createdAt"`);
    await queryRunner.query(
      `UPDATE "games" SET "status" = 'aborted', "finishedAt" = now() WHERE "status" = 'playing'`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_rooms_open_code" ON "rooms" ("code") WHERE "closedAt" IS NULL`,
    );
    await queryRunner.query(`CREATE INDEX "IDX_rooms_whiteId" ON "rooms" ("whiteId") `);
    await queryRunner.query(`CREATE INDEX "IDX_rooms_blackId" ON "rooms" ("blackId") `);
    await queryRunner.query(`CREATE INDEX "IDX_rooms_deadlineAt" ON "rooms" ("deadlineAt") `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "public"."IDX_rooms_deadlineAt"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_rooms_blackId"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_rooms_whiteId"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_rooms_open_code"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "updatedAt"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "closedAt"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "deadlineAt"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "expiresAt"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "clock"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "gameId"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "blackId"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "whiteId"`);
    await queryRunner.query(`ALTER TABLE "rooms" DROP COLUMN "players"`);
  }
}
