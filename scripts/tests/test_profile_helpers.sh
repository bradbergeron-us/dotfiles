#!/usr/bin/env bash
# test_profile_helpers.sh — unit tests for profile_helpers.sh
# Usage: bash scripts/tests/test_profile_helpers.sh
# shellcheck disable=SC1091,SC2030,SC2031,SC2034  # dynamic source; intentional subshell scoping

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

source "$SCRIPT_DIR/../lib/profile_helpers.sh"
# Baseline: isolate from the real machine's profile file / env for all tests.
DOTFILES_PROFILE_FILE="$TMPDIR_BASE/baseline-none"
unset DOTFILES_PROFILE 2>/dev/null || true

# ── valid_profile ─────────────────────────────────────────────────────────────
echo ""
echo "=== valid_profile ==="
if valid_profile personal && valid_profile work && valid_profile minimal && valid_profile server; then
  pass "valid_profile: known profiles accepted"
else
  fail "valid_profile: known profiles" "expected all accepted"
fi
if valid_profile bogus; then
  fail "valid_profile: unknown rejected" "expected rejection"
else
  pass "valid_profile: unknown profile rejected"
fi

# ── resolve_profile (precedence: flag > env > file > default) ──────────────────
echo ""
echo "=== resolve_profile ==="
printf 'work\n'    > "$TMPDIR_BASE/pf_work"
printf 'garbage\n' > "$TMPDIR_BASE/pf_bad"

( PF="$TMPDIR_BASE/none"; out="$(DOTFILES_PROFILE_FILE="$PF"; unset DOTFILES_PROFILE; resolve_profile "")"; [[ "$out" == personal ]] ) \
  && pass "resolve_profile: nothing set -> default personal" || fail "resolve_profile: default" "expected personal"

( out="$(DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pf_work"; unset DOTFILES_PROFILE; resolve_profile "")"; [[ "$out" == work ]] ) \
  && pass "resolve_profile: persisted file -> work" || fail "resolve_profile: file" "expected work"

( out="$(DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pf_work"; DOTFILES_PROFILE=server resolve_profile "")"; [[ "$out" == server ]] ) \
  && pass "resolve_profile: env overrides file" || fail "resolve_profile: env>file" "expected server"

( out="$(DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pf_work"; DOTFILES_PROFILE=server resolve_profile "minimal")"; [[ "$out" == minimal ]] ) \
  && pass "resolve_profile: flag overrides env" || fail "resolve_profile: flag>env" "expected minimal"

( out="$(DOTFILES_PROFILE_FILE="$TMPDIR_BASE/none"; DOTFILES_PROFILE=server resolve_profile "bogus")"; [[ "$out" == server ]] ) \
  && pass "resolve_profile: invalid flag falls through to env" || fail "resolve_profile: invalid flag" "expected server"

( out="$(DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pf_bad"; unset DOTFILES_PROFILE; resolve_profile "")"; [[ "$out" == personal ]] ) \
  && pass "resolve_profile: invalid file content -> default" || fail "resolve_profile: bad file" "expected personal"

# ── current_profile ───────────────────────────────────────────────────────────
echo ""
echo "=== current_profile ==="
( out="$(DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pf_work"; unset DOTFILES_PROFILE; current_profile)"; [[ "$out" == work ]] ) \
  && pass "current_profile: reads persisted file" || fail "current_profile" "expected work"

# ── persist_profile ───────────────────────────────────────────────────────────
echo ""
echo "=== persist_profile ==="
if ( DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pp"; persist_profile work; [[ "$(cat "$TMPDIR_BASE/pp")" == work ]] ); then
  pass "persist_profile: writes a valid profile"
else
  fail "persist_profile: valid" "file not written correctly"
fi
if ( DOTFILES_PROFILE_FILE="$TMPDIR_BASE/pp_bad"; ! persist_profile bogus && [[ ! -f "$TMPDIR_BASE/pp_bad" ]] ); then
  pass "persist_profile: rejects invalid name and writes nothing"
else
  fail "persist_profile: invalid" "should reject and not create file"
fi

# ── profile_includes ──────────────────────────────────────────────────────────
echo ""
echo "=== profile_includes ==="
if profile_includes minimal "" && profile_includes server "core"; then
  pass "profile_includes: empty/core apply to all"
else
  fail "profile_includes: empty/core" "expected match"
fi
if profile_includes personal gui && profile_includes work gui && ! profile_includes minimal gui && ! profile_includes server gui; then
  pass "profile_includes: gui -> personal/work only"
else
  fail "profile_includes: gui" "unexpected matching"
fi
if profile_includes work work && ! profile_includes personal work; then
  pass "profile_includes: work tag -> work only"
else
  fail "profile_includes: work" "unexpected matching"
fi
if profile_includes server server && ! profile_includes personal server; then
  pass "profile_includes: exact profile-name tag"
else
  fail "profile_includes: exact name" "unexpected matching"
fi
if profile_includes personal "gui,work" && profile_includes work "gui,work" && ! profile_includes server "gui,work"; then
  pass "profile_includes: multi-tag union"
else
  fail "profile_includes: multi-tag" "unexpected matching"
fi

# ── profile_brewfiles ─────────────────────────────────────────────────────────
echo ""
echo "=== profile_brewfiles ==="
BFD="$TMPDIR_BASE/bf"; mkdir -p "$BFD"
: > "$BFD/Brewfile"; : > "$BFD/Brewfile.personal"; : > "$BFD/Brewfile.work"
count_bf() { profile_brewfiles "$1" "$BFD" | wc -l | tr -d '[:space:]'; }
if [[ "$(count_bf minimal)" == "1" && "$(count_bf server)" == "1" ]]; then
  pass "profile_brewfiles: minimal/server -> core only"
else
  fail "profile_brewfiles: minimal/server" "expected 1 file"
fi
if [[ "$(count_bf personal)" == "2" ]]; then
  pass "profile_brewfiles: personal -> core + personal"
else
  fail "profile_brewfiles: personal" "expected 2 files"
fi
if [[ "$(count_bf work)" == "3" ]]; then
  pass "profile_brewfiles: work -> core + personal + work"
else
  fail "profile_brewfiles: work" "expected 3 files"
fi
rm -f "$BFD/Brewfile.personal" "$BFD/Brewfile.work"
if [[ "$(count_bf work)" == "1" ]]; then
  pass "profile_brewfiles: missing overlay files are omitted"
else
  fail "profile_brewfiles: missing overlays" "expected 1 file"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
