# ezarr

## Source

This project is based on [Luctia/ezarr](https://github.com/Luctia/ezarr) — a project that aims to make it as easy as possible to set up an entire Servarr/Jackett/BitTorrent/Usenet/Plex/Jellyfin media center stack using Docker.

## Server configuration

Host-level config for the Ubuntu server (systemd units etc.) lives in [`server/`](server/README.md). Containers are updated automatically every day by the `ezarr-update` systemd timer.
