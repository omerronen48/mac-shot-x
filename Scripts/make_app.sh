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

# Prefer a stable local code-signing identity if one exists (keeps the TCC/Screen-Recording
# grant across rebuilds); otherwise fall back to ad-hoc. Override with MACSHOT_SIGN_ID.
SIGN_ID="${MACSHOT_SIGN_ID:-MacShot Dev}"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$SIGN_ID"; then
  echo "Signing with identity: $SIGN_ID"
  codesign --force --deep --sign "$SIGN_ID" "$APP"
else
  echo "Signing ad-hoc (no '$SIGN_ID' identity; Screen-Recording grant resets each rebuild)..."
  codesign --force --deep --sign - "$APP"
fi

echo ""
echo "Built: $APP"
echo "Drag MacShot.app to /Applications to install."
