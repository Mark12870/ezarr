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
| `storage/media.mount` | `/etc/systemd/system/<escaped ROOT_DIR/data/media>.mount` | Mounts the media disk (ext4, label `ezarr-media`) at `ROOT_DIR/data/media`. Installed only if a filesystem with that label exists; never mounts over a non-empty folder. |
| `storage/docker-wait-media.conf` | `/etc/systemd/system/docker.service.d/50-ezarr-media.conf` | Docker starts only with the media disk mounted, so containers never see an empty library. |
| `smartd/smartd.conf` | `/etc/smartd.conf` (package `smartmontools`) | Disk health monitoring: short self-test daily 02:00, long self-test Saturday 03:00, temperature warnings. Findings in `journalctl -u smartmontools`. |

Network changes are not applied live (the interface rename would drop the connection); reboot after installing.

### Media disk

`data/media` (the library) lives on its own disk; `data/torrents` stays on the system disk.
Sonarr/Radarr then copy finished downloads into the library instead of hardlinking (different
filesystems); the torrent copy is removed after seeding by "Remove Completed".

Preparing a new media disk (erases it; replace `/dev/sdX`):

```bash
sudo sgdisk --zap-all /dev/sdX && sudo sgdisk -n1:0:0 -t1:8300 -c1:ezarr-media /dev/sdX
sudo mkfs.ext4 -L ezarr-media -m 0 -T largefile -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdX1
```

`-T largefile` keeps the inode tables small and `lazy_*_init=0` writes them during mkfs instead of
in the background later. Both matter on SMR drives, which slow down badly on scattered writes.

Then move the contents of `ROOT_DIR/data/media` onto it (Docker stopped), leave the folder
empty and run `./server/install.sh`, which mounts the disk there.

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
