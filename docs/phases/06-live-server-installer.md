# Phase 6 — Ubuntu Server live-server (8 GiB installer)

## Status

`done`

## Goal

Replace the Ubuntu **Desktop** live+installer default with **Ubuntu 26.04.1 live-server** so an 8 GiB PXE client can run an interactive subiquity install offline (no gateway). Keep the self-contained Docker stack (TFTP + HTTP + NFS). Desktop remains a post-install `apt` step when the machine has internet.

## Inputs

- Working stack through phase 5 (NFS live tree, host networking, OpenWrt PXE)
- [docs/iso.md](../iso.md) (updated pin)
- [docs/architecture.md](../architecture.md)
- [docs/laptop-pxe-test.md](../laptop-pxe-test.md)

## Tasks

- [x] Update AGENTS.md / README / iso.md / architecture contracts for live-server pin
- [x] Point fetch-iso + extract-live at `ubuntu-26.04.1-live-server-amd64.iso`; verify casper squashfs names
- [x] Republish GRUB: default NFS Server live; drop Desktop-minimized-without-installer
- [x] Update operations + laptop PXE docs (8 GiB, no-gateway install, desktop later)
- [x] Fetch ISO, extract, rebuild/republish, verify HTTP/NFS/TFTP + GRUB cmdline

## Acceptance criteria

- `./scripts/fetch-iso.sh` verifies `ubuntu-26.04.1-live-server-amd64.iso` and extracts `data/http/live/{casper,.disk}`
- Default GRUB entry uses `netboot=nfs` with a server squashfs `layerfs-path` (not Desktop `minimal.standard.live.squashfs`)
- Container exports NFS `/var/www/html/live`; TFTP serves server `vmlinuz`/`initrd`
- Docs state: interactive Server install works without gateway; Desktop via apt after internet

## Verification

```text
Verified ISO: ubuntu-26.04.1-live-server-amd64.iso (~2.7GiB)
Extracted layerfs: ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs
GRUB default: netboot=nfs nfsroot=192.168.1.111:/var/www/html/live layerfs-path=…installer.generic.squashfs
supervisor: tftpd/nginx/nfs RUNNING; exportfs /var/www/html/live; NFS mount OK
HTTP 200 / ; live-server squashfs Range OK
```

Hardware PXE → subiquity on the lab 8 GiB laptop is the operator smoke test ([laptop-pxe-test.md](../laptop-pxe-test.md)).

## Out of scope

- Autoinstall / cloud-init
- Local apt/Debian mirror
- Switching the project to Debian
- Keeping Desktop as the default boot target
