# ISO — pull Ubuntu Desktop LTS from the web

Operator contract for obtaining the live Desktop image.

## Pin

| Field | Value |
|-------|--------|
| Product | Ubuntu **Desktop** (not Server) |
| Version | **26.04.1 LTS** |
| Codename | Resolute Raccoon |
| Arch | amd64 |
| Artifact | Official desktop live ISO |

Do not use daily builds unless the 26.04.1 point-release ISO is unavailable from official mirrors; if that happens, document the temporary URL in this file and restore the pin when the point release appears.

## Source

Official Ubuntu release trees (prefer in this order):

1. `https://releases.ubuntu.com/26.04.1/` — desktop ISO and `SHA256SUMS`
2. `https://cdimage.ubuntu.com/ubuntu/releases/26.04.1/release/` — fallback

ISO name:

```text
ubuntu-26.04.1-desktop-amd64.iso
```

## Storage

| Path | Contents |
|------|----------|
| `./data/iso/` | ISO file + `SHA256SUMS` |
| `./data/http/live/` | Extracted `/casper` (+ `/.disk`) for HTTP live boot |

- Bind-mounted into the container (see [architecture.md](architecture.md)).
- **Gitignore** covers `data/` blobs (except `.gitkeep`).
- Do **not** `COPY` the ISO into the Docker image.

## Fetch procedure

```bash
./scripts/fetch-iso.sh           # download + verify + extract casper
./scripts/fetch-iso.sh --force   # re-download even if present
./scripts/fetch-iso.sh --no-extract
./scripts/extract-live.sh        # extract only (ISO must already exist)
```

Pin override: `UBUNTU_DESKTOP_VERSION=26.04.1` (script default / compose env).

Behavior:

1. Creates `./data/iso/` if missing.
2. Resolves version from `UBUNTU_DESKTOP_VERSION`.
3. Downloads `SHA256SUMS` (refreshed with `--force`).
4. Downloads the Desktop ISO only if missing or checksum fails (idempotent).
5. Verifies the ISO line in `SHA256SUMS`; exits non-zero on mismatch.
6. Prints the absolute path of the verified ISO.
7. Unless `--no-extract`, runs `extract-live.sh` into `./data/http/live/`.

## HTTP URL layout

Base: `http://TFTP_SERVER_IP/` (port 80, or `HTTP_PORT`).

| URL | Host path | Notes |
|-----|-----------|--------|
| `/iso/` | `./data/iso/` | Directory listing; ISO + checksums |
| `/iso/ubuntu-26.04.1-desktop-amd64.iso` | same | Full Desktop ISO (~6 GiB); `Accept-Ranges: bytes` |
| `/live/` | `./data/http/live/` | Extracted live tree |
| `/live/casper/vmlinuz` | …/casper/vmlinuz | Kernel for phase 4 |
| `/live/casper/initrd` | …/casper/initrd | Initrd for phase 4 |
| `/live/casper/minimal.standard.en.squashfs` | … | Typical Desktop squashfs (26.04 naming; not `filesystem.squashfs`) |

Phase 4 GRUB points casper at `/iso/ubuntu-….iso` with `layerfs-path=minimal.standard.live.squashfs` (see [architecture.md](architecture.md)).

## Force re-fetch / upgrade

1. Update `UBUNTU_DESKTOP_VERSION` and this pin table.
2. `./scripts/fetch-iso.sh --force`
3. Or remove `./data/iso/*.iso` and `./data/http/live/`, then re-run fetch.

## Out of scope for fetch/extract

- Serving (compose/nginx already does)
- Wiring GRUB/cmdline (phase 4)
- Autoinstall / seed generation

## Related

- [operations.md](operations.md) — prep order
- [phases/03-live-image-http.md](phases/03-live-image-http.md)
