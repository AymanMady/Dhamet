import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1790783329798 implements MigrationInterface {
  name = 'InitialSchema1790783329798';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "username" character varying(20) NOT NULL, "usernameKey" character varying(20) NOT NULL, "passwordHash" character varying(255) NOT NULL DEFAULT '', "isGuest" boolean NOT NULL DEFAULT false, "avatar" character varying(255), "rating" integer NOT NULL DEFAULT '1200', "wins" integer NOT NULL DEFAULT '0', "losses" integer NOT NULL DEFAULT '0', "draws" integer NOT NULL DEFAULT '0', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX "IDX_fddaf46b524fa6c88ac581ce8c" ON "users" ("usernameKey") `,
    );
    await queryRunner.query(
      `CREATE TABLE "games" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "roomCode" character varying(6) NOT NULL, "rated" boolean NOT NULL, "status" character varying(16) NOT NULL, "gameJson" text NOT NULL, "resultJson" text, "timeControl" text, "tournamentMatchId" uuid, "plyCount" integer NOT NULL DEFAULT '0', "startedAt" TIMESTAMP NOT NULL, "finishedAt" TIMESTAMP, CONSTRAINT "PK_c9b16b62917b5595af982d66337" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "game_players" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "gameId" uuid NOT NULL, "userId" uuid NOT NULL, "color" character varying(5) NOT NULL, "ratingBefore" integer NOT NULL, "ratingAfter" integer, CONSTRAINT "UQ_9a4deb5c0cabd6cd5af95b58754" UNIQUE ("gameId", "color"), CONSTRAINT "PK_a99af25a1c97122f04ba778197c" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_07c0d5e7c55181904b15137205" ON "game_players" ("userId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "moves" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "gameId" uuid NOT NULL, "ply" integer NOT NULL, "userId" uuid NOT NULL, "moveJson" text NOT NULL, "playedAt" TIMESTAMP NOT NULL, CONSTRAINT "UQ_555da4102eb9ae00a9b4b2574c7" UNIQUE ("gameId", "ply"), CONSTRAINT "PK_fcbf4e07f988d7d37d00e933133" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "rankings" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "userId" uuid NOT NULL, "gameId" uuid NOT NULL, "ratingBefore" integer NOT NULL, "ratingAfter" integer NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_05d87d598d485338c9980373d20" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_430fa616d89023b764c714fbcf" ON "rankings" ("userId") `,
    );
    await queryRunner.query(
      `CREATE TABLE "rooms" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "code" character varying(6) NOT NULL, "hostId" uuid NOT NULL, "status" character varying(16) NOT NULL, "rated" boolean NOT NULL, "timeControl" text, "tournamentMatchId" uuid, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_0368a2d7c215f2d0458a54933f2" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(`CREATE INDEX "IDX_368d83b661b9670e7be1bbb9cd" ON "rooms" ("code") `);
    await queryRunner.query(
      `CREATE TABLE "tournament_players" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "tournamentId" uuid NOT NULL, "userId" uuid NOT NULL, "score" real NOT NULL DEFAULT '0', "seed" integer NOT NULL, CONSTRAINT "UQ_18e079d7af71f7537f81f6864fb" UNIQUE ("tournamentId", "userId"), CONSTRAINT "PK_f6d9adf041fd0f856fd78734994" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "tournaments" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "name" character varying(60) NOT NULL, "format" character varying(20) NOT NULL, "status" character varying(16) NOT NULL, "maxPlayers" integer NOT NULL, "createdById" uuid NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_6d5d129da7a80cf99e8ad4833a9" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "tournament_matches" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "tournamentId" uuid NOT NULL, "round" integer NOT NULL, "whiteId" uuid NOT NULL, "blackId" uuid NOT NULL, "roomCode" character varying(6) NOT NULL, "gameId" uuid, "resultJson" text, CONSTRAINT "PK_b128bcced13707fbc4ac1519216" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_8b729ff23b080160ff0cc4a2b5" ON "tournament_matches" ("tournamentId") `,
    );
    await queryRunner.query(
      `ALTER TABLE "game_players" ADD CONSTRAINT "FK_66d478167a4c11e2ad1ba74e52f" FOREIGN KEY ("gameId") REFERENCES "games"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "game_players" ADD CONSTRAINT "FK_07c0d5e7c55181904b151372052" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "moves" ADD CONSTRAINT "FK_56ec01a71f76da6fca3509439d6" FOREIGN KEY ("gameId") REFERENCES "games"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "moves" ADD CONSTRAINT "FK_6cf9a20a4462fdd70569d2dee3c" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "rankings" ADD CONSTRAINT "FK_430fa616d89023b764c714fbcf5" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "rankings" ADD CONSTRAINT "FK_71223493bc7d2b1608dec9eacfe" FOREIGN KEY ("gameId") REFERENCES "games"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "rooms" ADD CONSTRAINT "FK_6c939085068c5539bad393be6b9" FOREIGN KEY ("hostId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_players" ADD CONSTRAINT "FK_97c7b74185fba6e51ba4eddb8cd" FOREIGN KEY ("tournamentId") REFERENCES "tournaments"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_players" ADD CONSTRAINT "FK_65bfd7187c411726f6d908bf368" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournaments" ADD CONSTRAINT "FK_5ff236c228350de491d16d3a78d" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_matches" ADD CONSTRAINT "FK_8b729ff23b080160ff0cc4a2b5f" FOREIGN KEY ("tournamentId") REFERENCES "tournaments"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_matches" ADD CONSTRAINT "FK_4892dd2e29702015e1c4c565700" FOREIGN KEY ("whiteId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_matches" ADD CONSTRAINT "FK_df256b97f2f35f7c015ff654fe0" FOREIGN KEY ("blackId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "tournament_matches" DROP CONSTRAINT "FK_df256b97f2f35f7c015ff654fe0"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_matches" DROP CONSTRAINT "FK_4892dd2e29702015e1c4c565700"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_matches" DROP CONSTRAINT "FK_8b729ff23b080160ff0cc4a2b5f"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournaments" DROP CONSTRAINT "FK_5ff236c228350de491d16d3a78d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_players" DROP CONSTRAINT "FK_65bfd7187c411726f6d908bf368"`,
    );
    await queryRunner.query(
      `ALTER TABLE "tournament_players" DROP CONSTRAINT "FK_97c7b74185fba6e51ba4eddb8cd"`,
    );
    await queryRunner.query(`ALTER TABLE "rooms" DROP CONSTRAINT "FK_6c939085068c5539bad393be6b9"`);
    await queryRunner.query(
      `ALTER TABLE "rankings" DROP CONSTRAINT "FK_71223493bc7d2b1608dec9eacfe"`,
    );
    await queryRunner.query(
      `ALTER TABLE "rankings" DROP CONSTRAINT "FK_430fa616d89023b764c714fbcf5"`,
    );
    await queryRunner.query(`ALTER TABLE "moves" DROP CONSTRAINT "FK_6cf9a20a4462fdd70569d2dee3c"`);
    await queryRunner.query(`ALTER TABLE "moves" DROP CONSTRAINT "FK_56ec01a71f76da6fca3509439d6"`);
    await queryRunner.query(
      `ALTER TABLE "game_players" DROP CONSTRAINT "FK_07c0d5e7c55181904b151372052"`,
    );
    await queryRunner.query(
      `ALTER TABLE "game_players" DROP CONSTRAINT "FK_66d478167a4c11e2ad1ba74e52f"`,
    );
    await queryRunner.query(`DROP INDEX "public"."IDX_8b729ff23b080160ff0cc4a2b5"`);
    await queryRunner.query(`DROP TABLE "tournament_matches"`);
    await queryRunner.query(`DROP TABLE "tournaments"`);
    await queryRunner.query(`DROP TABLE "tournament_players"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_368d83b661b9670e7be1bbb9cd"`);
    await queryRunner.query(`DROP TABLE "rooms"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_430fa616d89023b764c714fbcf"`);
    await queryRunner.query(`DROP TABLE "rankings"`);
    await queryRunner.query(`DROP TABLE "moves"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_07c0d5e7c55181904b15137205"`);
    await queryRunner.query(`DROP TABLE "game_players"`);
    await queryRunner.query(`DROP TABLE "games"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_fddaf46b524fa6c88ac581ce8c"`);
    await queryRunner.query(`DROP TABLE "users"`);
  }
}
