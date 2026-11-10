#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARCH_DIR="$(swift build -c release --show-bin-path)"
swift build -c release
BIN="$ARCH_DIR/MacOSHub"
APP="$ROOT/.build/MacOSHub.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MacOSHub"
chmod +x "$APP/Contents/MacOS/MacOSHub"
cp "$ROOT/Sources/MacOSHub/Info.plist" "$APP/Contents/Info.plist"
shopt -s nullglob
for bundle in "$ARCH_DIR"/MacOSHub_*.bundle; do
  cp -R "$bundle" "$APP/Contents/MacOS/"
done
shopt -u nullglob
# App icon for Finder
if [[ -f "$ROOT/website/assets/AppIcon.icns" ]]; then
  cp "$ROOT/website/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP/Contents/Info.plist" 2>/dev/null || true
fi

APP="$ROOT/.build/MacOSHub.app"
OUT="$ROOT/website/downloads/MacOSHub.zip"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT"
echo "Created $OUT ($(du -h "$OUT" | awk '{print $1}'))"
