#!/bin/bash
# Builds "Galaxy Shell.app".
#   scripts/build-app.sh            build into shell/build/
#   scripts/build-app.sh --install  also install it on this (your main) account and start it
#
# GalaxyOS runs on your main account (D3). It starts in GalaxyOS by default;
# press ctrl+opt+space to flip to macOS and back. scripts/uninstall.sh
# removes it and puts macOS's look back.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Galaxy Shell.app"
LABEL="com.galaxyos.shell"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
INSTALLED="$HOME/Applications/Galaxy Shell.app"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/GalaxyShell"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/GalaxyShell"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
  mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
  rm -rf "$INSTALLED"
  cp -R "$APP" "$INSTALLED"

  cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array><string>$INSTALLED/Contents/MacOS/GalaxyShell</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>LimitLoadToSessionType</key><string>Aqua</string>
</dict>
</plist>
PLIST

  launchctl bootstrap "gui/$UID" "$AGENT"
  echo "Installed and started. Galaxy Shell now starts every time you log in."
  echo "Press ctrl+opt+space any time to flip between GalaxyOS and macOS."
  echo "Note: each new build is a new signature, so macOS may ask for Accessibility access again"
  echo "(System Settings > Privacy & Security > Accessibility)."
fi
