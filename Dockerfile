FROM node:18.20.0-alpine3.19 AS base

WORKDIR /app
RUN npm install -g pnpm
RUN apk add --no-cache python3 make g++

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/server ./packages/server
COPY packages/webapp ./packages/webapp

RUN mkdir -p ./packages/server/static/upload

RUN pnpm install
RUN pnpm build:server
RUN pnpm build:webapp

# ================= RUNNER =================
FROM node:18.20.0-alpine3.19 AS runner

WORKDIR /app
RUN npm install -g pnpm
RUN apk add --no-cache python3 make g++

COPY --from=base /app/packages/webapp/out ./static
COPY --from=base /app/packages/server/resources ./resources
COPY --from=base /app/packages/server/view ./view
COPY --from=base /app/packages/server/static ./static
COPY --from=base /app/packages/server/src ./src
COPY --from=base /app/packages/server/tsconfig.json ./tsconfig.json
COPY --from=base /app/packages/server/package.json ./package.json

# ✅ THIS is where the UI comes from
COPY --from=base /app/packages/webapp/dist ./static

RUN pnpm install --prod

EXPOSE 9157
CMD ["npm", "start"]
