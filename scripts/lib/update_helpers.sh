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

# working_tree_dirty DIR — return 0 (true) if the git work tree at DIR has
# uncommitted changes to TRACKED files (staged or unstaged). Untracked files do
# not count: they neither block a rebase nor get touched by --autostash. Returns
# 1 (false) when the tree is clean or DIR is not a git work tree. update.sh uses
# this to skip `git pull` on a dirty repo instead of risking an autostash/rebase
# conflict on a working machine.
working_tree_dirty() {
  local dir="$1"
  git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null || return 1
  git -C "$dir" diff --quiet 2>/dev/null        || return 0  # unstaged changes
  git -C "$dir" diff --cached --quiet 2>/dev/null || return 0  # staged changes
  return 1
}

# rebase_in_progress DIR — return 0 (true) if a rebase is currently in progress
# in the repo at DIR. update.sh calls this after a failed `pull --rebase` so it
# can `git rebase --abort` and leave the repo exactly as it was before the pull.
rebase_in_progress() {
  local dir="$1" gitdir
  gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null) || return 1
  [[ "$gitdir" = /* ]] || gitdir="$dir/$gitdir"  # --git-dir may be relative to DIR
  [[ -d "$gitdir/rebase-merge" || -d "$gitdir/rebase-apply" ]]
}

# read_config_bool FILE KEY — echo "true" or "false" if FILE sets KEY to a
# recognized boolean (`KEY=value`; surrounding whitespace and `# comments`
# ignored; surrounding quotes stripped; the last assignment wins). Echoes nothing
# when the key is absent/unrecognized or the file is missing, so a caller can tell
# "unset" apart from an explicit value:
#   v=$(read_config_bool "$f" NO_UPGRADE); [[ -n "$v" ]] && NO_UPGRADE=$v
# update.sh reads ~/.config/dotfiles/update.conf this way so the launchd job
# (which never sources ~/.zshrc/.zshrc.local) still honors per-machine settings.
read_config_bool() {
  local file="$1" key="$2" line val=""
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"  # strip trailing comment
    if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*=[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
      val="${BASH_REMATCH[1]}"
      val="${val%\"}"; val="${val#\"}"  # strip optional surrounding double quotes
    fi
  done < "$file"
  case "$val" in
    1|true|TRUE|yes|YES|on|ON)    echo "true" ;;
    0|false|FALSE|no|NO|off|OFF)  echo "false" ;;
  esac
}
