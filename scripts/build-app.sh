#!/usr/bin/env bash
# Builds Paperclip as a distributable macOS .app bundle.
#
#   ./scripts/build-app.sh              → dist/Paperclip.app
#   ./scripts/build-app.sh --open       → also opens the resulting bundle
#
# Steps:
#   1. swift build -c release
#   2. assemble Paperclip.app/Contents/{MacOS, Resources, Info.plist}
#   3. render & convert AppIcon.icns
#   4. ad-hoc codesign so Gatekeeper doesn't immediately block first launch

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Paperclip"
BUNDLE_ID="com.sergesiluyanov.paperclip"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES_DIR="$CONTENTS/Resources"
INFO_PLIST_SRC="Resources/Info.plist"

echo "==> swift build -c release"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN" ]]; then
    echo "error: built binary not found at $BIN" >&2
    exit 1
fi

echo "==> assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

cp "$BIN" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$INFO_PLIST_SRC" "$CONTENTS/Info.plist"

echo "==> generating icon"
ICON_PNG="$DIST_DIR/AppIcon-1024.png"
ICON_SET="$DIST_DIR/AppIcon.iconset"

swift scripts/render-icon.swift "$ICON_PNG"

rm -rf "$ICON_SET"
mkdir "$ICON_SET"
sips -z 16   16   "$ICON_PNG" --out "$ICON_SET/icon_16x16.png"     >/dev/null
sips -z 32   32   "$ICON_PNG" --out "$ICON_SET/icon_16x16@2x.png"  >/dev/null
sips -z 32   32   "$ICON_PNG" --out "$ICON_SET/icon_32x32.png"     >/dev/null
sips -z 64   64   "$ICON_PNG" --out "$ICON_SET/icon_32x32@2x.png"  >/dev/null
sips -z 128  128  "$ICON_PNG" --out "$ICON_SET/icon_128x128.png"   >/dev/null
sips -z 256  256  "$ICON_PNG" --out "$ICON_SET/icon_128x128@2x.png">/dev/null
sips -z 256  256  "$ICON_PNG" --out "$ICON_SET/icon_256x256.png"   >/dev/null
sips -z 512  512  "$ICON_PNG" --out "$ICON_SET/icon_256x256@2x.png">/dev/null
sips -z 512  512  "$ICON_PNG" --out "$ICON_SET/icon_512x512.png"   >/dev/null
cp                "$ICON_PNG" "$ICON_SET/icon_512x512@2x.png"
iconutil -c icns "$ICON_SET" -o "$RES_DIR/AppIcon.icns"

echo "==> ad-hoc codesigning"
# Ad-hoc signing (--sign -) means the app isn't notarised, so Gatekeeper
# will still warn on first launch ("приложение от неустановленного
# разработчика").  Right-click → Open the first time, or run:
#     xattr -dr com.apple.quarantine $APP_DIR
codesign --force --deep --options runtime --sign - "$APP_DIR"

echo "==> verifying"
codesign --verify --deep --strict --verbose=2 "$APP_DIR" 2>&1 | tail -5
echo
ls -la "$APP_DIR/Contents/MacOS"

echo
echo "✓ built $APP_DIR"
echo "  copy to /Applications, or run: open '$APP_DIR'"

if [[ "${1:-}" == "--open" ]]; then
    open "$APP_DIR"
fi
