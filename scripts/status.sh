#!/usr/bin/env bash
# status.sh — quick, read-only snapshot of dotfiles health.
#
# Shows the dotfiles repo's git state and the result of the last `update.sh`
# run (read from logs/update.status, which update.sh writes on every run).
# Read-only and fast — safe to run any time. Handy alias: `dotstatus`.
#
# Usage:
#   bash ~/dotfiles/scripts/status.sh            # repo + last-update summary
#   bash ~/dotfiles/scripts/status.sh --verify   # also run the full verify.sh
#   bash ~/dotfiles/scripts/status.sh --exit-code  # non-zero exit if unhealthy
#   bash ~/dotfiles/scripts/status.sh --help

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$DOTFILES_DIR/logs"
STATUS_FILE="$LOG_DIR/update.status"
LOG_FILE="$LOG_DIR/update.log"

RUN_VERIFY=false
EXIT_CODE_MODE=false
for arg in "$@"; do
  case "$arg" in
    --verify) RUN_VERIFY=true ;;
    --exit-code) EXIT_CODE_MODE=true ;;
    --help|-h)
      cat <<'USAGE'
Usage: bash status.sh [OPTIONS]

Read-only snapshot of dotfiles health: repo git state + last update.sh result.

Options:
  --verify     also run verify.sh (the full health check; slower)
  --exit-code  exit non-zero if unhealthy (last update failed, or --verify failed)
  --help, -h   show this help
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)"
      exit 1
      ;;
  esac
done

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
# shellcheck source=scripts/lib/status_helpers.sh
source "$DOTFILES_DIR/scripts/lib/status_helpers.sh"
setup_colors

echo ""
printf "${BOLD}  🩺  dotfiles status${RESET}\n"
echo "  ─────────────────────────────────────────────────"

# ── Repo ──────────────────────────────────────────────────────────────────────
git_state "$DOTFILES_DIR"
_unhealthy=false
printf "  ${DIM}Repo${RESET}        %s\n" "${DOTFILES_DIR/#$HOME/~}"
if [[ -n "$GIT_STATE_BRANCH" ]]; then
  if [[ "$GIT_STATE_DIRTY" == true ]]; then
    if (( GIT_STATE_UNTRACKED > 0 )); then
      printf "  ${DIM}Branch${RESET}      %s  (${YELLOW}uncommitted changes · %s untracked${RESET})\n" "$GIT_STATE_BRANCH" "$GIT_STATE_UNTRACKED"
    else
      printf "  ${DIM}Branch${RESET}      %s  (${YELLOW}uncommitted changes${RESET})\n" "$GIT_STATE_BRANCH"
    fi
  elif (( GIT_STATE_UNTRACKED > 0 )); then
    printf "  ${DIM}Branch${RESET}      %s  (${GREEN}clean${RESET}, %s untracked)\n" "$GIT_STATE_BRANCH" "$GIT_STATE_UNTRACKED"
  else
    printf "  ${DIM}Branch${RESET}      %s  (${GREEN}clean${RESET})\n" "$GIT_STATE_BRANCH"
  fi
  if [[ "$GIT_STATE_UPSTREAM" == true ]]; then
    if (( GIT_STATE_AHEAD > 0 || GIT_STATE_BEHIND > 0 )); then
      printf "  ${DIM}Upstream${RESET}    ↑%s ahead · ↓%s behind\n" "$GIT_STATE_AHEAD" "$GIT_STATE_BEHIND"
    else
      printf "  ${DIM}Upstream${RESET}    in sync\n"
    fi
  else
    printf "  ${DIM}Upstream${RESET}    (no upstream configured)\n"
  fi
else
  warn "not a git repository: ${DOTFILES_DIR/#$HOME/~}"
fi

# ── Last update ───────────────────────────────────────────────────────────────
echo "  ─────────────────────────────────────────────────"
if [[ -f "$STATUS_FILE" ]]; then
  _last=$(read_kv_value "$STATUS_FILE" last_run)
  _result=$(read_kv_value "$STATUS_FILE" status)
  _failed=$(read_kv_value "$STATUS_FILE" failed_steps)
  _dur=$(read_kv_value "$STATUS_FILE" duration_seconds)
  printf "  ${DIM}Last update${RESET} %s\n" "${_last:-unknown}"
  if [[ "$_result" == "success" ]]; then
    success "result: success  (${_dur:-?}s)"
  else
    warn "result: ${_result:-unknown}  (${_dur:-?}s)"
    [[ -n "$_failed" ]] && warn "failed steps: $_failed"
    info "details: ${LOG_FILE/#$HOME/~}"
    _unhealthy=true
  fi
else
  info "No update.status yet — run:  bash ~/dotfiles/update.sh"
  info "Schedule daily runs:         bash ~/dotfiles/scripts/setup-scheduler.sh"
fi

# ── Optional full health check ────────────────────────────────────────────────
if [[ "$RUN_VERIFY" == true ]]; then
  echo "  ─────────────────────────────────────────────────"
  if ! bash "$DOTFILES_DIR/verify.sh"; then
    _unhealthy=true
  fi
fi

echo ""

# With --exit-code, propagate an unhealthy state (failed last update or, when
# --verify is used, a failing verify.sh) as a non-zero exit for scripting/CI.
# Without it, status.sh is a pure report and always exits 0.
if [[ "$EXIT_CODE_MODE" == true && "$_unhealthy" == true ]]; then
  exit 1
fi
