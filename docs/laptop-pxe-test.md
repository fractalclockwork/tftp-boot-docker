# Laptop PXE end-to-end test

UEFI network boot against this stack (multi-ISO GRUB; default **live-server** / subiquity).

Set `TFTP_SERVER_IP` in `.env` (see `.env.example`). OpenWrt must advertise `grubx64.efi,,$TFTP_SERVER_IP` with local TFTP off ([openwrt.md](openwrt.md)). Lab tested on OpenWrt **24.10.3**.

## Before you boot the laptop

On the Docker host:

```bash
cd /path/to/tftp-boot-docker
docker compose up -d --build
./scripts/sync-images.sh
set -a && source .env && set +a
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' "http://${TFTP_SERVER_IP}/"
docker compose exec tftp-boot exportfs -v
grep '^menuentry' data/tftp/grub/grub.cfg
```

Prefer **wired Ethernet** on the same LAN as OpenWrt.

- **Server (default):** ~8 GiB RAM OK; **no gateway required** for install-from-image if that stem has `pool/` + `dists/`. Skip “update installer” / Ubuntu Pro if offered.
- **Desktop:** more RAM; use NFS Live entry, not “via full ISO”, unless the machine has lots of free RAM.
- After Server install, with internet: `sudo apt update && sudo apt install ubuntu-desktop`.

## Laptop firmware

1. Enter firmware setup (vendor key: F2 / Del / Esc / F10, etc.).
2. **UEFI** mode (not Legacy/CSM-only).
3. Enable **Network Stack** / **PXE** as offered.
4. If Secure Boot blocks unsigned GRUB, disable Secure Boot for this test.
5. Boot **UEFI PXE** / **UEFI Network** — **not** “Intel Boot Agent” / Legacy LAN.

### PXE-E79 / Intel Boot Agent

If you see **Intel Boot Agent GE** and `PXE-E79: NBP is too big…`, the laptop is doing **Legacy BIOS PXE**. Switch firmware to **UEFI network boot**.

## What you should see

1. DHCP from OpenWrt → NBP `grubx64.efi` from `TFTP_SERVER_IP`.
2. GRUB menu: one group per synced ISO (default prefers live-server).
3. Kernel/initrd from TFTP `/images/<stem>/`.
4. Casper NFS-mounts `TFTP_SERVER_IP:/var/www/html/live/<stem>`.
5. Server → **subiquity**; Desktop → live session. Keep Ethernet up for NFS.
6. Skip installer update if no gateway; Server offline install needs `pool/` on that stem.

## If it fails

| Symptom | Check |
|---------|--------|
| **PXE-E79 NBP too big** / Intel Boot Agent | Legacy PXE — use UEFI network boot |
| No DHCP / no NBP | Cable, VLAN, OpenWrt `uci get dhcp.@dnsmasq[0].dhcp_boot` |
| TFTP timeout | Host firewall; `ss -ulnp \| grep :69`; `docker compose logs -f tftp-boot` |
| `No space left on device` | Full-ISO menu; use NFS entry instead |
| “unable to find a medium…” | NFS down or wrong stem; `exportfs -v`; `./scripts/sync-images.sh` |
| Installer crashes / offline apt fails | Missing `pool/`/`dists/` on that stem — `./scripts/extract-live.sh data/iso/<stem>.iso --force` |
| Desktop entry OOM / no Install app | Use live-server for install; Desktop minimized layers lack the installer |

## After a successful boot (optional OpenWrt rollback)

```bash
set -a && source .env && set +a
ssh root@OPENWRT 'cat > /tmp/openwrt-pxe-disable.sh' < scripts/openwrt-pxe-disable.sh
ssh root@OPENWRT "TFTP_SERVER_IP=$TFTP_SERVER_IP sh /tmp/openwrt-pxe-disable.sh"
```
