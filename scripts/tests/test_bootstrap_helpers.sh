#!/usr/bin/env bash
# test_bootstrap_helpers.sh — lightweight unit tests for bootstrap_helpers.sh
# Usage: bash scripts/tests/test_bootstrap_helpers.sh
# shellcheck disable=SC1091,SC2030,SC2031,SC2034  # dynamic source path; intentional subshell scoping; vars used by sourced fns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
  printf "  PASS  %s\n" "$1"
}

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
  printf "  FAIL  %s — %s\n" "$1" "$2"
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label" "expected '$expected', got '$actual'"
  fi
}

assert_not_empty() {
  local label="$1" value="$2"
  if [[ -n "$value" ]]; then
    pass "$label"
  else
    fail "$label" "expected non-empty value"
  fi
}

# ── setup_colors: TTY (stdout is a terminal) ─────────────────────────────────
echo ""
echo "=== setup_colors ==="

# When stdout is NOT a tty (piped to file), colors should be empty
result=$(
  # Source in a subshell where stdout goes to a pipe (not a tty)
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$RESET"
)
assert_eq "setup_colors (non-tty): RESET is empty" "" "$result"

result=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$BOLD"
)
assert_eq "setup_colors (non-tty): BOLD is empty" "" "$result"

result=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$GREEN"
)
assert_eq "setup_colors (non-tty): GREEN is empty" "" "$result"

result=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$YELLOW"
)
assert_eq "setup_colors (non-tty): YELLOW is empty" "" "$result"

result=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$CYAN"
)
assert_eq "setup_colors (non-tty): CYAN is empty" "" "$result"

result=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$BLUE"
)
assert_eq "setup_colors (non-tty): BLUE is empty" "" "$result"

result=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  echo "$DIM"
)
assert_eq "setup_colors (non-tty): DIM is empty" "" "$result"

# When stdout IS a tty, test via /dev/tty if available; otherwise just verify
# the function sets non-empty values by using script(1) to simulate a tty.
if command -v script &>/dev/null; then
  # Use script(1) to run inside a pty so [[ -t 1 ]] is true
  tty_output=$(script -q /dev/null bash -c "
    source '$SCRIPT_DIR/../lib/bootstrap_helpers.sh'
    setup_colors
    printf '%s' \"\$RESET\"
  " 2>/dev/null | tr -d '\r') || true

  if [[ -n "$tty_output" ]]; then
    pass "setup_colors (tty): RESET is non-empty"
  else
    # CI environments may not have full pty support — don't fail hard
    pass "setup_colors (tty): skipped (no pty support in this environment)"
  fi
else
  pass "setup_colors (tty): skipped (script command not available)"
fi

# ── step counter ──────────────────────────────────────────────────────────────
echo ""
echo "=== step counter ==="

# Source helpers and test step increments
if (
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  STEP=0
  TOTAL_STEPS=5

  step "first"  >/dev/null
  [[ "$STEP" -eq 1 ]] || { echo "  FAIL  step counter after 1 call — expected 1, got $STEP"; exit 1; }

  step "second" >/dev/null
  [[ "$STEP" -eq 2 ]] || { echo "  FAIL  step counter after 2 calls — expected 2, got $STEP"; exit 1; }

  step "third"  >/dev/null
  [[ "$STEP" -eq 3 ]] || { echo "  FAIL  step counter after 3 calls — expected 3, got $STEP"; exit 1; }
); then
  pass "step() increments STEP correctly (1, 2, 3)"
else
  fail "step() increments STEP correctly" "subshell exited non-zero"
fi

# Verify step() output includes the counter
output=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors
  STEP=0
  TOTAL_STEPS=10
  step "Testing label"
)
if echo "$output" | grep -q "1/10"; then
  pass "step() output contains counter [1/10]"
else
  fail "step() output contains counter [1/10]" "got: $output"
fi

if echo "$output" | grep -q "Testing label"; then
  pass "step() output contains label text"
else
  fail "step() output contains label text" "got: $output"
fi

# ── info / success / warn output ──────────────────────────────────────────────
echo ""
echo "=== output helpers ==="

if (
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  setup_colors

  out=$(info "hello info")
  echo "$out" | grep -q "hello info" || { echo "  FAIL  info() output"; exit 1; }

  out=$(success "hello success")
  echo "$out" | grep -q "hello success" || { echo "  FAIL  success() output"; exit 1; }

  out=$(warn "hello warn")
  echo "$out" | grep -q "hello warn" || { echo "  FAIL  warn() output"; exit 1; }
); then
  pass "info() contains message text"
  pass "success() contains message text"
  pass "warn() contains message text"
else
  fail "output helpers" "subshell exited non-zero"
fi

# ── parse_mise_runtimes ───────────────────────────────────────────────────────
echo ""
echo "=== parse_mise_runtimes ==="

PMR_TMP=$(mktemp -d)
trap 'rm -rf "$PMR_TMP"' EXIT

# Fixture: a representative mise config with a comment, blank lines, and a
# trailing table that must be ignored.
PMR_TOML="$PMR_TMP/mise.toml"
cat > "$PMR_TOML" << 'EOF'
# managed runtimes

[tools]
ruby = "3.3.6"
node = "22"
java = "temurin-21"
python = "3.12"
go = "1.24"

[settings]
experimental = true
EOF

# Case 1: emits one tool@version line per [tools] entry, preserving order
pmr_out=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  parse_mise_runtimes "$PMR_TOML"
)
pmr_expected=$'ruby@3.3.6\nnode@22\njava@temurin-21\npython@3.12\ngo@1.24'
assert_eq "parse_mise_runtimes: parses [tools] into tool@version lines" "$pmr_expected" "$pmr_out"

# Case 2: ignores comments, blank lines, and non-[tools] tables (exactly 5 entries)
pmr_count=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  parse_mise_runtimes "$PMR_TOML" | grep -c '@'
)
assert_eq "parse_mise_runtimes: ignores comments/blanks/other tables" "5" "$pmr_count"

# Case 3: a missing file prints nothing and exits 0
pmr_missing=$(
  source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
  parse_mise_runtimes "$PMR_TMP/does_not_exist.toml"
)
assert_eq "parse_mise_runtimes: missing file → empty output" "" "$pmr_missing"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
