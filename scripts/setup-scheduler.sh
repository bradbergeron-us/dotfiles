#!/usr/bin/env bash
# setup-scheduler.sh — schedule update.sh to run daily via launchd
#
# Usage:
#   bash ~/dotfiles/scripts/setup-scheduler.sh              # install (runs at 9 AM daily)
#   bash ~/dotfiles/scripts/setup-scheduler.sh --no-upgrade # install; scheduled run skips upgrades
#   bash ~/dotfiles/scripts/setup-scheduler.sh --no-pull    # install; scheduled run skips git pull
#   bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall  # remove the scheduled job
#
# --no-upgrade / --no-pull are baked into the launchd plist's ProgramArguments,
# so the scheduled job runs e.g. `update.sh --no-upgrade`. For a machine-wide
# default that also applies to manual runs, set NO_UPGRADE=true in
# ~/.config/dotfiles/update.conf instead.
#
# Logs are written to ~/dotfiles/logs/update.log
# Edit system/LaunchAgents/com.dotfiles.update.plist to change the schedule.
#
# update.log is rotated automatically by update.sh (copytruncate-style) once it
# exceeds DOTFILES_LOG_MAX_BYTES (default 1 MiB), keeping DOTFILES_LOG_KEEP
# (default 5) rotated copies — so the launchd log can't grow unbounded.
# update.sh also writes ~/dotfiles/logs/update.status after every run with the
# last-run timestamp, overall success/failure, and any failed steps.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_LABEL="com.dotfiles.update"
PLIST_SRC="$DOTFILES_DIR/system/LaunchAgents/$PLIST_LABEL.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
LOG_DIR="$DOTFILES_DIR/logs"

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
setup_colors

# ── Parse args ────────────────────────────────────────────────────────────────
ACTION="install"
EXTRA_ARGS=()   # extra args baked into the scheduled update.sh invocation
for arg in "$@"; do
  case "$arg" in
    --uninstall)  ACTION="uninstall" ;;
    --no-upgrade) EXTRA_ARGS+=("--no-upgrade") ;;
    --no-pull)    EXTRA_ARGS+=("--no-pull") ;;
    --help|-h)
      cat <<'USAGE'
Usage: bash setup-scheduler.sh [OPTIONS]

  (no option)    Install the daily launchd job (runs update.sh at 9 AM)
  --no-upgrade   Install so the scheduled run is `update.sh --no-upgrade`
  --no-pull      Install so the scheduled run is `update.sh --no-pull`
  --uninstall    Remove the scheduled job
  --help, -h     Show this help

For a machine-wide default that also affects manual runs, set NO_UPGRADE=true
in ~/.config/dotfiles/update.conf instead.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)"
      exit 1
      ;;
  esac
done

echo ""
printf "${BOLD}  ⏰  dotfiles scheduler${RESET}  —  launchd setup\n"
echo "  ─────────────────────────────────────────────────"

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "uninstall" ]]; then
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

# Render the plist: substitute __DOTFILES_DIR__ and splice any extra update.sh
# args into ProgramArguments in place of the __UPDATE_ARGS__ marker (or drop the
# marker line when there are none). awk reads the multi-line block from the
# environment (ENVIRON) so embedded newlines are handled safely.
args_block=""
if (( ${#EXTRA_ARGS[@]} > 0 )); then
  args_block=$(printf '        <string>%s</string>\n' "${EXTRA_ARGS[@]}")
  args_block=${args_block%$'\n'}
fi
EXTRA_BLOCK="$args_block" awk -v dir="$DOTFILES_DIR" '
  { gsub(/__DOTFILES_DIR__/, dir) }
  /^[[:space:]]*__UPDATE_ARGS__[[:space:]]*$/ { if (ENVIRON["EXTRA_BLOCK"] != "") print ENVIRON["EXTRA_BLOCK"]; next }
  { print }
' "$PLIST_SRC" > "$PLIST_DEST"

# Reload idempotently — bootout any existing version first, then bootstrap
launchctl bootout "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

echo ""
if (( ${#EXTRA_ARGS[@]} > 0 )); then
  success "update.sh scheduled — runs daily at 9 AM (args: ${EXTRA_ARGS[*]})"
else
  success "update.sh scheduled — runs daily at 9 AM"
fi
info "Log:       $LOG_DIR/update.log (auto-rotated; keeps ${DOTFILES_LOG_KEEP:-5} copies)"
info "Status:    $LOG_DIR/update.status"
info "Plist:     $PLIST_DEST"
info "Uninstall: bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall"
echo ""
