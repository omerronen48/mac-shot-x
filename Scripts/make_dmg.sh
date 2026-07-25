#!/usr/bin/env bash
# Build a downloadable mac-shot-x.dmg (drag-to-install). Works standalone:
#   - always: builds mac-shot-X.app (signed by make_app.sh with your available identity, else ad-hoc)
#     and packages it into a DMG with an /Applications drop target.
#   - if DEVELOPER_ID_APP + AC_NOTARY_PROFILE are set: also does hardened-runtime Developer-ID
#     signing + notarization + stapling, producing a DMG that opens with no Gatekeeper warning.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "Building mac-shot-X.app..."
bash "$SCRIPT_DIR/make_app.sh"

# Optional distribution signing (hardened runtime) — only if a Developer ID is provided.
if [ -n "${DEVELOPER_ID_APP:-}" ]; then
  echo "Signing app for distribution with: $DEVELOPER_ID_APP"
  codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APP" mac-shot-X.app
fi

echo "Staging DMG contents..."
STAGE="$(mktemp -d)"
cp -R mac-shot-X.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # drag-to-install target

echo "Creating DMG..."
rm -f mac-shot-x.dmg
hdiutil create -volname "mac-shot-X" -srcfolder "$STAGE" -ov -format UDZO mac-shot-x.dmg >/dev/null
rm -rf "$STAGE"

# Optional notarization — only if both a Developer ID and a notary profile are provided.
if [ -n "${DEVELOPER_ID_APP:-}" ] && [ -n "${AC_NOTARY_PROFILE:-}" ]; then
  echo "Submitting for notarization (this can take a few minutes)..."
  xcrun notarytool submit mac-shot-x.dmg --keychain-profile "$AC_NOTARY_PROFILE" --wait
  echo "Stapling notarization ticket..."
  xcrun stapler staple mac-shot-x.dmg
  echo ""
  echo "DMG: $REPO_ROOT/mac-shot-x.dmg — notarized, ready to distribute to anyone."
else
  echo ""
  echo "DMG: $REPO_ROOT/mac-shot-x.dmg — built (not notarized)."
  echo "Note: without a Developer ID + notarization, recipients open it via right-click → Open"
  echo "the first time (Gatekeeper). For a warning-free build, set DEVELOPER_ID_APP and"
  echo "AC_NOTARY_PROFILE and re-run."
fi
