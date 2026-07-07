# cop4331-large-project

A course-review website with a mobile app companion, built with the MERN stack for COP4331 at UCF.

| App | Stack | Path |
|---|---|---|
| Web frontend | React 19 + Vite | [`frontend/`](frontend/) |
| API backend | Express 5 + MongoDB (Mongoose) | [`backend/`](backend/) |
| Mobile app | Flutter 3.44 | [`mobile/`](mobile/) |

## Local development

Prerequisite: [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```bash
docker compose up --build
```

That starts everything with hot reload:

- **Frontend** → http://localhost:5173 (Vite HMR; edits to `frontend/src` reload instantly)
- **Backend** → http://localhost:5001 (nodemon; also proxied at http://localhost:5173/api/*)
- **MongoDB** → mongodb://localhost:27017 (data persists in the `mongo_data_dev` volume)

Frontend code should always call the API with **relative** URLs (`axios.get('/api/...')`).
Vite proxies `/api` to the backend in dev; nginx does the same in production. Never hardcode
a backend hostname or use a `VITE_API_URL`.

To seed the database while the stack is running:

```bash
cd backend && node seed.js        # uses MONGODB_URI, defaults to localhost:27017
```

Running without Docker also works (`npm run dev` in `backend/` and `frontend/`), but you'll
need your own MongoDB and a `backend/.env` (copy [`backend/.env.example`](backend/.env.example)).

> Hot-reload not triggering under Docker? Set `CHOKIDAR_USEPOLLING=true` on the frontend
> service, or change the backend dev script to `nodemon -L`.

## Tests & linting

| | Lint | Test |
|---|---|---|
| `frontend/` | `npm run lint` (ESLint) | `npm test` (Vitest + React Testing Library) |
| `backend/` | `npm run lint` (ESLint) | `npm test` (Jest + Supertest — needs Mongo running, e.g. `docker compose up mongo`) |
| `mobile/` | `flutter analyze` | `flutter test` |

## CI (GitHub Actions)

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every PR and push to `main`:

- **frontend** — ESLint, Vitest, production build
- **backend** — ESLint, Jest (against a MongoDB service container)
- **mobile** — `flutter analyze`, `flutter test`, release APK build (downloadable from the
  workflow run's **Artifacts** as `app-release-apk`)

Jobs are path-filtered: a mobile-only PR skips the web jobs and vice versa. The **`ci-ok`**
summary job always runs — set it as the *only* required status check in branch protection.

## Deployment (CD)

[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) runs on every push to `main`:

1. Builds the production Docker images and pushes them to GHCR
   (`ghcr.io/a1vcm/cop4331-large-project-backend` / `-frontend`).
2. SSHes into the DigitalOcean droplet, copies [`deploy/docker-compose.prod.yml`](deploy/docker-compose.prod.yml)
   to `/var/www/cop4331-large-project/deploy/`, pulls the new images, and restarts the containers.

Production runs four containers on the droplet: nginx (serves the React build, terminates
HTTPS, proxies `/api` to the backend), the Express backend, MongoDB (data in the `mongo_data`
volume, **not** exposed to the internet), and certbot (auto-renews the Let's Encrypt cert).

### One-time droplet setup

1. `scp deploy/setup-server.sh root@DROPLET_IP:` and run `bash setup-server.sh` on the droplet
   (installs Docker, configures UFW, creates `/var/www/cop4331-large-project/deploy/.env`, logs in to GHCR).
2. Edit `/var/www/cop4331-large-project/deploy/.env` — set `DOMAIN` and a strong `JWT_SECRET`.
3. Point the domain's DNS **A record** at the droplet IP (`dig +short YOUR_DOMAIN` to verify).
4. Add the GitHub Actions secrets below, then push to `main` (or copy
   `deploy/docker-compose.prod.yml` + `deploy/init-letsencrypt.sh` to `/var/www/cop4331-large-project/deploy` manually).
5. On the droplet: `cd /var/www/cop4331-large-project/deploy && bash init-letsencrypt.sh` — bootstraps the first
   Let's Encrypt certificate. After this, renewals are automatic.

### GitHub Actions secrets (repo → Settings → Secrets and variables → Actions)

| Secret | Value |
|---|---|
| `DO_HOST` | Droplet public IP (or hostname) |
| `DO_USER` | SSH user, e.g. `root` |
| `DO_SSH_KEY` | Private SSH key whose public half is in the droplet's `~/.ssh/authorized_keys` |
| `DO_SSH_PORT` | Only if SSH isn't on port 22 |

Runtime secrets (`DOMAIN`, `JWT_SECRET`) live only in `/var/www/cop4331-large-project/deploy/.env` on the droplet —
deploys never overwrite that file.

> **GHCR note:** the first image push creates the packages as *private*. Either keep them
> private (the setup script's `docker login` handles droplet pulls) or make them public in
> each package's settings on GitHub. If a later Actions push gets a 403, open the package
> settings and grant the repository **Actions** write access.
