#!/usr/bin/env bash
# macos.sh — set sensible macOS defaults for developers
# Run once after setting up a new Mac: bash ~/dotfiles/macos.sh
# Most changes take effect immediately; some require logout/restart.
#
# To revert any setting, look up the corresponding `defaults delete` command.

set -euo pipefail

echo "Applying macOS developer defaults..."
echo "(You may be prompted for your password)"
echo ""

# ------------------
# Keyboard
# ------------------
# Key repeat: make keys repeat fast (critical for vim/terminal work)
defaults write NSGlobalDomain KeyRepeat -int 2           # repeat rate (lower = faster)
defaults write NSGlobalDomain InitialKeyRepeat -int 15   # delay before repeat starts

# Disable autocorrect and smart quotes (they break code)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

echo "[ok] Keyboard settings"

# ------------------
# Trackpad
# ------------------
# Enable tap-to-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

echo "[ok] Trackpad settings"

# ------------------
# Finder
# ------------------
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show status bar and path bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Default to list view in all Finder windows
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

echo "[ok] Finder settings"

# ------------------
# Screenshots
# ------------------
# Save to ~/Desktop/screenshots instead of cluttering the desktop
SCREENSHOT_DIR="$HOME/Desktop/screenshots"
mkdir -p "$SCREENSHOT_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

echo "[ok] Screenshots → $SCREENSHOT_DIR"

# ------------------
# Dock
# ------------------
# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay (instant show/hide)
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

# Smaller dock size
defaults write com.apple.dock tilesize -int 48

echo "[ok] Dock settings"

# ------------------
# Mission Control / Spaces
# ------------------
# Don't automatically rearrange Spaces
defaults write com.apple.dock mru-spaces -bool false

# Speed up Mission Control animation
defaults write com.apple.dock expose-animation-duration -float 0.1

echo "[ok] Mission Control settings"

# ------------------
# Activity Monitor
# ------------------
# Show all processes, not just user ones
defaults write com.apple.ActivityMonitor ShowCategory -int 0

echo "[ok] Activity Monitor settings"

# ------------------
# TextEdit
# ------------------
# Use plain text by default
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

echo "[ok] TextEdit settings"

# ------------------
# Apply changes
# ------------------
echo ""
echo "Restarting affected apps..."
for app in "Finder" "Dock" "SystemUIServer" "cfprefsd"; do
  killall "$app" &>/dev/null || true
done

echo ""
echo "[ok] Done. Some changes (key repeat, trackpad) require logout to take effect."
