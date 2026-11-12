# ezarr

Docker Compose media stack (based on [Luctia/ezarr](https://github.com/Luctia/ezarr)).

## Server configuration lives in this repo

Goal: the Ubuntu server's configuration is reproducible from this repo.

- Every host-level config (systemd units, cron, apt/unattended-upgrades, sysctl, network, etc.) goes into `server/` and reaches the server only through `server/install.sh`. The script is idempotent and fills in paths/user; extend it for each new config.
- Give each config a row in the table in `server/README.md`.

## Secrets

Secrets stay out of the repo, in every commit, including examples and temporary ones.

- A **secret** is: passwords, API keys, tokens, VPN credentials/keys (gluetun), private keys, cookies, `.env` contents, app databases/configs holding credentials (e.g. `homarr/`, appdata), and personal info.
- Secrets live in `.env` (gitignored); `.env.example` carries placeholders.
- Configs copied from the server: replace secrets with variables/placeholders before they enter the repo.
- Before every commit, read `git diff --cached` for secrets.
- If a secret ever reaches a commit or push: stop and tell the user immediately. It must be rotated; a later removal commit leaves it in history.
