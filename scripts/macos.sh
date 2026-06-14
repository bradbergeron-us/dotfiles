#!/usr/bin/env bash
# macos.sh — set sensible macOS defaults for developers
# Run once after setting up a new Mac: bash ~/dotfiles/scripts/macos.sh
# Most changes take effect immediately; some require logout/restart.
#
# To revert any setting, look up the corresponding `defaults delete` command.

set -euo pipefail

printf "  → Applying macOS developer defaults...\n"
printf "  (You may be prompted for your password)\n"
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

printf "  ✓ Keyboard — fast repeat, no autocorrect, no smart quotes\n"

# ------------------
# Trackpad
# ------------------
# Enable tap-to-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

printf "  ✓ Trackpad — tap-to-click enabled\n"

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

printf "  ✓ Finder — show hidden files, all extensions, path bar, list view\n"

# ------------------
# Screenshots
# ------------------
# Save to ~/Desktop/screenshots instead of cluttering the desktop
SCREENSHOT_DIR="$HOME/Desktop/screenshots"
mkdir -p "$SCREENSHOT_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

printf "  ✓ Screenshots → %s\n" "$SCREENSHOT_DIR"

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

printf "  ✓ Dock — auto-hide, instant show/hide, no recent apps\n"

# ------------------
# Mission Control / Spaces
# ------------------
# Don't automatically rearrange Spaces
defaults write com.apple.dock mru-spaces -bool false

# Speed up Mission Control animation
defaults write com.apple.dock expose-animation-duration -float 0.1

printf "  ✓ Mission Control — faster animation, stable Spaces order\n"

# ------------------
# Activity Monitor
# ------------------
# Show all processes, not just user ones
defaults write com.apple.ActivityMonitor ShowCategory -int 0

printf "  ✓ Activity Monitor — show all processes\n"

# ------------------
# TextEdit
# ------------------
# Use plain text by default
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

printf "  ✓ TextEdit — plain text mode by default\n"

# ------------------
# Apply changes
# ------------------
echo ""
printf "  → Restarting affected apps (Finder, Dock)...\n"
for app in "Finder" "Dock" "SystemUIServer" "cfprefsd"; do
  killall "$app" &>/dev/null || true
done

echo ""
printf "  ✓ Done. Key repeat and trackpad changes take full effect after logout.\n"
