#!/usr/bin/env bash
# update_helpers.sh — observability/maintenance helpers sourced by update.sh.
#
# Side-effect-light and unit-testable: each reads its configuration from globals
# that update.sh defines before sourcing this file:
#   LOG_FILE, LOG_MAX_BYTES, LOG_KEEP   (rotate_log)
#   LOG_DIR, STATUS_FILE                (write_status)
# No function here calls `exit` or installs traps; the run flow (mark_failure,
# finalize, the EXIT trap) stays in update.sh.
# shellcheck disable=SC2034  # globals are provided by the sourcing script

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

# write_status TIMESTAMP STATUS FAILED_STEPS ELAPSED
# Writes a key=value status file to $STATUS_FILE recording the last run, so a
# silent failure of the daily launchd job is observable after the fact.
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
