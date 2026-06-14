#!/usr/bin/env bash
# setup-scheduler.sh — schedule update.sh to run daily via launchd
#
# Usage:
#   bash ~/dotfiles/scripts/setup-scheduler.sh             # install (runs at 9 AM daily)
#   bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall # remove the scheduled job
#
# Logs are written to ~/dotfiles/logs/update.log
# Edit LaunchAgents/com.dotfiles.update.plist to change the schedule.
#
# update.log is rotated automatically by update.sh (copytruncate-style) once it
# exceeds DOTFILES_LOG_MAX_BYTES (default 1 MiB), keeping DOTFILES_LOG_KEEP
# (default 5) rotated copies — so the launchd log can't grow unbounded.
# update.sh also writes ~/dotfiles/logs/update.status after every run with the
# last-run timestamp, overall success/failure, and any failed steps.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
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
  if launchctl print "gui/$(id -u)/$PLIST_LABEL" &>/dev/null 2>&1; then
    launchctl bootout "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null || true
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

# Reload idempotently — bootout any existing version first, then bootstrap
launchctl bootout "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

echo ""
success "update.sh scheduled — runs daily at 9 AM"
info "Log:       $LOG_DIR/update.log (auto-rotated; keeps ${DOTFILES_LOG_KEEP:-5} copies)"
info "Status:    $LOG_DIR/update.status"
info "Plist:     $PLIST_DEST"
info "Uninstall: bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall"
echo ""
