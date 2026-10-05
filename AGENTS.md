# AGENTS.md — tftp-boot-docker

Instructions for AI agents working in this repository.

## Goals

Build a Docker stack that:

1. Serves a UEFI network boot chain over **TFTP**.
2. Serves one or more **Ubuntu live ISOs** (default: Server 26.04.1) over **HTTP/NFS**.
3. Integrates with **OpenWrt DHCP** (external); clients PXE-boot a **GRUB menu** to pick an image and run an interactive install (fits ~8 GiB RAM for live-server; no gateway required for install-from-image with `pool/`).

## Hard constraints

- **Do not** run a DHCP server in this container or compose stack.
- **Do not** enable a competing TFTP server on OpenWrt for the same clients.
- **Do not** add autoinstall / cloud-init / unattended install unless a new phase explicitly adds it.
- Trusted LAN only; do not design for WAN exposure.
- Do not `COPY` the multi‑GB ISO into Docker image layers; keep it on a host volume (see [docs/iso.md](docs/iso.md)).
- Treat [docs/operations.md](docs/operations.md), [docs/iso.md](docs/iso.md), and [docs/openwrt.md](docs/openwrt.md) as **contracts**. Implementation must match them or update those docs in the same change.

## How to work

**One phase per session.** Follow the full loop in [docs/workflow.md](docs/workflow.md) (orient → select → claim `in_progress` → implement → verify acceptance → close as `done` → handoff).

## Ops contracts

| Contract | When it matters |
|----------|-----------------|
| [docs/operations.md](docs/operations.md) | Phase 1+ (compose up/down, ports, volumes) |
| [docs/iso.md](docs/iso.md) | Phase 3+ (fetch); phase 6–7 (live-server pin, multi-ISO sync) |
| [docs/openwrt.md](docs/openwrt.md) | Phase 5 (verify); operators may apply earlier |

## Phases

| # | Packet | Status |
|---|--------|--------|
| 0 | [docs/phases/00-docs-and-workflow.md](docs/phases/00-docs-and-workflow.md) | done |
| 1 | [docs/phases/01-container-skeleton.md](docs/phases/01-container-skeleton.md) | done |
| 2 | [docs/phases/02-tftp-boot-files.md](docs/phases/02-tftp-boot-files.md) | done |
| 3 | [docs/phases/03-live-image-http.md](docs/phases/03-live-image-http.md) | done |
| 4 | [docs/phases/04-boot-chain.md](docs/phases/04-boot-chain.md) | done |
| 5 | [docs/phases/05-openwrt-integration.md](docs/phases/05-openwrt-integration.md) | done |
| 6 | [docs/phases/06-live-server-installer.md](docs/phases/06-live-server-installer.md) | done |
| 7 | [docs/phases/07-multi-iso-menu.md](docs/phases/07-multi-iso-menu.md) | done |

## Definition of done (project)

A PXE client on the LAN, using OpenWrt for DHCP, boots a GRUB menu of synced Ubuntu live ISOs (default: Server 26.04.1 live-server over NFS / subiquity) and can complete an interactive install without a default gateway when `pool/` is present.
