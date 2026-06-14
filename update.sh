#!/usr/bin/env bash
# update.sh — keep your development environment current
#
# Run manually:     bash ~/dotfiles/update.sh
# Schedule daily with launchd (one command):
#   bash ~/dotfiles/scripts/setup-scheduler.sh             # install
#   bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall # remove
#
# What it does:
#   1. Pulls latest dotfiles from GitHub
#   2. Re-runs install.sh to pick up any new symlinks
#   3. Upgrades all Homebrew packages
#   4. Upgrades all mise-managed runtimes
#   5. Updates the Rust toolchain via rustup
#   6. Updates global Ruby gems
#   7. Runs verify.sh health check
#
# Self-healing / observability:
#   * Individual step failures no longer abort the run — every step is attempted
#     and any that fail are collected and reported at the end.
#   * On completion a status file is written to logs/update.status capturing the
#     last-run timestamp, overall success/failure, which step(s) failed, and the
#     run duration. This makes failures of the daily launchd job visible.
#   * On failure a macOS notification is posted (osascript). This is skipped in
#     CI and non-GUI/headless contexts so it is always safe to run.
#
# Log rotation:
#   The launchd job appends stdout/stderr to logs/update.log. To keep it from
#   growing unbounded, update.log is rotated (copytruncate-style, so launchd's
#   open file descriptor keeps appending) at the start of each run once it
#   exceeds a size threshold. Tunable via environment variables:
#     DOTFILES_LOG_MAX_BYTES  rotate when update.log exceeds this size
#                             (default: 1048576 = 1 MiB)
#     DOTFILES_LOG_KEEP       number of rotated copies to keep
#                             (default: 5 -> update.log.1 .. update.log.5)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
UPDATE_START=$SECONDS
# shellcheck disable=SC2034  # used by step() in helpers
STEP=0
# shellcheck disable=SC2034
TOTAL_STEPS=7

LOG_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOG_DIR/update.log"
STATUS_FILE="$LOG_DIR/update.status"
LOG_MAX_BYTES="${DOTFILES_LOG_MAX_BYTES:-1048576}"  # 1 MiB
LOG_KEEP="${DOTFILES_LOG_KEEP:-5}"

# Steps whose work failed during this run (reported in the summary + status file)
FAILED_STEPS=()

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$(dirname "$0")/scripts/lib/bootstrap_helpers.sh"
setup_colors

# ── Observability helpers ─────────────────────────────────────────────────────
mark_failure() { FAILED_STEPS+=("$1"); }

# rotate_log — copytruncate-style rotation of logs/update.log.
# Runs before any of this run's output is produced so the current run lands in a
# freshly truncated file. Truncating in place (rather than mv) keeps launchd's
# already-open file descriptor valid so it continues appending to the same inode.
rotate_log() {
  [[ -f "$LOG_FILE" ]] || return 0
  [[ "$LOG_MAX_BYTES" =~ ^[0-9]+$ ]] || return 0
  [[ "$LOG_KEEP" =~ ^[0-9]+$ ]] && (( LOG_KEEP >= 1 )) || return 0

  local size
  size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
  size=${size//[[:space:]]/}
  [[ "$size" =~ ^[0-9]+$ ]] || return 0
  (( size > LOG_MAX_BYTES )) || return 0

  # Shift existing rotations: .(KEEP-1) -> .KEEP, ... , .1 -> .2 (oldest dropped)
  local i
  for (( i = LOG_KEEP - 1; i >= 1; i-- )); do
    [[ -f "$LOG_FILE.$i" ]] && mv -f "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
  done
  cp "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null || return 0
  : > "$LOG_FILE"
  rm -f "$LOG_FILE.$((LOG_KEEP + 1))" 2>/dev/null || true
}

# can_notify — true only in an interactive macOS GUI (Aqua) session, never in CI
# or headless/ssh contexts, so notifications are always safe to attempt.
can_notify() {
  [[ -z "${CI:-}" ]] || return 1
  command -v osascript &>/dev/null || return 1
  [[ "$(launchctl managername 2>/dev/null || true)" == "Aqua" ]] || return 1
  return 0
}

notify() {
  local title="$1" msg="$2"
  can_notify || return 0
  osascript -e "display notification \"$msg\" with title \"$title\"" &>/dev/null || true
}

write_status() {
  local ts="$1" run_status="$2" failed="$3" elapsed="$4"
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  {
    echo "last_run=$ts"
    echo "status=$run_status"
    echo "failed_steps=$failed"
    echo "duration_seconds=$elapsed"
  } > "$STATUS_FILE" 2>/dev/null || true
}

# finalize — runs on EXIT (normal or aborted). Writes the status file, prints the
# summary banner, and notifies on failure. Always runs so failures of the daily
# launchd job are recorded even if a step aborts the script unexpectedly.
finalize() {
  local code=$?
  trap - EXIT

  local elapsed=$(( SECONDS - UPDATE_START ))
  local mins=$(( elapsed / 60 ))
  local secs=$(( elapsed % 60 ))

  # An unexpected abort (nonzero exit) with no recorded step counts as a failure.
  if (( code != 0 )) && (( ${#FAILED_STEPS[@]} == 0 )); then
    FAILED_STEPS+=("aborted (exit $code)")
  fi

  local failed_list=""
  if (( ${#FAILED_STEPS[@]} > 0 )); then
    failed_list=$(printf '%s, ' "${FAILED_STEPS[@]}")
    failed_list=${failed_list%, }
  fi

  local run_status="success"
  (( ${#FAILED_STEPS[@]} > 0 )) && run_status="failure"

  write_status "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$run_status" "$failed_list" "$elapsed"

  echo ""
  echo "  ─────────────────────────────────────────────────"
  if [[ "$run_status" == "success" ]]; then
    printf "${GREEN}${BOLD}  ✅  Update complete${RESET}  in %dm %ds\n" "$mins" "$secs"
  else
    printf "${YELLOW}${BOLD}  ⚠️  Update finished with issues${RESET}  in %dm %ds\n" "$mins" "$secs"
    printf "${YELLOW}  Failed: %s${RESET}\n" "$failed_list"
    notify "dotfiles update failed" "Steps with issues: $failed_list"
    (( code == 0 )) && code=1
  fi
  echo "  ─────────────────────────────────────────────────"
  echo ""

  exit "$code"
}
trap finalize EXIT

rotate_log

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🔄  dotfiles update${RESET}  —  keeping your environment current\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"

# ── Steps ─────────────────────────────────────────────────────────────────────

step "🔃  Dotfiles"
if git -C "$DOTFILES_DIR" pull --rebase --autostash; then
  success "Dotfiles pulled"
else
  warn "Dotfiles pull failed — continuing"
  mark_failure "Dotfiles"
fi

step "🔗  Symlinks"
if ! zsh "$DOTFILES_DIR/install.sh"; then
  warn "Symlink install failed — continuing"
  mark_failure "Symlinks"
fi

step "🍺  Homebrew"
if ! brew update; then
  warn "brew update failed — continuing"
  mark_failure "Homebrew"
fi
if brew upgrade; then
  success "All Homebrew packages upgraded"
else
  warn "Some Homebrew packages failed to upgrade — continuing anyway"
  mark_failure "Homebrew"
fi
brew autoremove 2>/dev/null || true
brew cleanup --prune=7 2>/dev/null || true  # remove downloads older than 7 days
success "Homebrew update complete"

step "⚡  Runtimes (mise)"
if command -v mise &>/dev/null; then
  if mise upgrade; then
    success "Runtimes upgraded: $(mise current 2>/dev/null | tr '\n' ' ' || true)"
  else
    warn "mise upgrade failed — continuing"
    mark_failure "Runtimes (mise)"
  fi
else
  warn "mise not installed — skipping runtime upgrades"
fi

step "🦀  Rust"
if command -v rustup &>/dev/null; then
  if rustup update; then
    success "Rust toolchain updated: $(rustc --version 2>/dev/null || true)"
  else
    warn "rustup update failed — continuing"
    mark_failure "Rust"
  fi
else
  warn "rustup not installed — skipping"
fi

step "💎  Ruby gems"
if command -v gem &>/dev/null; then
  if gem update --system --no-document 2>/dev/null; then
    success "Global gems updated"
  else
    warn "gem update failed — continuing"
    mark_failure "Ruby gems"
  fi
else
  warn "gem not found — skipping (mise Ruby may not be active)"
fi

# uv tool upgrade — updates globally installed tools (black, ruff, etc.)
# brew upgrade updates the uv binary itself; this updates tools managed by uv
if command -v uv &>/dev/null; then
  uv tool upgrade --all 2>/dev/null || true
fi

step "🔍  Health check"
if ! bash "$DOTFILES_DIR/verify.sh"; then
  warn "Some checks need attention — see output above"
  mark_failure "Health check"
fi

# Summary banner + status file + failure notification are emitted by finalize()
# via the EXIT trap installed near the top of this script.
