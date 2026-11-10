#!/bin/bash
# Fix MediaRemoteAdapter.framework layout after copying SwiftPM bundles into .app
set -euo pipefail
APP="${1:?Usage: repair-app-bundles.sh MacOSHub.app}"

repair_framework() {
  local fw="$1"
  local versions="$fw/Versions"
  [[ -d "$versions/A" ]] || return 0

  ln -sfn A "$versions/Current" 2>/dev/null || true

  local top="$fw/MediaRemoteAdapter"
  if [[ -L "$top" || -e "$top" ]]; then
    rm -f "$top"
  fi
  ln -s Versions/A/MediaRemoteAdapter "$top"

  for name in Headers Resources; do
  local link="$fw/$name"
    if [[ -L "$link" ]]; then
      rm -f "$link"
      ln -s "Versions/Current/$name" "$fw/$name"
    fi
  done
}

while IFS= read -r -d '' fw; do
  repair_framework "$fw"
done < <(find "$APP/Contents" -path '*/MediaRemoteAdapter.framework' -type d -print0)
