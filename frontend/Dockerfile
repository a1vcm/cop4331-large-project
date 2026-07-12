# syntax=docker/dockerfile:1
FROM node:22-alpine AS base
WORKDIR /app
COPY package*.json ./

# --- Dev: Vite dev server with HMR (source is bind-mounted by compose) ---
FROM base AS dev
RUN npm ci
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]

# --- Build: produce the static bundle ---
FROM base AS build
RUN npm ci
COPY . .
RUN npm run build

# --- Prod: nginx serves the bundle and reverse-proxies /api to the backend ---
FROM nginx:1.27-alpine AS prod
# nginx's docker-entrypoint runs envsubst on *.template files (fills ${DOMAIN})
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80 443
