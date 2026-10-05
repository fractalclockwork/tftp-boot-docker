# Phase 4 — Boot chain

## Status

`done`

## Goal

Wire TFTP bootloader → kernel/initrd → live root (casper) so a UEFI PXE client reaches a Ubuntu live environment.

> **Historical note:** This phase originally used Desktop over HTTP `url=*.iso`. Phases **6–7** changed the default to **live-server over NFS** and a **multi-ISO GRUB menu**. See [architecture.md](../architecture.md) and [iso.md](../iso.md) for the current contract.

## Inputs

- Phase 2 TFTP NBP/config
- Phase 3 HTTP live image layout
- [docs/architecture.md](../architecture.md) boot flow

## Tasks

- [x] Publish kernel and initrd where TFTP can supply them
- [x] Configure bootloader with casper parameters for live boot
- [x] Smoke-test from a UEFI PXE client (or document lab equivalent)
- [x] Update architecture.md with finalized paths

## Acceptance criteria

- Client obtains NBP via TFTP using OpenWrt-advertised bootfile
- Client loads a live session / installer from the served image
- Lab path documented

## Verification (as completed in phase 4)

```text
./scripts/publish-boot-chain.sh
tftp get: grubx64.efi, grub/grub.cfg, casper/vmlinuz, casper/initrd  OK
```

Current operator path: `./scripts/sync-images.sh` (multi-ISO). End-to-end OpenWrt: phase 5; live-server default: phase 6; multi-ISO: phase 7.

## Out of scope

- Formal OpenWrt doc rewrite (phase 5)
- Autoinstall / first-boot identity
- Legacy BIOS support
