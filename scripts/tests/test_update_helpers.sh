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

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
