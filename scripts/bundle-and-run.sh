#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/build-app-icon.sh" 2>/dev/null || true

ARCH_DIR="$(swift build -c release --show-bin-path)"
BIN="$ARCH_DIR/MacOSHub"
APP="$ROOT/.build/MacOSHub.app"

swift build -c release

pkill -x MacOSHub 2>/dev/null || true
sleep 0.3

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/MacOSHub"
chmod +x "$APP/Contents/MacOS/MacOSHub"
cp "$ROOT/Sources/MacOSHub/Info.plist" "$APP/Contents/Info.plist"
ICNS="$ROOT/website/assets/AppIcon.icns"
if [[ -f "$ICNS" ]]; then
  cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
fi

# SwiftPM resource bundles must sit beside the executable for Bundle.module.
shopt -s nullglob
for bundle in "$ARCH_DIR"/MacOSHub_*.bundle; do
  cp -R "$bundle" "$APP/Contents/MacOS/"
done
shopt -u nullglob

open "$APP"
echo "Launched $APP"
