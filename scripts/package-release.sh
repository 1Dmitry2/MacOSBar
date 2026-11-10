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

chmod +x "$ROOT/scripts/repair-app-bundles.sh" "$ROOT/scripts/codesign-app.sh"
"$ROOT/scripts/repair-app-bundles.sh" "$APP"

ICNS="$ROOT/website/assets/AppIcon.icns"
if [[ -f "$ICNS" ]]; then
  cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$APP/Contents/Info.plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist"
fi

"$ROOT/scripts/codesign-app.sh" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

DOWNLOAD_DIR="$ROOT/website/downloads"
mkdir -p "$DOWNLOAD_DIR"
DMG="$DOWNLOAD_DIR/MacOSHub.dmg"
STAGE="$ROOT/.build/dmg-stage"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/MacOSHub.app"
cat >"$STAGE/Установка.txt" <<'EOF'
MacOSHub

1. Перетащите MacOSHub.app в папку «Программы».
2. Если macOS пишет «приложение повреждено» — это защита Gatekeeper после скачивания из интернета, а не битый файл.

   В Терминале выполните:
   xattr -cr /Applications/MacOSHub.app

   Либо: Системные настройки → Конфиденциальность и безопасность → «Всё равно открыть».

Сборка подписана локально (ad-hoc), без Apple Developer ID.
EOF
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "MacOSHub" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
rm -f "$DOWNLOAD_DIR/MacOSHub.zip"

echo "Created $DMG ($(du -h "$DMG" | awk '{print $1}'))"
