#!/usr/bin/env bash
# setup-scheduler.sh — schedule update.sh to run daily via launchd
#
# Usage:
#   bash ~/dotfiles/setup-scheduler.sh             # install (runs at 9 AM daily)
#   bash ~/dotfiles/setup-scheduler.sh --uninstall # remove the scheduled job
#
# Logs are written to ~/dotfiles/logs/update.log
# Edit LaunchAgents/com.dotfiles.update.plist to change the schedule.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_LABEL="com.dotfiles.update"
PLIST_SRC="$DOTFILES_DIR/LaunchAgents/$PLIST_LABEL.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
LOG_DIR="$DOTFILES_DIR/logs"

# shellcheck source=scripts/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/bootstrap_helpers.sh"
setup_colors

echo ""
printf "${BOLD}  ⏰  dotfiles scheduler${RESET}  —  launchd setup\n"
echo "  ─────────────────────────────────────────────────"

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  if launchctl list "$PLIST_LABEL" &>/dev/null 2>&1; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    success "Unloaded $PLIST_LABEL"
  fi
  if [[ -f "$PLIST_DEST" ]]; then
    rm -f "$PLIST_DEST"
    success "Removed $PLIST_DEST"
  fi
  echo ""
  info "Daily update scheduling removed"
  echo ""
  exit 0
fi

# ── Install ───────────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR" "$HOME/Library/LaunchAgents"

# Substitute __DOTFILES_DIR__ placeholder with the actual path
sed "s|__DOTFILES_DIR__|$DOTFILES_DIR|g" "$PLIST_SRC" > "$PLIST_DEST"

# Reload idempotently — unload any existing version first
launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"

echo ""
success "update.sh scheduled — runs daily at 9 AM"
info "Log:       $LOG_DIR/update.log"
info "Plist:     $PLIST_DEST"
info "Uninstall: bash ~/dotfiles/setup-scheduler.sh --uninstall"
echo ""
