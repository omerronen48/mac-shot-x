#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DEVELOPER_ID_APP:-}" ]; then
    echo "Error: DEVELOPER_ID_APP is not set. Export your Developer ID Application certificate name."
    exit 1
fi
if [ -z "${AC_NOTARY_PROFILE:-}" ]; then
    echo "Error: AC_NOTARY_PROFILE is not set. Export your notarytool keychain profile name."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Building MacShot.app..."
bash "$SCRIPT_DIR/make_app.sh"

echo "Signing for distribution..."
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APP" MacShot.app

echo "Creating DMG..."
hdiutil create -volname MacShot -srcfolder MacShot.app -ov -format UDZO MacShot.dmg

echo "Submitting for notarization..."
xcrun notarytool submit MacShot.dmg --keychain-profile "$AC_NOTARY_PROFILE" --wait

echo "Stapling notarization ticket..."
xcrun stapler staple MacShot.dmg

echo ""
echo "DMG: $REPO_ROOT/MacShot.dmg — ready to distribute."
