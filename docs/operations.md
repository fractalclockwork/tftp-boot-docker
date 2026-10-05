# Operations — container up / down

Lifecycle for the compose stack. Service name: **`tftp-boot`** (tftpd-hpa + nginx under supervisord). Networking: **`network_mode: host`** — the container binds the host’s UDP **69** and TCP **80** directly (no `ports:` publish). Ensure nothing else on the host owns those ports.

## Prerequisites

- Docker Engine with Compose v2
- Host LAN IP reachable from PXE clients (`TFTP_SERVER_IP` in `.env`; see `.env.example`)
- UDP **69** and TCP **80** free on the host
- For full live boot: Ubuntu Desktop ISO on the host volume — see [iso.md](iso.md)

## Prep order

1. Publish TFTP NBP: `./scripts/publish-tftp-boot.sh` (if `grubx64.efi` missing)
2. Fetch ISO + extract casper: `./scripts/fetch-iso.sh`
3. Publish boot chain (kernel/initrd + live GRUB menu): `./scripts/publish-boot-chain.sh` — requires `TFTP_SERVER_IP` in `.env`
4. Bring the stack up (below)

HTTP: `/iso/…` (ISO for casper `url=`) and `/live/casper/…` (extracted tree). See [iso.md](iso.md) and [architecture.md](architecture.md).

## Bring up

```bash
# After phase 3:
# ./scripts/fetch-iso.sh

docker compose up -d --build
```

**Expected result:** Service `tftp-boot` running; TFTP on UDP 69; HTTP on TCP 80 (or `HTTP_PORT`).

## Status / health

```bash
docker compose ps
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1/
docker compose exec tftp-boot supervisorctl status
```

Confirm nothing else on the host owns UDP 69 (host `tftpd` conflicts are common).

## Logs

```bash
docker compose logs -f tftp-boot
```

## Bring down

```bash
# Stop containers; keep ISO and data dirs (bind mounts)
docker compose down
```

```bash
# This project uses bind mounts only — `down -v` does not remove ./data/iso.
# Still prefer ordinary `down` for routine stops.
docker compose down -v
```

**Contract:** ordinary `docker compose down` must **not** delete files under `./data/iso/` (bind mounts are preserved).

## Restart / rebuild

```bash
docker compose restart
docker compose up -d --build
```

Use `--build` after Dockerfile or `docker/` context changes.

## Volume mounts

| Host | Container |
|------|-----------|
| `./data/tftp` | `/var/lib/tftpboot` (TFTP root) |
| `./data/http` | `/var/www/html` (HTTP docroot) |
| `./data/iso` | `/data/iso` (read-only; also exposed at `http://…/iso/`) |

## Failure notes

| Symptom | Likely cause |
|---------|----------------|
| TFTP bind error / port in use | Host `tftpd` or another process on UDP 69 |
| LAN PXE TFTP fails | Confirm `network_mode: host` in compose; confirm firewall allows UDP 69 / TCP 80 |
| Clients time out on TFTP/HTTP | Firewall or OpenWrt pointing at wrong `TFTP_SERVER_IP` |
| HTTP 404 for live paths | Missing ISO; run `./scripts/fetch-iso.sh` |
| PXE ignores bootfile | OpenWrt options not applied; see [openwrt.md](openwrt.md) |

## Related

- [architecture.md](architecture.md) — ports, volumes, bootfile name
- [iso.md](iso.md) — pull and verify LTS ISO
- [openwrt.md](openwrt.md) — DHCP / PXE setup
