#!/bin/bash
# Puts this account back exactly as it was before setup-galaxy-world.sh,
# and removes Galaxy Shell from it.
set -euo pipefail

SUPPORT="$HOME/Library/Application Support/GalaxyOS"
BACKUP="$SUPPORT/backup"
LABEL="com.galaxyos.shell"

if [[ ! -d "$BACKUP" ]]; then
  echo "No backup found in $BACKUP, so this account was never set up. Nothing to undo."
  exit 1
fi

read -r -p "Undo the Galaxy world for '$USER'? Type yes: " answer
[[ "$answer" == "yes" ]] || { echo "Nothing changed."; exit 1; }

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/Galaxy Shell.app"

defaults import com.apple.dock "$BACKUP/dock.plist"
defaults import com.apple.finder "$BACKUP/finder.plist"
defaults import NSGlobalDomain "$BACKUP/global.plist"
defaults import com.apple.symbolichotkeys "$BACKUP/symbolichotkeys.plist"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true

rm -f "$SUPPORT/.galaxy-world"

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
open -a Finder

echo "Done. Your settings.json is kept in $SUPPORT in case you want it later."
echo "Log out and back in once to finish."
