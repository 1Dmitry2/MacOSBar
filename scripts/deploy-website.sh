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

ssh "$HOST" "chmod -R a+rX '$REMOTE_DIR' && command -v nginx >/dev/null && nginx -t && systemctl reload nginx || true"

echo "Deployed to $HOST:$REMOTE_DIR"
