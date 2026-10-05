# Architecture

## Roles

| Component | Owner | Responsibility |
|-----------|--------|----------------|
| DHCP / PXE options | OpenWrt (dnsmasq) | IP lease; advertise next-server (`TFTP_SERVER_IP`) and boot filename |
| TFTP | This container | NBP (`grubx64.efi`), GRUB config, per-image kernel/initrd under `/images/<stem>/` |
| HTTP | This container | All ISOs at `/iso/`; extracted trees at `/live/<stem>/` |
| NFS | This container | Per-ISO CD trees at `/var/www/html/live/<stem>/` for casper `netboot=nfs` |
| Live ISO blobs | Host volume | Official Ubuntu live ISOs under `./data/iso/` (not in image layers) |

OpenWrt must **point at** this host. It must not serve the same boot files from its own TFTP root.

## Boot flow

Default target: **UEFI** clients. Legacy BIOS is out of scope until a later phase adds it.

```text
PXE client
  → DHCP Discover/Request  → OpenWrt
  ← IP + next-server + bootfile (grubx64.efi)
  → TFTP get bootfile + GRUB menu
  → TFTP get /images/<stem>/{vmlinuz,initrd}
  → NFS mount /var/www/html/live/<stem> → Container :2049
  → Subiquity (Server) or Desktop live session
```

Kernel/initrd stay on TFTP. Squashfs and apt `pool/` stay on the server via **NFS**. Casper’s HTTP `url=` only accepts `*.iso` and downloads the whole file into RAM — optional high-RAM menu only. Default GRUB entry prefers live-server when present (~8 GiB OK).

## Design contracts (container)

These are the intended compose/runtime contracts. Implement in phase 1+; keep [operations.md](operations.md) in sync.

### Ports

| Port | Protocol | Service |
|------|----------|---------|
| 69 | UDP | TFTP |
| 80 | TCP | HTTP (ISO + extracted tree listing) |
| 111 | TCP/UDP | rpcbind (NFS) |
| 2049 | TCP/UDP | NFS (casper live media) |

Compose uses **`network_mode: host`** and **`privileged: true`** (kernel nfsd). Keep this table and [operations.md](operations.md) in sync if ports change.

### Volumes / paths

| Host path | Container path | Role |
|-----------|----------------|------|
| `./data/iso/` | `/data/iso` (ro) | Ubuntu live ISOs + checksums; HTTP `/iso/` |
| `./data/tftp/` | `/var/lib/tftpboot` | TFTP root (NBP, GRUB, `/images/<stem>/`) |
| `./data/http/` | `/var/www/html` | HTTP docroot; `live/<stem>/` → HTTP + NFS |

Compose service: **`tftp-boot`**. Networking: **`network_mode: host`** (binds host UDP 69 and TCP 80 directly). Bridge publish was abandoned for LAN PXE because TFTP data transfers through Docker NAT are unreliable. See [operations.md](operations.md).

### Environment (intended)

| Variable | Purpose |
|----------|---------|
| `TFTP_SERVER_IP` | LAN IP of the Docker host (documented for OpenWrt; may be informational in compose) |
| `HTTP_PORT` | Published HTTP port if not 80 |
| `UBUNTU_VERSION` | Pinned release string (see [iso.md](iso.md)); formerly `UBUNTU_DESKTOP_VERSION` |

### Planned UEFI bootfile

Default boot filename advertised by OpenWrt and served from the TFTP root:

```text
grubx64.efi
```

Publish with `./scripts/publish-tftp-boot.sh` (builds a network-capable GRUB EFI image via `grub-mkimage`).

### TFTP layout (phase 2+)

| TFTP path | Host path | Purpose |
|-----------|-----------|---------|
| `/grubx64.efi` | `./data/tftp/grubx64.efi` | UEFI NBP (OpenWrt bootfile) |
| `/grub/grub.cfg` | `./data/tftp/grub/grub.cfg` | Multi-ISO GRUB menu (`./scripts/sync-images.sh`) |
| `/images/<stem>/vmlinuz` | `./data/tftp/images/<stem>/vmlinuz` | Per-image kernel |
| `/images/<stem>/initrd` | `./data/tftp/images/<stem>/initrd` | Per-image initrd |
| `/casper/vmlinuz` | copy of default image | Compatibility path (same for `initrd`) |

**Why not HTTP `url=/live/…`?** Casper only enables HTTP netboot for `url=*.iso`. A directory URL is ignored (`Unable to find a medium containing a live file system`).

### Live boot chain (multi-ISO)

1. Client PXE-loads `grubx64.efi` from TFTP.
2. GRUB shows one menu group per extracted ISO under `data/http/live/<stem>/`.
3. Kernel/initrd load from TFTP `/images/<stem>/`.
4. Casper mounts **`nfsroot=TFTP_SERVER_IP:/var/www/html/live/<stem>`**.
5. Default entry prefers `*live-server*` when present (8 GiB-friendly subiquity + offline `pool/`).
6. Add ISOs anytime: copy into `data/iso/` → `./scripts/sync-images.sh`.

Regenerate:

```bash
./scripts/sync-images.sh
```

## Out of scope

- DHCP server inside this project
- Autoinstall / cloud-init / unattended install
- WAN / untrusted network deployment
- Baking the ISO into the Docker image with `COPY`
- Legacy BIOS PXE (unless a new phase adds it)
