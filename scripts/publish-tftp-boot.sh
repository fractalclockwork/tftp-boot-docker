#!/usr/bin/env bash
# Publish UEFI GRUB NBP + config into ./data/tftp (compose TFTP root).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TFTP_DIR="${ROOT}/data/tftp"
GRUB_DIR="${TFTP_DIR}/grub"
BOOTFILE="grubx64.efi"

mkdir -p "${GRUB_DIR}"

echo "Building ${BOOTFILE} into ${TFTP_DIR} via Debian container..."

docker run --rm \
  -v "${TFTP_DIR}:/out" \
  debian:bookworm-slim \
  bash -c '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends grub-efi-amd64-bin grub-common >/dev/null
    # Network-capable UEFI image; prefix points at TFTP path /grub
    grub-mkimage \
      -O x86_64-efi \
      -o /out/grubx64.efi \
      -p "(tftp)/grub" \
      all_video boot cat chain configfile echo efi_gop efi_uga \
      fat font gettext gfxterm gzio halt help http linux linuxefi \
      loadenv ls lsefi lsefimmap lsefisystab lssal memdisk minicmd \
      net efinet normal part_gpt part_msdos \
      probe reboot regexp search search_fs_file search_fs_uuid search_label \
      sleep tar test tftp time true
    chmod 644 /out/grubx64.efi
  '

# Placeholder menu only if no grub.cfg yet (publish-boot-chain.sh owns the live menu)
if [[ ! -f "${GRUB_DIR}/grub.cfg" ]]; then
  cat > "${GRUB_DIR}/grub.cfg" <<'EOF'
# tftp-boot-docker — served from TFTP as (tftp)/grub/grub.cfg
# Run ./scripts/publish-boot-chain.sh after fetch-iso for live Desktop entries.
set timeout=5
set default=0

menuentry "tftp-boot-docker (run publish-boot-chain.sh)" {
    echo "Fetched grub.cfg over TFTP."
    echo "Run ./scripts/publish-boot-chain.sh to enable live Desktop boot."
    sleep --interruptible 10
}
EOF
  chmod 644 "${GRUB_DIR}/grub.cfg"
fi

echo "Published:"
ls -la "${TFTP_DIR}/${BOOTFILE}" "${GRUB_DIR}/grub.cfg"
echo "Bootfile for OpenWrt: ${BOOTFILE}"
echo "GRUB prefix: (tftp)/grub  →  ${GRUB_DIR}/grub.cfg"
echo "For live Desktop menu: ./scripts/publish-boot-chain.sh"
