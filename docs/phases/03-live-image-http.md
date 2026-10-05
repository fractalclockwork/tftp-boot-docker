# Phase 3 — Live image HTTP

## Status

`done`

## Goal

Implement [docs/iso.md](../iso.md): fetch script with checksum verification; serve the pulled Ubuntu live image (ISO and/or extracted casper) over HTTP.

> **Historical note:** Originally pinned Desktop. Current pin is **live-server**; multi-ISO layout is `data/http/live/<stem>/` (phases 6–7). See current [iso.md](../iso.md).

## Inputs

- [docs/iso.md](../iso.md) — pin, URLs, fetch contract
- Phase 1 compose/HTTP skeleton

## Tasks

- [x] Add `./scripts/fetch-iso.sh` meeting the iso.md contract
- [x] Extract casper for HTTP serving
- [x] Document the HTTP URL layout
- [x] Confirm `.gitignore` covers `data/iso` blobs
- [x] Update iso.md/operations.md if paths differ

## Acceptance criteria

- `./scripts/fetch-iso.sh` downloads (or skips) and verifies the pinned ISO
- HTTP serves ISO and extracted live paths
- `docker compose down` retains ISO on host volume

## Verification (as completed)

```text
./scripts/fetch-iso.sh
curl /                         → 200
curl /iso/…iso                 → 200, Accept-Ranges
```

Current paths use `/live/<stem>/casper/…`. Operator sync: `./scripts/sync-images.sh`.

## Out of scope

- Wiring bootloader kernel cmdline (phase 4+)
- Autoinstall
