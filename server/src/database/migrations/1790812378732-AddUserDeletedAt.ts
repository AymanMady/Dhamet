import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUserDeletedAt1790812378732 implements MigrationInterface {
  name = 'AddUserDeletedAt1790812378732';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" ADD "deletedAt" TIMESTAMP`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "deletedAt"`);
  }
}
