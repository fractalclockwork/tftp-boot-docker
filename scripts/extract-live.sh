#!/usr/bin/env bash
# Extract one Ubuntu live ISO into data/http/live/<iso-stem>/ for NFS.
# Includes pool/ + dists/ when present (needed for offline Server install).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/iso-common.sh
source "${ROOT}/scripts/lib/iso-common.sh"

ISO_PATH=""
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      echo "Usage: $0 [path-to.iso] [--force]"
      exit 0
      ;;
    *)
      ISO_PATH="$arg"
      ;;
  esac
done

if [[ -z "${ISO_PATH}" ]]; then
  VERSION="${UBUNTU_VERSION:-${UBUNTU_DESKTOP_VERSION:-26.04.1}}"
  ISO_PATH="${ROOT}/data/iso/ubuntu-${VERSION}-live-server-amd64.iso"
fi

if [[ ! -f "${ISO_PATH}" ]]; then
  echo "ERROR: ISO not found: ${ISO_PATH}" >&2
  exit 1
fi

STEM="$(iso_stem "${ISO_PATH}")"
LIVE_DIR="${ROOT}/data/http/live/${STEM}"

mkdir -p "${LIVE_DIR}"

if [[ "${FORCE}" -eq 0 ]] \
  && [[ -f "${LIVE_DIR}/casper/vmlinuz" ]] \
  && [[ "${LIVE_DIR}/casper/vmlinuz" -nt "${ISO_PATH}" ]]; then
  if [[ -d "${LIVE_DIR}/pool" ]] || [[ "${STEM}" == *desktop* ]]; then
    echo "Live tree current: ${LIVE_DIR}"
    exit 0
  fi
fi

echo "Extracting ${ISO_PATH} → ${LIVE_DIR}"

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
    xorriso -osirrox on -indev /iso \
      -extract /casper /out/casper \
      -extract /.disk /out/.disk \
      -extract /dists /out/dists \
      -extract /pool /out/pool \
      || true
    if [[ ! -d /out/casper ]]; then
      echo "ERROR: casper/ not found in ISO" >&2
      exit 1
    fi
    chmod -R a+rX /out
  '

if [[ ! -f "${LIVE_DIR}/casper/vmlinuz" ]]; then
  echo "ERROR: extract incomplete (no vmlinuz)" >&2
  exit 1
fi

echo "Extracted ${STEM}:"
find "${LIVE_DIR}/casper" -maxdepth 1 -name '*.squashfs' -printf '  %f\t%s\n' | sort
[[ -d "${LIVE_DIR}/pool" ]] && du -sh "${LIVE_DIR}/pool" || echo "  (no pool/ — online apt may be required)"
echo "NFS path: /var/www/html/live/${STEM}"
