#!/usr/bin/env bash
# Fetch and verify the pinned Ubuntu live-server LTS ISO (docs/iso.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO_DIR="${ROOT}/data/iso"

# Single source of truth for the pin (override with env)
UBUNTU_VERSION="${UBUNTU_VERSION:-${UBUNTU_DESKTOP_VERSION:-26.04.1}}"
ISO_NAME="ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"
PRIMARY_BASE="https://releases.ubuntu.com/${UBUNTU_VERSION}"
FALLBACK_BASE="https://cdimage.ubuntu.com/ubuntu/releases/${UBUNTU_VERSION}/release"

FORCE=0
EXTRACT=1
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --no-extract) EXTRACT=0 ;;
    -h|--help)
      echo "Usage: $0 [--force] [--no-extract]"
      echo "  --force       Re-download SHA256SUMS and ISO even if present"
      echo "  --no-extract  Skip extracting casper tree into data/http/live/"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

mkdir -p "${ISO_DIR}"
cd "${ISO_DIR}"

download() {
  local url="$1" dest="$2"
  echo "Downloading ${url}"
  curl -fL --retry 3 --retry-delay 2 -o "${dest}.partial" "${url}"
  mv -f "${dest}.partial" "${dest}"
}

resolve_base() {
  if curl -fsSIL "${PRIMARY_BASE}/${ISO_NAME}" >/dev/null 2>&1; then
    echo "${PRIMARY_BASE}"
  elif curl -fsSIL "${FALLBACK_BASE}/${ISO_NAME}" >/dev/null 2>&1; then
    echo "${FALLBACK_BASE}"
  else
    echo "ERROR: cannot find ${ISO_NAME} under primary or fallback mirrors" >&2
    exit 1
  fi
}

BASE="$(resolve_base)"
echo "Using mirror base: ${BASE}"

if [[ "${FORCE}" -eq 1 ]] || [[ ! -f SHA256SUMS ]]; then
  download "${BASE}/SHA256SUMS" SHA256SUMS
else
  echo "SHA256SUMS present (use --force to refresh)"
fi

need_iso=0
if [[ "${FORCE}" -eq 1 ]] || [[ ! -f "${ISO_NAME}" ]]; then
  need_iso=1
elif ! grep -F "${ISO_NAME}" SHA256SUMS | sha256sum -c - >/dev/null 2>&1; then
  echo "Checksum mismatch or incomplete ISO; re-downloading"
  need_iso=1
fi

if [[ "${need_iso}" -eq 1 ]]; then
  download "${BASE}/${ISO_NAME}" "${ISO_NAME}"
fi

echo "Verifying ${ISO_NAME}..."
# Ubuntu SHA256SUMS uses "hash *filename" (binary indicator); match by name only
if ! grep -F "${ISO_NAME}" SHA256SUMS | sha256sum -c -; then
  echo "ERROR: checksum verification failed for ${ISO_NAME}" >&2
  exit 1
fi
echo "OK"

ISO_PATH="${ISO_DIR}/${ISO_NAME}"
echo "Verified ISO: ${ISO_PATH}"

if [[ "${EXTRACT}" -eq 1 ]]; then
  "${ROOT}/scripts/extract-live.sh" "${ISO_PATH}"
fi

echo "${ISO_PATH}"
