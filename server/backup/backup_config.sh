#!/bin/bash
# Backs up the app configs (ROOT_DIR/config) and .env into ONE archive, replacing the
# previous one: <ROOT_DIR>/data/media/.ezarr-backup/ezarr-config.tar.zst (root-only).
# With a separate media disk (see server/README.md) the backup survives a system disk failure.
# Running containers are stopped during the copy so the app databases are consistent
# (usually under a minute), then started again - also when the backup fails.
# Run as root, via the ezarr-backup systemd timer (see server/README.md).
set -euo pipefail
umask 077
EZARR_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
cd "$EZARR_DIR"

ROOT_DIR="$({ grep -E '^ROOT_DIR=' .env || true; } | tail -n1 | cut -d= -f2- | sed -E "s/^[\"'](.*)[\"']\$/\1/")"
[ -n "$ROOT_DIR" ] || { echo "ROOT_DIR missing in .env" >&2; exit 1; }
ROOT_DIR="$(realpath -m "$ROOT_DIR")"
DEST_DIR="$ROOT_DIR/data/media/.ezarr-backup"
DEST="$DEST_DIR/ezarr-config.tar.zst"
TMP="$DEST.partial"

mkdir -p "$DEST_DIR"; chmod 700 "$DEST_DIR"
rm -f "$TMP"

RUNNING="$(docker compose ps -q --status running)"
start_again() { if [ -n "$RUNNING" ]; then docker start $RUNNING >/dev/null; fi; }
trap 'rm -f "$TMP"; start_again' EXIT

if [ -n "$RUNNING" ]; then docker stop $RUNNING >/dev/null; fi
# Caches and transcodes are rebuilt by Jellyfin; leave them out.
tar --zstd -cf "$TMP" \
  --exclude='config/jellyfin-config/cache' \
  --exclude='config/jellyfin-config/.cache' \
  --exclude='config/jellyfin-config/transcodes' \
  -C "$ROOT_DIR" config \
  -C "$EZARR_DIR" .env
trap 'rm -f "$TMP"' EXIT
start_again

tar --zstd -tf "$TMP" >/dev/null   # archive readable?
mv -f "$TMP" "$DEST"               # replaces the previous backup only once the new one is complete
trap - EXIT
echo "Backup written: $DEST ($(du -h "$DEST" | cut -f1))"
