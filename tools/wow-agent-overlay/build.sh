#!/bin/sh
# Builds Murly.app next to this script. Usage: ./build.sh [--open]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
app="$here/Murly.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -O -o "$app/Contents/MacOS/Murly" "$here/main.swift"
cp "$here/index.html" "$app/Contents/Resources/"
# Frame art shared with the TDL addon, so Murly matches the in-game windows.
sips -s format png "$repo/TDL/Assets/Window.tga" --out "$app/Contents/Resources/frame.png" >/dev/null
sips -s format png "$repo/TDL/Assets/Background.tga" --out "$app/Contents/Resources/background.png" >/dev/null
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Murly</string>
  <key>CFBundleIdentifier</key><string>dev.wowforever.murly</string>
  <key>CFBundleName</key><string>Murly</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>WoWAgentRepo</key><string>$repo</string>
</dict></plist>
EOF
echo "Built $app"
[ "${1:-}" = "--open" ] && open "$app"
exit 0
