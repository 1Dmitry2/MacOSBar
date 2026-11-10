#!/bin/bash
# Ad-hoc sign the .app after manual bundling (avoids "повреждено" from linker-signed + extra resources).
set -euo pipefail
APP="${1:?Usage: codesign-app.sh /path/to/MacOSHub.app}"

if [[ ! -d "$APP" ]]; then
  echo "Not a directory: $APP" >&2
  exit 1
fi

exec_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist" 2>/dev/null || echo MacOSHub)
main_exe="$APP/Contents/MacOS/$exec_name"

while IFS= read -r -d '' bin; do
  if file -b "$bin" | grep -q 'Mach-O'; then
    codesign --force --sign - --timestamp=none "$bin"
  fi
done < <(find "$APP/Contents" -type f -perm +111 ! -path "$main_exe" -print0)

while IFS= read -r -d '' bundle; do
  codesign --force --sign - --timestamp=none "$bundle"
done < <(find "$APP/Contents" -name '*.bundle' -print0 | sort -rz)

codesign --force --sign - --timestamp=none "$main_exe"
codesign --force --sign - --timestamp=none "$APP"
