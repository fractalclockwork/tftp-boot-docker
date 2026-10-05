# Laptop PXE end-to-end test

Hardware client checklist for UEFI network boot against this stack.

Set `TFTP_SERVER_IP` in `.env` (see `.env.example`). OpenWrt must advertise `grubx64.efi,,$TFTP_SERVER_IP` with local TFTP off ([openwrt.md](openwrt.md)). Lab tested on OpenWrt **24.10.3**.

## Before you boot the laptop

On the Docker host:

```bash
cd /path/to/tftp-boot-docker
docker compose up -d
./scripts/publish-boot-chain.sh
# shellcheck: source .env for the curl below
set -a && source .env && set +a
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' "http://${TFTP_SERVER_IP}/"
```

Prefer **wired Ethernet** to the same LAN as OpenWrt (Wi‑Fi PXE is uncommon). Expect **≥16 GiB RAM** for Desktop ISO netboot (casper downloads the ~6 GiB ISO into memory).

## Laptop firmware

1. Enter firmware setup (vendor key: F2 / Del / Esc / F10, etc.).
2. **UEFI** mode (not Legacy/CSM-only).
3. Enable **Network Stack** / **PXE** / **HTTP Boot** as offered (PXE/TFTP is enough).
4. If Secure Boot blocks unsigned GRUB, disable Secure Boot for this test (our `grubx64.efi` is an unsigned `grub-mkimage` build).
5. Set boot order or use the one-shot boot menu to select **UEFI PXE** / **UEFI Network** — **not** “Intel Boot Agent” / Legacy LAN.

### PXE-E79 / Intel Boot Agent

If you see **Intel Boot Agent GE** and:

```text
PXE-E79: NBP is too big to fit in free base memory
```

the laptop is doing **Legacy BIOS PXE**. OpenWrt is handing out `grubx64.efi` (UEFI-only, ~876 KiB), which does not fit in BIOS base memory.

**Fix:** in firmware, disable **Legacy / CSM / Compatibility Support Module**, enable **UEFI**, and choose a boot entry named like **UEFI PXE** / **UEFI Network** / **IPv4 Network** (not “Intel Boot Agent”). Also disable Secure Boot for this lab if needed.

If the machine has **no UEFI network boot** at all, a Legacy NBP (`undionly.kpxe`) would be required; it is not in the current stack.

## What you should see

1. DHCP from OpenWrt → NBP `grubx64.efi` from `TFTP_SERVER_IP`.
2. GRUB menu: **Ubuntu Desktop 26.04.1 Live** (also minimized / safe graphics).
3. “Loading kernel (TFTP)…” / “Loading initrd (TFTP)…”.
4. Casper downloads `http://TFTP_SERVER_IP/iso/ubuntu-26.04.1-desktop-amd64.iso` (can take several minutes).
5. Ubuntu Desktop live session.

## If it fails

| Symptom | Check |
|---------|--------|
| **PXE-E79 NBP too big** / Intel Boot Agent | Legacy PXE loading UEFI `grubx64.efi` — switch firmware to **UEFI network boot** (see above) |
| No DHCP / no NBP | Cable, VLAN, OpenWrt `uci get dhcp.@dnsmasq[0].dhcp_boot` |
| TFTP timeout | Host firewall; `ss -ulnp \| grep :69`; `docker compose logs -f tftp-boot` |
| GRUB then hang on ISO | HTTP reachable from laptop to `http://TFTP_SERVER_IP/iso/`; RAM |
| Secure Boot violation | Disable Secure Boot for lab |
| “unable to find a live file system” | Re-run `./scripts/fetch-iso.sh && ./scripts/publish-boot-chain.sh` |

## After a successful boot (optional rollback)

```bash
set -a && source .env && set +a
ssh root@OPENWRT 'cat > /tmp/openwrt-pxe-disable.sh' < scripts/openwrt-pxe-disable.sh
ssh root@OPENWRT "TFTP_SERVER_IP=$TFTP_SERVER_IP sh /tmp/openwrt-pxe-disable.sh"
```

Re-enable with `openwrt-pxe-enable.sh` when needed.
