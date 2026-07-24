#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Building universal release binary..."
swift build -c release --arch arm64 --arch x86_64

BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
BINARY="$BIN_DIR/MacShot"

APP="$REPO_ROOT/MacShot.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/MacShot"
cp "$SCRIPT_DIR/Info.plist" "$APP/Contents/Info.plist"

if [ ! -f "$SCRIPT_DIR/AppIcon.icns" ]; then bash "$SCRIPT_DIR/make_icon.sh"; fi
cp "$SCRIPT_DIR/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Copy SwiftPM resource bundles (e.g. MacShot_MacShot.bundle holding Localizable.xcstrings)
# so Bundle.module / String(localized:bundle:.module) can find them — otherwise the app
# fatal-errors at the first localized string.
for b in "$BIN_DIR"/*.bundle; do
  [ -e "$b" ] && cp -R "$b" "$APP/Contents/Resources/" && echo "bundled resource: $(basename "$b")"
done

# Sign with a stable identity so the TCC/Screen-Recording grant persists across rebuilds.
# Priority: MACSHOT_SIGN_ID → any real identity in the keychain (Apple Development, etc.) → ad-hoc.
SIGN_ID="${MACSHOT_SIGN_ID:-}"
if [ -z "$SIGN_ID" ]; then
  SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/"/{print $2; exit}')
fi
if [ -n "$SIGN_ID" ] && security find-identity -v -p codesigning 2>/dev/null | grep -qF "$SIGN_ID"; then
  echo "Signing with identity: $SIGN_ID"
  codesign --force --deep --sign "$SIGN_ID" "$APP"
else
  echo "Signing ad-hoc (no signing identity found; Screen-Recording grant resets each rebuild)..."
  codesign --force --deep --sign - "$APP"
fi

echo ""
echo "Built: $APP"
echo "Drag MacShot.app to /Applications to install."
