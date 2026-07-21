#!/bin/bash
# One-time setup: create a LOCAL self-signed code-signing identity so MacShot's
# Screen-Recording (TCC) permission PERSISTS across rebuilds (no more re-granting).
#
# What it does (all reversible):
#   - creates a dedicated keychain `macshot-dev.keychain` (NOT your login keychain)
#   - generates a self-signed "MacShot Dev" code-signing certificate in it
#   - adds that keychain to your user search list so `codesign` can find the identity
#   - re-signs the current MacShot.app with it
# make_app.sh already prefers this "MacShot Dev" identity when present, so every future
# rebuild uses it automatically and the grant sticks.
#
# To UNDO everything later:
#   security delete-keychain macshot-dev.keychain
#   (and remove it from the search list via Keychain Access, or just delete-keychain)
#
# Review this script, then run:  ! bash /Users/omes/macshot/setup-signing.sh
set -euo pipefail

KC=macshot-dev.keychain
PW=macshotdev
CN="MacShot Dev"
TMP="$(mktemp -d)"
APP="/Users/omes/macshot-exec-m6-ship/MacShot.app"

echo "==> creating dedicated keychain (local, known password → no GUI prompts)"
security delete-keychain "$KC" 2>/dev/null || true
security create-keychain -p "$PW" "$KC"
security set-keychain-settings "$KC"                 # disable auto-lock timeout
security unlock-keychain -p "$PW" "$KC"

echo "==> generating self-signed code-signing certificate"
cat > "$TMP/cert.conf" <<'CONF'
[ req ]
distinguished_name = dn
x509_extensions = v3
prompt = no
[ dn ]
CN = MacShot Dev
[ v3 ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CONF
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/k.key" -out "$TMP/c.crt" -config "$TMP/cert.conf"
openssl pkcs12 -export -inkey "$TMP/k.key" -in "$TMP/c.crt" -out "$TMP/id.p12" -passout pass:mac

echo "==> importing into the dedicated keychain and authorizing codesign"
security import "$TMP/id.p12" -k "$KC" -P mac -A -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$PW" "$KC" >/dev/null

echo "==> adding the keychain to your user search list"
EXISTING=$(security list-keychains -d user | sed 's/[\" ]//g')
security list-keychains -d user -s "$KC" $EXISTING

rm -rf "$TMP"

echo "==> identity created:"
security find-identity -v -p codesigning | grep "$CN" || true

echo "==> re-signing the current app with the stable identity"
if [ -d "$APP" ]; then
  codesign --force --deep --sign "$CN" "$APP"
  echo "signed: $APP"
fi

echo ""
echo "DONE. Now: launch MacShot, grant Screen Recording ONCE, quit + relaunch."
echo "From here on, every rebuild is signed with '$CN' and the grant persists."
