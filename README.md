# tftp-boot-docker

Docker-based **TFTP + HTTP + NFS** PXE host. Drop Ubuntu live ISOs into `data/iso/`; GRUB lists each extracted image so you can pick what to install (or try) at boot.

Default recommendation for **~8 GiB** clients: **Ubuntu Server 26.04.1** live-server (subiquity, offline `pool/`). Desktop ISOs can sit alongside for larger machines.

**DHCP stays on OpenWrt.** This project does not run a DHCP server.

## Status

Working stack for **UEFI PXE** (OpenWrt DHCP + this container). Use **UEFI network boot**, not Legacy Intel Boot Agent.

## Quick start

```bash
cp .env.example .env
# Edit .env: set TFTP_SERVER_IP to this host’s LAN IP

./scripts/publish-tftp-boot.sh      # once: build grubx64.efi
./scripts/fetch-iso.sh              # recommended: live-server ISO
# Optional: copy more *.iso into data/iso/
./scripts/sync-images.sh            # extract all ISOs + GRUB menu
docker compose up -d --build

# Point OpenWrt at this host (see docs/openwrt.md):
ssh root@OPENWRT 'cat > /tmp/openwrt-pxe-enable.sh' < scripts/openwrt-pxe-enable.sh
ssh root@OPENWRT "TFTP_SERVER_IP=$(grep TFTP_SERVER_IP .env | cut -d= -f2) sh /tmp/openwrt-pxe-enable.sh"
```

**Add an ISO later:** copy into `data/iso/` → `./scripts/sync-images.sh` (no Docker rebuild).

Stop: `docker compose down` (keeps `data/`).

## Architecture (short)

1. OpenWrt DHCP → `grubx64.efi` over TFTP.
2. GRUB menu: one entry group per `data/http/live/<iso-stem>/`.
3. Casper NFS-mounts that stem; installer or live session starts.
4. ISOs stay on the host volume (not in image layers).

Details: [docs/architecture.md](docs/architecture.md).

## Operator docs

| Doc | Purpose |
|-----|---------|
| [docs/operations.md](docs/operations.md) | Container up / down / status / logs |
| [docs/iso.md](docs/iso.md) | Fetch, multi-ISO layout, sync |
| [docs/openwrt.md](docs/openwrt.md) | OpenWrt DHCP / PXE |
| [docs/laptop-pxe-test.md](docs/laptop-pxe-test.md) | Laptop checklist |

## Agentic workflow

[AGENTS.md](AGENTS.md) · [docs/workflow.md](docs/workflow.md) · [docs/phases/](docs/phases/)

## License

MIT — see [LICENSE](LICENSE).
