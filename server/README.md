# Server configuration

Host-level config for the Ubuntu media server, so it can be reproduced from this repo.

Install everything with:

```bash
./server/install.sh
```

## Contents

| Path | Installs to | Purpose |
|------|-------------|---------|
| `systemd/ezarr-update.service` | `/etc/systemd/system/` | Runs `update_containers.sh` (pull, recreate, prune) |
| `systemd/ezarr-update.timer` | `/etc/systemd/system/` | Triggers the update daily at ~04:00 (catches up after downtime) |
| `network/10-ezarr-wifi.link` | `/etc/systemd/network/` | Fixed WiFi interface name `wifi0` (PCI-based `wlp<N>s0` names change when hardware is added). Installed only if netplan defines `wifi0`. |
| `network/90-ezarr.yaml` | `/etc/netplan/` (mode 600) | Overlay: onboard ethernet `optional`, so the boot doesn't wait for it when no cable is connected. Merged with the server's own netplan files. |
| `network/wait-online-wifi.conf` | `/etc/systemd/system/systemd-networkd-wait-online.service.d/50-ezarr-wifi.conf` | Boot waits (max 60 s) for `wifi0`, so Docker starts with network. Netplan itself only waits for wired links. |

Network changes are not applied live (the interface rename would drop the connection); reboot after installing.

### WiFi connection: intentionally not in this repo

The WiFi credentials (SSID/password) live only in the server's own netplan file
(`/etc/netplan/*.yaml`), not here. The repo only expects that the WiFi entry there is
named `wifi0`.

One-time manual step (new install, or when migrating from the old `wlp*` names):

```bash
sudo cp -a /etc/netplan /root/netplan-backup-$(date +%F)   # backup
sudoedit /etc/netplan/<file-with-wifi>.yaml
```

Under `wifis:`, rename the active `wlp…:` entry to `wifi0:` and delete any other
`wlp*:` WiFi entries. Leave the access point and password as they are. Then run
`./server/install.sh` and reboot.

If WiFi does not come up after reboot: plug in an ethernet cable (DHCP), then restore the
backup into `/etc/netplan/` and remove `/etc/systemd/network/10-ezarr-wifi.link`.

Useful commands:

```bash
systemctl list-timers ezarr-update.timer      # next/last run
sudo systemctl start ezarr-update.service     # update now
journalctl -u ezarr-update.service            # logs
```
