#!/usr/bin/env bats
# test_dotfiles_cli.bats — smoke tests for the unified CLI (scripts/dotfiles.sh)
# and the bin/dotfiles shim. Run: bats scripts/tests/test_dotfiles_cli.bats

load 'test_helper'

CLI() { bash "$REPO_ROOT/scripts/dotfiles.sh" "$@"; }

# ── syntax ────────────────────────────────────────────────────────────────────
@test "dotfiles.sh passes bash -n" {
  run bash -n "$REPO_ROOT/scripts/dotfiles.sh"
  [ "$status" -eq 0 ]
}

@test "bin/dotfiles shim passes bash -n" {
  run bash -n "$REPO_ROOT/bin/dotfiles"
  [ "$status" -eq 0 ]
}

# ── help / default ────────────────────────────────────────────────────────────
@test "help: exits 0 and prints usage" {
  run CLI help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "no args: prints usage and exits 0" {
  run CLI
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

@test "help lists the core subcommands" {
  run CLI help
  [ "$status" -eq 0 ]
  for sub in status verify doctor update profile cleanup; do
    [[ "$output" == *"$sub"* ]]
  done
}

# ── unknown command ───────────────────────────────────────────────────────────
@test "unknown command: exits non-zero with a helpful message" {
  run CLI does-not-exist
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown command: does-not-exist"* ]]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

# ── shim parity ───────────────────────────────────────────────────────────────
@test "bin/dotfiles shim forwards to the CLI (help)" {
  run bash "$REPO_ROOT/bin/dotfiles" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: dotfiles"* ]]
}

# ── per-command help ──────────────────────────────────────────────────────────
@test "verify --help: exits 0, prints usage, does not run the checks" {
  run CLI verify --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: bash verify.sh"* ]]
  [[ "$output" != *"[1/9]"* ]]   # the step banner only appears on a real run
}

@test "doctor --help: exits 0, prints usage, does not run the checks" {
  run CLI doctor --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: dotfiles doctor"* ]]
  [[ "$output" != *"[1/4]"* ]]   # the step banner only appears on a real run
}

@test "help mentions per-command help and the man page" {
  run CLI help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--help"* ]]
  [[ "$output" == *"man dotfiles"* ]]
}
