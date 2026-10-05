# Phase 2 — TFTP boot files

## Status

`done`

## Goal

Publish an NBP and bootloader configuration that PXE clients can fetch over TFTP (UEFI default bootfile aligned with architecture/OpenWrt docs).

## Inputs

- Phase 1 compose stack running
- [docs/architecture.md](../architecture.md) — planned bootfile `grubx64.efi`
- [docs/openwrt.md](../openwrt.md) — bootfile name contract

## Tasks

- [x] Place UEFI NBP in the TFTP root under the documented bootfile name
- [x] Add minimal bootloader config so a client can request subsequent files over TFTP
- [x] Document exact TFTP paths in architecture.md if they differ from the stub
- [x] If bootfile name changes, update openwrt.md and architecture.md in the same change

## Acceptance criteria

- From a LAN host (or container network), `tftp` (or equivalent) can `get` the bootfile from `TFTP_SERVER_IP`
- Bootfile name matches what OpenWrt docs advertise
- No DHCP server added to the stack

## Verification

```text
./scripts/publish-tftp-boot.sh
# → data/tftp/grubx64.efi (~897KB), data/tftp/grub/grub.cfg

# From a client on the compose network:
tftp tftp-boot → get grubx64.efi (897024 bytes)
tftp tftp-boot → get grub/grub.cfg (placeholder menu)

Bootfile name unchanged: grubx64.efi (matches openwrt.md)
No DHCP service in compose.yaml
```

Host→published-port TFTP can hang under bridge NAT; prefer same-network clients or `network_mode: host` if LAN PXE fails (see operations.md).

## Out of scope

- HTTP live image / ISO fetch (phase 3)
- Complete casper boot (phase 4+; NFS multi-ISO in phases 6–7)
- OpenWrt device configuration (phase 5)
