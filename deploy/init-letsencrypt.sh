#!/bin/bash
# First-time Let's Encrypt certificate bootstrap (idempotent).
# Run from /opt/poost AFTER: .env is filled in, DNS points at this droplet,
# and docker-compose.prod.yml is present.
#
# Solves the chicken-and-egg problem: nginx won't start without cert files,
# but certbot needs nginx running to answer the HTTP-01 challenge. We create a
# temporary self-signed cert, start nginx, get the real cert, then reload.

set -euo pipefail
cd "$(dirname "$0")"

COMPOSE="docker compose -f docker-compose.prod.yml"

# shellcheck disable=SC1091
source .env
DOMAIN="${DOMAIN:?Set DOMAIN in .env first}"
EMAIL="${LETSENCRYPT_EMAIL:-}"   # optional: set LETSENCRYPT_EMAIL in .env for expiry notices
STAGING="${STAGING:-0}"          # STAGING=1 bash init-letsencrypt.sh -> use LE staging (no rate limits)

LIVE_PATH="/etc/letsencrypt/live/$DOMAIN"

# A renewal config only exists after a real (non-dummy) certbot issuance
if $COMPOSE run --rm --entrypoint sh certbot -c "[ -f '/etc/letsencrypt/renewal/$DOMAIN.conf' ]"; then
  echo "A Let's Encrypt certificate for $DOMAIN already exists. Nothing to do."
  exit 0
fi

echo "==> Creating temporary self-signed certificate for $DOMAIN"
$COMPOSE run --rm --entrypoint sh certbot -c "\
  mkdir -p '$LIVE_PATH' && \
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout '$LIVE_PATH/privkey.pem' \
    -out '$LIVE_PATH/fullchain.pem' \
    -subj '/CN=$DOMAIN'"

echo "==> Starting nginx"
$COMPOSE up -d frontend

echo "==> Requesting real certificate from Let's Encrypt"
EMAIL_ARG="--register-unsafely-without-email"
[ -n "$EMAIL" ] && EMAIL_ARG="--email $EMAIL --no-eff-email"
STAGING_ARG=""
[ "$STAGING" = "1" ] && STAGING_ARG="--staging"

# Delete the dummy cert so certbot can claim the live path
$COMPOSE run --rm --entrypoint sh certbot -c "\
  rm -rf '/etc/letsencrypt/live/$DOMAIN' '/etc/letsencrypt/archive/$DOMAIN' '/etc/letsencrypt/renewal/$DOMAIN.conf'"

$COMPOSE run --rm certbot certonly --webroot -w /var/www/certbot \
  $STAGING_ARG $EMAIL_ARG --agree-tos -d "$DOMAIN" \
  || { echo "Certificate request FAILED (is DNS pointing here? port 80 open?)"; exit 1; }

echo "==> Reloading nginx with the real certificate"
$COMPOSE exec frontend nginx -s reload

echo "Done. https://$DOMAIN should now be live."
