#!/bin/sh
# Builds WoWAgent.app next to this script. Usage: ./build.sh [--open]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
app="$here/WoWAgent.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
swiftc -O -o "$app/Contents/MacOS/WoWAgent" "$here/main.swift"
cp "$here/index.html" "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>WoWAgent</string>
  <key>CFBundleIdentifier</key><string>dev.wowforever.agent-overlay</string>
  <key>CFBundleName</key><string>WoW Agent</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>WoWAgentRepo</key><string>$repo</string>
</dict></plist>
EOF
echo "Built $app"
[ "${1:-}" = "--open" ] && open "$app"
exit 0
