# Phase 1 — Container skeleton

## Status

`done`

## Goal

Minimal Dockerfile + Compose stack that matches [docs/operations.md](../operations.md): TFTP and HTTP listeners, published ports, volume mounts including the ISO path.

## Inputs

- [docs/architecture.md](../architecture.md) — ports, volumes, env
- [docs/operations.md](../operations.md) — up/down/status/logs contract

## Tasks

- [x] Add Dockerfile (TFTP + HTTP capable base or multi-process/supervisor as chosen)
- [x] Add `compose.yaml` / `docker-compose.yml` with UDP 69 and TCP 80 published
- [x] Mount host paths `./data/tftp`, `./data/http`, `./data/iso` (or equivalent satisfying architecture)
- [x] Ensure `docker compose up -d` / `down` behave as documented in operations.md
- [x] Update operations.md if service names or networking mode differ from the draft

## Acceptance criteria

- `docker compose up -d` starts successfully on a clean host with Docker
- TFTP and HTTP ports are listening as documented
- `docker compose down` stops containers without deleting `./data/iso/` contents
- operations.md reflects actual service names and any host-vs-bridge decision

## Verification

```text
docker compose up -d --build
docker compose ps          # tftp-boot Up, 69/udp + 80/tcp
curl → HTTP 200
ss: UDP 69 and TCP 80 listening
echo preserved > data/iso/probe.txt && docker compose down
# probe.txt retained
docker compose exec tftp-boot supervisorctl status
# nginx RUNNING, tftpd RUNNING
```

## Out of scope

- Real NBP / bootloader files (phase 2)
- ISO fetch script and serving live casper (phase 3)
- Full boot chain / live session (later phases; current default is live-server over NFS)
- OpenWrt live verification (phase 5)
