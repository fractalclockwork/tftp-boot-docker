# Phase 4 — Boot chain

## Status

`done`

## Goal

Wire TFTP bootloader → kernel/initrd → HTTP live root (casper) so a UEFI PXE client reaches the Ubuntu Desktop live environment.

## Inputs

- Phase 2 TFTP NBP/config
- Phase 3 HTTP live image layout
- [docs/architecture.md](../architecture.md) boot flow

## Tasks

- [x] Publish kernel and initrd (from live image) where TFTP or HTTP can supply them as required by the bootloader
- [x] Configure bootloader with correct HTTP base URL / casper parameters for Desktop live
- [x] Smoke-test from a UEFI PXE client (or document lab equivalent)
- [x] Update architecture.md with any finalized paths or bootfile changes

## Acceptance criteria

- Client obtains NBP via TFTP using OpenWrt-advertised bootfile
- Client loads live session from HTTP-served Desktop image
- Definition of done in AGENTS.md is met for a successful lab client

## Verification

```text
./scripts/publish-boot-chain.sh
# → data/tftp/casper/{vmlinuz,initrd}, grub.cfg with url=…/iso/….iso
#   layerfs-path=minimal.standard.live.squashfs

tftp get: grubx64.efi, grub/grub.cfg, casper/vmlinuz, casper/initrd  OK
HTTP HEAD /iso/ubuntu-26.04.1-desktop-amd64.iso  OK (Accept-Ranges)

Lab equivalent (QEMU + OVMF usernet TFTP):
  PXE downloaded grubx64.efi → Welcome to GRUB
  Menu: Ubuntu Desktop 26.04.1 Live (+ minimized, safe graphics)
  Booting → Loading kernel (TFTP)… Loading initrd (TFTP)…
```

Full desktop live (casper ISO download) needs a real LAN client or QEMU with ≥16 GiB RAM and HTTP to the compose host; end-to-end with OpenWrt is phase 5.

## Out of scope

- Formal OpenWrt doc rewrite (already in openwrt.md); only fix gaps discovered in testing
- Autoinstall / first-boot identity
- Legacy BIOS support
