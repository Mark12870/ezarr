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

Useful commands:

```bash
systemctl list-timers ezarr-update.timer      # next/last run
sudo systemctl start ezarr-update.service     # update now
journalctl -u ezarr-update.service            # logs
```
