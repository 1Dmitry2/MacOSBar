#!/bin/bash
# Deploy static site + download zip to VPS. Auth via SSH key or DEPLOY_SSH (not committed).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${DEPLOY_HOST:-root@82.148.238.138}"
REMOTE_DIR="${DEPLOY_DIR:-/var/www/mactools}"

"$ROOT/scripts/package-release.sh"

rsync -avz --delete \
  "$ROOT/website/" \
  "$HOST:$REMOTE_DIR/"

ssh "$HOST" bash -s <<REMOTE
set -euo pipefail
chmod -R a+rX '$REMOTE_DIR'
cp '$REMOTE_DIR/nginx-mactools.conf' /etc/nginx/sites-available/mactools.conf
ln -sf /etc/nginx/sites-available/mactools.conf /etc/nginx/sites-enabled/mactools.conf
if [[ -f /etc/nginx/stream.d/mywave-sni-mux.conf ]] && ! grep -q 'mactools.duckdns.org' /etc/nginx/stream.d/mywave-sni-mux.conf; then
  sed -i '/mywaveplayer\.duckdns\.org[[:space:]]*127\.0\.0\.1:8443;/a\    mactools.duckdns.org           127.0.0.1:8445;' /etc/nginx/stream.d/mywave-sni-mux.conf
fi
nginx -t
systemctl reload nginx
REMOTE

echo "Deployed to $HOST:$REMOTE_DIR"
