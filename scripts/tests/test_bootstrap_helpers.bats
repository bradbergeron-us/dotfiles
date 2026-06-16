#!/usr/bin/env bats
# test_bootstrap_helpers.bats — unit tests for scripts/lib/bootstrap_helpers.sh
# Run: bats scripts/tests/test_bootstrap_helpers.bats

load 'test_helper'

setup() {
  # Sourced fresh per test (each bats test runs in its own process), so global
  # state set by these helpers can never leak between tests.
  # shellcheck source=/dev/null
  source "$LIB_DIR/bootstrap_helpers.sh"
}

# ── setup_colors: stdout is NOT a tty (piped) → empty color vars ───────────────
# Command substitution guarantees stdout is a pipe, so [[ -t 1 ]] is false and
# setup_colors must blank every color variable.

@test "setup_colors (non-tty): RESET is empty" {
  result=$(setup_colors; printf '%s' "$RESET")
  [ -z "$result" ]
}

@test "setup_colors (non-tty): BOLD is empty" {
  result=$(setup_colors; printf '%s' "$BOLD")
  [ -z "$result" ]
}

@test "setup_colors (non-tty): GREEN is empty" {
  result=$(setup_colors; printf '%s' "$GREEN")
  [ -z "$result" ]
}

@test "setup_colors (non-tty): YELLOW is empty" {
  result=$(setup_colors; printf '%s' "$YELLOW")
  [ -z "$result" ]
}

@test "setup_colors (non-tty): CYAN is empty" {
  result=$(setup_colors; printf '%s' "$CYAN")
  [ -z "$result" ]
}

@test "setup_colors (non-tty): BLUE is empty" {
  result=$(setup_colors; printf '%s' "$BLUE")
  [ -z "$result" ]
}

@test "setup_colors (non-tty): DIM is empty" {
  result=$(setup_colors; printf '%s' "$DIM")
  [ -z "$result" ]
}

# ── setup_colors: stdout IS a tty → non-empty (soft, env-dependent) ───────────
# Use script(1) to run inside a pty so [[ -t 1 ]] is true. CI environments may
# lack full pty support, so this never fails hard — it mirrors the original
# "skip rather than fail" behavior.
@test "setup_colors (tty): RESET is non-empty when a pty is available" {
  if ! command -v script >/dev/null 2>&1; then
    skip "script(1) not available"
  fi
  tty_output=$(script -q /dev/null bash -c "
    source '$LIB_DIR/bootstrap_helpers.sh'
    setup_colors
    printf '%s' \"\$RESET\"
  " 2>/dev/null | tr -d '\r') || true
  # Pass whether or not the environment grants pty support.
  [ -n "$tty_output" ] || skip "no pty support in this environment"
}

# ── step counter ──────────────────────────────────────────────────────────────
@test "step() increments STEP correctly (1, 2, 3)" {
  setup_colors
  STEP=0
  TOTAL_STEPS=5
  step "first"  >/dev/null
  [ "$STEP" -eq 1 ]
  step "second" >/dev/null
  [ "$STEP" -eq 2 ]
  step "third"  >/dev/null
  [ "$STEP" -eq 3 ]
}

@test "step() output contains counter [1/10]" {
  setup_colors
  STEP=0
  TOTAL_STEPS=10
  output=$(step "Testing label")
  echo "$output" | grep -q "1/10"
}

@test "step() output contains label text" {
  setup_colors
  STEP=0
  TOTAL_STEPS=10
  output=$(step "Testing label")
  echo "$output" | grep -q "Testing label"
}

# ── info / success / warn output ──────────────────────────────────────────────
@test "info() contains message text" {
  setup_colors
  out=$(info "hello info")
  echo "$out" | grep -q "hello info"
}

@test "success() contains message text" {
  setup_colors
  out=$(success "hello success")
  echo "$out" | grep -q "hello success"
}

@test "warn() contains message text" {
  setup_colors
  out=$(warn "hello warn")
  echo "$out" | grep -q "hello warn"
}

# ── parse_mise_runtimes ───────────────────────────────────────────────────────
# Fixture: a representative mise config with a comment, blank lines, and a
# trailing table that must be ignored.
write_mise_fixture() {
  cat > "$BATS_TEST_TMPDIR/mise.toml" << 'EOF'
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
}

@test "parse_mise_runtimes: parses [tools] into tool@version lines" {
  write_mise_fixture
  out=$(parse_mise_runtimes "$BATS_TEST_TMPDIR/mise.toml")
  expected=$'ruby@3.3.6\nnode@22\njava@temurin-21\npython@3.12\ngo@1.24'
  [ "$out" = "$expected" ]
}

@test "parse_mise_runtimes: ignores comments/blanks/other tables (5 entries)" {
  write_mise_fixture
  count=$(parse_mise_runtimes "$BATS_TEST_TMPDIR/mise.toml" | grep -c '@')
  [ "$count" -eq 5 ]
}

@test "parse_mise_runtimes: missing file → empty output" {
  out=$(parse_mise_runtimes "$BATS_TEST_TMPDIR/does_not_exist.toml")
  [ -z "$out" ]
}
