#!/bin/bash
# Installs the latest ezTime release into /Applications and starts it.
# Usage: curl -fsSL https://raw.githubusercontent.com/mbecker6/ezTime/main/install.sh | bash
set -euo pipefail

REPO="mbecker6/ezTime"
URL="https://github.com/$REPO/releases/latest/download/ezTime.zip"
DEST="/Applications"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading ezTime..."
curl -fsSL "$URL" -o "$TMP/ezTime.zip"
ditto -x -k "$TMP/ezTime.zip" "$TMP"

# Stop a running copy before replacing it.
pkill -x ezTime 2>/dev/null || true

if [ ! -w "$DEST" ]; then
    DEST="$HOME/Applications"
    mkdir -p "$DEST"
fi
rm -rf "$DEST/ezTime.app"
mv "$TMP/ezTime.app" "$DEST/"

# The app is not notarized; clear the download flag so Gatekeeper doesn't block it.
xattr -dr com.apple.quarantine "$DEST/ezTime.app" 2>/dev/null || true

open "$DEST/ezTime.app"
echo "Installed ezTime to $DEST/ezTime.app. Look for the clock in your menu bar."
