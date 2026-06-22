#!/usr/bin/env bash
# update.sh — keep your development environment current
#
# Run manually:     bash ~/dotfiles/update.sh
#   --dry-run       preview every action; change nothing
#   --no-upgrade    pull + re-symlink + verify only (skip brew/mise/rustup/gem
#                   upgrades) — ideal for work machines with pinned tooling
#   --no-pull       skip the git pull;  --force-pull  pull even if repo is dirty
#   --help          full usage
# Per-machine defaults (also honored by the launchd job, which does NOT source
# your shell rc): ~/.config/dotfiles/update.conf   e.g.  NO_UPGRADE=true
# Schedule daily with launchd (one command):
#   bash ~/dotfiles/scripts/setup-scheduler.sh               # install
#   bash ~/dotfiles/scripts/setup-scheduler.sh --no-upgrade  # install (no upgrades)
#   bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall   # remove
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

# Sourced early (no side effects) so the flag/config parsing below can use
# read_config_bool. bootstrap_helpers + setup_colors load further down.
# shellcheck source=scripts/lib/update_helpers.sh
source "$(dirname "$0")/scripts/lib/update_helpers.sh"

# ── Flags ─────────────────────────────────────────────────────────────────────
# Determinism / safety controls, resolved in increasing order of precedence:
#   1. per-machine config file  (~/.config/dotfiles/update.conf)
#   2. environment variables    (DOTFILES_UPDATE_NO_UPGRADE / _NO_PULL)
#   3. command-line flags       (--no-upgrade / --no-pull / ...)
# The config file is what makes the launchd job safe: launchd does NOT source
# ~/.zshrc/.zshrc.local, so an env var set there never reaches the scheduled run,
# but update.sh reads the config file directly on every invocation.
DRY_RUN=false
NO_UPGRADE=false
NO_PULL=false
FORCE_PULL=false

# 1. config file (override the path with DOTFILES_UPDATE_CONFIG, mainly for tests)
UPDATE_CONFIG="${DOTFILES_UPDATE_CONFIG:-$HOME/.config/dotfiles/update.conf}"
_v=$(read_config_bool "$UPDATE_CONFIG" NO_UPGRADE); [[ -n "$_v" ]] && NO_UPGRADE=$_v
_v=$(read_config_bool "$UPDATE_CONFIG" NO_PULL);    [[ -n "$_v" ]] && NO_PULL=$_v
unset _v

# 2. environment variables override the config file (accept true and false)
case "${DOTFILES_UPDATE_NO_UPGRADE:-}" in 1|true|yes|on) NO_UPGRADE=true ;; 0|false|no|off) NO_UPGRADE=false ;; esac
case "${DOTFILES_UPDATE_NO_PULL:-}"    in 1|true|yes|on) NO_PULL=true ;;    0|false|no|off) NO_PULL=false ;; esac

for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=true ;;
    --no-upgrade) NO_UPGRADE=true ;;
    --no-pull)    NO_PULL=true ;;
    --force-pull) FORCE_PULL=true ;;
    --help|-h)
      cat <<'USAGE'
Usage: bash update.sh [OPTIONS]

Keeps the environment current: pull dotfiles, re-symlink, upgrade packages,
then run the health check. Safe to run any time.

Options:
  --dry-run      Show what would happen without changing anything
  --no-upgrade   Pull + re-symlink + verify only; skip brew/mise/rustup/gem
                 upgrades (good for work machines with version-sensitive tools)
  --no-pull      Skip the git pull step
  --force-pull   Pull even if the dotfiles working tree has local changes
  --help, -h     Show this help

Environment:
  DOTFILES_UPDATE_NO_UPGRADE=1   same as --no-upgrade (accepts true/false)
  DOTFILES_UPDATE_NO_PULL=1      same as --no-pull   (accepts true/false)

Config file (read directly, so the scheduled launchd job honors it too):
  ~/.config/dotfiles/update.conf   NO_UPGRADE=true
                                   NO_PULL=false
Precedence: config file < environment < command-line flags.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)"
      exit 1
      ;;
  esac
done

UPDATE_START=$SECONDS
# shellcheck disable=SC2034  # used by step() in helpers
STEP=0
# shellcheck disable=SC2034
TOTAL_STEPS=7

LOG_DIR="$DOTFILES_DIR/logs"
# shellcheck disable=SC2034  # used by update_helpers.sh (sourced below)
LOG_FILE="$LOG_DIR/update.log"
# shellcheck disable=SC2034  # used by update_helpers.sh (sourced below)
STATUS_FILE="$LOG_DIR/update.status"
# shellcheck disable=SC2034  # used by update_helpers.sh (sourced below)
LOG_MAX_BYTES="${DOTFILES_LOG_MAX_BYTES:-1048576}"  # 1 MiB
# shellcheck disable=SC2034  # used by update_helpers.sh (sourced below)
LOG_KEEP="${DOTFILES_LOG_KEEP:-5}"

# Steps whose work failed during this run (reported in the summary + status file)
FAILED_STEPS=()

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$(dirname "$0")/scripts/lib/bootstrap_helpers.sh"
# update_helpers.sh is already sourced near the top (for read_config_bool).
setup_colors

# ── Observability helpers ─────────────────────────────────────────────────────
mark_failure() { FAILED_STEPS+=("$1"); }

# dry — print an intended action during --dry-run without executing it.
dry() { printf "  ${CYAN}→ would${RESET} %s\n" "$*"; }

# rotate_log, can_notify, notify, and write_status are defined in
# scripts/lib/update_helpers.sh (sourced above) so they can be unit-tested.

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

  # In dry-run we made no changes — don't write the status file or notify.
  if [[ "$DRY_RUN" != true ]]; then
    write_status "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$run_status" "$failed_list" "$elapsed"
  fi

  echo ""
  echo "  ─────────────────────────────────────────────────"
  if [[ "$DRY_RUN" == true ]]; then
    printf "${CYAN}${BOLD}  🔎  Dry run complete${RESET}  in %dm %ds — no changes made\n" "$mins" "$secs"
  elif [[ "$run_status" == "success" ]]; then
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

# Skip log rotation in dry-run (truncating/moving the log is a side effect).
[[ "$DRY_RUN" == true ]] || rotate_log

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🔄  dotfiles update${RESET}  —  keeping your environment current\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
_modes=()
[[ "$DRY_RUN" == true ]]    && _modes+=("dry-run")
[[ "$NO_UPGRADE" == true ]] && _modes+=("no-upgrade")
[[ "$NO_PULL" == true ]]    && _modes+=("no-pull")
[[ "$FORCE_PULL" == true ]] && _modes+=("force-pull")
if (( ${#_modes[@]} > 0 )); then
  printf -v _modes_str '%s, ' "${_modes[@]}"
  printf "  ${DIM}Mode${RESET}     %s\n" "${_modes_str%, }"
fi
echo "  ─────────────────────────────────────────────────"

# ── Steps ─────────────────────────────────────────────────────────────────────

step "🔃  Dotfiles"
if [[ "$NO_PULL" == true ]]; then
  info "Skipping git pull (--no-pull)"
elif [[ "$DRY_RUN" == true ]]; then
  if working_tree_dirty "$DOTFILES_DIR"; then
    dry "skip git pull — working tree has uncommitted changes (override: --force-pull)"
  else
    dry "git -C \"$DOTFILES_DIR\" pull --rebase --autostash"
  fi
elif working_tree_dirty "$DOTFILES_DIR" && [[ "$FORCE_PULL" != true ]]; then
  warn "Uncommitted changes in $DOTFILES_DIR — skipping pull to avoid a rebase conflict"
  info "Commit or stash them (or re-run with --force-pull). Continuing without pulling."
else
  if git -C "$DOTFILES_DIR" pull --rebase --autostash; then
    success "Dotfiles pulled"
  else
    warn "Dotfiles pull failed"
    if rebase_in_progress "$DOTFILES_DIR"; then
      git -C "$DOTFILES_DIR" rebase --abort 2>/dev/null || true
      warn "Aborted the in-progress rebase — repo left as it was before the pull"
    fi
    mark_failure "Dotfiles"
  fi
fi

step "🔗  Symlinks"
if [[ "$DRY_RUN" == true ]]; then
  dry "zsh \"$DOTFILES_DIR/install.sh\"  (re-link dotfiles; heals moved/renamed paths)"
elif ! zsh "$DOTFILES_DIR/install.sh"; then
  warn "Symlink install failed — continuing"
  mark_failure "Symlinks"
fi

step "🍺  Homebrew"
if [[ "$NO_UPGRADE" == true ]]; then
  info "Skipping Homebrew upgrades (--no-upgrade)"
elif [[ "$DRY_RUN" == true ]]; then
  dry "brew update && brew upgrade && brew autoremove && brew cleanup --prune=7"
else
  info "Updating Homebrew package definitions..."
  if ! brew update; then
    warn "brew update failed — continuing"
    mark_failure "Homebrew"
  fi
  info "Upgrading Homebrew packages (this may take several minutes)..."
  if brew upgrade; then
    success "All Homebrew packages upgraded"
  else
    warn "Some Homebrew packages failed to upgrade — continuing anyway"
    mark_failure "Homebrew"
  fi
  brew autoremove 2>/dev/null || true
  brew cleanup --prune=7 2>/dev/null || true  # remove downloads older than 7 days
  success "Homebrew update complete"
fi

step "⚡  Runtimes (mise)"
if [[ "$NO_UPGRADE" == true ]]; then
  info "Skipping runtime upgrades (--no-upgrade)"
elif [[ "$DRY_RUN" == true ]]; then
  dry "mise upgrade"
elif command -v mise &>/dev/null; then
  info "Upgrading runtimes (Node, Ruby, Python, etc. — may take a few minutes)..."
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
if [[ "$NO_UPGRADE" == true ]]; then
  info "Skipping Rust toolchain update (--no-upgrade)"
elif [[ "$DRY_RUN" == true ]]; then
  dry "rustup update"
elif command -v rustup &>/dev/null; then
  info "Updating Rust toolchain (this may take a minute while downloading components)..."
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
if [[ "$NO_UPGRADE" == true ]]; then
  info "Skipping gem + uv tool upgrades (--no-upgrade)"
elif [[ "$DRY_RUN" == true ]]; then
  dry "gem update --system && uv tool upgrade --all"
else
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
fi

step "🔍  Health check"
if [[ "$DRY_RUN" == true ]]; then
  dry "bash \"$DOTFILES_DIR/verify.sh\"  (read-only health check)"
elif ! bash "$DOTFILES_DIR/verify.sh"; then
  warn "Some checks need attention — see output above"
  mark_failure "Health check"
fi

# Summary banner + status file + failure notification are emitted by finalize()
# via the EXIT trap installed near the top of this script.
