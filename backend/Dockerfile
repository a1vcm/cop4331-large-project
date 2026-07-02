# syntax=docker/dockerfile:1
FROM node:22-alpine AS base
WORKDIR /app
COPY package*.json ./

# --- Dev: full deps + nodemon hot reload (source is bind-mounted by compose) ---
FROM base AS dev
RUN npm ci
COPY . .
ENV PORT=5001
EXPOSE 5001
CMD ["npm", "run", "dev"]

# --- Prod: production deps only, non-root ---
FROM base AS prod
ENV NODE_ENV=production
RUN npm ci --omit=dev
COPY . .
USER node
ENV PORT=5001
EXPOSE 5001
CMD ["node", "server.js"]
