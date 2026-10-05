# Phase 5 — OpenWrt integration

## Status

`done`

## Goal

Apply and verify [docs/openwrt.md](../openwrt.md) on a real OpenWrt router and PXE client; complete the smoke-test checklist; fix documentation gaps if commands differ on the deployed OpenWrt version.

## Inputs

- Working stack through phase 4
- [docs/openwrt.md](../openwrt.md)
- [docs/operations.md](../operations.md)
- [docs/laptop-pxe-test.md](../laptop-pxe-test.md)

## Tasks

- [x] Set `TFTP_SERVER_IP` and bootfile on OpenWrt via LuCI and/or UCI as documented
- [x] Confirm OpenWrt local TFTP is disabled/unused
- [x] PXE-boot a UEFI laptop into the live environment
- [x] Document rollback scripts (operator may run `openwrt-pxe-disable.sh` when desired)
- [x] Patch openwrt.md (host networking, enable/disable scripts, no-SFTP transfer, PXE-E79/Legacy note)

## Acceptance criteria

- Checklist in openwrt.md can be completed successfully
- Client boots using OpenWrt DHCP + this container
- Docs match the commands that worked

## Verification

```text
OpenWrt 24.10.3 — dhcp_boot=grubx64.efi,,<TFTP_SERVER_IP>; enable_tftp=0
compose network_mode: host; HTTP + TFTP OK on Docker host
Legacy Intel Boot Agent → PXE-E79 (expected with grubx64.efi)
UEFI network boot → GRUB → live session (lab laptop)
```

> Later phases: default image is **live-server** over NFS (phase 6); GRUB lists multiple ISOs (phase 7).

## Out of scope

- Adding DHCP to the container
- Autoinstall
- Legacy BIOS NBP (see laptop-pxe-test.md if needed later)
- Supporting every OpenWrt fork; version tested: **24.10.3**
