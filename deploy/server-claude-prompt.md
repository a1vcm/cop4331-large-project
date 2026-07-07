# Prompt for the Claude Code instance on the DigitalOcean droplet

Fill in the two values in step 0, then paste everything below into Claude Code on the server.

---

Set up this DigitalOcean droplet to host the COP4331 project (repo: github.com/a1vcm/cop4331-large-project). The app deploys via GitHub Actions: images come from GHCR, and the stack is run with docker compose from /opt/poost. Do the following, verifying each step before moving on:

0. Values for this setup (I'm filling these in before sending):
   - DOMAIN: <cop4331-summer2026-17.xyz>
   - LETSENCRYPT_EMAIL: <YOUR_EMAIL_HERE> (optional, for cert expiry notices)

1. **Docker**: If `docker` is not installed, install it with `curl -fsSL https://get.docker.com | sh`, then `systemctl enable --now docker`. Verify with `docker compose version`.

2. **Firewall**: With UFW, allow `OpenSSH`, `80/tcp`, and `443/tcp`, then `ufw --force enable`. Do NOT rely on UFW to protect container ports — Docker-published ports bypass it. Never publish MongoDB's port 27017.

3. **App directory**: Create `/opt/poost`. Get the files `deploy/docker-compose.prod.yml` and `deploy/init-letsencrypt.sh` from the repo into `/opt/poost/` (clone the repo to a temp dir, or `gh repo clone a1vcm/cop4331-large-project` if it's private and gh is authenticated; only those two files need to end up in /opt/poost). Make init-letsencrypt.sh executable.

4. **Environment file**: Create `/opt/poost/.env` (skip if it already exists and looks correct) containing:
   - `DOMAIN=` the domain from step 0
   - `JWT_SECRET=` generate one with `openssl rand -hex 32`
   - `LETSENCRYPT_EMAIL=` the email from step 0 (omit the line if none given)
   Set permissions to 600.

5. **Deploy SSH key for GitHub Actions**: Generate a dedicated keypair with `ssh-keygen -t ed25519 -f /root/.ssh/github-actions-deploy -N "" -C "github-actions-deploy"`. Append the public key to `/root/.ssh/authorized_keys`. Then print, clearly labeled, what I need to paste into the GitHub repo's Actions secrets:
   - `DO_HOST` = this droplet's public IP (get it with `curl -4 -s ifconfig.me`)
   - `DO_USER` = the user you set this up for (e.g. root)
   - `DO_SSH_KEY` = the full contents of the PRIVATE key file `/root/.ssh/github-actions-deploy`

6. **GHCR access**: Try `docker pull ghcr.io/a1vcm/cop4331-large-project-backend:latest`. If it fails with a denied/auth error, the packages are private (or don't exist yet): ask me for a GitHub classic PAT with the `read:packages` scope and run `docker login ghcr.io` with it. If the pull fails with "not found"/manifest errors even after login, the images haven't been pushed yet — tell me to push to main first (the Deploy workflow builds them), and pause here until I confirm.

7. **DNS check**: Compare `dig +short $DOMAIN` against the droplet's public IP. If they don't match, stop and tell me to fix the A record — do NOT proceed to step 8 (Let's Encrypt will fail and rate-limit us).

8. **First TLS certificate**: Only after steps 6 and 7 pass: `cd /opt/poost && bash init-letsencrypt.sh`. This creates a temporary self-signed cert, starts nginx, obtains the real Let's Encrypt cert via the HTTP-01 challenge, and reloads nginx. If you want a dry run first, run it as `STAGING=1 bash init-letsencrypt.sh`, then delete the staging cert artifacts and run it again for real.

9. **Bring up the full stack and verify**:
   - `cd /opt/poost && docker compose -f docker-compose.prod.yml up -d`
   - `docker compose -f docker-compose.prod.yml ps` — all containers healthy/running
   - `curl -s https://$DOMAIN/api/health` returns `{"status":"ok",...}`
   - `curl -s -o /dev/null -w '%{http_code}' http://$DOMAIN` returns 301
   - Confirm port 27017 is NOT reachable externally: `docker compose -f docker-compose.prod.yml port mongo 27017` should return nothing.

10. **Report**: Summarize what was done, print the three GitHub secret values (mark the private key clearly), and list anything that still needs my action.

Notes:
- Everything here is idempotent-safe to re-run except certificate issuance — never re-request certs in a loop (Let's Encrypt rate limits: 5 per week per domain).
- Don't edit docker-compose.prod.yml on the server; it gets overwritten by every deploy. Config belongs in /opt/poost/.env.
