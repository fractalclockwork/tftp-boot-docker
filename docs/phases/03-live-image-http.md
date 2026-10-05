# Phase 3 — Live image over HTTP

## Status

`done`

## Goal

Implement [docs/iso.md](../iso.md): fetch script with checksum verification; serve the pulled Ubuntu Desktop 26.04.1 live image (ISO and/or extracted casper) over HTTP.

## Inputs

- [docs/iso.md](../iso.md) — pin, URLs, fetch contract
- [docs/operations.md](../operations.md) — prep order
- Phase 1 HTTP service and volume mounts

## Tasks

- [x] Add `./scripts/fetch-iso.sh` meeting the iso.md contract (idempotent, SHA-256 verify, print path)
- [x] Wire compose/HTTP root so the verified ISO or extracted live tree is reachable
- [x] Document the HTTP URL layout operators and phase 4 will use
- [x] Confirm `.gitignore` covers `data/iso` blobs
- [x] Update iso.md/operations.md if paths or flags differ from the contract

## Acceptance criteria

- `./scripts/fetch-iso.sh` downloads (or skips) and verifies the pinned Desktop ISO
- HTTP GET succeeds for the documented live-image path(s) after compose is up
- ISO is not copied into image layers
- Ordinary `docker compose down` leaves the ISO on disk

## Verification

```text
./scripts/fetch-iso.sh
# → verified ubuntu-26.04.1-desktop-amd64.iso; extracted data/http/live/casper/

curl /                         → 200
curl /iso/ubuntu-26.04.1-…iso  → 200, Accept-Ranges: bytes, ~6.0GiB
curl /live/casper/vmlinuz      → 200
curl /live/casper/initrd       → 200
curl /live/casper/minimal.standard.en.squashfs → 200

docker compose down  → ISO retained under data/iso/
Image layers do not contain the ISO blob
```

## Out of scope

- Wiring bootloader kernel cmdline to casper (phase 4)
- OpenWrt verification (phase 5)
- Autoinstall
