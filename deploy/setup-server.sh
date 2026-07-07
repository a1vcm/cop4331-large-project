#!/bin/bash
# One-time (idempotent) bootstrap for the DigitalOcean droplet.
# Run as root (or with sudo):  bash setup-server.sh
#
# Installs Docker, configures the firewall, creates /var/www/cop4331-large-project/deploy with a .env
# template, and logs in to GHCR so the droplet can pull the private images.

set -euo pipefail

APP_DIR=/var/www/cop4331-large-project/deploy

echo "==> 1/4 Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
else
  echo "    docker already installed: $(docker --version)"
fi
systemctl enable --now docker

echo "==> 2/4 Firewall (UFW)"
if command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  echo "    NOTE: Docker-published ports bypass UFW. The prod compose file only"
  echo "    publishes 80/443 on the frontend; never add a ports: mapping to mongo."
else
  echo "    ufw not found, skipping (configure your firewall manually: allow 22, 80, 443)"
fi

echo "==> 3/4 App directory + .env"
mkdir -p "$APP_DIR"
if [ ! -f "$APP_DIR/.env" ]; then
  cat > "$APP_DIR/.env" <<'EOF'
# Production runtime config — EDIT THESE VALUES
DOMAIN=example.com
JWT_SECRET=change-me-to-a-long-random-string
EOF
  echo "    Created $APP_DIR/.env — EDIT IT NOW (domain + JWT secret)."
else
  echo "    $APP_DIR/.env already exists, leaving it alone."
fi

echo "==> 4/4 GHCR login (for pulling private images)"
if docker pull ghcr.io/a1vcm/cop4331-large-project-backend:latest >/dev/null 2>&1; then
  echo "    Already able to pull images, skipping login."
else
  echo "    Create a GitHub classic PAT with the read:packages scope"
  echo "    (github.com -> Settings -> Developer settings -> Personal access tokens),"
  echo "    then log in (username = your GitHub username, password = the PAT):"
  docker login ghcr.io
fi

cat <<'EOF'

Done. Remaining manual steps:
  1. Edit /var/www/cop4331-large-project/deploy/.env  (DOMAIN, JWT_SECRET)
  2. Point your domain's DNS A record at this droplet's public IP
     (verify with: dig +short YOUR_DOMAIN)
  3. Add the GitHub Actions secrets (DO_HOST, DO_USER, DO_SSH_KEY) to the repo,
     then push to main so the first deploy copies the compose file here — or
     copy deploy/docker-compose.prod.yml + deploy/init-letsencrypt.sh to /var/www/cop4331-large-project/deploy yourself.
  4. Run:  cd /var/www/cop4331-large-project/deploy && bash init-letsencrypt.sh   (first-time TLS certificate)
EOF
