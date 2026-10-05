#!/usr/bin/env bash
# Extract live boot payloads from the Desktop ISO into data/http/live/ for HTTP serving.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO_PATH="${1:-}"
LIVE_DIR="${ROOT}/data/http/live"

if [[ -z "${ISO_PATH}" ]]; then
  VERSION="${UBUNTU_DESKTOP_VERSION:-26.04.1}"
  ISO_PATH="${ROOT}/data/iso/ubuntu-${VERSION}-desktop-amd64.iso"
fi

if [[ ! -f "${ISO_PATH}" ]]; then
  echo "ERROR: ISO not found: ${ISO_PATH}" >&2
  exit 1
fi

mkdir -p "${LIVE_DIR}"

# Skip if kernel already present and newer than ISO
if [[ -f "${LIVE_DIR}/casper/vmlinuz" ]] \
  && [[ "${LIVE_DIR}/casper/vmlinuz" -nt "${ISO_PATH}" ]]; then
  echo "Live tree already extracted at ${LIVE_DIR} (use rm -rf data/http/live to force)"
  exit 0
fi

echo "Extracting casper (+ boot) from ${ISO_PATH} → ${LIVE_DIR}"

docker run --rm \
  -v "${ISO_PATH}:/iso:ro" \
  -v "${LIVE_DIR}:/out" \
  debian:bookworm-slim \
  bash -c '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends xorriso >/dev/null
    rm -rf /out/casper /out/.disk /out/dists /out/pool /out/preseed /out/install 2>/dev/null || true
    # Extract paths needed for HTTP live boot (phase 4 uses casper/)
    xorriso -osirrox on -indev /iso \
      -extract /casper /out/casper \
      -extract /.disk /out/.disk \
      || true
    # Some ISOs nest differently; ensure casper exists
    if [[ ! -d /out/casper ]]; then
      echo "ERROR: casper/ not found in ISO" >&2
      exit 1
    fi
    chmod -R a+rX /out
  '

echo "Extracted:"
find "${LIVE_DIR}/casper" -maxdepth 1 -type f | head -20
echo "HTTP paths: /live/casper/…  (see docs/iso.md)"
