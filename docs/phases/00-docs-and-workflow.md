# Phase 0 — Docs and workflow

## Status

`done`

## Goal

Documentation scaffolding, ops contracts, ISO pull contract, OpenWrt setup docs, agentic phase packets, and the [phase implementation workflow](../workflow.md) exist and are consistent.

## Inputs

- Project intent: Docker TFTP + HTTP/NFS Ubuntu live PXE; DHCP on OpenWrt (see current [AGENTS.md](../../AGENTS.md))
- Plan decisions: AGENTS.md + phase packets + always-apply Cursor rule

## Tasks

- [x] Rewrite README with purpose, links, start/stop blurb
- [x] Add AGENTS.md orchestrator
- [x] Add docs/architecture.md, operations.md, iso.md, openwrt.md
- [x] Add phase packets 00–05
- [x] Add `docs/workflow.md` (phase implementation loop)
- [x] Add `.cursor/rules/tftp-boot-docker.mdc`
- [x] Add `.gitignore` for `data/` ISO blobs

## Acceptance criteria

- README, AGENTS.md, and docs agree on scope (TFTP + live image, OpenWrt DHCP, no autoinstall)
- Phase index in AGENTS.md matches files under `docs/phases/`
- `docs/workflow.md` defines the implementation loop and is linked from AGENTS.md / README / Cursor rule
- Operations, ISO, and OpenWrt docs are concrete contracts (not empty stubs)
- This phase marked `done`; phases 1–5 marked `pending`

## Out of scope

- Dockerfile, compose, fetch script implementation
- Downloading the ISO
- Changes on a live OpenWrt device
