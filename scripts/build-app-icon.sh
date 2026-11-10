#!/bin/bash
# Build AppIcon.icns from website/assets/icon.svg (Quick Look thumbnail + iconutil).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/website/assets/icon.svg"
OUT_ICNS="$ROOT/website/assets/AppIcon.icns"
ICONSET="$ROOT/.build/AppIcon.iconset"
TMP_PNG="$ROOT/.build/AppIcon-1024.png"

mkdir -p "$ROOT/.build"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

qlmanage -t -s 1024 -o "$ROOT/.build" "$SVG" >/dev/null
mv "$ROOT/.build/$(basename "$SVG").png" "$TMP_PNG"

make_icon() {
  local size=$1
  local name=$2
  sips -z "$size" "$size" "$TMP_PNG" --out "$ICONSET/$name" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
cp "$TMP_PNG" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$OUT_ICNS"
echo "Wrote $OUT_ICNS"
