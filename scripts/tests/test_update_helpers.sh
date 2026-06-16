#!/usr/bin/env bash
# test_update_helpers.sh — unit tests for update_helpers.sh
# Usage: bash scripts/tests/test_update_helpers.sh
# shellcheck disable=SC1091,SC2030,SC2031,SC2034  # dynamic source; intentional subshell scoping; vars used by sourced fns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  TESTS_PASSED=$(( TESTS_PASSED + 1 ))
  TESTS_RUN=$(( TESTS_RUN + 1 ))
  printf "  PASS  %s\n" "$1"
}

fail() {
  TESTS_FAILED=$(( TESTS_FAILED + 1 ))
  TESTS_RUN=$(( TESTS_RUN + 1 ))
  printf "  FAIL  %s — %s\n" "$1" "$2"
}

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

source "$SCRIPT_DIR/../lib/update_helpers.sh"

# ── rotate_log ────────────────────────────────────────────────────────────────
echo ""
echo "=== rotate_log ==="

# Case 1: file under the size threshold → no rotation, file left untouched
if (
  LOG_FILE="$TMPDIR_BASE/under.log"
  LOG_MAX_BYTES=1048576
  LOG_KEEP=5
  printf 'small\n' > "$LOG_FILE"
  rotate_log
  [[ -f "$LOG_FILE" ]]              || { printf "  FAIL  log removed\n"; exit 1; }
  [[ "$(cat "$LOG_FILE")" == "small" ]] || { printf "  FAIL  content changed\n"; exit 1; }
  [[ ! -e "$LOG_FILE.1" ]]         || { printf "  FAIL  .1 should not exist\n"; exit 1; }
); then
  pass "rotate_log: under threshold → no rotation"
else
  fail "rotate_log: under threshold" "subshell exited non-zero"
fi

# Case 2: file over threshold → truncated in place, old content copied to .1
if (
  LOG_FILE="$TMPDIR_BASE/over.log"
  LOG_MAX_BYTES=10
  LOG_KEEP=5
  printf 'this content exceeds ten bytes\n' > "$LOG_FILE"
  rotate_log
  [[ -f "$LOG_FILE" ]]   || { printf "  FAIL  log missing after rotate\n"; exit 1; }
  [[ ! -s "$LOG_FILE" ]] || { printf "  FAIL  log should be truncated empty\n"; exit 1; }
  [[ -f "$LOG_FILE.1" ]] || { printf "  FAIL  .1 not created\n"; exit 1; }
  grep -q "exceeds ten bytes" "$LOG_FILE.1" || { printf "  FAIL  .1 missing old content\n"; exit 1; }
); then
  pass "rotate_log: over threshold → truncate in place + copy to .1"
else
  fail "rotate_log: over threshold" "subshell exited non-zero"
fi

# Case 3: existing rotations shift (.1 → .2) and LOG_KEEP caps the oldest
if (
  LOG_FILE="$TMPDIR_BASE/shift.log"
  LOG_MAX_BYTES=10
  LOG_KEEP=2
  printf 'NEW oversized current content\n' > "$LOG_FILE"
  printf 'OLD1\n' > "$LOG_FILE.1"
  rotate_log
  grep -q "NEW"  "$LOG_FILE.1" || { printf "  FAIL  current not copied to .1\n"; exit 1; }
  grep -q "OLD1" "$LOG_FILE.2" || { printf "  FAIL  .1 not shifted to .2\n"; exit 1; }
  [[ ! -e "$LOG_FILE.3" ]]     || { printf "  FAIL  .3 should not exist (KEEP=2)\n"; exit 1; }
); then
  pass "rotate_log: shifts .1→.2 and respects LOG_KEEP"
else
  fail "rotate_log: shift + keep-count" "subshell exited non-zero"
fi

# Case 4: missing log file → no-op, returns success
if (
  LOG_FILE="$TMPDIR_BASE/nonexistent.log"
  LOG_MAX_BYTES=10
  LOG_KEEP=5
  rotate_log
  [[ ! -e "$LOG_FILE.1" ]] || { printf "  FAIL  .1 created for missing log\n"; exit 1; }
); then
  pass "rotate_log: missing log file → no-op"
else
  fail "rotate_log: missing log file" "subshell exited non-zero"
fi

# ── write_status ──────────────────────────────────────────────────────────────
echo ""
echo "=== write_status ==="

# Case 1: success run → status file has all four keys
if (
  LOG_DIR="$TMPDIR_BASE/logs_ok"
  STATUS_FILE="$LOG_DIR/update.status"
  write_status "2026-06-14T00:00:00Z" "success" "" "42"
  [[ -f "$STATUS_FILE" ]] || { printf "  FAIL  status file not written\n"; exit 1; }
  grep -q "^last_run=2026-06-14T00:00:00Z$" "$STATUS_FILE" || { printf "  FAIL  last_run missing\n"; exit 1; }
  grep -q "^status=success$"                "$STATUS_FILE" || { printf "  FAIL  status missing\n"; exit 1; }
  grep -q "^failed_steps=$"                 "$STATUS_FILE" || { printf "  FAIL  failed_steps missing\n"; exit 1; }
  grep -q "^duration_seconds=42$"           "$STATUS_FILE" || { printf "  FAIL  duration missing\n"; exit 1; }
); then
  pass "write_status: success → file contains all four keys"
else
  fail "write_status: success" "subshell exited non-zero"
fi

# Case 2: failure run → records the failed-step list
if (
  LOG_DIR="$TMPDIR_BASE/logs_fail"
  STATUS_FILE="$LOG_DIR/update.status"
  write_status "2026-06-14T00:00:00Z" "failure" "Homebrew, Rust" "100"
  grep -q "^status=failure$"               "$STATUS_FILE" || { printf "  FAIL  status not failure\n"; exit 1; }
  grep -q "^failed_steps=Homebrew, Rust$"  "$STATUS_FILE" || { printf "  FAIL  failed_steps not recorded\n"; exit 1; }
); then
  pass "write_status: failure → records failed step list"
else
  fail "write_status: failure" "subshell exited non-zero"
fi

# ── can_notify ────────────────────────────────────────────────────────────────
echo ""
echo "=== can_notify ==="

# Case 1: under CI → always false (never posts notifications in CI/headless)
if (
  export CI=1
  if can_notify; then exit 1; else exit 0; fi
); then
  pass "can_notify: CI set → returns false"
else
  fail "can_notify: CI set" "expected false under CI"
fi

# ── working_tree_dirty / rebase_in_progress ───────────────────────────────────
echo ""
echo "=== working_tree_dirty / rebase_in_progress ==="

if command -v git &>/dev/null; then
  # Helper: init an isolated repo with one commit, no hooks, no signing.
  _mkrepo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email t@t
    git -C "$repo" config user.name t
    git -C "$repo" config commit.gpgsign false
    git -C "$repo" config core.hooksPath /dev/null
    printf 'hello\n' > "$repo/file.txt"
    git -C "$repo" add file.txt
    git -C "$repo" commit -q -m init --no-verify
  }

  # Case 1: clean repo → not dirty
  if (
    _mkrepo "$TMPDIR_BASE/wt_clean"
    if working_tree_dirty "$TMPDIR_BASE/wt_clean"; then exit 1; else exit 0; fi
  ); then
    pass "working_tree_dirty: clean repo → false"
  else
    fail "working_tree_dirty: clean repo" "expected false"
  fi

  # Case 2: unstaged modification → dirty
  if (
    _mkrepo "$TMPDIR_BASE/wt_unstaged"
    printf 'changed\n' >> "$TMPDIR_BASE/wt_unstaged/file.txt"
    if working_tree_dirty "$TMPDIR_BASE/wt_unstaged"; then exit 0; else exit 1; fi
  ); then
    pass "working_tree_dirty: unstaged change → true"
  else
    fail "working_tree_dirty: unstaged change" "expected true"
  fi

  # Case 3: staged modification → dirty
  if (
    _mkrepo "$TMPDIR_BASE/wt_staged"
    printf 'changed\n' >> "$TMPDIR_BASE/wt_staged/file.txt"
    git -C "$TMPDIR_BASE/wt_staged" add file.txt
    if working_tree_dirty "$TMPDIR_BASE/wt_staged"; then exit 0; else exit 1; fi
  ); then
    pass "working_tree_dirty: staged change → true"
  else
    fail "working_tree_dirty: staged change" "expected true"
  fi

  # Case 4: untracked file only → not dirty (does not block a rebase)
  if (
    _mkrepo "$TMPDIR_BASE/wt_untracked"
    printf 'new\n' > "$TMPDIR_BASE/wt_untracked/other.txt"
    if working_tree_dirty "$TMPDIR_BASE/wt_untracked"; then exit 1; else exit 0; fi
  ); then
    pass "working_tree_dirty: untracked-only → false"
  else
    fail "working_tree_dirty: untracked-only" "expected false"
  fi

  # Case 5: non-git directory → not dirty
  if (
    mkdir -p "$TMPDIR_BASE/wt_nogit"
    if working_tree_dirty "$TMPDIR_BASE/wt_nogit"; then exit 1; else exit 0; fi
  ); then
    pass "working_tree_dirty: non-git dir → false"
  else
    fail "working_tree_dirty: non-git dir" "expected false"
  fi

  # Case 6: no rebase in progress → false
  if (
    _mkrepo "$TMPDIR_BASE/rip_no"
    if rebase_in_progress "$TMPDIR_BASE/rip_no"; then exit 1; else exit 0; fi
  ); then
    pass "rebase_in_progress: no rebase → false"
  else
    fail "rebase_in_progress: no rebase" "expected false"
  fi

  # Case 7: rebase-merge dir present → true
  if (
    _mkrepo "$TMPDIR_BASE/rip_yes"
    _gd=$(git -C "$TMPDIR_BASE/rip_yes" rev-parse --git-dir)
    [[ "$_gd" = /* ]] || _gd="$TMPDIR_BASE/rip_yes/$_gd"
    mkdir -p "$_gd/rebase-merge"
    if rebase_in_progress "$TMPDIR_BASE/rip_yes"; then exit 0; else exit 1; fi
  ); then
    pass "rebase_in_progress: rebase-merge present → true"
  else
    fail "rebase_in_progress: rebase-merge present" "expected true"
  fi
else
  printf "  SKIP  working_tree_dirty/rebase_in_progress (git not available)\n"
fi

# ── read_config_bool ────────────────────────────────────────────────
echo ""
echo "=== read_config_bool ==="

CFG="$TMPDIR_BASE/update.conf"
cat > "$CFG" <<'EOF'
# sample update config
NO_UPGRADE=true
NO_PULL = false
QUOTED="true"
EOF

if [[ "$(read_config_bool "$CFG" NO_UPGRADE)" == "true" ]]; then
  pass "read_config_bool: NO_UPGRADE=true → true"
else
  fail "read_config_bool: NO_UPGRADE" "expected true"
fi

if [[ "$(read_config_bool "$CFG" NO_PULL)" == "false" ]]; then
  pass "read_config_bool: 'NO_PULL = false' (spaces) → false"
else
  fail "read_config_bool: NO_PULL spaces" "expected false"
fi

if [[ "$(read_config_bool "$CFG" QUOTED)" == "true" ]]; then
  pass "read_config_bool: quoted value → true"
else
  fail "read_config_bool: quoted value" "expected true"
fi

if [[ -z "$(read_config_bool "$CFG" MISSING_KEY)" ]]; then
  pass "read_config_bool: absent key → empty"
else
  fail "read_config_bool: absent key" "expected empty"
fi

if [[ -z "$(read_config_bool "$TMPDIR_BASE/does-not-exist.conf" NO_UPGRADE)" ]]; then
  pass "read_config_bool: missing file → empty"
else
  fail "read_config_bool: missing file" "expected empty"
fi

printf 'NO_UPGRADE=false\nNO_UPGRADE=true\n' > "$TMPDIR_BASE/last.conf"
if [[ "$(read_config_bool "$TMPDIR_BASE/last.conf" NO_UPGRADE)" == "true" ]]; then
  pass "read_config_bool: last assignment wins"
else
  fail "read_config_bool: last assignment" "expected true"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
