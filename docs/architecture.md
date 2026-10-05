# Architecture

## Roles

| Component | Owner | Responsibility |
|-----------|--------|----------------|
| DHCP / PXE options | OpenWrt (dnsmasq) | IP lease; advertise next-server (`TFTP_SERVER_IP`) and boot filename |
| TFTP | This container | NBP (UEFI bootloader), early bootloader config, kernel, initrd as needed |
| HTTP | This container | Ubuntu Desktop live ISO and/or extracted casper tree (squashfs, etc.) |
| Live ISO blob | Host volume | Downloaded from official Ubuntu mirrors; not stored in image layers |

OpenWrt must **point at** this host. It must not serve the same boot files from its own TFTP root.

## Boot flow

Default target: **UEFI** clients. Legacy BIOS is out of scope until a later phase adds it.

```text
PXE client
  → DHCP Discover/Request  → OpenWrt
  ← IP + next-server + bootfile (e.g. grubx64.efi)
  → TFTP get bootfile       → Container :69/udp
  → TFTP get config/kernel/initrd as directed by bootloader
  → HTTP get live root (casper / squashfs) → Container :80/tcp
  → Ubuntu Desktop live session
```

The Desktop live image is too large for practical TFTP transfer. After the bootloader/kernel handoff, content is fetched over HTTP.

## Design contracts (container)

These are the intended compose/runtime contracts. Implement in phase 1+; keep [docs/operations.md](operations.md) in sync.

### Ports

| Port | Protocol | Service |
|------|----------|---------|
| 69 | UDP | TFTP |
| 80 | TCP | HTTP (live image / casper) |

If host networking or alternate HTTP ports are chosen in phase 1, update this table and operations/OpenWrt docs together.

### Volumes / paths

| Host path | Container path | Role |
|-----------|----------------|------|
| `./data/iso/` | `/data/iso` (ro) | Downloaded Ubuntu Desktop ISO (and checksums); HTTP `/iso/` |
| `./data/tftp/` | `/var/lib/tftpboot` | TFTP root (NBP, bootloader config, kernel/initrd as published) |
| `./data/http/` | `/var/www/html` | HTTP docroot; extracted live tree under `live/` → HTTP `/live/` |

Compose service: **`tftp-boot`**. Networking: **`network_mode: host`** (binds host UDP 69 and TCP 80 directly). Bridge publish was abandoned for LAN PXE because TFTP data transfers through Docker NAT are unreliable. See [operations.md](operations.md).

### Environment (intended)

| Variable | Purpose |
|----------|---------|
| `TFTP_SERVER_IP` | LAN IP of the Docker host (documented for OpenWrt; may be informational in compose) |
| `HTTP_PORT` | Published HTTP port if not 80 |
| `UBUNTU_DESKTOP_VERSION` | Pinned release string (see [iso.md](iso.md)) |

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
| `/grub/grub.cfg` | `./data/tftp/grub/grub.cfg` | GRUB menu (`./scripts/publish-boot-chain.sh`) |
| `/casper/vmlinuz` | `./data/tftp/casper/vmlinuz` | Kernel (copied from live ISO casper) |
| `/casper/initrd` | `./data/tftp/casper/initrd` | Initrd (copied from live ISO casper) |

### Live boot chain (phase 4)

1. Client PXE-loads `grubx64.efi` from TFTP (`TFTP_SERVER_IP`).
2. GRUB loads `/casper/vmlinuz` + `/casper/initrd` from TFTP.
3. Casper downloads the Desktop ISO over HTTP: `http://TFTP_SERVER_IP/iso/ubuntu-26.04.1-desktop-amd64.iso`.
4. Default live layer: `layerfs-path=minimal.standard.live.squashfs` (“Try Ubuntu”).

Regenerate after changing `.env` or re-fetching the ISO:

```bash
./scripts/publish-boot-chain.sh
```

Desktop ISO netboot needs substantial client RAM (often ≥16 GiB) because casper pulls the full ISO into memory.

## Out of scope

- DHCP server inside this project
- Autoinstall / cloud-init / unattended install
- WAN / untrusted network deployment
- Baking the ISO into the Docker image with `COPY`
- Legacy BIOS PXE (unless a new phase adds it)
