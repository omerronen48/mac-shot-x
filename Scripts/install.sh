#!/usr/bin/env bash
# One-line installer — downloads the MacShot DMG and installs the app into /Applications,
# no git clone needed. Usage:
#   curl -fsSL https://raw.githubusercontent.com/omerronen48/mac-shot-x/main/Scripts/install.sh | bash
set -euo pipefail

DMG_URL="${MACSHOT_DMG_URL:-https://github.com/omerronen48/mac-shot-x/raw/main/MacShot.dmg}"
TMP="$(mktemp -d)"
DMG="$TMP/MacShot.dmg"
MOUNT="$TMP/mnt"

echo "Downloading MacShot…"
curl -fsSL "$DMG_URL" -o "$DMG"

echo "Mounting…"
mkdir -p "$MOUNT"
hdiutil attach "$DMG" -nobrowse -quiet -mountpoint "$MOUNT"

echo "Installing to /Applications…"
rm -rf "/Applications/MacShot.app"
cp -R "$MOUNT/MacShot.app" "/Applications/"

hdiutil detach "$MOUNT" -quiet || true
rm -rf "$TMP"

# Not notarized → clear the quarantine flag so it opens without a right-click dance.
xattr -dr com.apple.quarantine "/Applications/MacShot.app" 2>/dev/null || true

echo "Launching MacShot…"
open "/Applications/MacShot.app"

echo ""
echo "Installed. Grant Screen Recording when prompted (System Settings → Privacy &"
echo "Security → Screen Recording), then relaunch. Look for the MacShot menu-bar icon."
