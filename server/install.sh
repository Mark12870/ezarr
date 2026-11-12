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

# --- Network: fixed WiFi name, ethernet optional, boot waits for WiFi ---
# No credentials here: the WiFi connection (SSID/password) stays in the server's own
# netplan file, under the key "wifi0" (see server/README.md).
# Not applied live (renaming the interface would drop the connection); takes effect on reboot.
NETDIR="$EZARR_DIR/server/network"
LINK_DST=/etc/systemd/network/10-ezarr-wifi.link
YAML_DST=/etc/netplan/90-ezarr.yaml
WAIT_DST=/etc/systemd/system/systemd-networkd-wait-online.service.d/50-ezarr-wifi.conf
NET_CHANGED=0

install_if_changed() {  # <src> <dst> <mode>
  if ! sudo cmp -s "$1" "$2"; then
    sudo install -D -m "$3" -o root -g root "$1" "$2"
    echo "Installed $2"
    NET_CHANGED=1
  fi
}

# Ethernet optional: safe on its own (the boot just stops waiting for the ethernet link).
install_if_changed "$NETDIR/90-ezarr.yaml" "$YAML_DST" 600

# The rename to wifi0 is only safe if the server's netplan already configures "wifi0",
# otherwise WiFi would have no config after reboot. Only top-level keys are read (no secrets printed).
WIFI_KEYS="$(sudo netplan get wifis 2>/dev/null | { grep -E '^[^ #][^:]*:' || true; } | cut -d: -f1 | tr '\n' ' ')"
if echo " $WIFI_KEYS " | grep -q " wifi0 "; then
  install_if_changed "$NETDIR/10-ezarr-wifi.link" "$LINK_DST" 644
  install_if_changed "$NETDIR/wait-online-wifi.conf" "$WAIT_DST" 644
  OTHER_WIFI="$(echo "$WIFI_KEYS" | tr ' ' '\n' | { grep -vE '^(wifi0)?$' || true; } | tr '\n' ' ')"
  if [ -n "$OTHER_WIFI" ]; then
    echo "!! netplan still defines other WiFi entries: $OTHER_WIFI- remove them (see server/README.md)"
  fi
else
  echo "!! netplan has no WiFi entry 'wifi0' (found: ${WIFI_KEYS:-none})."
  echo "!! Skipping the WiFi rename. Do the one-time manual step in server/README.md, then re-run this script."
  if [ -f "$LINK_DST" ]; then
    echo "!! DANGER: $LINK_DST is installed but netplan has no 'wifi0' - WiFi will NOT work after reboot!"
  fi
fi

if [ "$NET_CHANGED" = 1 ]; then
  sudo netplan generate
  sudo systemctl daemon-reload
  if [ -f "$LINK_DST" ]; then
    echo "== Name the WiFi card will get on next boot (expect wifi0): =="
    for dev in /sys/class/net/*; do
      [ -d "$dev/wireless" ] || continue
      sudo udevadm test-builtin net_setup_link "$dev" 2>&1 | grep -E "ID_NET_LINK_FILE=|ID_NET_NAME=|NAME=" || true
    done
  fi
  echo ">> Network config changed. Reboot to activate it (sudo reboot)."
else
  echo "Network config up to date"
fi
