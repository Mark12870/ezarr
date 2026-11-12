#!/bin/bash
# Installs the host-level (Ubuntu server) configuration kept in this repo.
# Run on the media server from inside the ezarr checkout:  ./server/install.sh
set -euo pipefail

EZARR_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
RUN_USER="${SUDO_USER:-$USER}"

echo "Installing ezarr server config (dir: $EZARR_DIR, user: $RUN_USER)"

# --- Automatic Docker container updates (systemd timer) ---
for unit in ezarr-update.service ezarr-update.timer; do
  sed -e "s|@EZARR_DIR@|$EZARR_DIR|g" -e "s|@USER@|$RUN_USER|g" \
    "$EZARR_DIR/server/systemd/$unit" | sudo tee "/etc/systemd/system/$unit" >/dev/null
done
chmod +x "$EZARR_DIR/update_containers.sh"
sudo systemctl daemon-reload
sudo systemctl enable --now ezarr-update.timer
systemctl list-timers ezarr-update.timer --no-pager
