#!/usr/bin/env bash
# Wraps dist/Paperclip.app into a drag-and-drop DMG installer.
#
#   ./scripts/make-dmg.sh             → dist/Paperclip-0.1.0.dmg
#
# Run ./scripts/build-app.sh first.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Paperclip"
APP_DIR="dist/$APP_NAME.app"

if [[ ! -d "$APP_DIR" ]]; then
    echo "error: $APP_DIR not found — run scripts/build-app.sh first" >&2
    exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
            "$APP_DIR/Contents/Info.plist" 2>/dev/null || echo "0.0.0")"

DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="dist/$DMG_NAME"
STAGE="$(mktemp -d)/dmg-stage"
mkdir -p "$STAGE"

cp -R "$APP_DIR" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG_PATH"
echo "==> creating $DMG_PATH"
hdiutil create -volname "$APP_NAME" \
               -srcfolder "$STAGE" \
               -ov -format UDZO \
               "$DMG_PATH" >/dev/null

rm -rf "$(dirname "$STAGE")"

echo "✓ wrote $DMG_PATH"
echo "  size: $(du -h "$DMG_PATH" | cut -f1)"
