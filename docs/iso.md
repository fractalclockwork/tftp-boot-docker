# ISO — pull Ubuntu Server LTS from the web

Operator contract for obtaining the live-server image used for PXE install.

## Pin

| Field | Value |
|-------|--------|
| Product | Ubuntu **Server** (live-server; not Desktop) |
| Version | **26.04.1 LTS** |
| Codename | Resolute Raccoon |
| Arch | amd64 |
| Artifact | Official live-server ISO |

Do not use daily builds unless the 26.04.1 point-release ISO is unavailable from official mirrors; if that happens, document the temporary URL in this file and restore the pin when the point release appears.

## Source

Official Ubuntu release trees (prefer in this order):

1. `https://releases.ubuntu.com/26.04.1/` — live-server ISO and `SHA256SUMS`
2. `https://cdimage.ubuntu.com/ubuntu/releases/26.04.1/release/` — fallback

ISO name:

```text
ubuntu-26.04.1-live-server-amd64.iso
```

(~2.7 GiB; much lighter than Desktop for 8 GiB clients.)

## Storage

| Path | Contents |
|------|----------|
| `./data/iso/` | One or more `*.iso` + `SHA256SUMS` |
| `./data/http/live/<iso-stem>/` | Per-ISO CD tree: `casper/`, `.disk/`, and when present `pool/` + `dists/` |

`<iso-stem>` is the ISO basename without `.iso` (e.g. `ubuntu-26.04.1-live-server-amd64`).

- Bind-mounted into the container (see [architecture.md](architecture.md)).
- **Gitignore** covers `data/` blobs (except `.gitkeep`).
- Do **not** `COPY` the ISO into the Docker image.

## Fetch / sync procedure

```bash
./scripts/fetch-iso.sh           # download + verify pinned live-server ISO + extract
./scripts/fetch-iso.sh --force   # re-download even if present
./scripts/fetch-iso.sh --no-extract
./scripts/extract-live.sh PATH.iso   # extract one ISO
./scripts/sync-images.sh             # extract all data/iso/*.iso + regenerate GRUB
./scripts/sync-images.sh --force     # re-extract everything
```

Pin override: `UBUNTU_VERSION=26.04.1` (script default / compose env). Legacy alias: `UBUNTU_DESKTOP_VERSION` is accepted if `UBUNTU_VERSION` is unset.

**Add an image on the fly:** copy a live ISO into `./data/iso/`, then `./scripts/sync-images.sh` (no Docker image rebuild). Restart/reload NFS is usually unnecessary (same export parent).

Behavior of `fetch-iso.sh`:

1. Creates `./data/iso/` if missing.
2. Resolves version from `UBUNTU_VERSION`.
3. Downloads `SHA256SUMS` (refreshed with `--force`).
4. Downloads the live-server ISO only if missing or checksum fails (idempotent).
5. Verifies the ISO line in `SHA256SUMS`; exits non-zero on mismatch.
6. Prints the absolute path of the verified ISO.
7. Unless `--no-extract`, extracts into `./data/http/live/<stem>/`.

## HTTP / NFS URL layout

Base HTTP: `http://TFTP_SERVER_IP/` (port 80, or `HTTP_PORT`).

| URL / export | Host path | Notes |
|--------------|-----------|--------|
| `/iso/` | `./data/iso/` | All ISOs + checksums |
| `/iso/<name>.iso` | same | Full ISO; `Accept-Ranges: bytes` |
| `/live/<stem>/` | `./data/http/live/<stem>/` | Extracted tree (browsable) |
| NFS `…:/var/www/html/live/<stem>` | same | Casper `nfsroot` for that image |
| `/live/<stem>/casper/…` | … | Kernel, initrd, squashfs |
| `/live/<stem>/pool/…` | … | Offline apt (Server) |

GRUB lists every extracted stem (default prefers `*live-server*`). See [architecture.md](architecture.md).

## Force re-fetch / upgrade

1. Update `UBUNTU_VERSION` and this pin table if changing the default fetch.
2. Drop additional ISOs into `data/iso/` as needed.
3. `./scripts/sync-images.sh --force`
4. Or `rm -rf data/http/live/<stem>` then `./scripts/sync-images.sh`.

## Out of scope for fetch/extract

- Serving (compose/nginx/NFS already does)
- Wiring GRUB/cmdline (publish-boot-chain)
- Autoinstall / seed generation
- Installing a Desktop metapackage (operator does that after first boot when apt works)

## Related

- [operations.md](operations.md) — prep order
- [architecture.md](architecture.md) — boot flow
- [phases/06-live-server-installer.md](phases/06-live-server-installer.md)
- [phases/07-multi-iso-menu.md](phases/07-multi-iso-menu.md)
