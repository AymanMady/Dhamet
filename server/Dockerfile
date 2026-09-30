# Build from the repository root (the engine lives in packages/):
#   docker build -f server/Dockerfile .
# or `docker compose --profile api up --build` from server/.

# 1. The rules engine, from Dart to JavaScript.
FROM dart:3.13 AS engine
WORKDIR /src
COPY packages/dhamet_engine packages/dhamet_engine
COPY server/engine_bridge server/engine_bridge
WORKDIR /src/server/engine_bridge
RUN dart pub get && dart run tool/build.dart /out/dhamet_engine.js

# 2. The NestJS application.
FROM node:22-alpine AS build
WORKDIR /app
COPY server/package.json server/package-lock.json ./
RUN npm ci
COPY server/nest-cli.json server/tsconfig.json server/tsconfig.build.json ./
COPY server/src src
COPY --from=engine /out/dhamet_engine.js src/engine/generated/dhamet_engine.js
# --ignore-scripts: the engine is already built (no Dart SDK in this stage).
RUN npm run build --ignore-scripts && npm prune --omit=dev

# 3. Runtime.
FROM node:22-alpine
ENV NODE_ENV=production TZ=UTC
WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules node_modules
COPY --from=build /app/dist dist
USER node
EXPOSE 3000
CMD ["node", "dist/main"]
