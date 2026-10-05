# tftp-boot-docker

Docker-based **TFTP + HTTP** server that network-boots a machine into the **Ubuntu Desktop 26.04.1 LTS** (“Resolute Raccoon”) live environment.

**DHCP stays on OpenWrt.** This project does not run a DHCP server. OpenWrt advertises `next-server` and the boot filename; this container serves the bootloader over TFTP and the live Desktop image over HTTP.

## Status

Working stack for **UEFI PXE** clients (OpenWrt DHCP + this container). Use **UEFI network boot**, not Legacy Intel Boot Agent (`grubx64.efi` triggers PXE-E79 on BIOS PXE).

## Quick start

```bash
cp .env.example .env
# Edit .env: set TFTP_SERVER_IP to this host’s LAN IP

./scripts/publish-tftp-boot.sh      # once: build grubx64.efi
./scripts/fetch-iso.sh              # download + verify Desktop ISO + extract casper
./scripts/publish-boot-chain.sh     # kernel/initrd on TFTP + live GRUB menu
docker compose up -d

# Point OpenWrt at this host (see docs/openwrt.md):
ssh root@OPENWRT 'cat > /tmp/openwrt-pxe-enable.sh' < scripts/openwrt-pxe-enable.sh
ssh root@OPENWRT "TFTP_SERVER_IP=$(grep TFTP_SERVER_IP .env | cut -d= -f2) sh /tmp/openwrt-pxe-enable.sh"
```

Stop (keeps ISO/data by default): `docker compose down`.

Compose uses **`network_mode: host`** (UDP 69 + TCP 80 on the host). Full lifecycle: [docs/operations.md](docs/operations.md).

## Architecture (short)

1. PXE client gets an address and boot options from OpenWrt.
2. Client fetches the NBP (`grubx64.efi`) and kernel/initrd from this host over **TFTP**.
3. Casper downloads the Desktop ISO over **HTTP** and boots the live session.
4. The ISO is fetched from official mirrors onto a host volume (not baked into the image).

Details: [docs/architecture.md](docs/architecture.md).

## Operator docs

| Doc | Purpose |
|-----|---------|
| [docs/operations.md](docs/operations.md) | Container up / down / status / logs |
| [docs/iso.md](docs/iso.md) | Pull and verify the LTS Desktop ISO |
| [docs/openwrt.md](docs/openwrt.md) | OpenWrt DHCP / PXE requirements and setup |
| [docs/laptop-pxe-test.md](docs/laptop-pxe-test.md) | UEFI laptop end-to-end PXE checklist |

## Agentic workflow

Agents (and humans) work **one phase at a time**. Start at [AGENTS.md](AGENTS.md); follow [docs/workflow.md](docs/workflow.md). Phase packets: [docs/phases/](docs/phases/).

## License

MIT — see [LICENSE](LICENSE).
