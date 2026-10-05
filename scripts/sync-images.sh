#!/usr/bin/env bash
# Discover data/iso/*.iso, extract live trees, publish multi-image GRUB menu.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO_DIR="${ROOT}/data/iso"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      echo "Usage: $0 [--force]"
      echo "  Scan data/iso/*.iso, extract to data/http/live/<stem>/, regenerate GRUB."
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

shopt -s nullglob
isos=("${ISO_DIR}"/*.iso)
if [[ "${#isos[@]}" -eq 0 ]]; then
  echo "ERROR: no ISOs in ${ISO_DIR} — run ./scripts/fetch-iso.sh or copy an ISO there" >&2
  exit 1
fi

echo "Found ${#isos[@]} ISO(s) in ${ISO_DIR}"
for iso in "${isos[@]}"; do
  if [[ "${FORCE}" -eq 1 ]]; then
    "${ROOT}/scripts/extract-live.sh" "${iso}" --force
  else
    "${ROOT}/scripts/extract-live.sh" "${iso}"
  fi
done

"${ROOT}/scripts/publish-boot-chain.sh"
echo "Done. PXE clients will see a GRUB menu for each extracted image."
