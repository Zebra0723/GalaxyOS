#!/bin/bash
# Turns the CURRENT macOS account into the Galaxy world.
#
# Run it while logged into the account you created for GalaxyOS. NEVER run
# it in your normal Mac account: the Mac world must stay untouched (D1).
#
# It only changes this account's own preferences, and it saves a backup
# first. undo-galaxy-world.sh puts everything back.
set -euo pipefail

SUPPORT="$HOME/Library/Application Support/GalaxyOS"
BACKUP="$SUPPORT/backup"
MARKER="$SUPPORT/.galaxy-world"

echo "This turns the account '$USER' into the Galaxy world:"
echo "  - Dock hidden, macOS menu bar auto-hidden, desktop icons off"
echo "  - Finder can be quit, Spotlight's ⌘Space handed to Galaxy Launcher"
echo "  - light appearance (the clean light default)"
echo
read -r -p "Type the account name ($USER) to confirm: " answer
if [[ "$answer" != "$USER" ]]; then
  echo "Didn't match. Nothing changed."
  exit 1
fi

if [[ -f "$MARKER" ]]; then
  echo "Already set up; re-applying (the original backup is kept)."
else
  mkdir -p "$BACKUP"
  defaults export com.apple.dock "$BACKUP/dock.plist"
  defaults export com.apple.finder "$BACKUP/finder.plist"
  defaults export NSGlobalDomain "$BACKUP/global.plist"
  defaults export com.apple.symbolichotkeys "$BACKUP/symbolichotkeys.plist"
  echo "Backup saved in $BACKUP"
fi

# Dock: hidden, and so slow to reveal that it never appears.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock no-bouncing -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

# macOS menu bar: auto-hide (the Galaxy bar sits in its place).
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Finder: no desktop icons, and allowed to quit.
defaults write com.apple.finder CreateDesktop -bool false
defaults write com.apple.finder QuitMenuItem -bool true

# Spotlight ⌘Space (64) and ⌥⌘Space (65) off, so Galaxy Launcher gets ⌘Space.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "<dict><key>enabled</key><false/></dict>"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true

# Clean light default (D13).
defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true

mkdir -p "$SUPPORT"
touch "$MARKER"

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo
echo "Done. Next:"
echo "  1. cd into GalaxyOS/shell and run: scripts/build-app.sh --install"
echo "  2. Allow Galaxy Shell in System Settings > Privacy & Security > Accessibility"
echo "  3. Log out and back in once, so the menu bar change fully applies"
