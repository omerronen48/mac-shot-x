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

echo "Signing ad-hoc..."
codesign --force --deep --sign - "$APP"

echo ""
echo "Built: $APP"
echo "Drag MacShot.app to /Applications to install."
