#!/bin/bash
# Pulls the latest images, recreates containers whose image changed and removes old images.
# If you want to keep the old images, remove or comment out the last line.
# Run manually or via the ezarr-update systemd timer (see server/README.md).
# The user running this must be in the "docker" group.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

docker compose pull
docker compose up -d --remove-orphans
docker image prune -f
