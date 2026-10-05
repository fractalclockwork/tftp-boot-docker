# OpenWrt — DHCP / PXE requirements and setup

OpenWrt owns DHCP. This project’s container owns TFTP and HTTP. Configure OpenWrt to **point clients at the container host**; do not run a second DHCP server on the LAN.

## Placeholders

| Name | Meaning |
|------|--------|
| `OPENWRT` | OpenWrt LAN IP or hostname (often the default gateway) |
| `TFTP_SERVER_IP` | Stable LAN IP of the Docker host (set in `.env`; see `.env.example`) |
| Bootfile | `grubx64.efi` (must match [architecture.md](architecture.md)) |

Compose uses **`network_mode: host`** so TFTP/HTTP bind the host’s UDP 69 and TCP 80. After changing `TFTP_SERVER_IP`, re-run `./scripts/publish-boot-chain.sh`.

### Example lab

| Name | Example |
|------|--------|
| `OPENWRT` | `192.168.1.1` |
| `TFTP_SERVER_IP` | `192.168.1.50` |
| HTTP | `http://192.168.1.50/` |

Replace examples with your addresses everywhere below (or export `TFTP_SERVER_IP` when running the helper scripts).

## Requirements checklist

- [ ] OpenWrt is the only DHCP server on the PXE LAN segment
- [ ] Container host has a stable `TFTP_SERVER_IP` on that LAN
- [ ] dnsmasq PXE options applied (`dhcp_boot=grubx64.efi,,TFTP_SERVER_IP`)
- [ ] Clients can reach `TFTP_SERVER_IP:80/tcp` and `TFTP_SERVER_IP:69/udp`
- [ ] Boot filename is `grubx64.efi`
- [ ] OpenWrt’s own TFTP server disabled (`enable_tftp=0`)
- [ ] UEFI client reaches live Desktop (see [laptop-pxe-test.md](laptop-pxe-test.md))

## Setup

### 1. Record values

```bash
cp .env.example .env   # set TFTP_SERVER_IP
./scripts/publish-boot-chain.sh
docker compose up -d
curl -fsS -o /dev/null -w '%{http_code}\n' "http://${TFTP_SERVER_IP:-127.0.0.1}/"
```

### 2. LuCI

1. Open LuCI on `OPENWRT` → **Network** → **DHCP and DNS**.
2. Set network-boot / TFTP server to `TFTP_SERVER_IP` and boot filename `grubx64.efi`.
3. Ensure OpenWrt “enable TFTP server” is **off**.
4. **Save & Apply**.

### 3. UCI (CLI) — preferred for this repo

OpenWrt often has **no SFTP** (`ash: /usr/libexec/sftp-server: not found`), so plain `scp` fails. Use one of these instead:

**A — pipe the script over SSH (no SFTP):**

```bash
# From the Docker host repo root (prompts for OpenWrt root password).
# Scripts read TFTP_SERVER_IP from the environment on the router:
export TFTP_SERVER_IP=192.168.1.50   # your Docker host LAN IP
ssh root@OPENWRT 'cat > /tmp/openwrt-pxe-enable.sh' < scripts/openwrt-pxe-enable.sh
ssh root@OPENWRT "TFTP_SERVER_IP=$TFTP_SERVER_IP sh /tmp/openwrt-pxe-enable.sh"
```

**B — legacy SCP protocol** (OpenSSH client `-O`):

```bash
scp -O scripts/openwrt-pxe-enable.sh root@OPENWRT:/tmp/
ssh root@OPENWRT "TFTP_SERVER_IP=$TFTP_SERVER_IP sh /tmp/openwrt-pxe-enable.sh"
```

**C — paste UCI Option A manually** (no file transfer):

```sh
# Replace 192.168.1.50 with your TFTP_SERVER_IP
uci set dhcp.@dnsmasq[0].dhcp_boot='grubx64.efi,,192.168.1.50'
uci set dhcp.@dnsmasq[0].enable_tftp='0'
uci delete dhcp.@dnsmasq[0].tftp_root 2>/dev/null || true
uci commit dhcp
/etc/init.d/dnsmasq restart
uci get dhcp.@dnsmasq[0].dhcp_boot
```

**Option B** (DHCP options 66/67 on `lan`) if `dhcp_boot` is unavailable:

```sh
uci add_list dhcp.lan.dhcp_option='66,192.168.1.50'
uci add_list dhcp.lan.dhcp_option='67,grubx64.efi'
uci set dhcp.@dnsmasq[0].enable_tftp='0'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

Use dhcp_boot **or** options 66/67, not both.

### 4. Apply

LuCI **Save & Apply**, or `uci commit dhcp` + `/etc/init.d/dnsmasq restart`.

### 5. Verify

**On OpenWrt:**

```sh
uci get dhcp.@dnsmasq[0].dhcp_boot
uci get dhcp.@dnsmasq[0].enable_tftp   # expect 0
logread -e dnsmasq | tail
```

**From a LAN host / PXE client:**

```sh
curl -fsS -o /dev/null -w '%{http_code}\n' http://TFTP_SERVER_IP/
# tftp TFTP_SERVER_IP → get grubx64.efi
```

**UEFI client smoke:** Network boot → GRUB menu (“Ubuntu Desktop 26.04.1 Live”) → casper fetches the ISO over HTTP. Prefer UEFI PXE (not Legacy Intel Boot Agent). Client should have ample RAM (often ≥16 GiB for Desktop ISO netboot).

### 6. Rollback

```bash
ssh root@OPENWRT 'cat > /tmp/openwrt-pxe-disable.sh' < scripts/openwrt-pxe-disable.sh
ssh root@OPENWRT "TFTP_SERVER_IP=$TFTP_SERVER_IP sh /tmp/openwrt-pxe-disable.sh"
```

Or:

```sh
uci delete dhcp.@dnsmasq[0].dhcp_boot 2>/dev/null || true
uci commit dhcp
/etc/init.d/dnsmasq restart
```

## Related

- [architecture.md](architecture.md) — bootfile, host networking, boot chain
- [operations.md](operations.md) — container must be up before clients succeed
- [laptop-pxe-test.md](laptop-pxe-test.md) — UEFI laptop checklist / PXE-E79
- [phases/05-openwrt-integration.md](phases/05-openwrt-integration.md) — phase status
