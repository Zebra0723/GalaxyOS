#!/bin/bash
# Removes Galaxy Shell and puts macOS's own look back (Dock, menu bar,
# desktop icons, Spotlight shortcut), using the copy GalaxyOS saved when it
# was switched on. Works even if Galaxy Shell crashed while GalaxyOS was on.
set -euo pipefail

SUPPORT="$HOME/Library/Application Support/GalaxyOS"
SAVED="$SUPPORT/mac-look"
LABEL="com.galaxyos.shell"

read -r -p "Remove Galaxy Shell and restore macOS's look? Type yes: " answer
[[ "$answer" == "yes" ]] || { echo "Nothing changed."; exit 1; }

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/Galaxy Shell.app"

if [[ -f "$SAVED/galaxy-on" ]]; then
  [[ -f "$SAVED/dock.plist" ]] && defaults import com.apple.dock "$SAVED/dock.plist"
  [[ -f "$SAVED/finder.plist" ]] && defaults import com.apple.finder "$SAVED/finder.plist"
  [[ -f "$SAVED/symbolichotkeys.plist" ]] && defaults import com.apple.symbolichotkeys "$SAVED/symbolichotkeys.plist"
  case "$(cat "$SAVED/menubar-hidden.txt" 2>/dev/null || echo absent)" in
    1) defaults write -g _HIHideMenuBar -bool true ;;
    0) defaults write -g _HIHideMenuBar -bool false ;;
    *) defaults delete -g _HIHideMenuBar 2>/dev/null || true ;;
  esac
  rm -f "$SAVED/galaxy-on"
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  open -a Finder
  echo "macOS's look restored."
fi

echo "Galaxy Shell removed. Your settings.json is kept in $SUPPORT."
echo "Log out and back in once to finish."
