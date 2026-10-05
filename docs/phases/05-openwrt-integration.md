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
- [x] PXE-boot a UEFI laptop into the Desktop live environment
- [x] Document rollback scripts (operator may run `openwrt-pxe-disable.sh` when desired)
- [x] Patch openwrt.md (host networking, enable/disable scripts, no-SFTP transfer, PXE-E79/Legacy note)

## Acceptance criteria

- Checklist in openwrt.md can be completed successfully
- Client boots live Desktop using OpenWrt DHCP + this container
- Docs match the commands that worked (no stale placeholders left unexplained)

## Verification

```text
OpenWrt 24.10.3 — dhcp_boot=grubx64.efi,,<TFTP_SERVER_IP>; enable_tftp=0
compose network_mode: host; HTTP + TFTP OK on Docker host
Legacy Intel Boot Agent → PXE-E79 (expected with grubx64.efi)
UEFI network boot → GRUB → live Desktop (confirmed on lab laptop)
```

## Out of scope

- Adding DHCP to the container
- Autoinstall
- Legacy BIOS NBP (see laptop-pxe-test.md if needed later)
- Supporting every OpenWrt fork; version tested: **24.10.3**
