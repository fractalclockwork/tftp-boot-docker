# Operations — container up / down

Lifecycle for the compose stack. Service name: **`tftp-boot`** — one self-contained container (tftpd-hpa + nginx + NFSv3 under supervisord). No separate host TFTP/NFS packages. Networking: **`network_mode: host`** binds UDP **69**, TCP **80**, and NFS (**111** / **2049** / mountd **20048**) on the Docker host. Compose sets **`privileged: true`** only so the container can run kernel nfsd; operators still only run `docker compose up`.

## Prerequisites

- Docker Engine with Compose v2
- Host LAN IP reachable from PXE clients (`TFTP_SERVER_IP` in `.env`; see `.env.example`)
- UDP **69**, TCP **80**, and NFS **111/2049** free on the host; `nfsd` kernel module available
- At least one Ubuntu live ISO under `./data/iso/` — see [iso.md](iso.md)

## Prep order

1. Publish TFTP NBP: `./scripts/publish-tftp-boot.sh` (if `grubx64.efi` missing)
2. Fetch default ISO: `./scripts/fetch-iso.sh` (and/or copy more `*.iso` into `data/iso/`)
3. Extract all + GRUB: `./scripts/sync-images.sh` — requires `TFTP_SERVER_IP` in `.env`
4. Bring the stack up (below)

HTTP: `/iso/…` and `/live/<stem>/…`. NFS: `/var/www/html/live/<stem>`. See [iso.md](iso.md).

## Bring up

```bash
./scripts/fetch-iso.sh            # if needed
./scripts/sync-images.sh
docker compose up -d --build
```

**Expected result:** Service `tftp-boot` running; TFTP on UDP 69; HTTP on TCP 80 (or `HTTP_PORT`); NFS exporting `/var/www/html/live` (per-stem trees underneath).

## Add an ISO later

```bash
cp /path/to/ubuntu-….iso ./data/iso/
./scripts/sync-images.sh
# no Docker rebuild required; NFS parent export already covers new stems
```

## Status / health

```bash
docker compose ps
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1/
docker compose exec tftp-boot supervisorctl status   # expect tftpd, nginx, nfs RUNNING
docker compose exec tftp-boot exportfs -v
ls data/http/live/                                   # one directory per ISO stem
grep '^menuentry' data/tftp/grub/grub.cfg | head
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
docker compose down -v
```

**Contract:** ordinary `docker compose down` must **not** delete files under `./data/iso/` (bind mounts are preserved).

## Restart / rebuild

```bash
docker compose restart
docker compose up -d --build
```

Use `--build` after Dockerfile or `docker/` context changes (NFS helpers, nginx, etc.).

## Volume mounts

| Host | Container |
|------|-----------|
| `./data/tftp` | `/var/lib/tftpboot` (TFTP root) |
| `./data/http` | `/var/www/html` (HTTP docroot + NFS live trees) |
| `./data/iso` | `/data/iso` (read-only; also exposed at `http://…/iso/`) |

## Failure notes

| Symptom | Likely cause |
|---------|----------------|
| TFTP bind error / port in use | Host `tftpd` or another process on UDP 69 |
| LAN PXE TFTP fails | Confirm `network_mode: host`; firewall UDP 69 / TCP 80 / NFS 111+2049 |
| Clients time out on TFTP/HTTP/NFS | Firewall or wrong `TFTP_SERVER_IP` |
| HTTP 404 for `/live/<stem>/…` | Missing extract; `./scripts/sync-images.sh` |
| NFS program fatal / export missing | No `data/http/live/*/casper`; run sync; need `privileged: true` |
| `Unable to find a medium…` | Bad `nfsroot` stem or NFS down; do not use `url=/live/` (casper needs `url=*.iso` or NFS) |
| Installer crashes offline | Stem missing `pool/`/`dists/` — re-extract that ISO with `./scripts/extract-live.sh … --force` |
| PXE ignores bootfile | OpenWrt options; see [openwrt.md](openwrt.md) |

## Related

- [architecture.md](architecture.md) — ports, volumes, boot flow
- [iso.md](iso.md) — fetch, multi-ISO layout, sync
- [openwrt.md](openwrt.md) — DHCP / PXE setup
- [laptop-pxe-test.md](laptop-pxe-test.md) — client checklist
