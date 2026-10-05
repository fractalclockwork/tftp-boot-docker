#!/bin/sh
# NFSv3 for casper netboot=nfs — runs inside this container (not a host nfs-server package).
set -eu

LIVE_EXPORT="/var/www/html/live"

# Per-ISO trees live under live/<stem>/{casper,.disk}
ok=0
for d in "${LIVE_EXPORT}"/*/casper; do
  [ -d "$d" ] || continue
  stem=$(dirname "$d")
  if [ -d "${stem}/.disk" ]; then
    ok=1
    break
  fi
done
# Legacy flat layout
if [ -d "${LIVE_EXPORT}/casper" ] && [ -d "${LIVE_EXPORT}/.disk" ]; then
  ok=1
fi
if [ "$ok" -ne 1 ]; then
  echo "NFS: no live/<stem>/casper trees under ${LIVE_EXPORT} — run ./scripts/sync-images.sh" >&2
  sleep 5
  exit 1
fi

mkdir -p /run/rpcbind /run/rpc_pipefs /var/lib/nfs/sm /var/lib/nfs/sm.bak /var/lib/nfs/v4recovery /etc/nfs.conf.d
touch /run/rpcbind/rpcbind.lock 2>/dev/null || true

if ! mountpoint -q /run/rpc_pipefs 2>/dev/null; then
  mount -t rpc_pipefs sunrpc /run/rpc_pipefs 2>/dev/null || true
fi

# Kernel nfsd (compose privileged: true). Still one self-contained service.
if ! mountpoint -q /proc/fs/nfsd 2>/dev/null; then
  mount -t nfsd nfsd /proc/fs/nfsd 2>/dev/null || true
fi

# Stop any leftover nfsd threads from a previous container (host net + privileged).
rpc.nfsd 0 2>/dev/null || true
killall rpc.mountd 2>/dev/null || true
sleep 1

# network_mode: host — rpcbind may already exist on the Docker host; ignore clash
rpcbind -w 2>/dev/null || true

# Prefer TCP+UDP NFSv3; disable v4. Fixed mountd port for simpler LAN firewalls.
cat > /etc/nfs.conf.d/tftp-boot.conf <<'EOF'
[nfsd]
udp=y
tcp=y
vers3=y
vers4=n
vers4.0=n
vers4.1=n
vers4.2=n
threads=8

[mountd]
port=20048
EOF

exportfs -r
rpc.nfsd 8
exec rpc.mountd -F
