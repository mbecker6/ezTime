#!/bin/bash
# Builds a universal (Apple Silicon + Intel) ezTime.app and ezTime.zip into ./build
# Usage: VERSION=1.2.0 ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:-1.0.0}"

BINARIES=()
for arch in arm64 x86_64; do
    swift build -c release --triple "$arch-apple-macosx13.0"
    BINARIES+=(".build/$arch-apple-macosx/release/ezTime")
done

APP=build/ezTime.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create -output "$APP/Contents/MacOS/ezTime" "${BINARIES[@]}"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.eztime.app</string>
    <key>CFBundleName</key>
    <string>ezTime</string>
    <key>CFBundleExecutable</key>
    <string>ezTime</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc signature so macOS accepts the app as a login item.
codesign --force --sign - "$APP"

ditto -c -k --keepParent "$APP" build/ezTime.zip

echo "Built $APP and build/ezTime.zip (version $VERSION)"
