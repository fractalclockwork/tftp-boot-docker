#!/bin/sh
set -eu

mkdir -p /var/lib/tftpboot /var/www/html /data/iso

# Placeholder HTTP page when the http volume has no index
if [ ! -f /var/www/html/index.html ]; then
  cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>tftp-boot-docker</title>
</head>
<body>
  <h1>tftp-boot-docker</h1>
  <ul>
    <li><a href="/iso/">/iso/</a> — Ubuntu live ISOs + SHA256SUMS (host <code>./data/iso</code>)</li>
    <li><a href="/live/">/live/</a> — per-ISO trees <code>&lt;stem&gt;/</code> (NFS-exported)</li>
  </ul>
</body>
</html>
EOF
fi

chmod -R a+rX /var/lib/tftpboot 2>/dev/null || true

exec "$@"
