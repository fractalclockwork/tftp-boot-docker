# Phase 7 — Multi-ISO boot menu

## Status

`done`

## Goal

Discover every Ubuntu live ISO under `data/iso/`, extract each to its own NFS/HTTP live tree, and generate a GRUB menu so operators can pick which system to install (or try) at PXE boot. Adding an ISO is: drop file → `./scripts/sync-images.sh` (no image rebuild).

## Inputs

- Phase 6 live-server NFS stack
- [docs/iso.md](../iso.md), [docs/architecture.md](../architecture.md)

## Tasks

- [x] Layout: `data/http/live/<iso-stem>/` per image; TFTP `images/<iso-stem>/`
- [x] `extract-live.sh` extracts to per-ISO dir; `pool`/`dists` when present
- [x] `sync-images.sh` scans `data/iso/*.iso`, extracts stale/missing, republishes GRUB
- [x] `publish-boot-chain.sh` builds one GRUB entry set per extracted image
- [x] NFS exports parent `/var/www/html/live`; docs + ops updated
- [x] Migrate existing flat live tree; verify server + desktop ISOs appear in menu

## Acceptance criteria

- With both Desktop and live-server ISOs present, GRUB lists both (Install NFS for server; Live NFS for desktop)
- `nfsroot=…:/var/www/html/live/<stem>` mounts that image’s CD tree
- `./scripts/sync-images.sh` is the operator path to add/refresh images without rebuilding Docker
- Default menu entry prefers live-server when available

## Verification

```text
data/iso/: desktop + live-server ISOs
data/http/live/ubuntu-26.04.1-{desktop,live-server}-amd64/ present
GRUB default index → live-server NFS entry
NFS mount …/live/ubuntu-26.04.1-live-server-amd64 → OK
```

## Out of scope

- Autoinstall / cloud-init
- Non-Ubuntu ISOs / debian-installer
- Automatic inotify watch inside the container (manual sync is enough)
- Removing the pinned fetch of live-server as the recommended default ISO
