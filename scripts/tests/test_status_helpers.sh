#!/usr/bin/env bash
# test_status_helpers.sh — unit tests for status_helpers.sh
# Usage: bash scripts/tests/test_status_helpers.sh
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

source "$SCRIPT_DIR/../lib/status_helpers.sh"

# ── read_kv_value ─────────────────────────────────────────────────────────────
echo ""
echo "=== read_kv_value ==="

SF="$TMPDIR_BASE/update.status"
cat > "$SF" <<'EOF'
# last run summary
last_run=2026-06-16T03:00:00Z
status=failure
failed_steps=Homebrew, Rust
duration_seconds=42
EOF

if [[ "$(read_kv_value "$SF" last_run)" == "2026-06-16T03:00:00Z" ]]; then
  pass "read_kv_value: last_run"
else
  fail "read_kv_value: last_run" "value mismatch"
fi

if [[ "$(read_kv_value "$SF" status)" == "failure" ]]; then
  pass "read_kv_value: status"
else
  fail "read_kv_value: status" "value mismatch"
fi

if [[ "$(read_kv_value "$SF" failed_steps)" == "Homebrew, Rust" ]]; then
  pass "read_kv_value: value with spaces/commas preserved"
else
  fail "read_kv_value: failed_steps" "value mismatch"
fi

if [[ -z "$(read_kv_value "$SF" missing_key)" ]]; then
  pass "read_kv_value: absent key → empty"
else
  fail "read_kv_value: absent key" "expected empty"
fi

if [[ -z "$(read_kv_value "$TMPDIR_BASE/does-not-exist" status)" ]]; then
  pass "read_kv_value: missing file → empty"
else
  fail "read_kv_value: missing file" "expected empty"
fi

printf 'status=success\nstatus=failure\n' > "$TMPDIR_BASE/last.status"
if [[ "$(read_kv_value "$TMPDIR_BASE/last.status" status)" == "failure" ]]; then
  pass "read_kv_value: last assignment wins"
else
  fail "read_kv_value: last assignment" "expected failure"
fi

printf '# a full-line comment\nnote=a#b\n' > "$TMPDIR_BASE/hash.status"
if [[ "$(read_kv_value "$TMPDIR_BASE/hash.status" note)" == "a#b" ]]; then
  pass "read_kv_value: full-line comment skipped; '#' kept in value"
else
  fail "read_kv_value: inline #" "expected a#b"
fi

# ── git_state ─────────────────────────────────────────────────────────────────
echo ""
echo "=== git_state ==="

if command -v git &>/dev/null; then
  _mkrepo() {
    local r="$1"
    mkdir -p "$r"
    git -C "$r" init -q
    git -C "$r" config user.email t@t
    git -C "$r" config user.name t
    git -C "$r" config commit.gpgsign false
    git -C "$r" config core.hooksPath /dev/null
  }

  # non-git directory → defaults
  if (
    d="$TMPDIR_BASE/nogit"; mkdir -p "$d"
    git_state "$d"
    [[ -z "$GIT_STATE_BRANCH" && "$GIT_STATE_DIRTY" == false && "$GIT_STATE_UNTRACKED" == "0" && "$GIT_STATE_UPSTREAM" == false ]]
  ); then
    pass "git_state: non-git dir → defaults"
  else
    fail "git_state: non-git dir" "expected empty/false defaults"
  fi

  # clean repo → branch set, not dirty, no upstream
  if (
    r="$TMPDIR_BASE/clean"; _mkrepo "$r"
    echo hi > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m init --no-verify
    git_state "$r"
    [[ -n "$GIT_STATE_BRANCH" && "$GIT_STATE_DIRTY" == false && "$GIT_STATE_UNTRACKED" == "0" && "$GIT_STATE_UPSTREAM" == false ]]
  ); then
    pass "git_state: clean repo → branch set, not dirty"
  else
    fail "git_state: clean repo" "unexpected state"
  fi

  # dirty repo → dirty true
  if (
    r="$TMPDIR_BASE/dirty"; _mkrepo "$r"
    echo hi > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m init --no-verify
    echo more >> "$r/f"
    git_state "$r"
    [[ "$GIT_STATE_DIRTY" == true ]]
  ); then
    pass "git_state: dirty repo → dirty=true"
  else
    fail "git_state: dirty repo" "expected dirty=true"
  fi

  # ahead of upstream → upstream=true, ahead=1, behind=0
  if (
    rem="$TMPDIR_BASE/rem.git"; git init -q --bare "$rem"
    r="$TMPDIR_BASE/clone"; git clone -q "$rem" "$r"
    git -C "$r" config user.email t@t
    git -C "$r" config user.name t
    git -C "$r" config commit.gpgsign false
    git -C "$r" config core.hooksPath /dev/null
    echo a > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m c1 --no-verify
    git -C "$r" push -qu origin HEAD
    echo b >> "$r/f"; git -C "$r" commit -q -am c2 --no-verify
    git_state "$r"
    [[ "$GIT_STATE_UPSTREAM" == true && "$GIT_STATE_AHEAD" == "1" && "$GIT_STATE_BEHIND" == "0" ]]
  ); then
    pass "git_state: ahead of upstream → ahead=1, behind=0"
  else
    fail "git_state: ahead of upstream" "expected ahead=1 behind=0"
  fi

  # untracked-only → not dirty, untracked counted
  if (
    r="$TMPDIR_BASE/untracked"; _mkrepo "$r"
    echo hi > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m init --no-verify
    echo new > "$r/extra.txt"
    git_state "$r"
    [[ "$GIT_STATE_DIRTY" == false && "$GIT_STATE_UNTRACKED" == "1" ]]
  ); then
    pass "git_state: untracked-only → dirty=false, untracked=1"
  else
    fail "git_state: untracked-only" "expected dirty=false untracked=1"
  fi

  # detached HEAD → branch shows detached@<sha>, no upstream
  if (
    r="$TMPDIR_BASE/detached"; _mkrepo "$r"
    echo a > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m c1 --no-verify
    echo b >> "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m c2 --no-verify
    git -C "$r" checkout -q HEAD~1
    git_state "$r"
    [[ "$GIT_STATE_BRANCH" == detached@* && "$GIT_STATE_UPSTREAM" == false ]]
  ); then
    pass "git_state: detached HEAD → detached@<sha>"
  else
    fail "git_state: detached HEAD" "expected detached@* and no upstream"
  fi

  # behind upstream → upstream=true, ahead=0, behind=1
  if (
    rem="$TMPDIR_BASE/brem.git"; git init -q --bare "$rem"
    a="$TMPDIR_BASE/ba"; git clone -q "$rem" "$a"
    git -C "$a" config user.email t@t; git -C "$a" config user.name t
    git -C "$a" config commit.gpgsign false; git -C "$a" config core.hooksPath /dev/null
    echo a > "$a/f"; git -C "$a" add f; git -C "$a" commit -q -m c1 --no-verify
    git -C "$a" push -qu origin HEAD
    b="$TMPDIR_BASE/bb"; git clone -q "$rem" "$b"
    git -C "$b" config user.email t@t; git -C "$b" config user.name t
    git -C "$b" config commit.gpgsign false; git -C "$b" config core.hooksPath /dev/null
    echo b >> "$b/f"; git -C "$b" add f; git -C "$b" commit -q -m c2 --no-verify
    git -C "$b" push -q origin HEAD
    git -C "$a" fetch -q
    git_state "$a"
    [[ "$GIT_STATE_UPSTREAM" == true && "$GIT_STATE_AHEAD" == "0" && "$GIT_STATE_BEHIND" == "1" ]]
  ); then
    pass "git_state: behind upstream → ahead=0, behind=1"
  else
    fail "git_state: behind upstream" "expected ahead=0 behind=1"
  fi
else
  printf "  SKIP  git_state (git not available)\n"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
