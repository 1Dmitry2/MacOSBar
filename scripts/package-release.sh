#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/build-app-icon.sh"

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

ICNS="$ROOT/website/assets/AppIcon.icns"
if [[ -f "$ICNS" ]]; then
  cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$APP/Contents/Info.plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist"
fi

DOWNLOAD_DIR="$ROOT/website/downloads"
mkdir -p "$DOWNLOAD_DIR"
DMG="$DOWNLOAD_DIR/MacOSHub.dmg"
STAGE="$ROOT/.build/dmg-stage"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/MacOSHub.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "MacOSHub" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
rm -f "$DOWNLOAD_DIR/MacOSHub.zip"

echo "Created $DMG ($(du -h "$DMG" | awk '{print $1}'))"
