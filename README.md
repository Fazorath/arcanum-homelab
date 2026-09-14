# Arcanum

A self-hosted home server running 15+ containerized services on a repurposed laptop,
reachable from anywhere despite sitting behind carrier-grade NAT on a managed apartment
network I don't control.

This repo is the documentation and configuration for that system — the architecture, the
constraints that shaped it, and write-ups of the failures I had to diagnose along the way.

## Why

I wanted local-first ownership of my own media and files, LAN-speed transfers at home, and
remote access for family in another city — without exposing ports to the internet or
paying for someone else's cloud.

## Hardware

| | |
|---|---|
| **Host** | ThinkPad P52s — i7-8550U, 30 GB RAM, Samsung 870 SATA SSD |
| **OS** | Ubuntu 26.04 LTS |
| **Graphics** | Intel UHD 620 (QuickSync transcoding) + NVIDIA Quadro P500 |
| **Network** | NETGEAR GS105 unmanaged switch; building-managed Ruckus H550 AP upstream |

Repurposing a laptop means a built-in UPS, low idle draw, and no new hardware cost. The
tradeoff is a single SATA SSD and one free M.2 slot, which is what makes the storage
architecture below matter.

## Stack

Everything runs under a single Docker Compose project.

**Media** — Jellyfin (hardware transcoding via `/dev/dri` passthrough), Sonarr, Radarr,
Prowlarr, Bazarr, qBittorrent, Audiobookshelf, Listenarr
**Files & photos** — Nextcloud, Immich (Postgres + Valkey)
**Operations** — Homepage and Homarr dashboards, Diun update detection, Glances

## Architecture notes

- **[Remote access under CGNAT](docs/networking-cgnat.md)** — why there are two access
  paths instead of one, and how to tell whether your mesh VPN is actually routing locally.
- **[Storage and hardlinks](docs/storage-hardlinks.md)** — why the whole media tree has to
  live on one filesystem, and the one rsync flag that decides whether a migration works.
- **[Update pipeline](docs/update-pipeline.md)** — detecting new images without letting
  anything upgrade a database unattended.
- **[Incidents](docs/incidents.md)** — real failures and their root causes.

## Design decisions

**No public port forwarding.** Nothing is exposed directly. Trusted devices join a
Tailscale mesh; the one client that can't run a VPN agent (a smart TV) goes through a
Cloudflare Tunnel instead.

**Pin every image tag.** Floating tags turn an unattended restart into an unplanned
migration. Exceptions are deliberate and documented.

**Databases never auto-update.** A hold list keeps Postgres and friends out of the
automated upgrade path. Media services can update themselves at 04:30; stateful services
wait for a human.

**One filesystem for media.** Hardlinks between the download client and the media library
are what keep imports instant and storage single-counted. Splitting the tree across mounts
breaks that silently — see the storage doc.

## Repo layout

```
docs/                     architecture write-ups and incident reports
docker-compose.example.yml  sanitized service definitions
```

Secrets live in a `.env` that is not in this repo.
