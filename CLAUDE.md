# ezarr

Docker Compose media stack (based on [Luctia/ezarr](https://github.com/Luctia/ezarr)).

## Server configuration must live in this repo

The goal is to be able to reproduce the Ubuntu server's configuration from this repo.

- Never make one-off config changes directly on the server. Every host-level config (systemd units, cron, apt/unattended-upgrades, sysctl, etc.) goes into `server/`.
- Installation is handled by `server/install.sh` (idempotent; fills in paths/user). Extend it for every new config.
- Document each config in the table in `server/README.md`.

## NEVER commit sensitive data

Be extremely careful: never add secrets or sensitive data to the repo, not even temporarily or in an example.

- This includes passwords, API keys, tokens, VPN credentials/keys (gluetun), private keys, cookies, `.env` contents, app databases/configs containing credentials (e.g. `homarr/`, appdata), and personal info.
- Secrets belong in `.env` (gitignored); commit only placeholders in `.env.example`.
- When copying configs from the server, check them for secrets first and replace them with variables/placeholders.
- Before every commit, review `git diff --cached` for secrets. If anything sensitive is ever committed or pushed, stop and tell the user immediately. The secret then has to be rotated, and removing it in a later commit is not enough.
